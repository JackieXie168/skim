//  BibPref_General.m

//  Created by Michael McCracken on Sat Jun 01 2002.
/*
 This software is Copyright (c) 2002,2003,2004,2005
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

#import "BibPref_General.h"


@implementation BibPref_General

- (void)awakeFromNib{
    [super awakeFromNib];
        
    NSMutableArray *availableFontFamilies = [[[NSFontManager sharedFontManager] availableFontFamilies] mutableCopy];

    [previewFontPopup removeAllItems];
    [previewFontPopup addItemsWithTitles:[availableFontFamilies sortedArrayUsingSelector:@selector(compare:)]];
    [previewFontPopup selectItemWithTitle:[defaults objectForKey:BDSKPreviewPaneFontFamilyKey]];
    [availableFontFamilies release];
    
    NSMutableArray *availableFonts = [[[NSFontManager sharedFontManager] availableFonts] mutableCopy];
    
    [tableViewFontPopup removeAllItems];
    [tableViewFontPopup addItemsWithTitles:[availableFonts sortedArrayUsingSelector:@selector(compare:)]];
    [tableViewFontPopup selectItemWithTitle:[defaults objectForKey:BDSKTableViewFontKey]];
    [availableFonts release];
    
    [previewMaxNumberComboBox addItemsWithObjectValues:[NSArray arrayWithObjects:NSLocalizedString(@"All", @"All"), @"1", @"5", @"10", @"20", nil]];

}

- (IBAction)selectPreviewFont:(id)sender{
    [defaults setObject:[sender titleOfSelectedItem] forKey:BDSKPreviewPaneFontFamilyKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:BDSKPreviewPaneFontChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:BDSKPreviewDisplayChangedNotification object:nil];
}


- (void)updateUI{
    [startupBehaviorRadio selectCellWithTag:[[defaults objectForKey:BDSKStartupBehaviorKey] intValue]];
    if([[defaults objectForKey:BDSKStartupBehaviorKey] intValue] != 3)
        [defaultBibFileTextField setEnabled:NO];
    else
        [defaultBibFileTextField setEnabled:YES];
	
    [defaultBibFileTextField setStringValue:[[defaults objectForKey:BDSKDefaultBibFilePathKey] stringByAbbreviatingWithTildeInPath]];
	
    prevStartupBehaviorTag = [[defaults objectForKey:BDSKStartupBehaviorKey] intValue];
    [tableViewFontSizeField setFloatValue:[defaults floatForKey:BDSKTableViewFontSizeKey]];
    
    [displayPrefRadioMatrix selectCellWithTag:[defaults integerForKey:BDSKPreviewDisplayKey]];
	
    int maxNumber = [defaults integerForKey:BDSKPreviewMaxNumberKey];
	if (maxNumber == 0)
		[previewMaxNumberComboBox setStringValue:NSLocalizedString(@"All",@"All")];
	else 
		[previewMaxNumberComboBox setIntValue:maxNumber];
    
    [editOnPasteButton setState:[defaults boolForKey:BDSKEditOnPasteKey] ? NSOnState : NSOffState];

    [checkForUpdatesButton setState:([defaults boolForKey:BDSKAutoCheckForUpdatesKey] == YES) ? NSOnState : NSOffState];

}

- (IBAction)toggleAutoCheckForUpdates:(id)sender{
    [defaults setBool:([sender state] == NSOnState) ? YES : NO forKey:BDSKAutoCheckForUpdatesKey];
}

- (IBAction)setAutoOpenFilePath:(id)sender{
    [defaults setObject:[[sender stringValue] stringByExpandingTildeInPath] forKey:BDSKDefaultBibFilePathKey];
}

- (IBAction)changeStartupBehavior:(id)sender{
    int n = [[sender selectedCell] tag];
    [defaults setObject:[NSNumber numberWithInt:n] forKey:BDSKStartupBehaviorKey];
    [self updateUI];
    if(n == 3 && [[defaultBibFileTextField stringValue] isEqualToString:@""])
        [self chooseAutoOpenFile:nil];
}

-(IBAction) chooseAutoOpenFile:(id) sender {
    NSOpenPanel * openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel beginSheetForDirectory:nil file:nil types:[NSArray arrayWithObject:@"bib"] modalForWindow:[[OAPreferenceController sharedPreferenceController] window] modalDelegate: self didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSCancelButton)
        return;
    
    NSString * path = [[sheet filenames] objectAtIndex: 0];
    [defaultBibFileTextField setStringValue:[path stringByAbbreviatingWithTildeInPath]];    
    
    [defaults setObject:path forKey:BDSKDefaultBibFilePathKey];
    [defaults setObject:path forKey:@"NSOpen"]; // -- what did this do?
    [defaults setObject:[NSNumber numberWithInt:3] forKey:BDSKStartupBehaviorKey];
    [self updateUI];
}

- (IBAction)changePreviewDisplay:(id)sender{
    int tag = [[sender selectedCell] tag];
    if(tag != [defaults integerForKey:BDSKPreviewDisplayKey]){
        [defaults setInteger:tag forKey:BDSKPreviewDisplayKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:BDSKPreviewDisplayChangedNotification object:nil];
    }
}

- (IBAction)changePreviewMaxNumber:(id)sender{
    int maxNumber = [[[sender cell] objectValueOfSelectedItem] intValue]; // returns 0 if not a number (as in @"All")
    if(maxNumber != [defaults integerForKey:BDSKPreviewMaxNumberKey]){
		[defaults setInteger:maxNumber forKey:BDSKPreviewMaxNumberKey];
		[[NSNotificationCenter defaultCenter] postNotificationName:BDSKPreviewDisplayChangedNotification object:nil];
	}
	[self updateUI];
}

- (IBAction)chooseFont:(id)sender{
    if([sender isKindOfClass:[NSPopUpButton class]])
        [defaults setObject:[sender titleOfSelectedItem] forKey:BDSKTableViewFontKey];
    else if([sender isKindOfClass:[NSTextField class]])
        [defaults setFloat:[sender floatValue] forKey:BDSKTableViewFontSizeKey];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:BDSKTableViewFontChangedNotification
                                                        object:nil];
}

- (IBAction)changeEditOnPaste:(id)sender{
    [defaults setBool:([sender state] == NSOnState) forKey:BDSKEditOnPasteKey];
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

@end
