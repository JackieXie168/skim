//
//  SKSplitView.m
//  Skim
//
//  Created by Christiaan Hofman on 2/10/07.
/*
 This software is Copyright (c) 2007-2009
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

#define END_JOIN_WIDTH 3.0f

@implementation SKSplitView

+ (NSColor *)startColor{
    static NSColor *startColor = nil;
    if (startColor == nil)
        startColor = [[NSColor colorWithCalibratedWhite:0.95 alpha:1.0] retain];
    return startColor;
}

+ (NSColor *)endColor{
    static NSColor *endColor = nil;
    if (endColor == nil)
        endColor = [[NSColor colorWithCalibratedWhite:0.85 alpha:1.0] retain];
   return endColor;
}

- (id)initWithFrame:(NSRect)frameRect{
    if (self = [super initWithFrame:frameRect]) {
        blendEnds = NO;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder{
    if (self = [super initWithCoder:coder]) {
        blendEnds = NO;
    }
    return self;
}

- (void)mouseDown:(NSEvent *)theEvent {
    if ([theEvent clickCount] > 1 && [[self delegate] respondsToSelector:@selector(splitView:doubleClickedDividerAt:)]) {
        NSPoint mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        NSArray *subviews = [self subviews];
        NSInteger i, count = [subviews count];
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
            
            if (NSMouseInRect(mouseLoc, divRect, [self isFlipped])) {
                [[self delegate] splitView:self doubleClickedDividerAt:i];
                return;
            }
        }
    }
    [super mouseDown:theEvent];
}

- (void)drawDividerInRect:(NSRect)aRect {
    NSGradient *gradient = [[[NSGradient alloc] initWithStartingColor:[[self class] startColor] endingColor:[[self class] endColor]] autorelease];
    [gradient drawInRect:aRect angle:[self isVertical] ? 0.0 : 90.0];

    if (blendEnds) {
        NSRect endRect, ignored;
        
        NSDivideRect(aRect, &endRect, &ignored, END_JOIN_WIDTH, [self isVertical] ? NSMinYEdge : NSMinXEdge);
        gradient = [[[NSGradient alloc] initWithStartingColor:[[self class] endColor] endingColor:[[[self class] endColor] colorWithAlphaComponent:0.0]] autorelease];
        [gradient drawInRect:endRect angle:[self isVertical] ? 90.0 : 0.0];
        NSDivideRect(aRect, &endRect, &ignored, END_JOIN_WIDTH, [self isVertical] ? NSMaxYEdge : NSMaxXEdge);
        gradient = [[[NSGradient alloc] initWithStartingColor:[[self class] startColor] endingColor:[[[self class] startColor] colorWithAlphaComponent:0.0]] autorelease];
        [gradient drawInRect:endRect angle:[self isVertical] ? 270.0 : 180.0];
    }
    
    [NSGraphicsContext saveGraphicsState];
    
    // Draw the handle
    NSPoint startPoint, endPoint;
    CGFloat handleSize = 20.0;
    NSShadow *shade = [[[NSShadow alloc] init] autorelease];
    
    [shade setShadowBlurRadius:0.0];
    [shade setShadowColor:[NSColor colorWithCalibratedWhite:0.95 alpha:1.0]];
    [NSBezierPath setDefaultLineWidth:1.0];
    if ([self isVertical]) {
        handleSize = SKMin(handleSize, 2.0 * SKFloor(0.5 * NSHeight(aRect)));
        startPoint = NSMakePoint(NSMinX(aRect) + 1.5, NSMidY(aRect) - 0.5 * handleSize);
        endPoint = NSMakePoint(startPoint.x, startPoint.y + handleSize);
        [shade setShadowOffset:NSMakeSize(1.0, 0.0)];
        [shade set];
        [[NSColor colorWithCalibratedWhite:0.6 alpha:1.0] set];
        [NSBezierPath strokeLineFromPoint:startPoint toPoint:endPoint];
        startPoint.x += 2.0;
        endPoint.x += 2.0;
        [NSBezierPath strokeLineFromPoint:startPoint toPoint:endPoint];
    } else {
        handleSize = SKMin(handleSize, 2.0 * SKFloor(0.5 * NSWidth(aRect)));
        startPoint = NSMakePoint(NSMidX(aRect) - 0.5 * handleSize, NSMinY(aRect) + 1.5);
        endPoint = NSMakePoint(startPoint.x + handleSize, startPoint.y);
        [shade setShadowOffset:NSMakeSize(0.0, -1.0)];
        [shade set];
        [[NSColor colorWithCalibratedWhite:0.6 alpha:1.0] set];
        [NSBezierPath strokeLineFromPoint:startPoint toPoint:endPoint];
        startPoint.y += 2.0;
        endPoint.y += 2.0;
        [NSBezierPath strokeLineFromPoint:startPoint toPoint:endPoint];
    }
    
    [NSGraphicsContext restoreGraphicsState];
}

- (CGFloat)dividerThickness {
	return 6.0;
}

- (BOOL)blendEnds {
    return blendEnds;
}

- (void)setBlendEnds:(BOOL)flag {
    if (blendEnds != flag) {
        blendEnds = flag;
    }
}

@end
