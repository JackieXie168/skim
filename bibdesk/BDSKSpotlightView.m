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

@implementation BDSKSpotlightCircle

- (id)initWithCenterPoint:(NSPoint)p radius:(float)r;
{
    self = [super init];
    center = p;
    radius = r;
    return self;
}
- (float)radius {
    return radius;
}
- (NSPoint)center {
    return center;
}

@end

@implementation BDSKSpotlightView;

static NSColor *maskColor = nil;
static CIFilter *cropFilter = nil;

+ (void)initialize
{
    static BOOL alreadyInit = NO;
    if(NO == alreadyInit){
        maskColor = [[[NSColor blackColor] colorWithAlphaComponent:0.3] retain];
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
    NSArray *highlightCircles = [delegate highlightCirclesInScreenCoordinates];
    
    // array of BDSKSpotlightCircle objects; centers in screen coordinates
    NSEnumerator *circleEnum = [highlightCircles objectEnumerator];
        
    unsigned int maximumBlur = 10;
    float blurPadding = maximumBlur * 2;

    // we make the bounds larger so the blurred edges will fall outside the view
    NSRect maskRect = NSInsetRect(aRect, -blurPadding, -blurPadding);
    NSBezierPath *path = [NSBezierPath bezierPathWithRect:maskRect];
    
    // this causes the paths we append to act as holes in the overall path
    [path setWindingRule:NSEvenOddWindingRule];
    
    NSPoint center;
    float radius;
    NSWindow *window = [self window];
    BDSKSpotlightCircle *circle;
    
    while (circle = [circleEnum nextObject]) {
        center = [window convertScreenToBase:[circle center]];
        center = [self convertPoint:center fromView:nil];
        radius = [circle radius];
        [path appendBezierPathWithOvalInRect:NSMakeRect(center.x - radius, center.y - radius, radius * 2, radius * 2)];
    }
            
    // Drawing to an NSImage and then creating the CIImage with -[NSImage TIFFRepresentation] gives an incorrect CIImage extent when display scaling is turned on, probably due to NSCachedImageRep.  We also have to pass bytesPerRow:0 when scaling is on, which seems like a bug.
    NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL 
                                                                         pixelsWide:NSWidth(maskRect) 
                                                                         pixelsHigh:NSHeight(maskRect) 
                                                                      bitsPerSample:8 
                                                                    samplesPerPixel:4
                                                                           hasAlpha:YES 
                                                                           isPlanar:NO 
                                                                     colorSpaceName:NSCalibratedRGBColorSpace 
                                                                       bitmapFormat:0 
                                                                        bytesPerRow:0 /*(4 * NSWidth(maskRect)) */
                                                                       bitsPerPixel:32];

    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:imageRep]];
    
    // we need to shift because canvas of the image is at positive values
    NSAffineTransform *transform = [NSAffineTransform transform];
    [transform translateXBy:blurPadding yBy:blurPadding];
    [transform concat];
    
    // fill the entire space with clear
    [[NSColor clearColor] setFill];
    NSRectFill(maskRect);
    
    // draw the mask
    [maskColor setFill];
    [path fill];
    
    [NSGraphicsContext restoreGraphicsState];
    
    // see NSCIImageRep.h for this and other useful methods that aren't documented
    CIImage *ciImage = [[CIImage alloc] initWithBitmapImageRep:imageRep];
    
    // sys prefs uses fuzzier circles for more matches; filter range 0 -- 100, values 0 -- 10 are reasonable?
    radius = MIN([highlightCircles count], maximumBlur);
    
    // apply the blur filter to soften the edges of the circles
    CIImage *blurredImage = [ciImage blurredImageWithBlurRadius:radius];
    [ciImage release];
    
    // crop to the original bounds size; this crops all sides of the image
    CIVector *cropVector = [CIVector vectorWithX:blurPadding Y:blurPadding Z:NSWidth(aRect) W:NSHeight(aRect)];
    [cropFilter setValue:cropVector forKey:@"inputRectangle"];
    [cropFilter setValue:blurredImage forKey:@"inputImage"];
    
    return [cropFilter valueForKey:@"outputImage"];
}

// sys prefs draws solid black for no matches, so we'll do the same
- (void)drawRect:(NSRect)aRect;
{
    if([delegate isSearchActive]){
        NSRect boundsRect = [self bounds];
        CIImage *image = [self spotlightMaskImageWithFrame:boundsRect];
        CGRect extent = [image extent];
        [image drawInRect:boundsRect fromRect:*(NSRect *)&extent operation:NSCompositeCopy fraction:1.0];
    } else {
        [[NSColor clearColor] setFill];
        NSRectFill(aRect);
    }   
}

@end