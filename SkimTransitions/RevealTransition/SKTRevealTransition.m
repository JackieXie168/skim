//
//  SKTRevealTransition.m
//  SkimTransitions
//
//  Created by Christiaan Hofman on 22/5/2019.
//  Copyright Christiaan Hofman 2019. All rights reserved.
//

#import "SKTRevealTransition.h"
#import <Foundation/Foundation.h>
#import <ApplicationServices/ApplicationServices.h>

#define kCIInputRectangleKey @"inputRectangle"

@implementation SKTRevealTransition

static CIKernel *_SKTRevealTransitionKernel = nil;

- (id)init
{
    if(_SKTRevealTransitionKernel == nil)
    {
        NSBundle    *bundle = [NSBundle bundleForClass:NSClassFromString(@"SKTRevealTransition")];
        NSStringEncoding encoding = NSUTF8StringEncoding;
        NSError     *error = nil;
        NSString    *code = [NSString stringWithContentsOfFile:[bundle pathForResource:@"SKTRevealTransitionKernel" ofType:@"cikernel"] encoding:encoding error:&error];
        NSArray     *kernels = [CIKernel kernelsWithString:code];
        
        _SKTRevealTransitionKernel = [kernels firstObject];
    }
    return [super init];
}

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

- (CGRect)regionOf:(int)sampler destRect:(CGRect)R userInfo:(CIVector *)offset {
    if (sampler == 0) {
        R = CGRectOffset(R, [offset X], [offset Y]);
    }
    return R;
}

// called when setting up for fragment program and also calls fragment program
- (CIImage *)outputImage
{
    CISampler *src = [CISampler samplerWithImage:inputImage];
    CISampler *trgt = [CISampler samplerWithImage:inputTargetImage];
     CGFloat t = [inputTime doubleValue];
    CGFloat angle = [inputAngle doubleValue];
    CGFloat c = cos(angle);
    CGFloat s = sin(angle);
    CGFloat d = [inputExtent Z] * t / fmax(fabs(c), fabs(s));
    CIVector *offset = [CIVector vectorWithX:d * c Y:d * s];
    NSArray *extent = [NSArray arrayWithObjects:[NSNumber numberWithFloat:[inputExtent X]], [NSNumber numberWithFloat:[inputExtent Y]], [NSNumber numberWithFloat:[inputExtent Z]], [NSNumber numberWithFloat:[inputExtent W]], nil];
    NSArray *arguments = [NSArray arrayWithObjects:src, trgt, inputExtent, offset, nil];
    NSDictionary *options  = [NSDictionary dictionaryWithObjectsAndKeys:extent, kCIApplyOptionDefinition, extent, kCIApplyOptionExtent, offset, kCIApplyOptionUserInfo, nil];
    
    [_SKTRevealTransitionKernel setROISelector:@selector(regionOf:destRect:userInfo:)];
    
    return [self apply:_SKTRevealTransitionKernel arguments:arguments options:options];
}

@end
