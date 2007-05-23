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

- (NSRect)foregroundRect;
{    
    int i, iMax = [self pixelsWide] - MARGIN;
    int j, jMax = [self pixelsHigh] - MARGIN;
    
    unsigned int pixel[4] = { 0, 0, 0, 255 };
    
    int iLeft = iMax;
    int jTop = jMax;
    int iRight = MARGIN - 1;
    int jBottom = MARGIN - 1;
    
    unsigned int backgroundPixel[4];
    [self getPixel:backgroundPixel atX:MIN(MARGIN, iMax) y:MIN(MARGIN, jMax)];
    
    // basic idea borrowed from ImageMagick's statistics.c implementation
    
    // bitmap pixels are ordered top to bottom
    
    // top margin
    for (j = MARGIN; j < jTop; j++) {
        for (i = MARGIN; i < iMax; i++) {            
            [self getPixel:pixel atX:i y:j];
            if (differentPixels(pixel, backgroundPixel, 4)) {
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
            [self getPixel:pixel atX:i y:j];
            if (differentPixels(pixel, backgroundPixel, 4)) {
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
            [self getPixel:pixel atX:i y:j];
            if (differentPixels(pixel, backgroundPixel, 4)) {
                iLeft = i; // final
                break;
            }
        }
    }
    
    // right margin
    for (i = iMax - 1; i > iRight; i--) {
        for (j = jTop; j <= jBottom; j++) {            
            [self getPixel:pixel atX:i y:j];
            if (differentPixels(pixel, backgroundPixel, 4)) {
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
                          samplesPerPixel:4
                                 hasAlpha:YES 
                                 isPlanar:NO 
                           colorSpaceName:NSCalibratedRGBColorSpace 
                             bitmapFormat:0 
                              bytesPerRow:0 /*(4 * NSWidth(maskRect)) */
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
