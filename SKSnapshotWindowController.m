//
//  SKSnapshotWindowController.m
//  Skim
//
//  Created by Michael McCracken on 12/6/06.
/*
 This software is Copyright (c) 2006,2007
 Michael O. McCracken. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

 - Neither the name of Michael O. McCracken nor the names of any
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

#import "SKSnapshotWindowController.h"
#import "SKMainWindowController.h"
#import "SKDocument.h"
#import "SKMiniaturizeWindow.h"
#import <Quartz/Quartz.h>
#import "SKPDFAnnotationNote.h"
#import "SKPDFView.h"
#import "NSWindowController_SKExtensions.h"
#import "SKStringConstants.h"
#import "NSUserDefaultsController_SKExtensions.h"

static NSString *SKSnapshotWindowFrameAutosaveName = @"SKSnapshotWindow";
static NSString *SKSnapshotViewChangedNotification = @"SKSnapshotViewChangedNotification";

@implementation SKSnapshotWindowController

- (void)dealloc {
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKey:SKSnapshotsOnTopKey];
	[[NSNotificationCenter defaultCenter] removeObserver: self];
    [thumbnail release];
    [super dealloc];
}

- (NSString *)windowNibName {
    return @"SnapshotWindow";
}

- (void)windowDidLoad {
    BOOL keepOnTop = [[NSUserDefaults standardUserDefaults] boolForKey:SKSnapshotsOnTopKey];
    [[self window] setLevel:keepOnTop || forceOnTop ? NSFloatingWindowLevel : NSNormalWindowLevel];
    [[self window] setHidesOnDeactivate:keepOnTop];
    [self setWindowFrameAutosaveNameOrCascade:SKSnapshotWindowFrameAutosaveName];
    [[self window] makeFirstResponder:pdfView];
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKey:SKSnapshotsOnTopKey];
}

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName {
    return [NSString stringWithFormat:@"%@ - Page %@", displayName, [[pdfView currentPage] label]];
}

- (void)handlePageChangedNotification:(NSNotification *)notification {
    [[self window] setTitle:[self windowTitleForDocumentDisplayName:[[self document] displayName]]];
    [self willChangeValueForKey:@"pageLabel"];
    [self didChangeValueForKey:@"pageLabel"];
    [self willChangeValueForKey:@"pageIndex"];
    [self didChangeValueForKey:@"pageIndex"];
    [self willChangeValueForKey:@"pageAndWindow"];
    [self didChangeValueForKey:@"pageAndWindow"];
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

- (void)handleAnnotationDidChangeNotification:(NSNotification *)notification {
    PDFAnnotation *annotation = [notification object];
    if ([[annotation page] isEqual:[pdfView currentPage]]) {
        NSRect aRect = [pdfView convertRect:[[annotation page] boundsForBox:kPDFDisplayBoxMediaBox] fromPage:[annotation page]];
        float scale = [pdfView scaleFactor];
        NSPoint max = NSMakePoint(ceilf(NSMaxX(aRect)) + scale, ceilf(NSMaxY(aRect)) + scale);
        NSPoint origin = NSMakePoint(floorf(NSMinX(aRect)) - scale, floorf(NSMinY(aRect)) - scale);
        [pdfView setNeedsDisplayInRect:NSMakeRect(origin.x, origin.y, max.x - origin.x, max.y - origin.y)];
    }
}

- (void)handleDidRemoveAnnotationNotification:(NSNotification *)notification {
    PDFPage *page = [[notification userInfo] objectForKey:@"page"];
    if ([page isEqual:[pdfView currentPage]]) {
        [page removeAnnotation:[[notification userInfo] objectForKey:@"annotation"]];
        NSRect aRect = [pdfView convertRect:[page boundsForBox:kPDFDisplayBoxMediaBox] fromPage:page];
        float scale = [pdfView scaleFactor];
        NSPoint max = NSMakePoint(ceilf(NSMaxX(aRect)) + scale, ceilf(NSMaxY(aRect)) + scale);
        NSPoint origin = NSMakePoint(floorf(NSMinX(aRect)) - scale, floorf(NSMinY(aRect)) - scale);
        [pdfView setNeedsDisplayInRect:NSMakeRect(origin.x, origin.y, max.x - origin.x, max.y - origin.y)];
    }
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePDFViewFrameChangedNotification:) 
                                                 name:NSViewFrameDidChangeNotification object:clipView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePDFViewFrameChangedNotification:) 
                                                 name:NSViewBoundsDidChangeNotification object:clipView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleViewChangedNotification:) 
                                                 name:SKSnapshotViewChangedNotification object:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAnnotationDidChangeNotification:) 
                                                 name:SKAnnotationDidChangeNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDidRemoveAnnotationNotification:) 
                                                 name:SKPDFViewDidRemoveAnnotationNotification object:nil];    
    if ([[self delegate] respondsToSelector:@selector(snapshotControllerDidFinishSetup:)])
        [[self delegate] performSelector:@selector(snapshotControllerDidFinishSetup:) withObject:self afterDelay:0.1];
}

- (void)setPdfDocument:(PDFDocument *)pdfDocument scaleFactor:(float)factor goToPageNumber:(int)pageNum rect:(NSRect)rect{
    [self window];
    
    [pdfView setDocument:pdfDocument];
    [pdfView setScaleFactor:factor];
    [pdfView setAutoScales:NO];
    [pdfView setDisplaysPageBreaks:NO];
    
    PDFPage *page = [pdfDocument pageAtIndex:pageNum];
    NSRect contentRect = [pdfView convertRect:rect fromPage:page];
    contentRect = [pdfView convertRect:contentRect toView:nil];
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
    [self performSelector:@selector(goToDestination:) withObject:dest afterDelay:0.1];
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

- (NSDictionary *)pageAndWindow {
    NSString *label = [self pageLabel] ? [self pageLabel] : @"";
    NSNumber *hasWindow = [NSNumber numberWithBool:[[self window] isVisible]];
    return [NSDictionary dictionaryWithObjectsAndKeys:label, @"label", hasWindow, @"hasWindow", nil];
}

- (BOOL)forceOnTop {
    return forceOnTop;
}

- (void)setForceOnTop:(BOOL)flag {
    forceOnTop = flag;
    BOOL keepOnTop = [[NSUserDefaults standardUserDefaults] boolForKey:SKSnapshotsOnTopKey];
    [[self window] setLevel:keepOnTop || forceOnTop ? NSFloatingWindowLevel : NSNormalWindowLevel];
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
    [self willChangeValueForKey:@"pageAndWindow"];
    [self didChangeValueForKey:@"pageAndWindow"];
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
    [self willChangeValueForKey:@"pageAndWindow"];
    [self didChangeValueForKey:@"pageAndWindow"];
}

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == [NSUserDefaultsController sharedUserDefaultsController] && [keyPath hasPrefix:@"values."]) {
        NSString *key = [keyPath substringFromIndex:7];
        if ([key isEqualToString:SKSnapshotsOnTopKey]) {
            BOOL keepOnTop = [[NSUserDefaults standardUserDefaults] boolForKey:SKSnapshotsOnTopKey];
            [[self window] setLevel:keepOnTop || forceOnTop ? NSFloatingWindowLevel : NSNormalWindowLevel];
            [[self window] setHidesOnDeactivate:keepOnTop];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
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
