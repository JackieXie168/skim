//
//  NSGeometry_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 8/22/07.
/*
 This software is Copyright (c) 2007-2010
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

#import "NSGeometry_SKExtensions.h"

NSPoint SKConstrainPointInRect(NSPoint point, NSRect boundary){
    if (point.x < NSMinX(boundary))
        point.x = NSMinX(boundary);
    else if (point.x > NSMaxX(boundary))
        point.x = NSMaxX(boundary);
    
    if (point.y < NSMinY(boundary))
        point.y = NSMinY(boundary);
    else if (point.y > NSMaxY(boundary))
        point.y = NSMaxY(boundary);
    
    return point;
}

NSRect SKConstrainRect(NSRect rect, NSRect boundary) {
    if (NSWidth(rect) > NSWidth(boundary))
        rect.size.width = NSWidth(boundary);
    if (NSHeight(rect) > NSHeight(boundary))
        rect.size.height = NSHeight(boundary);
    
    if (NSMinX(rect) < NSMinX(boundary))
        rect.origin.x = NSMinX(boundary);
    else if (NSMaxX(rect) > NSMaxX(boundary))
        rect.origin.x = NSMaxX(boundary) - NSWidth(rect);
    
    if (NSMinY(rect) < NSMinY(boundary))
        rect.origin.y = NSMinY(boundary);
    else if (NSMaxY(rect) > NSMaxY(boundary))
        rect.origin.y = NSMaxY(boundary) - NSHeight(rect);
    
    return rect;
}

NSRect SKIntersectionRect(NSRect rect, NSRect boundary) {
    CGFloat minX = fmin(fmax(NSMinX(rect), NSMinX(boundary)), NSMaxX(boundary));
    CGFloat maxX = fmax(fmin(NSMaxX(rect), NSMaxX(boundary)), NSMinX(boundary));
    CGFloat minY = fmin(fmax(NSMinY(rect), NSMinY(boundary)), NSMaxY(boundary));
    CGFloat maxY = fmax(fmin(NSMaxY(rect), NSMaxY(boundary)), NSMinY(boundary));
    return NSMakeRect(minX, minY, maxX - minX, maxY - minY);
}

NSRect SKCenterRect(NSRect rect, NSSize size, BOOL flipped) {
    rect.origin.x += 0.5 * (NSWidth(rect) - size.width);
    rect.origin.y += 0.5 * (NSHeight(rect) - size.height);
    rect.origin.y = flipped ? ceil(rect.origin.y)  : floor(rect.origin.y);
    rect.size = size;
    return rect;
}

NSRect SKCenterRectVertically(NSRect rect, CGFloat height, BOOL flipped) {
    rect.origin.y += 0.5 * (NSHeight(rect) - height);
    rect.origin.y = flipped ? ceil(rect.origin.y)  : floor(rect.origin.y);
    rect.size.height = height;
    return rect;
}

NSRect SKCenterRectHorizontally(NSRect rect, CGFloat width) {
    rect.origin.x += floor(0.5 * (NSWidth(rect) - width));
    rect.size.width = width;
    return rect;
}

BOOL SKPointNearLineFromPointToPoint(NSPoint point, NSPoint aPoint, NSPoint bPoint, CGFloat pointDelta, CGFloat lineDelta) {
    if (point.x < fmin(aPoint.x, bPoint.x) - pointDelta || point.y < fmin(aPoint.y, bPoint.y) - pointDelta || point.x > fmax(aPoint.x, bPoint.x) + pointDelta || point.y > fmax(aPoint.y, bPoint.y) + pointDelta)
        return NO;
    
    NSPoint relPoint = SKSubstractPoints(bPoint, aPoint);
    CGFloat extProduct = ( point.x - aPoint.x ) * relPoint.y - ( point.y - aPoint.y ) * relPoint.x;
    
    return extProduct * extProduct < lineDelta * lineDelta * ( relPoint.x * relPoint.x + relPoint.y * relPoint.y );
}

#pragma mark -

#define MIN_BUTTON_WIDTH 82.0
#define MAX_BUTTON_WIDTH 100.0

void SKAutoSizeButtons(NSButton *defaultButton, NSButton *altButton) {
    CGFloat width, right = NSMaxX([defaultButton frame]);
    NSRect altFrame, defaultFrame;
    [altButton sizeToFit];
    [defaultButton sizeToFit];
    altFrame = altButton ? [altButton frame] : NSZeroRect;
    defaultFrame = [defaultButton frame];
    width = fmin(MAX_BUTTON_WIDTH, fmax(MIN_BUTTON_WIDTH, fmax(NSWidth(altFrame), NSWidth(defaultFrame))));
    altFrame.size.width = fmax(NSWidth(altFrame), width);
    defaultFrame.size.width = fmax(NSWidth(defaultFrame), width);
    defaultFrame.origin.x = right - NSWidth(defaultFrame);
    altFrame.origin.x = NSMinX(defaultFrame) - NSWidth(altFrame);
    [altButton setFrame:altFrame];
    [defaultButton setFrame:defaultFrame];
}

CGFloat SKAutoSizeLabelFields(NSArray *labelFields, NSArray *controls, BOOL resizeControls) {
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
    for (control in controls) {
        frame = [control frame];
        frame.origin.x += dw;
        if (resizeControls)
            frame.size.width -= dw;
        [control setFrame:frame];
    }
    return dw;
}

