//
//  SKSegmentedControl.m
//  Skim
//
//  Created by Christiaan Hofman on 10/19/08.
/*
 This software is Copyright (c) 2008
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

#import "SKSegmentedControl.h"
#import "NSImage_SKExtensions.h"
#import "NSGeometry_SKExtensions.h"


@implementation SKSegmentedControl

- (id)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        if ([self respondsToSelector:@selector(setSegmentStyle:)] == NO) {
            SKSegmentedCell *cell = [[[SKSegmentedCell alloc] init] autorelease];
            id oldCell = [self cell];
            unsigned int i, count = [self segmentCount];
            
            [cell setSegmentCount:count];
            [cell setTrackingMode:[oldCell trackingMode]];
            [cell setAction:[oldCell action]];
            [cell setTarget:[oldCell target]];
            [cell setTag:[oldCell tag]];
            [cell setEnabled:[oldCell isEnabled]];
            [cell setBezeled:NO];
            [cell setBordered:NO];
            
            for (i = 0; i < count; i++) {
                [cell setWidth:[oldCell widthForSegment:i] forSegment:i];
                [cell setImage:[oldCell imageForSegment:i] forSegment:i];
                [cell setLabel:[oldCell labelForSegment:i] forSegment:i];
                [cell setToolTip:[oldCell toolTipForSegment:i] forSegment:i];
                [cell setEnabled:[oldCell isEnabledForSegment:i] forSegment:i];
                [cell setSelected:[oldCell isSelectedForSegment:i] forSegment:i];
                [cell setMenu:[oldCell menuForSegment:i] forSegment:i];
                [cell setTag:[oldCell tagForSegment:i] forSegment:i];
            }
            
            [self setCell:cell];
        }
    }
    return self;
}

@end


@interface NSSegmentedCell (SKApplePrivateDeclarations)
- (int)_trackingSegment;
- (int)_keySegment;
@end


#define SEGMENT_HEIGHT          23.0
#define SEGMENT_HEIGHT_OFFSET   1.0
#define SEGMENT_CAP_WIDTH       15.0
#define SEGMENT_CAP_EXTRA_WIDTH 3.0
#define SEGMENT_SLIVER_WIDTH    1.0

@implementation SKSegmentedCell

- (BOOL)isPressedSegment:(int)segment {
    return [self isSelectedForSegment:segment] || ([self respondsToSelector:@selector(_trackingSegment)] && segment == [self _trackingSegment]);
}

- (void)drawWithFrame:(NSRect)frame inView:(NSView *)controlView {
    int i, count = [self segmentCount];
    int keySegment = [self respondsToSelector:@selector(_keySegment)] ? [self _keySegment] : -1;
    NSRect rect = SKCenterRectVertically(frame, SEGMENT_HEIGHT, [controlView isFlipped]), keyRect = NSZeroRect;
    
    for (i = 0; i < count; i++) {
        NSRect sideRect, midRect;
        NSRect capRect = NSMakeRect(0.0, 0.0, SEGMENT_CAP_WIDTH, SEGMENT_HEIGHT);
        NSRect sliverRect = NSMakeRect(0.0, 0.0, SEGMENT_SLIVER_WIDTH, SEGMENT_HEIGHT);
        rect.size.width = [self widthForSegment:i];
        midRect = rect;
        BOOL isPressed = [self isPressedSegment:i];
        NSImage *image;
        if (i == 0) {
            rect.size.width += SEGMENT_CAP_EXTRA_WIDTH;
            NSDivideRect(rect, &sideRect, &midRect, SEGMENT_CAP_WIDTH, NSMinXEdge);
            image = [NSImage imageNamed:isPressed ? @"Segment_LeftCapPress" : @"Segment_LeftCap"];
            [image drawFlipped:[controlView isFlipped] inRect:sideRect fromRect:capRect operation:NSCompositeSourceOver fraction:1.0];
        }
        if (i == count - 1) {
            rect.size.width += SEGMENT_CAP_EXTRA_WIDTH;
            midRect.size.width += SEGMENT_CAP_EXTRA_WIDTH;
            NSDivideRect(midRect, &sideRect, &midRect, SEGMENT_CAP_WIDTH, NSMaxXEdge);
            image = [NSImage imageNamed:isPressed ? @"Segment_RightCapPress" : @"Segment_RightCap"];
            [image drawFlipped:[controlView isFlipped] inRect:sideRect fromRect:capRect operation:NSCompositeSourceOver fraction:1.0];
        } else {
            NSDivideRect(midRect, &sideRect, &midRect, -SEGMENT_SLIVER_WIDTH, NSMaxXEdge);
            NSDivideRect(midRect, &sideRect, &midRect, SEGMENT_SLIVER_WIDTH, NSMaxXEdge);
            image = [NSImage imageNamed:isPressed || [self isPressedSegment:i + 1] ? @"Segment_SeparatorPress" : @"Segment_Separator"];
            [image drawFlipped:[controlView isFlipped] inRect:sideRect fromRect:sliverRect operation:NSCompositeSourceOver fraction:1.0];
        }
        if (NSWidth(midRect) > 0.0) {
            image = [NSImage imageNamed:isPressed ? @"Segment_MiddlePress" : @"Segment_Middle"];
            [image drawFlipped:[controlView isFlipped] inRect:midRect fromRect:sliverRect operation:NSCompositeSourceOver fraction:1.0];
        }
        if (keySegment == i && [[controlView window] isKeyWindow] && [[controlView window] firstResponder] == controlView)
            NSDivideRect(rect, &sideRect, &keyRect, SEGMENT_HEIGHT_OFFSET, [controlView isFlipped] ? NSMaxYEdge : NSMinYEdge);
        rect.origin.x = NSMaxX(rect) + SEGMENT_SLIVER_WIDTH;
    }
    
    if (NSIsEmptyRect(keyRect) == NO) {
		[NSGraphicsContext saveGraphicsState];
		NSSetFocusRingStyle(NSFocusRingOnly);
        NSBezierPath *path = [NSBezierPath bezierPath];
        if (keySegment == 0) {
            [path moveToPoint:NSMakePoint(NSMaxX(keyRect), NSMaxY(keyRect))];
            [path appendBezierPathWithArcFromPoint:NSMakePoint(NSMinX(keyRect), NSMaxY(keyRect)) toPoint:NSMakePoint(NSMinX(keyRect), NSMidY(keyRect)) radius:0.5 * (SEGMENT_HEIGHT - SEGMENT_HEIGHT_OFFSET)];
            [path appendBezierPathWithArcFromPoint:NSMakePoint(NSMinX(keyRect), NSMinY(keyRect)) toPoint:NSMakePoint(NSMaxX(keyRect), NSMinY(keyRect)) radius:0.5 * (SEGMENT_HEIGHT - SEGMENT_HEIGHT_OFFSET)];
            [path lineToPoint:NSMakePoint(NSMaxX(keyRect), NSMinY(keyRect))];
            [path closePath];
        } else if (keySegment == count - 1) {
            [path moveToPoint:NSMakePoint(NSMinX(keyRect), NSMinY(keyRect))];
            [path appendBezierPathWithArcFromPoint:NSMakePoint(NSMaxX(keyRect), NSMinY(keyRect)) toPoint:NSMakePoint(NSMaxX(keyRect), NSMidY(keyRect)) radius:0.5 * (SEGMENT_HEIGHT - SEGMENT_HEIGHT_OFFSET)];
            [path appendBezierPathWithArcFromPoint:NSMakePoint(NSMaxX(keyRect), NSMaxY(keyRect)) toPoint:NSMakePoint(NSMinX(keyRect), NSMaxY(keyRect)) radius:0.5 * (SEGMENT_HEIGHT - SEGMENT_HEIGHT_OFFSET)];
            [path lineToPoint:NSMakePoint(NSMinX(keyRect), NSMaxY(keyRect))];
            [path closePath];
        } else {
            [path appendBezierPathWithRect:keyRect];
        }
        [path fill];
		[NSGraphicsContext restoreGraphicsState];
    }
    
    [self drawInteriorWithFrame:[self drawingRectForBounds:frame] inView:controlView];
}

@end
