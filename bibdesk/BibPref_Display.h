//
//  BibPref_Display.h
//  Bibdesk
//
//  Created by Adam Maxwell on 07/25/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BibPrefController.h"

@interface BibPref_Display : OAPreferenceClient {
    // display pref radio matrix
    IBOutlet NSMatrix* displayPrefRadioMatrix;
    IBOutlet NSComboBox *previewMaxNumberComboBox;
    
    IBOutlet NSPopUpButton *previewFontPopup;
    IBOutlet NSTextField *previewFontSizeField;
    IBOutlet NSPopUpButton *tableViewFontPopup;
    IBOutlet NSTextField *tableViewFontSizeField;
    
    // sorting
    IBOutlet NSButton *addButton;
    IBOutlet NSButton *removeButton;
    IBOutlet NSTableView *tableView;
    
}

// tableview font selection:
- (IBAction)chooseFont:(id)sender;
- (IBAction)changePreviewDisplay:(id)sender;
- (IBAction)changePreviewMaxNumber:(id)sender;
- (IBAction)selectPreviewFont:(id)sender;

- (IBAction)addTerm:(id)sender;
- (IBAction)removeSelectedTerm:(id)sender;
@end
