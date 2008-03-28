//
//  NSValue_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 5/26/07.
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

#import "NSValue_SKExtensions.h"


@implementation NSValue (SKExtensions)

- (NSComparisonResult)boundsCompare:(NSValue *)aValue {
    NSRect rect1 = [self rectValue];
    NSRect rect2 = [aValue rectValue];
    float top1 = NSMaxY(rect1);
    float top2 = NSMaxY(rect2);
    
    if (top1 > top2)
        return NSOrderedAscending;
    else if (top1 < top2)
        return NSOrderedDescending;
    
    float left1 = NSMinX(rect1);
    float left2 = NSMinX(rect2);
    
    if (left1 < left2)
        return NSOrderedAscending;
    else if (left1 > left2)
        return NSOrderedDescending;
    else
        return NSOrderedSame;
}

- (NSString *)rectString {
    return NSStringFromRect([self rectValue]);
}

- (NSString *)pointString {
    return NSStringFromPoint([self pointValue]);
}

- (NSString *)originString {
    return NSStringFromPoint([self rectValue].origin);
}

- (NSString *)sizeString {
    return NSStringFromSize([self rectValue].size);
}

- (NSString *)midPointString {
    NSRect rect = [self rectValue];
    return NSStringFromPoint(NSMakePoint(NSMidX(rect), NSMidY(rect)));
}

- (float)rectX {
    return [self rectValue].origin.x;
}

- (float)rectY {
    return [self rectValue].origin.y;
}

- (float)rectWidth {
    return [self rectValue].size.width;
}

- (float)rectHeight {
    return [self rectValue].size.height;
}

- (float)pointX {
    return [self pointValue].x;
}

- (float)pointY {
    return [self pointValue].y;
}

@end
