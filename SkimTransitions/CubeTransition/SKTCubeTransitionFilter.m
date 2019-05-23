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

// we actually draw a pentagon, because we want to collapse the side at t=0 and t=1
static CGFloat ANGLE = 0.0;
static CGFloat SIN_1 = 0.0;
static CGFloat COS_1 = 0.0;
static CGFloat SIN_2 = 0.0;
static CGFloat COS_2 = 0.0;

+ (void)initialize {
    ANGLE = 0.4 * M_PI;
    SIN_1 = sin(0.5 * ANGLE);
    COS_1 = cos(0.5 * ANGLE);
    SIN_2 = sin(ANGLE);
    COS_2 = cos(ANGLE);
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
    CGFloat angle = (moveRight ? -1.0 : 1.0) * ANGLE * (t - 0.5);
    CGFloat s = sin(angle);
    CGFloat c = cos(angle);
    CGFloat ratio = width / (SIN_1 * height);
    CGFloat scaledHeight = 0.5 * height * (1.0 - COS_2) * COS_1;
    CGFloat y1 = scaledHeight / (COS_1 - COS_2 * (COS_2 * c - SIN_2 * s));
    CGFloat y2 = scaledHeight / (COS_1 - COS_2 * c);
    CGFloat y3 = scaledHeight / (COS_1 - COS_2 * (COS_2 * c + SIN_2 * s));
    CGFloat x1 = - ratio * y1 * (COS_2 * s + SIN_2 * c);
    CGFloat x2 = - ratio * y2 * s;
    CGFloat x3 = - ratio * y3 * (COS_2 * s - SIN_2 * c);
    
    CIFilter *perspectiveFilter1 = [CIFilter filterWithName:@"CIPerspectiveTransformWithExtent"];
    [perspectiveFilter1 setValue:moveRight ? inputTargetImage : inputImage forKey:kCIInputImageKey];
    [perspectiveFilter1 setValue:inputExtent forKey:kCIInputExtentKey];
    [perspectiveFilter1 setValue:[CIVector vectorWithX:x + x1 Y:y + y1] forKey:@"inputTopLeft"];
    [perspectiveFilter1 setValue:[CIVector vectorWithX:x + x1 Y:y - y1] forKey:@"inputBottomLeft"];
    [perspectiveFilter1 setValue:[CIVector vectorWithX:x + x2 Y:y + y2] forKey:@"inputTopRight"];
    [perspectiveFilter1 setValue:[CIVector vectorWithX:x + x2 Y:y - y2] forKey:@"inputBottomRight"];
    
    CIFilter *perspectiveFilter2 = [CIFilter filterWithName:@"CIPerspectiveTransformWithExtent"];
    [perspectiveFilter2 setValue:moveRight ? inputImage : inputTargetImage forKey:@"inputImage"];
    [perspectiveFilter2 setValue:inputExtent forKey:kCIInputExtentKey];
    [perspectiveFilter2 setValue:[CIVector vectorWithX:x + x2 Y:y + y2] forKey:@"inputTopLeft"];
    [perspectiveFilter2 setValue:[CIVector vectorWithX:x + x2 Y:y - y2] forKey:@"inputBottomLeft"];
    [perspectiveFilter2 setValue:[CIVector vectorWithX:x + x3 Y:y + y3] forKey:@"inputTopRight"];
    [perspectiveFilter2 setValue:[CIVector vectorWithX:x + x3 Y:y - y3] forKey:@"inputBottomRight"];
    
    BOOL backIs1 = (t < 0.5) == moveRight;
    CIFilter *compositingFilter = [CIFilter filterWithName:@"CISourceOverCompositing"];
    [compositingFilter setValue:[perspectiveFilter1 valueForKey:kCIOutputImageKey] forKey:backIs1 ? kCIInputBackgroundImageKey : kCIInputImageKey];
    [compositingFilter setValue:[perspectiveFilter2 valueForKey:kCIOutputImageKey] forKey:backIs1 ? kCIInputImageKey :kCIInputBackgroundImageKey];
    
    return [compositingFilter valueForKey:kCIOutputImageKey];
}

@end
