//
//  NSGeometry_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 8/22/07.
/*
 This software is Copyright (c) 2007-2013
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

#import "UIGeometry_SKExtensions.h"

CGPoint SKConstrainPointInRect(CGPoint point, CGRect boundary){
    if (point.x < CGRectGetMinX(boundary))
        point.x = CGRectGetMinX(boundary);
    else if (point.x > CGRectGetMaxX(boundary))
        point.x = CGRectGetMaxX(boundary);
    
    if (point.y < CGRectGetMinY(boundary))
        point.y = CGRectGetMinY(boundary);
    else if (point.y > CGRectGetMaxY(boundary))
        point.y = CGRectGetMaxY(boundary);
    
    return point;
}

CGRect SKConstrainRect(CGRect rect, CGRect boundary) {
    if (CGRectGetWidth(rect) > CGRectGetWidth(boundary))
        rect.size.width = CGRectGetWidth(boundary);
    if (CGRectGetHeight(rect) > CGRectGetHeight(boundary))
        rect.size.height = CGRectGetHeight(boundary);
    
    if (CGRectGetMinX(rect) < CGRectGetMinX(boundary))
        rect.origin.x = CGRectGetMinX(boundary);
    else if (CGRectGetMaxX(rect) > CGRectGetMaxX(boundary))
        rect.origin.x = CGRectGetMaxX(boundary) - CGRectGetWidth(rect);
    
    if (CGRectGetMinY(rect) < CGRectGetMinY(boundary))
        rect.origin.y = CGRectGetMinY(boundary);
    else if (CGRectGetMaxY(rect) > CGRectGetMaxY(boundary))
        rect.origin.y = CGRectGetMaxY(boundary) - CGRectGetHeight(rect);
    
    return rect;
}

CGRect SKIntersectionRect(CGRect rect, CGRect boundary) {
    CGFloat minX = fmin(fmax(CGRectGetMinX(rect), CGRectGetMinX(boundary)), CGRectGetMaxX(boundary));
    CGFloat maxX = fmax(fmin(CGRectGetMaxX(rect), CGRectGetMaxX(boundary)), CGRectGetMinX(boundary));
    CGFloat minY = fmin(fmax(CGRectGetMinY(rect), CGRectGetMinY(boundary)), CGRectGetMaxY(boundary));
    CGFloat maxY = fmax(fmin(CGRectGetMaxY(rect), CGRectGetMaxY(boundary)), CGRectGetMinY(boundary));
    return CGRectMake(minX, minY, maxX - minX, maxY - minY);
}

CGRect SKCenterRect(CGRect rect, CGSize size, BOOL flipped) {
    rect.origin.x += 0.5 * (CGRectGetWidth(rect) - size.width);
    rect.origin.y += 0.5 * (CGRectGetHeight(rect) - size.height);
    rect.origin.y = flipped ? ceil(rect.origin.y)  : floor(rect.origin.y);
    rect.size = size;
    return rect;
}

CGRect SKCenterRectVertically(CGRect rect, CGFloat height, BOOL flipped) {
    rect.origin.y += 0.5 * (CGRectGetHeight(rect) - height);
    rect.origin.y = flipped ? ceil(rect.origin.y)  : floor(rect.origin.y);
    rect.size.height = height;
    return rect;
}

CGRect SKCenterRectHorizontally(CGRect rect, CGFloat width) {
    rect.origin.x += floor(0.5 * (CGRectGetWidth(rect) - width));
    rect.size.width = width;
    return rect;
}

BOOL SKPointNearLineFromPointToPoint(CGPoint point, CGPoint aPoint, CGPoint bPoint, CGFloat delta) {
    if (point.x < fmin(aPoint.x, bPoint.x) - delta || point.y < fmin(aPoint.y, bPoint.y) - delta || point.x > fmax(aPoint.x, bPoint.x) + delta || point.y > fmax(aPoint.y, bPoint.y) + delta)
        return NO;
    
    CGPoint relPoint = SKSubstractPoints(bPoint, aPoint);
    CGFloat extProduct = ( point.x - aPoint.x ) * relPoint.y - ( point.y - aPoint.y ) * relPoint.x;
    
    return extProduct * extProduct < delta * delta * ( relPoint.x * relPoint.x + relPoint.y * relPoint.y );
}

static inline BOOL SKPointNearCoordinates(CGPoint point, CGFloat x, CGFloat y, CGFloat delta) {
    CGRect rect;
    rect.origin.x = x - delta;
    rect.origin.y = y - delta;
    rect.size.width = rect.size.height = 2.0 * delta;
    return CGRectContainsPoint(rect, point);
}

SKRectEdges SKResizeHandleForPointFromRect(CGPoint point, CGRect rect, CGFloat delta) {
    if (CGRectContainsPoint(CGRectInset(rect, -delta, -delta), point) == NO)
        return 0;
    if (SKPointNearCoordinates(point, CGRectGetMaxX(rect), CGRectGetMinY(rect), delta))
        return SKMaxXEdgeMask | SKMinYEdgeMask;
    else if (SKPointNearCoordinates(point, CGRectGetMaxX(rect), CGRectGetMaxY(rect), delta))
        return SKMaxXEdgeMask | SKMaxYEdgeMask;
    else if (SKPointNearCoordinates(point, CGRectGetMinX(rect), CGRectGetMinY(rect), delta))
        return SKMinXEdgeMask | SKMinYEdgeMask;
    else if (SKPointNearCoordinates(point, CGRectGetMinX(rect), CGRectGetMaxY(rect), delta))
        return SKMinXEdgeMask | SKMaxYEdgeMask;
    else if (SKPointNearCoordinates(point, CGRectGetMaxX(rect), CGRectGetMidY(rect), delta))
        return SKMaxXEdgeMask;
    else if (SKPointNearCoordinates(point, CGRectGetMidX(rect), CGRectGetMinY(rect), delta))
        return SKMinYEdgeMask;
    else if (SKPointNearCoordinates(point, CGRectGetMidX(rect), CGRectGetMaxY(rect), delta))
        return SKMaxYEdgeMask;
    else if (SKPointNearCoordinates(point, CGRectGetMinX(rect), CGRectGetMidY(rect), delta))
        return SKMinXEdgeMask;
    else
        return 0;
}

NSComparisonResult SKCompareRects(CGRect rect1, CGRect rect2) {
    CGFloat top1 = CGRectGetMaxY(rect1);
    CGFloat top2 = CGRectGetMaxY(rect2);
    
    if (top1 > top2)
        return NSOrderedAscending;
    else if (top1 < top2)
        return NSOrderedDescending;
    
    CGFloat left1 = CGRectGetMinX(rect1);
    CGFloat left2 = CGRectGetMinX(rect2);
    
    if (left1 < left2)
        return NSOrderedAscending;
    else if (left1 > left2)
        return NSOrderedDescending;
    else
        return NSOrderedSame;
}
