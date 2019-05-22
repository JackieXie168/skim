//
//  SKTSinkTransitionFilter.m
//  SkimTransitions
//
//  Created by Christiaan Hofman on 22/5/2019.
//  Copyright Christiaan Hofman 2019. All rights reserved.
//

#import "SKTSinkTransitionFilter.h"
#import <Foundation/Foundation.h>
#import <ApplicationServices/ApplicationServices.h>

@implementation SKTSinkTransitionFilter

static CIKernel *_SKTSinkTransitionFilterKernel = nil;

- (id)init
{
    if(_SKTSinkTransitionFilterKernel == nil)
    {
		NSBundle    *bundle = [NSBundle bundleForClass:NSClassFromString(@"SKTSinkTransitionFilter")];
		NSStringEncoding encoding = NSUTF8StringEncoding;
		NSError     *error = nil;
		NSString    *code = [NSString stringWithContentsOfFile:[bundle pathForResource:@"SKTSinkTransitionFilterKernel" ofType:@"cikernel"] encoding:encoding error:&error];
		NSArray     *kernels = [CIKernel kernelsWithString:code];

		_SKTSinkTransitionFilterKernel = [kernels firstObject];
    }
    return [super init];
}

- (NSDictionary *)customAttributes
{
    return [NSDictionary dictionaryWithObjectsAndKeys:

        [NSDictionary dictionaryWithObjectsAndKeys:
            [CIVector vectorWithX:150.0 Y:150.0], kCIAttributeDefault,
            kCIAttributeTypePosition,          kCIAttributeType,
            nil],                              @"inputCenter",
 
        [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithDouble:  0.0], kCIAttributeMin,
            [NSNumber numberWithDouble:  1.0], kCIAttributeMax,
            [NSNumber numberWithDouble:  0.0], kCIAttributeSliderMin,
            [NSNumber numberWithDouble:  1.0], kCIAttributeSliderMax,
            [NSNumber numberWithDouble:  0.0], kCIAttributeDefault,
            [NSNumber numberWithDouble:  0.0], kCIAttributeIdentity,
            kCIAttributeTypeTime,              kCIAttributeType,
            nil],                              @"inputTime",

        nil];
}

- (CGRect)regionOf:(int)sampler destRect:(CGRect)R userInfo:(CISampler *)img {
    return [img extent];
}

// called when setting up for fragment program and also calls fragment program
- (CIImage *)outputImage
{
    CGFloat t = [inputTime doubleValue];
    CISampler *src = [CISampler samplerWithImage:t < 0.5 ? inputImage : inputTargetImage];
    
    NSArray *arguments = [NSArray arrayWithObjects:src, inputCenter, [NSNumber numberWithDouble:1.0 - fabs(2.0 * t - 1.0)], nil];
    NSDictionary *options  = [NSDictionary dictionaryWithObjectsAndKeys:[src definition], kCIApplyOptionDefinition, src, kCIApplyOptionUserInfo, nil];
    
    [_SKTSinkTransitionFilterKernel setROISelector:@selector(regionOf:destRect:userInfo:)];
    
    return [self apply:_SKTSinkTransitionFilterKernel arguments:arguments options:options];
}

@end
