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
    IBOutlet NSPopUpButton *encodingPopUp;
    IBOutlet NSMatrix *defaultParserRadio;
    IBOutlet NSButton *backgroundLoadCheckbox;
    BDSKStringEncodingManager *encodingManager;
}

- (IBAction)setDefaultStringEncoding:(id)sender;
- (IBAction)setDefaultBibTeXParser:(id)sender;
- (IBAction)setLoadFilesInBackground:(id)sender;

@end
