//
//  BibTeXParser.m
//  Bibdesk
//
//  Created by Michael McCracken on Thu Nov 28 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import "BibTeXParser.h"


@implementation BibTeXParser

+ (NSMutableArray *)itemsFromString:(NSString *)itemString
                              error:(BOOL *)hadProblems{
    return [BibTeXParser itemsFromString:itemString error:hadProblems frontMatter:nil filePath:@"Paste/Drag"];
}


+ (NSMutableArray *)itemsFromString:(NSString *)itemString
                              error:(BOOL *)hadProblems
                        frontMatter:(NSMutableString *)frontMatter
                           filePath:(NSString *)filePath{
    int ok = 1;
    long cidx = 0; // used to scan through buf for annotes.
    char annoteDelim = '\0';
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
    char *buf = (char *) malloc(sizeof(char) * [itemString cStringLength]);

    //dictionary is the bibtex entry
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:6];
    const char * fs_path = NULL;
    NSString *tempFilePath = nil;
    FILE *infile = NULL;

    NSRange EnglishRange;
    NSMutableCharacterSet *EnglishLetters;

    //This range defines ASCII without most of the control characters (or should).
    EnglishRange.location = (unsigned int)' '; //Begin at space
    EnglishRange.length = 95; //This should get everything through tilde
    EnglishLetters = [NSMutableCharacterSet characterSetWithRange:EnglishRange];
    [EnglishLetters addCharactersInString:@"\n"];
    
    
    if( !([filePath isEqualToString:@"Paste/Drag"]) && [[NSFileManager defaultManager] fileExistsAtPath:filePath]){
        fs_path = [[NSFileManager defaultManager] fileSystemRepresentationWithPath:filePath];
    }else{
        tempFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]];
        [itemString writeToFile:tempFilePath atomically:YES];
        fs_path = [[NSFileManager defaultManager] fileSystemRepresentationWithPath:tempFilePath];
    }
    infile = fopen(fs_path, "r");

    *hadProblems = NO;

    NS_DURING
        [itemString getCString:buf];
    NS_HANDLER
        // if we couldn't convert it, we won't be able to read it: just give up.
        // maybe instead of giving up we should find a way to use lossyCString here... ?
        if ([[localException name] isEqualToString:NSCharacterConversionException]) {
            NSLog(@"Exception %@ raised in itemsFromString, handled by giving up.", [localException name]);
            itemString = @"";
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
                                annoteDelim = buf[cidx];
                                buf[cidx] = '\0';
                                s = [NSString stringWithCString:&buf[field->down->offset]];
                                buf[cidx] = annoteDelim;
                            }else{
                                *hadProblems = YES;
                            }
                        }else{
                            s = [NSString stringWithCString:bt_get_text(field)];
                        }

                        // Now that we have the string from the file, check for invalid characters:
                        
                        //Begin check for valid characters (ASCII); otherwise we mangle the .bib file every time we write out
                        //by inserting two characters for every extended character.  All we do is pop up the corrupted file
                        //dialog and give the user the option to continue; it would be nice if we could pass the line no. too.

                        // Note (mmcc) : This is necessary only when CharacterConversion.plist doesn't cover a character that's in the file - this may be fixable in BDSKConverter also.
                        
                        NSScanner *validscan;
                        NSString *validscanstring = nil;
                                                
                        validscan = [NSScanner scannerWithString:s];  //Scan string s after we get it from bt

                        [validscan scanCharactersFromSet:EnglishLetters intoString:&validscanstring];
                        
                        if([validscanstring length] != [s length]) //Compare it to the original string
                        {
                            NSLog(@"I am string s: [%@]",s);
                            NSLog(@"I am validscanstring: [%@]",validscanstring);
                            *hadProblems = YES;
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
        free(buf);
        return returnArray;
}


@end
