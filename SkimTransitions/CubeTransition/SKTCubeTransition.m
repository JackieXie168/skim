//
//  SKTCubeTransition.m
//  SkimTransitions
//
//  Created by Christiaan Hofman on 22/05/2019.
//  Copyright © 2019 Skim. All rights reserved.
//

#import "SKTCubeTransition.h"
#import <Foundation/Foundation.h>
#import <ApplicationServices/ApplicationServices.h>

#define kCIInputTopLeftKey @"inputTopLeft"
#define kCIInputTopRightKey @"inputTopRight"
#define kCIInputBottomLeftKey @"inputBottomLeft"
#define kCIInputBottomRightKey @"inputBottomRight"

@implementation SKTCubeTransition

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

static inline NSInteger directionForAngles(CGFloat angle, CGFloat cornerAngle) {
    while (angle <= M_PI)
        angle += 2.0 * M_PI;
    while (angle > M_PI)
        angle -= 2.0 * M_PI;
    if (angle > cornerAngle) {
        if (angle < M_PI - cornerAngle)
            return 1;
        else
            return 2;
    } else if (angle < -cornerAngle) {
        if (angle > cornerAngle - M_PI)
            return 3;
        else
            return 2;
    }
    return 0;
}

// called when setting up for fragment program and also calls fragment program
- (CIImage *)outputImage
{
    CGFloat t = [inputTime doubleValue];
    CGFloat angle = [inputAngle doubleValue];
    CGFloat width = [inputExtent Z];
    CGFloat height = [inputExtent W];
    CGFloat x = [inputExtent X] + 0.5 * width;
    CGFloat y = [inputExtent Y] + 0.5 * height;
    NSInteger direction = directionForAngles(angle, atan2(height, width));
    CGFloat a = (direction > 1 ? -1.0 : 1.0) * ANGLE * (t - 0.5);
    CGFloat s = sin(a);
    CGFloat c = cos(a);
    
    CIFilter *perspectiveFilter1 = [CIFilter filterWithName:@"CIPerspectiveTransformWithExtent"];
    [perspectiveFilter1 setValue:direction > 1 ? inputTargetImage : inputImage forKey:kCIInputImageKey];
    [perspectiveFilter1 setValue:inputExtent forKey:kCIInputExtentKey];
    
    CIFilter *perspectiveFilter2 = [CIFilter filterWithName:@"CIPerspectiveTransformWithExtent"];
    [perspectiveFilter2 setValue:direction > 1 ? inputImage : inputTargetImage forKey:kCIInputImageKey];
    [perspectiveFilter2 setValue:inputExtent forKey:kCIInputExtentKey];
    
    if (direction % 2 == 0) {
        CGFloat ratio = width / (SIN_1 * height);
        CGFloat factor = 0.5 * height * (1.0 - COS_2) * COS_1;
        CGFloat y1 = factor / (COS_1 - COS_2 * (COS_2 * c - SIN_2 * s));
        CGFloat y2 = factor / (COS_1 - COS_2 * c);
        CGFloat y3 = factor / (COS_1 - COS_2 * (COS_2 * c + SIN_2 * s));
        CGFloat x1 = - ratio * y1 * (COS_2 * s + SIN_2 * c);
        CGFloat x2 = - ratio * y2 * s;
        CGFloat x3 = - ratio * y3 * (COS_2 * s - SIN_2 * c);
        [perspectiveFilter1 setValue:[CIVector vectorWithX:x + x1 Y:y + y1] forKey:kCIInputTopLeftKey];
        [perspectiveFilter1 setValue:[CIVector vectorWithX:x + x1 Y:y - y1] forKey:kCIInputBottomLeftKey];
        [perspectiveFilter1 setValue:[CIVector vectorWithX:x + x2 Y:y + y2] forKey:kCIInputTopRightKey];
        [perspectiveFilter1 setValue:[CIVector vectorWithX:x + x2 Y:y - y2] forKey:kCIInputBottomRightKey];
        [perspectiveFilter2 setValue:[CIVector vectorWithX:x + x2 Y:y + y2] forKey:kCIInputTopLeftKey];
        [perspectiveFilter2 setValue:[CIVector vectorWithX:x + x2 Y:y - y2] forKey:kCIInputBottomLeftKey];
        [perspectiveFilter2 setValue:[CIVector vectorWithX:x + x3 Y:y + y3] forKey:kCIInputTopRightKey];
        [perspectiveFilter2 setValue:[CIVector vectorWithX:x + x3 Y:y - y3] forKey:kCIInputBottomRightKey];
    } else {
        CGFloat ratio = height / (SIN_1 * width);
        CGFloat factor = 0.5 * width * (1.0 - COS_2) * COS_1;
        CGFloat x1 = factor / (COS_1 - COS_2 * (COS_2 * c - SIN_2 * s));
        CGFloat x2 = factor / (COS_1 - COS_2 * c);
        CGFloat x3 = factor / (COS_1 - COS_2 * (COS_2 * c + SIN_2 * s));
        CGFloat y1 = - ratio * x1 * (COS_2 * s + SIN_2 * c);
        CGFloat y2 = - ratio * x2 * s;
        CGFloat y3 = - ratio * x3 * (COS_2 * s - SIN_2 * c);
        [perspectiveFilter1 setValue:[CIVector vectorWithX:x - x1 Y:y + y1] forKey:kCIInputTopLeftKey];
        [perspectiveFilter1 setValue:[CIVector vectorWithX:x + x1 Y:y + y1] forKey:kCIInputTopRightKey];
        [perspectiveFilter1 setValue:[CIVector vectorWithX:x - x2 Y:y + y2] forKey:kCIInputBottomLeftKey];
        [perspectiveFilter1 setValue:[CIVector vectorWithX:x + x2 Y:y + y2] forKey:kCIInputBottomRightKey];
        [perspectiveFilter2 setValue:[CIVector vectorWithX:x - x2 Y:y + y2] forKey:kCIInputTopLeftKey];
        [perspectiveFilter2 setValue:[CIVector vectorWithX:x + x2 Y:y + y2] forKey:kCIInputTopRightKey];
        [perspectiveFilter2 setValue:[CIVector vectorWithX:x - x3 Y:y + y3] forKey:kCIInputBottomLeftKey];
        [perspectiveFilter2 setValue:[CIVector vectorWithX:x + x3 Y:y + y3] forKey:kCIInputBottomRightKey];
    }
    
    BOOL backIs1 = (t < 0.5) == (direction > 1);
    CIFilter *compositingFilter = [CIFilter filterWithName:@"CISourceOverCompositing"];
    [compositingFilter setValue:[perspectiveFilter1 valueForKey:kCIOutputImageKey] forKey:backIs1 ? kCIInputBackgroundImageKey : kCIInputImageKey];
    [compositingFilter setValue:[perspectiveFilter2 valueForKey:kCIOutputImageKey] forKey:backIs1 ? kCIInputImageKey :kCIInputBackgroundImageKey];
    
    return [compositingFilter valueForKey:kCIOutputImageKey];
}

@end
