//
//  BDSKSpotlightView.m
//  Bibdesk
//
//  Created by Adam Maxwell on 05/04/06.
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

#import "BDSKSpotlightView.h"
#import <QuartzCore/QuartzCore.h>
#import "CIImage_BDSKExtensions.h"

@implementation BDSKSpotlightView;

static NSColor *maskColor = nil;
static CIFilter *shiftFilter = nil;
static CIFilter *cropFilter = nil;

+ (void)initialize
{
    static BOOL alreadyInit = NO;
    if(NO == alreadyInit){
        maskColor = [[[NSColor blackColor] colorWithAlphaComponent:0.3] retain];
        shiftFilter = [[CIFilter filterWithName:@"CIAffineTransform"] retain];
        cropFilter = [[CIFilter filterWithName:@"CICrop"] retain];
        alreadyInit = YES;
    }
}

- (id)initWithFrame:(NSRect)frameRect delegate:(id)anObject;
{
    if(self = [super initWithFrame:frameRect]){
        [self setDelegate:anObject];
    }
    return self;
}

- (void)setDelegate:(id)anObject;
{
    NSParameterAssert([anObject conformsToProtocol:@protocol(BDSKSpotlightViewDelegate)]);
    delegate = anObject;
}

- (CIImage *)spotlightMaskImageWithFrame:(NSRect)aRect
{
    NSArray *highlightRects = [delegate highlightRectsInScreenCoordinates];
    
    // array of NSValue objects; aRect and highlightRects should have same coordinate system
    NSEnumerator *rectEnum = [highlightRects objectEnumerator];
    NSValue *value;
        
    unsigned int maximumBlur = 10;
    float blurPadding = maximumBlur * 2;

    // we make the bounds larger so the blurred edges will fall outside the view
    NSRect maskRect = NSInsetRect(aRect, -blurPadding, -blurPadding);
    NSBezierPath *path = [NSBezierPath bezierPathWithRect:maskRect];
    
    // this causes the paths we append to act as holes in the overall path
    [path setWindingRule:NSEvenOddWindingRule];
    
    NSRect holeRect;
    NSPoint baseOrigin;
    NSWindow *window = [self window];
    
    while(value = [rectEnum nextObject]){
        holeRect = [value rectValue];
        baseOrigin = [window convertScreenToBase:holeRect.origin];
        holeRect.origin = baseOrigin;
        [path appendBezierPathWithOvalInRect:holeRect];
    }
    
    // we need to shift because canvas of the image is at positive values
    NSAffineTransform *transform = [NSAffineTransform transform];
    [transform translateXBy:blurPadding yBy:blurPadding];
    [path transformUsingAffineTransform:transform];
        
    // @@ resolution independence:  drawing to an NSImage and then creating the CIImage with -[NSImage TIFFRepresentation] gives an incorrect CIImage extent when display scaling is turned on, probably due to NSCachedImageRep.  Drawing directly to an NSBitmapImageRep gives the correct overall size, but the hole locations are off, and there appears to be a blurred section on the top and right side.
    NSImage *image = [[NSImage alloc] initWithSize:maskRect.size];
    [image lockFocus];
    [NSGraphicsContext saveGraphicsState];
    
    // fill the entire space with clear
    [[NSColor clearColor] setFill];
    NSRectFill(maskRect);
    
    // draw the mask
    [maskColor setFill];
    [path fill];
    
    [NSGraphicsContext restoreGraphicsState];
    [image unlockFocus];
    
    CIImage *ciImage = [[CIImage alloc] initWithData:[image TIFFRepresentation]];
    [image release];
    
    // sys prefs uses fuzzier circles for more matches; filter range 0 -- 100, values 0 -- 10 are reasonable?
    float radius = MIN([highlightRects count], maximumBlur);
    
    // apply the blur filter to soften the edges of the circles
    CIImage *blurredImage = [ciImage blurredImageWithBlurRadius:radius];
    [ciImage release];
    
    // shift the image back by inverting the transform
    [transform invert];
    [shiftFilter setValue:transform forKey:@"inputTransform"];
    [shiftFilter setValue:blurredImage forKey:@"inputImage"];
    
    // crop to the original bounds size; this crops all sides of the image
    CIVector *cropVector = [CIVector vectorWithX:0 Y:0 Z:NSWidth(aRect) W:NSHeight(aRect)];
    [cropFilter setValue:cropVector forKey:@"inputRectangle"];
    [cropFilter setValue:[shiftFilter valueForKey:@"outputImage"] forKey:@"inputImage"];
    
    return [cropFilter valueForKey:@"outputImage"];
}

// sys prefs draws solid black for no matches, so we'll do the same
- (void)drawRect:(NSRect)aRect;
{
    if([delegate isSearchActive]){
        CIContext *ciContext = [[NSGraphicsContext currentContext] CIContext];
        NSRect boundsRect = [self bounds];
        [ciContext drawImage:[self spotlightMaskImageWithFrame:boundsRect] atPoint:CGPointZero fromRect:CGRectMake(0, 0, NSWidth(boundsRect), NSHeight(boundsRect))];
    } else {
        [[NSColor clearColor] setFill];
        NSRectFill(aRect);
    }
}

@end