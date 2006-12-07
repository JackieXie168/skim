//
//  BDSKTagItemDisplayController.m
//  bd2
//
//  Created by Christiaan Hofman on 2/8/06.
//  Copyright 2006. All rights reserved.
//

#import "BDSKTagItemDisplayController.h"
#import "BDSKDocument.h"
#import "NSTableView_BDSKExtensions.h"


@implementation BDSKTagItemDisplayController

- (NSString *)windowNibName{
    return @"BDSKTagItemDisplay";
}

- (void)awakeFromNib{
	[super awakeFromNib];
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
	return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView *)tv acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)op {
	return NO;
}

@end
