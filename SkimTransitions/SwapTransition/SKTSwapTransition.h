//
//  SKTSwapTransition.h
//  SkimTransitions
//
//  Created by Christiaan Hofman on 22/05/2019.
//  Copyright © 2019-2020 Skim. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@interface SKTSwapTransition : CIFilter {
    CIImage      *inputImage;
    CIImage      *inputTargetImage;
    CIVector     *inputExtent;
    NSNumber     *inputAngle;
    NSNumber     *inputTime;
}

@property (nonatomic, retain) CIImage *inputImage;
@property (nonatomic, retain) CIImage *inputTargetImage;
@property (nonatomic, retain) CIVector *inputExtent;
@property (nonatomic, retain) NSNumber *inputAngle;
@property (nonatomic, retain) NSNumber *inputTime;

@end
