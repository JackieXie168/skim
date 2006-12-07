//
//  BDSKPersonTableDisplayController.m
//  bd2
//
//  Created by Michael McCracken on 7/13/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "BDSKPersonTableDisplayController.h"
#import "BDSKDocument.h"
#import "NSTableView_BDSKExtensions.h"


@implementation BDSKPersonTableDisplayController

- (NSArray *)acceptableDraggedTypes {
    return [NSArray arrayWithObjects:BDSKPublicationPboardType, BDSKPersonPboardType, BDSKInstitutionPboardType, BDSKTagPboardType, nil];
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
        return [self writeRowsWithIndexes:rowIndexes toPasteboard:pboard forType:BDSKPersonPboardType];
	}
    
	return NO;
}

- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op {
	if (tv == itemsTableView) {
		
        NSPasteboard *pboard = [info draggingPasteboard];
		NSString *type = [pboard availableTypeFromArray:[NSArray arrayWithObjects:BDSKPersonPboardType, nil]];
        if ([tv setValidDropRow:&row dropOperation:NSTableViewDropOn] == NO)
            return NSDragOperationNone;
		if ([type isEqualToString:BDSKPersonPboardType]) {
            if ([info draggingSource] == tv) 
                return NSDragOperationLink;
		} else
            return [super tableView:tv validateDrop:info proposedRow:row proposedDropOperation:op];
    }
    
    return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView *)tv acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)op {
	
    if (tv == itemsTableView) {
		
        if (!([info draggingSourceOperationMask] & NSDragOperationLink))
			return NO;
        
        NSPasteboard *pboard = [info draggingPasteboard];
		NSString *type = [pboard availableTypeFromArray:[NSArray arrayWithObjects:BDSKPersonPboardType, nil]];
		
        if ([type isEqualToString:BDSKPersonPboardType]) {
			
            NSArray *draggedURIs = [NSUnarchiver unarchiveObjectWithData:[pboard dataForType:BDSKPersonPboardType]];
			NSEnumerator *uriE = [draggedURIs objectEnumerator];
			NSManagedObjectContext *moc = [self managedObjectContext];
			NSURL *moURI;
			NSManagedObject *person = [[itemsArrayController arrangedObjects] objectAtIndex:row];
			NSManagedObject *publication;
			NSManagedObject *institution;
			NSManagedObject *relationship;
			NSManagedObject *mo;
			NSEnumerator *relationshipE;
            NSMutableArray *removedPersons = [[NSMutableArray alloc] initWithCapacity:[draggedURIs count]];
			
            while (moURI = [uriE nextObject]) {
				mo = [moc objectWithID:[[moc persistentStoreCoordinator] managedObjectIDForURIRepresentation:moURI]];
				if (mo == person) {
					continue;
				} else if ([[mo valueForKey:@"name"] isEqualToString:[person valueForKey:@"name"]] == NO) {
					NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Renaming Person", @"Renaming person warning message")
													 defaultButton:NSLocalizedString(@"Yes", @"OK")
												   alternateButton:NSLocalizedString(@"No", @"Cancel")
													   otherButton:nil
										 informativeTextWithFormat:NSLocalizedString(@"Do you want to identify person \"%@\" with \"%@\"? This will rename \"%@\" to \"%@\" everywhere.", @""), [mo valueForKeyPath:@"name"],  [person valueForKeyPath:@"name"], [mo valueForKeyPath:@"name"],  [person valueForKeyPath:@"name"]];
					int rv = [alert runModal];
					if (rv == NSAlertAlternateReturn)
						continue;
				}
				// TODO: change other relationships. How to handle one-way relationships, like groups?
				// update index
				relationshipE = [[mo valueForKey:@"publicationRelationships"] objectEnumerator];
				while (relationship = [relationshipE nextObject]) {
					publication = [relationship valueForKey:@"publication"];
					if ([[publication valueForKeyPath:@"contributorRelationships.@distinctUnionOfObjects.contributor"] containsObject:person] == NO)
						[relationship setValue:person forKey:@"contributor"];
				}
				relationshipE = [[mo valueForKey:@"institutionRelationships"] objectEnumerator];
				while (relationship = [relationshipE nextObject]) {
					institution = [relationship valueForKey:@"institution"];
					if ([[institution valueForKeyPath:@"personRelationships.@distinctUnionOfObjects.person"] containsObject:person] == NO)
						[relationship setValue:person forKey:@"person"];
				}
				[[person mutableSetValueForKey:@"notes"] unionSet:[mo valueForKey:@"notes"]];
				[[person mutableSetValueForKey:@"tags"] unionSet:[mo valueForKey:@"tags"]];
				[[person mutableSetValueForKey:@"containingGroups"] unionSet:[mo valueForKey:@"containingGroups"]];
                [removedPersons addObject:mo];
			}
            [self removeItems:removedPersons];
            [removedPersons release];
            
			return YES;
            
		} else {
            
            // create relationships for other types
            return [super tableView:tv acceptDrop:info row:row dropOperation:op];
            
        }
	}
    
	return NO;
}

@end
