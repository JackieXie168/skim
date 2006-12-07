//
//  PubMedParser.m
//  Bibdesk
//
//  Created by Michael McCracken on Sun Nov 16 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "PubMedParser.h"


@implementation PubMedParser
+ (NSMutableArray *)itemsFromString:(NSString *)itemString
                              error:(BOOL *)hadProblems{
    return [PubMedParser itemsFromString:itemString error:hadProblems frontMatter:nil filePath:@"Paste/Drag"];
}


+ (NSMutableArray *)itemsFromString:(NSString *)itemString
                              error:(BOOL *)hadProblems
                        frontMatter:(NSMutableString *)frontMatter
                           filePath:(NSString *)filePath{
    
    BibItem *newBI = nil;
    

    int itemOrder = 1;
    BibAppController *appController = (BibAppController *)[NSApp delegate]; // used to add autocomplete entries.

    NSMutableArray *returnArray = [NSMutableArray arrayWithCapacity:1];
    
    //dictionary is the publication entry
    NSMutableDictionary *pubDict = [NSMutableDictionary dictionaryWithCapacity:6];
    const char * fs_path = NULL;
    NSString *tempFilePath = nil;
    BOOL usingTempFile = NO;

    
    if( !([filePath isEqualToString:@"Paste/Drag"]) && [[NSFileManager defaultManager] fileExistsAtPath:filePath]){
        fs_path = [[NSFileManager defaultManager] fileSystemRepresentationWithPath:filePath];
        usingTempFile = NO;
    }else{
        tempFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]];
        [itemString writeToFile:tempFilePath atomically:YES];
        fs_path = [[NSFileManager defaultManager] fileSystemRepresentationWithPath:tempFilePath];
        NSLog(@"using temporary file %@ - was it deleted?",tempFilePath);
        usingTempFile = YES;
    }
    
    // ARM:  This code came from Art Isbell to cocoa-dev on Tue Jul 10 22:13:11 2001.  Comments are his.
    //       We were using componentsSeparatedByString:@"\r", but this is not robust.  Files from ScienceDirect
    //       have \n as newlines, so this code handles those cases as well as PubMed.
    unsigned stringLength = [itemString length];  // start cocoadev
    unsigned startIndex;
    unsigned lineEndIndex = 0;
    unsigned contentsEndIndex;
    NSRange range;
    NSMutableArray *sourceLines = [NSMutableArray array];
    
    // There is more than one way to terminate this loop.  Beware of an
    // invalid termination test which might exist in this untested example :-)
    while (lineEndIndex < stringLength)
    {
	// Include only a single character in range.  Not sure whether
	// this will work with empty lines, but if not, try a length of 0.
	range = NSMakeRange(lineEndIndex, 1);
	[itemString getLineStart:&startIndex end:&lineEndIndex 
		     contentsEnd:&contentsEndIndex forRange:range];
	
	// If you want to exclude line terminators...
	[sourceLines addObject:[itemString 
	 substringWithRange:NSMakeRange(startIndex, contentsEndIndex - 
					startIndex)]];
    } // end cocoadev

    
    NSEnumerator *sourceLineE = [sourceLines objectEnumerator];
    NSString *sourceLine = nil;
    NSString *key = nil;
    NSString *bibTeXKey = nil;
    NSMutableString *wholeValue = [NSMutableString string];
    NSString *value = nil;
    BibTypeManager *typeManager = [BibTypeManager sharedManager];
    NSCharacterSet *whitespaceNewlineSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSCharacterSet *newlineSet = [NSCharacterSet characterSetWithCharactersInString:@"\n"];
    BOOL haveFAU = NO;
    BOOL usingAU = NO;
    
    NSString *prefix = nil;
    
    while(sourceLine = [sourceLineE nextObject]){
        sourceLine = [sourceLine stringByTrimmingCharactersInSet:newlineSet];
//        NSLog(@" = [%@]",sourceLine);        
        if([sourceLine length] > 5){

            prefix = [[sourceLine substringWithRange:NSMakeRange(0,4)] stringByTrimmingCharactersInSet:whitespaceNewlineSet];
            
            
            if([[sourceLine substringWithRange:NSMakeRange(4,1)] isEqualToString:@"-"]){
                // this is a "key - value" line
                
                value = [sourceLine substringWithRange:NSMakeRange(6,[sourceLine length]-6)];
                value = [value stringByTrimmingCharactersInSet:whitespaceNewlineSet];
                
                
                if([prefix isEqualToString:@"PMID"] || [prefix isEqualToString:@"TY"]){ // ARM:  PMID for Medline, TY for Elsevier-ScienceDirect.  I hope.
                    // we have a new publication
                    
                    if([[pubDict allKeys] count] > 0){
                        // and we've already seen an old one: so save the old one off -
                        
                        newBI = [[BibItem alloc] initWithType:@"misc"
                                                     fileType:@"PubMed"
                                                      authors:
                            [NSMutableArray arrayWithCapacity:0]];
                        [newBI setFileOrder:itemOrder];
                        itemOrder++;
                        [newBI setFields:pubDict];
                        [newBI setCiteKey:[pubDict valueForKey:@"PMID"]];
                        [returnArray addObject:[newBI autorelease]];

                    }
                    [pubDict removeAllObjects];
                    [pubDict setObject:value forKey:prefix];
		    // reset these for the next pub
		    haveFAU = NO;
		    usingAU = NO;
                    
                }else{
                    // we just have a new key in the same publication.
                    // key is still the old value. prefix has the new key.
					//    NSLog(@"old key     - [%@]", key);
					//    NSLog(@"new, prefix - [%@]", prefix);
                    if(key){
						//	    NSLog(@"  inserting obj [%@] for key [%@]", wholeValue, key);
						// ARM:  I removed FAU = Author from the dictionary, because we need to discriminate between FAU and AU
						// and handle the case where AU occurs before FAU.  The final setObject: forKey: was blowing away
						// the AU values, otherwise, because it recognized FAU as Author.
						if([key isEqualToString:@"FAU"] && usingAU==NO){
						        haveFAU = YES;  // use full author info
							addAuthorName_toDict([[wholeValue copy] autorelease],pubDict);
						}else{
						    // If we didn't get a FAU key (shows up first in PubMed), fall back to AU
						    // AU is not in the dictionary, so we don't get confused with FAU
						    if([key isEqualToString:@"AU"] && haveFAU==NO){
							usingAU = YES;  // use AU info, and put FAU in its own field if it occurred too late
							addAuthorName_toDict([[wholeValue copy] autorelease],pubDict);
						    }else{
						    if([key isEqualToString:@"Keywords"]){
							addKeywordString_toDict([[wholeValue copy] autorelease],pubDict);
						    }else{
						        [pubDict setObject:[[wholeValue copy] autorelease] forKey:key];
						    }
						  }
					        }
                    }
                    
                    [wholeValue setString:value];
                    
                    bibTeXKey = [typeManager fieldNameForPubMedTag:prefix];
                    if(bibTeXKey){
                        key = bibTeXKey;
                    }else{
                        key = prefix;
                    }
                    
                    key = [key stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                }

            }else{
                [wholeValue appendString:@" "];
                [wholeValue appendString:[sourceLine stringByTrimmingCharactersInSet:whitespaceNewlineSet]];
                // NSLog(@"cont. [%@]", sourceLine);
            }
            
        }
    }
    if([[pubDict allKeys] count] > 0){
        newBI = [[BibItem alloc] initWithType:@"misc"
                                     fileType:@"PubMed"
                                      authors:
            [NSMutableArray arrayWithCapacity:0]];
        [newBI setFileOrder:itemOrder];
        itemOrder++;
        [newBI setFields:pubDict];
        [returnArray addObject:[newBI autorelease]];
        [newBI setCiteKey:[pubDict valueForKey:@"PMID"]];
        
    }
    //    NSLog(@"pubDict is %@", pubDict);
    *hadProblems = NO;
    return returnArray;
}

void addAuthorName_toDict(NSString *wholeValue, NSMutableDictionary *pubDict){
	NSString *oldAuthString = [pubDict objectForKey:@"Author"];
	if(!oldAuthString){
		[pubDict setObject:wholeValue forKey:@"Author"];
	}else{
		NSString *newAuthString = [NSString stringWithFormat:@"%@ and %@", oldAuthString, wholeValue];
		[pubDict setObject:newAuthString forKey:@"Author"];
	}
}

void addKeywordString_toDict(NSString *wholeValue, NSMutableDictionary *pubDict){
	NSString *oldKeywordString = [pubDict objectForKey:@"Keywords"];
	if(!oldKeywordString){
		[pubDict setObject:wholeValue forKey:@"Keywords"];
	}else{
		NSString *newKeywordString = [NSString stringWithFormat:@"%@, %@", oldKeywordString, wholeValue];
		[pubDict setObject:newKeywordString forKey:@"Keywords"];
	}
}


@end
