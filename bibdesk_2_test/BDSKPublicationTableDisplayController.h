//
//  BDSKPublicationTableDisplayController.h
//  bd2
//
//  Created by Michael McCracken on 6/21/05.
//  Copyright 2005 Michael McCracken. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BDSKTableDisplayController.h"


@interface BDSKPublicationTableDisplayController : BDSKTableDisplayController {
    IBOutlet NSArrayController *contributorsArrayController;
    IBOutlet NSArrayController *tagsArrayController;
    IBOutlet NSArrayController *notesArrayController;
    IBOutlet NSArrayController *keyValuePairsController;
	IBOutlet NSTableView *contributorsTableView;
	IBOutlet NSTableView *tagsTableView;
	IBOutlet NSTableView *notesTableView;
	IBOutlet NSTableView *keyValuePairsTableView;
}

- (IBAction)addPublication:(id)sender;
- (IBAction)removePublications:(NSArray *)selectedItems;
- (IBAction)addContributor:(id)sender;
- (IBAction)removeContributors:(NSArray *)selectedContributors;
- (IBAction)removeNotes:(NSArray *)selectedNotes;

@end
