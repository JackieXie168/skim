//
//  BDSKMainWindowController.h
//  bd2
//
//  Created by Michael McCracken on 6/16/05.
//  Copyright 2005 Michael McCracken. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BDSKSecondaryWindowController.h"
#import "BDSKImporters.h"

@interface BDSKMainWindowController : BDSKSecondaryWindowController {

    IBOutlet NSOutlineView *sourceList;
    IBOutlet NSArrayController *selectedItemsArrayController;
    IBOutlet NSTreeController *sourceListTreeController;
    
    // Importer stuff
    IBOutlet NSWindow *importSettingsWindow;
    IBOutlet NSBox *importSettingsMainBox;
}

- (NSSet *)sourceListSelectedItems;
- (void)addSourceListSelectedItemsObject:(id)obj;
- (void)removeSourceListSelectedItemsObject:(id)obj;

// actions
- (IBAction)showWindowForSourceListSelection:(id)sender;

- (IBAction)addNewGroup:(id)sender;
- (IBAction)addNewFolderGroup:(id)sender;
- (IBAction)addNewSmartGroup:(id)sender;

- (IBAction)removeSelectedGroup:(id)sender;

- (IBAction)editSmartGroup:(id)sender;

- (IBAction)getInfo:(id)sender;

- (void)importUsingImporter:(id<BDSKImporter>)importer userInfo:(NSDictionary *)userInfo;
- (IBAction)oneShotImportFromBibTeXFile:(id)sender;
- (IBAction)closeImportSettingsSheet:(id)sender;

@end
