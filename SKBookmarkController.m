//
//  SKBookmarkController.m
//  Skim
//
//  Created by Christiaan Hofman on 3/16/07.
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

#import "SKBookmarkController.h"
#import "BDAlias.h"
#import "SKDocument.h"
#import "SKMainWindowController.h"
#import "Files_SKExtensions.h"

@implementation SKBookmarkController

static unsigned int maxRecentDocumentsCount = 0;

+ (void)initialize {
    [NSValueTransformer setValueTransformer:[[[SKPageIndexTransformer alloc] init] autorelease] forName:@"SKPageIndexTransformer"];
    [NSValueTransformer setValueTransformer:[[[SKAliasDataTransformer alloc] init] autorelease] forName:@"SKAliasDataTransformer"];
    
    maxRecentDocumentsCount = [[NSUserDefaults standardUserDefaults] integerForKey:@"SKMaximumDocumentPageHistoryCount"];
    if (maxRecentDocumentsCount == 0)
        maxRecentDocumentsCount = 50;
}

+ (id)sharedBookmarkController {
    static SKBookmarkController *sharedBookmarkController = nil;
    if (sharedBookmarkController == nil)
        sharedBookmarkController = [[self alloc] init];
    return sharedBookmarkController;
}

- (id)init {
    if (self = [super init]) {
        bookmarks = [[NSMutableArray alloc] init];
        recentDocuments = [[NSMutableArray alloc] init];
        
        NSData *data = [NSData dataWithContentsOfFile:[self bookmarksFilePath]];
        if (data) {
            NSString *error = nil;
            NSPropertyListFormat format = NSPropertyListXMLFormat_v1_0;
            id plist = [NSPropertyListSerialization propertyListFromData:data
                                                        mutabilityOption:NSPropertyListImmutable
                                                                  format:&format 
                                                        errorDescription:&error];
            
            if (error) {
                NSLog(@"Error deserializing: %@", error);
                [error release];
            } else if ([plist isKindOfClass:[NSDictionary class]]) {
                [bookmarks addObjectsFromArray:[plist objectForKey:@"bookmarks"]];
                [recentDocuments addObjectsFromArray:[plist objectForKey:@"recentDocuments"]];
            }
        }
    }
    return self;
}

- (void)dealloc {
    [bookmarks release];
    [recentDocuments release];
    [super dealloc];
}

- (NSString *)windowNibName { return @"BookmarksWindow"; }

- (NSArray *)bookmarks {
    return bookmarks;
}

- (void)setBookmarks:(NSArray *)newBookmarks {
    return [bookmarks setArray:newBookmarks];
}

- (unsigned)countOfBookmarks {
    return [bookmarks count];
}

- (id)objectInBookmarksAtIndex:(unsigned)index {
    return [bookmarks objectAtIndex:index];
}

- (void)insertObject:(id)obj inBookmarksAtIndex:(unsigned)index {
    [bookmarks insertObject:obj atIndex:index];
    [self saveBookmarks];
}

- (void)removeObjectFromBookmarksAtIndex:(unsigned)index {
    [bookmarks removeObjectAtIndex:index];
    [self saveBookmarks];
}

- (void)addBookmarkForPath:(NSString *)path pageIndex:(unsigned)pageIndex label:(NSString *)label {
    if (path == nil)
        return;
    NSData *data = [[BDAlias aliasWithPath:path] aliasData];
    NSMutableDictionary *bm = [NSMutableDictionary dictionaryWithObjectsAndKeys:path, @"path", label, @"label", [NSNumber numberWithUnsignedInt:pageIndex], @"pageIndex", data, @"_BDAlias", nil];
    [[self mutableArrayValueForKey:@"bookmarks"] addObject:bm];
}

- (NSArray *)recentDocuments {
    return recentDocuments;
}

- (unsigned int)indexOfRecentDocumentAtPath:(NSString *)path {
    unsigned int index = [[recentDocuments valueForKey:@"path"] indexOfObject:path];
    if (index == NSNotFound) {
        unsigned int i, iMax = [recentDocuments count];
        for (i = 0; i < iMax; i++) {
            NSData *aliasData = [[recentDocuments objectAtIndex:i] valueForKey:@"_BDAlias"];
            if ([[[BDAlias aliasWithData:aliasData] fullPathNoUI] isEqualToString:path]) {
                index = i;
                break;
            }
        }
    }
    return index;
}

