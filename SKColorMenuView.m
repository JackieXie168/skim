//
//  SKColorMenuView.m
//  Skim
//
//  Created by Christiaan on 05/12/2019.
/*
This software is Copyright (c) 2019-2020
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

#import "SKColorMenuView.h"
#import <Quartz/Quartz.h>
#import "NSColor_SKExtensions.h"
#import "NSEvent_SKExtensions.h"
#import "PDFAnnotation_SKExtensions.h"

@interface SKColorMenuView (SKPrivate)
- (void)setup;
@end

@implementation SKColorMenuView

- (id)initWithAnnotation:(PDFAnnotation *)anAnnotation {
    self = [super init];
    if (self) {
        annotation = [anAnnotation retain];
        hoveredIndex = NSNotFound;
        [self setup];
    }
    return self;
}

- (void)dealloc {
    SKDESTROY(annotation);
    SKDESTROY(colors);
    [super dealloc];
}

- (NSRect)rectAtIndex:(NSUInteger)anIndex {
    return NSMakeRect(anIndex * 23.0 + 20.0, 0.0, 21.0, 21.0);
}

- (NSUInteger)indexForPoint:(NSPoint)point {
    NSUInteger i, iMax = [colors count];
    for (i = 0; i < iMax; i++) {
        if (NSPointInRect(point, [self rectAtIndex:i]))
            return i;
    }
    return NSNotFound;
}

- (void)setHoveredIndex:(NSUInteger)idx {
    if (hoveredIndex != idx) {
        if (hoveredIndex != NSNotFound)
            [self setNeedsDisplayInRect:[self rectAtIndex:hoveredIndex]];
        hoveredIndex = idx;
        if (hoveredIndex != NSNotFound)
            [self setNeedsDisplayInRect:[self rectAtIndex:hoveredIndex]];
    }
}

- (void)drawRect:(NSRect)dirtyRect {
    NSColor *borderColor = [[NSColor controlTextColor] colorWithAlphaComponent:0.2];
    NSUInteger i, iMax = [colors count];
    for (i = 0; i < iMax; i++) {
        NSRect rect = [self rectAtIndex:i];
        if (NSIntersectsRect(rect, dirtyRect) == NO) continue;
        if (i == hoveredIndex) {
            [NSGraphicsContext saveGraphicsState];
            [[borderColor colorWithAlphaComponent:0.15] setFill];
            [[borderColor colorWithAlphaComponent:0.1] setStroke];
            [[NSBezierPath bezierPathWithRoundedRect:rect xRadius:2.5 yRadius:2.5] fill];
            [[NSBezierPath bezierPathWithRoundedRect:NSInsetRect(rect, 0.5, 0.5) xRadius:2.0 yRadius:2.0] stroke];
            [NSGraphicsContext restoreGraphicsState];
        }
        rect = NSInsetRect(rect, 4.0, 4.0);
        [NSGraphicsContext saveGraphicsState];
        [[NSBezierPath bezierPathWithOvalInRect:rect] addClip];
        [[colors objectAtIndex:i] drawSwatchInRect:rect];
        [borderColor setStroke];
        [[NSBezierPath bezierPathWithOvalInRect:NSInsetRect(rect, 0.5, 0.5)] stroke];
        [NSGraphicsContext restoreGraphicsState];
    }
}

- (void)mouseEntered:(NSEvent *)theEvent {
    if ([[SKColorMenuView superclass] instancesRespondToSelector:_cmd])
        [super mouseEntered:theEvent];
    NSTrackingArea *area = [theEvent trackingArea];
    if (area) {
        NSRect rect = [area rect];
        [self setHoveredIndex:[self indexForPoint:NSMakePoint(NSMidX(rect), NSMidY(rect))]];
    }
}

- (void)mouseExited:(NSEvent *)theEvent {
    if ([[SKColorMenuView superclass] instancesRespondToSelector:_cmd])
        [super mouseExited:theEvent];
    if ([theEvent trackingArea])
        [self setHoveredIndex:NSNotFound];
}

- (void)mouseDown:(NSEvent *)theEvent {
    NSUInteger idx = [self indexForPoint:[theEvent locationInView:self]];
    if (idx != NSNotFound) {
        [self setHoveredIndex:idx];
        NSRect rect = [self rectAtIndex:idx];
        while (YES) {
            theEvent = [[self window] nextEventMatchingMask:NSLeftMouseUpMask | NSLeftMouseDraggedMask];
            BOOL inside = NSPointInRect([theEvent locationInView:self], rect);
            [self setHoveredIndex:inside ? idx : NSNotFound];
            if ([theEvent type] == NSLeftMouseUp) {
                if (inside) {
                    BOOL isShift = ([theEvent modifierFlags] & NSShiftKeyMask) != 0;
                    BOOL isAlt = ([theEvent modifierFlags] & NSAlternateKeyMask) != 0;
                    [annotation setColor:[colors objectAtIndex:idx] alternate:isAlt updateDefaults:isShift];
                    [[[self enclosingMenuItem] menu] cancelTracking];
                }
                break;
            }
        }
    }
}

- (void)setup {
    colors = [[NSColor favoriteColors] copy];
    
    [self setFrame:NSMakeRect(0.0, 0.0, [colors count] * 23.0 + 20.0, 21.0)];
    
    NSUInteger i, iMax = [colors count];
    for (i = 0; i < iMax; i++) {
        NSRect rect = [self rectAtIndex:i];
        NSTrackingArea *area = [[[NSTrackingArea alloc] initWithRect:rect options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp owner:self userInfo:nil] autorelease];
        [self addTrackingArea:area];
    }
}

@end
