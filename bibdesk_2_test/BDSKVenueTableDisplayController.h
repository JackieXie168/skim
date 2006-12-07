//
//  BDSKVenueTableDisplayController.h
//  bd2xtest
//
//  Created by Christiaan Hofman on 2/7/06.
//  Copyright 2006. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BDSKTableDisplayController.h"


@interface BDSKVenueTableDisplayController : BDSKTableDisplayController {
    IBOutlet NSArrayController *publicationsArrayController;
	IBOutlet NSTableView *publicationsTableView;
}

- (IBAction)addVenue:(id)sender;
- (IBAction)removeVenues:(NSArray *)selectedItems;

@end
