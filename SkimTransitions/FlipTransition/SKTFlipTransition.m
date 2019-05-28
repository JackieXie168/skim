//
//  SKTFlipTransition.m
//  SkimTransitions
//
//  Created by Christiaan Hofman on 22/05/2019.
//  Copyright © 2019 Skim. All rights reserved.
//

#import "SKTFlipTransition.h"
#import <Foundation/Foundation.h>
#import <ApplicationServices/ApplicationServices.h>

#define kCIInputTopLeftKey @"inputTopLeft"
#define kCIInputTopRightKey @"inputTopRight"
#define kCIInputBottomLeftKey @"inputBottomLeft"
#define kCIInputBottomRightKey @"inputBottomRight"

@implementation SKTFlipTransition

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
    CGFloat a = (0.5 - fabs(t - 0.5)) * M_PI * (direction > 1 ? -1.0 : 1.0);
    CGFloat s = sin(a) * (t < 0.5 ? 1.0 : -1.0);
    CGFloat c = cos(a);
    CIImage *image = t < 0.5 ? inputImage : inputTargetImage;
    NSRect extent = NSRectFromCGRect([image extent]);
    CGFloat yt = NSMaxY(extent) - y;
    CGFloat yb = NSMinY(extent) - y;
    CGFloat xl = NSMinX(extent) - x;
    CGFloat xr = NSMaxX(extent) - x;
    
    CIFilter *perspectiveFilter = [CIFilter filterWithName:@"CIPerspectiveTransform"];
    [perspectiveFilter setValue:image forKey:kCIInputImageKey];
    
    if (direction % 2 == 0) {
        CGFloat right = 1.0 / (1.0 - s * xr / width);
        CGFloat left = 1.0 / (1.0 - s * xl / width);
        [perspectiveFilter setValue:[CIVector vectorWithX:x + left * c * xl Y:y + left * yt] forKey:kCIInputTopLeftKey];
        [perspectiveFilter setValue:[CIVector vectorWithX:x + right * c * xr Y:y + right * yt] forKey:kCIInputTopRightKey];
        [perspectiveFilter setValue:[CIVector vectorWithX:x + left * c * xl Y:y + left * yb] forKey:kCIInputBottomLeftKey];
        [perspectiveFilter setValue:[CIVector vectorWithX:x + right * c * xr Y:y + right * yb] forKey:kCIInputBottomRightKey];
    } else {
        CGFloat top = 1.0 / (1.0 - s * yt / height);
        CGFloat bottom = 1.0 / (1.0 - s * yb / height);
        [perspectiveFilter setValue:[CIVector vectorWithX:x + top * xl Y:y + top * c * yt] forKey:kCIInputTopLeftKey];
        [perspectiveFilter setValue:[CIVector vectorWithX:x + top * xr Y:y + top * c * yt] forKey:kCIInputTopRightKey];
        [perspectiveFilter setValue:[CIVector vectorWithX:x + bottom * xl Y:y + bottom * c * yb] forKey:kCIInputBottomLeftKey];
        [perspectiveFilter setValue:[CIVector vectorWithX:x + bottom * xr Y:y + bottom * c * yb] forKey:kCIInputBottomRightKey];
    }

    return [perspectiveFilter valueForKey:kCIOutputImageKey];
}

@end
