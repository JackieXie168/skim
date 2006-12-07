//
//  BibPref_InputManager.h
//  BibDesk
//
//  Created by Adam Maxwell on Fri Aug 27 2004.
//  Copyright (c) 2004 Adam R. Maxwell. All rights reserved.
/*
 This software is Copyright (c) 2004,2005,2006
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
#import <OmniAppKit/OAGradientTableView.h>
#import <OmniAppKit/OATextWithIconCell.h>

@interface BibPref_InputManager : OAPreferenceClient
{
    IBOutlet OAGradientTableView *tableView;
    IBOutlet NSButton *enableButton;
    IBOutlet NSArrayController *arrayController;
    NSString *inputManagerPath;
    NSMutableArray *applications;
}

- (void)addApplicationsWithIdentifiers:(NSArray *)identifiers;
- (void)synchronizePreferences;

- (IBAction)enableAutocompletion:(id)sender;
- (IBAction)addApplication:(id)sender;
- (IBAction)removeApplication:(id)sender;

- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;

@end
