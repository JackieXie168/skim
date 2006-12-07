//
//  BibPref_Files.h
//  Bibdesk
//
//  Created by Adam Maxwell on 01/02/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BibPrefController.h"


@interface BibPref_Files : OAPreferenceClient {
    IBOutlet NSPopUpButton *encodingPopUp;
    IBOutlet NSMatrix *defaultParserRadio;
    NSArray *encodingsArray;
    NSArray *encodingNames;
}

- (IBAction)setDefaultStringEncoding:(id)sender;
- (unsigned)tagForEncoding:(NSStringEncoding)encoding;
- (IBAction)setDefaultBibTeXParser:(id)sender;

@end
