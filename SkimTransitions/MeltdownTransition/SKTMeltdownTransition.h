//
//  SKTMeltdownTransitionFilter.h
//  MeltdownTransition
//
//  Created by Christiaan Hofman on 22/5/2019.
//  Copyright Christiaan Hofman 2019. All rights reserved.

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>


@interface SKTMeltdownTransitionFilter : CIFilter
{
    CIImage     *inputImage;
    CIImage     *inputTargetImage;
    CIImage     *inputMaskImage;
    CIVector    *inputExtent;
    NSNumber    *inputAmount;
    NSNumber    *inputTime;
}

@end
