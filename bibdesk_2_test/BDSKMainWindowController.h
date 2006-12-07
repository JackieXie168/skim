//
//  BDSKMainWindowController.h
//  bd2
//
//  Created by Michael McCracken on 6/16/05.
//  Copyright 2005 Michael McCracken. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BDSKSecondaryWindowController.h"


@interface BDSKMainWindowController : BDSKSecondaryWindowController {

    IBOutlet NSOutlineView *sourceList;
    IBOutlet NSArrayController *selectedItemsArrayController;
    IBOutlet NSTreeController *sourceListTreeController;
}

- (NSSet *)sourceListSelectedItems;
- (void)addSourceListSelectedItemsObject:(id)obj;
- (void)removeSourceListSelectedItemsObject:(id)obj;

// actions
- (IBAction)showWindowForSourceListSelection:(id)sender;

- (IBAction)addNewGroup:(id)sender;
- (IBAction)addNewFolderGroup:(id)sender;
- (IBAction)addNewSmartGroup:(id)sender;

- (IBAction)editSmartGroup:(id)sender;

- (IBAction)getInfo:(id)sender;

- (void)importFromBibTeXFile:(id)sender;

@end
