//
//  BibTeXParser.m
//  Bibdesk
//
//  Created by Michael McCracken on Thu Nov 28 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import "BibTeXParser.h"


@interface BibTeXParser (Private)

// private function to do ASCII checking.
NSString * checkAndTranslateString(NSString *s, int line, NSString *filePath);

// private function to get array value from field:
// "foo" # macro # {string} # 19
// becomes an autoreleased array of dicts of different types.
NSString *stringFromBTField(AST *field, 
							NSString *fieldName, 
							NSString *filePath,
							BibDocument* theDocument);

/// The remaining private methods are used by the NSString-based BibTeX parser

// used to stop a parsing operation in progress if its parent document window closes
- (void)terminateCurrentThread;

// range functions used to avoid out-of-range exceptions when using NSString rangeOfString:
NSRange SafeForwardSearchRange( unsigned startLoc, unsigned seekLength, unsigned maxLoc );
NSRange SafeBackwardSearchRange(NSRange startRange, unsigned seekLength);

// called by the Unicode parser; provides compatibility with the btparse error messages
- (void)postParsingErrorNotification:(NSString *)message errorType:(NSString *)type fileName:(NSString *)name errorRange:(NSRange)range;

// formerly used to determine if an '@' character represented a new entry, but is now only used to find the first one in the string
- (BOOL)isNewEntryAtRange:(NSRange)theRange inString:(NSString *)fullString;

// main NSString-based parser method; use the public methods to access this
- (NSMutableArray *)itemsFromString:(NSString *)fullString error:(BOOL *)hadProblems frontMatter:(NSMutableString *)frontMatter filePath:(NSString *)filePath document:(BibDocument *)aDocument background:(BOOL)background;

// used to scan the contents of @string declarations
- (NSDictionary *)macroStringFromScanner:(NSScanner *)scanner endingRange:(NSRange)range string:(NSString *)fullString;

// used to scan @preamble declarations
- (NSString *)preambleStringFromScanner:(NSScanner *)scanner endingRange:(NSRange)range string:(NSString *)fullString filePath:(NSString *)filePath hadProblems:(BOOL *)hadProblems;

@end

@implementation BibTeXParser

- (id)init{
    if(self = [super init]){
        theDocument = nil;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(terminateCurrentThread)
                                                     name:BDSKDocumentWindowWillCloseNotification
                                                   object:[self document]]; 
    }
    return self;
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

/// libbtparse methods
+ (NSMutableArray *)itemsFromData:(NSData *)inData
                              error:(BOOL *)hadProblems{
    BibTeXParser *parser = [[[BibTeXParser alloc] init] autorelease];
    return [parser itemsFromData:inData error:hadProblems frontMatter:nil filePath:@"Paste/Drag" document:nil];
}

+ (NSMutableArray *)itemsFromData:(NSData *)inData error:(BOOL *)hadProblems frontMatter:(NSMutableString *)frontMatter filePath:(NSString *)filePath document:(BibDocument *)aDocument{
    BibTeXParser *parser = [[[BibTeXParser alloc] init] autorelease];
    return [parser itemsFromData:inData error:hadProblems frontMatter:frontMatter filePath:filePath document:aDocument];
}

/// Unicode scanner methods
+ (NSMutableArray *)itemsFromString:(NSString *)string error:(BOOL *)hadProblems{
    BibTeXParser *parser = [[[BibTeXParser alloc] init] autorelease];
    return [parser itemsFromString:string error:hadProblems frontMatter:nil filePath:@"Paste/Drag" document:nil background:NO];
}

+ (NSMutableArray *)itemsFromString:(NSString *)string error:(BOOL *)hadProblems frontMatter:(NSMutableString *)frontMatter filePath:(NSString *)filePath document:(BibDocument *)document{
    BibTeXParser *parser = [[[BibTeXParser alloc] init] autorelease];
    return [parser itemsFromString:string error:hadProblems frontMatter:frontMatter filePath:filePath document:document background:NO];
}

- (void)setDocument:(BibDocument *)aDocument{
    theDocument = aDocument;
}

- (BibDocument *)document{
    return theDocument;
}

- (void)parseItemsFromString:(NSString *)fullString addToDocument:(BibDocument *)document frontMatter:(NSMutableString *)frontMatter{
    BOOL hadProblems;
    [self itemsFromString:fullString error:&hadProblems frontMatter:frontMatter filePath:[document fileName] document:document background:YES];
}

