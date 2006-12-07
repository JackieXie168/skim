//
//  BDSKPopUpButtonCell.h
//  Bibdesk
//
//  Created by Sven-S. Porst on Tue Aug 03 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>


@interface BDSKPopUpButtonCell : NSPopUpButtonCell {
	NSButtonCell *buttonCell;
}

- (id)initImageCell:(NSImage *)anImage pullsDown:(BOOL)pullDown;

@end
