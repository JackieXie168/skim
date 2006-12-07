#import "BibPrefController.h"
NSString *BDSKDefaultBibFilePathKey = @"Default Bib File";
NSString *BDSKStartupBehaviorKey = @"Startup Behavior";

NSString *BDSKTeXBinPathKey = @"TeX Binary Path";
NSString *BDSKBibTeXBinPathKey = @"BibTeX Binary Path";
NSString *BDSKBTStyleKey = @"BibTeX Style";
NSString *BDSKUsesTeXKey = @"Uses TeX";

NSString *BDSKDragCopyKey = @"Drag and Copy";
NSString *BDSKEditOnPasteKey = @"Edit on Paste";
NSString *BDSKSeparateCiteKey = @"Separate Cite";
NSString *BDSKCiteStringKey = @"Cite String";

NSString *BDSKShowColsKey = @"Shown Columns";
NSString *BDSKShownColsNamesKey = @"Shown Column Names";
NSString *BDSKColumnWidthsKey = @"Column Widths by Name";
NSString *BDSKColumnOrderKey = @"Column Names in Order";

NSString *BDSKTableViewFontKey = @"TableView Font";
NSString *BDSKTableViewFontSizeKey = @"TableView Font Size";
NSString *BDSKPreviewDisplayKey = @"Preview Pane Displays What?";

NSString *BDSKDefaultFieldsKey = @"Default Fields";
NSString *BDSKOutputTemplateFileKey = @"Output Template File";

NSString *BDSKCustomCiteStringsKey = @"Custom CiteStrings";
NSString *BDSKAutoSaveAsRSSKey = @"Auto-save as RSS";
NSString *BDSKRSSDescriptionFieldKey = @"Field to use as Description in RSS";

NSString *BDSKViewByKey = @"View-by Field";

NSString *BDSKPubTypeKey = @"Current Publication Type";

NSString *BDSKShowWarningsKey = @"Show Warnings in Error Panel";

NSString *BDSKCurrentQuickSearchKey = @"Current Quick Search Key";
NSString *BDSKCurrentQuickSearchTextDict = @"Current Quick Search Text Dictionary";
NSString *BDSKQuickSearchKeys = @"Quick Search Keys";

#pragma mark ||  Notification name strings
NSString *BDSKDocumentUpdateUINotification = @"General UI update Notification";
NSString *BDSKTableViewFontChangedNotification = @"Tableview font selection is changing Notification";
NSString *BDSKPreviewDisplayChangedNotification = @"Preview Pane Preference Change Notification";
NSString *BDSKCustomStringsChangedNotification = @"CustomStringsChangedNotification";
NSString *BDSKTableColumnChangedNotification = @"TableColumnChangedNotification";

@implementation BibPrefController

- (id)init
{

 //   if(self = [super initWithWindowNibName:@"BibPreferences"]){

       //    }

    return self;
}

- (void)dealloc{
//    [showColsArray release];
//    [defaultFieldsArray release];
}




@end
