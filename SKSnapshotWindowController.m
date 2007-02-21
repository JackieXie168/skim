//
//  SKSnapshotWindowController.m


//  This code is licensed under a BSD license. Please see the file LICENSE for details.
//
//  Created by Michael McCracken on 12/6/06.
//  Copyright 2006 Michael O. McCracken. All rights reserved.
//

#import "SKSnapshotWindowController.h"
#import "SKMainWindowController.h"
#import "SKDocument.h"
#import "SKMiniaturizeWindow.h"
#import <Quartz/Quartz.h>

static NSString *SKSnapshotWindowFrameAutosaveName = @"SKSnapshotWindowFrameAutosaveName";
static NSString *SKSnapshotViewChangedNotification = @"SKSnapshotViewChangedNotification";

@implementation SKSnapshotWindowController

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver: self];
    [thumbnail release];
    [super dealloc];
}

- (NSString *)windowNibName {
    return @"SubWindow";
}

- (void)windowDidLoad {
    [[self window] setFrameUsingName:SKSnapshotWindowFrameAutosaveName];
    static NSPoint nextWindowLocation = {0.0, 0.0};
    [self setShouldCascadeWindows:NO];
    if ([[self window] setFrameAutosaveName:SKSnapshotWindowFrameAutosaveName]) {
        NSRect windowFrame = [[self window] frame];
        nextWindowLocation = NSMakePoint(NSMinX(windowFrame), NSMaxY(windowFrame));
    }
    nextWindowLocation = [[self window] cascadeTopLeftFromPoint:nextWindowLocation];
    
    [[self window] makeFirstResponder:pdfView];
}

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName {
    return [NSString stringWithFormat:@"%@ - Page %@", displayName, [[pdfView currentPage] label]];
}

- (void)handlePageChangedNotification:(NSNotification *)notification {
    [[self window] setTitle:[self windowTitleForDocumentDisplayName:[[self document] displayName]]];
    [self willChangeValueForKey:@"pageLabel"];
    [self willChangeValueForKey:@"pageIndex"];
    [self didChangeValueForKey:@"pageIndex"];
    [self didChangeValueForKey:@"pageLabel"];
}

- (void)handlePDFViewFrameChangedNotification:(NSNotification *)notification {
    if ([[self delegate] respondsToSelector:@selector(snapshotControllerViewDidChange:)]) {
        NSNotification *note = [NSNotification notificationWithName:SKSnapshotViewChangedNotification object:self];
        [[NSNotificationQueue defaultQueue] enqueueNotification:note postingStyle:NSPostWhenIdle coalesceMask:NSNotificationCoalescingOnName forModes:nil];
    }
}

- (void)handleViewChangedNotification:(NSNotification *)notification {
    if ([[self delegate] respondsToSelector:@selector(snapshotControllerViewDidChange:)])
        [[self delegate] snapshotControllerViewDidChange:self];
}

- (void)windowWillClose:(NSNotification *)notification {
    if (miniaturizing == NO && [[self delegate] respondsToSelector:@selector(snapshotControllerWindowWillClose:)])
        [[self delegate] snapshotControllerWindowWillClose:self];
}

- (void)goToDestination:(PDFDestination *)destination {
    [pdfView goToDestination:destination];
	
    [self handlePageChangedNotification:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePageChangedNotification:) 
                                                 name:PDFViewPageChangedNotification object:pdfView];
    
    NSView *clipView = [[[pdfView documentView] enclosingScrollView] contentView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleClipViewFrameChangedNotification:) 
                                                 name:NSViewFrameDidChangeNotification object:clipView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePDFViewFrameChangedNotification:) 
                                                 name:NSViewBoundsDidChangeNotification object:clipView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleViewChangedNotification:) 
                                                 name:SKSnapshotViewChangedNotification object:self];
    
    if ([[self delegate] respondsToSelector:@selector(snapshotControllerDidFinishSetup:)])
        [[self delegate] snapshotControllerDidFinishSetup:self];
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
    [self performSelector:@selector(goToDestination:) withObject:dest afterDelay:0.0];
}

#pragma mark Acessors

- (id)delegate {
    return delegate;
}

- (void)setDelegate:(id)newDelegate {
    delegate = newDelegate;
}

- (PDFView *)pdfView {
    return pdfView;
}

- (NSImage *)thumbnail {
    return thumbnail;
}

