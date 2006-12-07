/* BibPref_RSS */

#import <Cocoa/Cocoa.h>
#import "BibPrefController.h"
#import "BDSKLinkButton.h"

/*!
    @class BibPref_RSS
    @abstract OAPreferenceClient subclass to control RSS file settings.
    @discussion «words go here»
*/
@interface BibPref_RSS : OAPreferenceClient
{
    IBOutlet NSButton* autoSaveAsRSSButton;
    IBOutlet BDSKLinkButton* findOutMoreButton;
    IBOutlet NSMatrix* descriptionFieldMatrix;
    IBOutlet NSTextField* descriptionFieldTextField;
}
- (IBAction)autoSaveAsRSSChanged:(id)sender;

- (IBAction)descriptionFieldChanged:(id)sender;

- (IBAction)findOutMoreButtonPressed:(id)sender;

@end
