//
//  BibPref_CiteKey.h
//  
//
//  Created by Christiaan Hofman on 11/4/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BibPrefController.h"
#import "BibItem.h"
#import "BDSKConverter.h"

@interface BibPref_CiteKey : OAPreferenceClient
{
    IBOutlet NSTextField *citeKeyLine;
    IBOutlet NSTextField *formatField;
    IBOutlet NSPopUpButton *formatPresetPopUp;
    IBOutlet NSPopUpButton *formatRepositoryPopUp;
    IBOutlet NSButton *formatWarningButton;
    IBOutlet NSButton* citeKeyAutogenerateCheckButton;
}

- (IBAction)citeKeyFormatChanged:(id)sender;
- (IBAction)citeKeyFormatAdd:(id)sender;
- (IBAction)formatHelp:(id)sender;
- (IBAction)changeCiteKeyAutogenerate:(id)sender;
- (void)updateUI;
- (IBAction)showCiteKeyFormatWarning:(id)sender;
- (void)setCiteKeyFormatInvalidWarning:(BOOL)set message:message;

@end
