//
//  NSBitmapImageRep_SKExtensions.m
//  Skim
//
//  Created by Adam Maxwell on 05/22/07.
/*
 This software is Copyright (c) 2007
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

#import "NSBitmapImageRep_SKExtensions.h"

@implementation NSBitmapImageRep (SKExtensions)

// allow for a slight margin around the image; maybe caused by a shadow (found this in testing)
static const int MARGIN = 2;

static const unsigned EPSILON = 2;

static inline BOOL differentPixels( const unsigned int *p1, const unsigned int *p2, unsigned count )
{
    unsigned i;    
    for (i = 0; i < count; i++) {
        if (abs(p2[i] - p1[i]) > EPSILON)
            return YES;
    }
    return NO;
}

static void getRGBAPixelFromBitmapData(const unsigned char *data, unsigned int widthInPixels, int x, int y, unsigned int pixel[])
{    
    typedef struct _RGBAPixel {
        unsigned char redByte, greenByte, blueByte, alphaByte;  
    } RGBAPixel;
    
    RGBAPixel *bitmapData = (RGBAPixel *)data;
    
    RGBAPixel *thisPixel = &(bitmapData[widthInPixels * y + x]);
    pixel[0] = thisPixel->redByte;
    pixel[1] = thisPixel->greenByte;
    pixel[2] = thisPixel->blueByte;
    pixel[3] = thisPixel->alphaByte;
}

// we're presently only using this with RGBA; if it ever needs to be generalized, use samplesPerPixel and add a wrapper function and more implementations; define instead of constant so the arrays show up in the debugger
#define NUMBER_OF_SAMPLES 4

- (NSRect)foregroundRect;
{    
    int i, iMax = [self pixelsWide] - MARGIN;
    int j, jMax = [self pixelsHigh] - MARGIN;
    
    unsigned int samplesPerPixel = NUMBER_OF_SAMPLES;
    unsigned int pixel[NUMBER_OF_SAMPLES];
    memset(pixel, 0, NUMBER_OF_SAMPLES);
    
    int iLeft = iMax;
    int jTop = jMax;
    int iRight = MARGIN - 1;
    int jBottom = MARGIN - 1;
    
    const unsigned char *bitmapData = [self bitmapData];
    unsigned widthInPixels = [self pixelsWide];

    unsigned int backgroundPixel[NUMBER_OF_SAMPLES];
    getRGBAPixelFromBitmapData(bitmapData, widthInPixels, MIN(MARGIN, iMax), MIN(MARGIN, jMax), backgroundPixel);
        
    // basic idea borrowed from ImageMagick's statistics.c implementation
    
    // top margin
    for (j = MARGIN; j < jTop; j++) {
        for (i = MARGIN; i < iMax; i++) {            
            getRGBAPixelFromBitmapData(bitmapData, widthInPixels, i, j, pixel);
            if (differentPixels(pixel, backgroundPixel, samplesPerPixel)) {
                // keep in mind that we're manipulating corner points, not height/width
                jTop = j; // final
                jBottom = j;
                iLeft = i;
                iRight = i;
                break;
            }
        }
    }
    
    if (jTop == jMax)
        // no foreground pixel detected
        return NSZeroRect;
    
    // bottom margin
    for (j = jMax - 1; j > jBottom; j--) {
        for (i = MARGIN; i < iMax; i++) {            
            getRGBAPixelFromBitmapData(bitmapData, widthInPixels, i, j, pixel);
            if (differentPixels(pixel, backgroundPixel, samplesPerPixel)) {
                jBottom = j; // final
                if (iLeft > i)
                    iLeft = i;
                if (iRight < i)
                    iRight = i;
                break;
            }
        }
    }
    
    // left margin
    for (i = MARGIN; i < iLeft; i++) {
        for (j = jTop; j <= jBottom; j++) {            
            getRGBAPixelFromBitmapData(bitmapData, widthInPixels, i, j, pixel);
            if (differentPixels(pixel, backgroundPixel, samplesPerPixel)) {
                iLeft = i; // final
                break;
            }
        }
    }
    
    // right margin
    for (i = iMax - 1; i > iRight; i--) {
        for (j = jTop; j <= jBottom; j++) {            
            getRGBAPixelFromBitmapData(bitmapData, widthInPixels, i, j, pixel);
            if (differentPixels(pixel, backgroundPixel, samplesPerPixel)) {
                iRight = i; // final
                break;
            }
        }
    }
    
    // finally, convert the corners to a bounding rect
    return NSMakeRect(iLeft, jMax + MARGIN - jBottom - 1, iRight + 1 - iLeft, jBottom + 1 - jTop);
}

- (NSBitmapImageRep *)initWithPDFPage:(PDFPage *)page forBox:(PDFDisplayBox)box;
{
    
    NSRect bounds = [page boundsForBox:box];    
    self = [self initWithBitmapDataPlanes:NULL
                               pixelsWide:NSWidth(bounds) 
                               pixelsHigh:NSHeight(bounds) 
                            bitsPerSample:8 
                          samplesPerPixel:NUMBER_OF_SAMPLES
                                 hasAlpha:YES 
                                 isPlanar:NO 
                           colorSpaceName:NSCalibratedRGBColorSpace 
                             bitmapFormat:0 
                              bytesPerRow:0
                             bitsPerPixel:32];
    if (self) {
        [NSGraphicsContext saveGraphicsState];
        [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:self]];
        [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationNone];
        [[NSGraphicsContext currentContext] setShouldAntialias:NO];
        int rotation = [page rotation];
        if (rotation) {
            NSAffineTransform *transform = [NSAffineTransform transform];
            [transform rotateByDegrees:rotation];
            switch (rotation) {
                case 90:
                    [transform translateXBy:0.0 yBy:-NSWidth(bounds)];
                    break;
                case 180:
                    [transform translateXBy:-NSWidth(bounds) yBy:-NSHeight(bounds)];
                    break;
                case 270:
                    [transform translateXBy:-NSHeight(bounds) yBy:0.0];
                    break;
            }
            [transform concat];
        }
        [page drawWithBox:box];
        [NSGraphicsContext restoreGraphicsState];
    }
    return self;
}

@end
