//
//  BDSKTagItemDisplayController.h
//  bd2
//
//  Created by Christiaan Hofman on 2/8/06.
//  Copyright 2006. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BDSKDisplayController.h"

@interface BDSKTagItemDisplayController : BDSKItemDisplayController {
    IBOutlet NSArrayController *taggedItemsArrayController;
    IBOutlet NSTableView *taggedItemsTableView;
}

@end
