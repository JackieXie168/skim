//
//  SKTCubeTransitionFilter.m
//  SkimTransitions
//
//  Created by Christiaan Hofman on 22/05/2019.
//  Copyright © 2019 Skim. All rights reserved.
//

#import "SKTCubeTransitionFilter.h"
#import <Foundation/Foundation.h>
#import <ApplicationServices/ApplicationServices.h>

@implementation SKTCubeTransitionFilter

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
                 nil],                             @"inputRight",
            
            nil];
}

// called when setting up for fragment program and also calls fragment program
- (CIImage *)outputImage
{
    CGFloat t = [inputTime floatValue];
    BOOL moveRight = [inputRight boolValue];
    CGFloat width = [inputExtent Z];
    CGFloat height = [inputExtent W];
    CGFloat x = [inputExtent X] + 0.5 * width;
    CGFloat y = [inputExtent Y] + 0.5 * height;
    CGFloat amount = 1.0;
    CGFloat angle1 = (0.5 - t) * M_PI_2;
    CGFloat angle2 = (0.5 + t) * M_PI_2;
    CGFloat s1 = sin(angle1);
    CGFloat c1 = cos(angle1);
    CGFloat s2 = sin(angle2);
    CGFloat c2 = cos(angle2);
    CGFloat x1 = -M_SQRT2 * width * s2 / (2.0 - amount * (M_SQRT2 * c2 - 1.0));
    CGFloat x2 = M_SQRT2 * width * s1 / (2.0 - amount * (M_SQRT2 * c1 - 1.0));
    CGFloat x3 = M_SQRT2 * width * s2 / (2.0 + amount * (M_SQRT2 * c2 + 1.0));
    CGFloat y1 = height / (2.0 - amount * (M_SQRT2 * c2 - 1.0));
    CGFloat y2 = height / (2.0 - amount * (M_SQRT2 * c1 - 1.0));
    CGFloat y3 = height / (2.0 + amount * (M_SQRT2 * c2 + 1.0));
    
    CIFilter *perspectiveFilter1 = [CIFilter filterWithName:@"CIPerspectiveTransformWithExtent"];
    [perspectiveFilter1 setValue:inputImage forKey:@"inputImage"];
    [perspectiveFilter1 setValue:inputExtent forKey:@"inputExtent"];
    
    CIFilter *perspectiveFilter2 = [CIFilter filterWithName:@"CIPerspectiveTransformWithExtent"];
    [perspectiveFilter2 setValue:inputTargetImage forKey:@"inputImage"];
    [perspectiveFilter2 setValue:inputExtent forKey:@"inputExtent"];
    
    if (moveRight) {
        [perspectiveFilter1 setValue:[CIVector vectorWithX:x - x2 Y:y + y2] forKey:@"inputTopLeft"];
        [perspectiveFilter1 setValue:[CIVector vectorWithX:x - x1 Y:y + y1] forKey:@"inputTopRight"];
        [perspectiveFilter1 setValue:[CIVector vectorWithX:x - x2 Y:y - y2] forKey:@"inputBottomLeft"];
        [perspectiveFilter1 setValue:[CIVector vectorWithX:x - x1 Y:y - y1] forKey:@"inputBottomRight"];
        [perspectiveFilter2 setValue:[CIVector vectorWithX:x - x3 Y:y + y3] forKey:@"inputTopLeft"];
        [perspectiveFilter2 setValue:[CIVector vectorWithX:x - x2 Y:y + y2] forKey:@"inputTopRight"];
        [perspectiveFilter2 setValue:[CIVector vectorWithX:x - x3 Y:y - y3] forKey:@"inputBottomLeft"];
        [perspectiveFilter2 setValue:[CIVector vectorWithX:x - x2 Y:y - y2] forKey:@"inputBottomRight"];
    } else {
        [perspectiveFilter1 setValue:[CIVector vectorWithX:x + x1 Y:y + y1] forKey:@"inputTopLeft"];
        [perspectiveFilter1 setValue:[CIVector vectorWithX:x + x2 Y:y + y2] forKey:@"inputTopRight"];
        [perspectiveFilter1 setValue:[CIVector vectorWithX:x + x1 Y:y - y1] forKey:@"inputBottomLeft"];
        [perspectiveFilter1 setValue:[CIVector vectorWithX:x + x2 Y:y - y2] forKey:@"inputBottomRight"];
        [perspectiveFilter2 setValue:[CIVector vectorWithX:x + x2 Y:y + y2] forKey:@"inputTopLeft"];
        [perspectiveFilter2 setValue:[CIVector vectorWithX:x + x3 Y:y + y3] forKey:@"inputTopRight"];
        [perspectiveFilter2 setValue:[CIVector vectorWithX:x + x2 Y:y - y2] forKey:@"inputBottomLeft"];
        [perspectiveFilter2 setValue:[CIVector vectorWithX:x + x3 Y:y - y3] forKey:@"inputBottomRight"];
    }

    CIFilter *compositingFilter = [CIFilter filterWithName:@"CISourceOverCompositing"];
    [compositingFilter setValue:[t < 0.5 ? perspectiveFilter1 : perspectiveFilter2 valueForKey:@"outputImage"] forKey:@"inputImage"];
    [compositingFilter setValue:[t < 0.5 ? perspectiveFilter2 : perspectiveFilter1 valueForKey:@"outputImage"] forKey:@"inputBackgroundImage"];
    
    return [compositingFilter valueForKey:@"outputImage"];
}

@end
