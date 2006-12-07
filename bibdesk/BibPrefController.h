// BibPrefController 

#import <Cocoa/Cocoa.h>
#import <OmniFoundation/OFPreference.h>
#import <OmniAppKit/OmniAppKit.h>

#pragma mark ||  User Defaults Key String Declarations

/*! @const BDSKTeXBinPathKey
@discussion Key for the user default:  the path to tex.
<br> I don't think these are respected yet. why not?
*/
extern NSString *BDSKTeXBinPathKey;

/*! @const BDSKBibTeXBinPathKey 
@discussion Key for the user default: the path to bibtex
*/
extern NSString *BDSKBibTeXBinPathKey;

/*! @const BDSKBTStyleKey Key for user default: The style file name to be inserted into the tex template for preview. */
extern NSString *BDSKBTStyleKey;
extern NSString *BDSKDefaultBibFilePathKey;
extern NSString *BDSKStartupBehaviorKey;
extern NSString *BDSKDragCopyKey;
extern NSString *BDSKUsesTeXKey;
extern NSString *BDSKEditOnPasteKey;
extern NSString *BDSKSeparateCiteKey;
extern NSString *BDSKShowColsKey;
extern NSString *BDSKShownColsNamesKey;
extern NSString *BDSKDefaultFieldsKey;
extern NSString *BDSKOutputTemplateFileKey;
extern NSString *BDSKCiteStringKey;
extern NSString *BDSKTableViewFontKey;
extern NSString *BDSKTableViewFontSizeKey;
extern NSString *BDSKPreviewDisplayKey;
extern NSString *BDSKCustomCiteStringsKey;

extern NSString *BDSKAutoSaveAsRSSKey;
extern NSString *BDSKRSSDescriptionFieldKey;

extern NSString *BDSKColumnWidthsKey;
extern NSString *BDSKColumnOrderKey;

extern NSString *BDSKViewByKey;

extern NSString *BDSKPubTypeKey;

extern NSString *BDSKShowWarningsKey;

extern NSString *BDSKCurrentQuickSearchKey;
extern NSString *BDSKCurrentQuickSearchTextDict;
extern NSString *BDSKQuickSearchKeys;



#pragma mark ||  Notification name strings
extern NSString *BDSKDocumentUpdateUINotification;
extern NSString *BDSKTableViewFontChangedNotification;
extern NSString *BDSKPreviewDisplayChangedNotification;
extern NSString *BDSKCustomStringsChangedNotification;
extern NSString *BDSKTableColumnChangedNotification;
/*!
    @class BibPrefController
    @abstract was Window Controller for the preferences panel
    @discussion now just declares constant strings.
*/
@interface BibPrefController : NSWindowController
{   
   
}
- (id)init;
@end
