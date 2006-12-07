//
//  BDSKUndoManager.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 14/12/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "BDSKUndoManager.h"


@implementation BDSKUndoManager

- (id)delegate
{
	return delegate;
}

- (void)setDelegate:(id)newDelegate
{
	delegate = newDelegate;
}

- (void)undo
{
	if (delegate && [delegate respondsToSelector:@selector(undoManagerShouldUndoChange:)] && 
		![delegate undoManagerShouldUndoChange:self]) {
		return;
	}
	[super undo];
}

@end
