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
        startColor = [[CIColor colorWithNSColor:[NSColor colorWithCalibratedWhite:0.85 alpha:1.0]] retain];
    return startColor;
}

+ (CIColor *)endColor{
    static CIColor *endColor = nil;
    if (endColor == nil)
        endColor = [[CIColor colorWithNSColor:[NSColor colorWithCalibratedWhite:0.95 alpha:1.0]] retain];
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
            if ([self isVertical]) {
                divRect.origin.x = NSMaxX (divRect);
                divRect.size.width = [self dividerThickness];
            } else {
                divRect.origin.y = NSMaxY (divRect);
                divRect.size.height = [self dividerThickness];
            }
            
            if (NSPointInRect(mouseLoc, divRect)) {
                [[self delegate] splitView:self doubleClickedDividerAt:i];
                return;
            }
        }
    }
    [super mouseDown:theEvent];
}

- (void)drawDividerInRect:(NSRect)aRect {
    NSPoint startPoint, endPoint;
    float handleSize = 20.0;
    NSColor *darkColor = [NSColor colorWithCalibratedWhite:0.6 alpha:1.0];
    NSColor *lightColor = [NSColor colorWithCalibratedWhite:0.95 alpha:1.0];
    
    // Draw the gradient
    [[NSBezierPath bezierPathWithRect:aRect] fillPathVertically:NO == [self isVertical] withStartColor:[[self class] startColor] endColor:[[self class] endColor]];
    
    [NSGraphicsContext saveGraphicsState];
    
    // Draw the handle
    [NSBezierPath setDefaultLineWidth:1.0];
    
    if ([self isVertical]) {
        handleSize = fminf(handleSize, 2.0 * floorf(0.5 * NSHeight(aRect)));
        startPoint = NSMakePoint(NSMinX(aRect) + 1.5, NSMidY(aRect) - 0.5 * handleSize);
        endPoint = NSMakePoint(startPoint.x, startPoint.y + handleSize);
        [darkColor set];
        [NSBezierPath strokeLineFromPoint:startPoint toPoint:endPoint];
        startPoint.x += 2.0;
        endPoint.x += 2.0;
        [NSBezierPath strokeLineFromPoint:startPoint toPoint:endPoint];
        [lightColor set];
        startPoint.x -= 1.0;
        endPoint.x -= 1.0;
        [NSBezierPath strokeLineFromPoint:startPoint toPoint:endPoint];
        startPoint.x += 2.0;
        endPoint.x += 2.0;
        [NSBezierPath strokeLineFromPoint:startPoint toPoint:endPoint];
    } else {
        handleSize = fminf(handleSize, 2.0 * floorf(0.5 * NSWidth(aRect)));
        startPoint = NSMakePoint(NSMidX(aRect) - 0.5 * handleSize, NSMinY(aRect) + 1.5);
        endPoint = NSMakePoint(startPoint.x + handleSize, startPoint.y);
        [darkColor set];
        [NSBezierPath strokeLineFromPoint:startPoint toPoint:endPoint];
        startPoint.y += 2.0;
        endPoint.y += 2.0;
        [NSBezierPath strokeLineFromPoint:startPoint toPoint:endPoint];
        [lightColor set];
        startPoint.y -= 1.0;
        endPoint.y -= 1.0;
        [NSBezierPath strokeLineFromPoint:startPoint toPoint:endPoint];
        startPoint.y += 2.0;
        endPoint.y += 2.0;
        [NSBezierPath strokeLineFromPoint:startPoint toPoint:endPoint];
    }
    
    [NSGraphicsContext restoreGraphicsState];
}

- (float)dividerThickness {
	return 6.0;
}

@end
