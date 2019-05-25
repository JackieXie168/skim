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

- (NSDictionary *)customAttributes
{
    return [NSDictionary dictionaryWithObjectsAndKeys:

        [NSDictionary dictionaryWithObjectsAndKeys:
            [CIVector vectorWithX:300.0 Y:300.0], kCIAttributeDefault,
            kCIAttributeTypeRectangle,         kCIAttributeType,
            nil],                              kCIInputExtentKey,
 
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
    CIImage *image = t < 0.5 ? inputImage : inputTargetImage;
    NSRect extent = NSMakeRect([inputExtent X], [inputExtent Y], [inputExtent Z], [inputExtent W]);
    CGRect imgExtent = [image extent];
    
    if (NSContainsRect(*(NSRect*)&imgExtent, extent) == NO) {
        CIFilter *generatorFilter = [CIFilter filterWithName:@"CIConstantColorGenerator"];
        [generatorFilter setValue:[CIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0] forKey:kCIInputColorKey];
        CIFilter *compositingFilter = [CIFilter filterWithName:@"CISourceOverCompositing"];
        [compositingFilter setValue:image forKey:kCIInputImageKey];
        [compositingFilter setValue:[generatorFilter valueForKey:kCIOutputImageKey] forKey:kCIInputBackgroundImageKey];
        image = [compositingFilter valueForKey:kCIOutputImageKey];
    }
    
    CIFilter *blurFilter = [CIFilter filterWithName:@"CIMotionBlur"];
    [blurFilter setDefaults];
    [blurFilter setValue:image forKey:kCIInputImageKey];
    [blurFilter setValue:[NSNumber numberWithDouble:50.0 * (0.5 - fabs(0.5 - t))] forKey:kCIInputRadiusKey];
    CIFilter *cropFilter = [CIFilter filterWithName:@"CICrop"];
    [cropFilter setValue:[blurFilter valueForKey:kCIOutputImageKey] forKey:kCIInputImageKey];
    [cropFilter setValue:inputExtent forKey:kCIInputRectangleKey];
    
    return [cropFilter valueForKey:kCIOutputImageKey];
}

@end
