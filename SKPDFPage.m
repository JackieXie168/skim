//
//  SKPDFPage.m
//  Skim
//
//  Created by Christiaan Hofman on 9/4/09.
/*
 This software is Copyright (c) 2009-2012
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

#import "SKPDFPage.h"
#import "SKStringConstants.h"
#import "NSBitmapImageRep_SKExtensions.h"
#import "NSData_SKExtensions.h"
#import "NSGeometry_SKExtensions.h"
#import "NSUserDefaults_SKExtensions.h"

#define SKAutoCropBoxMarginWidthKey @"SKAutoCropBoxMarginWidth"
#define SKAutoCropBoxMarginHeightKey @"SKAutoCropBoxMarginHeight"

@implementation SKPDFPage

- (BOOL)isEditable { return YES; }

- (NSBitmapImageRep *)newBitmapImageRepForBox:(PDFDisplayBox)box {
    NSRect bounds = [self boundsForBox:box];
    NSBitmapImageRep *imageRep;
    imageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
                                                       pixelsWide:NSWidth(bounds) 
                                                       pixelsHigh:NSHeight(bounds) 
                                                    bitsPerSample:8 
                                                  samplesPerPixel:4
                                                         hasAlpha:YES 
                                                         isPlanar:NO 
                                                   colorSpaceName:NSCalibratedRGBColorSpace 
                                                     bitmapFormat:0 
                                                      bytesPerRow:0 
                                                     bitsPerPixel:32];
    if (imageRep) {
        [NSGraphicsContext saveGraphicsState];
        [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:imageRep]];
        [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationNone];
        [[NSGraphicsContext currentContext] setShouldAntialias:NO];
        if ([self rotation]) {
            NSAffineTransform *transform = [NSAffineTransform transform];
            switch ([self rotation]) {
                case 90:  [transform translateXBy:NSWidth(bounds) yBy:0.0]; break;
                case 180: [transform translateXBy:NSHeight(bounds) yBy:NSWidth(bounds)]; break;
                case 270: [transform translateXBy:0.0 yBy:NSHeight(bounds)]; break;
            }
            [transform rotateByDegrees:[self rotation]];
            [transform concat];
        }
        [self drawWithBox:box]; 
        [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationDefault];
        [NSGraphicsContext restoreGraphicsState];
    }
    return imageRep;
}

- (NSRect)foregroundBox {
    if (NSEqualRects(NSZeroRect, foregroundBox)) {
        CGFloat marginWidth = [[NSUserDefaults standardUserDefaults] floatForKey:SKAutoCropBoxMarginWidthKey];
        CGFloat marginHeight = [[NSUserDefaults standardUserDefaults] floatForKey:SKAutoCropBoxMarginHeightKey];
        NSBitmapImageRep *imageRep = [self newBitmapImageRepForBox:kPDFDisplayBoxMediaBox];
        NSRect bounds = [self boundsForBox:kPDFDisplayBoxMediaBox];
        foregroundBox = [imageRep foregroundRect];
        if (imageRep == nil) {
            foregroundBox = [self boundsForBox:kPDFDisplayBoxMediaBox];
        } else if (NSIsEmptyRect(foregroundBox)) {
            foregroundBox.origin = SKIntegralPoint(SKCenterPoint(bounds));
            foregroundBox.size = NSZeroSize;
        } else {
            foregroundBox.origin = SKAddPoints(foregroundBox.origin, bounds.origin);
        }
        [imageRep release];
        foregroundBox = NSIntersectionRect(NSInsetRect(foregroundBox, -marginWidth, -marginHeight), bounds);
    }
    return foregroundBox;
}

- (NSAttributedString *)attributedString {
    // on 10.6 the attributedstring is over-released by one
    if ((NSInteger)floor(NSAppKitVersionNumber) == NSAppKitVersionNumber10_6)
        return [[super attributedString] retain];
    return [super attributedString];
}

- (void)drawWithBox:(PDFDisplayBox)box {
   NSColor *backgroundColor = [[NSUserDefaults standardUserDefaults] colorForKey:SKPageBackgroundColorKey];
   if (backgroundColor && [[NSGraphicsContext currentContext] isDrawingToScreen]) {
       [NSGraphicsContext saveGraphicsState];
       [self transformContextForBox:box];
       [backgroundColor setFill];
       NSRectFillUsingOperation([self boundsForBox:box], NSCompositeSourceOver);
       [NSGraphicsContext restoreGraphicsState];
   }
   [super drawWithBox:box];
}

@end
