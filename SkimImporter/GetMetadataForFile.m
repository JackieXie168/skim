//
//  GetMetadataForFile.m
//  SkimImporter
//
//  Created by Christiaan Hofman on 5/21/07.
/*
 This software is Copyright (c) 2007
 Christiaan Hofman. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

 - Neither the name of Christiaan Hofman nor the names of any
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

#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

Boolean GetMetadataForFile(void* thisInterface, 
                           CFMutableDictionaryRef attributes, 
                           CFStringRef contentTypeUTI,
                           CFStringRef pathToFile)
{
    /* Pull any available metadata from the file at the specified path */
    /* Return the attribute keys and attribute values in the dict */
    /* Return TRUE if successful, FALSE if there was no data provided */
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    Boolean success = FALSE;
    NSString *notePath = nil;
    NSString *sourcePath = nil;
    
    if (UTTypeEqual(contentTypeUTI, CFSTR("net.sourceforge.skim-app.skimnotes"))) {
        notePath = (NSString *)pathToFile;
        sourcePath = [[(NSString *)pathToFile stringByDeletingPathExtension] stringByAppendingPathExtension:@"pdf"];
    } else if (UTTypeEqual(contentTypeUTI, CFSTR("net.sourceforge.skim-app.pdfd"))) {
        notePath = [(NSString *)pathToFile stringByAppendingPathComponent:@"data.skim"];
    }
    
    if (notePath && [[NSFileManager defaultManager] fileExistsAtPath:notePath]) {
        NSData *data = [[NSData alloc] initWithContentsOfFile:notePath options:NSUncachedRead error:NULL];
        if (data) {
            NSArray *array = [NSKeyedUnarchiver unarchiveObjectWithData:data];
            [data release];
            
            if (array) {
                NSEnumerator *noteEnum = [array objectEnumerator];
                NSDictionary *note;
                NSMutableString *textContent = [[NSMutableString alloc] init];
                NSMutableArray *notes = [[NSMutableArray alloc] init];
                while (note = [noteEnum nextObject]) {
                    NSString *contents = [note objectForKey:@"contents"];
                    if (contents) {
                        if ([textContent length])
                            [textContent appendString:@"\n\n"];
                        [textContent appendString:contents];
                        [notes addObject:contents];
                    }
                    NSString *text = [[note objectForKey:@"text"] string];
                    if (text) {
                        if ([textContent length])
                            [textContent appendString:@"\n\n"];
                        [textContent appendString:text];
                    }
                }
                [(NSMutableDictionary *)attributes setObject:textContent forKey:(NSString *)kMDItemTextContent];
                [(NSMutableDictionary *)attributes setObject:notes forKey:@"net_sourceforge_skim_app_notes"];
                [textContent release];
                [notes release];
            }
        }
        
        [(NSMutableDictionary *)attributes setObject:@"Skim" forKey:(NSString *)kMDItemCreator];
        
        if (sourcePath && [[NSFileManager defaultManager] fileExistsAtPath:sourcePath])
            [(NSMutableDictionary *)attributes setObject:[NSArray arrayWithObjects:sourcePath, nil] forKey:(NSString *)kMDItemWhereFroms];
        
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] fileAttributesAtPath:(NSString *)pathToFile traverseLink:YES];
        NSDate *date;
        if (date = [fileAttributes objectForKey:NSFileModificationDate])
            [(NSMutableDictionary *)attributes setObject:date forKey:(NSString *)kMDItemContentModificationDate];
        if (date = [fileAttributes objectForKey:NSFileCreationDate])
            [(NSMutableDictionary *)attributes setObject:date forKey:(NSString *)kMDItemContentCreationDate];
        
        success = TRUE;
    } else {
        NSLog(@"Importer asked to handle unknown UTI %@ at path", contentTypeUTI, pathToFile);
    }
    
    [pool release];
    
    return success;
}
