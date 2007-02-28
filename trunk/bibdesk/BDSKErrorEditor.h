//
//  BDSKErrorEditor.h
//  Bibdesk
//
//  Created by Christiaan Hofman on 8/21/06.
/*
 This software is Copyright (c) 2006,2007
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

@class BDSKErrorManager, BibDocument;

@interface BDSKErrorEditor : NSWindowController {
    IBOutlet NSTextView *textView;
    IBOutlet NSButton *syntaxHighlightCheckbox;
    IBOutlet NSButton *reopenButton;
    IBOutlet NSButton *reloadButton;
    IBOutlet NSTextField *lineNumberField;
    BDSKErrorManager *manager;
    NSString *fileName;
    NSData *data;
    int changeCount;
    unsigned int invalidSyntaxHighlightMark;
    BOOL enableSyntaxHighlighting;
    BOOL isPasteDrag;
}

// designated initializer
- (id)initWithFileName:(NSString *)aFileName pasteDragData:(NSData *)aData;
// for editing document source file, load and name errors
- (id)initWithFileName:(NSString *)aFileName;
// for editing Paste/Drag data
- (id)initWithPasteDragData:(NSData *)aData;

- (BDSKErrorManager *)manager;
- (void)setManager:(BDSKErrorManager *)newManager;

- (NSString *)fileName;
- (void)setFileName:(NSString *)newFileName;
- (NSString *)displayName;
- (NSData *)pasteDragData;
- (BOOL)isPasteDrag;

- (IBAction)loadFile:(id)sender;
- (IBAction)reopenDocument:(id)sender;
- (IBAction)changeSyntaxHighlighting:(id)sender;
- (IBAction)changeLineNumber:(id)sender;

- (void)gotoLine:(int)lineNumber;

- (void)handleSelectionDidChangeNotification:(NSNotification *)notification;
- (void)handleUndoManagerChangeUndoneNotification:(NSNotification *)notification;
- (void)handleUndoManagerChangeDoneNotification:(NSNotification *)notification;

@end
