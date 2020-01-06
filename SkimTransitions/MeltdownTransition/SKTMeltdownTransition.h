//
//  SKTMeltdownTransition.h
//  MeltdownTransition
//
//  Created by Christiaan Hofman on 22/5/2019.
//  Copyright Christiaan Hofman 2019-2020. All rights reserved.

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>


@interface SKTMeltdownTransition : CIFilter
{
    CIImage     *inputImage;
    CIImage     *inputTargetImage;
    CIImage     *inputMaskImage;
    CIVector    *inputExtent;
    NSNumber    *inputAmount;
    NSNumber    *inputTime;
}

@property (nonatomic, retain) CIImage *inputImage;
@property (nonatomic, retain) CIImage *inputTargetImage;
@property (nonatomic, retain) CIImage *inputMaskImage;
@property (nonatomic, retain) CIVector *inputExtent;
@property (nonatomic, retain) NSNumber *inputAmount;
@property (nonatomic, retain) NSNumber *inputTime;

@end
