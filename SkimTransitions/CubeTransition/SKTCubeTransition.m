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

// we actually draw a pentagon, because we want to collapse the side at t=0 and t=1
static CGFloat ANGLE = 0.0;
static CGFloat TAN_1 = 0.0;
static CGFloat TAN_2 = 0.0;

+ (void)initialize {
    ANGLE = 0.4 * M_PI;
    TAN_1 = tan(0.5 * ANGLE);
    TAN_2 = tan(ANGLE);
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
    CIImage *image[2] = {inputImage, inputTargetImage};
    CGFloat s[2], c[2];
    NSRect extent[2];
    CGFloat left[2], right[2], top[2], bottom[2];
    NSPoint tl[2], bl[2], tr[2], br[2];
    NSInteger i;
    
    for (i = 0; i < 2; i++) {
        CGFloat a = (direction > 1 ? -1.0 : 1.0) * ANGLE * (t - i);
        s[i] = sin(a);
        c[i] = cos(a);
        extent[i] = [image[i] extent];
        left[i] = NSMinX(extent[i]) - x;
        right[i] = NSMaxX(extent[i]) - x;
        top[i] = NSMaxY(extent[i]) - y;
        bottom[i] = NSMinY(extent[i]) - y;
    }

    if (direction % 2 == 0) {
        CGFloat r = 0.5 * width / TAN_1;
        CGFloat d = 0.5 * width * TAN_2;
        
        for (i = 0; i < 2; i++) {
            CGFloat fl = d / (d + r - r * c[i] - left[i] * s[i]);
            CGFloat fr = d / (d + r - r * c[i] - right[i] * s[i]);
            tl[i].x = bl[i].x = fl * (-r * s[i] + left[i] * c[i]);
            tr[i].x = br[i].x = fr * (-r * s[i] + right[i] * c[i]);
            tl[i].y = fl * top[i];
            bl[i].y = fl * bottom[i];
            tr[i].y = fr * top[i];
            br[i].y = fr * bottom[i];
        }
    } else {
        CGFloat r = 0.5 * height / TAN_1;
        CGFloat d = 0.5 * height * TAN_2;
        
        for (i = 0; i < 2; i++) {
            CGFloat ft = d / (d + r - r * c[i] - top[i] * s[i]);
            CGFloat fb = d / (d + r - r * c[i] - bottom[i] * s[i]);
            tl[i].x = ft * left[i];
            tr[i].x = ft * right[i];
            bl[i].x = fb * left[i];
            br[i].x = fb * right[i];
            tl[i].y = tr[i].y = ft * (-r * s[i] + top[i] * c[i]);
            bl[i].y = br[i].y = fb * (-r * s[i] + bottom[i] * c[i]);
        }
    }
    
    CIFilter *perspectiveFilter[2];
    
    for (i = 0; i < 2; i++) {
        perspectiveFilter[i] = [CIFilter filterWithName:@"CIPerspectiveTransform"];
        [perspectiveFilter[i] setValue:image[i] forKey:kCIInputImageKey];
        [perspectiveFilter[i] setValue:[CIVector vectorWithX:x + tl[i].x Y:y + tl[i].y] forKey:kCIInputTopLeftKey];
        [perspectiveFilter[i] setValue:[CIVector vectorWithX:x + bl[i].x Y:y + bl[i].y] forKey:kCIInputBottomLeftKey];
        [perspectiveFilter[i] setValue:[CIVector vectorWithX:x + tr[i].x Y:y + tr[i].y] forKey:kCIInputTopRightKey];
        [perspectiveFilter[i] setValue:[CIVector vectorWithX:x + br[i].x Y:y + br[i].y] forKey:kCIInputBottomRightKey];
    }
    
    CIFilter *compositingFilter = [CIFilter filterWithName:@"CISourceOverCompositing"];
    [compositingFilter setValue:[perspectiveFilter[t > 0.5] valueForKey:kCIOutputImageKey] forKey:kCIInputImageKey];
    [compositingFilter setValue:[perspectiveFilter[t <= 0.5] valueForKey:kCIOutputImageKey] forKey:kCIInputBackgroundImageKey];
    
    return [compositingFilter valueForKey:kCIOutputImageKey];
}

@end
