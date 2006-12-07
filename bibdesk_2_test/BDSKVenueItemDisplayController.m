//
//  BDSKVenueItemDisplayController.m
//  bd2xtest
//
//  Created by Christiaan Hofman on 2/7/06.
//  Copyright 2006. All rights reserved.
//

#import "BDSKVenueItemDisplayController.h"
#import "BDSKDocument.h"
#import "NSTableView_BDSKExtensions.h"


@implementation BDSKVenueItemDisplayController

- (NSString *)windowNibName{
    return @"BDSKVenueItemDisplay";
}

- (void)awakeFromNib{
	[super awakeFromNib];
	[publicationsTableView registerForDraggedTypes:[NSArray arrayWithObjects:BDSKPublicationPboardType, nil]];
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
	NSPasteboard *pboard = [info draggingPasteboard];
	if (tv == publicationsTableView) {
		
        if ([[itemObjectController selectedObjects] count] != 1)
			return NSDragOperationNone;
		NSString *type = [pboard availableTypeFromArray:[NSArray arrayWithObjects:BDSKPublicationPboardType, nil]];
		if ([type isEqualToString:BDSKPublicationPboardType]) {
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
			return [self addRelationshipsFromPasteboard:pboard forType:type keyPath:@"publication"];
        
    }
    
	return NO;
}

@end
