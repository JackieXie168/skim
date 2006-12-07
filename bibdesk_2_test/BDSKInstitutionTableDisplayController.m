//
//  BDSKInstitutionTableDisplayController.m
//  bd2
//
//  Created by Christiaan Hofman on 2/7/06.
//  Copyright 2006. All rights reserved.
//

#import "BDSKInstitutionTableDisplayController.h"
#import "BDSKDocument.h"
#import "NSTableView_BDSKExtensions.h"


@implementation BDSKInstitutionTableDisplayController

- (void)dealloc{
    [super dealloc];
}

- (NSString *)windowNibName{
    return @"BDSKInstitutionTableDisplayController";
}

- (void)awakeFromNib{
	[super awakeFromNib];
	[itemsTableView registerForDraggedTypes:[NSArray arrayWithObjects:BDSKPublicationPboardType, BDSKPersonPboardType, BDSKTagPboardType, nil]];
	[personsTableView registerForDraggedTypes:[NSArray arrayWithObjects:BDSKPersonPboardType, nil]];
	[publicationsTableView registerForDraggedTypes:[NSArray arrayWithObjects:BDSKPublicationPboardType, nil]];
	[tagsTableView registerForDraggedTypes:[NSArray arrayWithObjects:BDSKTagPboardType, nil]];
}

#pragma mark Actions

- (IBAction)addInstitution:(id)sender {
	NSManagedObjectContext *moc = [self managedObjectContext];
	NSManagedObject *institution = [NSEntityDescription insertNewObjectForEntityForName:InstitutionEntityName inManagedObjectContext:moc];
    [itemsArrayController addObject:institution];
    [moc processPendingChanges];
    [itemsArrayController setSelectedObjects:[NSArray arrayWithObject:institution]];
}

- (IBAction)removeInstitutions:(NSArray *)selectedItems {
	NSManagedObjectContext *moc = [self managedObjectContext];
	NSEnumerator *selEnum = [selectedItems objectEnumerator];
	NSManagedObject *institution;
	while (institution = [selEnum nextObject]) 
		[moc deleteObject:institution];
    [moc processPendingChanges];
    // dirty fix for CoreData bug, which registers an extra change when objects are deleted
    [[self document] updateChangeCount:NSChangeUndone];
}

- (IBAction)addPerson:(id)sender {
	NSManagedObjectContext *moc = [self managedObjectContext];
	NSManagedObject *person = [NSEntityDescription insertNewObjectForEntityForName:PersonEntityName inManagedObjectContext:moc];
	NSManagedObject *relationship = [NSEntityDescription insertNewObjectForEntityForName:PersonInstitutionRelationshipEntityName inManagedObjectContext:moc];
	[relationship setValue:person forKey:@"person"];
	[relationship setValue:@"institution" forKey:@"relationshipType"];
	[personsArrayController addObject:relationship];
}

- (IBAction)removePersons:(NSArray *)selectedPersons {
	[personsArrayController removeObjects:selectedPersons];
    // dirty fix for CoreData bug, which registers an extra change when objects are deleted
    [[self document] updateChangeCount:NSChangeUndone];
}

- (IBAction)addPublication:(id)sender{
	NSManagedObjectContext *moc = [self managedObjectContext];
	NSManagedObject *publication = [NSEntityDescription insertNewObjectForEntityForName:PublicationEntityName inManagedObjectContext:moc];
	NSManagedObject *relationship = [NSEntityDescription insertNewObjectForEntityForName:ContributorPublicationRelationshipEntityName inManagedObjectContext:moc];
	[relationship setValue:[NSNumber numberWithInt:[[publicationsArrayController arrangedObjects] count]] forKey:@"index"];
	[relationship setValue:publication forKey:@"publication"];
	[relationship setValue:@"institution" forKey:@"relationshipType"];
	[publicationsArrayController addObject:relationship];
}

- (IBAction)removePublications:(NSArray *)selectedPublications {
	[publicationsArrayController removeObjects:selectedPublications];
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
        options = [NSDictionary dictionaryWithObjectsAndKeys:@"Address", NSDisplayNameBindingOption, @"address contains[c] $value", NSPredicateFormatBindingOption, nil];
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
        return [self writeRowsWithIndexes:rowIndexes toPasteboard:pboard forType:BDSKInstitutionPboardType];
	}
    
	return NO;
}

- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op {
	if (tv == publicationsTableView) {
		
        if ([[itemsArrayController selectedObjects] count] != 1)
			return NSDragOperationNone;
		NSPasteboard *pboard = [info draggingPasteboard];
		NSString *type = [pboard availableTypeFromArray:[NSArray arrayWithObjects:BDSKPublicationPboardType, nil]];
		if ([type isEqualToString:BDSKPublicationPboardType]) {
			[tv setDropRow:-1 dropOperation:NSTableViewDropOn];
			if ([[[info draggingSource] dataSource] document] == [self document])
				return NSDragOperationLink;
			else
				return NSDragOperationCopy;
		}
        
	} else if (tv == personsTableView) {
		
        if ([[itemsArrayController selectedObjects] count] != 1)
			return NSDragOperationNone;
		NSPasteboard *pboard = [info draggingPasteboard];
		NSString *type = [pboard availableTypeFromArray:[NSArray arrayWithObjects:BDSKPersonPboardType, nil]];
		if ([type isEqualToString:BDSKPersonPboardType]) {
			[tv setDropRow:-1 dropOperation:NSTableViewDropOn];
			if ([[[info draggingSource] dataSource] document] == [self document])
				return NSDragOperationLink;
			else
				return NSDragOperationCopy;
		}
        
    } else if (tv == tagsTableView) {
		
        if ([[itemsArrayController selectedObjects] count] != 1)
			return NSDragOperationNone;
		NSPasteboard *pboard = [info draggingPasteboard];
		NSString *type = [pboard availableTypeFromArray:[NSArray arrayWithObjects:BDSKTagPboardType, nil]];
		if ([type isEqualToString:BDSKTagPboardType]) {
			[tv setDropRow:-1 dropOperation:NSTableViewDropOn];
			if ([[[info draggingSource] dataSource] document] == [self document])
				return NSDragOperationLink;
			else
				return NSDragOperationCopy;
		}
        
	} else if (tv == itemsTableView) {
		
        NSPasteboard *pboard = [info draggingPasteboard];
		NSString *type = [pboard availableTypeFromArray:[NSArray arrayWithObjects:BDSKPublicationPboardType, BDSKPersonPboardType, BDSKTagPboardType, nil]];
		if ([type isEqualToString:BDSKPublicationPboardType] || [type isEqualToString:BDSKPersonPboardType] || [type isEqualToString:BDSKTagPboardType]) {
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
			return [self addRelationshipsFromPasteboard:pboard forType:type parentRow:-1 keyPath:@"publicationRelationships.publication"];
        
	} else if (tv == tagsTableView) {
        
        NSString *type = [pboard availableTypeFromArray:[NSArray arrayWithObjects:BDSKTagPboardType, nil]];
		if (([info draggingSourceOperationMask] & NSDragOperationLink) &&
			[type isEqualToString:BDSKTagPboardType])
			return [self addRelationshipsFromPasteboard:pboard forType:type parentRow:-1 keyPath:@"tags"];
        
    } else if (tv == itemsTableView) {
		
        if (!([info draggingSourceOperationMask] & NSDragOperationLink))
			return NO;
		NSString *type = [pboard availableTypeFromArray:[NSArray arrayWithObjects:BDSKPublicationPboardType, BDSKPersonPboardType, BDSKTagPboardType, nil]];
		
        if ([type isEqualToString:BDSKPublicationPboardType]) {
			
            return [self addRelationshipsFromPasteboard:pboard forType:type parentRow:row keyPath:@"publicationRelationships.publication"];
            
        } else if ([type isEqualToString:BDSKPersonPboardType]) {
			
            return [self addRelationshipsFromPasteboard:pboard forType:type parentRow:row keyPath:@"personRelationships.person"];
            
        } else if ([type isEqualToString:BDSKTagPboardType]) {
			
            return [self addRelationshipsFromPasteboard:pboard forType:type parentRow:row keyPath:@"tags"];
            
		}
	}
    
	return NO;
}

@end
