//
//  NSGeometry_SKExtensions.h
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

#import <UIKit/UIKit.h>

enum {
	SKNoEdgeMask = 0,
	SKMinXEdgeMask = 1 << CGRectMinXEdge,
	SKMinYEdgeMask = 1 << CGRectMinYEdge,
	SKMaxXEdgeMask = 1 << CGRectMaxXEdge,
	SKMaxYEdgeMask = 1 << CGRectMaxYEdge,
	SKEveryEdgeMask = SKMinXEdgeMask | SKMinYEdgeMask | SKMaxXEdgeMask | SKMaxYEdgeMask,
};
typedef NSUInteger SKRectEdges;

static inline CGPoint SKIntegralPoint(CGPoint point) {
    return CGPointMake(round(point.x), round(point.y));
}

static inline CGPoint SKAddPoints(CGPoint aPoint, CGPoint bPoint) {
    return CGPointMake(aPoint.x + bPoint.x, aPoint.y + bPoint.y);
}

static inline CGPoint SKSubstractPoints(CGPoint aPoint, CGPoint bPoint) {
    return CGPointMake(aPoint.x - bPoint.x, aPoint.y - bPoint.y);
}

static inline CGPoint SKBottomLeftPoint(CGRect rect) {
    return CGPointMake(CGRectGetMinX(rect), CGRectGetMinY(rect));
}

static inline CGPoint SKBottomRightPoint(CGRect rect) {
    return CGPointMake(CGRectGetMaxX(rect), CGRectGetMinY(rect));
}

static inline CGPoint SKTopLeftPoint(CGRect rect) {
    return CGPointMake(CGRectGetMinX(rect), CGRectGetMaxY(rect));
}

static inline CGPoint SKTopRightPoint(CGRect rect) {
    return CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect));
}

static inline CGPoint SKCenterPoint(CGRect rect) {
    return CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
}

static inline CGSize SKMakeSquareSize(CGFloat width) {
    return CGSizeMake(width, width);
}

static inline CGRect SKRectFromPoints(CGPoint aPoint, CGPoint bPoint) {
    CGRect rect;
    rect.origin.x = fmin(aPoint.x, bPoint.x);
    rect.origin.y = fmin(aPoint.y, bPoint.y);
    rect.size.width = fmax(aPoint.x, bPoint.x) - CGRectGetMinX(rect);
    rect.size.height = fmax(aPoint.y, bPoint.y) - CGRectGetMinY(rect);
    return rect;
}

static inline CGRect SKIntegralRectFromPoints(CGPoint aPoint, CGPoint bPoint) {
    CGRect rect;
    rect.origin.x = floor(fmin(aPoint.x, bPoint.x));
    rect.origin.y = floor(fmin(aPoint.y, bPoint.y));
    rect.size.width = ceil(fmax(aPoint.x, bPoint.x) - CGRectGetMinX(rect));
    rect.size.height = ceil(fmax(aPoint.y, bPoint.y) - CGRectGetMinY(rect));
    return rect;
}

static inline CGRect SKRectFromCenterAndPoint(CGPoint center, CGPoint point) {
    CGRect rect;
    rect.size.width = 2.0 * fabs(center.x - point.x);
    rect.size.height = 2.0 * fabs(center.y - point.y);
    rect.origin.x = center.x - 0.5 * CGRectGetWidth(rect);
    rect.origin.y = center.y - 0.5 * CGRectGetHeight(rect);
    return rect;
}

static inline CGRect SKRectFromCenterAndSize(CGPoint center, CGSize size) {
    CGRect rect;
    rect.origin.x = center.x - 0.5 * size.width;
    rect.origin.y = center.y - 0.5 * size.height;
    rect.size = size;
    return rect;
}

static inline CGRect SKRectFromCenterAndSquareSize(CGPoint center, CGFloat size) {
    CGRect rect;
    rect.origin.x = center.x - 0.5 * size;
    rect.origin.y = center.y - 0.5 * size;
    rect.size.width = size;
    rect.size.height = size;
    return rect;
}

static inline CGRect SKSliceRect(CGRect rect, CGFloat amount, CGRectEdge edge) {
    CGRect ignored;
    CGRectDivide(rect, &rect, &ignored, amount, edge);
    return rect;
}

static inline CGRect SKShrinkRect(CGRect rect, CGFloat amount, CGRectEdge edge) {
    CGRect ignored;
    CGRectDivide(rect, &ignored, &rect, amount, edge);
    return rect;
}

#pragma mark -

extern CGPoint SKConstrainPointInRect(CGPoint point, CGRect boundary);
extern CGRect SKConstrainRect(CGRect rect, CGRect boundary);
extern CGRect SKIntersectionRect(CGRect rect, CGRect boundary);

extern CGRect SKCenterRect(CGRect rect, CGSize size, BOOL flipped);
extern CGRect SKCenterRectVertically(CGRect rect, CGFloat height, BOOL flipped);
extern CGRect SKCenterRectHorizontally(CGRect rect, CGFloat width);

#pragma mark -

extern BOOL SKPointNearLineFromPointToPoint(CGPoint point, CGPoint startPoint, CGPoint endPoint, CGFloat delta);
extern SKRectEdges SKResizeHandleForPointFromRect(CGPoint point, CGRect rect, CGFloat delta);

#pragma mark -

extern NSComparisonResult SKCompareRects(CGRect rect1, CGRect rect2);

#pragma mark -

static inline
Rect SKQDRectFromCGRect(CGRect CGRect) {
    Rect qdRect;
    qdRect.left = round(CGRectGetMinX(CGRect));
    qdRect.bottom = round(CGRectGetMinY(CGRect));
    qdRect.right = round(CGRectGetMaxX(CGRect));
    qdRect.top = round(CGRectGetMaxY(CGRect));
    return qdRect;
}

static inline
CGRect SKCGRectFromQDRect(Rect qdRect) {
    CGRect CGRect;
    CGRect.origin.x = (CGFloat)qdRect.left;
    CGRect.origin.y = (CGFloat)qdRect.bottom;
    CGRect.size.width = (CGFloat)(qdRect.right - qdRect.left);
    CGRect.size.height = (CGFloat)(qdRect.top - qdRect.bottom);
    return CGRect;
}


static inline
Point SKQDPointFromCGPoint(CGPoint CGPoint) {
    Point qdPoint;
    qdPoint.h = round(CGPoint.x);
    qdPoint.v = round(CGPoint.y);
    return qdPoint;
}

static inline
CGPoint SKCGPointFromQDPoint(Point qdPoint) {
    CGPoint CGPoint;
    CGPoint.x = (CGFloat)qdPoint.h;
    CGPoint.y = (CGFloat)qdPoint.v;
    return CGPoint;
}
