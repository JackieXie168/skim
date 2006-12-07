//
//  BDSKTagTableDisplayController.m
//  bd2
//
//  Created by Christiaan Hofman on 2/8/06.
//  Copyright 2006. All rights reserved.
//

#import "BDSKTagTableDisplayController.h"
#import "BDSKDocument.h"
#import "NSTableView_BDSKExtensions.h"


@implementation BDSKTagTableDisplayController

- (NSString *)windowNibName{
    return @"BDSKTagTableDisplayController";
}

- (void)awakeFromNib{
	[super awakeFromNib];
	[itemsTableView registerForDraggedTypes:[NSArray arrayWithObjects:BDSKPublicationPboardType, BDSKPersonPboardType, BDSKInstitutionPboardType, nil]];
}

#pragma mark Actions

- (IBAction)addTag:(id)sender {
	NSManagedObjectContext *moc = [self managedObjectContext];
	NSManagedObject *note = [NSEntityDescription insertNewObjectForEntityForName:TagEntityName inManagedObjectContext:moc];
    [itemsArrayController addObject:note];
    [moc processPendingChanges];
    [itemsArrayController setSelectedObjects:[NSArray arrayWithObject:note]];
}

- (IBAction)removeTags:(NSArray *)selectedItems {
	NSManagedObjectContext *moc = [self managedObjectContext];
	NSEnumerator *selEnum = [selectedItems objectEnumerator];
	NSManagedObject *note;
	while (note = [selEnum nextObject]) 
		[moc deleteObject:note];
    [moc processPendingChanges];
    // dirty fix for CoreData bug, which registers an extra change when objects are deleted
    [[self document] updateChangeCount:NSChangeUndone];
}

#pragma mark Filter predicate binding

- (NSArray *)filterPredicates {
    static NSMutableArray *filterPredicates = nil;
    if (filterPredicates == nil) {
        NSDictionary *options;
        filterPredicates = [[NSMutableArray alloc] initWithCapacity:1];
        options = [NSDictionary dictionaryWithObjectsAndKeys:@"Name", NSDisplayNameBindingOption, @"name contains[c] $value", NSPredicateFormatBindingOption, nil];
        [filterPredicates addObject:options];
    }
    return filterPredicates;
}

#pragma mark NSTableView DataSource protocol

// dummy implementation as the NSTableView DataSource protocols requires these methods
- (int)numberOfRowsInTableView:(NSTableView *)tv {
	return 0;
}

// dummy implementation as the NSTableView DataSource protocols requires these methods
- (id)tableView:(NSTableView *)tv objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row {
	return nil;
}

- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard {
	if (tv == itemsTableView) {
        return [self writeRowsWithIndexes:rowIndexes toPasteboard:pboard forType:BDSKTagPboardType];
	}
    
	return NO;
}

- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op {
	if (tv == itemsTableView) {
        
		NSPasteboard *pboard = [info draggingPasteboard];
		NSString *type = [pboard availableTypeFromArray:[NSArray arrayWithObjects:BDSKPublicationPboardType, BDSKPersonPboardType, BDSKInstitutionPboardType, nil]];
		if ([type isEqualToString:BDSKPublicationPboardType] || [type isEqualToString:BDSKPersonPboardType] || [type isEqualToString:BDSKInstitutionPboardType]) {
            if ([tv setValidDropRow:row dropOperation:NSTableViewDropOn] == NO)
                return NSDragOperationNone;
			if ([[[info draggingSource] dataSource] document] == [self document])
				return NSDragOperationLink;
			else
				return NSDragOperationCopy;
		}
        
	}
	return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView *)tv acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)op {
	if (tv == itemsTableView) {
        
		NSPasteboard *pboard = [info draggingPasteboard];
		NSString *type = [pboard availableTypeFromArray:[NSArray arrayWithObjects:BDSKPublicationPboardType, BDSKPersonPboardType, BDSKInstitutionPboardType, nil]];
		if (([info draggingSourceOperationMask] & NSDragOperationLink) &&
			[type isEqualToString:BDSKPublicationPboardType] || [type isEqualToString:BDSKPersonPboardType] || [type isEqualToString:BDSKInstitutionPboardType]) 
			return [self addRelationshipsFromPasteboard:pboard forType:type parentRow:row keyPath:@"items"];
        
	}
    
	return NO;
}

@end
