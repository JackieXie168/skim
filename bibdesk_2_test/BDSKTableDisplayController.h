//
//  BDSKTableDisplayController.h
//  bd2xtest
//
//  Created by Christiaan Hofman on 1/29/06.
//  Copyright 2006. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BDSKDisplayController.h"


@interface BDSKTableDisplayController : BDSKDisplayController {
    NSManagedObject *currentItem;
    BOOL isEditable;
    NSDictionary *itemDisplayControllersInfoDict;
    NSMutableArray *itemDisplayControllers;
    NSMutableDictionary *currentItemDisplayControllerForEntity;
    BDSKItemDisplayController *currentItemDisplayController;
    IBOutlet NSView *currentItemDisplayView;
    IBOutlet NSArrayController *itemsArrayController;
    IBOutlet NSTableView *itemsTableView;
}

- (NSArrayController *)itemsArrayController;
- (NSTableView *)itemsTableView;

- (NSArray *)filterPredicates;
- (NSArray *)columnInfo;

- (BOOL)isEditable;
- (void)setEditable:(BOOL)value;

- (NSManagedObject *)currentItem;
- (void)setCurrentItem:(NSManagedObject *)newItem;

- (BDSKItemDisplayController *)itemDisplayController;
- (void)setItemDisplayController:(BDSKItemDisplayController *)newDisplayController;

- (NSArray *)itemDisplayControllers;
- (NSArray *)itemDisplayControllersForCurrentType;

- (BDSKItemDisplayController *)itemDisplayControllerForEntity:(NSEntityDescription *)entity;

- (void)setupItemDisplayControllers;
- (void)bindItemDisplayController:(BDSKItemDisplayController *)displayController;
- (void)unbindItemDisplayController:(BDSKItemDisplayController *)displayController;

- (void)setupTableColumns;

- (void)addItem;
- (void)removeItems:(NSArray *)selectedItems;

- (NSArray *)acceptableDraggedTypes;

- (BOOL)writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard forType:(NSString *)type;
- (BOOL)canAddRelationshipsFromPasteboardType:(NSString *)type parentRow:(int)row;
- (BOOL)addRelationshipsFromPasteboard:(NSPasteboard *)pboard forType:(NSString *)type parentRow:(int)row keyPath:(NSString *)keyPath;

@end
