//
//  BDSKInstitutionItemDisplayController.h
//  bd2
//
//  Created by Christiaan Hofman on 2/7/06.
//  Copyright 2006. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BDSKDisplayController.h"

@interface BDSKInstitutionItemDisplayController : BDSKItemDisplayController {
    IBOutlet NSArrayController *personsArrayController;
    IBOutlet NSArrayController *publicationsArrayController;
    IBOutlet NSArrayController *tagsArrayController;
    IBOutlet NSTableView *personsTableView;
    IBOutlet NSTableView *publicationsTableView;
    IBOutlet NSTableView *tagsTableView;
}

- (IBAction)addPerson:(id)sender;
- (IBAction)removePersons:(NSArray *)selectedPersons;
- (IBAction)addPublication:(id)sender;
- (IBAction)removePublications:(NSArray *)selectedPublications;

@end
