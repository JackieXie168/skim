//
//  BibPref_Startup.h
//  Bibdesk
//
//  Created by Michael McCracken on Sat Jun 01 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BibPrefController.h"

@interface BibPref_Startup : OAPreferenceClient {
    IBOutlet NSMatrix *startupBehaviorRadio;
    IBOutlet NSView* openSheetAccessoryView;
    IBOutlet NSTextField *defaultBibFileField;
    int prevStartupBehaviorTag;

    IBOutlet NSButton* showErrorsCheckButton;
}

- (IBAction)toggleShowWarnings:(id)sender;
- (IBAction)changeStartupBehavior:(id)sender;
@end
