//
//  SKSplitView.m
//  Skim
//
//  Created by Christiaan Hofman on 10/2/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "SKSplitView.h"
#import "NSBezierPath_CoreImageExtensions.h"
#import "CIImage_BDSKExtensions.h"


@implementation SKSplitView

+ (CIColor *)startColor{
    static CIColor *startColor = nil;
    if (startColor == nil)
        startColor = [[CIColor colorWithNSColor:[NSColor colorWithDeviceWhite:0.85 alpha:1.0]] retain];
    return startColor;
}

+ (CIColor *)endColor{
    static CIColor *endColor = nil;
    if (endColor == nil)
        endColor = [[CIColor colorWithNSColor:[NSColor colorWithDeviceWhite:0.95 alpha:1.0]] retain];
   return endColor;
}

- (void)mouseDown:(NSEvent *)theEvent {
    if ([theEvent clickCount] > 1) {
        NSPoint mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        NSEnumerator *viewEnum = [[self subviews] objectEnumerator];
        NSView *view = nil;
        
        while (view = [viewEnum nextObject]) {
            if (NSPointInRect(mouseLoc, [view frame]))
                break;
        }
        if (view == nil && [[self delegate] respondsToSelector:@selector(splitViewDoubleClick:)])
            [[self delegate] splitViewDoubleClick:self];
        else
            [super mouseDown:theEvent];
    } else {
        [super mouseDown:theEvent];
    }
}

- (void)drawRect:(NSRect)rect {
	
	NSArray *subviews = [self subviews];
	int i, count = [subviews count];
	id view;
	NSRect divRect;

	// draw the dimples 
	for (i = 0; i < (count-1); i++) {
		view = [subviews objectAtIndex:i];
		divRect = [view frame];
		if ([self isVertical] == NO) {
			divRect.origin.y = NSMaxY (divRect);
			divRect.size.height = [self dividerThickness];
		} else {
			divRect.origin.x = NSMaxX (divRect);
			divRect.size.width = [self dividerThickness];
		}
		if (NSIntersectsRect(rect, divRect)) {
			[[NSBezierPath bezierPathWithRect:divRect] fillPathVertically:![self isVertical] withStartColor:[[self class] startColor] endColor:[[self class] endColor]];
			[self drawDividerInRect: divRect];
		}
	}
}

- (float)dividerThickness {
	return 6.0;
}

@end
