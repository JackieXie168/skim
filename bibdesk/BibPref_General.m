//  BibPref_Startup.m

//  Created by Michael McCracken on Sat Jun 01 2002.
/*
 This software is Copyright (c) 2002, Michael O. McCracken
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 -  Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 -  Neither the name of Michael O. McCracken nor the names of any contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "BibPref_General.h"


@implementation BibPref_General

- (void)awakeFromNib{
    [super awakeFromNib];
	
	
	[[NSNotificationCenter defaultCenter]
addObserver:self
   selector:@selector(handleFontChangedNotification:)
       name:BDSKTableViewFontChangedNotification
     object:nil];
}




- (void)updateUI{
    [startupBehaviorRadio selectCellWithTag:[[defaults objectForKey:BDSKStartupBehaviorKey] intValue]];
	
	[self updateButtonForAutoOpenFile:[defaults objectForKey:BDSKDefaultBibFilePathKey]];
	
    prevStartupBehaviorTag = [[defaults objectForKey:BDSKStartupBehaviorKey] intValue];
    [showErrorsCheckButton setState: 
		([defaults boolForKey:BDSKShowWarningsKey] == YES) ? NSOnState : NSOffState  ];	
	
	NSFont *tableViewFont = [NSFont fontWithName:[defaults objectForKey:BDSKTableViewFontKey]
												size:[defaults floatForKey:BDSKTableViewFontSizeKey]];
		
		[fontPreviewField setStringValue:[[tableViewFont displayName] stringByAppendingFormat:@" %.0f",[tableViewFont pointSize]]];
		[fontPreviewField setFont:tableViewFont];
		
		[displayPrefRadioMatrix selectCellWithTag:[defaults integerForKey:BDSKPreviewDisplayKey]];
		
		[editOnPasteButton setState:[defaults integerForKey:BDSKEditOnPasteKey]];

}



- (void)setValueForSender:(id)sender{
    // ?
}


- (void)becomeCurrentPreferenceClient{
	//    NSLog(@"not sure - becomecurrent");
}
- (void)resignCurrentPreferenceClient{
	//    NSLog(@"not sure - resigncurrent");
}

- (IBAction)toggleShowWarnings:(id)sender{
    BibAppController *ac = (BibAppController *)[NSApp delegate];
    [defaults setBool:([sender state] == NSOnState) ? YES : NO forKey:BDSKShowWarningsKey];
    if ([sender state] == NSOnState) {
        [ac showErrorPanel:self];
    }else{
        [ac hideErrorPanel:self];
    }        
}

- (IBAction)changeStartupBehavior:(id)sender{
    int n = [[sender selectedCell] tag];
    [defaults setObject:[NSNumber numberWithInt:n] forKey:BDSKStartupBehaviorKey];
    
    if (n == 3) {
        NSOpenPanel * openPanel = [NSOpenPanel openPanel];
		[openPanel beginSheetForDirectory:nil file:nil types:[NSArray arrayWithObject:@"bib"] modalForWindow:[sender window] modalDelegate: self didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:) contextInfo:NULL];
    }else{
        prevStartupBehaviorTag = n;
    }
    [defaults synchronize];
}


/*
	Invoked by the choose button for the 'auto open bibliography' radio button
	Simply simulates a click on the radio button.
*/ 
-(IBAction) chooseAutoOpenFile:(id) sender {
	[startupBehaviorRadio selectCellWithTag:3];	
	[startupBehaviorRadio performClick:self];
}


/*
 finishing off the open panel for selecting the file to open on startup
 
 -> re-sets the previous behaviour if the user cancels
 -> sets the 'auto open' behaviour otherwise and adjusts the corresponding button's text
*/
- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	if (returnCode == NSCancelButton)
	{
		[startupBehaviorRadio selectCellWithTag:prevStartupBehaviorTag];
		return;
	}
	NSString * path = [[sheet filenames] objectAtIndex: 0];
	[self updateButtonForAutoOpenFile:path];
	
	[defaults setObject:path forKey:BDSKDefaultBibFilePathKey];
	[defaults setObject:path forKey:@"NSOpen"]; // -- what did this do?		
}



