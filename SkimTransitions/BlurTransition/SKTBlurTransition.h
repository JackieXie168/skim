//
//  SKTBlurTransition.h
//  SkimTransitions
//
//  Created by Christiaan Hofman on 22/5/2019.
//  Copyright Christiaan Hofman 2019-2020. All rights reserved.

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>


@interface SKTBlurTransition : CIFilter
{
    CIImage     *inputImage;
    CIImage     *inputTargetImage;
    NSNumber    *inputAngle;
    NSNumber    *inputTime;
}

@property (nonatomic, retain) CIImage *inputImage;
@property (nonatomic, retain) CIImage *inputTargetImage;
@property (nonatomic, retain) NSNumber *inputAngle;
@property (nonatomic, retain) NSNumber *inputTime;

@end
