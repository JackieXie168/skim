//
//  SKTMeltdownTransitionFilter.m
//  MeltdownTransition
//
//  Created by Christiaan Hofman on 22/5/2019.
//  Copyright Christiaan Hofman 2019. All rights reserved.
//

#import "SKTMeltdownTransitionFilter.h"
#import <Foundation/Foundation.h>
#import <ApplicationServices/ApplicationServices.h>

#define kCIInputAmountKey @"inputAmount"

@implementation SKTMeltdownTransitionFilter

static CIKernel *_SKTMeltdownTransitionFilterKernel = nil;

- (id)init
{
    if(_SKTMeltdownTransitionFilterKernel == nil)
    {
		NSBundle    *bundle = [NSBundle bundleForClass:NSClassFromString(@"SKTMeltdownTransitionFilter")];
		NSStringEncoding encoding = NSUTF8StringEncoding;
		NSError     *error = nil;
		NSString    *code = [NSString stringWithContentsOfFile:[bundle pathForResource:@"SKTMeltdownTransitionFilterKernel" ofType:@"cikernel"] encoding:encoding error:&error];
		NSArray     *kernels = [CIKernel kernelsWithString:code];

		_SKTMeltdownTransitionFilterKernel = [kernels firstObject];
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
            [NSNumber numberWithDouble:  1.0], kCIAttributeMax,
            [NSNumber numberWithDouble:  0.0], kCIAttributeSliderMin,
            [NSNumber numberWithDouble:  500.0], kCIAttributeSliderMax,
            [NSNumber numberWithDouble:  200.0], kCIAttributeDefault,
            [NSNumber numberWithDouble:  0.0], kCIAttributeIdentity,
            kCIAttributeTypeDistance,          kCIAttributeType,
            nil],                              kCIInputAmountKey,
 
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

- (CGRect)regionOf:(int)sampler destRect:(CGRect)R userInfo:(NSArray *)array {
    CGFloat amount = [[array objectAtIndex:2] doubleValue];
    CGFloat radius = [[array objectAtIndex:3] doubleValue];
    if (sampler == 0) {
        CGRect extent = [[array objectAtIndex:0] extent];
        R.origin.y += radius;
        R.size.height += amount;
        R = CGRectIntersection(R, extent);
    } else if (sampler == 2) {
        CGRect extent = [[array objectAtIndex:1] extent];
        R.origin.y += radius;
        R = CGRectIntersection(R, extent);
    }
    
    return R;
}

// called when setting up for fragment program and also calls fragment program
- (CIImage *)outputImage
{
    CISampler *src = [CISampler samplerWithImage:inputImage];
    CISampler *trgt = [CISampler samplerWithImage:inputTargetImage];
    CISampler *mask = [CISampler samplerWithImage:inputMaskImage];
    CGFloat x = [inputExtent X];
    CGFloat y = [inputExtent Y];
    CGFloat width = [inputExtent Z];
    CGFloat height = [inputExtent W];
    CGFloat t = [inputTime doubleValue];
    NSNumber *radius = [NSNumber numberWithDouble:height * t];
    NSNumber *amount = [NSNumber numberWithDouble:[inputAmount doubleValue] * t];
    
    NSArray *extent = [NSArray arrayWithObjects:[NSNumber numberWithDouble:x], [NSNumber numberWithDouble:y], [NSNumber numberWithDouble:width], [NSNumber numberWithDouble:height], nil];
    NSArray *arguments = [NSArray arrayWithObjects:src, trgt, mask, amount, radius, nil];
    NSArray *userInfo = [NSArray arrayWithObjects:src, mask, amount, radius, nil];
    NSDictionary *options  = [NSDictionary dictionaryWithObjectsAndKeys:extent, kCIApplyOptionDefinition, extent, kCIApplyOptionExtent, userInfo, kCIApplyOptionUserInfo, nil];
    
    [_SKTMeltdownTransitionFilterKernel setROISelector:@selector(regionOf:destRect:userInfo:)];
    
    return [self apply:_SKTMeltdownTransitionFilterKernel arguments:arguments options:options];
}

@end
