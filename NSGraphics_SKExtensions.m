//
//  NSGraphics_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 10/20/11.
/*
 This software is Copyright (c) 2011-2014
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

#import "NSGraphics_SKExtensions.h"
#import "NSGeometry_SKExtensions.h"
#import "NSColor_SKExtensions.h"


void SKDrawResizeHandle(NSPoint point, CGFloat radius, BOOL active)
{
    NSBezierPath *path = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(point.x - 0.875 * radius, point.y - 0.875 * radius, 1.75 * radius, 1.75 * radius)];
    [path setLineWidth:0.25 * radius];
    [(active ? [NSColor selectionHighlightInteriorColor] : [NSColor disabledSelectionHighlightInteriorColor]) setFill];
    [(active ? [NSColor selectionHighlightColor] : [NSColor disabledSelectionHighlightColor]) setStroke];
    [path fill];
    [path stroke];
}

void SKDrawResizeHandles(NSRect rect, CGFloat radius, BOOL active)
{
    SKDrawResizeHandle(NSMakePoint(NSMinX(rect), NSMidY(rect)), radius, active);
    SKDrawResizeHandle(NSMakePoint(NSMidX(rect), NSMaxY(rect)), radius, active);
    SKDrawResizeHandle(NSMakePoint(NSMidX(rect), NSMinY(rect)), radius, active);
    SKDrawResizeHandle(NSMakePoint(NSMaxX(rect), NSMidY(rect)), radius, active);
    SKDrawResizeHandle(NSMakePoint(NSMinX(rect), NSMaxY(rect)), radius, active);
    SKDrawResizeHandle(NSMakePoint(NSMinX(rect), NSMinY(rect)), radius, active);
    SKDrawResizeHandle(NSMakePoint(NSMaxX(rect), NSMaxY(rect)), radius, active);
    SKDrawResizeHandle(NSMakePoint(NSMaxX(rect), NSMinY(rect)), radius, active);
}

#pragma mark -

void SKDrawTextFieldBezel(NSRect rect, NSView *controlView) {
    static NSTextFieldCell *cell = nil;
    if (cell == nil) {
        cell = [[NSTextFieldCell alloc] initTextCell:@""];
        [cell setBezeled:YES];
    }
    [cell drawWithFrame:rect inView:controlView];
    [cell setControlView:nil];
}

#pragma mark -

#define MIN_BUTTON_WIDTH 82.0
#define MAX_BUTTON_WIDTH 100.0
#define EXTRA_BUTTON_WIDTH 12.0

void SKShiftAndResizeViews(NSArray *views, CGFloat dx, CGFloat dw) {
    for (NSView *view in views)
       SKShiftAndResizeView(view, dx, dw);
}

void SKShiftAndResizeView(NSView *view, CGFloat dx, CGFloat dw) {
    NSRect frame = [view frame];
    frame.origin.x += dx;
    frame.size.width += dw;
    [view setFrame:frame];
}

void SKResizeWindow(NSWindow *window, CGFloat dw) {
    NSRect frame = [window frame];
    frame.size.width += dw;
    [window setFrame:frame display:NO];
}

void SKAutoSizeButtons(NSArray *buttons, BOOL rightAlign) {
    if ([buttons count] == 0)
        return;
    NSButton *button = [buttons objectAtIndex:0];
    CGFloat x = rightAlign ? NSMaxX([button frame]) : NSMinX([button frame]);
    CGFloat width = 0.0;
    for (button in buttons) {
        [button sizeToFit];
        width = fmax(width, NSWidth([button frame]) + EXTRA_BUTTON_WIDTH);
    }
    width = fmin(MAX_BUTTON_WIDTH, fmax(MIN_BUTTON_WIDTH, width));
    for (button in buttons) {
        NSRect frame = [button frame];
        frame.size.width = fmax(width, NSWidth(frame) + EXTRA_BUTTON_WIDTH);
        if (rightAlign) {
            x -= NSWidth(frame);
            frame.origin.x = x;
        } else {
            frame.origin.x = x;
            x += NSWidth(frame);
        }
        [button setFrame:frame];
    }
}

CGFloat SKAutoSizeLabelFields(NSArray *labelFields, NSArray *controls, BOOL resizeControls) {
    if ([labelFields count] == 0)
        return 0.0;
    NSControl *control;
    NSRect frame;
    CGFloat left = CGFLOAT_MAX, width = 0.0, right, dw = -NSMaxX([[labelFields lastObject] frame]);
    for (control in labelFields) {
        [control sizeToFit];
        frame = [control frame];
        left = fmin(left, NSMinX(frame));
        width = fmax(width, NSWidth(frame));
    }
    right = left + width;
    for (control in labelFields) {
        frame = [control frame];
        frame.origin.x = right - NSWidth(frame);
        [control setFrame:frame];
    }
    dw += right;
    SKShiftAndResizeViews(controls, dw, resizeControls ? -dw : 0.0);
    return dw;
}

extern CGFloat SKAutoSizeLabelField(NSControl *labelField, NSControl *control, BOOL resizeControls) {
    return SKAutoSizeLabelFields([NSArray arrayWithObjects:labelField, nil], [NSArray arrayWithObjects:control, nil], resizeControls);
}
