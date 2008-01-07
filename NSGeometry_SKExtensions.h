//
//  NSGeometry_SKExtensions.h
//  Skim
//
//  Created by Christiaan Hofman on 8/22/07.
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

#import <Cocoa/Cocoa.h>


static inline NSPoint SKIntegralPoint(NSPoint point) {
    return NSMakePoint(roundf(point.x), roundf(point.y));
}

static inline NSPoint SKAddPoints(NSPoint aPoint, NSPoint bPoint) {
    return NSMakePoint(aPoint.x + bPoint.x, aPoint.y + bPoint.y);
}

static inline NSPoint SKSubstractPoints(NSPoint aPoint, NSPoint bPoint) {
    return NSMakePoint(aPoint.x - bPoint.x, aPoint.y - bPoint.y);
}

static inline NSPoint SKBottomLeftPoint(NSRect rect) {
    return NSMakePoint(NSMinX(rect), NSMinY(rect));
}

static inline NSPoint SKBottomRightPoint(NSRect rect) {
    return NSMakePoint(NSMaxX(rect), NSMinY(rect));
}

static inline NSPoint SKTopLeftPoint(NSRect rect) {
    return NSMakePoint(NSMinX(rect), NSMaxY(rect));
}

static inline NSPoint SKTopRightPoint(NSRect rect) {
    return NSMakePoint(NSMaxX(rect), NSMaxY(rect));
}

static inline NSPoint SKCenterPoint(NSRect rect) {
    return NSMakePoint(NSMidX(rect), NSMidY(rect));
}

static inline NSSize SKMakeSquareSize(float width) {
    return NSMakeSize(width, width);
}

static inline NSRect SKRectFromPoints(NSPoint aPoint, NSPoint bPoint) {
    NSRect rect;
    rect.origin.x = fminf(aPoint.x, bPoint.x);
    rect.origin.y = fminf(aPoint.y, bPoint.y);
    rect.size.width = fmaxf(aPoint.x, bPoint.x) - NSMinX(rect);
    rect.size.height = fmaxf(aPoint.y, bPoint.y) - NSMinY(rect);
    return rect;
}

static inline NSRect SKIntegralRectFromPoints(NSPoint aPoint, NSPoint bPoint) {
    NSRect rect;
    rect.origin.x = floorf(fminf(aPoint.x, bPoint.x));
    rect.origin.y = floorf(fminf(aPoint.y, bPoint.y));
    rect.size.width = ceilf(fmaxf(aPoint.x, bPoint.x) - NSMinX(rect));
    rect.size.height = ceilf(fmaxf(aPoint.y, bPoint.y) - NSMinY(rect));
    return rect;
}

static inline NSRect SKRectFromCenterAndPoint(NSPoint center, NSPoint point) {
    NSRect rect;
    rect.size.width = 2.0 * fabsf(center.x - point.x);
    rect.size.height = 2.0 * fabsf(center.y - point.y);
    rect.origin.x = center.x - 0.5 * NSWidth(rect);
    rect.origin.y = center.y - 0.5 * NSHeight(rect);
    return rect;
}

static inline NSRect SKRectFromCenterAndSize(NSPoint center, NSSize size) {
    NSRect rect;
    rect.origin.x = center.x - 0.5 * size.width;
    rect.origin.y = center.y - 0.5 * size.height;
    rect.size = size;
    return rect;
}

extern NSPoint SKConstrainPointInRect(NSPoint point, NSRect boundary);
extern NSRect SKConstrainRect(NSRect rect, NSRect boundary);
extern NSRect SKIntersectionRect(NSRect rect, NSRect boundary);
