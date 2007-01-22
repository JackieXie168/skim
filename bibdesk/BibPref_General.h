//  BibPref_General.h
//  BibDesk 
//  Created by Michael McCracken on Sat Jun 01 2002.
/*
 This software is Copyright (c) 2002,2003,2004,2005,2006,2007
 Michael O. McCracken. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

 - Neither the name of Michael O. McCracken nor the names of any
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
#import "BibAppController.h"

@interface BibPref_General : OAPreferenceClient {
    IBOutlet NSMatrix *startupBehaviorRadio;
    int prevStartupBehaviorTag;
	
    IBOutlet NSPopUpButton *emailTemplatePopup;
	IBOutlet NSButton* editOnPasteButton;
    IBOutlet NSPopUpButton *checkForUpdatesButton;
    IBOutlet NSButton *warnOnDeleteButton;
    IBOutlet NSButton *warnOnRemovalFromGroupButton;
    IBOutlet NSButton *warnOnRenameGroupButton;
    IBOutlet NSButton *warnOnGenerateCiteKeysButton;
    IBOutlet NSTextField *defaultBibFileTextField;
    IBOutlet NSButton *defaultBibFileButton;

}

- (IBAction)setAutoOpenFilePath:(id)sender;
- (IBAction)changeStartupBehavior:(id)sender;
- (IBAction)changeEmailTemplate:(id)sender;
- (IBAction)chooseAutoOpenFile:(id) sender;
- (IBAction)changeUpdateInterval:(id)sender;
- (IBAction)changeEditOnPaste:(id)sender;
- (IBAction)changeWarnOnDelete:(id)sender;
- (IBAction)changeWarnOnRemovalFromGroup:(id)sender;
- (IBAction)changeWarnOnRenameGroup:(id)sender;
- (IBAction)changeWarnOnGenerateCiteKeys:(id)sender;

- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)handleWarningPrefChanged:(NSNotification *)notification;
- (void)handleTemplatePrefsChanged:(NSNotification *)notification;

@end