/*
	Updates the UI to reflect the file setup for auto-opening on startup
	This is called from both -openPanelDidEnd and -updateUI
*/
- (void) updateButtonForAutoOpenFile:(NSString*) path {
	NSCell * autoOpenRadioButton = [startupBehaviorRadio cellWithTag:3];

	// change title to reflect the file name
	[autoOpenRadioButton setTitle:[NSString stringWithFormat:NSLocalizedString(@"Open Bibliography \"%@\"",@"Open bibliography %@ (should be the same as the radio button in the general preference, don't forget to use curly quotes)"), [path lastPathComponent]]];
	
	// change the tool tip to reflect the whole path
	[startupBehaviorRadio setToolTip:path forCell:autoOpenRadioButton];
}



- (IBAction)changePreviewDisplay:(id)sender{
    int tag = [[sender selectedCell] tag];
    if(tag != [defaults integerForKey:BDSKPreviewDisplayKey]){
        switch(tag){
            case 0:
                // show everything
                [defaults setInteger:tag forKey:BDSKPreviewDisplayKey];
                break;
            case 1:
                // show only annote
                [defaults setInteger:tag forKey:BDSKPreviewDisplayKey];
                break;
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:BDSKPreviewDisplayChangedNotification object:nil];
	}
}

- (IBAction)changeShownColumns:(id)sender{
    // 0,1,2,3,4,5 = citekey, title(shouldn't change), date,auth1,auth2,auth3
    int n = [[sender selectedCell] tag];
    if([[sender selectedCell] state] == NSOnState){
        [showColsArray replaceObjectAtIndex:n
                                 withObject:[NSNumber numberWithInt:1]];
    }else{
        [showColsArray replaceObjectAtIndex:n
                                 withObject:[NSNumber numberWithInt:0]];
    }
    [defaults setObject:showColsArray forKey:BDSKShowColsKey];
    [[[NSDocumentController sharedDocumentController] documents]
makeObjectsPerformSelector:@selector(updateUI)];
}


- (IBAction)chooseFont:(id)sender{
    NSFont *oldFont = [NSFont fontWithName:
        [defaults objectForKey:BDSKTableViewFontKey]
                                      size:
        [defaults floatForKey:BDSKTableViewFontSizeKey]];
    [[NSFontManager sharedFontManager] setSelectedFont:oldFont isMultiple:NO];
    [[NSFontManager sharedFontManager] orderFrontFontPanel:self];
}


- (void)handleFontChangedNotification:(NSNotification *)notification{
    NSFont *font =
    [NSFont fontWithName:[defaults objectForKey:BDSKTableViewFontKey]
                    size:[defaults floatForKey:BDSKTableViewFontSizeKey]];
    //NSLog(@"%@", font);
    [fontPreviewField setStringValue:
        [[font displayName] stringByAppendingFormat:@" %.0f",[font pointSize]]];
    [fontPreviewField setFont:font];
}



// changeFont is deprecated here.
// this same code (mostly) is in the BibAppController now.
// we just listen for a notification about the font change so we can change the previewfield.
- (void)changeFont:(id)fontManager{
    NSFont *newFont;
    NSFont *oldFont =
        [NSFont fontWithName:[defaults objectForKey:BDSKTableViewFontKey]
                        size:[defaults floatForKey:BDSKTableViewFontSizeKey]];
	
    newFont = [[NSFontPanel sharedFontPanel] panelConvertFont:oldFont];
    [defaults setObject:[newFont fontName] forKey:BDSKTableViewFontKey];
    [defaults setFloat:[newFont pointSize] forKey:BDSKTableViewFontSizeKey];
    [fontPreviewField setStringValue:
        [[newFont displayName] stringByAppendingFormat:@" %.0f",[newFont pointSize]]];
    // make it have live updates:
    //  [[[NSDocumentController sharedDocumentController] documents]
    //makeObjectsPerformSelector:@selector(updateUI)];
	[[NSNotificationCenter defaultCenter] postNotificationName:BDSKTableViewFontChangedNotification
														object:nil];
}


- (IBAction)changeEditOnPaste:(id)sender{
    [defaults setInteger:[sender state] forKey:BDSKEditOnPasteKey];
}




- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

@end
