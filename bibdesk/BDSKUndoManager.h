//
//  BDSKUndoManager.h
//  BibDesk
//
//  Created by Christiaan Hofman on 14/12/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface BDSKUndoManager : NSUndoManager {
	id delegate;
}

- (id)delegate;
- (void)setDelegate:(id)newDelegate;

@end

@interface NSObject (BDSKUndoManagerDelegate)

- (BOOL)undoManagerShouldUndoChange:(id)sender;

@end
