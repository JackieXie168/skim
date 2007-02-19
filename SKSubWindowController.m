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

static NSString *SKSubWindowFrameAutosaveName = @"SKSubWindowFrameAutosaveName";

@implementation SKSubWindowController

- (NSString *)windowNibName {
    return @"SubWindow";
}

- (void)windowDidLoad {
    [[self window] setFrameUsingName:SKSubWindowFrameAutosaveName];
    static NSPoint nextWindowLocation = {0.0, 0.0};
    [self setShouldCascadeWindows:NO];
    if ([[self window] setFrameAutosaveName:SKSubWindowFrameAutosaveName]) {
        NSRect windowFrame = [[self window] frame];
        nextWindowLocation = NSMakePoint(NSMinX(windowFrame), NSMaxY(windowFrame));
    }
    nextWindowLocation = [[self window] cascadeTopLeftFromPoint:nextWindowLocation];
    
    [[self window] makeFirstResponder:pdfView];
}

- (void)setPdfDocument:(PDFDocument *)pdfDocument scaleFactor:(float)factor goToPageNumber:(int)pageNum rect:(NSRect)rect{
    [self window];
    
    [pdfView setDocument:pdfDocument];
    [pdfView setScaleFactor:factor];
    [pdfView setAutoScales:NO];
    
    PDFPage *page = [pdfDocument pageAtIndex:pageNum];
    NSRect contentRect = [pdfView convertRect:rect fromPage:page];
    NSRect frame = [[self window] frame];
    NSRect screenFrame = [[[self window] screen] visibleFrame];
    
    contentRect.size.width += [NSScroller scrollerWidth];
    contentRect.size.height += [NSScroller scrollerWidth];
    frame.size = [[self window] frameRectForContentRect:contentRect].size;
    
    if (NSMaxX(frame) > NSMaxX(screenFrame))
        frame.origin.x = NSMaxX(screenFrame) - NSWidth(frame);
    if (NSMinX(frame) < NSMinX(screenFrame)) {
        frame.origin.x = NSMinX(screenFrame);
        if (NSWidth(frame) > NSWidth(screenFrame))
            frame.size.width = NSWidth(screenFrame);
    }
    if (NSMaxY(frame) > NSMaxY(screenFrame))
        frame.origin.x = NSMaxY(screenFrame) - NSHeight(frame);
    if (NSMinY(frame) < NSMinY(screenFrame)) {
        frame.origin.x = NSMinY(screenFrame);
        if (NSHeight(frame) > NSHeight(screenFrame))
            frame.size.height = NSHeight(screenFrame);
    }
    
    [[self window] setFrame:NSIntegralRect(frame) display:NO animate:NO];
    
    [pdfView goToPage:page];
    
    NSPoint point;
    point.x = ([page rotation] == 0 || [page rotation] == 90) ? NSMinX(rect) : NSMaxX(rect);
    point.y = ([page rotation] == 90 || [page rotation] == 180) ? NSMinY(rect) : NSMaxY(rect);
    
    PDFDestination *dest = [[[PDFDestination alloc] initWithPage:page atPoint:point] autorelease];
    
    // Delayed to allow PDFView to finish its bookkeeping 
    // fixes bug of apparently ignoring the point but getting the page right.
    [pdfView performSelector:@selector(goToDestination:) withObject:dest afterDelay:0.1];
}

- (PDFView *)pdfView {
    return pdfView;
}

- (NSRect)rectForThumbnail {
    NSView *clipView = [[[pdfView documentView] enclosingScrollView] contentView];
    NSRect rect = [pdfView convertRect:[clipView bounds] fromView:clipView];
    return [pdfView convertRect:rect toView:nil];
}

- (NSImage *)thumbnailWithSize:(float)size shadowBlurRadius:(float)shadowBlurRadius shadowOffset:(NSSize)shadowOffset {
    NSRect bounds = [pdfView convertRect:[self rectForThumbnail] fromView:nil];
    NSBitmapImageRep *imageRep = [pdfView bitmapImageRepForCachingDisplayInRect:bounds];
    BOOL isScaled = size > 0.0;
    BOOL hasShadow = shadowBlurRadius > 0.0;
    float scaleX, scaleY;
    NSSize thumbnailSize;
    NSImage *image;
    
    [pdfView cacheDisplayInRect:bounds toBitmapImageRep:imageRep];
    
    
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
    [imageRep drawInRect:bounds];
    [NSGraphicsContext restoreGraphicsState];
    [image unlockFocus];
    
    return [image autorelease];
}

@end


@interface NSWindow (SKPrivate)
- (id)_updateButtonsForModeChanged;
@end


@implementation SKSubWindow

- (id)initWithContentRect:(NSRect)contentRect styleMask:(unsigned int)styleMask backing:(NSBackingStoreType)bufferingType defer:(BOOL)deferCreation {
    if (self = [super initWithContentRect:contentRect styleMask:styleMask backing:bufferingType defer:deferCreation]) {
        [[self standardWindowButton:NSWindowMiniaturizeButton] setEnabled:YES];
    }
    return self;
}

- (id)_updateButtonsForModeChanged {
    id rv = [super _updateButtonsForModeChanged];
    [[self standardWindowButton:NSWindowMiniaturizeButton] setEnabled:YES];
    return rv;
}

- (void)miniaturize:(id)sender {
    [[[[self windowController] document] mainWindowController] miniaturizeSnapshotController:[self windowController]];
}

@end
