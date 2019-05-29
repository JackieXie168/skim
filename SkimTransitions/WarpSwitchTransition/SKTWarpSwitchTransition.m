//
//  SKTWarpSwitchTransition.m
//  SkimTransitions
//
//  Created by Christiaan Hofman on 22/5/2019.
//  Copyright Christiaan Hofman 2019. All rights reserved.
//

#import "SKTWarpSwitchTransition.h"
#import <Foundation/Foundation.h>
#import <ApplicationServices/ApplicationServices.h>

@implementation SKTWarpSwitchTransition

- (NSDictionary *)customAttributes
{
    return [NSDictionary dictionaryWithObjectsAndKeys:

        [NSDictionary dictionaryWithObjectsAndKeys:
            [CIVector vectorWithX:150.0 Y:150.0], kCIAttributeDefault,
            kCIAttributeTypePosition,          kCIAttributeType,
            nil],                              kCIInputCenterKey,
 
        [NSDictionary dictionaryWithObjectsAndKeys:
            [CIVector vectorWithX:0.0 Y:0.0 Z:300.0 W:300.0], kCIAttributeDefault,
            kCIAttributeTypeRectangle,          kCIAttributeType,
            nil],                               kCIInputExtentKey,
 
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
    CGFloat angle = ((2.0 * t - 1.0) * (2.0 * t - 1.0) - 1.0) * 2.0 * M_PI;
    CGFloat t1 = fmin(fmax(2.0 * (t - 0.25), 0.0), 1.0);
    CGFloat radius = fmax(width, height);
    
    CIFilter *dissolveFilter = [CIFilter filterWithName:@"CIDissolveTransition"];
    [dissolveFilter setValue:inputImage forKey:kCIInputImageKey];
    [dissolveFilter setValue:inputTargetImage forKey:kCIInputTargetImageKey];
    [dissolveFilter setValue:[NSNumber numberWithDouble:t1] forKey:kCIInputTimeKey];
    
    CIFilter *twirlFilter = [CIFilter filterWithName:@"CITwirlDistortion"];
    [twirlFilter setValue:t < 0.5 ? inputImage : inputTargetImage forKey:kCIInputImageKey];
    [twirlFilter setValue:inputCenter forKey:kCIInputCenterKey];
    [twirlFilter setValue:[NSNumber numberWithDouble:radius] forKey:kCIInputRadiusKey];
    [twirlFilter setValue:[NSNumber numberWithDouble:angle] forKey:kCIInputAngleKey];
    
    return [twirlFilter valueForKey:kCIOutputImageKey];
}

@end