- (void)setThumbnail:(NSImage *)newThumbnail {
    if (thumbnail != newThumbnail) {
        [thumbnail release];
        thumbnail = [newThumbnail retain];
    }
}

- (NSString *)pageLabel {
    return [[pdfView currentPage] label];
}

- (unsigned int)pageIndex {
    return [[pdfView document] indexForPage:[pdfView currentPage]];
}

#pragma mark Thumbnails

- (NSImage *)thumbnailWithSize:(float)size shadowBlurRadius:(float)shadowBlurRadius shadowOffset:(NSSize)shadowOffset {
    NSView *clipView = [[[pdfView documentView] enclosingScrollView] contentView];
    NSRect bounds = [pdfView convertRect:[clipView bounds] fromView:clipView];
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

#pragma mark Miniaturize / Deminiaturize

- (void)miniaturize {
    miniaturizing = YES;
    if ([[self delegate] respondsToSelector:@selector(snapshotControllerTargetRectForMiniaturize:)]) {
        NSView *clipView = [[[pdfView documentView] enclosingScrollView] contentView];
        NSRect startRect = [pdfView convertRect:[clipView bounds] fromView:clipView];
        NSRect endRect = [[self delegate] snapshotControllerTargetRectForMiniaturize:self];
        float thumbRatio = NSHeight(startRect) / NSWidth(startRect);
        float cellRatio = NSHeight(endRect) / NSWidth(endRect);
        
        startRect = [pdfView convertRect:startRect toView:nil];
        startRect.origin = [[self window] convertBaseToScreen:startRect.origin];
        if (thumbRatio > cellRatio)
            endRect = NSInsetRect(endRect, 0.5 * NSWidth(endRect) * (1.0 - cellRatio / thumbRatio), 0.0);
        else
            endRect = NSInsetRect(endRect, 0.0, 0.5 * NSHeight(endRect) * (1.0 - thumbRatio / cellRatio));
        
        NSImage *image = [self thumbnailWithSize:0.0 shadowBlurRadius:0.0 shadowOffset:NSZeroSize];
        SKMiniaturizeWindow *miniaturizeWindow = [[SKMiniaturizeWindow alloc] initWithContentRect:startRect image:image];
        
        [miniaturizeWindow orderFront:self];
        [[self window] orderOut:self];
        [miniaturizeWindow setFrame:endRect display:YES animate:YES];
        [miniaturizeWindow orderOut:self];
        [miniaturizeWindow release];
    } else {
        [[self window] orderOut:self];
    }
    miniaturizing = NO;
}

- (void)deminiaturize {
    if ([[self delegate] respondsToSelector:@selector(snapshotControllerSourceRectForDeminiaturize:)]) {
        NSView *clipView = [[[pdfView documentView] enclosingScrollView] contentView];
        NSRect endRect = [pdfView convertRect:[clipView bounds] fromView:clipView];
        NSRect startRect = [[self delegate] snapshotControllerSourceRectForDeminiaturize:self];
        float thumbRatio = NSHeight(endRect) / NSWidth(endRect);
        float cellRatio = NSHeight(startRect) / NSWidth(startRect);
        
        endRect = [pdfView convertRect:endRect toView:nil];
        endRect.origin = [[self window] convertBaseToScreen:endRect.origin];
        if (thumbRatio > cellRatio)
            startRect = NSInsetRect(startRect, 0.5 * NSWidth(startRect) * (1.0 - cellRatio / thumbRatio), 0.0);
        else
            startRect = NSInsetRect(startRect, 0.0, 0.5 * NSHeight(startRect) * (1.0 - thumbRatio / cellRatio));
        
        NSImage *image = [self thumbnailWithSize:0.0 shadowBlurRadius:0.0 shadowOffset:NSZeroSize];
        SKMiniaturizeWindow *miniaturizeWindow = [[SKMiniaturizeWindow alloc] initWithContentRect:startRect image:image];
        
        [miniaturizeWindow orderFront:self];
        [miniaturizeWindow setFrame:endRect display:YES animate:YES];
        [[self window] orderFront:self];
        [miniaturizeWindow orderOut:self];
        [miniaturizeWindow release];
    } else {
        [self showWindow:self];
    }
}

@end

#pragma mark -

@interface NSWindow (SKPrivate)
- (id)_updateButtonsForModeChanged;
@end

@implementation SKSnapshotWindow

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
    [[self windowController] miniaturize];
}

@end
