/* BibPref_Cite */

#import <OmniAppKit/OmniAppKit.h>
#import <Cocoa/Cocoa.h>
#import "BibPrefController.h"

@interface BibPref_Cite : OAPreferenceClient
{
    IBOutlet NSMatrix *dragCopyRadio;
    IBOutlet NSTextField* citeBehaviorLine; /*! for feedback */
    IBOutlet NSTextField* citeStringField; /*! for user input */
    IBOutlet NSButton* separateCiteCheckButton;
    IBOutlet NSButton* editOnPasteButton;

    NSMutableArray *customStringArray;
    IBOutlet NSTableView* customStringTableView;
    IBOutlet NSTextField* customStringField;
    IBOutlet NSButton* addCustomStringButton;
    IBOutlet NSButton* delSelectedCustomStringButton;
}

- (IBAction)changeCopyBehavior:(id)sender;
- (IBAction)changeSeparateCite:(id)sender;
- (IBAction)changeEditOnPaste:(id)sender;
- (IBAction)citeStringFieldChanged:(id)sender;

- (IBAction)addCustomString:(id)sender;
- (IBAction)delSelectedCustomString:(id)sender;
@end
