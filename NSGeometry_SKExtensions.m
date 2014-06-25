//
//  NSGeometry_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 8/22/07.
/*
 This software is Copyright (c) 2007-2014
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

BOOL SKPointNearLineFromPointToPoint(NSPoint point, NSPoint aPoint, NSPoint bPoint, CGFloat delta) {
    if (point.x < fmin(aPoint.x, bPoint.x) - delta || point.y < fmin(aPoint.y, bPoint.y) - delta || point.x > fmax(aPoint.x, bPoint.x) + delta || point.y > fmax(aPoint.y, bPoint.y) + delta)
        return NO;
    
    NSPoint relPoint = SKSubstractPoints(bPoint, aPoint);
    CGFloat extProduct = ( point.x - aPoint.x ) * relPoint.y - ( point.y - aPoint.y ) * relPoint.x;
    
    return extProduct * extProduct < delta * delta * ( relPoint.x * relPoint.x + relPoint.y * relPoint.y );
}

static inline BOOL SKPointNearCoordinates(NSPoint point, CGFloat x, CGFloat y, CGFloat delta) {
    NSRect rect;
    rect.origin.x = x - delta;
    rect.origin.y = y - delta;
    rect.size.width = rect.size.height = 2.0 * delta;
    return NSPointInRect(point, rect);
}

SKRectEdges SKResizeHandleForPointFromRect(NSPoint point, NSRect rect, CGFloat delta) {
    if (NSPointInRect(point, NSInsetRect(rect, -delta, -delta)) == NO)
        return 0;
    if (SKPointNearCoordinates(point, NSMaxX(rect), NSMinY(rect), delta))
        return SKMaxXEdgeMask | SKMinYEdgeMask;
    else if (SKPointNearCoordinates(point, NSMaxX(rect), NSMaxY(rect), delta))
        return SKMaxXEdgeMask | SKMaxYEdgeMask;
    else if (SKPointNearCoordinates(point, NSMinX(rect), NSMinY(rect), delta))
        return SKMinXEdgeMask | SKMinYEdgeMask;
    else if (SKPointNearCoordinates(point, NSMinX(rect), NSMaxY(rect), delta))
        return SKMinXEdgeMask | SKMaxYEdgeMask;
    else if (SKPointNearCoordinates(point, NSMaxX(rect), NSMidY(rect), delta))
        return SKMaxXEdgeMask;
    else if (SKPointNearCoordinates(point, NSMidX(rect), NSMinY(rect), delta))
        return SKMinYEdgeMask;
    else if (SKPointNearCoordinates(point, NSMidX(rect), NSMaxY(rect), delta))
        return SKMaxYEdgeMask;
    else if (SKPointNearCoordinates(point, NSMinX(rect), NSMidY(rect), delta))
        return SKMinXEdgeMask;
    else
        return 0;
}

NSComparisonResult SKCompareRects(NSRect rect1, NSRect rect2) {
    CGFloat top1 = NSMaxY(rect1);
    CGFloat top2 = NSMaxY(rect2);
    
    if (top1 > top2)
        return NSOrderedAscending;
    else if (top1 < top2)
        return NSOrderedDescending;
    
    CGFloat left1 = NSMinX(rect1);
    CGFloat left2 = NSMinX(rect2);
    
    if (left1 < left2)
        return NSOrderedAscending;
    else if (left1 > left2)
        return NSOrderedDescending;
    else
        return NSOrderedSame;
}

NSComparisonResult SKCompareMirroredRects(NSRect rect1, NSRect rect2) {
    CGFloat top1 = NSMaxY(rect1);
    CGFloat top2 = NSMaxY(rect2);
    
    if (top1 > top2)
        return NSOrderedAscending;
    else if (top1 < top2)
        return NSOrderedDescending;
    
    CGFloat right1 = NSMaxX(rect1);
    CGFloat right2 = NSMaxX(rect2);
    
    if (right1 > right2)
        return NSOrderedAscending;
    else if (right1 < right2)
        return NSOrderedDescending;
    else
        return NSOrderedSame;
}
