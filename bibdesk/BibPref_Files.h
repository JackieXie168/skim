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
    IBOutlet NSButton *saveAnnoteAndAbstractAtEndButton;
    IBOutlet NSButton *useNormalizedNamesButton;
    IBOutlet NSButton *useTemplateFileButton;
    IBOutlet NSButton* autoSaveAsRSSButton;
    IBOutlet NSButton *outputTemplateFileButton;
}

- (IBAction)setDefaultStringEncoding:(id)sender;
- (IBAction)toggleShowWarnings:(id)sender;
- (IBAction)toggleShouldTeXify:(id)sender;
- (IBAction)toggleShouldUseNormalizedNames:(id)sender;
- (IBAction)toggleSaveAnnoteAndAbstractAtEnd:(id)sender;
- (IBAction)toggleShouldUseTemplateFile:(id)sender;
- (IBAction)toggleAutoSaveAsRSSChanged:(id)sender;
- (IBAction)editTemplateFile:(id)sender;
- (IBAction)showConversionEditor:(id)sender;

@end
