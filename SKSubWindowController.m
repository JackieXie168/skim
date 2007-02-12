//
//  SKSubWindowController.m


//  This code is licensed under a BSD license. Please see the file LICENSE for details.
//
//  Created by Michael McCracken on 12/6/06.
//  Copyright 2006 Michael O. McCracken. All rights reserved.
//

#import "SKSubWindowController.h"
#import "SKMainWindowController.h"
#import "SKDocument.h"
#import <Quartz/Quartz.h>


@implementation SKSubWindowController

- (NSString *)windowNibName {
    return @"SubWindow";
}

- (void)setPdfDocument:(PDFDocument *)pdfDocument scaleFactor:(int)factor autoScales:(BOOL)autoScales goToPageNumber:(int)pageNum point:(NSPoint)locationInPageSpace{
    [self window];
    [pdfView setDocument:pdfDocument];
    [pdfView setScaleFactor:factor];
    
    PDFPage *page = [pdfDocument pageAtIndex:pageNum];
    PDFDestination *dest = [[[PDFDestination alloc] initWithPage:page atPoint:locationInPageSpace] autorelease];
    NSRect frame = [[self window] frame];
    frame.size.width = [pdfView rowSizeForPage:[dest page]].width;
    [[self window] setFrame:frame display:NO animate:NO];
    
    [pdfView setAutoScales:autoScales];
    
    [pdfView becomeFirstResponder];
    // Delayed to allow PDFView to finish its bookkeeping 
    // fixes bug of apparently ignoring the point but getting the page right.
    [pdfView performSelector:@selector(goToDestination:) withObject:dest afterDelay:0.1];
}

- (void)windowWillClose:(NSNotification *)aNotification {
    [[[self window] parentWindow] removeChildWindow:[self window]];
}

- (PDFView *)pdfView {
    return pdfView;
}

- (NSImage *)thumbnailWithSize:(float)size shadowBlurRadius:(float)shadowBlurRadius shadowOffset:(NSSize)shadowOffset {
    NSView *clipView = [[[pdfView documentView] enclosingScrollView] contentView];
    NSRect bounds = [pdfView convertRect:[clipView bounds] fromView:clipView];
    NSBitmapImageRep *imageRep = [pdfView bitmapImageRepForCachingDisplayInRect:bounds];
    BOOL isScaled = size > 0.0;
    BOOL hasShadow = shadowBlurRadius > 0.0;
    float scale = isScaled ? (size - 2.0 * shadowBlurRadius) / MAX(NSWidth(bounds), NSHeight(bounds)) : 1.0;
    NSSize thumbnailSize = NSMakeSize(scale * NSWidth(bounds) + 2.0 * shadowBlurRadius, scale * NSHeight(bounds) + 2.0 * shadowBlurRadius);
    NSImage *image = [[NSImage alloc] initWithSize:thumbnailSize];
    
    [pdfView cacheDisplayInRect:bounds toBitmapImageRep:imageRep];
    
    [image lockFocus];
    [NSGraphicsContext saveGraphicsState];
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
    if (isScaled || hasShadow) {
        NSAffineTransform *transform = [NSAffineTransform transform];
        if (isScaled)
            [transform scaleBy:scale];
        [transform translateXBy:(shadowBlurRadius - shadowOffset.width) / scale yBy:(shadowBlurRadius - shadowOffset.height) / scale];
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
    [imageRep drawInRect:bounds];
    [NSGraphicsContext restoreGraphicsState];
    [image unlockFocus];
    
    return [image autorelease];
}

@end


@implementation SKSubWindow

- (void)miniaturize:(id)sender {
    [[[[self windowController] document] mainWindowController] miniaturizeSubWindowController:[self windowController]];
}

- (NSTimeInterval)animationResizeTime:(NSRect)newWindowFrame {
    return 0.3;
}

@end
