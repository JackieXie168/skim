//
//  SKPDFPage.m
//  Skim
//
//  Created by Christiaan on 9/4/09.
//  Copyright 2009 Christiaan Hofman. All rights reserved.
//

#import "SKPDFPage.h"
#import "SKStringConstants.h"
#import "NSBitmapImageRep_SKExtensions.h"
#import "NSData_SKExtensions.h"
#import "SKPDFAnnotationTemporary.h"
#import "NSGeometry_SKExtensions.h"

#define SKAutoCropBoxMarginWidthKey @"SKAutoCropBoxMarginWidth"
#define SKAutoCropBoxMarginHeightKey @"SKAutoCropBoxMarginHeight"

@implementation SKPDFPage

- (id)init {
    if (self = [super init]) {
        foregroundBox = NSZeroRect;
    }
    return self;
}

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
        [[self annotations] makeObjectsPerformSelector:@selector(hideIfTemporary)];
        [self drawWithBox:box]; 
        [[self annotations] makeObjectsPerformSelector:@selector(displayIfTemporary)];
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
    if (floor(NSAppKitVersionNumber) > 949)
        return [[super attributedString] retain];
    return [super attributedString];
}

@end
