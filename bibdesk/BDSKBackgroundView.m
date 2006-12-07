//
//  BDSKBackgroundView.m
//  BibDesk
//
//  Created by Christiaan Hofman on 26/2/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "BDSKBackgroundView.h"

@implementation BDSKBackgroundView
- (void)drawRect:(NSRect)rect
{
	float blur = 4.0;
	float offset = 2.0;
	NSSize size = [self bounds].size;
	NSRect viewRect = NSMakeRect(blur, blur + offset, size.width - 2 * blur, size.height - blur - offset);
	NSShadow *viewShadow = [[[NSShadow alloc] init] autorelease];
	[viewShadow setShadowOffset:NSMakeSize(0.0, - offset)];
	[viewShadow setShadowBlurRadius:blur];
	[viewShadow setShadowColor:[[NSColor blackColor] colorWithAlphaComponent:0.6]];
	
	[NSGraphicsContext saveGraphicsState];
	[viewShadow set];
 	[[[NSColor controlBackgroundColor] colorWithAlphaComponent:0.9] set]; // this is the white control background
	[NSBezierPath fillRect:viewRect];
	[NSGraphicsContext restoreGraphicsState];
	
	[super drawRect:rect];
}
@end
