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


@implementation SKBookmarkController

+ (id)sharedBookmarkController {
    static SKBookmarkController *sharedBookmarkController = nil;
    if (sharedBookmarkController == nil)
        sharedBookmarkController = [[self alloc] init];
    return sharedBookmarkController;
}

- (id)init {
    if (self = [super init]) {
        bookmarks = [[NSMutableArray alloc] init];
        
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
            } else if ([plist isKindOfClass:[NSArray class]]) {
                [bookmarks addObjectsFromArray:plist];
            }
        }
    }
    return self;
}

- (void)dealloc {
    [bookmarks release];
    [super dealloc];
}

- (NSString *)windowNibName { return @"BookmarksWindow"; }

- (NSArray *)bookmarks {
    return [[bookmarks retain] autorelease];
}

- (void)setBookmarks:(NSArray *)newBookmarks {
    if (bookmarks != newBookmarks) {
        [bookmarks release];
        bookmarks = [newBookmarks mutableCopy];
    }
}

- (unsigned)countOfBookmarks {
    return [bookmarks count];
}

- (id)objectInBookmarksAtIndex:(unsigned)index {
    return [bookmarks objectAtIndex:index];
}

- (void)insertObject:(id)obj inBookmarksAtIndex:(unsigned)index {
    [bookmarks insertObject:obj atIndex:index];
}

- (void)removeObjectFromBookmarksAtIndex:(unsigned)index {
    [bookmarks removeObjectAtIndex:index];
}

- (void)addBookmarkForPath:(NSString *)path pageIndex:(unsigned)pageIndex label:(NSString *)label {
    NSMutableDictionary *bm = [NSMutableDictionary dictionaryWithObjectsAndKeys:path, @"path", label, @"label", [NSNumber numberWithUnsignedInt:pageIndex], @"pageIndex", nil];
    [[self mutableArrayValueForKey:@"bookmarks"] addObject:bm];
    [self saveBookmarks];
}

- (void)saveBookmarks {
    NSString *error = nil;
    NSPropertyListFormat format = NSPropertyListXMLFormat_v1_0;
    NSData *data = [NSPropertyListSerialization dataFromPropertyList:bookmarks format:format errorDescription:&error];
    
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

@end
