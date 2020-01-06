//
//  SKTWarpFadeTransition.m
//  SkimTransitions
//
//  Created by Christiaan Hofman on 22/5/2019.
//  Copyright Christiaan Hofman 2019-2020. All rights reserved.
//

#import "SKTWarpFadeTransition.h"
#import <Foundation/Foundation.h>
#import <ApplicationServices/ApplicationServices.h>

@implementation SKTWarpFadeTransition

@synthesize inputImage, inputTargetImage, inputCenter, inputExtent, inputTime;

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
    CGFloat angle = -2.0 * M_PI * t;
    CGFloat radius = fmax(width, height);
    
    CIFilter *twirlFilter = [CIFilter filterWithName:@"CITwirlDistortion"];
    [twirlFilter setValue:inputImage forKey:kCIInputImageKey];
    [twirlFilter setValue:inputCenter forKey:kCIInputCenterKey];
    [twirlFilter setValue:[NSNumber numberWithDouble:radius] forKey:kCIInputRadiusKey];
    [twirlFilter setValue:[NSNumber numberWithDouble:angle] forKey:kCIInputAngleKey];
    
    CIFilter *dissolveFilter1 = [CIFilter filterWithName:@"CIDissolveTransition"];
    [dissolveFilter1 setValue:[twirlFilter valueForKey:kCIOutputImageKey] forKey:kCIInputImageKey];
    [dissolveFilter1 setValue:[CIImage emptyImage] forKey:kCIInputTargetImageKey];
    [dissolveFilter1 setValue:inputTime forKey:kCIInputTimeKey];
    
    CIFilter *dissolveFilter2 = [CIFilter filterWithName:@"CIDissolveTransition"];
    [dissolveFilter2 setValue:[CIImage emptyImage] forKey:kCIInputImageKey];
    [dissolveFilter2 setValue:inputTargetImage forKey:kCIInputTargetImageKey];
    [dissolveFilter2 setValue:inputTime forKey:kCIInputTimeKey];
    
    return [[dissolveFilter1 valueForKey:kCIOutputImageKey] imageByCompositingOverImage:[dissolveFilter2 valueForKey:kCIOutputImageKey]];
}

@end
