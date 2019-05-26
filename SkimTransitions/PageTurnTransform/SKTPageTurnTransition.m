//
//  SKTPageTurnTransition.m
//  SkimTransitions
//
//  Created by Christiaan Hofman on 22/05/2019.
//  Copyright © 2019 Skim. All rights reserved.
//

#import "SKTPageTurnTransition.h"
#import <Foundation/Foundation.h>
#import <ApplicationServices/ApplicationServices.h>

#define kCIInputTopLeftKey @"inputTopLeft"
#define kCIInputTopRightKey @"inputTopRight"
#define kCIInputBottomLeftKey @"inputBottomLeft"
#define kCIInputBottomRightKey @"inputBottomRight"

@implementation SKTPageTurnTransition

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
    CGFloat a = (1.0 - t) * atan(4.0);
    CGFloat s = sin(a);
    CGFloat c = cos(a);
    CGFloat shadowBlurRadius = (direction % 2 == 0 ? width : height) * 0.1 * s;
    
    CIFilter *perspectiveFilter = [CIFilter filterWithName:@"CIPerspectiveTransformWithExtent"];
    [perspectiveFilter setValue:inputTargetImage forKey:kCIInputImageKey];
    [perspectiveFilter setValue:inputExtent forKey:kCIInputExtentKey];
    
    if (direction == 0) {
        CGFloat xr = 0.5 * width;
        CGFloat xl = width * (1.0 - 2.0 * c) / (2.0 - s);
        CGFloat yr = 0.5 * height;
        CGFloat yl = height / (2.0 - s);
        [perspectiveFilter setValue:[CIVector vectorWithX:x + xl Y:y + yl] forKey:kCIInputTopLeftKey];
        [perspectiveFilter setValue:[CIVector vectorWithX:x + xr Y:y + yr] forKey:kCIInputTopRightKey];
        [perspectiveFilter setValue:[CIVector vectorWithX:x + xl Y:y - yl] forKey:kCIInputBottomLeftKey];
        [perspectiveFilter setValue:[CIVector vectorWithX:x + xr Y:y - yr] forKey:kCIInputBottomRightKey];
    } else if (direction == 2) {
        CGFloat xr = width * (-1.0 + 2.0 * c) / (2.0 - s);
        CGFloat xl = -0.5 * width;
        CGFloat yr = height / (2.0 - s);
        CGFloat yl = 0.5 * height;
        [perspectiveFilter setValue:[CIVector vectorWithX:x + xl Y:y + yl] forKey:kCIInputTopLeftKey];
        [perspectiveFilter setValue:[CIVector vectorWithX:x + xr Y:y + yr] forKey:kCIInputTopRightKey];
        [perspectiveFilter setValue:[CIVector vectorWithX:x + xl Y:y - yl] forKey:kCIInputBottomLeftKey];
        [perspectiveFilter setValue:[CIVector vectorWithX:x + xr Y:y - yr] forKey:kCIInputBottomRightKey];
    } else if (direction == 1) {
        CGFloat xt = 0.5 * width;
        CGFloat xb = width / (2.0 - s);
        CGFloat yt = height * (1.0 - 2.0 * c) / (2.0 - s);
        CGFloat yb = 0.5 * height;
        [perspectiveFilter setValue:[CIVector vectorWithX:x - xt Y:y + yt] forKey:kCIInputTopLeftKey];
        [perspectiveFilter setValue:[CIVector vectorWithX:x + xt Y:y + yt] forKey:kCIInputTopRightKey];
        [perspectiveFilter setValue:[CIVector vectorWithX:x - xb Y:y + yb] forKey:kCIInputBottomLeftKey];
        [perspectiveFilter setValue:[CIVector vectorWithX:x + xb Y:y + yb] forKey:kCIInputBottomRightKey];
    } else {
        CGFloat xt = width / (2.0 - s);
        CGFloat xb = 0.5 * width;
        CGFloat yt = 0.5 * height;
        CGFloat yb = height * (-1.0 + 2.0 * c) / (2.0 - s);
        [perspectiveFilter setValue:[CIVector vectorWithX:x - xt Y:y + yt] forKey:kCIInputTopLeftKey];
        [perspectiveFilter setValue:[CIVector vectorWithX:x + xt Y:y + yt] forKey:kCIInputTopRightKey];
        [perspectiveFilter setValue:[CIVector vectorWithX:x - xb Y:y + yb] forKey:kCIInputBottomLeftKey];
        [perspectiveFilter setValue:[CIVector vectorWithX:x + xb Y:y + yb] forKey:kCIInputBottomRightKey];
    }
    
    CIImage *perspectiveTargetImage = [perspectiveFilter valueForKey:kCIOutputImageKey];
    
    CIFilter *generatorFilter = [CIFilter filterWithName:@"CIConstantColorGenerator"];
    [generatorFilter setValue:[CIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.66667] forKey:kCIInputColorKey];
    
    CIFilter *sourceInFilter = [CIFilter filterWithName:@"CISourceInCompositing"];
    [sourceInFilter setValue:perspectiveTargetImage forKey:kCIInputBackgroundImageKey];
    [sourceInFilter setValue:[generatorFilter valueForKey:kCIOutputImageKey] forKey:kCIInputImageKey];
    
    CIFilter *blurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [blurFilter setValue:[sourceInFilter valueForKey:kCIOutputImageKey] forKey:kCIInputImageKey];
    [blurFilter setValue:[NSNumber numberWithDouble:shadowBlurRadius] forKey:kCIInputRadiusKey];
    
    CIFilter *sourceAtopFilter = [CIFilter filterWithName:@"CISourceAtopCompositing"];
    [sourceAtopFilter setValue:inputImage forKey:kCIInputBackgroundImageKey];
    [sourceAtopFilter setValue:[blurFilter valueForKey:kCIOutputImageKey] forKey:kCIInputImageKey];
    
    CIFilter *sourceOverFilter = [CIFilter filterWithName:@"CISourceOverCompositing"];
    [sourceOverFilter setValue:[sourceAtopFilter valueForKey:kCIOutputImageKey] forKey:kCIInputBackgroundImageKey];
    [sourceOverFilter setValue:perspectiveTargetImage forKey:kCIInputImageKey];
    
    return [sourceOverFilter valueForKey:kCIOutputImageKey];
}

@end
