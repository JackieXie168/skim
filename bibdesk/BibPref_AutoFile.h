//
//  BibPref_AutoFile.h
//  BibDesk
//
//  Created by Michael McCracken on Wed Oct 08 2003.

/*
 This software is Copyright (c) 2003,2004,2005
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

#import <Foundation/Foundation.h>
#import "BibPrefController.h"
#import "BibItem.h"

@interface BibPref_AutoFile : OAPreferenceClient {
	IBOutlet NSTextField* papersFolderLocationTextField;
	IBOutlet NSButton* choosePapersFolderLocationButton;
	IBOutlet NSButton* filePapersAutomaticallyCheckButton;
    IBOutlet NSTextField *formatField;
    IBOutlet NSPopUpButton *formatPresetPopUp;
    IBOutlet NSPopUpButton *formatRepositoryPopUp;
    IBOutlet NSButton *formatWarningButton;
    IBOutlet NSButton *formatLowercaseCheckButton;
	IBOutlet NSTextField *previewTextField;
	IBOutlet NSMatrix *formatCleanRadio;
}

- (IBAction)choosePapersFolderLocationAction:(id)sender;
- (IBAction)toggleFilePapersAutomaticallyAction:(id)sender;
- (IBAction)localUrlFormatChanged:(id)sender;
- (IBAction)changeLocalUrlLowercase:(id)sender;
- (IBAction)setFormatCleanOption:(id)sender;
- (IBAction)localUrlFormatAdd:(id)sender;
- (IBAction)formatHelp:(id)sender;
- (IBAction)showLocalUrlFormatWarning:(id)sender;
- (void)setLocalUrlFormatInvalidWarning:(BOOL)set message:message;

@end
