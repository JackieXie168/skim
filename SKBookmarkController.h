//
//  SKBookmarkController.h
//  Skim
//
//  Created by Christiaan Hofman on 3/16/07.
/*
 This software is Copyright (c) 2007-2014
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

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import "SKWindowController.h"
#import "SKOutlineView.h"

@class SKBookmark, SKStatusBar;

@interface SKBookmarkController : SKWindowController <NSWindowDelegate, NSToolbarDelegate, NSMenuDelegate, SKOutlineViewDelegate, QLPreviewPanelDataSource, QLPreviewPanelDelegate> {
    SKOutlineView *outlineView;
    SKStatusBar *statusBar;
    SKBookmark *bookmarkRoot;
    SKBookmark *previousSession;
    NSMutableArray *recentDocuments;
    NSUndoManager *undoManager;
    NSArray *draggedBookmarks;
    NSDictionary *toolbarItems;
}

+ (id)sharedBookmarkController;

@property (nonatomic, retain) IBOutlet SKOutlineView *outlineView;
@property (nonatomic, retain) IBOutlet SKStatusBar *statusBar;
@property (nonatomic, readonly) SKBookmark *bookmarkRoot;
@property (nonatomic, readonly) NSArray *recentDocuments;
@property (nonatomic, readonly) NSUndoManager *undoManager;

- (IBAction)openBookmark:(id)sender;

- (IBAction)doubleClickBookmark:(id)sender;
- (IBAction)insertBookmarkFolder:(id)sender;
- (IBAction)insertBookmarkSeparator:(id)sender;
- (IBAction)addBookmark:(id)sender;
- (IBAction)deleteBookmark:(id)sender;
- (IBAction)toggleStatusBar:(id)sender;

- (void)addRecentDocumentForURL:(NSURL *)fileURL pageIndex:(NSUInteger)pageIndex snapshots:(NSArray *)setups;
- (NSUInteger)pageIndexForRecentDocumentAtURL:(NSURL *)fileURL;
- (NSArray *)snapshotsForRecentDocumentAtURL:(NSURL *)fileURL;

@end
