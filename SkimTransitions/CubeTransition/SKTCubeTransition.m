//
//  SKTCubeTransition.m
//  SkimTransitions
//
//  Created by Christiaan Hofman on 22/05/2019.
//  Copyright © 2019 Skim. All rights reserved.
//

#import "SKTCubeTransition.h"
#import <Foundation/Foundation.h>
#import <ApplicationServices/ApplicationServices.h>

#define kCIInputTopLeftKey @"inputTopLeft"
#define kCIInputTopRightKey @"inputTopRight"
#define kCIInputBottomLeftKey @"inputBottomLeft"
#define kCIInputBottomRightKey @"inputBottomRight"

@implementation SKTCubeTransition

- (NSDictionary *)customAttributes
{
    return [NSDictionary dictionaryWithObjectsAndKeys:
            
            [NSDictionary dictionaryWithObjectsAndKeys:
                 [CIVector vectorWithX:0.0 Y:0.0 Z:300.0 W:300.0], kCIAttributeDefault,
                 kCIAttributeTypeRectangle,          kCIAttributeType,
                 nil],                               kCIInputExtentKey,
            
            [NSDictionary dictionaryWithObjectsAndKeys:
                 [NSNumber numberWithDouble:  0.0], kCIAttributeMin,
                 [NSNumber numberWithDouble:  0.0], kCIAttributeMax,
                 [NSNumber numberWithDouble:  -M_PI], kCIAttributeSliderMin,
                 [NSNumber numberWithDouble:  M_PI], kCIAttributeSliderMax,
                 [NSNumber numberWithDouble:  0.0], kCIAttributeDefault,
                 [NSNumber numberWithDouble:  0.0], kCIAttributeIdentity,
                 kCIAttributeTypeAngle,             kCIAttributeType,
                 nil],                              kCIInputAngleKey,
            
            [NSDictionary dictionaryWithObjectsAndKeys:
                 [NSNumber numberWithDouble:  0.0], kCIAttributeMin,
                 [NSNumber numberWithDouble:  1.0], kCIAttributeMax,
                 [NSNumber numberWithDouble:  0.0], kCIAttributeSliderMin,
                 [NSNumber numberWithDouble:  1.0], kCIAttributeSliderMax,
                 [NSNumber numberWithDouble:  0.0], kCIAttributeDefault,
                 [NSNumber numberWithDouble:  0.0], kCIAttributeIdentity,
                 kCIAttributeTypeTime,              kCIAttributeType,
                 nil],                              kCIInputTimeKey,
            
            nil];
}

// we actually draw a pentagon, because we want to collapse the side at t=0 and t=1
static CGFloat ANGLE = 0.0;
static CGFloat TAN_1 = 0.0;
static CGFloat TAN_2 = 0.0;

+ (void)initialize {
    ANGLE = 0.4 * M_PI;
    TAN_1 = tan(0.5 * ANGLE);
    TAN_2 = tan(ANGLE);
}

static inline NSInteger directionForAngles(CGFloat angle, CGFloat cornerAngle) {
    while (angle <= M_PI)
        angle += 2.0 * M_PI;
    while (angle > M_PI)
        angle -= 2.0 * M_PI;
    if (angle > cornerAngle) {
        if (angle < M_PI - cornerAngle)
            return 1;
        else
            return 2;
    } else if (angle < -cornerAngle) {
        if (angle > cornerAngle - M_PI)
            return 3;
        else
            return 2;
    }
    return 0;
}

