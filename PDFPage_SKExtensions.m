//
//  PDFPage_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 2/16/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "PDFPage_SKExtensions.h"


@implementation PDFPage (SKExtensions) 

- (NSImage *)image {
    NSRect bounds = [self boundsForBox:kPDFDisplayBoxCropBox];
    NSImage *image = [[NSImage alloc] initWithSize:bounds.size];
    
    [image lockFocus];
    [NSGraphicsContext saveGraphicsState];
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
    if ([self rotation]) {
        NSAffineTransform *transform = [NSAffineTransform transform];
        [transform rotateByDegrees:[self rotation]];
        switch ([self rotation]) {
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
    [[NSColor whiteColor] set];
    bounds.origin = NSZeroPoint;
    NSRectFill(bounds);
    [self drawWithBox:kPDFDisplayBoxCropBox]; 
    [NSGraphicsContext restoreGraphicsState];
    [image unlockFocus];
    
    return [image autorelease];
}

- (NSImage *)thumbnailWithSize:(float)size shadowBlurRadius:(float)shadowBlurRadius shadowOffset:(NSSize)shadowOffset {
    NSRect bounds = [self boundsForBox:kPDFDisplayBoxCropBox];
    BOOL isScaled = size > 0.0;
    BOOL hasShadow = shadowBlurRadius > 0.0;
    float scaleX, scaleY;
    NSSize thumbnailSize;
    NSImage *image;
    
    if ([self rotation] % 180 == 90)
        bounds = NSMakeRect(NSMinX(bounds), NSMinY(bounds), NSHeight(bounds), NSWidth(bounds));
    
    if (isScaled) {
        if (NSHeight(bounds) > NSWidth(bounds))
            thumbnailSize = NSMakeSize(roundf((size - 2.0 * shadowBlurRadius) * NSWidth(bounds) / NSHeight(bounds) + 2.0 * shadowBlurRadius), size);
        else
            thumbnailSize = NSMakeSize(size, roundf((size - 2.0 * shadowBlurRadius) * NSHeight(bounds) / NSWidth(bounds) + 2.0 * shadowBlurRadius));
        scaleX = (thumbnailSize.width - 2.0 * shadowBlurRadius) / NSWidth(bounds);
        scaleY = (thumbnailSize.height - 2.0 * shadowBlurRadius) / NSHeight(bounds);
    } else {
        thumbnailSize = NSMakeSize(NSWidth(bounds) + 2.0 * shadowBlurRadius, NSHeight(bounds) + 2.0 * shadowBlurRadius);
        scaleX = scaleY = 1.0;
    }
    
    image = [[NSImage alloc] initWithSize:thumbnailSize];
    [image lockFocus];
    [NSGraphicsContext saveGraphicsState];
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
    if (isScaled || hasShadow) {
        NSAffineTransform *transform = [NSAffineTransform transform];
        if (isScaled)
            [transform scaleXBy:scaleX yBy:scaleY];
        [transform translateXBy:(shadowBlurRadius - shadowOffset.width) / scaleX yBy:(shadowBlurRadius - shadowOffset.height) / scaleY];
        [transform concat];
    }
    [NSGraphicsContext saveGraphicsState];
    [[NSColor whiteColor] set];
    if (hasShadow) {
        NSShadow *shadow = [[NSShadow alloc] init];
        [shadow setShadowColor:[NSColor colorWithDeviceWhite:0.0 alpha:0.5]];
        [shadow setShadowBlurRadius:shadowBlurRadius];
        [shadow setShadowOffset:shadowOffset];
        [shadow set];
        [shadow release];
    }
    bounds.origin = NSZeroPoint;
    NSRectFill(bounds);
    [NSGraphicsContext restoreGraphicsState];
    [self drawWithBox:kPDFDisplayBoxCropBox]; 
    [NSGraphicsContext restoreGraphicsState];
    [image unlockFocus];
    
    return [image autorelease];
}

@end
