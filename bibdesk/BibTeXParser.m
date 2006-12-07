//
//  BibTeXParser.m
//  BibDesk
//
//  Created by Michael McCracken on Thu Nov 28 2002.
/*
 This software is Copyright (c) 2002,2003,2004,2005
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


@interface BibTeXParser (Private)

// private function to do ASCII checking.
NSString * checkAndTranslateString(NSString *s, int line, NSString *filePath, NSStringEncoding parserEncoding);

// private function to get array value from field:
// "foo" # macro # {string} # 19
// becomes an autoreleased array of dicts of different types.
NSString *stringFromBTField(AST *field, 
							NSString *fieldName, 
							NSString *filePath,
							BibDocument* theDocument);

@end

@implementation BibTeXParser

/// libbtparse methods
+ (NSMutableArray *)itemsFromData:(NSData *)inData
                              error:(BOOL *)hadProblems{
    return [self itemsFromData:inData error:hadProblems frontMatter:nil filePath:@"Paste/Drag" document:nil];
}

+ (NSMutableArray *)itemsFromData:(NSData *)inData error:(BOOL *)hadProblems frontMatter:(NSMutableString *)frontMatter filePath:(NSString *)filePath document:(BibDocument *)aDocument{
    if(![inData length]) // btparse chokes on non-BibTeX or empty data, so we'll at least check for zero length
        return [NSMutableArray array];
	
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
    int ok = 1;
    long cidx = 0; // used to scan through buf for annotes.
    int braceDepth = 0;
    
    BibItem *newBI = nil;

    // Strings read from file and added to Dictionary object
    char *fieldname = "\0";
    NSString *s = nil;
    NSString *sFieldName = nil;
    NSString *complexString = nil;
	
    AST *entry = NULL;
    AST *field = NULL;

    NSString *entryType = nil;
    NSMutableArray *returnArray = [[NSMutableArray alloc] initWithCapacity:1];
    
    const char *buf = NULL; // (char *) malloc(sizeof(char) * [inData length]);

    //dictionary is the bibtex entry
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:6];
    
    const char * fs_path = NULL;
    FILE *infile = NULL;
    
    NSStringEncoding parserEncoding;
    if(!aDocument)
        parserEncoding = NSUTF8StringEncoding; // is this a good assumption?  only used for pasteboard stuff.
    else
        parserEncoding = [aDocument documentStringEncoding]; 
    
    if( !([filePath isEqualToString:@"Paste/Drag"]) && [[NSFileManager defaultManager] fileExistsAtPath:filePath]){
        fs_path = [[NSFileManager defaultManager] fileSystemRepresentationWithPath:filePath];
        infile = fopen(fs_path, "r");
    }else{
        infile = [inData openReadOnlyStandardIOFile];
        fs_path = NULL; // used for error context in libbtparse
    }    

    *hadProblems = NO;

    buf = (const char *) [inData bytes];

    bt_initialize();
    bt_set_stringopts(BTE_PREAMBLE, BTO_EXPAND);
    bt_set_stringopts(BTE_REGULAR, BTO_MINIMAL);

    while(entry =  bt_parse_entry(infile, (char *)fs_path, 0, &ok)){
        NSAutoreleasePool *innerPool = [[NSAutoreleasePool alloc] init];
        if (ok){
            // Adding a new BibItem
            entryType = [NSString stringWithBytes:bt_entry_type(entry) encoding:parserEncoding];
            
            if (bt_entry_metatype (entry) != BTE_REGULAR){
                // put preambles etc. into the frontmatter string so we carry them along.
                
                if (frontMatter && [entryType isEqualToString:@"preamble"]){
                    [frontMatter appendString:@"\n@preamble{\""];
                    [frontMatter appendString:[NSString stringWithBytes:bt_get_text(entry) encoding:parserEncoding]];
                    [frontMatter appendString:@"\"}"];
                }else if(frontMatter && [entryType isEqualToString:@"string"]){
                    field = bt_next_field (entry, NULL, &fieldname);
                    NSString *macroKey = [NSString stringWithBytes: field->text encoding:parserEncoding];
                    NSString *macroString = [NSString stringWithBytes: field->down->text encoding:parserEncoding];                        
                    macroString = checkAndTranslateString(macroString, field->line, filePath, parserEncoding); // check for bad characters, deTeXify
                    if(aDocument)
                        [aDocument addMacroDefinitionWithoutUndo:macroString
                                                        forMacro:macroKey];
                }
            }else{
                field = NULL;
                // Returned special case handling of abstract & annote.
                // Special case is there to avoid losing newlines that exist in preexisting files.
                while (field = bt_next_field (entry, field, &fieldname))
                {
                    //Get fieldname as a capitalized NSString
                    sFieldName = [[NSString stringWithBytes: fieldname encoding:parserEncoding] capitalizedString];
                    
                    if(!strcmp(fieldname, "annote") ||
                       !strcmp(fieldname, "abstract") ||
                       !strcmp(fieldname, "rss-description")){
                        if(field->down){
                            cidx = field->down->offset;
                            
                            // the delimiter is at cidx-1
                            if(buf[cidx-1] == '{'){
                                // scan up to the balanced brace
                                for(braceDepth = 1; braceDepth > 0; cidx++){
                                    if(buf[cidx] == '{') braceDepth++;
                                    if(buf[cidx] == '}') braceDepth--;
                                }
                                cidx--;     // just advanced cidx one past the end of the field.
                            }else if(buf[cidx-1] == '"'){
                                // scan up to the next quote.
                                for(; buf[cidx] != '"'; cidx++);
                            }
                            complexString = [[[NSString alloc] initWithData:[NSData dataWithBytes:&buf[field->down->offset] length:(cidx- (field->down->offset))] encoding:parserEncoding] autorelease];
                            complexString = checkAndTranslateString(complexString, field->line, filePath, parserEncoding); // check for bad characters, deTeXify
                        }else{
                            *hadProblems = YES;
                        }
                    }else{
                        complexString = stringFromBTField(field, sFieldName, filePath, aDocument); // handles TeXification
                    }
                    
                    // add the expanded values to the autocomplete dictionary
                    [[NSApp delegate] addString:complexString forCompletionEntry:sFieldName];
                    
                    [dictionary setObject:complexString forKey:sFieldName];
                    
                }// end while field - process next bt field                    
                
                newBI = [[BibItem alloc] initWithType:[entryType lowercaseString]
                                             fileType:BDSKBibtexString
                                            pubFields:dictionary
                                              authors:nil
                                          createdDate:[filePath isEqualToString:@"Paste/Drag"] ? [NSCalendarDate date] : nil];
                [newBI setCiteKeyString:[NSString stringWithBytes:bt_entry_key(entry) encoding:parserEncoding]];
                [returnArray addObject:newBI];
                [newBI release];
                
                [dictionary removeAllObjects];
            } // end generate BibItem from ENTRY metatype.
        }else{
            // wasn't ok, record it and deal with it later.
            *hadProblems = YES;
        }
        bt_free_ast(entry);
        [innerPool release];
    } // while (scanning through file) 
    
    bt_cleanup();

    fclose(infile);
    // @@readonly free(buf);
    
    [pool release];
    return [returnArray autorelease];
}

+ (NSDictionary *)macrosFromBibTeXString:(NSString *)aString hadProblems:(BOOL *)hadProblems{
    NSMutableDictionary *retDict = [NSMutableDictionary dictionary];
    AST *entry = NULL;
    AST *field = NULL;
    char *entryType = NULL;
    char *fieldName = NULL;
    
    bt_initialize();
    bt_set_stringopts(BTE_PREAMBLE, BTO_EXPAND);
    bt_set_stringopts(BTE_REGULAR, BTO_MINIMAL);
    boolean ok;
    *hadProblems = NO;
    
    NSString *macroKey;
    NSString *macroString;
    
    FILE *stream = [[aString dataUsingEncoding:NSUTF8StringEncoding] openReadOnlyStandardIOFile];
    
    while(entry = bt_parse_entry(stream, NULL, 0, &ok)){
        if(entry == NULL && ok) // this is the exit condition
            break;
        if(!ok){
            *hadProblems = YES;
            break;
        }
        entryType = bt_entry_type(entry);
        if(strcmp(entryType, "string") != 0)
            break;
        field = bt_next_field(entry, NULL, &fieldName);
        macroKey = [NSString stringWithBytes: field->text encoding:NSUTF8StringEncoding];
        macroString = [NSString stringWithBytes: field->down->text encoding:NSUTF8StringEncoding];
		macroString = checkAndTranslateString(macroString, field->line, @"Paste/Drag", NSUTF8StringEncoding); // check for bad characters, TeXify
        [retDict setObject:macroString forKey:macroKey];
        
        bt_free_ast(entry);
        entry = NULL;
        field = NULL;
    }
    bt_cleanup();
    fclose(stream);
    return retDict;
}

+ (NSString *)stringFromBibTeXValue:(NSString *)value error:(BOOL *)hadProblems document:(BibDocument *)aDocument{
	NSString *entryString = [NSString stringWithFormat:@"@dummyentry{dummykey, dummyfield = %@}", value];
	NSString *valueString = @"";
    AST *entry = NULL;
    AST *field = NULL;
    char *fieldname = "\0";
	ushort options = BTO_MINIMAL;
	boolean ok;
	
	bt_initialize();
	
	entry = bt_parse_entry_s((char *)[entryString UTF8String], NULL, 1, options, &ok);
	if(ok){
		field = bt_next_field(entry, NULL, &fieldname);
		valueString = stringFromBTField(field, nil, nil, aDocument);
		*hadProblems = NO;
	}else{
		*hadProblems = YES;
	}
	
	bt_parse_entry_s(NULL, NULL, 1, options, NULL);
	bt_free_ast(entry);
	bt_cleanup();
	
	return valueString;
}

+ (NSDictionary *)macrosFromBibTeXStyle:(NSString *)styleContents{
    
    NSScanner *scanner = [[NSScanner alloc] initWithString:styleContents];
    [scanner setCharactersToBeSkipped:nil];
    
    NSMutableDictionary *bstMacros = [NSMutableDictionary dictionary];
    NSString *key = nil;
    NSMutableString *value;

	NSCharacterSet *bracesCharSet = [NSCharacterSet characterSetWithCharactersInString:@"{}"];
	NSString *s;
	int nesting;
	unichar ch;
    
    // NSScanner is case-insensitive by default
    
    while(![scanner isAtEnd]){
        
        [scanner scanUpToString:@"MACRO" intoString:nil]; // don't check the return value on this, in case there are no characters between the initial location and "MACRO"
        
        // scan past the MACRO keyword
        if(![scanner scanString:@"MACRO" intoString:nil])
            break;
        
		[scanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:nil];

        // scan the key
		if(![scanner scanString:@"{" intoString:nil] || 
		   ![scanner scanUpToString:@"}" intoString:&key])
            continue;
        
		[scanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:nil];
        
        // scan the value, a '{}'- or '"'-quoted string between braces
        if(![scanner scanString:@"{" intoString:nil] || [scanner isAtEnd])
			continue;
		
		ch = [styleContents characterAtIndex:[scanner scanLocation]];
        value = [NSMutableString string];
		
		if(ch == '{'){
			
			[scanner setScanLocation:[scanner scanLocation] + 1];
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
			if(nesting > 0){
				//NSLog(@"Unbalanced braces in macro definition.");
				continue;
			}
			
		}else if(ch == '"'){
			
			[scanner setScanLocation:[scanner scanLocation] + 1];
			nesting = 1;
			while(nesting > 0 && ![scanner isAtEnd]){
				if ([scanner scanUpToString:@"\"" intoString:&s])
					[value appendString:s];
				if(![scanner isAtEnd]){
					if([styleContents characterAtIndex:[scanner scanLocation] - 1] == '\\')
						[value appendString:@"\""];
					else 
						nesting = 0;
					[scanner setScanLocation:[scanner scanLocation] + 1];
				}
			}
			if(nesting > 0 || ![value isStringTeXQuotingBalancedWithBraces:YES connected:NO]){
				//NSLog(@"Unbalanced braces in macro definition");
				continue;
			}
			
		}else{
			//NSLog(@"Missing braces around macro definition");
			continue;
		}
        
        [value removeSurroundingWhitespace];
        
        [bstMacros setObject:value forKey:[key stringByRemovingSurroundingWhitespace]];
		
    }
	
    [scanner release];
    
    return ([bstMacros count] ? bstMacros : nil);
    
}

@end

/// private functions used with libbtparse code

NSString * checkAndTranslateString(NSString *s, int line, NSString *filePath, NSStringEncoding parserEncoding){
    if(![s canBeConvertedToEncoding:parserEncoding]){
        NSString *type = NSLocalizedString(@"Error", @"");
        NSString *message = NSLocalizedString(@"Unable to convert characters to the specified encoding.", @"");
        NSDictionary *errorDict = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:filePath, [NSNumber numberWithInt:line], type, message, nil]
                                                              forKeys:[NSArray arrayWithObjects:@"fileName", @"lineNumber", @"errorClassName", @"errorMessage", nil]];
        [[NSNotificationCenter defaultCenter] postNotificationName:BDSKParserErrorNotification
                                                            object:errorDict];
        // make sure the error panel is displayed, regardless of prefs; we can't show the "Keep going/data loss" alert, though
        [[NSApp delegate] performSelectorOnMainThread:@selector(showErrorPanel:) withObject:nil waitUntilDone:NO];
    }
    
    //deTeXify it
    NSString *sDeTexified = [[BDSKConverter sharedConverter] stringByDeTeXifyingString:s];
    return sDeTexified;
}

NSString *stringFromBTField(AST *field, NSString *fieldName, NSString *filePath, BibDocument* document){
    BibAppController *appController = (BibAppController *)[NSApp delegate];
    NSMutableArray *stringValueArray = [NSMutableArray array];
    NSString *s = NULL;
    BDSKStringNode *sNode;
    AST *simple_value;
    
    NSStringEncoding parserEncoding;
    if(!document)
        parserEncoding = NSUTF8StringEncoding;
    else
        parserEncoding = [document documentStringEncoding]; 
    
	if(field->nodetype != BTAST_FIELD){
		NSLog(@"error! expected field here");
	}
	simple_value = field->down;
	
	char *expanded_text = NULL;
	
	while(simple_value){
        if (simple_value->text){
            switch (simple_value->nodetype){
                case BTAST_MACRO:
                    s = [[NSString alloc] initWithBytes:simple_value->text encoding:parserEncoding];
                    
                    // We parse the macros in itemsFromData, but for reference, if we wanted to get the 
                    // macro value we could do this:
                    // expanded_text = bt_macro_text (simple_value->text, (char *)[filePath fileSystemRepresentation], simple_value->line);
                    sNode = [BDSKStringNode nodeWithMacroString:s];
            
                    break;
                case BTAST_STRING:
                    s = [[NSString alloc] initWithBytes:simple_value->text encoding:parserEncoding];
                    sNode = [BDSKStringNode nodeWithQuotedString:checkAndTranslateString(s, field->line, filePath, parserEncoding)];

                    break;
                case BTAST_NUMBER:
                    s = [[NSString alloc] initWithBytes:simple_value->text encoding:parserEncoding];
                    sNode = [BDSKStringNode nodeWithNumberString:s];

                    break;
                default:
                    [NSException raise:@"bad node type exception" format:@"Node type %d is unexpected.", simple_value->nodetype];
            }
            [stringValueArray addObject:sNode];
            [s release];
        }
        
            simple_value = simple_value->right;
	} // while simple_value
	
    // Common case: return a solo string as a non-complex string.
    
    if([stringValueArray count] == 1 &&
       [(BDSKStringNode *)[stringValueArray objectAtIndex:0] type] == BSN_STRING){
        return [(BDSKStringNode *)[stringValueArray objectAtIndex:0] value]; // an NSString
    }
    
    return [NSString complexStringWithArray:stringValueArray macroResolver:document];
}

