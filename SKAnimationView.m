//
//  SKAnimationView.m
//  Skim
//
//  Created by Christiaan Hofman on 7/15/07.
/*
 This software is Copyright (c) 2007
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
 
/*
 This code is based partly on Apple's AnimatingTabView example code
 and Ankur Kothari's AnimatingTabsDemo application <http://dev.lipidity.com>
*/

#import "SKAnimationView.h"
#import <Quartz/Quartz.h>
#import "NSBitmapImageRep_SKExtensions.h"
#include <unistd.h>


@implementation SKAnimationView

- (void)dealloc {
    [initialImage release];
    [super dealloc];
}

- (CIImage *)inputShadingImage {
    static CIImage *inputShadingImage = nil;
    if (inputShadingImage == nil) {
        NSData *shadingBitmapData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"TransitionShading" ofType:@"tiff"]];
        NSBitmapImageRep *shadingBitmap = [[[NSBitmapImageRep alloc] initWithData:shadingBitmapData] autorelease];
        inputShadingImage = [[CIImage alloc] initWithBitmapImageRep:shadingBitmap];
    }
    return inputShadingImage;
}

- (CIImage *)inputMaskImage {
    static CIImage *inputMaskImage = nil;
    if (inputMaskImage == nil) {
        NSData *maskBitmapData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"TransitionMask" ofType:@"jpg"]];
        NSBitmapImageRep *maskBitmap = [[[NSBitmapImageRep alloc] initWithData:maskBitmapData] autorelease];
        inputMaskImage = [[CIImage alloc] initWithBitmapImageRep:maskBitmap];
    }
    return inputMaskImage;
}

- (CIFilter *)transitionFilter:(SKAnimationTransitionStyle)transitionStyle forRect:(NSRect)rect initialCIImage:(CIImage *)initialCIImage finalCIImage:(CIImage *)finalCIImage {
    CIFilter *transitionFilter = nil;
    
    CIFilter *maskScalingFilter = nil;
    CGRect maskExtent;
    NSRect bounds = [self bounds];
    
    if (NSEqualRects(rect, bounds) == NO) {
        CIFilter *cropFilter = [CIFilter filterWithName:@"CICrop"];
        [cropFilter setValue:[CIVector vectorWithX:NSMinX(imageRect) Y:NSMinY(imageRect) Z:NSWidth(imageRect) W:NSHeight(imageRect)] forKey:@"inputRectangle"];
        [cropFilter setValue:initialCIImage forKey:@"inputImage"];
        initialCIImage = [cropFilter valueForKey:@"outputImage"];
        [cropFilter setValue:finalCIImage forKey:@"inputImage"];
        finalCIImage = [cropFilter valueForKey:@"outputImage"];
    }
    
    switch (transitionStyle) {
        case SKCopyMachineTransition:
            transitionFilter = [CIFilter filterWithName:@"CICopyMachineTransition"];
            [transitionFilter setDefaults];
            [transitionFilter setValue:[CIVector vectorWithX:NSMinX(rect) Y:NSMinY(rect) Z:NSWidth(rect) W:NSHeight(rect)] forKey:@"inputExtent"];
            break;

        case SKDisintegrateTransition:
            transitionFilter = [CIFilter filterWithName:@"CIDisintegrateWithMaskTransition"];
            [transitionFilter setDefaults];

            // Scale our mask image to match the transition area size, and set the scaled result as the "inputMaskImage" to the transitionFilter.
            maskScalingFilter = [CIFilter filterWithName:@"CILanczosScaleTransform"];
            [maskScalingFilter setDefaults];
            maskExtent = [[self inputMaskImage] extent];
            float xScale = NSWidth(rect) / CGRectGetWidth(maskExtent);
            float yScale = NSHeight(rect) / CGRectGetHeight(maskExtent);
            [maskScalingFilter setValue:[NSNumber numberWithFloat:yScale] forKey:@"inputScale"];
            [maskScalingFilter setValue:[NSNumber numberWithFloat:xScale / yScale] forKey:@"inputAspectRatio"];
            [maskScalingFilter setValue:[self inputMaskImage] forKey:@"inputImage"];

            [transitionFilter setValue:[maskScalingFilter valueForKey:@"outputImage"] forKey:@"inputMaskImage"];
            break;

        case SKDissolveTransition:
            transitionFilter = [CIFilter filterWithName:@"CIDissolveTransition"];
            [transitionFilter setDefaults];
            break;

        case SKFlashTransition:
            transitionFilter = [CIFilter filterWithName:@"CIFlashTransition"];
            [transitionFilter setDefaults];
            [transitionFilter setValue:[CIVector vectorWithX:NSMidX(rect) Y:NSMidY(rect)] forKey:@"inputCenter"];
            [transitionFilter setValue:[CIVector vectorWithX:NSMinX(bounds) Y:NSMinY(bounds) Z:NSWidth(bounds) W:NSHeight(bounds)] forKey:@"inputExtent"];
            break;

        case SKModTransition:
            transitionFilter = [CIFilter filterWithName:@"CIModTransition"];
            [transitionFilter setDefaults];
            [transitionFilter setValue:[CIVector vectorWithX:NSMidX(rect) Y:NSMidY(rect)] forKey:@"inputCenter"];
            break;

        case SKPageCurlTransition:
            transitionFilter = [CIFilter filterWithName:@"CIPageCurlTransition"];
            [transitionFilter setDefaults];
            [transitionFilter setValue:[NSNumber numberWithFloat:-M_PI_4] forKey:@"inputAngle"];
            [transitionFilter setValue:initialCIImage forKey:@"inputBacksideImage"];
            [transitionFilter setValue:[self inputShadingImage] forKey:@"inputShadingImage"];
            [transitionFilter setValue:[CIVector vectorWithX:NSMinX(rect) Y:NSMinY(rect) Z:NSWidth(rect) W:NSHeight(rect)] forKey:@"inputExtent"];
            break;

        case SKSwipeTransition:
            transitionFilter = [CIFilter filterWithName:@"CISwipeTransition"];
            [transitionFilter setDefaults];
            break;

        case SKRippleTransition:
        default:
            transitionFilter = [CIFilter filterWithName:@"CIRippleTransition"];
            [transitionFilter setDefaults];
            [transitionFilter setValue:[CIVector vectorWithX:NSMidX(rect) Y:NSMidY(rect)] forKey:@"inputCenter"];
            [transitionFilter setValue:[CIVector vectorWithX:NSMinX(bounds) Y:NSMinY(bounds) Z:NSWidth(bounds) W:NSHeight(bounds)] forKey:@"inputExtent"];
            [transitionFilter setValue:[self inputShadingImage] forKey:@"inputShadingImage"];
            break;
    }
    [transitionFilter setValue:initialCIImage forKey:@"inputImage"];
    [transitionFilter setValue:finalCIImage forKey:@"inputTargetImage"];
    
    return transitionFilter;
}

