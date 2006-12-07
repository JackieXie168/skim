//
//  BDSKVenueTableDisplayController.m
//  bd2xtest
//
//  Created by Christiaan Hofman on 2/7/06.
//  Copyright 2006. All rights reserved.
//

#import "BDSKVenueTableDisplayController.h"
#import "BDSKDocument.h"
#import "NSTableView_BDSKExtensions.h"


@implementation BDSKVenueTableDisplayController

- (NSString *)windowNibName{
    return @"BDSKVenueTableDisplayController";
}

- (void)awakeFromNib{
	[super awakeFromNib];
	[itemsTableView registerForDraggedTypes:[NSArray arrayWithObjects:BDSKPublicationPboardType, nil]];
	[publicationsTableView registerForDraggedTypes:[NSArray arrayWithObjects:BDSKPublicationPboardType, nil]];
}

#pragma mark Actions

- (IBAction)addVenue:(id)sender {
	NSManagedObjectContext *moc = [self managedObjectContext];
	NSManagedObject *venue = [NSEntityDescription insertNewObjectForEntityForName:VenueEntityName inManagedObjectContext:moc];
    [itemsArrayController addObject:venue];
    [moc processPendingChanges];
    [itemsArrayController setSelectedObjects:[NSArray arrayWithObject:venue]];
}

- (IBAction)removeVenues:(NSArray *)selectedItems {
	NSManagedObjectContext *moc = [self managedObjectContext];
	NSEnumerator *selEnum = [selectedItems objectEnumerator];
	NSManagedObject *venue;
	while (venue = [selEnum nextObject]) 
		[moc deleteObject:venue];
    [moc processPendingChanges];
    // dirty fix for CoreData bug, which registers an extra change when objects are deleted
    [[self document] updateChangeCount:NSChangeUndone];
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
        return [self writeRowsWithIndexes:rowIndexes toPasteboard:pboard forType:BDSKVenuePboardType];
	}
	return NO;
}

- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op {
	NSPasteboard *pboard = [info draggingPasteboard];
	if (tv == publicationsTableView) {
		
        if ([[itemsArrayController selectedObjects] count] != 1)
			return NSDragOperationNone;
		NSString *type = [pboard availableTypeFromArray:[NSArray arrayWithObjects:BDSKPublicationPboardType, nil]];
		if ([type isEqualToString:BDSKPublicationPboardType]) {
			[tv setDropRow:-1 dropOperation:NSTableViewDropOn];
			if ([[[info draggingSource] dataSource] document] == [self document])
				return NSDragOperationLink;
			else
				return NSDragOperationCopy;
		}
        
	} else if (tv == itemsTableView) {
		
        NSPasteboard *pboard = [info draggingPasteboard];
		NSString *type = [pboard availableTypeFromArray:[NSArray arrayWithObjects:BDSKPublicationPboardType, nil]];
		if ([type isEqualToString:BDSKPublicationPboardType]) {
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
	NSPasteboard *pboard = [info draggingPasteboard];
	
    if (tv == publicationsTableView) {
        
        NSString *type = [pboard availableTypeFromArray:[NSArray arrayWithObjects:BDSKPublicationPboardType, nil]];
		if (([info draggingSourceOperationMask] & NSDragOperationLink) &&
			[type isEqualToString:BDSKPublicationPboardType])
			return [self addRelationshipsFromPasteboard:pboard forType:type parentRow:-1 keyPath:@"publication"];
        
	} else if (tv == itemsTableView) {
        
        NSString *type = [pboard availableTypeFromArray:[NSArray arrayWithObjects:BDSKPublicationPboardType, nil]];
		if (([info draggingSourceOperationMask] & NSDragOperationLink) &&
			[type isEqualToString:BDSKPublicationPboardType])
			return [self addRelationshipsFromPasteboard:pboard forType:type parentRow:row keyPath:@"publication"];
        
	}
    
	return NO;
}

@end
