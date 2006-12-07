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
    [encodingPopUp selectItemWithTitle:[encodingManager displayedNameForStringEncoding:[prefs integerForKey:BDSKDefaultStringEncoding]]];
    [defaultParserRadio selectCellWithTag:( [prefs boolForKey:BDSKUseUnicodeBibTeXParser] ? 1 : 0 )];
    [backgroundLoadCheckbox setEnabled:[prefs boolForKey:BDSKUseUnicodeBibTeXParser]];
    [backgroundLoadCheckbox setState:( [prefs boolForKey:BDSKUseThreadedFileLoading] ? NSOnState : NSOffState )];
}

- (IBAction)setDefaultStringEncoding:(id)sender{    
    NSStringEncoding encoding = [encodingManager stringEncodingForDisplayedName:[[sender selectedItem] title]];
    
    // NSLog(@"set encoding to %i for tag %i", [[encodingsArray objectAtIndex:[sender indexOfSelectedItem]] intValue], [sender indexOfSelectedItem]);    
    [[OFPreferenceWrapper sharedPreferenceWrapper] setInteger:encoding forKey:BDSKDefaultStringEncoding];    
}

- (IBAction)setDefaultBibTeXParser:(id)sender{
    BOOL yn = ( [[sender selectedCell] tag] == 0 ? NO : YES );
    [[OFPreferenceWrapper sharedPreferenceWrapper] setBool:yn forKey:BDSKUseUnicodeBibTeXParser];
    if(!yn) // use libbtparse
        [[OFPreferenceWrapper sharedPreferenceWrapper] setBool:NO forKey:BDSKUseThreadedFileLoading];
    [self updateUI];
    // NSLog(@"use unicode parser is %@", ( [[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKUseUnicodeBibTeXParser] ? @"YES" : @"NO" ) );
}

- (IBAction)setLoadFilesInBackground:(id)sender{
    [[OFPreferenceWrapper sharedPreferenceWrapper] setBool:([sender state] == NSOnState ? YES : NO ) forKey:BDSKUseThreadedFileLoading];
}

    

@end
