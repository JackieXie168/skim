//
//  CIImage_BDSKExtensions.h
//  Bibdesk
//
//  Created by Christiaan Hofman on 5/7/06.
/*
 This software is Copyright (c) 2005,2006,2007
 Christiaan Hofman. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

 - Neither the name of Christiaan Hofman nor the names of any
    contributors may be used to endorse or promote products derived
    from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>


@interface CIImage (BDSKExtensions)

+ (CIImage *)imageWithConstantColor:(CIColor *)color;

// the order of the colors is the opposite of the order of the points for some reason
+ (CIImage *)imageInRect:(CGRect)aRect withLinearGradientFromPoint:(CGPoint)startPoint toPoint:(CGPoint)endPoint fromColor:(CIColor *)startColor toColor:(CIColor *)endColor;

// startColor is the color at the right
+ (CIImage *)imageInRect:(CGRect)aRect withHorizontalGradientFromColor:(CIColor *)startColor toColor:(CIColor *)endColor;

// startColor is the color at the bottom
+ (CIImage *)imageInRect:(CGRect)aRect withVerticalGradientFromColor:(CIColor *)startColor toColor:(CIColor *)endColor;

// startColor is the color at the center
+ (CIImage *)imageWithGaussianGradientWithCenter:(CGPoint)center radius:(float)radius fromColor:(CIColor *)startColor toColor:(CIColor *)endColor;

+ (CIImage *)imageInRect:(CGRect)aRect withHorizontalGradientFromColor:(CIColor *)fgStartColor toColor:(CIColor *)fgEndColor blendedAtTop:(BOOL)top ofVerticalGradientFromColor:(CIColor *)bgStartColor toColor:(CIColor *)bgEndColor;

+ (CIImage *)imageInRect:(CGRect)aRect withVerticalGradientFromColor:(CIColor *)fgStartColor toColor:(CIColor *)fgEndColor blendedAtRight:(BOOL)right ofHorizontalGradientFromColor:(CIColor *)bgStartColor toColor:(CIColor *)bgEndColor;

+ (CIImage *)imageInRect:(CGRect)aRect withColor:(CIColor *)fgColor blendedAtRight:(BOOL)right ofVerticalGradientFromColor:(CIColor *)bgStartColor toColor:(CIColor *)bgEndColor;

+ (CIImage *)imageInRect:(CGRect)aRect withColor:(CIColor *)fgColor blendedAtTop:(BOOL)top ofHorizontalGradientFromColor:(CIColor *)bgStartColor toColor:(CIColor *)bgEndColor;

- (CIImage *)blendedImageWithBackground:(CIImage *)background usingMask:(CIImage *)mask;

- (CIImage *)blurredImageWithBlurRadius:(float)radius;

- (CIImage *)croppedImageWithRect:(CGRect)aRect;

@end


@interface CIColor (BDSKExtensions)

+ (CIColor *)colorWithWhite:(float)white;

+ (CIColor *)colorWithNSColor:(NSColor *)color;

+ (CIColor *)clearColor;

@end 
