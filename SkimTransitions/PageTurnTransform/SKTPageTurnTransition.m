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

@synthesize inputImage, inputTargetImage, inputExtent, inputAngle, inputTime;

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
    NSRect extent = NSRectFromCGRect([inputTargetImage extent]);
    CGFloat left = NSMinX(extent) - x;
    CGFloat right = NSMaxX(extent) - x;
    CGFloat top = NSMaxY(extent) - y;
    CGFloat bottom = NSMinY(extent) - y;

    CIFilter *perspectiveFilter = [CIFilter filterWithName:@"CIPerspectiveTransform"];
    [perspectiveFilter setValue:inputTargetImage forKey:kCIInputImageKey];
    
    if (direction == 0) {
        CGFloat xr = (width - (width - 2.0 * right) * c) / (2.0 - (0.5 - right / width) * s);
        CGFloat xl = (width - (width - 2.0 * left) * c) / (2.0 - (0.5 - left / width) * s);
        CGFloat yr = 2.0 / (2.0 - (0.5 - right / width) * s);
        CGFloat yl = 2.0 / (2.0 - (0.5 - left / width) * s);
        [perspectiveFilter setValue:[CIVector vectorWithX:x + xl Y:y + yl * top] forKey:kCIInputTopLeftKey];
        [perspectiveFilter setValue:[CIVector vectorWithX:x + xr Y:y + yr * top] forKey:kCIInputTopRightKey];
        [perspectiveFilter setValue:[CIVector vectorWithX:x + xl Y:y + yl * bottom] forKey:kCIInputBottomLeftKey];
        [perspectiveFilter setValue:[CIVector vectorWithX:x + xr Y:y + yr * bottom] forKey:kCIInputBottomRightKey];
    } else if (direction == 2) {
        CGFloat xr = (-width + (width + 2.0 * right) * c) / (2.0 - (0.5 + right / width) * s);
        CGFloat xl = (-width + (width + 2.0 * left) * c) / (2.0 - (0.5 + left / width) * s);
        CGFloat yr = 2.0 / (2.0 - (0.5 + right / width) * s);
        CGFloat yl = 2.0 / (2.0 - (0.5 + left / width) * s);
        [perspectiveFilter setValue:[CIVector vectorWithX:x + xl Y:y + yl * top] forKey:kCIInputTopLeftKey];
        [perspectiveFilter setValue:[CIVector vectorWithX:x + xr Y:y + yr * top] forKey:kCIInputTopRightKey];
        [perspectiveFilter setValue:[CIVector vectorWithX:x + xl Y:y + yl * bottom] forKey:kCIInputBottomLeftKey];
        [perspectiveFilter setValue:[CIVector vectorWithX:x + xr Y:y + yr * bottom] forKey:kCIInputBottomRightKey];
    } else if (direction == 1) {
        CGFloat xt = 2.0 / (2.0 - (0.5 - top / height) * s);
        CGFloat xb = 2.0 / (2.0 - (0.5 - bottom / height) * s);
        CGFloat yt = (height - (height - 2.0 * top) * c) / (2.0 - (0.5 - top / height) * s);
        CGFloat yb = (height - (height - 2.0 * bottom) * c) / (2.0 - (0.5 - bottom / height) * s);
        [perspectiveFilter setValue:[CIVector vectorWithX:x + xt * left Y:y + yt] forKey:kCIInputTopLeftKey];
        [perspectiveFilter setValue:[CIVector vectorWithX:x + xt * right Y:y + yt] forKey:kCIInputTopRightKey];
        [perspectiveFilter setValue:[CIVector vectorWithX:x + xb * left Y:y + yb] forKey:kCIInputBottomLeftKey];
        [perspectiveFilter setValue:[CIVector vectorWithX:x + xb * right Y:y + yb] forKey:kCIInputBottomRightKey];
    } else {
        CGFloat xt = 2.0 / (2.0 - (0.5 + top / height) * s);
        CGFloat xb = 2.0 / (2.0 - (0.5 + bottom / height) * s);
        CGFloat yt = (-height + (height + 2.0 * top) * c) / (2.0 - (0.5 + top / height) * s);
        CGFloat yb = (-height + (height + 2.0 * bottom) * c) / (2.0 - (0.5 + bottom / height) * s);
        [perspectiveFilter setValue:[CIVector vectorWithX:x + xt * left Y:y + yt] forKey:kCIInputTopLeftKey];
        [perspectiveFilter setValue:[CIVector vectorWithX:x + xt * right Y:y + yt] forKey:kCIInputTopRightKey];
        [perspectiveFilter setValue:[CIVector vectorWithX:x + xb * left Y:y + yb] forKey:kCIInputBottomLeftKey];
        [perspectiveFilter setValue:[CIVector vectorWithX:x + xb * right Y:y + yb] forKey:kCIInputBottomRightKey];
    }
    
    CIImage *perspectiveTargetImage = [perspectiveFilter valueForKey:kCIOutputImageKey];
    
    CIFilter *sourceInFilter = [CIFilter filterWithName:@"CISourceInCompositing"];
    [sourceInFilter setValue:perspectiveTargetImage forKey:kCIInputBackgroundImageKey];
    [sourceInFilter setValue:[CIImage imageWithColor:[CIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.66667]] forKey:kCIInputImageKey];
    
    CIFilter *blurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [blurFilter setValue:[sourceInFilter valueForKey:kCIOutputImageKey] forKey:kCIInputImageKey];
    [blurFilter setValue:[NSNumber numberWithDouble:shadowBlurRadius] forKey:kCIInputRadiusKey];
    
    CIFilter *sourceAtopFilter = [CIFilter filterWithName:@"CISourceAtopCompositing"];
    [sourceAtopFilter setValue:inputImage forKey:kCIInputBackgroundImageKey];
    [sourceAtopFilter setValue:[blurFilter valueForKey:kCIOutputImageKey] forKey:kCIInputImageKey];
    
    return [perspectiveTargetImage imageByCompositingOverImage:[sourceAtopFilter valueForKey:kCIOutputImageKey]];
}

@end
