//
//  BibTeXParser.m
//  BibDesk
//
//  Created by Michael McCracken on Thu Nov 28 2002.
/*
 This software is Copyright (c) 2002,2003,2004,2005,2006
 Michael O. McCracken. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

 - Neither the name of Michael O. McCracken nor the names of any
    contributors may be used to endorse or promote products derived
    from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "BibTeXParser.h"
#import <BTParse/btparse.h>
#import <BTParse/error.h>
#import "BibAppController.h"
#include <stdio.h>
#import "BibItem.h"
#import "BDSKConverter.h"
#import "BDSKComplexString.h"
#import "BibPrefController.h"
#import "BibDocument_Groups.h"
#import "NSString_BDSKExtensions.h"
#import "BibAuthor.h"
#import "BDSKErrorObjectController.h"
#import "BDSKStringNode.h"
#import "BDSKMacroResolver.h"

static NSString *BibTeXParserInternalException = @"BibTeXParserInternalException";
static NSLock *parserLock = nil;

@interface BibTeXParser (Private)

// private function to do ASCII checking.
static NSString * checkAndTranslateString(NSString *s, int line, NSString *filePath, NSStringEncoding parserEncoding);

// private function to get array value from field:
// "foo" # macro # {string} # 19
// becomes an autoreleased array of dicts of different types.
static NSString *stringFromBTField(AST *field, NSString *filePath, BDSKMacroResolver *macroResolver, NSStringEncoding parserEncoding);

// private functions for handling different entry types; these functions do not do any locking around the parser
static void appendPreambleToFrontmatter(AST *entry, NSMutableString *frontMatter, NSStringEncoding encoding);
static void addMacroToResolver(AST *entry, BDSKMacroResolver *macroResolver, NSString *filePath, NSStringEncoding encoding, NSError **error);
static void appendCommentToFrontmatterOrAddGroups(AST *entry, NSMutableString *frontMatter, BibDocument *document, NSStringEncoding encoding);

// private function for preserving newlines in annote/abstract fields; does not lock the parser
static NSString *copyStringFromNoteField(AST *field, const char *data, NSStringEncoding encoding, NSError **error);

@end

@implementation BibTeXParser

+ (void)initialize{
    if(nil == parserLock)
        parserLock = [[NSLock alloc] init];
}

/// libbtparse methods
+ (NSMutableArray *)itemsFromData:(NSData *)inData
                              error:(NSError **)outError
						   document:(BibDocument *)aDocument{
    return [self itemsFromData:inData error:outError frontMatter:nil filePath:BDSKParserPasteDragString document:aDocument];
}

+ (NSMutableArray *)itemsFromData:(NSData *)inData error:(NSError **)outError frontMatter:(NSMutableString *)frontMatter filePath:(NSString *)filePath document:(BibDocument *)aDocument{
	[[BDSKErrorObjectController sharedErrorObjectController] setDocumentForErrors:aDocument];
    
	if(![inData length]) // btparse chokes on non-BibTeX or empty data, so we'll at least check for zero length
        return [NSMutableArray array];
		
    int ok = 1;
    
    BibItem *newBI = nil;
    
    BDSKMacroResolver *macroResolver = [aDocument macroResolver];

    // Strings read from file and added to Dictionary object
    char *fieldname = "\0";
    NSString *sFieldName = nil;
    NSString *complexString = nil;
	
    AST *entry = NULL;
    AST *field = NULL;

    NSString *entryType = nil;
    NSMutableArray *returnArray = [NSMutableArray arrayWithCapacity:100];
    
    const char *buf = NULL;

    //dictionary is the bibtex entry
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:6];
    
    const char * fs_path = NULL;
    FILE *infile = NULL;
    BOOL isPasteOrDrag = [filePath isEqualToString:BDSKParserPasteDragString];
    
    NSStringEncoding parserEncoding = (aDocument == nil || isPasteOrDrag ? NSUTF8StringEncoding : [(BibDocument *)aDocument documentStringEncoding]);
    
    if( !(isPasteOrDrag) && [[NSFileManager defaultManager] fileExistsAtPath:filePath]){
        fs_path = [[NSFileManager defaultManager] fileSystemRepresentationWithPath:filePath];
        infile = fopen(fs_path, "r");
    }else{
        infile = [inData openReadOnlyStandardIOFile];
        fs_path = NULL; // used for error context in libbtparse
    }    

    NSError *error = nil;

    buf = (const char *) [inData bytes];

    if([parserLock tryLock] == NO)
        [NSException raise:NSInternalInconsistencyException format:@"Attempt to reenter the parser.  Please report this error."];
    
    bt_initialize();
    bt_set_stringopts(BTE_PREAMBLE, BTO_EXPAND);
    bt_set_stringopts(BTE_MACRODEF, BTO_MINIMAL);
    bt_set_stringopts(BTE_REGULAR, BTO_COLLAPSE);
    
    NSString *tmpStr = nil;

    @try {
        while(entry =  bt_parse_entry(infile, (char *)fs_path, 0, &ok)){

            if (ok){
                // Adding a new BibItem
                tmpStr = [[NSString alloc] initWithCString:bt_entry_type(entry) usingEncoding:parserEncoding];
                entryType = [tmpStr lowercaseString];
                [tmpStr release];
                
                if ((bt_entry_metatype (entry) != BTE_REGULAR) && nil != frontMatter){
                    // put @preamble etc. into the frontmatter string so we carry them along.
                    if ([entryType isEqualToString:@"preamble"]){
                        appendPreambleToFrontmatter(entry, frontMatter, parserEncoding);
                    }else if([entryType isEqualToString:@"string"]){
                        addMacroToResolver(entry, macroResolver, filePath, parserEncoding, &error);
                    }else if([entryType isEqualToString:@"comment"]){
                        appendCommentToFrontmatterOrAddGroups(entry, frontMatter, aDocument, parserEncoding);
                    }
                    
                }else{
                    // regular type (@article, @proceedings, etc.)
                    field = NULL;
                    while (field = bt_next_field (entry, field, &fieldname))
                    {
                        //Get fieldname as a capitalized NSString
                        tmpStr = [[NSString alloc] initWithCString:fieldname usingEncoding:parserEncoding];
                        sFieldName = [tmpStr capitalizedString];
                        [tmpStr release];
                        
                        // Special case handling of abstract & annote is to avoid losing newlines in preexisting files.
                        if([[BibTypeManager sharedManager] isNoteField:sFieldName]){
                            tmpStr = copyStringFromNoteField(field, buf, parserEncoding, &error);
                            if(nil == tmpStr){
                                // this can happen with badly formed annote/abstract fields, and leads to data loss
                                bt_free_ast(entry);
                                @throw BibTeXParserInternalException;
                            }
                            complexString = checkAndTranslateString(tmpStr, field->line, filePath, parserEncoding);
                            [tmpStr release];
                        }else{
                            complexString = stringFromBTField(field, filePath, macroResolver, parserEncoding);
                        }
                        
                        // add the expanded values to the autocomplete dictionary
                        [[NSApp delegate] addString:complexString forCompletionEntry:sFieldName];
                        
                        [dictionary setObject:complexString forKey:sFieldName];
                        
                    }// end while field - process next bt field                    
                    
                    if([entryType isEqualToString:@"bibdesk_info"] && nil != frontMatter){
                        [aDocument setDocumentInfoWithoutUndo:dictionary];
                    }else{
                        
                        newBI = [[BibItem alloc] initWithType:entryType
                                                     fileType:BDSKBibtexString
                                                    pubFields:dictionary
                                                  createdDate:(isPasteOrDrag ? [NSCalendarDate date] : nil)];

                        tmpStr = [[NSString alloc] initWithCString:bt_entry_key(entry) usingEncoding:parserEncoding];
                        [newBI setCiteKeyString:tmpStr];
                        [tmpStr release];
                        
                        [returnArray addObject:newBI];
                        [newBI release];
                    }
                    
                    [dictionary removeAllObjects];
                } // end generate BibItem from ENTRY metatype.
            }else{
                // wasn't ok, record it and deal with it later.
                OFError(&error, BDSKParserError, NSLocalizedDescriptionKey, NSLocalizedString(@"Unable to parse string as BibTeX", @""), nil);
            }
            bt_free_ast(entry);

        } // while (scanning through file) 
    }
    
    @catch (id exception) {
        if([exception isEqual:BibTeXParserInternalException] == NO)
            @throw;
    }
    
    @finally {
        // execute this regardless, so the parser isn't left in an inconsistent state
        bt_cleanup();
        fclose(infile);
        
        // docs say to return nil in an error condition, rather than checking the NSError itself, but we may want to return partial data
        if(error && outError) *outError = error;
        [parserLock unlock];
    }
    return returnArray;
}

+ (NSDictionary *)macrosFromBibTeXString:(NSString *)aString hadProblems:(BOOL *)hadProblems document:(BibDocument *)aDocument{
	[[BDSKErrorObjectController sharedErrorObjectController] setDocumentForErrors:aDocument];
    
	NSMutableDictionary *retDict = [NSMutableDictionary dictionary];
    AST *entry = NULL;
    AST *field = NULL;
    char *entryType = NULL;
    char *fieldName = NULL;
    
    if([parserLock tryLock] == NO)
        [NSException raise:NSInternalInconsistencyException format:@"Attempt to reenter the parser.  Please report this error."];

    bt_initialize();
    bt_set_stringopts(BTE_MACRODEF, BTO_MINIMAL);
    boolean ok;
    *hadProblems = NO;
    
    NSString *macroKey;
    NSString *macroString;
    
    FILE *stream = [[aString dataUsingEncoding:NSUTF8StringEncoding] openReadOnlyStandardIOFile];
    
    while(entry = bt_parse_entry(stream, NULL, 0, &ok)){
        if(entry == NULL){ // this is the exit condition
            if(!ok)
                *hadProblems = YES;
            break;
        }
        entryType = bt_entry_type(entry);
        if(strcmp(entryType, "string") == 0){
            field = NULL;
            while(field = bt_next_field (entry, field, &fieldName)){
                macroKey = [NSString stringWithCString: field->text usingEncoding:NSUTF8StringEncoding];
                macroString = stringFromBTField(field, BDSKParserPasteDragString, [aDocument macroResolver], NSUTF8StringEncoding); // handles TeXification
                [retDict setObject:macroString forKey:macroKey];
            }
        }
        bt_free_ast(entry);
        entry = NULL;
        field = NULL;
    }
    bt_cleanup();
    [parserLock unlock];
    fclose(stream);
    return retDict;
}

+ (NSString *)stringFromBibTeXValue:(NSString *)value error:(NSError **)outError document:(BibDocument *)aDocument{
	[[BDSKErrorObjectController sharedErrorObjectController] setDocumentForErrors:aDocument];
	
	NSString *entryString = [NSString stringWithFormat:@"@dummyentry{dummykey, dummyfield = %@}", value];
	NSString *valueString = @"";
    AST *entry = NULL;
    AST *field = NULL;
    char *fieldname = "\0";
	ushort options = BTO_MINIMAL;
	boolean ok;
	
    if([parserLock tryLock] == NO)
        [NSException raise:NSInternalInconsistencyException format:@"Attempt to reenter the parser.  Please report this error."];
    
	bt_initialize();
	NSError *error = nil;
    
	entry = bt_parse_entry_s((char *)[entryString UTF8String], NULL, 1, options, &ok);
	if(ok){
		field = bt_next_field(entry, NULL, &fieldname);
		valueString = stringFromBTField(field, nil, [aDocument macroResolver], NSUTF8StringEncoding);
	}else{
        OFError(&error, BDSKParserError, NSLocalizedDescriptionKey, NSLocalizedString(@"Unable to parse string as BibTeX", @""), nil);
	}
	
    if(outError) *outError = error;
    
	bt_parse_entry_s(NULL, NULL, 1, options, NULL);
	bt_free_ast(entry);
	bt_cleanup();
	[parserLock unlock];
    
	return valueString;
}

+ (NSDictionary *)macrosFromBibTeXString:(NSString *)stringContents document:(BibDocument *)aDocument{
    NSScanner *scanner = [[NSScanner alloc] initWithString:stringContents];
    [scanner setCharactersToBeSkipped:nil];
    
    NSMutableDictionary *macros = [NSMutableDictionary dictionary];
    NSString *key = nil;
    NSMutableString *value;
    BOOL endOfValue;

	NSCharacterSet *bracesCharSet = [NSCharacterSet curlyBraceCharacterSet];
	NSString *s;
	int nesting;
	unichar ch;
    
    static NSCharacterSet *bracesAndCommaCharSet = nil;
    if (bracesAndCommaCharSet == nil) {
        NSMutableCharacterSet *tmpSet = [bracesCharSet mutableCopy];
        [tmpSet addCharactersInString:@","];
        bracesAndCommaCharSet = [tmpSet copy];
        [tmpSet release];
    }
    
    // NSScanner is case-insensitive by default
    
    while(![scanner isAtEnd]){
        
        [scanner scanUpToString:@"@STRING" intoString:nil]; // don't check the return value on this, in case there are no characters between the initial location and the keyword
        
        // scan past the keyword
        if(![scanner scanString:@"@STRING" intoString:nil])
            break;
        
		[scanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:nil];
		
        if(![scanner scanString:@"{" intoString:nil])
            continue;

        // scan macro=value items up to the closing brace 
        nesting = 1;
        while(nesting > 0 && ![scanner isAtEnd]){
            
            // scan the key
            if(![scanner scanUpToString:@"=" intoString:&key] ||
               ![scanner scanString:@"=" intoString:nil])
                break;
            
            // scan the value, up to the next comma or the closing brace, passing through nested braces
            endOfValue = NO;
            value = [NSMutableString string];
            while(endOfValue == NO && ![scanner isAtEnd]){
                if([scanner scanUpToCharactersFromSet:bracesAndCommaCharSet intoString:&s])
                    [value appendString:s];
                if([scanner isAtEnd]) break;
                if([stringContents characterAtIndex:[scanner scanLocation] - 1] != '\\'){
                    // we found an unquoted brace
                    ch = [stringContents characterAtIndex:[scanner scanLocation]];
                    if(ch == '{'){
                        ++nesting;
                    }else if(ch == '}'){
                        if(nesting == 1)
                            endOfValue = YES;
                        --nesting;
                    }else if(ch == ','){
                        if(nesting == 1)
                            endOfValue = YES;
                    }
                    if (endOfValue == NO) // we don't include the outer braces or the separating commas
                        [value appendCharacter:ch];
                }
                [scanner setScanLocation:[scanner scanLocation] + 1];
            }
            if(endOfValue == NO)
                break;
            
            [value removeSurroundingWhitespace];
            
            key = [key stringByRemovingSurroundingWhitespace];
            @try{
                value = [NSString stringWithBibTeXString:value macroResolver:[aDocument macroResolver]];
                [macros setObject:value forKey:key];
            }
            @catch(id exception){
                if([[exception name] isEqualToString:BDSKComplexStringException])
                    NSLog(@"Ignoring invalid complex macro: %@",[exception reason]);
                else
                    NSLog(@"Ignoring exception %@ while parsing macro: %@", [exception name], [exception reason]);
            }
            
        }
		
    }
	
    [scanner release];
    
    return ([macros count] ? macros : nil);
}

+ (NSDictionary *)macrosFromBibTeXStyle:(NSString *)styleContents document:(BibDocument *)aDocument{
    NSScanner *scanner = [[NSScanner alloc] initWithString:styleContents];
    [scanner setCharactersToBeSkipped:nil];
    
    NSMutableDictionary *macros = [NSMutableDictionary dictionary];
    NSString *key = nil;
    NSMutableString *value;

	NSCharacterSet *bracesCharSet = [NSCharacterSet curlyBraceCharacterSet];
	NSString *s;
	int nesting;
	unichar ch;
    
    // NSScanner is case-insensitive by default
    
    while(![scanner isAtEnd]){
        
        [scanner scanUpToString:@"MACRO" intoString:nil]; // don't check the return value on this, in case there are no characters between the initial location and the keyword
        
        // scan past the keyword
        if(![scanner scanString:@"MACRO" intoString:nil])
            break;
        
		[scanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:nil];

        // scan the key
		if(![scanner scanString:@"{" intoString:nil] ||
           ![scanner scanUpToString:@"}" intoString:&key] ||
           ![scanner scanString:@"}" intoString:nil])
            continue;
        
        [scanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:nil];
        
        if(![scanner scanString:@"{" intoString:nil])
            continue;
        
        value = [NSMutableString string];
        nesting = 1;
        while(nesting > 0 && ![scanner isAtEnd]){
            if([scanner scanUpToCharactersFromSet:bracesCharSet intoString:&s])
                [value appendString:s];
            if([scanner isAtEnd]) break;
            if([styleContents characterAtIndex:[scanner scanLocation] - 1] != '\\'){
                // we found an unquoted brace
                ch = [styleContents characterAtIndex:[scanner scanLocation]];
                if(ch == '}'){
                    --nesting;
                }else{
                    ++nesting;
                }
                if (nesting > 0) // we don't include the outer braces
                    [value appendFormat:@"%C",ch];
            }
            [scanner setScanLocation:[scanner scanLocation] + 1];
        }
        if(nesting > 0)
            continue;
        
        [value removeSurroundingWhitespace];
        
        key = [key stringByRemovingSurroundingWhitespace];
        @try{
            value = [NSString stringWithBibTeXString:value macroResolver:[aDocument macroResolver]];
            [macros setObject:value forKey:key];
        }
        @catch(id exception){
            if([[exception name] isEqualToString:BDSKComplexStringException])
                NSLog(@"Ignoring invalid complex macro: %@",[exception reason]);
            else
                NSLog(@"Ignoring exception %@ while parsing macro: %@", [exception name], [exception reason]);
        }
		
    }
	
    [scanner release];
    
    return ([macros count] ? macros : nil);
}

static CFArrayRef
__BDCreateArrayOfNamesByCheckingBraceDepth(CFArrayRef names)
{
    CFIndex i, iMax = CFArrayGetCount(names);
    if(iMax <= 1)
        return CFRetain(names);
    
    CFAllocatorRef allocator = CFAllocatorGetDefault();
    
    CFStringInlineBuffer inlineBuffer;
    CFMutableStringRef mutableString = CFStringCreateMutable(allocator, 0);
    CFIndex idx, braceDepth = 0;
    CFStringRef name;
    CFIndex nameLen;
    UniChar ch;
    Boolean shouldAppend = FALSE;
    
    CFMutableArrayRef mutableArray = CFArrayCreateMutable(allocator, iMax, &kCFTypeArrayCallBacks);
    
    for(i = 0; i < iMax; i++){
        name = CFArrayGetValueAtIndex(names, i);
        nameLen = CFStringGetLength(name);
        CFStringInitInlineBuffer(name, &inlineBuffer, CFRangeMake(0, nameLen));

        // check for balanced braces in this name (including braces from a previous name)
        for(idx = 0; idx < nameLen; idx++){
            ch = CFStringGetCharacterFromInlineBuffer(&inlineBuffer, idx);
            if(ch == '{')
                braceDepth++;
            else if(ch == '}')
                braceDepth--;
        }
        // if we had an unbalanced string last time, we need to keep appending to the mutable string; likewise, we want to append this name to the mutable string if braces are still unbalanced
        if(shouldAppend || braceDepth != 0){
            if(BDIsEmptyString(mutableString) == FALSE)
                CFStringAppend(mutableString, CFSTR(" and "));
            CFStringAppend(mutableString, name);
            shouldAppend = TRUE;
        } else {
            // braces balanced, so append the value, and reset the mutable string
            CFArrayAppendValue(mutableArray, name);
            CFStringReplaceAll(mutableString, CFSTR(""));
            // don't append next time unless the next name has unbalanced braces in its own right
            shouldAppend = FALSE;
        }
    }
    
    if(BDIsEmptyString(mutableString) == FALSE)
        CFArrayAppendValue(mutableArray, mutableString);
    CFRelease(mutableString);
    
    // returning NULL will signify our error condition
    if(braceDepth != 0){
        CFRelease(mutableArray);
        mutableArray = NULL;
    }
    
    return mutableArray;
}

+ (NSArray *)authorsFromBibtexString:(NSString *)aString withPublication:(BibItem *)pub{
    
	NSMutableArray *authors = [NSMutableArray arrayWithCapacity:2];
    
    if ([NSString isEmptyString:aString])
        return authors;

    // This is equivalent to btparse's bt_split_list(str, "and", "BibTex Name", 0, ""), but avoids UTF8String conversion
    CFArrayRef array = BDStringCreateArrayBySeparatingStringsWithOptions(CFAllocatorGetDefault(), (CFStringRef)aString, CFSTR(" and "), kCFCompareCaseInsensitive);
    
    // check brace depth; corporate authors such as {Someone and Someone Else, Inc} use braces, so this parsing is BibTeX-specific, rather than general string handling
    CFArrayRef names = __BDCreateArrayOfNamesByCheckingBraceDepth(array);
    CFRelease(array);
    
    // shouldn't ever see this case as far as I know, as long as we're using btparse
    if(names == NULL){
        BDSKErrObj *errorObject = [[BDSKErrObj alloc] init];
        [errorObject setValue:[[pub document] fileName] forKey:@"fileName"];
        [errorObject setValue:[NSNumber numberWithInt:-1] forKey:@"lineNumber"];
        [errorObject setValue:NSLocalizedString(@"Error", @"") forKey:@"errorClassName"];
        [errorObject setValue:[NSString stringWithFormat:@"%@ \"%@\"", NSLocalizedString(@"Unbalanced braces in author names:", @""), [(id)array description]] forKey:@"errorMessage"];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:BDSKParserErrorNotification
                                                            object:errorObject];
        [errorObject release];
        // make sure the error panel is displayed, regardless of prefs
        [[BDSKErrorObjectController sharedErrorObjectController] performSelectorOnMainThread:@selector(showErrorPanel:) withObject:nil waitUntilDone:NO];
        
        // @@ return the empty array or nil?
        return authors;
    }
    
    CFIndex i = 0, iMax = CFArrayGetCount(names);
    BibAuthor *anAuthor;
    
    for(i = 0; i < iMax; i++){
        anAuthor = [[BibAuthor alloc] initWithName:(id)CFArrayGetValueAtIndex(names, i) andPub:pub];
        [authors addObject:anAuthor];
        [anAuthor release];
    }
    
	CFRelease(names);
	return authors;
}

@end

/// private functions used with libbtparse code

static NSString * checkAndTranslateString(NSString *s, int line, NSString *filePath, NSStringEncoding parserEncoding){
    if(![s canBeConvertedToEncoding:parserEncoding]){
        NSString *type = NSLocalizedString(@"Error", @"");
        NSString *message = NSLocalizedString(@"Unable to convert characters to the specified encoding.", @"");

        BDSKErrObj *errorObject = [[BDSKErrObj alloc] init];
        [errorObject setValue:filePath forKey:@"fileName"];
        [errorObject setValue:[NSNumber numberWithInt:line] forKey:@"lineNumber"];
        [errorObject setValue:type forKey:@"errorClassName"];
        [errorObject setValue:message forKey:@"errorMessage"];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:BDSKParserErrorNotification
                                                            object:errorObject];
        [errorObject release];
        // make sure the error panel is displayed, regardless of prefs; we can't show the "Keep going/data loss" alert, though
        [[BDSKErrorObjectController sharedErrorObjectController] performSelectorOnMainThread:@selector(showErrorPanel:) withObject:nil waitUntilDone:NO];
    }
    
    //deTeXify it
    NSString *sDeTexified = [[BDSKConverter sharedConverter] stringByDeTeXifyingString:s];
    return sDeTexified;
}

static NSString *stringFromBTField(AST *field, NSString *filePath, BDSKMacroResolver *macroResolver, NSStringEncoding parserEncoding){
    NSMutableArray *stringValueArray = [[NSMutableArray alloc] initWithCapacity:5];
    NSString *s = nil;
    BDSKStringNode *sNode = nil;
    AST *simple_value;
    
	if(field->nodetype != BTAST_FIELD){
		NSLog(@"error! expected field here");
	}
	simple_value = field->down;
		
	while(simple_value){
        if (simple_value->text){
            switch (simple_value->nodetype){
                case BTAST_MACRO:
                    s = [[NSString alloc] initWithCString:simple_value->text usingEncoding:parserEncoding];
                    if(!s)
                        NSLog(@"possible encoding conversion failure for \"%s\" at line %d", simple_value->text, field->line);
                    
                    // We parse the macros in itemsFromData, but for reference, if we wanted to get the 
                    // macro value we could do this:
                    // expanded_text = bt_macro_text (simple_value->text, (char *)[filePath fileSystemRepresentation], simple_value->line);
                    sNode = [[BDSKStringNode alloc] initWithMacroString:s];
            
                    break;
                case BTAST_STRING:
                    s = [[NSString alloc] initWithCString:simple_value->text usingEncoding:parserEncoding];
                    if(!s)
                        NSLog(@"possible encoding conversion failure for \"%s\" at line %d", simple_value->text, field->line);
                    
                    sNode = [[BDSKStringNode alloc] initWithQuotedString:checkAndTranslateString(s, field->line, filePath, parserEncoding)];

                    break;
                case BTAST_NUMBER:
                    s = [[NSString alloc] initWithCString:simple_value->text usingEncoding:parserEncoding];
                    if(!s)
                        NSLog(@"possible encoding conversion failure for \"%s\" at line %d", simple_value->text, field->line);

                    sNode = [[BDSKStringNode alloc] initWithNumberString:s];

                    break;
                default:
                    [NSException raise:@"bad node type exception" format:@"Node type %d is unexpected.", simple_value->nodetype];
            }
            [stringValueArray addObject:sNode];
            [s release];
            [sNode release];
        }
        
            simple_value = simple_value->right;
	} // while simple_value
	
    // This will return a single string-type node as a non-complex string.
    NSString *returnValue = [NSString stringWithNodes:stringValueArray macroResolver:macroResolver];
    [stringValueArray release];
    
    return returnValue;
}

static void appendPreambleToFrontmatter(AST *entry, NSMutableString *frontMatter, NSStringEncoding encoding)
{
    
    [frontMatter appendString:@"\n@preamble{\""];
    AST *field = NULL;
    bt_nodetype type = BTAST_STRING;
    BOOL paste = NO;
    NSString *tmpStr = nil;
    
    // bt_get_text() just gives us \\ne for the field, so we'll manually traverse it and poke around in the AST to get what we want.  This is sort of nasty, so if someone finds a better way, go for it.
    while(field = bt_next_value(entry, field, &type, NULL)){
        char *text = field->text;
        if(text){
            if(paste) [frontMatter appendString:@"\" #\n   \""];
            tmpStr = [[NSString alloc] initWithCString:text usingEncoding:encoding];
            if(tmpStr) 
                [frontMatter appendString:tmpStr];
            else
                NSLog(@"Possible encoding error: unable to create NSString from %s", text);
            [tmpStr release];
            paste = YES;
        }
    }
    [frontMatter appendString:@"\"}"];
}

static void addMacroToResolver(AST *entry, BDSKMacroResolver *macroResolver, NSString *filePath, NSStringEncoding encoding, NSError **error)
{
    // get the field name, there can be several macros in a single entry
    AST *field = NULL;
    char *fieldname = NULL;
    
    while (field = bt_next_field (entry, field, &fieldname)){
        NSString *macroKey = [NSString stringWithCString: field->text usingEncoding:encoding];
        NSString *macroString = stringFromBTField(field, filePath, macroResolver, encoding); // handles TeXification
        if([macroResolver macroDefinition:macroString dependsOnMacro:macroKey]){
            NSString *type = NSLocalizedString(@"Error", @"");
            NSString *message = NSLocalizedString(@"Macro leads to circular definition, ignored.", @"");
            
            BDSKErrObj *errorObject = [[BDSKErrObj alloc] init];
            [errorObject setValue:filePath forKey:@"fileName"];
            [errorObject setValue:[NSNumber numberWithInt:field->line] forKey:@"lineNumber"];
            [errorObject setValue:type forKey:@"errorClassName"];
            [errorObject setValue:message forKey:@"errorMessage"];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:BDSKParserErrorNotification
                                                                object:errorObject];
            [errorObject release];
            // make sure the error panel is displayed, regardless of prefs; we can't show the "Keep going/data loss" alert, though
            [[BDSKErrorObjectController sharedErrorObjectController] performSelectorOnMainThread:@selector(showErrorPanel:) withObject:nil waitUntilDone:NO];
            
            OFError(error, BDSKParserError, NSLocalizedDescriptionKey, NSLocalizedString(@"Circular macro ignored.", @""), nil);
        }else{
            [macroResolver addMacroDefinitionWithoutUndo:macroString forMacro:macroKey];
        }
    } // end while field - process next macro    
}

static void appendCommentToFrontmatterOrAddGroups(AST *entry, NSMutableString *frontMatter, BibDocument *document, NSStringEncoding encoding)
{
    NSMutableString *commentStr = [[NSMutableString alloc] init];
    AST *field = NULL;
    char *text = NULL;
    NSString *tmpStr = nil;
    
    // this is our identifier string for a smart group
    const char *smartGroupStr = "BibDesk Smart Groups";
    size_t smartGroupStrLength = strlen(smartGroupStr);
    Boolean isSmartGroup = FALSE;
    const char *staticGroupStr = "BibDesk Static Groups";
    size_t staticGroupStrLength = strlen(staticGroupStr);
    Boolean isStaticGroup = FALSE;
    
    while(field = bt_next_value(entry, field, NULL, &text)){
        if(text){
            if(strlen(text) >= smartGroupStrLength && strncmp(text, smartGroupStr, smartGroupStrLength) == 0)
                isSmartGroup = TRUE;
            else if(strlen(text) >= staticGroupStrLength && strncmp(text, staticGroupStr, staticGroupStrLength) == 0)
                isStaticGroup = TRUE;
            
            // encoding will be UTF-8 for the plist, so make sure we use it for each line
            tmpStr = [[NSString alloc] initWithCString:text usingEncoding:((isSmartGroup || isStaticGroup)? NSUTF8StringEncoding : encoding)];
            
            if(tmpStr) 
                [commentStr appendString:tmpStr];
            else
                NSLog(@"Possible encoding error: unable to create NSString from %s", text);
            [tmpStr release];
        }
    }
    if(isSmartGroup == TRUE || isStaticGroup == TRUE){
        if(document){
            NSRange range = [commentStr rangeOfString:@"{"];
            if(range.location != NSNotFound){
                [commentStr deleteCharactersInRange:NSMakeRange(0,NSMaxRange(range))];
                range = [commentStr rangeOfString:@"}" options:NSBackwardsSearch];
                if(range.location != NSNotFound){
                    [commentStr deleteCharactersInRange:NSMakeRange(range.location,[commentStr length] - range.location)];
                    if (isSmartGroup == TRUE)
                        [document setSmartGroupsFromSerializedData:[commentStr dataUsingEncoding:NSUTF8StringEncoding]];
                    else
                        [document setStaticGroupsFromSerializedData:[commentStr dataUsingEncoding:NSUTF8StringEncoding]];
                }
            }
        }
    }else{
        [frontMatter appendString:@"\n@comment{"];
        [frontMatter appendString:commentStr];
        [frontMatter appendString:@"}"];
    }
    [commentStr release];    
}

static NSString *copyStringFromNoteField(AST *field, const char *data, NSStringEncoding encoding, NSError **error)
{
    NSString *returnString = nil;
    long cidx = 0; // used to scan through buf for annotes.
    int braceDepth = 0;
    
    if(field->down){
        cidx = field->down->offset;
        
        // the delimiter is at cidx-1
        if(data[cidx-1] == '{'){
            // scan up to the balanced brace
            for(braceDepth = 1; braceDepth > 0; cidx++){
                if(data[cidx] == '{') braceDepth++;
                if(data[cidx] == '}') braceDepth--;
            }
            cidx--;     // just advanced cidx one past the end of the field.
        }else if(data[cidx-1] == '"'){
            // scan up to the next quote.
            for(; data[cidx] != '"'; cidx++);
        }else{ 
            // no brace and no quote => unknown problem
            NSString *errorString = [NSString stringWithFormat:NSLocalizedString(@"Unexpected delimiter \"%@\" encountered at line %d.", @""), [[[NSString alloc] initWithBytes:&data[cidx-1] length:1 encoding:encoding] autorelease], field->line];
            OFError(error, BDSKParserError, NSLocalizedDescriptionKey, errorString, nil);
        }
        returnString = [[NSString alloc] initWithBytes:&data[field->down->offset] length:(cidx- (field->down->offset)) encoding:encoding];
    }else{
        OFError(error, BDSKParserError, NSLocalizedDescriptionKey, NSLocalizedString(@"Unable to parse string as BibTeX", @""), nil);
    }
    return returnString;
}
