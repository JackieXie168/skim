//
//  BDSKVenueItemDisplayController.h
//  bd2xtest
//
//  Created by Christiaan Hofman on 2/7/06.
//  Copyright 2006. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BDSKDisplayController.h"


@interface BDSKVenueItemDisplayController : BDSKItemDisplayController {
    IBOutlet NSArrayController *publicationsArrayController;
	IBOutlet NSTableView *publicationsTableView;
}

@end
