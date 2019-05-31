//
//  SKTSweepTransition.m
//  SkimTransitions
//
//  Created by Christiaan Hofman on 22/5/2019.
//  Copyright Christiaan Hofman 2019. All rights reserved.
//

#import "SKTSweepTransition.h"
#import <Foundation/Foundation.h>
#import <ApplicationServices/ApplicationServices.h>

#define kCIInputPoint0Key @"inputPoint0"
#define kCIInputPoint1Key @"inputPoint1"
#define kCIInputColor0Key @"inputColor0"
#define kCIInputColor1Key @"inputColor1"

@implementation SKTSweepTransition

@synthesize inputImage, inputTargetImage, inputExtent, inputAngle, inputWidth, inputTime;

- (NSDictionary *)customAttributes
{
    return [NSDictionary dictionaryWithObjectsAndKeys:
        
        [NSDictionary dictionaryWithObjectsAndKeys:
             [CIVector vectorWithX:300.0 Y:300.0], kCIAttributeDefault,
             kCIAttributeTypeRectangle,         kCIAttributeType,
             nil],                              kCIInputExtentKey,
        
        [NSDictionary dictionaryWithObjectsAndKeys:
             [NSNumber numberWithDouble:  -M_PI], kCIAttributeMin,
             [NSNumber numberWithDouble:  M_PI], kCIAttributeMax,
             [NSNumber numberWithDouble:  -M_PI], kCIAttributeSliderMin,
             [NSNumber numberWithDouble:  M_PI], kCIAttributeSliderMax,
             [NSNumber numberWithDouble:  0.0], kCIAttributeDefault,
             [NSNumber numberWithDouble:  0.0], kCIAttributeIdentity,
             kCIAttributeTypeAngle,             kCIAttributeType,
             nil],                              kCIInputAngleKey,
        
        [NSDictionary dictionaryWithObjectsAndKeys:
             [NSNumber numberWithDouble:  0.0], kCIAttributeMin,
             [NSNumber numberWithDouble:  500.0], kCIAttributeMax,
             [NSNumber numberWithDouble:  0.0], kCIAttributeSliderMin,
             [NSNumber numberWithDouble:  500.0], kCIAttributeSliderMax,
             [NSNumber numberWithDouble:  150.0], kCIAttributeDefault,
             kCIAttributeTypeDistance,          kCIAttributeType,
             nil],                              kCIInputWidthKey,
        
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

// called when setting up for fragment program and also calls fragment program
- (CIImage *)outputImage
{
    CGFloat t = [inputTime doubleValue];
    CGFloat angle = [inputAngle doubleValue];
    CGFloat c = cos(angle);
    CGFloat s = sin(angle);
    CGFloat width = [inputExtent Z];
    CGFloat height = [inputExtent W];
    CGFloat x = [inputExtent X];
    CGFloat y = [inputExtent Y];
    CGFloat w = [inputWidth doubleValue];
    CGFloat d = width * fabs(c) + height * fabs(s);
    CGFloat x1 = (c < 0.0 ? x + width : x) + (d + w) * t * c;
    CGFloat y1 = (s < 0.0 ? y + height : y) + (d + w) * t * s;
    CGFloat x0 = x1 - w * c;
    CGFloat y0 = y1 - w * s;

    CIFilter *gradientFilter = [CIFilter filterWithName:@"CILinearGradient"];
    [gradientFilter setValue:[CIVector vectorWithX:x0 Y:y0] forKey:kCIInputPoint0Key];
    [gradientFilter setValue:[CIVector vectorWithX:x1 Y:y1] forKey:kCIInputPoint1Key];
    [gradientFilter setValue:[CIColor colorWithRed:1.0 green:1.0 blue:1.0] forKey:kCIInputColor0Key];
    [gradientFilter setValue:[CIColor colorWithRed:0.0 green:0.0 blue:0.0] forKey:kCIInputColor1Key];

    CIFilter *blendFilter = [CIFilter filterWithName:@"CIBlendWithMask"];
    [blendFilter setValue:inputImage forKey:kCIInputBackgroundImageKey];
    [blendFilter setValue:inputTargetImage forKey:kCIInputImageKey];
    [blendFilter setValue:[gradientFilter valueForKey:kCIOutputImageKey] forKey:kCIInputMaskImageKey];

    return [blendFilter valueForKey:kCIOutputImageKey];
}

@end
