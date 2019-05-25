//
//  SKTRadarTransition.h
//  RadarTransition
//
//  Created by Christiaan Hofman on 22/5/2019.
//  Copyright Christiaan Hofman 2019. All rights reserved.

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>


@interface SKTRadarTransition : CIFilter
{
    CIImage     *inputImage;
    CIImage     *inputTargetImage;
    CIVector    *inputCenter;
    NSNumber    *inputAngle;
    NSNumber    *inputWidth;
    NSNumber    *inputTime;
}

@end
