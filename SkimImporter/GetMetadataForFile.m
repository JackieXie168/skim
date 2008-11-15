//
//  GetMetadataForFile.m
//  SkimImporter
//
//  Created by Christiaan Hofman on 5/21/07.
/*
 This software is Copyright (c) 2007-2008
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
    BOOL isSkimNotes = UTTypeEqual(contentTypeUTI, CFSTR("net.sourceforge.skim-app.skimnotes"));
    BOOL isPDFBundle = isSkimNotes == NO && UTTypeEqual(contentTypeUTI, CFSTR("net.sourceforge.skim-app.pdfd"));
    
    if (isSkimNotes) {
        notePath = (NSString *)pathToFile;
        sourcePath = [[(NSString *)pathToFile stringByDeletingPathExtension] stringByAppendingPathExtension:@"pdf"];
    } else if (isPDFBundle) {
        NSArray *files = [[NSFileManager defaultManager] subpathsAtPath:(NSString *)pathToFile];
        NSString *noteFilename = [[[(NSString *)pathToFile lastPathComponent] stringByDeletingPathExtension] stringByAppendingPathExtension:@"skim"];
        if ([files containsObject:noteFilename] == NO) {
            unsigned idx = [[files valueForKeyPath:@"pathExtension.lowercaseString"] indexOfObject:@"skim"];
            noteFilename = idx == NSNotFound ? nil : [files objectAtIndex:idx];
        }
        if (noteFilename)
            notePath = [(NSString *)pathToFile stringByAppendingPathComponent:noteFilename];
    }
    
    if (notePath && [[NSFileManager defaultManager] fileExistsAtPath:notePath]) {
        NSMutableString *textContent = [[NSMutableString alloc] init];
        
        NSData *data = [[NSData alloc] initWithContentsOfFile:notePath options:NSUncachedRead error:NULL];
        if (data) {
            NSArray *array = [NSKeyedUnarchiver unarchiveObjectWithData:data];
            [data release];
            
            if (array) {
                NSEnumerator *noteEnum = [array objectEnumerator];
                NSDictionary *note;
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
                [(NSMutableDictionary *)attributes setObject:notes forKey:@"net_sourceforge_skim_app_notes"];
                [notes release];
            }
        }
        
        if (isPDFBundle) {
            NSString *textPath = [(NSString *)pathToFile stringByAppendingPathComponent:@"data.txt"];
            NSString *string = [NSString stringWithContentsOfFile:textPath];
            if ([string length]) {
                if ([textContent length])
                    [textContent appendString:@"\n\n"];
                [textContent appendString:string];
            }
        
            NSString *plistPath = [(NSString *)pathToFile stringByAppendingPathComponent:@"data.plist"];
            NSData *plistData = [NSData dataWithContentsOfFile:plistPath];
            NSDictionary *info = plistData ? [NSPropertyListSerialization propertyListFromData:plistData mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:NULL] : nil;
            if (info) {
                id value;
                id pageWidth = [info objectForKey:@"PageWidth"], pageHeight = [info objectForKey:@"PageHeight"];
                if (value = [info objectForKey:@"Title"])
                    [(NSMutableDictionary *)attributes setObject:value forKey:(NSString *)kMDItemTitle];
                if (value = [info objectForKey:@"Author"])
                    [(NSMutableDictionary *)attributes setObject:value forKey:(NSString *)kMDItemAuthors];
                if (value = [info objectForKey:@"Keywords"])
                    [(NSMutableDictionary *)attributes setObject:value forKey:(NSString *)kMDItemKeywords];
                if (value = [info objectForKey:@"Producer"])
                    [(NSMutableDictionary *)attributes setObject:value forKey:(NSString *)kMDItemEncodingApplications];
                if (value = [info objectForKey:@"Version"])
                    [(NSMutableDictionary *)attributes setObject:value forKey:(NSString *)kMDItemVersion];
                if (value = [info objectForKey:@"Encrypted"])
                    [(NSMutableDictionary *)attributes setObject:[value boolValue] ? @"Password Encrypted" : @"None" forKey:(NSString *)kMDItemSecurityMethod];
                if (value = [info objectForKey:@"PageCount"])
                    [(NSMutableDictionary *)attributes setObject:value forKey:(NSString *)kMDItemNumberOfPages];
                if (pageWidth && pageHeight) {
                    [(NSMutableDictionary *)attributes setObject:pageWidth forKey:(NSString *)kMDItemPageWidth];
                    [(NSMutableDictionary *)attributes setObject:pageHeight forKey:(NSString *)kMDItemPageHeight];
                    [(NSMutableDictionary *)attributes setObject:[NSString stringWithFormat:@"%@ x %@ points", pageWidth, pageHeight] forKey:@"net_sourceforge_skim_app_dimensions"];
                }
            }
        }
        
        [(NSMutableDictionary *)attributes setObject:textContent forKey:(NSString *)kMDItemTextContent];
        [textContent release];
        
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
        NSLog(@"Unable to read note path %@ when importing file %@", notePath, pathToFile);
    }
    
    [pool release];
    
    return success;
}