- (NSMutableArray *)itemsFromData:(NSData *)inData
                            error:(BOOL *)hadProblems
                      frontMatter:(NSMutableString *)frontMatter
                         filePath:(NSString *)filePath
                         document:(BibDocument *)aDocument{
	
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
    int itemOrder = 1;
    NSString *entryType = nil;
    NSMutableArray *returnArray = [[NSMutableArray alloc] initWithCapacity:1];
    
    const char *buf = NULL; // (char *) malloc(sizeof(char) * [inData length]);

    //dictionary is the bibtex entry
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:6];
    
    const char * fs_path = NULL;
    NSString *tempFilePath = nil;
    BOOL usingTempFile = NO;
    FILE *infile = NULL;

    NSRange asciiRange;
    NSCharacterSet *asciiLetters;

    //This range defines ASCII, used for the invalid character check during file read
    //we include all the control characters, since anything bad in here should be caught by btparse
    asciiRange.location = 0;
    asciiRange.length = 127; //This should get everything through tilde
    asciiLetters = [NSCharacterSet characterSetWithRange:asciiRange];
    
    [self setDocument:aDocument];
    NSStringEncoding parserEncoding;
    if(!aDocument)
        parserEncoding = [NSString defaultCStringEncoding]; // is this a good assumption?  only used for pasteboard stuff.
    else
        parserEncoding = [[self document] documentStringEncoding]; 
    
    if( !([filePath isEqualToString:@"Paste/Drag"]) && [[NSFileManager defaultManager] fileExistsAtPath:filePath]){
        fs_path = [[NSFileManager defaultManager] fileSystemRepresentationWithPath:filePath];
        usingTempFile = NO;
    }else{
        tempFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]];
        [inData writeToFile:tempFilePath atomically:YES];
        fs_path = [[NSFileManager defaultManager] fileSystemRepresentationWithPath:tempFilePath];
        NSLog(@"using temporary file %@ - was it deleted?",tempFilePath);
        usingTempFile = YES;
    }
    
    infile = fopen(fs_path, "r");

    *hadProblems = NO;

    NS_DURING
       // [inData getBytes:buf length:[inData length]];
        buf = (const char *) [inData bytes];
    NS_HANDLER
        // if we couldn't convert it, we won't be able to read it: just give up.
        // maybe instead of giving up we should find a way to use lossyCString here... ?
        if ([[localException name] isEqualToString:NSCharacterConversionException]) {
            NSLog(@"Exception %@ raised in itemsFromString, handled by giving up.", [localException name]);
            inData = nil;
            NSBeep();
        }else{
            [localException raise];
        }
        NS_ENDHANDLER

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
                        if(theDocument)
                            [theDocument addMacroDefinitionWithoutUndo:macroString
                                                   forMacro:macroKey];
					}
                }else{
                    newBI = [[BibItem alloc] initWithType:[entryType lowercaseString]
                                                 fileType:BDSKBibtexString
                                                  authors:[NSMutableArray arrayWithCapacity:0]
                                              createdDate:nil];
					[newBI setFileOrder:itemOrder];
                    itemOrder++;
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
                            }else{
                                *hadProblems = YES;
                            }
                        }else{
                            complexString = stringFromBTField(field, sFieldName, filePath, theDocument);
                        }
                        
                        [dictionary setObject:complexString forKey:sFieldName];

                    }// end while field - process next bt field                    
					
                    [newBI setCiteKeyString:[NSString stringWithBytes:bt_entry_key(entry) encoding:parserEncoding]];
                    [newBI setPubFields:dictionary];
                    [returnArray addObject:[newBI autorelease]];
                    
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

        if(tempFilePath){
            if (![[NSFileManager defaultManager] removeFileAtPath:tempFilePath handler:nil]) {
                NSLog(@"itemsFromString Failed to delete temporary file. (%@)", tempFilePath);
            }
        }
        fclose(infile);
        if(usingTempFile){
            if(remove(fs_path)){
                NSLog(@"Error - unable to remove temporary file %@", tempFilePath);
            }
        }
        // @@readonly free(buf);
		
		[pool release];
        return [returnArray autorelease];
}

/// private method implementations for NSString-based parser

- (void)terminateCurrentThread{
    // NSLog(@"%@", NSStringFromSelector(_cmd));
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [theDocument stopParseUpdateTimer];
    [self setDocument:nil];
    // [NSThread exit]; // causes a hang; why?
}

- (void)postParsingErrorNotification:(NSString *)message errorType:(NSString *)type fileName:(NSString *)name errorRange:(NSRange)range{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSDictionary *errorDict = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:name, [NSNull null], type, message, [NSValue valueWithRange:range], nil]
                                                          forKeys:[NSArray arrayWithObjects:@"fileName", @"lineNumber", @"errorClassName", @"errorMessage", @"errorRange", nil]];
    [[NSNotificationCenter defaultCenter] postNotificationName:BDSKParserErrorNotification
                                                        object:errorDict];
    [pool release];
}

// returns the largest possible search range from a starting location, based on a desired seek length and the maximum location (string length); avoids out-of-range exceptions
NSRange SafeForwardSearchRange( unsigned startLoc, unsigned seekLength, unsigned maxLoc ){
    seekLength = ( (startLoc + seekLength > maxLoc) ? maxLoc - startLoc : seekLength );
    return NSMakeRange(startLoc, seekLength);
}

// returns the largest possible search range from a starting range to a previous location, based on a desired seek length; avoids out-of-range exceptions
NSRange SafeBackwardSearchRange(NSRange startRange, unsigned seekLength){
    unsigned minLoc = ( (startRange.location > seekLength) ? seekLength : startRange.location);
    return NSMakeRange(startRange.location - minLoc, minLoc);
}

// used to determine if the first '@' character in a file is quoted or not; this method is not robust
- (BOOL)isNewEntryAtRange:(NSRange)theRange inString:(NSString *)fullString{ // use this to determine if an '@' is inside braces or not
    NSRange rbRange = [fullString rangeOfString:@"}" options:NSLiteralSearch | NSBackwardsSearch range:SafeBackwardSearchRange(theRange, theRange.location)];
    NSRange lbRange = [fullString rangeOfString:@"{" options:NSLiteralSearch | NSBackwardsSearch range:SafeBackwardSearchRange(theRange, theRange.location)];
    if(rbRange.location >= lbRange.location && rbRange.location != NSNotFound){ // it's an unbraced @, so should be a new entry
        return YES;
    } else if(rbRange.location == NSNotFound && lbRange.location == NSNotFound){ //( handles NSNotFound for both, as in the initial @ )
        return YES;
    } else {
        return NO;
    }
}

