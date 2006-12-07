//
//  BibPref_Display.h
//  Bibdesk
//
//  Created by Adam Maxwell on 07/25/05.
/*
 This software is Copyright (c) 2005,2006
 Adam Maxwell. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 
 - Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 
 - Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in
 the documentation and/or other materials provided with the
 distribution.
 
 - Neither the name of Adam Maxwell nor the names of any
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
#import "BibPrefController.h"

@interface BibPref_Display : OAPreferenceClient {
    // display pref radio matrix
    IBOutlet NSMatrix* displayPrefRadioMatrix;
    IBOutlet NSComboBox *previewMaxNumberComboBox;
    IBOutlet NSPopUpButton *previewTemplatePopup;
    
    IBOutlet NSPopUpButton *fontElementPopup;
    IBOutlet NSButton *fontButton;
    
    // sorting
    IBOutlet NSButton *addButton;
    IBOutlet NSButton *removeButton;
    IBOutlet NSTableView *tableView;
    
    IBOutlet NSMatrix *authorNameMatrix;
}

- (IBAction)changePreviewDisplay:(id)sender;
- (IBAction)changePreviewMaxNumber:(id)sender;
- (IBAction)changePreviewTemplate:(id)sender;
- (void)handlePreviewDisplayChangedNotification:(NSNotification *)notification;
- (void)handleTemplatePrefsChangedNotification:(NSNotification *)notification;

- (IBAction)addTerm:(id)sender;
- (IBAction)removeSelectedTerm:(id)sender;

- (IBAction)changeAuthorDisplay:(id)sender;

- (void)changeFont:(id)sender;
- (IBAction)changeFontElement:(id)sender;

- (NSFont *)currentFont;
- (void)setCurrentFont:(NSFont *)font;
- (void)updateFontPanel:(NSNotification *)notification;
- (void)resetFontPanel:(NSNotification *)notification;

@end


@interface OAPreferenceController (BDSKFontExtension)

- (void)localChangeFont:(id)sender;

@end
