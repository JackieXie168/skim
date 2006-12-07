//
//  NSTableView_BDSKExtensions.m
//  bd2xtest
//
//  Created by Christiaan Hofman on 2/5/06.
//  Copyright 2006. All rights reserved.
//

#import "NSTableView_BDSKExtensions.h"


@implementation NSTableView (BDSKExtensions)

- (BOOL)setValidDropRow:(int *)row dropOperation:(NSTableViewDropOperation)operation{
	if (*row < 0)
		*row = 0;
	if (operation == NSTableViewDropOn) {
		unsigned numRows = [self numberOfRows];
        if (numRows == 0) 
			return NO;
		if (*row >= numRows)
			*row = numRows - 1;
	}
	[self setDropRow:*row dropOperation:operation];
	return YES;
}

@end
