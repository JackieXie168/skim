//
//  SKTCubeTransition.m
//  SkimTransitions
//
//  Created by Christiaan Hofman on 22/05/2019.
//  Copyright © 2019-2020 Skim. All rights reserved.
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

- (CIImage *)rotatedImage:(CIImage *)image angle:(CGFloat)angle size:(NSSize)size center:(NSPoint)center horizontal:(BOOL)horizontal {
    CGFloat s = sin(angle);
    CGFloat c = cos(angle);
    NSRect extent = [image extent];
    CGFloat left = NSMinX(extent) - center.x;
    CGFloat right = NSMaxX(extent) - center.x;
    CGFloat top = NSMaxY(extent) - center.y;
    CGFloat bottom = NSMinY(extent) - center.y;
    NSPoint tl, bl, tr, br;
    
    if (horizontal) {
        CGFloat r = 0.5 * size.width / TAN_1;
        CGFloat d = 0.5 * size.width * TAN_2;
        CGFloat fl = d / (d + r - r * c - left * s);
        CGFloat fr = d / (d + r - r * c - right * s);
        tl.x = bl.x = fl * (-r * s + left * c);
        tr.x = br.x = fr * (-r * s + right * c);
        tl.y = fl * top;
        bl.y = fl * bottom;
        tr.y = fr * top;
        br.y = fr * bottom;
    } else {
        CGFloat r = 0.5 * size.height / TAN_1;
        CGFloat d = 0.5 * size.height * TAN_2;
        CGFloat ft = d / (d + r - r * c - top * s);
        CGFloat fb = d / (d + r - r * c - bottom * s);
        tl.x = ft * left;
        tr.x = ft * right;
        bl.x = fb * left;
        br.x = fb * right;
        tl.y = tr.y = ft * (-r * s + top * c);
        bl.y = br.y = fb * (-r * s + bottom * c);
    }
    
    CIFilter *perspectiveFilter = [CIFilter filterWithName:@"CIPerspectiveTransform"];
    
    [perspectiveFilter setValue:image forKey:kCIInputImageKey];
    [perspectiveFilter setValue:[CIVector vectorWithX:center.x + tl.x Y:center.y + tl.y] forKey:kCIInputTopLeftKey];
    [perspectiveFilter setValue:[CIVector vectorWithX:center.x + bl.x Y:center.y + bl.y] forKey:kCIInputBottomLeftKey];
    [perspectiveFilter setValue:[CIVector vectorWithX:center.x + tr.x Y:center.y + tr.y] forKey:kCIInputTopRightKey];
    [perspectiveFilter setValue:[CIVector vectorWithX:center.x + br.x Y:center.y + br.y] forKey:kCIInputBottomRightKey];
    image = [perspectiveFilter valueForKey:kCIOutputImageKey];
    
    return [perspectiveFilter valueForKey:kCIOutputImageKey];
}

// called when setting up for fragment program and also calls fragment program
- (CIImage *)outputImage
{
    CGFloat t = [inputTime doubleValue];
    CGFloat angle = [inputAngle doubleValue];
    NSSize size = NSMakeSize([inputExtent Z], [inputExtent W]);
    NSPoint center = NSMakePoint([inputExtent X] + 0.5 * size.width, [inputExtent Y] + 0.5 * size.height);
    NSInteger direction = directionForAngles(angle, atan2(size.height, size.width));
    CIImage *image[2] = {inputImage, inputTargetImage};
    NSInteger i;
    
    for (i = 0; i < 2; i++)
        image[i] = [self rotatedImage:image[i] angle:(direction > 1 ? -1.0 : 1.0) * ANGLE * (t - i) size:size center:center horizontal:direction % 2 == 0];
    
    i = t > 0.5 ? 1 : 0;
    
    return [image[i] imageByCompositingOverImage:image[1 - i]];
}

@end
