//
//  BibPref_Files.m
//  BibDesk
//
//  Created by Adam Maxwell on 01/02/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "BibPref_Files.h"
#import "BibAppController.h"
#import "BDSKCharacterConversion.h"


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
        [ac showErrorPanel:self];
    }else{
        [ac hideErrorPanel:self];
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
