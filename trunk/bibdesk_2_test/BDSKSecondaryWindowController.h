//
//  BDSKSecondaryWindowController.h
//  bd2
//
//  Created by Christiaan Hofman on 1/29/06.
//  Copyright 2006 Christiaan Hofman. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString *BDSKDocumentToolbarIdentifier;
extern NSString *BDSKDocumentToolbarNewItemIdentifier;
extern NSString *BDSKDocumentToolbarDeleteItemIdentifier;
extern NSString *BDSKDocumentToolbarNewGroupIdentifier;
extern NSString *BDSKDocumentToolbarNewSmartGroupIdentifier;
extern NSString *BDSKDocumentToolbarNewFolderIdentifier;
extern NSString *BDSKDocumentToolbarDeleteGroupIdentifier;
extern NSString *BDSKDocumentToolbarGetInfoIdentifier;
extern NSString *BDSKDocumentToolbarDetachIdentifier;
extern NSString *BDSKDocumentToolbarSearchItemIdentifier;

@class BDSKGroup;

@interface BDSKSecondaryWindowController : NSWindowController {
    
	BDSKGroup *sourceGroup;
	
    // Display Controller stuff
    NSDictionary *displayControllersInfoDict;
    NSMutableArray *displayControllers;
    NSMutableDictionary *currentDisplayControllerForEntity;
    id currentDisplayController;
    IBOutlet NSView *currentDisplayView;
    IBOutlet NSSearchField *searchField;
    
    NSMutableDictionary *toolbarItems;
}

- (NSManagedObjectContext *)managedObjectContext;

- (BDSKGroup *)sourceGroup;
- (void)setSourceGroup:(BDSKGroup *)newSourceGroup;

- (id)displayController;
- (void)setDisplayController:(id)newDisplayController;

- (NSArray *)displayControllers;
- (NSArray *)displayControllersForCurrentType;

- (id)displayControllerForEntityName:(NSString *)entityName;

- (void)setupDisplayControllers;
- (void)bindDisplayController:(id)displayController;
- (void)unbindDisplayController:(id)displayController;

// actions
- (IBAction)addNewItem:(id)sender;
- (IBAction)removeSelectedItems:(id)sender;
- (IBAction)delete:(id)sender;

- (NSToolbar *) setupToolbar;
- (NSToolbarItem *)addToolbarItemWithIdentifier:(NSString *)identifier label:(NSString *)label paletteLabel:(NSString *)paletteLabel toolTip:(NSString *)toolTip target:(id)target action:(SEL)action itemContent:(id)itemContent menuItem:(NSMenuItem *)menuItem;

@end
