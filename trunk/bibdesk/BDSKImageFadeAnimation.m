//
//  BDSKImageFadeAnimation.m
//  Bibdesk
//
//  Created by Adam Maxwell on 10/29/06.
/*
 This software is Copyright (c) 2006,2007
 Adam Maxwell. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 
 - Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 
 - Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in
 the documentation and/or other materials provided with the
 distribution.
 
 - Neither the name of Adam Maxwell nor the names of any
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

#import "BDSKImageFadeAnimation.h"
#import <QuartzCore/QuartzCore.h>

@implementation BDSKImageFadeAnimation

- (id)initWithDuration:(NSTimeInterval)duration animationCurve:(NSAnimationCurve)animationCurve;
{
    self = [super initWithDuration:duration animationCurve:animationCurve];
    if (self) {
        filter = [[CIFilter filterWithName:@"CIDissolveTransition"] retain];
        [filter setDefaults];
        bitmapData = CFDataCreateMutable(CFAllocatorGetDefault(), 0);
    }
    return self;
}

- (void)dealloc
{
    [filter release];
    CFRelease(bitmapData);
    [super dealloc];
}

- (void)setDelegate:(id)anObject
{
    // not much point in using the class if the delegate doesn't implement this method...
    NSAssert(nil == anObject || [anObject respondsToSelector:@selector(imageAnimationDidUpdate:)], @"Delegate must implement imageAnimationDidUpdate:");
    [super setDelegate:anObject];
}

- (void)setCurrentProgress:(NSAnimationProgress)progress;
{
    [super setCurrentProgress:progress];
    
    // -currentValue ranges 0--1.0 and accounts for the animation curve
    [filter setValue:[NSNumber numberWithFloat:[self currentValue]] forKey:@"inputTime"];
    [[self delegate] imageAnimationDidUpdate:self];
}

- (void)setStartingImage:(NSImage *)anImage;
{
    [filter setValue:[CIImage imageWithData:[anImage TIFFRepresentation]] forKey:@"inputImage"];
}

- (void)setTargetImage:(NSImage *)anImage;
{
    [filter setValue:[CIImage imageWithData:[anImage TIFFRepresentation]] forKey:@"inputTargetImage"];
}

- (NSImage *)finalImage;
{
    NSNumber *inputTime = [filter valueForKey:@"inputTime"];
    
    [filter setValue:[NSNumber numberWithInt:1] forKey:@"inputTime"];
    NSImage *currentImage = [self currentImage];
    
    // restore the input time, since calling -finalImage shouldn't interrupt the animation
    [filter setValue:inputTime forKey:@"inputTime"];
    return currentImage;
}

- (NSImage *)currentImage;
{ 
    CIImage *image = [filter valueForKey:@"outputImage"];
    CGRect rect = [image extent];
    
    // Numerous ways to convert the CIImage to an NSImage, but this method is fast and reasonably simple.  Note that drawing into an offscreen context will cause major leakage (and the animation stutters).
    CGImageRef cgImage = [[[NSGraphicsContext currentContext] CIContext] createCGImage:image fromRect:rect];
    
    // truncate the mutable data
    CFDataSetLength(bitmapData, 0);
    
    CGImageDestinationRef imDest = CGImageDestinationCreateWithData(bitmapData, kUTTypeTIFF, 1, NULL);
    CGImageDestinationAddImage(imDest, cgImage, NULL);
    CGImageDestinationFinalize(imDest);
    CFRelease(imDest);
    CGImageRelease(cgImage);
 
    NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc] initWithData:(NSData *)bitmapData];
    NSImage *nsImage = [[NSImage alloc] initWithSize:((NSRect *)&rect)->size];  
    [nsImage addRepresentation:imageRep];
    [imageRep release];
    
    return [nsImage autorelease];
}

@end

