//
//  SKSplitView.m
//  Skim
//
//  Created by Christiaan Hofman on 2/10/07.
/*
 This software is Copyright (c) 2007-2008
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

#define END_JOIN_WIDTH 3.0f

@implementation SKSplitView

+ (CIColor *)startColor{
    static CIColor *startColor = nil;
    if (startColor == nil)
        startColor = [[CIColor colorWithNSColor:[NSColor colorWithCalibratedWhite:0.95 alpha:1.0]] retain];
    return startColor;
}

+ (CIColor *)endColor{
    static CIColor *endColor = nil;
    if (endColor == nil)
        endColor = [[CIColor colorWithNSColor:[NSColor colorWithCalibratedWhite:0.85 alpha:1.0]] retain];
   return endColor;
}

- (id)initWithFrame:(NSRect)frameRect{
    if (self = [super initWithFrame:frameRect]) {
        blendEnds = NO;
        dividerLayer = NULL;
        minBlendLayer = NULL;
        maxBlendLayer = NULL;
    }
    return self;
}

- (void)dealloc {
    CGLayerRelease(dividerLayer);
    CGLayerRelease(minBlendLayer);
    CGLayerRelease(maxBlendLayer);
    [super dealloc];
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
    CGContextRef currentContext = [[NSGraphicsContext currentContext] graphicsPort];
    
    if (NULL == dividerLayer) {
        CGSize dividerSize = CGSizeMake(aRect.size.width, aRect.size.height);
        dividerLayer = CGLayerCreateWithContext(currentContext, dividerSize, NULL);
        [NSGraphicsContext saveGraphicsState];
        NSGraphicsContext *nsContext = [NSGraphicsContext graphicsContextWithGraphicsPort:CGLayerGetContext(dividerLayer) flipped:NO];
        [NSGraphicsContext setCurrentContext:nsContext];
        NSRect rectToFill = aRect;
        rectToFill.origin = NSZeroPoint;
        [[NSBezierPath bezierPathWithRect:rectToFill] fillPathVertically:NO == [self isVertical] withStartColor:[[self class] startColor] endColor:[[self class] endColor]];
        [NSGraphicsContext restoreGraphicsState];
    }
    CGContextDrawLayerInRect(currentContext, *(CGRect *)&aRect, dividerLayer);
    
    if (blendEnds) {
        NSRect endRect, ignored;
        
        NSDivideRect(aRect, &endRect, &ignored, END_JOIN_WIDTH, [self isVertical] ? NSMinYEdge : NSMinXEdge);
        if (NULL == minBlendLayer) {
            CGSize blendSize = CGSizeMake(endRect.size.width, endRect.size.height);
            minBlendLayer = CGLayerCreateWithContext(currentContext, blendSize, NULL);
            [NSGraphicsContext saveGraphicsState];
            NSGraphicsContext *nsContext = [NSGraphicsContext graphicsContextWithGraphicsPort:CGLayerGetContext(minBlendLayer) flipped:NO];
            [NSGraphicsContext setCurrentContext:nsContext];
            NSRect rectToFill = endRect;
            rectToFill.origin = NSZeroPoint;
            [[NSBezierPath bezierPathWithRect:rectToFill] fillPathVertically:[self isVertical] withStartColor:[[self class] endColor] endColor:[CIColor clearColor]];
            [NSGraphicsContext restoreGraphicsState];
        }
        CGContextDrawLayerInRect(currentContext, *(CGRect *)&endRect, minBlendLayer);
        
        NSDivideRect(aRect, &endRect, &ignored, END_JOIN_WIDTH, [self isVertical] ? NSMaxYEdge : NSMaxXEdge);
        if (NULL == maxBlendLayer) {
            CGSize blendSize = CGSizeMake(endRect.size.width, endRect.size.height);
            maxBlendLayer = CGLayerCreateWithContext(currentContext, blendSize, NULL);
            [NSGraphicsContext saveGraphicsState];
            NSGraphicsContext *nsContext = [NSGraphicsContext graphicsContextWithGraphicsPort:CGLayerGetContext(maxBlendLayer) flipped:NO];
            [NSGraphicsContext setCurrentContext:nsContext];
            NSRect rectToFill = endRect;
            rectToFill.origin = NSZeroPoint;
            [[NSBezierPath bezierPathWithRect:rectToFill] fillPathVertically:[self isVertical] withStartColor:[CIColor clearColor] endColor:[[self class] startColor]];
            [NSGraphicsContext restoreGraphicsState];
        }
        CGContextDrawLayerInRect(currentContext, *(CGRect *)&endRect, maxBlendLayer);
    }
    
    [NSGraphicsContext saveGraphicsState];
    
    // Draw the handle
    NSPoint startPoint, endPoint;
    float handleSize = 20.0;
    NSColor *darkColor = [NSColor colorWithCalibratedWhite:0.6 alpha:1.0];
    NSColor *lightColor = [NSColor colorWithCalibratedWhite:0.95 alpha:1.0];
    
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

- (BOOL)blendEnds {
    return blendEnds;
}

- (void)setBlendEnds:(BOOL)flag {
    if (blendEnds != flag) {
        blendEnds = flag;
        CGLayerRelease(minBlendLayer);
        minBlendLayer = NULL;
        CGLayerRelease(maxBlendLayer);
        maxBlendLayer = NULL;
    }
}

- (void)setVertical:(BOOL)flag {
    if ([self isVertical] != flag) {
        CGLayerRelease(dividerLayer);
        dividerLayer = NULL;
        CGLayerRelease(minBlendLayer);
        minBlendLayer = NULL;
        CGLayerRelease(maxBlendLayer);
        maxBlendLayer = NULL;
    }
    [super setVertical:flag];
}

@end
