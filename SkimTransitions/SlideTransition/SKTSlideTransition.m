//
//  SKTSlideTransition.m
//  SkimTransitions
//
//  Created by Christiaan Hofman on 22/05/2019.
//  Copyright © 2019-2020 Skim. All rights reserved.
//

#import "SKTSlideTransition.h"
#import <Foundation/Foundation.h>
#import <ApplicationServices/ApplicationServices.h>

#define kCIInputRectangleKey @"inputRectangle"

@implementation SKTSlideTransition

@synthesize inputImage, inputTargetImage, inputExtent, inputAngle, inputTime;

static CIKernel *_SKTSlideTransitionKernel = nil;

- (id)init
{
    if(_SKTSlideTransitionKernel == nil)
    {
        NSBundle    *bundle = [NSBundle bundleForClass:NSClassFromString(@"SKTSlideTransition")];
        NSStringEncoding encoding = NSUTF8StringEncoding;
        NSError     *error = nil;
        NSString    *code = [NSString stringWithContentsOfFile:[bundle pathForResource:@"SKTSlideTransitionKernel" ofType:@"cikernel"] encoding:encoding error:&error];
        NSArray     *kernels = [CIKernel kernelsWithString:code];
        
        _SKTSlideTransitionKernel = [kernels firstObject];
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

- (CGRect)regionOf:(int)sampler destRect:(CGRect)R userInfo:(NSArray *)userInfo {
    CIVector *offset = [userInfo objectAtIndex:sampler];
    return CGRectOffset(R, [offset X], [offset Y]);
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
    CGFloat d1 = [inputExtent Z] * t / fmax(fabs(c), fabs(s));
    CGFloat d2 = [inputExtent Z] * (t - 1.0) / fmax(fabs(c), fabs(s));
    CIVector *offset1 = [CIVector vectorWithX:d1 * c Y:d1 * s];
    CIVector *offset2 = [CIVector vectorWithX:d2 * c Y:d2 * s];
    NSArray *extent = [NSArray arrayWithObjects:[NSNumber numberWithDouble:[inputExtent X]], [NSNumber numberWithDouble:[inputExtent Y]], [NSNumber numberWithDouble:[inputExtent Z]], [NSNumber numberWithDouble:[inputExtent W]], nil];
    NSArray *arguments = [NSArray arrayWithObjects:src, trgt, inputExtent, offset1, offset2, nil];
    NSArray *userInfo = [NSArray arrayWithObjects:offset1, offset2, nil];
    NSDictionary *options  = [NSDictionary dictionaryWithObjectsAndKeys:extent, kCIApplyOptionDefinition, extent, kCIApplyOptionExtent, userInfo, kCIApplyOptionUserInfo, nil];
    
    [_SKTSlideTransitionKernel setROISelector:@selector(regionOf:destRect:userInfo:)];
    
    return [self apply:_SKTSlideTransitionKernel arguments:arguments options:options];
}

@end