// Scan @string definitions into a dictionary
- (NSDictionary *)macroStringFromScanner:(NSScanner *)scanner endingRange:(NSRange)range string:(NSString *)fullString{
    
    NSString *field = nil;
    NSString *value = nil;
    NSCharacterSet *trimQuoteCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"\""]; // strip these from the ends of the value string
    
    [scanner scanString:@"{" intoString:nil]; // if there wasn't a brace, the warning message will come from the caller
    
    [scanner scanUpToString:@"=" intoString:&field];
    [scanner scanString:@"=" intoString:nil];
    
    // someone (Nelson Beebe or Greg Ward) indicated that you can use macros within @string declarations, so we may not have a quote.  great.
    [scanner scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:nil];
    
    value = [fullString substringWithRange:NSMakeRange([scanner scanLocation], range.location - [scanner scanLocation])];
    value = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if([[fullString substringWithRange:NSMakeRange([scanner scanLocation], 1)] isEqualToString:@"\""])
        value = [value stringByTrimmingCharactersInSet:trimQuoteCharacterSet];
    
    NSAssert( [scanner scanLocation] < range.location, @"Scanner scanned out of range!" );
    
    [scanner setScanLocation:range.location]; // needs to be set so it's at the right location when we return
    
    NSAssert( field != nil, @"Found a nil @string field (key)" );
    NSAssert( value != nil, @"Found a nil @string value" );
    
    return [NSDictionary dictionaryWithObject:value forKey:[field stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
    
}

// scan @preamble declarations into a string, so they can be carried along with frontmatter
- (NSString *)preambleStringFromScanner:(NSScanner *)scanner endingRange:(NSRange)range string:(NSString *)fullString filePath:(NSString *)filePath hadProblems:(BOOL *)hadProblems{
    
    BOOL keepScanning = YES;
    
    unsigned searchStart = [scanner scanLocation]; // we want to keep the first and last brace, so be careful of the start/end points
    unsigned fullStringLength = [fullString length]; // we have no idea a priori where this will end, so we'll just scan through it up to the full length
    NSString *leftDelim = @"{";
    NSString *rightDelim = @"}";
    NSString *logString;
    
    unsigned rightDelimLocation = 0;
    unsigned leftDelimLocation = searchStart;
    if([scanner scanUpToString:rightDelim intoString:nil]){
        rightDelimLocation = [scanner scanLocation];
    } else {
        *hadProblems = YES;
        [self postParsingErrorNotification:[NSString stringWithFormat:@"Delimiter '%@' not found", rightDelim]
                                 errorType:@"Parse Error" 
                                  fileName:filePath 
                                errorRange:[fullString lineRangeForRange:NSMakeRange([scanner scanLocation], 0)]];
    }
    
    while(keepScanning){
        NSRange braceSearchRange = NSMakeRange(searchStart, fullStringLength - searchStart); // braceSearchRange is the "key = {" <-- brace, up to the first '}'
                                                                                             // NSLog(@"Beginning search: substring in braceSearchRange is %@", [fullString substringWithRange:braceSearchRange] );
        NSRange braceFoundRange = [fullString rangeOfString:leftDelim options:NSLiteralSearch range:braceSearchRange]; // this is the first '{' found searching forward in braceSearchRange
        
        // Locals used only in this while()
        unsigned tempStart = braceFoundRange.location;
        BOOL doShallow = YES;
        
        // Okay, so we found a left delimiter.  However, it may be nested inside yet another brace pair, so let's look back from the left delimiter and see if we find another left delimiter at a different location.  
        // Example:  Title = {Physical insight into the {Ergun} and {Wen {\&} Yu} equations for fluid flow in packed and fluidised beds},
        // In this example, the {Wen {\&} Yu} expression is problematic, because we need to account for both left braces; if we don't, everything after the } is stripped.
        // WARNING:  this while() is sort of nasty, and the best way to see how it works is to uncomment the debugging code.  It handles cases such as the above.
        // No guarantee that my comments are totally accurate, either, since some of this is by trial-and-error, and it's easy to get lost in the braces when you're debugging.
        
        while(tempStart != [fullString rangeOfString:leftDelim options:NSLiteralSearch | NSBackwardsSearch range:braceSearchRange].location){ // this means we found "{ {" between { and }
            
            // Reset tempStart, so we know where to look from on the next pass through the loop
            tempStart = [fullString rangeOfString:leftDelim options:NSLiteralSearch range:braceSearchRange].location; // look forward to get the next one to compare with in the while() above
                                                                                                                      // NSLog(@"Reset tempStart!  Neighboring characters are %@", [fullString substringWithRange:NSMakeRange(tempStart - 2, 5)]);
            
            // Perform a forward search to find the leftDelim that we're trying to match; we need to keep track of which leftDelim we're starting from or else we get off by one (or more) braces, and throw an error.
            braceSearchRange = [fullString rangeOfString:leftDelim options:NSLiteralSearch range:NSMakeRange(braceSearchRange.location + 1, rightDelimLocation - braceSearchRange.location - 1)];
            
            // If there are no more leftDelims hanging around, we're done; bail out and go to the next key-value line in the parent while(); don't do the shallow brace check,
            // since that puts us past the end.
            if(braceSearchRange.location == NSNotFound){
                // NSLog(@"braceSearchRange.location is not found, breaking out.");                        
                keepScanning = NO;
                break;
            }
            
            [scanner scanString:rightDelim intoString:&logString]; // More to come, so scan past it
                                                                   //NSLog(@"Deep nested brace check, scanned rightDelim %@", logString);
            
            if(![scanner scanUpToString:rightDelim intoString:&logString] && // find the next right delimiter
               [fullString rangeOfString:@"},\n" options:NSLiteralSearch range:NSMakeRange(tempStart + 1, [scanner scanLocation] - tempStart - 1)].location != NSNotFound ){ // see if there's an equal sign, which means we probably went too far and hit another key/value 
                                                                                                                                                                             //NSLog(@"*** ERROR doubly nested braces");
                                                                                                                                                                             //NSLog(@"the substring was %@", [fullString substringWithRange:NSMakeRange(tempStart + 1, [scanner scanLocation] - tempStart - 1)]);
                *hadProblems = YES; // May not be an error, since these tests are sort of bogus
                                    // showWarning = YES;
                [self postParsingErrorNotification:[NSString stringWithFormat:@"I am puzzled: delimiter '%@' may be missing", rightDelim]
                                         errorType:@"Parse Warning" 
                                          fileName:filePath 
                                        errorRange:[fullString lineRangeForRange:NSMakeRange(leftDelimLocation, 0)]];
            }
            rightDelimLocation = [scanner scanLocation];
            // NSLog(@"Deep nested braces, scanned up to %@ and found %@", rightDelim, logString);
            // NSLog(@"Next I'll compare %i with %i", [fullString rangeOfString:leftDelim options:NSLiteralSearch range:braceSearchRange].location, [fullString rangeOfString:leftDelim options:NSLiteralSearch | NSBackwardsSearch range:braceSearchRange].location);
        }
        
    }

    if(![scanner scanString:rightDelim intoString:&logString]){
        *hadProblems = YES;
        [self postParsingErrorNotification:[NSString stringWithFormat:@"Delimiter '%@' not found", rightDelim]
                                 errorType:@"Parse Error" 
                                  fileName:filePath 
                                errorRange:[fullString lineRangeForRange:NSMakeRange(leftDelimLocation, 0)]];
    }

    NSString *returnString = [NSString stringWithFormat:@"@preamble%@\n\n", [fullString substringWithRange:NSMakeRange(searchStart, [scanner scanLocation] - searchStart)]];
    // NSLog(@"returning %@", returnString);
    return returnString;
}

// NSString-based BibTeX parser method.

- (NSMutableArray *)itemsFromString:(NSString *)fullString error:(BOOL *)hadProblems frontMatter:(NSMutableString *)frontMatter filePath:(NSString *)filePath document:(BibDocument *)aDocument background:(BOOL)background{

// Potential problems with this method:
//
// Nested double quotes are bound to cause problems if the entries use the key = "value", instead of key = {value}, approach.  I can't do anything about this; if you're using TeX,
// you shouldn't have double quotes in your files.  This is a non-issue for BibDesk-created files, as BibItem uses curly braces instead of double quotes; JabRef-1.6 appears to use braces, also.
// This problem will only munge a single entry, though, since we scan between @ markers as entry delimiters; the larger problem is that there is no warning for this case.
    
    NSAutoreleasePool *threadPool = [[NSAutoreleasePool alloc] init];
    BOOL isThreadedLoad = background;
    *hadProblems = NO;
    BOOL isMacro = NO;
    
    [self setDocument:aDocument];
    
    NSAssert( fullString != nil, @"A nil string was passed to the parser.  This is probably due to an incorrect guess at the string encoding." );

    NSScanner *scanner = [[NSScanner alloc] initWithString:fullString];
    [scanner setCharactersToBeSkipped:nil];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    unsigned fullStringLength = [fullString length];
    unsigned fileOrder = 0;
    NSCharacterSet *possibleLeftDelimiters = [NSCharacterSet characterSetWithCharactersInString:@"\"{"];
    BOOL isStringValue = NO;
    BOOL showWarning = NO;
    NSMutableDictionary *stringsDictionary = [NSMutableDictionary dictionary];
    
    BibItem *newBI;
    NSMutableArray *bibItemArray = [NSMutableArray array];
    
    NSRange firstAtRange = [fullString rangeOfString:@"@" options:NSLiteralSearch range:NSMakeRange(0, [fullString length])];
    
    NSAssert( firstAtRange.location != NSNotFound, @"This does not appear to be a BibTeX entry.  Perhaps due to an incorrect encoding guess?" );
    
    // if the @ is unbraced, get the next one; only use this method to find the first @ in the file
    while(firstAtRange.location >= 1 && ![self isNewEntryAtRange:firstAtRange inString:fullString])
        firstAtRange = [fullString rangeOfString:@"@" options:NSLiteralSearch range:SafeForwardSearchRange(firstAtRange.location + 1, fullStringLength - firstAtRange.location - 1, fullStringLength)];

    NSRange nextAtRange = [fullString rangeOfString:@"@" options:NSLiteralSearch range:SafeForwardSearchRange(firstAtRange.location + 1, fullStringLength - firstAtRange.location - 1, fullStringLength)];    
    // check this one to make sure the @ is not escaped; make sure there _is_ another one, though!  if there are unbalanced braces between the firstAt and this one, we know it's not a new entry (or else the braces in the file are hosed)
    while(nextAtRange.location != NSNotFound && ![fullString isStringTeXQuotingBalancedWithBraces:YES connected:YES range:NSMakeRange(firstAtRange.location, nextAtRange.location - firstAtRange.location)])
        nextAtRange = [fullString rangeOfString:@"@" options:NSLiteralSearch range:SafeForwardSearchRange(nextAtRange.location + 1, fullStringLength - nextAtRange.location - 1, fullStringLength)];

    if(nextAtRange.location == NSNotFound)
        nextAtRange = NSMakeRange(fullStringLength, 0); // avoid out-of-range exceptions

    NSRange entryClosingBraceRange = [fullString rangeOfString:@"}" options:NSLiteralSearch | NSBackwardsSearch range:NSMakeRange(firstAtRange.location + 1, nextAtRange.location - firstAtRange.location - 1)]; // look back from the next @ to find the closing brace of the present bib entry
    
    if(entryClosingBraceRange.location == NSNotFound && nextAtRange.location != fullStringLength){ // there's another @entry here (next), but we can't find the brace for the present one (first)
        *hadProblems = YES;
        [self postParsingErrorNotification:@"Entry is missing a closing brace."
                                         errorType:@"Parse Error"
                                          fileName:filePath
                                        errorRange:[fullString lineRangeForRange:NSMakeRange(firstAtRange.location, 0)]];
        entryClosingBraceRange.location = nextAtRange.location;
    }    
    
    // NSLog(@"Creating a new bibitem, first one is at %i, second is at %@", firstAtRange.location, ( nextAtRange.location != NSNotFound ? [NSString stringWithFormat:@"%i", nextAtRange.location] : @"NSNotFound" ) );
    
    while(![scanner isAtEnd]){
        
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        // get the type and citekey
        NSString *type = nil;
        NSString *citekey = nil;
                
        if(firstAtRange.location + 1 < fullStringLength)
            [scanner setScanLocation:(firstAtRange.location + 1)];
        else
            [scanner setScanLocation:fullStringLength];

        if(![scanner scanUpToString:@"{" intoString:&type]){
            *hadProblems = YES;
            [self postParsingErrorNotification:@"Reference type not found"
                                             errorType:@"Parse Error"
                                              fileName:filePath
                                            errorRange:[fullString lineRangeForRange:NSMakeRange([scanner scanLocation], 0)]];
        }
        
        if([scanner scanLocation] > entryClosingBraceRange.location){
            *hadProblems = YES;
            [self postParsingErrorNotification:@"Opening brace not found for entry"
                                             errorType:@"Parse Error"
                                              fileName:filePath
                                            errorRange:[fullString lineRangeForRange:NSMakeRange(entryClosingBraceRange.location, 0)]];
        }            
        
        if(type && [type compare:@"String" options:NSCaseInsensitiveSearch] == NSOrderedSame){ // it's a string!  add it to the dictionary
            isStringValue = YES;
            NSDictionary *macDefDict = [self macroStringFromScanner:scanner
                                                        endingRange:entryClosingBraceRange
                                                             string:fullString];
            // macroStringFromScanner: also sets the scanner so we don't go into the while() loop below
            [stringsDictionary addEntriesFromDictionary:macDefDict];
            
            if(theDocument)
                [theDocument addMacroDefinitionWithoutUndo:[[macDefDict allValues] objectAtIndex:0] forMacro:[[[macDefDict allKeys] objectAtIndex:0] lowercaseString]];
            // NSLog(@"macDefDict has %@", [macDefDict description]);
        } else {
            if(type && [type compare:@"preamble" options:NSCaseInsensitiveSearch] == NSOrderedSame){ // it's the preamble, oh no...
                isStringValue = YES; // this works for preamble as well, since we don't want to run those through the while() loop
                [frontMatter appendString:[self preambleStringFromScanner:scanner
                                                              endingRange:entryClosingBraceRange
                                                                   string:fullString
                                                                 filePath:filePath
                                                              hadProblems:&*hadProblems]];
                NSLog(@"frontMatter is %@", frontMatter);
                nextAtRange = [fullString rangeOfString:@"@" options:NSLiteralSearch range:SafeForwardSearchRange([scanner scanLocation], fullStringLength - [scanner scanLocation], fullStringLength)];
                if(nextAtRange.location != NSNotFound){
                    entryClosingBraceRange = [fullString rangeOfString:@"}" options:NSLiteralSearch | NSBackwardsSearch range:NSMakeRange([scanner scanLocation], nextAtRange.location - [scanner scanLocation])];
                } else {
                    entryClosingBraceRange = NSMakeRange(NSNotFound, 0);
                    showWarning = YES;
                    [self postParsingErrorNotification:@"Content not found after @preamble!"
                                             errorType:@"Parse Warning"
                                              fileName:filePath
                                            errorRange:[fullString lineRangeForRange:NSMakeRange([scanner scanLocation], 0)]];                    
                }
            } else {
                isStringValue = NO; // don't forget to reset this!
            }
        }
        
        if(!isStringValue){
            if(![scanner scanString:@"{" intoString:nil]){
                *hadProblems = YES;
                [self postParsingErrorNotification:@"Brace not found"
                                                 errorType:@"Parse Error"
                                                  fileName:filePath
                                                errorRange:[fullString lineRangeForRange:NSMakeRange([scanner scanLocation], 0)]];
            }
            
            
            if(![scanner scanUpToString:@"," intoString:&citekey]){ // order matters here...
                *hadProblems = YES;
                [self postParsingErrorNotification:@"Citekey not found"
                                                 errorType:@"Parse Error"
                                                  fileName:filePath
                                                errorRange:[fullString lineRangeForRange:NSMakeRange([scanner scanLocation], 0)]];
            }
            
            // NSAssert( citekey != nil && type != nil, @"Missing a citekey or type" );
            
            newBI = [[BibItem alloc] initWithType:[type lowercaseString]
                                         fileType:BDSKBibtexString
                                          authors:[NSMutableArray array]
									  createdDate:nil];        
            
            [newBI setCiteKeyString:[citekey stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
        }
        
        while(entryClosingBraceRange.location != NSNotFound && [scanner scanLocation] < entryClosingBraceRange.location){ // while we are within bounds of a single bibitem
            NSString *key = nil;
            NSString *value = nil;
            NSRange quoteRange;
            NSRange braceRange;
            BOOL usingBraceDelimiter = YES; // assume BibDesk; double quote also works, though
            NSString *leftDelim = @"{";
            NSString *rightDelim = @"}";
            unsigned leftDelimLocation;
            
            [scanner scanUpToString:@"," intoString:nil]; // find the comma
              
            if([scanner scanLocation] >= entryClosingBraceRange.location){
                // NSLog(@"End of file or reached the next bibitem...breaking");
                break; // either at EOF or scanned into the next bibitem
            }

            [scanner scanString:@"," intoString:nil];// get rid of the comma
            
            [scanner scanUpToString:@"=" intoString:&key]; // this should be our key
                           
            [scanner scanString:@"=" intoString:nil];

            quoteRange = [fullString rangeOfString:@"\"" options:NSLiteralSearch range:SafeForwardSearchRange([scanner scanLocation], 100, fullStringLength)];
            braceRange = [fullString rangeOfString:@"{" options:NSLiteralSearch range:SafeForwardSearchRange([scanner scanLocation], 100, fullStringLength)];

            if(quoteRange.location != NSNotFound){
                usingBraceDelimiter = NO;
                leftDelim = @"\"";
                rightDelim = leftDelim;
            }

            if(braceRange.location != NSNotFound && quoteRange.location != NSNotFound && braceRange.location < quoteRange.location){
                usingBraceDelimiter = YES;
                leftDelim = @"{";
                rightDelim = @"}";
            }

            leftDelimLocation = ( usingBraceDelimiter ? braceRange.location : quoteRange.location );
            
            if([scanner scanLocation] >= entryClosingBraceRange.location){
                break; // break here, since this happens at the end of every entry with JabRef-generated BibTeX, and we don't need to hit the assertion below
            }                
            
            // scan whitespace after the = to see if we have an opening delimiter or not; this will be for macroish stuff like publisher =    pub-WADSWORTH # " and " # pub-BC,
            [scanner scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:nil];
            if(![possibleLeftDelimiters characterIsMember:[fullString characterAtIndex:[scanner scanLocation]]]){
                leftDelimLocation = [scanner scanLocation] - 1; // rewind so we don't lose the first character
                rightDelim = @",\n"; // set the delimiter appropriately for an unquoted value
                isMacro = YES;
            } else {
                [scanner setScanLocation:leftDelimLocation + 1];
            }
            
            // Look between leftDelim and \n to see if there is a hash, since we don't handle other cases anyway.
            // In other words, if you have "field = {valueA} # {valueB \n valueC}," or something, you're SOL, because I can't figure out how to parse
            // something like "field = "valueA" # "valueB \n valueC"," which uses double-quote delimiters.
            unsigned contentsEnd;
            [fullString getLineStart:NULL end:NULL contentsEnd:&contentsEnd forRange:NSMakeRange(leftDelimLocation, 1)]; // handles any newline character
                        
            NSRange hashRange = [[fullString substringWithRange:NSMakeRange(leftDelimLocation, contentsEnd - leftDelimLocation)] rangeOfString:@"#"];
            // if the # character exists and is unescaped/unbraced, we assume it's for concatenation
            if(hashRange.location != NSNotFound && [fullString characterAtIndex:(hashRange.location - 1)] != '\\'){
                BOOL balanced = [fullString isStringTeXQuotingBalancedWithBraces:usingBraceDelimiter connected:YES range:NSMakeRange(leftDelimLocation, hashRange.location)]; 
                if(balanced){
                    NSLog(@"BibTeXParser thinks this should be a complex string");
                    leftDelimLocation = [scanner scanLocation] - ((isMacro) ? 1 : 2); // rewind so we don't lose the first character
                    isMacro = YES;
                    rightDelim = @",\n"; // only search to the end of the line; if you can concatenate over multiple lines, this won't work
                    usingBraceDelimiter = NO;
                }
            }
            
            if(leftDelimLocation == NSNotFound){
                *hadProblems = YES;
                [self postParsingErrorNotification:[NSString stringWithFormat:@"Delimiter '%@' not found", leftDelim]
                                                 errorType:@"Parse Error"
                                                  fileName:filePath
                                                errorRange:[fullString lineRangeForRange:NSMakeRange([scanner scanLocation], 0)]];
                break; // nothing more we can do with this one
            }                
                        
            if([scanner scanLocation] >= entryClosingBraceRange.location)
                break;
                        
            unsigned rightDelimLocation = 0;
            if([scanner scanUpToString:rightDelim intoString:nil]){
                rightDelimLocation = [scanner scanLocation];
            } else {
                *hadProblems = YES;
                [self postParsingErrorNotification:[NSString stringWithFormat:@"Delimiter '%@' not found", rightDelim]
                                                 errorType:@"Parse Error" 
                                                  fileName:filePath 
                                                errorRange:[fullString lineRangeForRange:NSMakeRange([scanner scanLocation], 0)]];
            }
               
            unsigned searchStart = leftDelimLocation;
            NSRange braceSearchRange;
            NSRange braceFoundRange;
            NSString *logString = nil;
            
            BOOL keepScanning = YES;
                      
            while(usingBraceDelimiter && keepScanning){
                braceSearchRange = NSMakeRange(searchStart, fullStringLength - searchStart); // braceSearchRange is the "key = {" <-- brace, up to the first '}'
                // NSLog(@"Beginning search: substring in braceSearchRange is %@", [fullString substringWithRange:braceSearchRange] );
                braceFoundRange = [fullString rangeOfString:leftDelim options:NSLiteralSearch range:braceSearchRange]; // this is the first '{' found searching forward in braceSearchRange
                
                // Locals used only in this while()
                unsigned tempStart = braceFoundRange.location;
                
                // Okay, so we found a left delimiter.  However, it may be nested inside yet another brace pair, so let's look back from the left delimiter and see if we find another left delimiter at a different location.  
                // Example:  Title = {Physical insight into the {Ergun} and {Wen {\&} Yu} equations for fluid flow in packed and fluidised beds},
                // In this example, the {Wen {\&} Yu} expression is problematic, because we need to account for both left braces; if we don't, everything after the } is stripped.
                // WARNING:  this while() is sort of nasty, and the best way to see how it works is to uncomment the debugging code.  It handles cases such as the above.
                // No guarantee that my comments are totally accurate, either, since some of this is by trial-and-error, and it's easy to get lost in the braces when you're debugging.
                if(tempStart == [fullString rangeOfString:leftDelim options:NSLiteralSearch | NSBackwardsSearch range:braceSearchRange].location){
                    // NSLog(@"set keepScanning to NO");
                    keepScanning = NO;
                }
                
                while(tempStart != [fullString rangeOfString:leftDelim options:NSLiteralSearch | NSBackwardsSearch range:braceSearchRange].location){ // this means we found "{ {" between { and }
                    
                    // Reset tempStart, so we know where to look from on the next pass through the loop
                    tempStart = [fullString rangeOfString:leftDelim options:NSLiteralSearch range:braceSearchRange].location; // look forward to get the next one to compare with in the while() above
                    // NSLog(@"Reset tempStart!  Neighboring characters are %@", [fullString substringWithRange:NSMakeRange(tempStart - 2, 5)]);
                    
                    // Perform a forward search to find the leftDelim that we're trying to match; we need to keep track of which leftDelim we're starting from or else we get off by one (or more) braces, and throw an error.
                    braceSearchRange = [fullString rangeOfString:leftDelim options:NSLiteralSearch range:NSMakeRange(braceSearchRange.location + 1, rightDelimLocation - braceSearchRange.location - 1)];
                    
                    // If there are no more leftDelims hanging around, we're done; bail out and go to the next key-value line in the parent while(); don't do the shallow brace check,
                    // since that puts us past the end.
                    if(braceSearchRange.location == NSNotFound){
                       //  NSLog(@"braceSearchRange.location is not found, breaking out.");      
                       // NSLog(@"keepScanning set to NO");
                        keepScanning = NO;
                        break;
                    }
                    
                    [scanner scanString:rightDelim intoString:&logString]; // More to come, so scan past it
                    //NSLog(@"Deep nested brace check, scanned rightDelim %@", logString);
                    
                    if(![scanner scanUpToString:rightDelim intoString:&logString] && // find the next right delimiter
                       [fullString rangeOfString:@"},\n" options:NSLiteralSearch range:NSMakeRange(tempStart + 1, [scanner scanLocation] - tempStart - 1)].location != NSNotFound ){ // see if there's an equal sign, which means we probably went too far and hit another key/value 
                        // NSLog(@"*** ERROR doubly nested braces");
                        //NSLog(@"the substring was %@", [fullString substringWithRange:NSMakeRange(tempStart + 1, [scanner scanLocation] - tempStart - 1)]);
                        *hadProblems = YES; // May not be an error, since these tests are sort of bogus
                                            // showWarning = YES;
                        [self postParsingErrorNotification:[NSString stringWithFormat:@"I am puzzled: delimiter '%@' may be missing", rightDelim]
                                                 errorType:@"Parse Warning" 
                                                  fileName:filePath 
                                                errorRange:[fullString lineRangeForRange:NSMakeRange(leftDelimLocation, 0)]];
                    }
                    rightDelimLocation = [scanner scanLocation];
                    // NSLog(@"Deep nested braces, scanned up to %@ and found %@", rightDelim, logString);
                    // NSLog(@"Next I'll compare %i with %i", [fullString rangeOfString:leftDelim options:NSLiteralSearch range:braceSearchRange].location, [fullString rangeOfString:leftDelim options:NSLiteralSearch | NSBackwardsSearch range:braceSearchRange].location);
                }
                
            }            
                                    
            value = [fullString substringWithRange:NSMakeRange(leftDelimLocation + 1, [scanner scanLocation] - leftDelimLocation - 1)]; // here's the "bar" part of foo = bar

            NSAssert( NSMakeRange(leftDelimLocation + 1, [scanner scanLocation] - leftDelimLocation - 1).location <= nextAtRange.location, @"The parser scanned into the next bibitem");

            value = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

            key = [[key stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] capitalizedString];
            
            NSAssert( value != nil, @"Found a nil value string");
            NSAssert( key != nil, @"Found a nil key string");
            
            if(![[NSCharacterSet letterCharacterSet] characterIsMember:[key characterAtIndex:0]]){
                [self postParsingErrorNotification:@"Field names must begin with a letter.  Skipping this field."
                                         errorType:@"Parse Error" 
                                          fileName:filePath 
                                        errorRange:[fullString lineRangeForRange:NSMakeRange([scanner scanLocation], 0)]];
            } else {
                if(isMacro){
                    NS_DURING
						value = [NSString complexStringWithBibTeXString:value macroResolver:theDocument];
						[dict setObject:value forKey:[key capitalizedString]];
						[[NSApp delegate] addString:value forCompletionEntry:key];
					NS_HANDLER
						[self postParsingErrorNotification:@"Invalid BibTeX string for field value.  Skipping this field."
												 errorType:@"Parse Error" 
												  fileName:filePath 
												errorRange:[fullString lineRangeForRange:NSMakeRange([scanner scanLocation], 0)]];
					NS_ENDHANDLER
                    isMacro = NO;
                } else {
                    [dict setObject:value forKey:[key capitalizedString]];
					[[NSApp delegate] addString:value forCompletionEntry:key];
                }
            }
            
        }
        
        if(!isStringValue){ // this is all BibItem related stuff
            [newBI setFileOrder:fileOrder];
            [newBI setPubFields:dict];
            (isThreadedLoad) ? [theDocument addPublicationInBackground:newBI] : [bibItemArray addObject:newBI];
            [newBI release]; // now retained by the array

            fileOrder ++;
        }
        
        [dict removeAllObjects];
        
        firstAtRange = nextAtRange; // we know the next one is safe (unbraced)
        
        nextAtRange = [fullString rangeOfString:@"@" options:NSLiteralSearch range:SafeForwardSearchRange(firstAtRange.location + 1, fullStringLength - firstAtRange.location - 1, fullStringLength)];
        // check for a braced @ string
        while(nextAtRange.location != NSNotFound && ![fullString isStringTeXQuotingBalancedWithBraces:YES connected:YES range:NSMakeRange(firstAtRange.location, nextAtRange.location - firstAtRange.location)])
            nextAtRange = [fullString rangeOfString:@"@" options:NSLiteralSearch range:SafeForwardSearchRange(nextAtRange.location + 1, fullStringLength - nextAtRange.location - 1, fullStringLength)];

        if(nextAtRange.location == NSNotFound)
            nextAtRange = NSMakeRange(fullStringLength, 0);
        
        if(firstAtRange.location != NSNotFound){ // we get to scan another one, so set the scanner appropriately and find the end of the bibitem
            [scanner setScanLocation:firstAtRange.location];
            entryClosingBraceRange = [fullString rangeOfString:@"}" options:NSLiteralSearch | NSBackwardsSearch range:NSMakeRange(firstAtRange.location + 1, nextAtRange.location - firstAtRange.location - 1)]; // look back from the next @ to find the closing brace of the present bib entry
        } else {
            entryClosingBraceRange.location = NSNotFound;
        }
        
        if(entryClosingBraceRange.location == NSNotFound && nextAtRange.location != fullStringLength){ // there's another @entry here (next), but we can't find the brace for the present one (first)
            *hadProblems = YES;
            [self postParsingErrorNotification:@"Entry is missing a closing brace."
                                             errorType:@"Parse Error"
                                              fileName:filePath
                                            errorRange:[fullString lineRangeForRange:NSMakeRange(firstAtRange.location, 0)]];
            entryClosingBraceRange.location = nextAtRange.location;
        }
        
        // NSLog(@"Finished a bibitem, next one is at %i, following is at %@", firstAtRange.location, ( nextAtRange.location != NSNotFound ? [NSString stringWithFormat:@"%i", nextAtRange.location] : @"NSNotFound" ) );

        [pool release];
    }

    if(*hadProblems || showWarning)
        [[NSApp delegate] performSelectorOnMainThread:@selector(showErrorPanel:)
                                           withObject:nil
                                        waitUntilDone:NO]; // this isn't nice, but I'm going to override the warning preference until the parser has been tested

    if(isThreadedLoad && theDocument != nil){ // see if the document ivar has been set to nil, since posting this notification can overlap with the document's -dealloc and cause a crash
        [theDocument stopParseUpdateTimer]; // tell the doc to stop periodic gui updates
        [[NSNotificationCenter defaultCenter] postNotificationName:BDSKDocumentUpdateUINotification object:nil]; // tell the doc to update; this will happen on the main thread
    }
    
    [bibItemArray retain]; // don't release this when we release the threadPool!

    [threadPool release];
    
    [bibItemArray autorelease]; // autorelease to balance the retain above, so this stays around until the sender gets it
    
    return (isThreadedLoad) ? nil : bibItemArray;    
}


@end

/// private functions used with libbtparse code

NSString * checkAndTranslateString(NSString *s, int line, NSString *filePath){
	
	//deTeXify it
	NSString *sDeTexified = [[BDSKConverter sharedConverter] stringByDeTeXifyingString:s];
	return sDeTexified;
}

NSString *stringFromBTField(AST *field, NSString *fieldName, NSString *filePath, BibDocument* document){
    BibAppController *appController = (BibAppController *)[NSApp delegate];
    NSMutableArray *stringValueArray = [[NSMutableArray alloc] initWithCapacity:10];
    NSString *s = NULL;
    BDSKStringNode *sNode;
    AST *simple_value;
    
    NSStringEncoding parserEncoding;
    if(!document)
        parserEncoding = [NSString defaultCStringEncoding];
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
                    sNode = [BDSKStringNode nodeWithQuotedString:checkAndTranslateString(s, field->line, filePath)];
                    
                    break;
                case BTAST_NUMBER:
                    s = [[NSString alloc] initWithBytes:simple_value->text encoding:parserEncoding];
                    sNode = [BDSKStringNode nodeWithNumberString:s];
                    
                    break;
                default:
                    [NSException raise:@"bad node type exception" format:@"Node type %d is unexpected.", simple_value->nodetype];
            }
            [stringValueArray addObject:sNode];
            
            // if we have multiple strings for one field, we add them separately.
            [appController addString:s forCompletionEntry:fieldName]; 
            [s release];
            [sNode release];
        }
        
            simple_value = simple_value->right;
	} // while simple_value
	
    // Common case: return a solo string as a non-complex string.
    
    if([stringValueArray count] == 1 &&
       [(BDSKStringNode *)[stringValueArray objectAtIndex:0] type] == BSN_STRING){
        return [[stringValueArray objectAtIndex:0] value]; // an NSString
    }
    
    return [NSString complexStringWithArray:stringValueArray macroResolver:document];
}

