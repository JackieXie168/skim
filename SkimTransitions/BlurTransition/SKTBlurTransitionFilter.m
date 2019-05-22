//
//  SKTBlurTransitionFilter.m
//  SkimTransitions
//
//  Created by Christiaan Hofman on 22/5/2019.
//  Copyright Christiaan Hofman 2019. All rights reserved.
//

#import "SKTBlurTransitionFilter.h"
#import <Foundation/Foundation.h>
#import <ApplicationServices/ApplicationServices.h>

@implementation SKTBlurTransitionFilter

- (NSDictionary *)customAttributes
{
    return [NSDictionary dictionaryWithObjectsAndKeys:

        [NSDictionary dictionaryWithObjectsAndKeys:
            [CIVector vectorWithX:300.0 Y:300.0], kCIAttributeDefault,
            kCIAttributeTypeRectangle,         kCIAttributeType,
            nil],                              @"inputExtent",
 
        [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithDouble:  0.0], kCIAttributeMin,
            [NSNumber numberWithDouble:  1.0], kCIAttributeMax,
            [NSNumber numberWithDouble:  0.0], kCIAttributeSliderMin,
            [NSNumber numberWithDouble:  1.0], kCIAttributeSliderMax,
            [NSNumber numberWithDouble:  0.0], kCIAttributeDefault,
            [NSNumber numberWithDouble:  0.0], kCIAttributeIdentity,
            kCIAttributeTypeTime,              kCIAttributeType,
            nil],                              @"inputTime",

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
        [generatorFilter setValue:[CIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0] forKey:@"inputColor"];
        CIFilter *compositingFilter = [CIFilter filterWithName:@"CISourceOverCompositing"];
        [compositingFilter setValue:image forKey:@"inputImage"];
        [compositingFilter setValue:[generatorFilter valueForKey:@"outputImage"] forKey:@"inputBackgroundImage"];
        image = [compositingFilter valueForKey:@"outputImage"];
    }
    
    CIFilter *blurFilter = [CIFilter filterWithName:@"CIMotionBlur"];
    [blurFilter setDefaults];
    [blurFilter setValue:image forKey:@"inputImage"];
    [blurFilter setValue:[NSNumber numberWithDouble:50.0 * (0.5 - fabs(0.5 - t))] forKey:@"inputRadius"];
    CIFilter *cropFilter = [CIFilter filterWithName:@"CICrop"];
    [cropFilter setValue:[blurFilter valueForKey:@"outputImage"] forKey:@"inputImage"];
    [cropFilter setValue:inputExtent forKey:@"inputRectangle"];
    
    return [cropFilter valueForKey:@"outputImage"];
}

@end
