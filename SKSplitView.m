//
//  SKSplitView.m
//  Skim
//
//  Created by Christiaan Hofman on 2/10/07.
/*
 This software is Copyright (c) 2007
 Christiaan Hofman. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

 - Neither the name of Christiaan Hofman nor the names of any
    contributors may be used to endorse or promote products derived
    from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

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
    if ([theEvent clickCount] > 1 && [[self delegate] respondsToSelector:@selector(splitView:doubleClickedDividerAt:)]) {
        NSPoint mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        NSArray *subviews = [self subviews];
        int i, count = [subviews count];
        id view;
        NSRect divRect;

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
            
            if (NSPointInRect(mouseLoc, divRect)) {
                [[self delegate] splitView:self doubleClickedDividerAt:i];
                return;
            }
        }
    }
    [super mouseDown:theEvent];
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
