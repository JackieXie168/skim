/* BibPref_Display */

#import <Cocoa/Cocoa.h>
#import <OmniAppKit/OAPreferenceClient.h>
#import "BibPrefController.h"

@interface BibPref_Display : OAPreferenceClient
{
    IBOutlet NSMatrix* showColsButtons;
    NSMutableArray *showColsArray;    //" the columns to show"
    // shows the font
    IBOutlet NSTextField* fontPreviewField;
    // display pref radio matrix
    IBOutlet NSMatrix* displayPrefRadioMatrix;
}

// tableview font selection:
- (IBAction)chooseFont:(id)sender;
- (IBAction)changePreviewDisplay:(id)sender;
- (IBAction)changeShownColumns:(id)sender;
@end
