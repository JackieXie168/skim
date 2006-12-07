//
//  BDSKPersonItemDisplayController.m
//  bd2
//
//  Created by Michael McCracken on 7/13/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "BDSKPersonItemDisplayController.h"
#import "BDSKDocument.h"
#import "NSTableView_BDSKExtensions.h"


@implementation BDSKPersonItemDisplayController

- (NSString *)windowNibName{
    return @"BDSKPersonItemDisplay";
}

- (void)awakeFromNib{
	[super awakeFromNib];
	[publicationsTableView registerForDraggedTypes:[NSArray arrayWithObjects:BDSKPublicationPboardType, nil]];
	[institutionsTableView registerForDraggedTypes:[NSArray arrayWithObjects:BDSKInstitutionPboardType, nil]];
	[tagsTableView registerForDraggedTypes:[NSArray arrayWithObjects:BDSKTagPboardType, nil]];
}

#pragma mark Actions

- (IBAction)addPublication:(id)sender{
	NSManagedObjectContext *moc = [self managedObjectContext];
	NSManagedObject *publication = [NSEntityDescription insertNewObjectForEntityForName:PublicationEntityName inManagedObjectContext:moc];
	NSManagedObject *relationship = [NSEntityDescription insertNewObjectForEntityForName:ContributorPublicationRelationshipEntityName inManagedObjectContext:moc];
	[relationship setValue:[NSNumber numberWithInt:[[publicationsArrayController arrangedObjects] count]] forKey:@"index"];
	[relationship setValue:publication forKey:@"publication"];
	[relationship setValue:@"author" forKey:@"relationshipType"];
	[publicationsArrayController addObject:relationship];
}

- (IBAction)removePublications:(NSArray *)selectedPublications {
	[publicationsArrayController removeObject:selectedPublications];
    // dirty fix for CoreData bug, which registers an extra change when objects are deleted
    [[self document] updateChangeCount:NSChangeUndone];
}

- (IBAction)addInstitution:(id)sender{
	NSManagedObjectContext *moc = [self managedObjectContext];
	NSManagedObject *institution = [NSEntityDescription insertNewObjectForEntityForName:InstitutionEntityName inManagedObjectContext:moc];
	NSManagedObject *relationship = [NSEntityDescription insertNewObjectForEntityForName:PersonInstitutionRelationshipEntityName inManagedObjectContext:moc];
	[relationship setValue:institution forKey:@"institution"];
	[relationship setValue:@"institution" forKey:@"relationshipType"];
	[institutionsArrayController addObject:relationship];
}

- (IBAction)removeInstitutions:(NSArray *)selectedInstitutions {
	[institutionsArrayController removeObject:selectedInstitutions];
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
	return NO;
}

- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op {
	if (tv == publicationsTableView) {
		
        if ([[itemObjectController selectedObjects] count] != 1)
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
        
	} else if (tv == institutionsTableView) {
		
        if ([[itemObjectController selectedObjects] count] != 1)
			return NSDragOperationNone;
		NSPasteboard *pboard = [info draggingPasteboard];
		NSString *type = [pboard availableTypeFromArray:[NSArray arrayWithObjects:BDSKInstitutionPboardType, nil]];
		if ([type isEqualToString:BDSKInstitutionPboardType]) {
			[tv setDropRow:-1 dropOperation:NSTableViewDropOn];
			if ([[[info draggingSource] dataSource] document] == [self document])
				return NSDragOperationLink;
			else
				return NSDragOperationCopy;
		}
        
    } else if (tv == tagsTableView) {
		
        if ([[itemObjectController selectedObjects] count] != 1)
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
        
	}
    
	return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView *)tv acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)op {
	NSPasteboard *pboard = [info draggingPasteboard];
	
    if (tv == publicationsTableView) {
		
        NSString *type = [pboard availableTypeFromArray:[NSArray arrayWithObjects:BDSKPublicationPboardType, nil]];
		if (([info draggingSourceOperationMask] & NSDragOperationLink) &&
			[type isEqualToString:BDSKPublicationPboardType])
			return [self addRelationshipsFromPasteboard:pboard forType:type keyPath:@"publicationRelationships.publication"];
        
	} else if (tv == tagsTableView) {
        
        NSString *type = [pboard availableTypeFromArray:[NSArray arrayWithObjects:BDSKTagPboardType, nil]];
		if (([info draggingSourceOperationMask] & NSDragOperationLink) &&
			[type isEqualToString:BDSKTagPboardType])
			return [self addRelationshipsFromPasteboard:pboard forType:type keyPath:@"tags"];
        
	} else if (tv == institutionsTableView) {
        
        NSString *type = [pboard availableTypeFromArray:[NSArray arrayWithObjects:BDSKInstitutionPboardType, nil]];
		if (([info draggingSourceOperationMask] & NSDragOperationLink) &&
			[type isEqualToString:BDSKInstitutionPboardType])
			return [self addRelationshipsFromPasteboard:pboard forType:type keyPath:@"institutionRelationships.institution"];
        
	}
    
	return NO;
}

@end
