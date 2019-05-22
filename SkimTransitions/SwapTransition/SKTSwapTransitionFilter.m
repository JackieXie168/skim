//
//  SKTSwapTransitionFilter.m
//  SkimTransitions
//
//  Created by Christiaan Hofman on 22/05/2019.
//  Copyright © 2019 Skim. All rights reserved.
//

#import "SKTSwapTransitionFilter.h"
#import <Foundation/Foundation.h>
#import <ApplicationServices/ApplicationServices.h>

@implementation SKTSwapTransitionFilter

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
    BOOL swapRight = [inputRight boolValue];
    CGFloat width = [inputExtent Z];
    CGFloat height = [inputExtent W];
    CGFloat r = width;
    CGFloat x = [inputExtent X] + 0.5 * width;
    CGFloat y = [inputExtent Y] + 0.5 * height;
    CGFloat amount = 1.0;
    CGFloat angle = swapRight ? -t * M_PI : t * M_PI;
    CGFloat s = sin(angle);
    CGFloat c = cos(angle);
    CGFloat x1 = (- width - r * s) / (2.0 - amount * (c - 1.0));
    CGFloat x2 = (width - r * s) / (2.0 - amount * (c - 1.0));
    CGFloat x3 = (- width + r * s) / (2.0 + amount * (c + 1.0));
    CGFloat x4 = (width + r * s) / (2.0 + amount * (c + 1.0));
    CGFloat y1 = height / (2.0 - amount * (c - 1.0));
    CGFloat y3 = height / (2.0 + amount * (c + 1.0));
    CIVector *top1 = [CIVector vectorWithX:x + x1 Y:y + y1];
    CIVector *bottom1 = [CIVector vectorWithX:x + x1 Y:y - y1];
    CIVector *top2 = [CIVector vectorWithX:x + x2 Y:y + y1];
    CIVector *bottom2 = [CIVector vectorWithX:x + x2 Y:y - y1];
    CIVector *top3 = [CIVector vectorWithX:x + x3 Y:y + y3];
    CIVector *bottom3 = [CIVector vectorWithX:x + x3 Y:y - y3];
    CIVector *top4 = [CIVector vectorWithX:x + x4 Y:y + y3];
    CIVector *bottom4 = [CIVector vectorWithX:x + x4 Y:y - y3];

    CIFilter *perspectiveFilter1 = [CIFilter filterWithName:@"CIPerspectiveTransformWithExtent"];
    [perspectiveFilter1 setValue:inputImage forKey:@"inputImage"];
    [perspectiveFilter1 setValue:inputExtent forKey:@"inputExtent"];
    [perspectiveFilter1 setValue:top1 forKey:@"inputTopLeft"];
    [perspectiveFilter1 setValue:top2 forKey:@"inputTopRight"];
    [perspectiveFilter1 setValue:bottom1 forKey:@"inputBottomLeft"];
    [perspectiveFilter1 setValue:bottom2 forKey:@"inputBottomRight"];
    
    CIFilter *perspectiveFilter2 = [CIFilter filterWithName:@"CIPerspectiveTransformWithExtent"];
    [perspectiveFilter2 setValue:inputTargetImage forKey:@"inputImage"];
    [perspectiveFilter2 setValue:inputExtent forKey:@"inputExtent"];
    [perspectiveFilter2 setValue:top3 forKey:@"inputTopLeft"];
    [perspectiveFilter2 setValue:top4 forKey:@"inputTopRight"];
    [perspectiveFilter2 setValue:bottom3 forKey:@"inputBottomLeft"];
    [perspectiveFilter2 setValue:bottom4 forKey:@"inputBottomRight"];
    
    CIFilter *compositingFilter = [CIFilter filterWithName:@"CISourceOverCompositing"];
    [compositingFilter setValue:[t < 0.5 ? perspectiveFilter1 : perspectiveFilter2 valueForKey:@"outputImage"] forKey:@"inputImage"];
    [compositingFilter setValue:[t < 0.5 ? perspectiveFilter2 : perspectiveFilter1 valueForKey:@"outputImage"] forKey:@"inputBackgroundImage"];
    
    return [compositingFilter valueForKey:@"outputImage"];
}

@end
