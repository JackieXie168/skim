//
//  SKTHoleTransition.m
//  SkimTransitions
//
//  Created by Christiaan Hofman on 22/5/2019.
//  Copyright Christiaan Hofman 2019-2020. All rights reserved.
//

#import "SKTHoleTransition.h"
#import <Foundation/Foundation.h>
#import <ApplicationServices/ApplicationServices.h>

@implementation SKTHoleTransition

@synthesize inputImage, inputTargetImage, inputCenter, inputExtent, inputTime;

static CIKernel *_SKTHoleTransitionKernel = nil;

- (id)init
{
    if(_SKTHoleTransitionKernel == nil)
    {
		NSBundle    *bundle = [NSBundle bundleForClass:NSClassFromString(@"SKTHoleTransition")];
		NSStringEncoding encoding = NSUTF8StringEncoding;
		NSError     *error = nil;
		NSString    *code = [NSString stringWithContentsOfFile:[bundle pathForResource:@"SKTHoleTransitionKernel" ofType:@"cikernel"] encoding:encoding error:&error];
		NSArray     *kernels = [CIKernel kernelsWithString:code];

		_SKTHoleTransitionKernel = [kernels firstObject];
    }
    return [super init];
}

- (NSDictionary *)customAttributes
{
    return [NSDictionary dictionaryWithObjectsAndKeys:

        [NSDictionary dictionaryWithObjectsAndKeys:
            [CIVector vectorWithX:150.0 Y:150.0], kCIAttributeDefault,
            kCIAttributeTypePosition,          kCIAttributeType,
            nil],                              kCIInputCenterKey,
 
        [NSDictionary dictionaryWithObjectsAndKeys:
            [CIVector vectorWithX:0.0 Y:0.0 Z:300.0 W:300.0], kCIAttributeDefault,
            kCIAttributeTypeRectangle,          kCIAttributeType,
            nil],                               kCIInputExtentKey,
 
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

- (CGRect)regionOf:(int)sampler destRect:(CGRect)R userInfo:(CIVector *)center {
    CGFloat x = [center X];
    CGFloat y = [center Y];
    
    if (sampler == 0) {
        if (x < R.origin.x) {
            R.size.width += R.origin.x - x;
            R.origin.x = x;
        } else if (x > R.origin.x + R.size.width) {
            R.size.width = x - R.origin.x;
        }
        if (y < R.origin.y) {
            R.size.height += R.origin.y - y;
            R.origin.y = y;
        } else if (y > R.origin.y + R.size.height) {
            R.size.height = y - R.origin.y;
        }
    }
        
    return R;
}

// called when setting up for fragment program and also calls fragment program
- (CIImage *)outputImage
{
    CISampler *src = [CISampler samplerWithImage:inputImage];
    CISampler *trgt = [CISampler samplerWithImage:inputTargetImage];
    CGFloat x = [inputExtent X];
    CGFloat y = [inputExtent Y];
    CGFloat width = [inputExtent Z];
    CGFloat height = [inputExtent W];
    CGFloat dx = x - [inputCenter X];
    CGFloat dy = y - [inputCenter Y];
    CGFloat radius;
    
    dx = fmax(fabs(dx), fabs(dx + width));
    dy = fmax(fabs(dy), fabs(dy + height));
    radius = ceilf(sqrt(dx * dx + dy * dy)) * [inputTime doubleValue];
    
    NSArray *extent = [NSArray arrayWithObjects:[NSNumber numberWithDouble:x], [NSNumber numberWithDouble:y], [NSNumber numberWithDouble:width], [NSNumber numberWithDouble:height], nil];
    NSArray *arguments = [NSArray arrayWithObjects:src, trgt, inputCenter, [NSNumber numberWithDouble:radius], nil];
    NSDictionary *options  = [NSDictionary dictionaryWithObjectsAndKeys:extent, kCIApplyOptionDefinition, extent, kCIApplyOptionExtent, inputCenter, kCIApplyOptionUserInfo, nil];
    
    [_SKTHoleTransitionKernel setROISelector:@selector(regionOf:destRect:userInfo:)];
    
    return [self apply:_SKTHoleTransitionKernel arguments:arguments options:options];
}

@end