- (void)prepareForAnimationWithTransitionStyle:(SKAnimationTransitionStyle)transitionStyle fromRect:(NSRect)rect{
	if (transitionStyle >= SKCopyMachineTransition) {
        NSRect bounds = [self bounds];
        [initialImage release];
        NSBitmapImageRep *initialContentBitmap = [self bitmapImageRepForCachingDisplayInRect:bounds];
        [initialContentBitmap clear];
        [self cacheDisplayInRect:bounds toBitmapImageRep:initialContentBitmap];
        initialImage = [[CIImage alloc] initWithBitmapImageRep:initialContentBitmap];
        imageRect = rect;
    }
}

- (void)animateWithTransitionStyle:(SKAnimationTransitionStyle)transitionStyle direction:(CGSTransitionOption)direction duration:(float)duration fromRect:(NSRect)rect {
	if (transitionStyle == SKNoTransition) {

	} else if (transitionStyle < SKCopyMachineTransition) {
        
        // declare our variables  
        int handle = -1;
        CGSTransitionSpec spec;
        
        // specify our specifications
        spec.unknown1 = 0;
        spec.type =  transitionStyle;
        spec.option = direction;
        spec.backColour = NULL;
        spec.wid = [[self window] windowNumber];
        
        // Let’s get a connection
        CGSConnection cgs = _CGSDefaultConnection();
        
        // Create a transition
        CGSNewTransition(cgs, &spec, &handle);
        
        // Redraw the window
        [[self window] display];
        
        CGSInvokeTransition(cgs, handle, duration);
        // We need to wait for the transition to finish before we get rid of it, otherwise we’ll get all sorts of nasty errors... or maybe not.
        usleep((useconds_t)(duration * 1000000));
        
        CGSReleaseTransition(cgs, handle);
        handle = 0;
		
	} else {
        
        if (initialImage == nil)
            [self prepareForAnimationWithTransitionStyle:transitionStyle fromRect:rect];
        NSRect bounds = [self bounds];
        imageRect = NSIntersectionRect(NSUnionRect(imageRect, rect), bounds);
        
        NSBitmapImageRep *finalContentBitmap = [self bitmapImageRepForCachingDisplayInRect:bounds];
        [finalContentBitmap clear];
        [self cacheDisplayInRect:bounds toBitmapImageRep:finalContentBitmap];
        CIImage *finalImage = [[CIImage alloc] initWithBitmapImageRep:finalContentBitmap];
        
        CIFilter *transitionFilter = [self transitionFilter:transitionStyle forRect:imageRect initialCIImage:initialImage finalCIImage:finalImage];
        
        [finalImage release];
        [initialImage release];
        initialImage = nil;
        
        SKTransitionAnimation *animation = [[SKTransitionAnimation alloc] initWithFilter:transitionFilter duration:duration animationCurve:NSAnimationLinear];
        [animation setDelegate:self];
        
        [animation startAnimation];
        
        [animation release];
        
        [self setNeedsDisplay:YES];
        
    }
}

- (void)transitionAnimationDidUpdate:(SKTransitionAnimation *)anAnimation {
    NSRect nsBounds = [self bounds];
    CGRect cgBounds = *(CGRect *)&nsBounds;
    
    [self lockFocus];
    
    NSGraphicsContext *context = [NSGraphicsContext currentContext];
    [context saveGraphicsState];
    
    [[[self window] backgroundColor] setFill];
    NSRectFill(nsBounds);
    
    [[context CIContext] drawImage:[anAnimation currentImage] inRect:cgBounds fromRect:cgBounds];
    [context flushGraphics];
    
    [context restoreGraphicsState];
    
    [self unlockFocus];
}

@end


@implementation SKTransitionAnimation

- (id)initWithFilter:(CIFilter *)aFilter duration:(NSTimeInterval)duration animationCurve:(NSAnimationCurve)animationCurve {
    if (self = [super initWithDuration:duration animationCurve:animationCurve]) {
        filter = [aFilter retain];
    }
    return self;
}

- (void)dealloc {
    [filter release];
    [super dealloc];
}

- (void)setCurrentProgress:(NSAnimationProgress)progress {
    [filter setValue:[NSNumber numberWithFloat:[self currentValue]] forKey:@"inputTime"];
    [super setCurrentProgress:progress];
    if ([[self delegate] respondsToSelector:@selector(transitionAnimationDidUpdate:)])
        [[self delegate] transitionAnimationDidUpdate:self];
}

- (CIImage *)currentImage {
    return [filter valueForKey:@"outputImage"];
}

@end
