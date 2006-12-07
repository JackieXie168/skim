//
//  BDSKTagTableDisplayController.h
//  bd2
//
//  Created by Christiaan Hofman on 2/8/06.
//  Copyright 2006. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BDSKTableDisplayController.h"

@interface BDSKTagTableDisplayController : BDSKTableDisplayController {
    IBOutlet NSArrayController *taggedItemsArrayController;
    IBOutlet NSTableView *taggedItemsTableView;
}

- (IBAction)addTag:(id)sender;
- (IBAction)removeTags:(NSArray *)selectedItems;

@end
