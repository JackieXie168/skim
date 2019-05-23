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
static CGFloat SIN_3 = 0.0;
static CGFloat COS_3 = 0.0;
static CGFloat A = 0.0;
static CGFloat B = 0.0;

+ (void)initialize {
    ANGLE = 0.2 * M_PI;
    SIN_1 = sin(ANGLE);
    COS_1 = cos(ANGLE);
    SIN_3 = sin(3.0 * ANGLE);
    COS_3 = cos(3.0 * ANGLE);
    A = 1.0 / (SIN_1 * SIN_1);
    B = (2.0 - A) / COS_1;
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
    CGFloat angle = 2.0 * ANGLE * t;
    CGFloat s = sin(angle);
    CGFloat c = cos(angle);
    CGFloat C = width / (SIN_1 * height);
    CGFloat y1 = height / (A + B * (COS_1 * c - SIN_1 * s));
    CGFloat y2 = height / (A + B * (COS_1 * c + SIN_1 * s));
    CGFloat y3 = height / (A + B * (COS_3 * c + SIN_3 * s));
    CGFloat x1 = C * y1 * (- SIN_1 * c - COS_1 * s);
    CGFloat x2 = C * y2 * (SIN_1 * c - COS_1 * s);
    CGFloat x3 = C * y3 * (SIN_3 * c - COS_3 * s);
    
    CIFilter *perspectiveFilter1 = [CIFilter filterWithName:@"CIPerspectiveTransformWithExtent"];
    [perspectiveFilter1 setValue:inputImage forKey:@"inputImage"];
    [perspectiveFilter1 setValue:inputExtent forKey:@"inputExtent"];
    
    CIFilter *perspectiveFilter2 = [CIFilter filterWithName:@"CIPerspectiveTransformWithExtent"];
    [perspectiveFilter2 setValue:inputTargetImage forKey:@"inputImage"];
    [perspectiveFilter2 setValue:inputExtent forKey:@"inputExtent"];
    
    if (moveRight) {
        [perspectiveFilter1 setValue:[CIVector vectorWithX:x - x2 Y:y + y2] forKey:@"inputTopLeft"];
        [perspectiveFilter1 setValue:[CIVector vectorWithX:x - x2 Y:y - y2] forKey:@"inputBottomLeft"];
        [perspectiveFilter1 setValue:[CIVector vectorWithX:x - x1 Y:y + y1] forKey:@"inputTopRight"];
        [perspectiveFilter1 setValue:[CIVector vectorWithX:x - x1 Y:y - y1] forKey:@"inputBottomRight"];
        [perspectiveFilter2 setValue:[CIVector vectorWithX:x - x3 Y:y + y3] forKey:@"inputTopLeft"];
        [perspectiveFilter2 setValue:[CIVector vectorWithX:x - x3 Y:y - y3] forKey:@"inputBottomLeft"];
        [perspectiveFilter2 setValue:[CIVector vectorWithX:x - x2 Y:y + y2] forKey:@"inputTopRight"];
        [perspectiveFilter2 setValue:[CIVector vectorWithX:x - x2 Y:y - y2] forKey:@"inputBottomRight"];
    } else {
        [perspectiveFilter1 setValue:[CIVector vectorWithX:x + x1 Y:y + y1] forKey:@"inputTopLeft"];
        [perspectiveFilter1 setValue:[CIVector vectorWithX:x + x1 Y:y - y1] forKey:@"inputBottomLeft"];
        [perspectiveFilter1 setValue:[CIVector vectorWithX:x + x2 Y:y + y2] forKey:@"inputTopRight"];
        [perspectiveFilter1 setValue:[CIVector vectorWithX:x + x2 Y:y - y2] forKey:@"inputBottomRight"];
        [perspectiveFilter2 setValue:[CIVector vectorWithX:x + x2 Y:y + y2] forKey:@"inputTopLeft"];
        [perspectiveFilter2 setValue:[CIVector vectorWithX:x + x2 Y:y - y2] forKey:@"inputBottomLeft"];
        [perspectiveFilter2 setValue:[CIVector vectorWithX:x + x3 Y:y + y3] forKey:@"inputTopRight"];
        [perspectiveFilter2 setValue:[CIVector vectorWithX:x + x3 Y:y - y3] forKey:@"inputBottomRight"];
    }
    
    CIFilter *compositingFilter = [CIFilter filterWithName:@"CISourceOverCompositing"];
    [compositingFilter setValue:[t < 0.5 ? perspectiveFilter1 : perspectiveFilter2 valueForKey:@"outputImage"] forKey:@"inputImage"];
    [compositingFilter setValue:[t < 0.5 ? perspectiveFilter2 : perspectiveFilter1 valueForKey:@"outputImage"] forKey:@"inputBackgroundImage"];
    
    return [compositingFilter valueForKey:@"outputImage"];
}

@end
