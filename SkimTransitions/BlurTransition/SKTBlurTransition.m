//
//  SKTBlurTransition.m
//  SkimTransitions
//
//  Created by Christiaan Hofman on 22/5/2019.
//  Copyright Christiaan Hofman 2019. All rights reserved.
//

#import "SKTBlurTransition.h"
#import <Foundation/Foundation.h>
#import <ApplicationServices/ApplicationServices.h>

#define kCIInputRectangleKey @"inputRectangle"

@implementation SKTBlurTransition

@synthesize inputImage, inputTargetImage, inputAngle, inputTime;

- (NSDictionary *)customAttributes
{
    return [NSDictionary dictionaryWithObjectsAndKeys:
        
        [NSDictionary dictionaryWithObjectsAndKeys:
             [NSNumber numberWithDouble:  -M_PI], kCIAttributeMin,
             [NSNumber numberWithDouble:  M_PI], kCIAttributeMax,
             [NSNumber numberWithDouble:  -M_PI], kCIAttributeSliderMin,
             [NSNumber numberWithDouble:  M_PI], kCIAttributeSliderMax,
             [NSNumber numberWithDouble:  0.0], kCIAttributeDefault,
             [NSNumber numberWithDouble:  0.0], kCIAttributeIdentity,
             kCIAttributeTypeAngle,            kCIAttributeType,
             nil],                             kCIInputAngleKey,
        
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
    CGFloat t1 = fmin(fmax(2.0 * t - 0.5, 0.0), 1.0);
    CGRect extent = CGRectUnion([inputImage extent], [inputTargetImage extent]);
    
    CIFilter *dissolveFilter = [CIFilter filterWithName:@"CIDissolveTransition"];
    [dissolveFilter setValue:inputImage forKey:kCIInputImageKey];
    [dissolveFilter setValue:inputTargetImage forKey:kCIInputTargetImageKey];
    [dissolveFilter setValue:[NSNumber numberWithDouble:t1] forKey:kCIInputTimeKey];
    
    CIFilter *clampFilter = [CIFilter filterWithName:@"CIAffineClamp"];
    [clampFilter setValue:[[dissolveFilter valueForKey:kCIOutputImageKey] imageByCroppingToRect:CGRectInset(extent, 1.0, 1.0)] forKey:kCIInputImageKey];
    [clampFilter setValue:[NSAffineTransform transform] forKey:kCIInputTransformKey];
    
    CIFilter *blurFilter = [CIFilter filterWithName:@"CIMotionBlur"];
    [blurFilter setValue:[clampFilter valueForKey:kCIOutputImageKey] forKey:kCIInputImageKey];
    [blurFilter setValue:[NSNumber numberWithDouble:50.0 * (0.5 - fabs(0.5 - t))] forKey:kCIInputRadiusKey];
    [blurFilter setValue:inputAngle forKey:kCIInputAngleKey];

    return [[blurFilter valueForKey:kCIOutputImageKey] imageByCroppingToRect:extent];
}

@end
