//
//  BDSKNoteTableDisplayController.h
//  bd2
//
//  Created by Michael McCracken on 7/13/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BDSKTableDisplayController.h"

@interface BDSKNoteTableDisplayController : BDSKTableDisplayController {
}

- (IBAction)addNote:(id)sender;
- (IBAction)removeNotes:(NSArray *)selectedItems;

@end
