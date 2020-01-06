//
//  SKTRadialSwipeTransition.m
//  SkimTransitions
//
//  Created by Christiaan Hofman on 22/5/2019.
//  Copyright Christiaan Hofman 2019-2020. All rights reserved.
//

#import "SKTRadialSwipeTransition.h"
#import <Foundation/Foundation.h>
#import <ApplicationServices/ApplicationServices.h>

#define kCIInputRadius0Key @"inputRadius0"
#define kCIInputRadius1Key @"inputRadius1"
#define kCIInputColor0Key @"inputColor0"
#define kCIInputColor1Key @"inputColor1"

@implementation SKTRadialSwipeTransition

@synthesize inputImage, inputTargetImage, inputExtent, inputWidth, inputTime;

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
             [NSNumber numberWithDouble:200.0], kCIAttributeDefault,
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
    CGFloat width = [inputExtent Z];
    CGFloat height = [inputExtent W];
    CGFloat x = [inputExtent X] + 0.5 * width;
    CGFloat y = [inputExtent Y] + 0.5 * height;
    CGFloat w = [inputWidth doubleValue];
    CGFloat r = sqrt(width * width + height * height);
    CGFloat r1 = (r + w) * t;
    CGFloat r0 = fmax(0.0, r1 - w);
    
    CIFilter *gradientFilter = [CIFilter filterWithName:@"CIRadialGradient"];
    [gradientFilter setValue:[CIVector vectorWithX:x Y:y] forKey:kCIInputCenterKey];
    [gradientFilter setValue:[NSNumber numberWithDouble:r0] forKey:kCIInputRadius0Key];
    [gradientFilter setValue:[NSNumber numberWithDouble:r1] forKey:kCIInputRadius1Key];
    [gradientFilter setValue:[CIColor colorWithRed:1.0 green:1.0 blue:1.0] forKey:kCIInputColor0Key];
    [gradientFilter setValue:[CIColor colorWithRed:0.0 green:0.0 blue:0.0] forKey:kCIInputColor1Key];
    
    CIFilter *blendFilter = [CIFilter filterWithName:@"CIBlendWithMask"];
    [blendFilter setValue:inputImage forKey:kCIInputBackgroundImageKey];
    [blendFilter setValue:inputTargetImage forKey:kCIInputImageKey];
    [blendFilter setValue:[gradientFilter valueForKey:kCIOutputImageKey] forKey:kCIInputMaskImageKey];
    
    return [blendFilter valueForKey:kCIOutputImageKey];
}

@end