- (void)addRecentDocumentForPath:(NSString *)path pageIndex:(unsigned)pageIndex snapshots:(NSArray *)setups {
    if (path == nil)
        return;
    
    unsigned int index = [self indexOfRecentDocumentAtPath:path];
    if (index != NSNotFound)
        [recentDocuments removeObjectAtIndex:index];
    
    NSData *data = [[BDAlias aliasWithPath:path] aliasData];
    NSMutableDictionary *bm = [NSMutableDictionary dictionaryWithObjectsAndKeys:path, @"path", [NSNumber numberWithUnsignedInt:pageIndex], @"pageIndex", data, @"_BDAlias", [setups count] ? setups : nil, @"snapshots", nil];
    [recentDocuments insertObject:bm atIndex:0];
    if ([recentDocuments count] > maxRecentDocumentsCount)
        [recentDocuments removeLastObject];
    
    [self saveBookmarks];
}

- (unsigned int)pageIndexForRecentDocumentAtPath:(NSString *)path {
    if (path == nil)
        return NSNotFound;
    unsigned int index = [self indexOfRecentDocumentAtPath:path];
    return index == NSNotFound ? NSNotFound : [[[recentDocuments objectAtIndex:index] objectForKey:@"pageIndex"] unsignedIntValue];
}

- (NSArray *)snapshotsAtPath:(NSString *)path {
    if (path == nil)
        return nil;
    unsigned int index = [self indexOfRecentDocumentAtPath:path];
    NSArray *setups = index == NSNotFound ? nil : [[recentDocuments objectAtIndex:index] objectForKey:@"snapshots"];
    return [setups count] ? setups : nil;
}

- (void)saveBookmarks {
    NSDictionary *bookmarksDictionary = [NSDictionary dictionaryWithObjectsAndKeys:bookmarks, @"bookmarks", recentDocuments, @"recentDocuments", nil];
    NSString *error = nil;
    NSPropertyListFormat format = NSPropertyListXMLFormat_v1_0;
    NSData *data = [NSPropertyListSerialization dataFromPropertyList:bookmarksDictionary format:format errorDescription:&error];
    
	if (error) {
		NSLog(@"Error deserializing: %@", error);
        [error release];
	} else {
        [data writeToFile:[self bookmarksFilePath] atomically:YES];
    }
}

- (NSString *)bookmarksFilePath {
    static NSString *bookmarksPath = nil;
    
    if (bookmarksPath == nil) {
        NSString *prefsPath = nil;
        FSRef foundRef;
        OSStatus err = noErr;
        
        err = FSFindFolder(kUserDomain,  kPreferencesFolderType, kCreateFolder, &foundRef);
        if (err != noErr) {
            NSLog(@"Error %d:  the system was unable to find your Preferences folder.", err);
            return nil;
        }
        
        CFURLRef url = CFURLCreateFromFSRef(kCFAllocatorDefault, &foundRef);
        
        if (url != nil) {
            prefsPath = [(NSURL *)url path];
            CFRelease(url);
            
            NSString *bundleIdentifier = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleIdentifierKey];
            
            bookmarksPath = [[[prefsPath stringByAppendingPathComponent:[bundleIdentifier stringByAppendingString:@".bookmarks"]] stringByAppendingPathExtension:@"plist"] copy];
        }
        
    }
    
    return bookmarksPath;
}

- (void)controlTextDidEndEditing:(NSNotification *)notification {
    [self saveBookmarks];
}

- (void)openBookmarks:(NSArray *)items {
    NSEnumerator *bmEnum = [items objectEnumerator];
    NSDictionary *bm;
    
    while (bm = [bmEnum nextObject]) {
        id document = nil;
        NSURL *fileURL = [[BDAlias aliasWithData:[bm objectForKey:@"_BDAlias"]] fileURL];
        NSError *error;
        
        if (fileURL == nil && [bm objectForKey:@"path"])
            fileURL = [NSURL fileURLWithPath:[bm objectForKey:@"path"]];
        if (fileURL && NO == SKFileIsInTrash(fileURL)) {
            if (document = [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:fileURL display:YES error:&error]) {
                [[document mainWindowController] setPageNumber:[[bm objectForKey:@"pageIndex"] unsignedIntValue] + 1];
            } else {
                [NSApp presentError:error];
            }
        }
    }
}

@end


@implementation SKPageIndexTransformer

+ (Class)transformedValueClass {
    return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation {
    return NO;
}

- (id)transformedValue:(id)number {
    return [NSNumber numberWithUnsignedInt:[number unsignedIntValue] + 1];
}

@end


@implementation SKAliasDataTransformer

+ (Class)transformedValueClass {
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation {
    return NO;
}

- (id)transformedValue:(id)dictionary {
    NSString *path = [[BDAlias aliasWithData:[dictionary valueForKey:@"_BDAlias"]] fullPathNoUI];
    if (path == nil)
        path = [dictionary valueForKey:@"path"];
    return path;
}

@end
