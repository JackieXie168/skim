//
//  SKSnapshotWindowController.m
//  Skim
//
//  Created by Michael McCracken on 12/6/06.
/*
 This software is Copyright (c) 2006-2008
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
#import "SKPDFDocument.h"
#import "SKMiniaturizeWindow.h"
#import <Quartz/Quartz.h>
#import "BDSKZoomablePDFView.h"
#import <SkimNotes/PDFAnnotation_SKNExtensions.h>
#import "SKPDFView.h"
#import "NSWindowController_SKExtensions.h"
#import "SKStringConstants.h"
#import "NSUserDefaultsController_SKExtensions.h"
#import "NSGeometry_SKExtensions.h"
#import "PDFPage_SKExtensions.h"
#import "SKSnapshotPageCell.h"
#import "SKUtilities.h"

NSString *SKSnapshotCurrentSetupKey = @"currentSetup";

static NSString *SKSnapshotPageKey = @"page";
static NSString *SKSnapshotRectKey = @"rect";
static NSString *SKSnapshotScaleFactorKey = @"scaleFactor";
static NSString *SKSnapshotAutoFitsKey = @"autoFits";
static NSString *SKSnapshotHasWindowKey = @"hasWindow";
static NSString *SKSnapshotWindowFrameKey = @"windowFrame";

static NSString *SKSnapshotWindowPageLabelKey = @"pageLabel";
static NSString *SKSnapshotWindowHasWindowKey = @"hasWindow";
static NSString *SKSnapshotWindowPageAndWindowKey = @"pageAndWindow";

static NSString *SKSnapshotWindowFrameAutosaveName = @"SKSnapshotWindow";
static NSString *SKSnapshotViewChangedNotification = @"SKSnapshotViewChangedNotification";

static void *SKSnaphotWindowDefaultsObservationContext = (void *)@"SKSnaphotWindowDefaultsObservationContext";

@interface SKSnapshotWindowController (SKPrivate) 
- (void)setPageLabel:(NSString *)newPageLabel;
- (void)setHasWindow:(BOOL)flag;
@end

@implementation SKSnapshotWindowController

+ (void)initialize {
    [self setKeys:[NSArray arrayWithObjects:SKSnapshotWindowPageLabelKey, SKSnapshotWindowHasWindowKey, nil] triggerChangeNotificationsForDependentKey:SKSnapshotWindowPageAndWindowKey];
    OBINITIALIZE;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver: self];
    [thumbnail release];
    [pageLabel release];
    [super dealloc];
}

- (NSString *)windowNibName {
    return @"SnapshotWindow";
}

- (void)windowDidLoad {
    BOOL keepOnTop = [[NSUserDefaults standardUserDefaults] boolForKey:SKSnapshotsOnTopKey];
    [[self window] setLevel:keepOnTop || forceOnTop ? NSFloatingWindowLevel : NSNormalWindowLevel];
    [[self window] setHidesOnDeactivate:keepOnTop || forceOnTop];
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKey:SKSnapshotsOnTopKey context:SKSnaphotWindowDefaultsObservationContext];
}

- (void)windowDidExpose:(NSNotification *)notification {
    [self setHasWindow:YES];
}

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName {
    return [NSString stringWithFormat:NSLocalizedString(@"%@ %C Page %@", @"Window title format: [filename] - Page [number]"), displayName, 0x2014, [[pdfView currentPage] label]];
}

- (void)setNeedsDisplayInRect:(NSRect)rect ofPage:(PDFPage *)page {
    NSRect aRect = [pdfView convertRect:rect fromPage:page];
    float scale = [pdfView scaleFactor];
	float maxX = ceilf(NSMaxX(aRect) + scale);
	float maxY = ceilf(NSMaxY(aRect) + scale);
	float minX = floorf(NSMinX(aRect) - scale);
	float minY = floorf(NSMinY(aRect) - scale);
	
    aRect = NSIntersectionRect([pdfView bounds], NSMakeRect(minX, minY, maxX - minX, maxY - minY));
    if (NSIsEmptyRect(aRect) == NO)
        [pdfView setNeedsDisplayInRect:aRect];
}

- (void)setNeedsDisplayForAnnotation:(PDFAnnotation *)annotation onPage:(PDFPage *)page {
    NSRect bounds = [annotation bounds];
    if ([[annotation type] isEqualToString:SKNUnderlineString]) {
        float delta = 0.03 * NSHeight(bounds);
        bounds.origin.y -= delta;
        bounds.size.height += delta;
    } else if ([[annotation type] isEqualToString:SKNLineString]) {
        // need a large padding amount for large line width and cap changes
        bounds = NSInsetRect(bounds, -20.0, -20.0);
    }
    [self setNeedsDisplayInRect:bounds ofPage:page];
}

- (void)redisplay {
    [pdfView setNeedsDisplay:YES];
}

- (void)handlePageChangedNotification:(NSNotification *)notification {
    NSString *label = [[pdfView currentPage] label];
    [self setPageLabel:label ? label : [NSString stringWithFormat:@"%i", [self pageIndex]]];
    [[self window] setTitle:[self windowTitleForDocumentDisplayName:[[self document] displayName]]];
}

- (void)handleDocumentDidUnlockNotification:(NSNotification *)notification {
    [[self window] setTitle:[self windowTitleForDocumentDisplayName:[[self document] displayName]]];
    NSString *label = [[pdfView currentPage] label];
    [self setPageLabel:label ? label : [NSString stringWithFormat:@"%i", [self pageIndex]]];
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

- (void)handleDidAddRemoveAnnotationNotification:(NSNotification *)notification {
    PDFAnnotation *annotation = [[notification userInfo] objectForKey:SKPDFViewAnnotationKey];
    PDFPage *page = [[notification userInfo] objectForKey:SKPDFViewPageKey];
    if ([[page document] isEqual:[pdfView document]] && [self isPageVisible:page])
        [self setNeedsDisplayForAnnotation:annotation onPage:page];
}

- (void)handleDidMoveAnnotationNotification:(NSNotification *)notification {
    PDFAnnotation *annotation = [notification object];
    PDFPage *oldPage = [[notification userInfo] objectForKey:SKPDFViewOldPageKey];
    PDFPage *newPage = [[notification userInfo] objectForKey:SKPDFViewNewPageKey];
    if ([[newPage document] isEqual:[pdfView document]]) {
        if ([self isPageVisible:oldPage])
            [self setNeedsDisplayForAnnotation:annotation onPage:oldPage];
        if ([self isPageVisible:newPage])
            [self setNeedsDisplayForAnnotation:annotation onPage:newPage];
    }
}

- (void)windowWillClose:(NSNotification *)notification {
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKey:SKSnapshotsOnTopKey];
    if (miniaturizing == NO && [[self delegate] respondsToSelector:@selector(snapshotControllerWindowWillClose:)])
        [[self delegate] snapshotControllerWindowWillClose:self];
}


- (void)goToDestination:(PDFDestination *)destination {
    [pdfView goToDestination:destination];
    
    [[self window] makeFirstResponder:pdfView];
	
    [self handlePageChangedNotification:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePageChangedNotification:) 
                                                 name:PDFViewPageChangedNotification object:pdfView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDocumentDidUnlockNotification:) 
                                                 name:PDFDocumentDidUnlockNotification object:[pdfView document]];
    
    NSView *clipView = [[[pdfView documentView] enclosingScrollView] contentView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePDFViewFrameChangedNotification:) 
                                                 name:NSViewFrameDidChangeNotification object:clipView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePDFViewFrameChangedNotification:) 
                                                 name:NSViewBoundsDidChangeNotification object:clipView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleViewChangedNotification:) 
                                                 name:SKSnapshotViewChangedNotification object:self];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDidAddRemoveAnnotationNotification:) 
                                                 name:SKPDFViewDidAddAnnotationNotification object:nil];    
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDidAddRemoveAnnotationNotification:) 
                                                 name:SKPDFViewDidRemoveAnnotationNotification object:nil];    
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDidMoveAnnotationNotification:) 
                                                 name:SKPDFViewDidMoveAnnotationNotification object:nil];    
    if ([[self delegate] respondsToSelector:@selector(snapshotControllerDidFinishSetup:)])
        [[self delegate] performSelector:@selector(snapshotControllerDidFinishSetup:) withObject:self afterDelay:0.1];
}

- (void)setPdfDocument:(PDFDocument *)pdfDocument scaleFactor:(float)factor goToPageNumber:(int)pageNum rect:(NSRect)rect autoFits:(BOOL)autoFits {
    [self window];
    
    [pdfView setScaleFactor:factor];
    [pdfView setAutoScales:NO];
    [pdfView setDisplaysPageBreaks:NO];
    [pdfView setDisplayBox:kPDFDisplayBoxCropBox];
    [pdfView setDocument:pdfDocument];
    
    PDFPage *page = [pdfDocument pageAtIndex:pageNum];
    NSRect contentRect = [pdfView convertRect:rect fromPage:page];
    contentRect = [pdfView convertRect:contentRect toView:nil];
    NSRect frame = [[self window] frame];
    
    contentRect.size.width += [NSScroller scrollerWidth];
    contentRect.size.height += [NSScroller scrollerWidth];
    frame.size = [[self window] frameRectForContentRect:contentRect].size;
    frame = SKConstrainRect(frame, [[[self window] screen] visibleFrame]);
    
    [self setWindowFrameAutosaveNameOrCascade:SKSnapshotWindowFrameAutosaveName];
    [[self window] setFrame:NSIntegralRect(frame) display:NO animate:NO];
    
    [pdfView goToPage:page];
    
    NSPoint point;
    point.x = ([page rotation] == 0 || [page rotation] == 90) ? NSMinX(rect) : NSMaxX(rect);
    point.y = ([page rotation] == 90 || [page rotation] == 180) ? NSMinY(rect) : NSMaxY(rect);
    
    PDFDestination *dest = [[[PDFDestination alloc] initWithPage:page atPoint:point] autorelease];
    
    if (autoFits && [pdfView respondsToSelector:@selector(setAutoFits:)])
        [(BDSKZoomablePDFView *)pdfView setAutoFits:autoFits];
    
    // Delayed to allow PDFView to finish its bookkeeping 
    // fixes bug of apparently ignoring the point but getting the page right.
    [self performSelector:@selector(goToDestination:) withObject:dest afterDelay:0.1];
}

- (void)setPdfDocument:(PDFDocument *)pdfDocument setup:(NSDictionary *)setup {
    [self setPdfDocument:pdfDocument
             scaleFactor:[[setup objectForKey:SKSnapshotScaleFactorKey] floatValue]
          goToPageNumber:[[setup objectForKey:SKSnapshotPageKey] unsignedIntValue]
                    rect:NSRectFromString([setup objectForKey:SKSnapshotRectKey])
                autoFits:[[setup objectForKey:SKSnapshotAutoFitsKey] boolValue]];
    
    if ([setup objectForKey:SKSnapshotWindowFrameKey])
        [[self window] setFrame:NSRectFromString([setup objectForKey:SKSnapshotWindowFrameKey]) display:NO];
    if ([[setup objectForKey:SKSnapshotHasWindowKey] boolValue])
        [self performSelector:@selector(showWindow:) withObject:self afterDelay:0.0];
}

- (BOOL)isPageVisible:(PDFPage *)page {
    if ([[page document] isEqual:[pdfView document]] == NO)
        return NO;
    
    NSView *clipView = [[[pdfView documentView] enclosingScrollView] contentView];
    NSRect visibleRect = [clipView convertRect:[clipView visibleRect] toView:pdfView];
    unsigned first, last, idx = [page pageIndex];
    
    first = [[pdfView pageForPoint:SKTopLeftPoint(visibleRect) nearest:YES] pageIndex];
    last = [[pdfView pageForPoint:SKBottomRightPoint(visibleRect) nearest:YES] pageIndex];
    
    return idx >= first && idx <= last;
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

- (NSRect)bounds {
    NSView *clipView = [[[pdfView documentView] enclosingScrollView] contentView];
    return [pdfView convertRect:[pdfView convertRect:[clipView bounds] fromView:clipView] toPage:[pdfView currentPage]];
}

- (unsigned int)pageIndex {
    return [[pdfView currentPage] pageIndex];
}

- (NSString *)pageLabel {
    return pageLabel;
}

- (void)setPageLabel:(NSString *)newPageLabel {
    if (pageLabel != newPageLabel) {
        [pageLabel release];
        pageLabel = [newPageLabel retain];
    }
}

- (BOOL)hasWindow {
    return hasWindow;
}

- (void)setHasWindow:(BOOL)flag {
    hasWindow = flag;
}

- (NSDictionary *)pageAndWindow {
    return [NSDictionary dictionaryWithObjectsAndKeys:[self pageLabel], SKSnapshotPageCellLabelKey, [NSNumber numberWithBool:[self hasWindow]], SKSnapshotPageCellHasWindowKey, nil];
}

- (BOOL)forceOnTop {
    return forceOnTop;
}

- (void)setForceOnTop:(BOOL)flag {
    forceOnTop = flag;
    BOOL keepOnTop = [[NSUserDefaults standardUserDefaults] boolForKey:SKSnapshotsOnTopKey];
    [[self window] setLevel:keepOnTop || forceOnTop ? NSFloatingWindowLevel : NSNormalWindowLevel];
    [[self window] setHidesOnDeactivate:keepOnTop || forceOnTop];
}

- (NSDictionary *)currentSetup {
    NSView *clipView = [[[pdfView documentView] enclosingScrollView] contentView];
    NSRect rect = [pdfView convertRect:[pdfView convertRect:[clipView bounds] fromView:clipView] toPage:[pdfView currentPage]];
    BOOL autoFits = [pdfView respondsToSelector:@selector(autoFits)] && [(BDSKZoomablePDFView *)pdfView autoFits];
    return [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:[self pageIndex]], SKSnapshotPageKey, NSStringFromRect(rect), SKSnapshotRectKey, [NSNumber numberWithFloat:[pdfView scaleFactor]], SKSnapshotScaleFactorKey, [NSNumber numberWithBool:autoFits], SKSnapshotAutoFitsKey, [NSNumber numberWithBool:[[self window] isVisible]], SKSnapshotHasWindowKey, NSStringFromRect([[self window] frame]), SKSnapshotWindowFrameKey, nil];
}

#pragma mark Actions

- (IBAction)doZoomIn:(id)sender {
    [pdfView zoomIn:sender];
}

- (IBAction)doZoomOut:(id)sender {
    [pdfView zoomOut:sender];
}

- (IBAction)doZoomToPhysicalSize:(id)sender {
    float scaleFactor = 1.0;
    NSScreen *screen = [[self window] screen];
	CGDirectDisplayID displayID = (CGDirectDisplayID)[[[screen deviceDescription] objectForKey:@"NSScreenNumber"] unsignedIntValue];
	CGSize physicalSize = CGDisplayScreenSize(displayID);
    NSSize resolution = [[[screen deviceDescription] objectForKey:NSDeviceResolution] sizeValue];
	
    if (CGSizeEqualToSize(physicalSize, CGSizeZero) == NO)
        scaleFactor = CGDisplayPixelsWide(displayID) * 25.4f / (physicalSize.width * resolution.width);
    [pdfView setScaleFactor:scaleFactor];
}

- (IBAction)doZoomToActualSize:(id)sender {
    [pdfView setScaleFactor:1.0];
}

- (IBAction)toggleAutoScale:(id)sender {
    [pdfView setAutoFits:[pdfView autoFits] == NO];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    SEL action = [menuItem action];
    if (action == @selector(doZoomIn:)) {
        return [pdfView canZoomIn];
    } else if (action == @selector(doZoomOut:)) {
        return [pdfView canZoomOut];
    } else if (action == @selector(doZoomToActualSize:)) {
        return fabsf([pdfView scaleFactor] - 1.0 ) > 0.01;
    } else if (action == @selector(doZoomToPhysicalSize:)) {
        return YES;
    } else if (action == @selector(toggleAutoScale:)) {
        [menuItem setState:[pdfView autoFits] ? NSOnState : NSOffState];
        return YES;
    }
    return YES;
}

#pragma mark Thumbnails

- (NSImage *)thumbnailWithSize:(float)size {
    float shadowBlurRadius = roundf(size / 32.0);
    float shadowOffset = - ceilf(shadowBlurRadius * 0.75);
    return  [self thumbnailWithSize:size shadowBlurRadius:shadowBlurRadius shadowOffset:NSMakeSize(0.0, shadowOffset)];
}

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
        NSShadow *aShadow = [[NSShadow alloc] init];
        [aShadow setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.5]];
        [aShadow setShadowBlurRadius:shadowBlurRadius];
        [aShadow setShadowOffset:shadowOffset];
        [aShadow set];
        [aShadow release];
    }
    bounds.origin = NSZeroPoint;
    NSRectFill(bounds);
    [NSGraphicsContext restoreGraphicsState];
    [imageRep drawInRect:bounds];
    [image unlockFocus];
    
    return [image autorelease];
}

- (NSAttributedString *)thumbnailAttachmentWithSize:(float)size {
    NSImage *image = [self thumbnailWithSize:size];
    
    NSFileWrapper *wrapper = [[NSFileWrapper alloc] initRegularFileWithContents:[image TIFFRepresentation]];
    [wrapper setFilename:@"page.tiff"];
    [wrapper setPreferredFilename:@"page.tiff"];

    NSTextAttachment *attachment = [[NSTextAttachment alloc] initWithFileWrapper:wrapper];
    [wrapper release];
    NSAttributedString *attrString = [NSAttributedString attributedStringWithAttachment:attachment];
    [attachment release];
    
    return attrString;
}

- (NSAttributedString *)thumbnailAttachment {
    return [self thumbnailAttachmentWithSize:0.0];
}

- (NSAttributedString *)thumbnail512Attachment {
    return [self thumbnailAttachmentWithSize:512.0];
}

- (NSAttributedString *)thumbnail256Attachment {
    return [self thumbnailAttachmentWithSize:256.0];
}

- (NSAttributedString *)thumbnail128Attachment {
    return [self thumbnailAttachmentWithSize:128.0];
}

- (NSAttributedString *)thumbnail64Attachment {
    return [self thumbnailAttachmentWithSize:64.0];
}

- (NSAttributedString *)thumbnail32Attachment {
    return [self thumbnailAttachmentWithSize:32.0];
}

#pragma mark Miniaturize / Deminiaturize

- (void)getMiniRect:(NSRect *)miniRect maxiRect:(NSRect *)maxiRect forDockingRect:(NSRect)dockRect {
    NSView *clipView = [[[pdfView documentView] enclosingScrollView] contentView];
    NSRect clipRect = [pdfView convertRect:[clipView bounds] fromView:clipView];
    float thumbRatio = NSHeight(clipRect) / NSWidth(clipRect);
    float dockRatio = NSHeight(dockRect) / NSWidth(dockRect);
    
    clipRect = [pdfView convertRect:clipRect toView:nil];
    clipRect.origin = [[self window] convertBaseToScreen:clipRect.origin];
    *maxiRect = clipRect;
    
    if (thumbRatio > dockRatio)
        *miniRect = NSInsetRect(dockRect, 0.5 * NSWidth(dockRect) * (1.0 - dockRatio / thumbRatio), 0.0);
    else
        *miniRect = NSInsetRect(dockRect, 0.0, 0.5 * NSHeight(dockRect) * (1.0 - thumbRatio / dockRatio));
}

- (void)miniaturize {
    miniaturizing = YES;
    if ([[self delegate] respondsToSelector:@selector(snapshotControllerTargetRectForMiniaturize:)]) {
        NSRect startRect, endRect, dockRect = [[self delegate] snapshotControllerTargetRectForMiniaturize:self];
        
        [self getMiniRect:&endRect maxiRect:&startRect forDockingRect:dockRect];
        
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
    [self setHasWindow:NO];
}

- (void)deminiaturize {
    if ([[self delegate] respondsToSelector:@selector(snapshotControllerSourceRectForDeminiaturize:)]) {
        NSRect startRect, endRect, dockRect = [[self delegate] snapshotControllerSourceRectForDeminiaturize:self];
        
        [self getMiniRect:&startRect maxiRect:&endRect forDockingRect:dockRect];
        
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
    [self setHasWindow:YES];
}

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == SKSnaphotWindowDefaultsObservationContext) {
        NSString *key = [keyPath substringFromIndex:7];
        if ([key isEqualToString:SKSnapshotsOnTopKey]) {
            BOOL keepOnTop = [[NSUserDefaults standardUserDefaults] boolForKey:SKSnapshotsOnTopKey];
            [[self window] setLevel:keepOnTop || forceOnTop ? NSFloatingWindowLevel : NSNormalWindowLevel];
            [[self window] setHidesOnDeactivate:keepOnTop || forceOnTop];
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

- (void)awakeFromNib {
	// Overrides the parent attribute of the placard so that it belongs to the window.
	NSView *popup = [pdfView scalePopUpButton];
	[NSAccessibilityUnignoredDescendant(popup) accessibilitySetOverrideValue:NSAccessibilityUnignoredAncestor(self) forAttribute:NSAccessibilityParentAttribute];
	[NSAccessibilityUnignoredDescendant(popup) accessibilitySetOverrideValue:NSLocalizedString(@"Zoom", @"Zoom pop-up menu description") forAttribute:NSAccessibilityDescriptionAttribute];
}

- (id)accessibilityAttributeValue:(NSString *)attribute {
	// Overrides the children attribute to add the placard to the children of the window.
	if([attribute isEqualToString:NSAccessibilityChildrenAttribute])
		return [[super accessibilityAttributeValue:attribute] arrayByAddingObject:NSAccessibilityUnignoredDescendant([pdfView scalePopUpButton])];
	else
		return [super accessibilityAttributeValue:attribute];
}

@end
