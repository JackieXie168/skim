//
//  BDSKPopUpButton.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 14/12/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "BDSKPopUpButton.h"
#import "BDSKPopUpButtonCell.h"


@implementation BDSKPopUpButton

+ (Class)cellClass
{
	return [BDSKPopUpButtonCell class];
}

- (id)initWithFrame:(NSRect)frameRect
{
	// the default is pulldown
	self = [self initWithFrame:frameRect pullsDown:YES];
	return self;
}

- (id)initWithFrame:(NSRect)frameRect pullsDown:(BOOL)flag
{
	self = [super initWithFrame:frameRect pullsDown:flag];
	return self;
}

//this is called in IB, unfortunately it inits with an NSPopUpButtonCell
- (id)initWithCoder:(NSCoder *)coder
{
	self = [super initWithCoder:coder];
	
	if (self && ![[self cell] isKindOfClass:[BDSKPopUpButtonCell class]]) {
		BDSKPopUpButtonCell *cell = [[[BDSKPopUpButtonCell alloc] initImageCell:[self image] pullsDown:[self pullsDown]] autorelease];
		
		// copy the relevant data
		[cell setEnabled:[self isEnabled]];
		[cell setTransparent:[self isTransparent]];
		// only 0 and 8=NSShadowlessSquareBezelStyle are acceptable bezel styles
		[cell setBezelStyle:([self bezelStyle] & 7)? NSShadowlessSquareBezelStyle : [self bezelStyle]];
		[cell setBordered:[self isBordered]];
		if ([self alternateImage] != nil) 
			[cell setAlternateImage:[self alternateImage]];
		if ([self menu] != nil) {
			NSMenu *initialMenu = [self menu];
			[initialMenu removeItemAtIndex:0];
			[cell setMenu:initialMenu];
		}
		[self setCell:cell];
	}
	return self;
}

@end
