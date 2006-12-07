//
//  BDSKPersonItemDisplayController.h
//  bd2
//
//  Created by Michael McCracken on 7/15/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BDSKDisplayController.h"

@interface BDSKPersonItemDisplayController : BDSKItemDisplayController {
    IBOutlet NSArrayController *publicationsArrayController;
    IBOutlet NSArrayController *institutionsArrayController;
    IBOutlet NSArrayController *tagsArrayController;
    IBOutlet NSTableView *publicationsTableView;
    IBOutlet NSTableView *institutionsTableView;
    IBOutlet NSTableView *tagsTableView;
}

- (IBAction)addPublication:(id)sender;
- (IBAction)removePublications:(NSArray *)selectedPublications;
- (IBAction)addInstitution:(id)sender;
- (IBAction)removeInstitutions:(NSArray *)selectedInstitutions;

@end
