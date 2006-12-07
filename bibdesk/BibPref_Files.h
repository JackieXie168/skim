//
//  BibPref_Files.h
//  Bibdesk
//
//  Created by Adam Maxwell on 01/02/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BibPrefController.h"
#import "BDSKStringEncodingManager.h"


@interface BibPref_Files : OAPreferenceClient {
    BDSKStringEncodingManager *encodingManager;
    IBOutlet NSButton *showErrorsCheckButton;
    IBOutlet NSPopUpButton *encodingPopUp;
    IBOutlet NSButton *shouldTeXifyCheckButton;
}

- (IBAction)setDefaultStringEncoding:(id)sender;
- (IBAction)toggleShowWarnings:(id)sender;
- (IBAction)toggleShouldTeXify:(id)sender;

@end
