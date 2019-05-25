//
//  SKTFlipTransitionFilter.m
//  SkimTransitions
//
//  Created by Christiaan Hofman on 22/05/2019.
//  Copyright © 2019 Skim. All rights reserved.
//

#import "SKTFlipTransitionFilter.h"
#import <Foundation/Foundation.h>
#import <ApplicationServices/ApplicationServices.h>

#define kCIInputTopLeftKey @"inputTopLeft"
#define kCIInputTopRightKey @"inputTopRight"
#define kCIInputBottomLeftKey @"inputBottomLeft"
#define kCIInputBottomRightKey @"inputBottomRight"

@implementation SKTFlipTransitionFilter

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
    
    CIFilter *perspectiveFilter = [CIFilter filterWithName:@"CIPerspectiveTransformWithExtent"];
    [perspectiveFilter setValue:t < 0.5 ? inputImage : inputTargetImage forKey:kCIInputImageKey];
    [perspectiveFilter setValue:inputExtent forKey:kCIInputExtentKey];
    
    if (direction % 2 == 0) {
        CGFloat xr = width * c / (2.0 - s);
        CGFloat xl = width * c / (2.0 + s);
        CGFloat yr = height / (2.0 - s);
        CGFloat yl = height / (2.0 + s);
        [perspectiveFilter setValue:[CIVector vectorWithX:x - xl Y:y + yl] forKey:kCIInputTopLeftKey];
        [perspectiveFilter setValue:[CIVector vectorWithX:x + xr Y:y + yr] forKey:kCIInputTopRightKey];
        [perspectiveFilter setValue:[CIVector vectorWithX:x - xl Y:y - yl] forKey:kCIInputBottomLeftKey];
        [perspectiveFilter setValue:[CIVector vectorWithX:x + xr Y:y - yr] forKey:kCIInputBottomRightKey];
    } else {
        CGFloat xt = width / (2.0 - s);
        CGFloat xb = width / (2.0 + s);
        CGFloat yt = height * c / (2.0 - s);
        CGFloat yb = height * c / (2.0 + s);
        [perspectiveFilter setValue:[CIVector vectorWithX:x - xt Y:y + yt] forKey:kCIInputTopLeftKey];
        [perspectiveFilter setValue:[CIVector vectorWithX:x + xt Y:y + yt] forKey:kCIInputTopRightKey];
        [perspectiveFilter setValue:[CIVector vectorWithX:x - xb Y:y - yb] forKey:kCIInputBottomLeftKey];
        [perspectiveFilter setValue:[CIVector vectorWithX:x + xb Y:y - yb] forKey:kCIInputBottomRightKey];
    }

    return [perspectiveFilter valueForKey:kCIOutputImageKey];
}

@end
