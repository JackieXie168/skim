//
//  BibTeXParser.m
//  Bibdesk
//
//  Created by Michael McCracken on Thu Nov 28 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import "BibTeXParser.h"


@implementation BibTeXParser

+ (NSMutableArray *)itemsFromData:(NSData *)inData
                              error:(BOOL *)hadProblems{
    return [BibTeXParser itemsFromData:inData error:hadProblems frontMatter:nil filePath:@"Paste/Drag"];
}

+ (NSMutableArray *)itemsFromData:(NSData *)inData
                              error:(BOOL *)hadProblems
                        frontMatter:(NSMutableString *)frontMatter
                           filePath:(NSString *)filePath{
    int ok = 1;
    long cidx = 0; // used to scan through buf for annotes.
    int braceDepth = 0;
    
    BibItem *newBI = nil;

    // Strings read from file and added to Dictionary object
    char *fieldname = "\0";
    NSString *s = nil;
    NSString *sDeTexified = nil;
    NSString *sFieldName = nil;

    AST *entry = NULL;
    AST *field = NULL;
    int itemOrder = 1;
    BibAppController *appController = (BibAppController *)[NSApp delegate];
    NSString *entryType = nil;
    NSMutableArray *returnArray = [NSMutableArray arrayWithCapacity:1];
    
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

        while(entry =  bt_parse_entry(infile, fs_path, 0, &ok)){
            if (ok){
                // Adding a new BibItem
                if (bt_entry_metatype (entry) != BTE_REGULAR){
                    // put preambles etc. into the frontmatter string so we carry them along.
                    entryType = [NSString stringWithCString:bt_entry_type(entry)];
                    
                    if (frontMatter && [entryType isEqualToString:@"preamble"]){
                        [frontMatter appendString:@"\n@preamble{\""];
                        [frontMatter appendString:[NSString stringWithCString:bt_get_text(entry) ]];
                        [frontMatter appendString:@"\"}"];
                    }
                }else{
                    newBI = [[BibItem alloc] initWithType:
                        [[NSString stringWithCString:bt_entry_type(entry)] lowercaseString]
                                                 fileType:@"BibTeX"
                                                  authors:
                        [NSMutableArray arrayWithCapacity:0]];
                    [newBI setFileOrder:itemOrder];
                    itemOrder++;
                    field = NULL;
                    // Returned special case handling of abstract & annote.
                    // Special case is there to avoid losing newlines that exist in preexisting files.
                    // newlines that are typed in bibdesk are
                    //  now converted to \par and back in stringByDeTexifyingString
                    while (field = bt_next_field (entry, field, &fieldname))
                    {

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
                                s = [NSString stringWithCString:&buf[field->down->offset] length:(cidx- (field->down->offset))];
                            }else{
                                *hadProblems = YES;
                            }
                        }else{
                            s = [NSString stringWithCString:bt_get_text(field)];
                        }

                        // Now that we have the string from the file, check for invalid characters:
                        
                        //Begin check for valid characters (ASCII); otherwise we mangle the .bib file every time we write out
                        //by inserting two characters for every extended character.

                        // Note (mmcc) : This is necessary only when CharacterConversion.plist doesn't cover a character that's in the file - this may be fixable in BDSKConverter also.
                        
                        NSScanner *validscan;
                        NSString *validscanstring = nil;
                                                
                        validscan = [NSScanner scannerWithString:s];  //Scan string s after we get it from bt
                        
                        [validscan setCharactersToBeSkipped:nil]; //If the first character is a newline or whitespace, NSScanner will skip it by default, which gives a bad length value
                        BOOL scannedCharacters = [validscan scanCharactersFromSet:asciiLetters intoString:&validscanstring];
                        
                        if(scannedCharacters && ([validscanstring length] != [s length])) //Compare it to the original string
                        {
                            NSLog(@"This string was in the file: [%@]",s);
                            NSLog(@"This is the part we can read: [%@]",validscanstring);
                            int errorLine = field->line;
                            NSLog(@"Invalid characters at line [%i]",errorLine);
                            
                            // This sets up an error dictionary object and passes it to the listener
                            NSString *fileName = filePath;  //We call this fileName, but its actually trimmed in BibAppController
                            NSValue *lineNumber = [NSNumber numberWithInt:errorLine];  //Need NSValues for NSArray
                            NSString *errorClassName = @"warning"; //We call it a warning
                            NSString *errorMessage = @"Invalid characters"; //This is the actual error message for the table
                            //Need to make an NSDictionary, see BibAppController.m for implementation
                            NSDictionary *errDict = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:fileName, lineNumber, errorClassName, errorMessage, nil]
                                                                                forKeys:[NSArray arrayWithObjects:@"fileName", @"lineNumber", @"errorClassName", @"errorMessage", nil]];
                            *hadProblems = YES; //Set this before we post the notification
                            //Maybe the dictionary should be passed as userInfo:errDict, but BibAppController expects object:errDict.
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"BTPARSE ERROR"
                                                                                object:errDict];
                            
                        }
                        //End check for valid characters.
                        
                        //deTeXify it (includes conversion of /par to \n\n.)
                        sDeTexified = [BDSKConverter stringByDeTeXifyingString:s];
                        //Get fieldname as a capitalized NSString
                        sFieldName = [[NSString stringWithCString: fieldname] capitalizedString];

                        [dictionary setObject:sDeTexified forKey:sFieldName];

                        [appController addString:sDeTexified forCompletionEntry:sFieldName ];
                        
                    }// end while field - process next bt field                    
                   
                    [newBI setCiteKey:[NSString stringWithCString:bt_entry_key(entry)]];
                    [newBI setFields:dictionary];
                    [returnArray addObject:[newBI autorelease]];
                    
                    [dictionary removeAllObjects];
                }
            }else{
                // wasn't ok, record it and deal with it later.
                *hadProblems = YES;
            }
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
        return returnArray;
}


@end
