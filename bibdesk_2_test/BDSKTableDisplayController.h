//
//  BDSKTableDisplayController.h
//  bd2xtest
//
//  Created by Christiaan Hofman on 1/29/06.
//  Copyright 2006. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ImageBackgroundBox.h"


@interface BDSKTableDisplayController : NSWindowController {
    IBOutlet NSView *mainView;
    IBOutlet NSArrayController *itemsArrayController;
    IBOutlet NSTableView *itemsTableView;
    IBOutlet ImageBackgroundBox *selectionDetailsBox;
    NSDocument *document;
}

- (NSDocument *)document;
- (void)setDocument:(NSDocument *)newDocument;

- (NSManagedObjectContext *)managedObjectContext;

- (NSView *)view;

- (NSArrayController *)itemsArrayController;
- (NSTableView *)itemsTableView;

- (NSArray *)filterPredicates;

- (BOOL)writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard forType:(NSString *)type;
- (BOOL)addRelationshipsFromPasteboard:(NSPasteboard *)pboard forType:(NSString *)type parentRow:(int)row keyPath:(NSString *)keyPath;

@end