// called when setting up for fragment program and also calls fragment program
- (CIImage *)outputImage
{
    CGFloat t = [inputTime doubleValue];
    CGFloat angle = [inputAngle doubleValue];
    CGFloat width = [inputExtent Z];
    CGFloat height = [inputExtent W];
    CGFloat x = [inputExtent X] + 0.5 * width;
    CGFloat y = [inputExtent Y] + 0.5 * height;
    NSInteger direction = directionForAngles(angle, atan2(height, width));
    CGFloat angle1 = (direction > 1 ? -1.0 : 1.0) * ANGLE * t;
    CGFloat s1 = sin(angle1);
    CGFloat c1 = cos(angle1);
    CGFloat angle2 = (direction > 1 ? -1.0 : 1.0) * ANGLE * (t - 1.0);
    CGFloat s2 = sin(angle2);
    CGFloat c2 = cos(angle2);
    NSRect extent1 = NSRectFromCGRect([inputImage extent]);
    NSRect extent2 = NSRectFromCGRect([inputTargetImage extent]);
    CGFloat xl1 = NSMinX(extent1) - x;
    CGFloat xr1 = NSMaxX(extent1) - x;
    CGFloat yt1 = NSMaxY(extent1) - y;
    CGFloat yb1 = NSMinY(extent1) - y;
    CGFloat xl2 = NSMinX(extent2) - x;
    CGFloat xr2 = NSMaxX(extent2) - x;
    CGFloat yt2 = NSMaxY(extent2) - y;
    CGFloat yb2 = NSMinY(extent2) - y;
    NSPoint tl1, bl1, tr1, br1, tl2, bl2, tr2, br2;

    if (direction % 2 == 0) {
        CGFloat r = 0.5 * width / TAN_1;
        CGFloat d = 0.5 * width * TAN_2;
        CGFloat fl1 = d / (d + r - r * c1 - xl1 * s1);
        CGFloat fr1 = d / (d + r - r * c1 - xr1 * s1);
        CGFloat fl2 = d / (d + r - r * c2 - xl2 * s2);
        CGFloat fr2 = d / (d + r - r * c2 - xr2 * s2);
        
        tl1.x = bl1.x = fl1 * (-r * s1 + xl1 * c1);
        tr1.x = br1.x = fr1 * (-r * s1 + xr1 * c1);
        tl1.y = fl1 * yt1;
        bl1.y = fl1 * yb1;
        tr1.y = fr1 * yt1;
        br1.y = fr1 * yb1;
        
        tl2.x = bl2.x = fl2 * (-r * s2 + xl2 * c2);
        tr2.x = br2.x = fr2 * (-r * s2 + xr2 * c2);
        tl2.y = fl2 * yt2;
        bl2.y = fl2 * yb2;
        tr2.y = fr2 * yt2;
        br2.y = fr2 * yb2;
    } else {
        CGFloat r = 0.5 * height / TAN_1;
        CGFloat d = 0.5 * height * TAN_2;
        CGFloat ft1 = d / (d + r - r * c1 - yt1 * s1);
        CGFloat fb1 = d / (d + r - r * c1 - yb1 * s1);
        CGFloat ft2 = d / (d + r - r * c2 - yt2 * s2);
        CGFloat fb2 = d / (d + r - r * c2 - yb2 * s2);
        
        tl1.x = ft1 * xl1;
        tr1.x = ft1 * xr1;
        bl1.x = fb1 * xl1;
        br1.x = fb1 * xr1;
        tl1.y = tr1.y = ft1 * (-r * s1 + yt1 * c1);
        bl1.y = br1.y = fb1 * (-r * s1 + yb1 * c1);
        
        tl2.x = ft2 * xl2;
        tr2.x = ft2 * xr2;
        bl2.x = fb2 * xl2;
        br2.x = fb2 * xr2;
        tl2.y = tr2.y = ft2 * (-r * s2 + yt2 * c2);
        bl2.y = br2.y = fb2 * (-r * s2 + yb2 * c2);
    }
    
    CIFilter *perspectiveFilter1 = [CIFilter filterWithName:@"CIPerspectiveTransform"];
    [perspectiveFilter1 setValue:inputImage forKey:kCIInputImageKey];
    [perspectiveFilter1 setValue:[CIVector vectorWithX:x + tl1.x Y:y + tl1.y] forKey:kCIInputTopLeftKey];
    [perspectiveFilter1 setValue:[CIVector vectorWithX:x + bl1.x Y:y + bl1.y] forKey:kCIInputBottomLeftKey];
    [perspectiveFilter1 setValue:[CIVector vectorWithX:x + tr1.x Y:y + tr1.y] forKey:kCIInputTopRightKey];
    [perspectiveFilter1 setValue:[CIVector vectorWithX:x + br1.x Y:y + br1.y] forKey:kCIInputBottomRightKey];
    
    CIFilter *perspectiveFilter2 = [CIFilter filterWithName:@"CIPerspectiveTransform"];
    [perspectiveFilter2 setValue:inputTargetImage forKey:kCIInputImageKey];
    [perspectiveFilter2 setValue:[CIVector vectorWithX:x + tl2.x Y:y + tl2.y] forKey:kCIInputTopLeftKey];
    [perspectiveFilter2 setValue:[CIVector vectorWithX:x + bl2.x Y:y + bl2.y] forKey:kCIInputBottomLeftKey];
    [perspectiveFilter2 setValue:[CIVector vectorWithX:x + tr2.x Y:y + tr2.y] forKey:kCIInputTopRightKey];
    [perspectiveFilter2 setValue:[CIVector vectorWithX:x + br2.y Y:y + br2.y] forKey:kCIInputBottomRightKey];
    
    CIFilter *compositingFilter = [CIFilter filterWithName:@"CISourceOverCompositing"];
    [compositingFilter setValue:[perspectiveFilter1 valueForKey:kCIOutputImageKey] forKey:t > 0.5 ? kCIInputBackgroundImageKey : kCIInputImageKey];
    [compositingFilter setValue:[perspectiveFilter2 valueForKey:kCIOutputImageKey] forKey:t > 0.5 ? kCIInputImageKey :kCIInputBackgroundImageKey];
    
    return [compositingFilter valueForKey:kCIOutputImageKey];
}

@end
