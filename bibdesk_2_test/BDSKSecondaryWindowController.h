//
//  BDSKSecondaryWindowController.h
//  bd2
//
//  Created by Christiaan Hofman on 1/29/06.
//  Copyright 2006 Christiaan Hofman. All rights reserved.
//

#import <Cocoa/Cocoa.h>

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
}

- (NSManagedObjectContext *)managedObjectContext;

- (BDSKGroup *)sourceGroup;
- (void)setSourceGroup:(BDSKGroup *)newSourceGroup;

- (id)displayController;
- (void)setDisplayController:(id)newDisplayController;

- (NSArray *)displayControllers;
- (NSArray *)displayControllersForCurrentType;

- (void)setupDisplayControllers;
- (void)bindDisplayController:(id)displayController;
- (void)unbindDisplayController:(id)displayController;

// actions
- (IBAction)addNewItem:(id)sender;

@end
