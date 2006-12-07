//
//  BibPref_Files.m
//  BibDesk
//
//  Created by Adam Maxwell on 01/02/05.
/*
 This software is Copyright (c) 2005
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

#import "BibPref_Files.h"
#import "BibAppController.h"
#import "BDSKCharacterConversion.h"
#import "BDSKErrorObjectController.h"

@implementation BibPref_Files

- (void)awakeFromNib{
    [super awakeFromNib];
    
    encodingManager = [BDSKStringEncodingManager sharedEncodingManager];
    [encodingPopUp removeAllItems];
    [encodingPopUp addItemsWithTitles:[encodingManager availableEncodingDisplayedNames]];
}

- (void)dealloc{
    [super dealloc];
}

- (void)updateUI{
    OFPreferenceWrapper *prefs = [OFPreferenceWrapper sharedPreferenceWrapper];
    [encodingPopUp selectItemWithTitle:[encodingManager displayedNameForStringEncoding:[defaults integerForKey:BDSKDefaultStringEncodingKey]]];
    [showErrorsCheckButton setState: 
		([defaults boolForKey:BDSKShowWarningsKey] == YES) ? NSOnState : NSOffState  ];	
    [shouldTeXifyCheckButton setState:([defaults boolForKey:BDSKShouldTeXifyWhenSavingAndCopyingKey] == YES) ? NSOnState : NSOffState];
    [saveAnnoteAndAbstractAtEndButton setState:([defaults boolForKey:BDSKSaveAnnoteAndAbstractAtEndOfItemKey] == YES) ? NSOnState : NSOffState];
    [useNormalizedNamesButton setState:[defaults boolForKey:BDSKShouldSaveNormalizedAuthorNamesKey] ? NSOnState : NSOffState];
    [useTemplateFileButton setState:[defaults boolForKey:BDSKShouldUseTemplateFile] ? NSOnState : NSOffState];
    [autoSaveAsRSSButton setState:[defaults boolForKey:BDSKAutoSaveAsRSSKey] ? NSOnState : NSOffState];
}

- (IBAction)setDefaultStringEncoding:(id)sender{    
    NSStringEncoding encoding = [encodingManager stringEncodingForDisplayedName:[[sender selectedItem] title]];
    
    // NSLog(@"set encoding to %i for tag %i", [[encodingsArray objectAtIndex:[sender indexOfSelectedItem]] intValue], [sender indexOfSelectedItem]);    
    [defaults setInteger:encoding forKey:BDSKDefaultStringEncodingKey];    
}

- (IBAction)toggleShowWarnings:(id)sender{
    BibAppController *ac = (BibAppController *)[NSApp delegate];
    [defaults setBool:([sender state] == NSOnState) ? YES : NO forKey:BDSKShowWarningsKey];
    if ([sender state] == NSOnState) {
        [[BDSKErrorObjectController sharedErrorObjectController] showErrorPanel:self];
    }else{
        [[BDSKErrorObjectController sharedErrorObjectController] hideErrorPanel:self];
    }        
}

- (IBAction)toggleShouldTeXify:(id)sender{
    [defaults setBool:([sender state] == NSOnState ? YES : NO) forKey:BDSKShouldTeXifyWhenSavingAndCopyingKey];
    [self updateUI];
}

- (IBAction)toggleShouldUseNormalizedNames:(id)sender{
    [defaults setBool:([sender state] == NSOnState ? YES : NO) forKey:BDSKShouldSaveNormalizedAuthorNamesKey];
}

- (IBAction)toggleSaveAnnoteAndAbstractAtEnd:(id)sender{
    [defaults setBool:([sender state] == NSOnState ? YES : NO) forKey:BDSKSaveAnnoteAndAbstractAtEndOfItemKey];
    [self updateUI];
}

- (IBAction)toggleAutoSaveAsRSSChanged:(id)sender{
    [defaults setBool:([sender state] == NSOnState ? YES : NO) forKey:BDSKAutoSaveAsRSSKey];
}

- (IBAction)toggleShouldUseTemplateFile:(id)sender{
    [defaults setBool:([[sender selectedCell] tag] == 1 ? YES : NO) forKey:BDSKShouldUseTemplateFile];
}

- (IBAction)editTemplateFile:(id)sender{
    if(![[NSWorkspace sharedWorkspace] openFile:[[defaults stringForKey:BDSKOutputTemplateFileKey] stringByExpandingTildeInPath]])
        if(![[NSWorkspace sharedWorkspace] openFile:[[defaults stringForKey:BDSKOutputTemplateFileKey] stringByExpandingTildeInPath] withApplication:@"TextEdit"])
            NSBeep();
}

- (IBAction)showConversionEditor:(id)sender{
    [[BDSKCharacterConversion sharedConversionEditor] showWindow:self];
}

@end
