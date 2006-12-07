/* BibPref_Defaults */

#import <Cocoa/Cocoa.h>
#import <OmniAppKit/OAPreferenceClient.h>
#import "BibPrefController.h"

@interface BibPref_Defaults : OAPreferenceClient
{
    // Default Fields stuff
    NSMutableArray *defaultFieldsArray;    // the fields to add to every new bib.
    IBOutlet NSButton* delSelectedFieldButton;
    IBOutlet NSButton* addFieldButton;
    IBOutlet NSTextField* addFieldField;
    IBOutlet NSTableView* defaultFieldsTableView;
    // the template file button:
    IBOutlet NSButton* outputTemplateFileButton;
}
// defaultFieldStuff
- (IBAction)delSelectedDefaultField:(id)sender;
- (IBAction)addDefaultField:(id)sender;
// edits the template file:
- (IBAction)outputTemplateButtonPressed:(id)sender;

@end
