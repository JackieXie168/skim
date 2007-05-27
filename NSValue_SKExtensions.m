//
//  NSValue_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 26/5/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "NSValue_SKExtensions.h"


@implementation NSValue (SKExtensions)

- (NSComparisonResult)boundsCompare:(NSValue *)aValue {
    NSRect rect1 = [self rectValue];
    NSRect rect2 = [aValue rectValue];
    float y1 = NSMaxY(rect1);
    float y2 = NSMaxY(rect2);
    
    if (y1 > y2)
        return NSOrderedAscending;
    else if (y1 < y2)
        return NSOrderedDescending;
    
    float x1 = NSMinX(rect1);
    float x2 = NSMinX(rect2);
    
    if (x1 < x2)
        return NSOrderedAscending;
    else if (x1 > x2)
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
    return [self rectValue].origin.x;
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
