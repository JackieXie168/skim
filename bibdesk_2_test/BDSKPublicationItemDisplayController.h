//
//  BDSKPublicationItemDisplayController.h
//  bd2
//
//  Created by Michael McCracken on 6/21/05.
//  Copyright 2005 Michael McCracken. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BDSKDisplayController.h"


@interface BDSKPublicationItemDisplayController : BDSKItemDisplayController {
    IBOutlet NSArrayController *contributorsArrayController;
    IBOutlet NSArrayController *tagsArrayController;
    IBOutlet NSArrayController *notesArrayController;
    IBOutlet NSArrayController *keyValuePairsController;
	IBOutlet NSTableView *contributorsTableView;
	IBOutlet NSTableView *tagsTableView;
	IBOutlet NSTableView *notesTableView;
	IBOutlet NSTableView *keyValuePairsTableView;
}

- (IBAction)addContributor:(id)sender;
- (IBAction)removeContributors:(NSArray *)selectedContributors;
- (IBAction)removeNotes:(NSArray *)selectedNotes;

@end
