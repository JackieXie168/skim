//
//  BDSKMainWindowController.h
//  bd2
//
//  Created by Michael McCracken on 6/16/05.
//  Copyright 2005 Michael McCracken. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BDSKDocument.h"
#import "ImageAndTextCell.h"

#import "BDSKPublicationTableDisplayController.h" // @@ TODO: itemdisplayflex this should be temporary
#import "BDSKNoteTableDisplayController.h" // @@ TODO: itemdisplayflex this should be temporary


@interface BDSKMainWindowController : NSWindowController {
    IBOutlet NSTreeController *sourceListTreeController;
    IBOutlet NSOutlineView *sourceList;
        

    IBOutlet NSSplitView *mainSplitView;
    
    // Display Controller stuff
    NSDictionary *displayControllersInfoDict;
    NSMutableArray *displayControllers;
    NSString *currentEntityClassName;
    NSMutableDictionary *currentDisplayControllerForEntity;
    id currentDisplayController;
    IBOutlet NSView *currentDisplayView;
}

- (void)setupDisplayControllers;
- (NSArray *)displayControllersForCurrentType;
- (void)setDisplayController:(id)newDisplayController;

// actions
- (IBAction)addNewPublication:(id)sender;
- (IBAction)addNewPublicationGroup:(id)sender;

- (IBAction)addNewNote:(id)sender;
- (IBAction)addNewNoteGroup:(id)sender;

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object 
                        change:(NSDictionary *)change
                       context:(void *)context;    

@end
