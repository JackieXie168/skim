//
//  SKTSlideTransition.m
//  SkimTransitions
//
//  Created by Christiaan Hofman on 22/05/2019.
//  Copyright © 2019 Skim. All rights reserved.
//

#import "SKTSlideTransition.h"
#import <Foundation/Foundation.h>
#import <ApplicationServices/ApplicationServices.h>

#define kCIInputRectangleKey @"inputRectangle"

@implementation SKTSlideTransition

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

// called when setting up for fragment program and also calls fragment program
- (CIImage *)outputImage
{
    CGFloat t = [inputTime doubleValue];
    CGFloat angle = [inputAngle doubleValue];
    CGFloat c = cos(angle);
    CGFloat s = sin(angle);
    CGFloat d1 = [inputExtent Z] * t / fmax(fabs(c), fabs(s));
    CGFloat d2 = [inputExtent Z] * (1.0 - t) / fmax(fabs(c), fabs(s));
    
    NSAffineTransform *transform;
    
    CIFilter *transformFilter1 = [CIFilter filterWithName:@"CIAffineTransform"];
    transform = [NSAffineTransform transform];
    [transform translateXBy:-d1 * c yBy:-d1 * s];
    [transformFilter1 setValue:inputImage forKey:kCIInputImageKey];
    [transformFilter1 setValue:transform forKey:kCIInputTransformKey];
    
    CIFilter *transformFilter2 = [CIFilter filterWithName:@"CIAffineTransform"];
    transform = [NSAffineTransform transform];
    [transform translateXBy:d2 * c yBy:d2 * s];
    [transformFilter2 setValue:inputTargetImage forKey:kCIInputImageKey];
    [transformFilter2 setValue:transform forKey:kCIInputTransformKey];
    
    CIFilter *compositingFilter = [CIFilter filterWithName:@"CISourceOverCompositing"];
    [compositingFilter setValue:[transformFilter1 valueForKey:kCIOutputImageKey] forKey:kCIInputImageKey];
    [compositingFilter setValue:[transformFilter2 valueForKey:kCIOutputImageKey] forKey:kCIInputBackgroundImageKey];
    
    CIFilter *cropFilter = [CIFilter filterWithName:@"CICrop"];
    [cropFilter setValue:[compositingFilter valueForKey:kCIOutputImageKey] forKey:kCIInputImageKey];
    [cropFilter setValue:inputExtent forKey:kCIInputRectangleKey];
    
    return [cropFilter valueForKey:kCIOutputImageKey];
}

@end
