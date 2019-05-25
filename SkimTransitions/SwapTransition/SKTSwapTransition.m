//
//  SKTSwapTransition.m
//  SkimTransitions
//
//  Created by Christiaan Hofman on 22/05/2019.
//  Copyright © 2019 Skim. All rights reserved.
//

#import "SKTSwapTransition.h"
#import <Foundation/Foundation.h>
#import <ApplicationServices/ApplicationServices.h>

#define kCIInputTopLeftKey @"inputTopLeft"
#define kCIInputTopRightKey @"inputTopRight"
#define kCIInputBottomLeftKey @"inputBottomLeft"
#define kCIInputBottomRightKey @"inputBottomRight"

@implementation SKTSwapTransition

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
    CGFloat r = width;
    CGFloat x = [inputExtent X] + 0.5 * width;
    CGFloat y = [inputExtent Y] + 0.5 * height;
    NSInteger direction = directionForAngles(angle, atan2(height, width));
    CGFloat a = direction > 1 ? -M_PI * t : M_PI * t;
    CGFloat s = sin(a);
    CGFloat c = cos(a);
    CGFloat f1 = 1.0 / (2.0 - (c - 1.0));
    CGFloat f2 = 1.0 / (2.0 + (c + 1.0));
    CGFloat tn = 1.0;
    CGFloat cotn = 1.0;
    
    if (direction % 2 == 0) {
        tn = tan(angle);
        r = width;
    } else {
        cotn = 1.0 / tan(angle);
        r = height;
    }
    
    CGFloat x1 = f1 * (- width - r * s * cotn);
    CGFloat x2 = f1 * (width - r * s * cotn);
    CGFloat x3 = f2 * (- width + r * s * cotn);
    CGFloat x4 = f2 * (width + r * s * cotn);
    CGFloat y1 = f1 * (height - r * s * tn);
    CGFloat y2 = f1 * (- height - r * s * tn);
    CGFloat y3 = f2 * (height + r * s * tn);
    CGFloat y4 = f2 * (- height + r * s * tn);
    
    CIFilter *perspectiveFilter1 = [CIFilter filterWithName:@"CIPerspectiveTransformWithExtent"];
    [perspectiveFilter1 setValue:inputImage forKey:kCIInputImageKey];
    [perspectiveFilter1 setValue:inputExtent forKey:kCIInputExtentKey];
    [perspectiveFilter1 setValue:[CIVector vectorWithX:x + x1 Y:y + y1] forKey:kCIInputTopLeftKey];
    [perspectiveFilter1 setValue:[CIVector vectorWithX:x + x2 Y:y + y1] forKey:kCIInputTopRightKey];
    [perspectiveFilter1 setValue:[CIVector vectorWithX:x + x1 Y:y + y2] forKey:kCIInputBottomLeftKey];
    [perspectiveFilter1 setValue:[CIVector vectorWithX:x + x2 Y:y + y2] forKey:kCIInputBottomRightKey];
    
    CIFilter *perspectiveFilter2 = [CIFilter filterWithName:@"CIPerspectiveTransformWithExtent"];
    [perspectiveFilter2 setValue:inputTargetImage forKey:kCIInputImageKey];
    [perspectiveFilter2 setValue:inputExtent forKey:kCIInputExtentKey];
    [perspectiveFilter2 setValue:[CIVector vectorWithX:x + x3 Y:y + y3] forKey:kCIInputTopLeftKey];
    [perspectiveFilter2 setValue:[CIVector vectorWithX:x + x4 Y:y + y3] forKey:kCIInputTopRightKey];
    [perspectiveFilter2 setValue:[CIVector vectorWithX:x + x3 Y:y + y4] forKey:kCIInputBottomLeftKey];
    [perspectiveFilter2 setValue:[CIVector vectorWithX:x + x4 Y:y + y4] forKey:kCIInputBottomRightKey];
    
    CIFilter *compositingFilter = [CIFilter filterWithName:@"CISourceOverCompositing"];
    CIFilter *dissolveFilter = [CIFilter filterWithName:@"CIDissolveTransition"];
    [dissolveFilter setValue:[[CIImage alloc] init] forKey:kCIInputTargetImageKey];
    [dissolveFilter setValue:[NSNumber numberWithDouble:(2.0 * t - 1.0) * (2.0 * t - 1.0)] forKey:kCIInputTimeKey];
    if (t < 0.5) {
        [dissolveFilter setValue:[perspectiveFilter2 valueForKey:kCIOutputImageKey] forKey:kCIInputImageKey];
        [compositingFilter setValue:[perspectiveFilter1 valueForKey:kCIOutputImageKey] forKey:kCIInputImageKey];
        [compositingFilter setValue:[dissolveFilter valueForKey:kCIOutputImageKey] forKey:kCIInputBackgroundImageKey];
    } else {
        [dissolveFilter setValue:[perspectiveFilter1 valueForKey:kCIOutputImageKey] forKey:kCIInputImageKey];
        [compositingFilter setValue:[perspectiveFilter2 valueForKey:kCIOutputImageKey] forKey:kCIInputImageKey];
        [compositingFilter setValue:[dissolveFilter valueForKey:kCIOutputImageKey] forKey:kCIInputBackgroundImageKey];
    }
    
    return [compositingFilter valueForKey:kCIOutputImageKey];
}

@end
