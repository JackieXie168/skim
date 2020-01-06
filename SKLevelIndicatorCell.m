//
//  SKLevelIndicatorCell.m
//  Skim
//
//  Created by Christiaan Hofman on 10/31/08.
/*
 This software is Copyright (c) 2007-2020
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

#import "SKLevelIndicatorCell.h"
#import "NSGeometry_SKExtensions.h"

#define EDGE_HEIGHT 4.0

@implementation SKLevelIndicatorCell

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    BOOL drawDiscreteContinuous = ([self levelIndicatorStyle] == NSDiscreteCapacityLevelIndicatorStyle) && (NSWidth(cellFrame) + 1.0 < 3.0 * [self maxValue]);
    if (drawDiscreteContinuous)
        [self setLevelIndicatorStyle:NSContinuousCapacityLevelIndicatorStyle];
    [NSGraphicsContext saveGraphicsState];
    [[NSBezierPath bezierPathWithRect:cellFrame] addClip];
    CGFloat cellHeight = [self cellSize].height;
    if (fabs(NSHeight(cellFrame) - cellHeight) <= 0.0) {
        [super drawWithFrame:cellFrame inView:controlView];
    } else if (RUNNING_BEFORE(10_13)) {
        NSRect frame = SKCenterRectVertically(cellFrame, cellHeight, 0.0, [controlView isFlipped]);
        [NSGraphicsContext saveGraphicsState];
        [[NSBezierPath bezierPathWithRect:cellFrame] addClip];
        [super drawWithFrame:frame inView:controlView];
        [NSGraphicsContext restoreGraphicsState];
    } else if (NSHeight(cellFrame) <= 2.0 * (cellHeight - EDGE_HEIGHT)) {
        NSRect topFrame, bottomFrame, frame = cellFrame;
        NSDivideRect(cellFrame, &topFrame, &bottomFrame, floor(0.5 * NSHeight(cellFrame)), NSMinYEdge);
        frame.size.height = cellHeight;
        [NSGraphicsContext saveGraphicsState];
        [[NSBezierPath bezierPathWithRect:topFrame] addClip];
        [super drawWithFrame:frame inView:controlView];
        [NSGraphicsContext restoreGraphicsState];
        [NSGraphicsContext saveGraphicsState];
        [[NSBezierPath bezierPathWithRect:bottomFrame] addClip];
        frame.origin.y = NSMaxY(bottomFrame) -  cellHeight;
        [super drawWithFrame:frame inView:controlView];
        [NSGraphicsContext restoreGraphicsState];
    } else {
        NSRect topFrame, bottomFrame, restFrame, frame = cellFrame, midFrame;
        NSDivideRect(cellFrame, &topFrame, &bottomFrame, cellHeight - EDGE_HEIGHT, NSMinYEdge);
        NSDivideRect(bottomFrame, &bottomFrame, &restFrame, cellHeight - EDGE_HEIGHT, NSMaxYEdge);
        frame.size.height = cellHeight;
        [NSGraphicsContext saveGraphicsState];
        [[NSBezierPath bezierPathWithRect:topFrame] addClip];
        [super drawWithFrame:frame inView:controlView];
        [NSGraphicsContext restoreGraphicsState];
        do {
            NSDivideRect(restFrame, &midFrame, &restFrame, fmin(cellHeight - 2.0 * EDGE_HEIGHT, NSHeight(restFrame)), NSMinYEdge);
            [NSGraphicsContext saveGraphicsState];
            [[NSBezierPath bezierPathWithRect:midFrame] addClip];
            frame.origin.y = NSMinY(midFrame) - EDGE_HEIGHT;
            [super drawWithFrame:frame inView:controlView];
            [NSGraphicsContext restoreGraphicsState];
        } while (NSHeight(restFrame) > 0.0);
        frame.origin.y = NSMaxY(bottomFrame) -  cellHeight;
        [NSGraphicsContext saveGraphicsState];
        [[NSBezierPath bezierPathWithRect:bottomFrame] addClip];
        [super drawWithFrame:frame inView:controlView];
        [NSGraphicsContext restoreGraphicsState];
    }
    [NSGraphicsContext restoreGraphicsState];
    if (drawDiscreteContinuous)
        [self setLevelIndicatorStyle:NSDiscreteCapacityLevelIndicatorStyle];
}

@end
