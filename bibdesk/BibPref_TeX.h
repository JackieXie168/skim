/* BibPref_TeX */

#import <Cocoa/Cocoa.h>
#import <OmniAppKit/OAPreferenceClient.h>
#import "BibPrefController.h"

@interface BibPref_TeX : OAPreferenceClient
{
    IBOutlet NSButton *usesTeXButton;
    IBOutlet NSBox *texPrefsBox;
    IBOutlet NSTextField *texBinaryPath;
    IBOutlet NSTextField *bibtexBinaryPath;
    IBOutlet NSTextField *bibTeXStyle;
}

- (IBAction)changeUsesTeX:(id)sender;
- (IBAction)changeTexBinPath:(id)sender;
- (IBAction)changeBibTexBinPath:(id)sender;
- (IBAction)changeStyle:(id)sender;


@end
