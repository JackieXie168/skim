//
//  BDSKSearchBookmarkController.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 3/26/07.
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

#import "BDSKSearchBookmarkController.h"
#import "BibPrefController.h"


@implementation BDSKSearchBookmarkController

+ (id)sharedBookmarkController {
    static BDSKSearchBookmarkController *sharedBookmarkController = nil;
    if (sharedBookmarkController == nil)
        sharedBookmarkController = [[self alloc] init];
    return sharedBookmarkController;
}

- (id)init {
    if (self = [super init]) {
        bookmarks = [[NSMutableArray alloc] init];
        NSEnumerator *bmEnum = [[[OFPreferenceWrapper sharedPreferenceWrapper] arrayForKey:BDSKSearchGroupBookmarksKey] objectEnumerator];
        NSDictionary *bm;
        
        while (bm = [bmEnum nextObject]) {
            bm = [bm mutableCopy];
            [bookmarks addObject:bm];
            [bm release];
        }
    }
    return self;
}

- (void)dealloc {
    [bookmarks release];
    [super dealloc];
}

- (NSString *)windowNibName { return @"SearchBookmarksWindow"; }

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

- (void)saveBookmarks {
    [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:bookmarks forKey:BDSKSearchGroupBookmarksKey];
}

#pragma mark tableView datasource methods

- (int)numberOfRowsInTableView:(NSTableView *)tv{
    return [bookmarks count];
}

- (id)tableView:(NSTableView *)tv objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row{
    return [[bookmarks objectAtIndex:row] objectForKey:[tableColumn identifier]];
}

- (void)tableView:(NSTableView *)tv setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(int)row{
    [[bookmarks objectAtIndex:row] setObject:object forKey:[tableColumn identifier]];
    [self saveBookmarks];
}

@end
