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

@implementation SKTFlipTransitionFilter

- (NSDictionary *)customAttributes
{
    return [NSDictionary dictionaryWithObjectsAndKeys:
            
            [NSDictionary dictionaryWithObjectsAndKeys:
                 [CIVector vectorWithX:0.0 Y:0.0 Z:300.0 W:300.0], kCIAttributeDefault,
                 kCIAttributeTypeRectangle,          kCIAttributeType,
                 nil],                               @"inputExtent",
            
            [NSDictionary dictionaryWithObjectsAndKeys:
                 [NSNumber numberWithDouble:  0.0], kCIAttributeMin,
                 [NSNumber numberWithDouble:  1.0], kCIAttributeMax,
                 [NSNumber numberWithDouble:  0.0], kCIAttributeSliderMin,
                 [NSNumber numberWithDouble:  1.0], kCIAttributeSliderMax,
                 [NSNumber numberWithDouble:  0.0], kCIAttributeDefault,
                 [NSNumber numberWithDouble:  0.0], kCIAttributeIdentity,
                 kCIAttributeTypeTime,              kCIAttributeType,
                 nil],                              @"inputTime",
            
            [NSDictionary dictionaryWithObjectsAndKeys:
                 [NSNumber numberWithBool:NO], kCIAttributeDefault,
                 kCIAttributeTypeBoolean,          kCIAttributeType,
                 nil],                               @"inputRight",
            
            nil];
}

// called when setting up for fragment program and also calls fragment program
- (CIImage *)outputImage
{
    CGFloat t = [inputTime floatValue];
    BOOL flipRight = [inputRight boolValue];
    CGFloat width = [inputExtent Z];
    CGFloat height = [inputExtent W];
    CGFloat x = [inputExtent X] + 0.5 * width;
    CGFloat y = [inputExtent Y] + 0.5 * height;
    CGFloat angle = (0.5 - fabs(t - 0.5)) * M_PI * (flipRight ? -1.0 : 1.0);
    CGFloat s = sin(angle) * (t < 0.5 ? 1.0 : -1.0);
    CGFloat c = cos(angle);
    CGFloat xr = width * c / (2.0 - s);
    CGFloat xl = width * c / (2.0 + s);
    CGFloat yr = height / (2.0 - s);
    CGFloat yl = height / (2.0 + s);
    CIVector *topLeft = [CIVector vectorWithX:x - xl Y:y + yl];
    CIVector *topRight = [CIVector vectorWithX:x + xr Y:y + yr];
    CIVector *bottomLeft = [CIVector vectorWithX:x - xl Y:y - yl];
    CIVector *bottomRight = [CIVector vectorWithX:x + xr Y:y - yr];
    
    CIFilter *perspectiveFilter = [CIFilter filterWithName:@"CIPerspectiveTransformWithExtent"];
    [perspectiveFilter setValue:t < 0.5 ? inputImage : inputTargetImage forKey:@"inputImage"];
    [perspectiveFilter setValue:inputExtent forKey:@"inputExtent"];
    [perspectiveFilter setValue:topLeft forKey:@"inputTopLeft"];
    [perspectiveFilter setValue:topRight forKey:@"inputTopRight"];
    [perspectiveFilter setValue:bottomLeft forKey:@"inputBottomLeft"];
    [perspectiveFilter setValue:bottomRight forKey:@"inputBottomRight"];

    return [perspectiveFilter valueForKey:@"outputImage"];
}

@end
