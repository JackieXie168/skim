//
//  SKDownloadPreferenceController.m
//  Skim
//
//  Created by Christiaan Hofman on 3/29/10.
/*
 This software is Copyright (c) 2010-2014
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

#import "SKDownloadPreferenceController.h"
#import "NSGraphics_SKExtensions.h"
#import "NSMenu_SKExtensions.h"
#import "SKStringConstants.h"


@implementation SKDownloadPreferenceController

@synthesize checkButtons, doneButton, downloadsFolderPopUp, downloadsFolderLabelField;

- (void)dealloc {
    SKDESTROY(checkButtons);
    SKDESTROY(doneButton);
    SKDESTROY(downloadsFolderPopUp);
    SKDESTROY(downloadsFolderLabelField);
    [super dealloc];
}

- (NSString *)windowNibName {
    return @"DownloadPreferenceSheet";
}

- (void)updateDownloadsFolderPopUp {
    NSString *downloadsFolder = [[[NSUserDefaults standardUserDefaults] stringForKey:SKDownloadsDirectoryKey] stringByExpandingTildeInPath];
    NSMenuItem *menuItem = [downloadsFolderPopUp itemAtIndex:0];
    [menuItem setImageAndSize:[[NSWorkspace sharedWorkspace] iconForFile:downloadsFolder]];
    [menuItem setTitle:[[NSFileManager defaultManager] displayNameAtPath:downloadsFolder]];
    [downloadsFolderPopUp selectItemAtIndex:0];
}

- (void)windowDidLoad {
    SKAutoSizeButtons([NSArray arrayWithObjects:doneButton, nil], YES);
    
    NSRect frame = [[self window] frame];
    frame.size.width = 0.0;
    for (NSButton *button in checkButtons) {
        [button sizeToFit];
        frame.size.width = fmax(NSWidth(frame), NSMaxX([button frame]));
    }
    frame.size.width += 18.0;
    [[self window] setFrame:frame display:NO];
    
    SKAutoSizeLabelField(downloadsFolderLabelField, downloadsFolderPopUp, YES);
    [self updateDownloadsFolderPopUp];
}

- (IBAction)chooseDownloadsFolder:(id)sender {
    if ([sender selectedItem] == [sender lastItem]) {
        [sender selectItemAtIndex:0];
        
        NSString *downloadsFolder = [[[NSUserDefaults standardUserDefaults] stringForKey:SKDownloadsDirectoryKey] stringByExpandingTildeInPath];
        NSURL *downloadsFolderURL = [NSURL fileURLWithPath:downloadsFolder];
        
        NSOpenPanel *openPanel = [NSOpenPanel openPanel];
        [openPanel setCanChooseDirectories:YES];
        [openPanel setCanChooseFiles:NO];
        [openPanel setPrompt:NSLocalizedString(@"Select", @"Button title")];
        [openPanel setDirectoryURL:downloadsFolderURL];
        [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
                if (result == NSFileHandlingPanelOKButton) {
                    [[NSUserDefaults standardUserDefaults] setObject:[[[openPanel URL] path] stringByAbbreviatingWithTildeInPath] forKey:SKDownloadsDirectoryKey];
                    [self updateDownloadsFolderPopUp];
                }
            }];
    }
}

@end
