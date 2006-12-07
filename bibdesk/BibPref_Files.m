//
//  BibPref_Files.m
//  Bibdesk
//
//  Created by Adam Maxwell on 01/02/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "BibPref_Files.h"
#import "BibAppController.h"


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
    [encodingPopUp selectItemWithTitle:[encodingManager displayedNameForStringEncoding:[defaults integerForKey:BDSKDefaultStringEncoding]]];
    [showErrorsCheckButton setState: 
		([defaults boolForKey:BDSKShowWarningsKey] == YES) ? NSOnState : NSOffState  ];	
    [shouldTeXifyCheckButton setState:([defaults boolForKey:BDSKShouldTeXifyWhenSavingAndCopying] == YES) ? NSOnState : NSOffState];
}

- (IBAction)setDefaultStringEncoding:(id)sender{    
    NSStringEncoding encoding = [encodingManager stringEncodingForDisplayedName:[[sender selectedItem] title]];
    
    // NSLog(@"set encoding to %i for tag %i", [[encodingsArray objectAtIndex:[sender indexOfSelectedItem]] intValue], [sender indexOfSelectedItem]);    
    [defaults setInteger:encoding forKey:BDSKDefaultStringEncoding];    
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
    [defaults setBool:([sender state] == NSOnState ? YES : NO) forKey:BDSKShouldTeXifyWhenSavingAndCopying];
    [self updateUI];
}

@end
