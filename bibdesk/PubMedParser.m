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
    
    NSString *s = nil;
    NSString *sFieldName = nil;

    int itemOrder = 1;
    BibAppController *appController = (BibAppController *)[NSApp delegate]; // used to add autocomplete entries.
    NSString *entryType = nil;
    NSMutableArray *returnArray = [NSMutableArray arrayWithCapacity:1];
    NSArray *sourceLines = nil;
    
    //dictionary is the publication entry
    NSMutableDictionary *pubDict = [NSMutableDictionary dictionaryWithCapacity:6];
    const char * fs_path = NULL;
    NSString *tempFilePath = nil;
    BOOL usingTempFile = NO;
    FILE *infile = NULL;

    
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
    

    sourceLines = [itemString componentsSeparatedByString:@"\r"];
    
    
    NSEnumerator *sourceLineE = [sourceLines objectEnumerator];
    NSString *sourceLine = nil;
    NSString *key = nil;
    NSString *bibTeXKey = nil;
    NSMutableString *wholeValue = [NSMutableString string];
    NSString *value = nil;
    BibTypeManager *typeManager = [BibTypeManager sharedManager];
    NSCharacterSet *whitespaceNewlineSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSCharacterSet *newlineSet = [NSCharacterSet characterSetWithCharactersInString:@"\n"];
    
    NSString *prefix = nil;
    
    while(sourceLine = [sourceLineE nextObject]){
        sourceLine = [sourceLine stringByTrimmingCharactersInSet:newlineSet];
        NSLog(@" = [%@]",sourceLine);        
        if([sourceLine length] > 5){

            prefix = [[sourceLine substringWithRange:NSMakeRange(0,4)] stringByTrimmingCharactersInSet:whitespaceNewlineSet];
            
            
            if([[sourceLine substringWithRange:NSMakeRange(4,1)] isEqualToString:@"-"]){
                // this is a "key - value" line
                
                value = [sourceLine substringWithRange:NSMakeRange(6,[sourceLine length]-6)];
                value = [value stringByTrimmingCharactersInSet:whitespaceNewlineSet];
                
                
                if([prefix isEqualToString:@"PMID"]){
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
                    
                }else{
                    // we just have a new key in the same publication.
                    // key is still the old value. prefix has the new key.
                    NSLog(@"old key     - [%@]", key);
                    NSLog(@"new, prefix - [%@]", prefix);
                    if(key){
                        NSLog(@"  inserting obj [%@] for key [%@]", wholeValue, key);
                        [pubDict setObject:[[wholeValue copy] autorelease] forKey:key];
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
                NSLog(@"cont. [%@]", sourceLine);
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

@end
