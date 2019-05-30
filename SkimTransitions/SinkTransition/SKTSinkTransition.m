//
//  SKTSinkTransition.m
//  SkimTransitions
//
//  Created by Christiaan Hofman on 22/5/2019.
//  Copyright Christiaan Hofman 2019. All rights reserved.
//

#import "SKTSinkTransition.h"
#import <Foundation/Foundation.h>
#import <ApplicationServices/ApplicationServices.h>

@implementation SKTSinkTransition

static CIKernel *_SKTSinkTransitionKernel = nil;

- (id)init
{
    if(_SKTSinkTransitionKernel == nil)
    {
		NSBundle    *bundle = [NSBundle bundleForClass:NSClassFromString(@"SKTSinkTransition")];
		NSStringEncoding encoding = NSUTF8StringEncoding;
		NSError     *error = nil;
		NSString    *code = [NSString stringWithContentsOfFile:[bundle pathForResource:@"SKTSinkTransitionKernel" ofType:@"cikernel"] encoding:encoding error:&error];
		NSArray     *kernels = [CIKernel kernelsWithString:code];

		_SKTSinkTransitionKernel = [kernels firstObject];
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
            [CIVector vectorWithX:150.0 Y:150.0], kCIAttributeDefault,
            kCIAttributeTypePosition,          kCIAttributeType,
            nil],                              kCIInputCenterKey,
 
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

- (CGRect)regionOf:(int)sampler destRect:(CGRect)R userInfo:(CISampler *)img {
    if (sampler == 0) {
        return [img extent];
    }
    return R;
}

// called when setting up for fragment program and also calls fragment program
- (CIImage *)outputImage
{
    CISampler *src = [CISampler samplerWithImage:inputImage];
    CISampler *trgt = [CISampler samplerWithImage:inputTargetImage];

    NSArray *arguments = [NSArray arrayWithObjects:src, trgt, inputCenter, inputTime, nil];
    NSDictionary *options  = [NSDictionary dictionaryWithObjectsAndKeys:[src definition], kCIApplyOptionDefinition, src, kCIApplyOptionUserInfo, nil];
    
    [_SKTSinkTransitionKernel setROISelector:@selector(regionOf:destRect:userInfo:)];
    
    return [self apply:_SKTSinkTransitionKernel arguments:arguments options:options];
}

@end
