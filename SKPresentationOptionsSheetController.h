//
//  SKPresentationOptionsSheetController.h
//  Skim
//
//  Created by Christiaan Hofman on 9/28/08.
/*
 This software is Copyright (c) 2008-2020
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
#import "SKWindowController.h"
#import "SKTransitionController.h"
#import "SKTableView.h"
#import "NSTouchBar_SKForwardDeclarations.h"

@class SKMainWindowController, SKThumbnail, SKTransitionInfo, SKScroller;

@interface SKPresentationOptionsSheetController : SKWindowController <NSWindowDelegate, SKTableViewDelegate, NSTableViewDataSource, NSTouchBarDelegate> {
    NSPopUpButton *notesDocumentPopUpButton;
    SKTableView *tableView;
    NSPopUpButton *stylePopUpButton;
    NSMatrix *extentMatrix;
    NSButton *okButton;
    NSButton *cancelButton;
    NSLayoutConstraint *boxLeadingConstraint;
    NSLayoutConstraint *tableWidthConstraint;
    NSArrayController *arrayController;
    BOOL separate;
    SKTransitionInfo *transition;
    NSArray *transitions;
    SKMainWindowController *controller;
    NSUndoManager *undoManager;
}

@property (nonatomic, retain) IBOutlet NSPopUpButton *notesDocumentPopUpButton;
@property (nonatomic, retain) IBOutlet SKTableView *tableView;
@property (nonatomic, retain) IBOutlet NSPopUpButton *stylePopUpButton;
@property (nonatomic, retain) IBOutlet NSMatrix *extentMatrix;
@property (nonatomic, retain) IBOutlet NSButton *okButton, *cancelButton;
@property (nonatomic, retain) IBOutlet NSLayoutConstraint *boxLeadingConstraint, *tableWidthConstraint;
@property (nonatomic, retain) IBOutlet NSArrayController *arrayController;
@property (nonatomic) BOOL separate;
@property (nonatomic, readonly) SKTransitionInfo *transition;
@property (nonatomic, copy) NSArray *transitions;
@property (nonatomic, readonly) NSArray *currentTransitions;
@property (nonatomic, readonly) NSArray *pageTransitions;
@property (nonatomic, readonly) NSDocument *notesDocument;
@property (nonatomic, readonly) NSInteger notesDocumentOffset;
@property (nonatomic, readonly) SKScroller *verticalScroller;
@property (nonatomic, readonly) NSUndoManager *undoManager;

- (id)initForController:(SKMainWindowController *)aController;

- (void)startObservingTransitions:(NSArray *)infos;
- (void)stopObservingTransitions:(NSArray *)infos;

@end
