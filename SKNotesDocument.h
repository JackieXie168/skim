//
//  SKNotesDocument.h
//  Skim
//
//  Created by Christiaan Hofman on 4/10/07.
/*
 This software is Copyright (c) 2007-2009
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
#import "SKNoteOutlineView.h"

@class SKNoteOutlineView, SKStatusBar;

@interface SKNotesDocument : NSDocument <NSWindowDelegate, NSToolbarDelegate, SKNoteOutlineViewDelegate, NSOutlineViewDataSource> {
    IBOutlet SKNoteOutlineView *outlineView;
    IBOutlet NSArrayController *arrayController;
    IBOutlet SKStatusBar *statusBar;
    IBOutlet NSSearchField *searchField;
    NSMutableDictionary *toolbarItems;
    NSMutableArray *notes;
    NSMapTable *rowHeights;
    BOOL exportUsingPanel;
    BOOL caseInsensitiveSearch;
}

- (IBAction)openPDF:(id)sender;
- (IBAction)searchNotes:(id)sender;
- (IBAction)toggleStatusBar:(id)sender;
- (IBAction)toggleCaseInsensitiveSearch:(id)sender;
 
- (NSArray *)notes;
- (NSUInteger)countOfNotes;
- (NSDictionary *)objectInNotesAtIndex:(NSUInteger)index;
- (void)insertObject:(NSDictionary *)note inNotesAtIndex:(NSUInteger)index;
- (void)removeObjectFromNotesAtIndex:(NSUInteger)index;

- (void)setupToolbar:(NSWindowController *)aController;

@end
