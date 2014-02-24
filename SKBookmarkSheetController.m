//
//  SKBookmarkSheetController.m
//  Skim
//
//  Created by Christiaan Hofman on 1/23/12.
/*
 This software is Copyright (c) 2012-2014
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

#import "SKBookmarkSheetController.h"
#import "SKBookmarkController.h"
#import "SKBookmark.h"
#import "NSMenu_SKExtensions.h"
#import "NSWindowController_SKExtensions.h"


@implementation SKBookmarkSheetController

@synthesize folderPopUp;
@dynamic selectedFolder;

- (void)dealloc {
    SKDESTROY(folderPopUp);
    [super dealloc];
}

- (NSString *)windowNibName { return @"BookmarkSheet"; }

- (void)addMenuItemsForBookmarks:(NSArray *)bookmarks level:(NSInteger)level toMenu:(NSMenu *)menu {
    for (SKBookmark *bm in bookmarks) {
        if ([bm bookmarkType] == SKBookmarkTypeFolder) {
            NSString *label = [bm label];
            NSMenuItem *item = [menu addItemWithTitle:label ?: @"" action:NULL keyEquivalent:@""];
            [item setImageAndSize:[bm icon]];
            [item setIndentationLevel:level];
            [item setRepresentedObject:bm];
            [self addMenuItemsForBookmarks:[bm children] level:level+1 toMenu:menu];
        }
    }
}

- (void)beginSheetModalForWindow:(NSWindow *)window completionHandler:(void (^)(NSInteger result))handler {
    SKBookmarkController *bookmarkController = [SKBookmarkController sharedBookmarkController];
    SKBookmark *root = [bookmarkController bookmarkRoot];
    [self window];
    [folderPopUp removeAllItems];
    [self addMenuItemsForBookmarks:[NSArray arrayWithObjects:root, nil] level:0 toMenu:[folderPopUp menu]];
    [folderPopUp selectItemAtIndex:0];
    
    [super beginSheetModalForWindow:window completionHandler:handler];
}

- (SKBookmark *)selectedFolder {
    return [[folderPopUp selectedItem] representedObject];
}

@end
