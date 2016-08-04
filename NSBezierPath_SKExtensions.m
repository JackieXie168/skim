//
//  NSBezierPath_SKExtensions.m
//  Skim
//
//  Created by Adam Maxwell on 10/22/05.
/*
 This software is Copyright (c) 2005-2016
 Adam Maxwell. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 
 - Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 
 - Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in
 the documentation and/or other materials provided with the
 distribution.
 
 - Neither the name of Adam Maxwell nor the names of any
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

#import "NSBezierPath_SKExtensions.h"
#import "NSGeometry_SKExtensions.h"


@implementation NSBezierPath (SKExtensions)

- (NSArray *)dashPattern {
    NSInteger i, count = 0;
    NSMutableArray *array = [NSMutableArray array];
    [self getLineDash:NULL count:&count phase:NULL];
    if (count > 0) {
        CGFloat pattern[count];
        [self getLineDash:pattern count:&count phase:NULL];
        for (i = 0; i < count; i++)
            [array addObject:[NSNumber numberWithDouble:pattern[i]]];
    }
    return array;
}

- (void)setDashPattern:(NSArray *)newPattern {
    NSInteger i, count = [newPattern count];
    CGFloat pattern[count];
    for (i = 0; i< count; i++)
        pattern[i] = [[newPattern objectAtIndex:i] doubleValue];
    [self setLineDash:pattern count:count phase:0];
}

- (NSPoint)associatedPointForElementAtIndex:(NSUInteger)anIndex {
    NSPoint points[3];
    if (NSCurveToBezierPathElement == [self elementAtIndex:anIndex associatedPoints:points])
        return points[2];
    else
        return points[0];
}

- (NSRect)nonEmptyBounds {
    NSRect bounds = [self bounds];
    if (NSIsEmptyRect(bounds) && [self elementCount]) {
        NSPoint point, minPoint = NSZeroPoint, maxPoint = NSZeroPoint;
        NSUInteger i, count = [self elementCount];
        for (i = 0; i < count; i++) {
            point = [self associatedPointForElementAtIndex:i];
            if (i == 0) {
                minPoint = maxPoint = point;
            } else {
                minPoint.x = fmin(minPoint.x, point.x);
                minPoint.y = fmin(minPoint.y, point.y);
                maxPoint.x = fmax(maxPoint.x, point.x);
                maxPoint.y = fmax(maxPoint.y, point.y);
            }
        }
        bounds = NSMakeRect(minPoint.x - 0.1, minPoint.y - 0.1, maxPoint.x - minPoint.x + 0.2, maxPoint.y - minPoint.y + 0.2);
    }
    return bounds;
}

- (CGPathRef)CGPath {
    CGMutablePathRef mutablePath = CGPathCreateMutable();
    NSInteger numElements = [self elementCount];
    NSPoint points[3];
    NSInteger i;
    
    for (i = 0; i < numElements; i++) {
        switch ([self elementAtIndex:i associatedPoints:points]) {
            case NSMoveToBezierPathElement:
                CGPathMoveToPoint(mutablePath, NULL, points[0].x, points[0].y);
                break;
            case NSLineToBezierPathElement:
                CGPathAddLineToPoint(mutablePath, NULL, points[0].x, points[0].y);
                break;
            case NSCurveToBezierPathElement:
                CGPathAddCurveToPoint(mutablePath, NULL, points[0].x, points[0].y,points[1].x, points[1].y, points[2].x, points[2].y);
                break;
            case NSClosePathBezierPathElement:
                CGPathCloseSubpath(mutablePath);
                break;
        }
    }
    
    CGPathRef path = CGPathCreateCopy(mutablePath);
    CGPathRelease(mutablePath);
    
    return (CGPathRef)[(id)path autorelease];
}

@end

