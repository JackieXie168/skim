//
//  SKSnapshotWindowController.m
//  Skim
//
//  Created by Michael McCracken on 12/6/06.
/*
 This software is Copyright (c) 2006-2012
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
#import "SKMainDocument.h"
#import "SKBorderlessImageWindow.h"
#import <Quartz/Quartz.h>
#import "SKSnapshotPDFView.h"
#import <SkimNotes/SkimNotes.h>
#import "SKPDFView.h"
#import "NSWindowController_SKExtensions.h"
#import "SKStringConstants.h"
#import "NSUserDefaultsController_SKExtensions.h"
#import "NSGeometry_SKExtensions.h"
#import "PDFPage_SKExtensions.h"
#import "SKSnapshotPageCell.h"
#import "PDFAnnotation_SKExtensions.h"
#import "PDFView_SKExtensions.h"
#import "NSUserDefaults_SKExtensions.h"

#define EM_DASH_CHARACTER (unichar)0x2014

NSString *SKSnapshotCurrentSetupKey = @"currentSetup";

#define PAGE_KEY            @"page"
#define RECT_KEY            @"rect"
#define SCALEFACTOR_KEY     @"scaleFactor"
#define AUTOFITS_KEY        @"autoFits"
#define WINDOWFRAME_KEY     @"windowFrame"
#define HASWINDOW_KEY       @"hasWindow"
#define PAGELABEL_KEY       @"pageLabel"
#define PAGEANDWINDOW_KEY   @"pageAndWindow"

#define SKSnapshotWindowFrameAutosaveName @"SKSnapshotWindow"
#define SKSnapshotViewChangedNotification @"SKSnapshotViewChangedNotification"

static char SKSnaphotWindowDefaultsObservationContext;

@interface SKSnapshotWindowController () 
@property (nonatomic, copy) NSString *pageLabel;
@property (nonatomic) BOOL hasWindow;
@end

@implementation SKSnapshotWindowController

@synthesize pdfView, delegate, thumbnail, pageLabel, hasWindow, forceOnTop;
@dynamic pageIndex, pageAndWindow, currentSetup, thumbnailAttachment, thumbnail512Attachment, thumbnail256Attachment, thumbnail128Attachment, thumbnail64Attachment, thumbnail32Attachment;

+ (NSSet *)keyPathsForValuesAffectingPageAndWindow {
    return [NSSet setWithObjects:PAGELABEL_KEY, HASWINDOW_KEY, nil];
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver: self];
    [pdfView setDelegate:nil];
    delegate = nil;
    SKDESTROY(thumbnail);
    SKDESTROY(pageLabel);
    SKDESTROY(pdfView);
    [super dealloc];
}

- (NSString *)windowNibName {
    return @"SnapshotWindow";
}

- (void)windowDidLoad {
    BOOL keepOnTop = [[NSUserDefaults standardUserDefaults] boolForKey:SKSnapshotsOnTopKey];
    [[self window] setLevel:keepOnTop || forceOnTop ? NSFloatingWindowLevel : NSNormalWindowLevel];
    [[self window] setHidesOnDeactivate:keepOnTop || forceOnTop];
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeys:[NSArray arrayWithObjects:SKSnapshotsOnTopKey, SKShouldAntiAliasKey, SKGreekingThresholdKey, SKBackgroundColorKey, SKPageBackgroundColorKey, nil] context:&SKSnaphotWindowDefaultsObservationContext];
    // the window is initialially exposed. The windowDidExpose notification is useless, it has nothing to do with showing the window
    [self setHasWindow:YES];
}

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName {
    return [NSString stringWithFormat:@"%@ %C %@", displayName, EM_DASH_CHARACTER, [NSString stringWithFormat:NSLocalizedString(@"Page %@", @""), [self pageLabel]]];
}

- (void)setNeedsDisplayInRect:(NSRect)rect ofPage:(PDFPage *)page {
    NSRect aRect = [pdfView convertRect:rect fromPage:page];
    CGFloat scale = [pdfView scaleFactor];
	CGFloat maxX = ceil(NSMaxX(aRect) + scale);
	CGFloat maxY = ceil(NSMaxY(aRect) + scale);
	CGFloat minX = floor(NSMinX(aRect) - scale);
	CGFloat minY = floor(NSMinY(aRect) - scale);
	
    aRect = NSIntersectionRect([pdfView bounds], NSMakeRect(minX, minY, maxX - minX, maxY - minY));
    if (NSIsEmptyRect(aRect) == NO)
        [pdfView setNeedsDisplayInRect:aRect];
}

- (void)setNeedsDisplayForAnnotation:(PDFAnnotation *)annotation onPage:(PDFPage *)page {
    [self setNeedsDisplayInRect:[annotation displayRect] ofPage:page];
}

- (void)redisplay {
    [pdfView setNeedsDisplay:YES];
}

- (void)handlePageChangedNotification:(NSNotification *)notification {
    [self setPageLabel:[[pdfView currentPage] displayLabel]];
}

- (void)handleDocumentDidUnlockNotification:(NSNotification *)notification {
    [self setPageLabel:[[pdfView currentPage] displayLabel]];
}

- (void)handlePDFViewFrameChangedNotification:(NSNotification *)notification {
    if ([[self delegate] respondsToSelector:@selector(snapshotControllerDidChange:)]) {
        NSNotification *note = [NSNotification notificationWithName:SKSnapshotViewChangedNotification object:self];
        [[NSNotificationQueue defaultQueue] enqueueNotification:note postingStyle:NSPostWhenIdle coalesceMask:NSNotificationCoalescingOnName forModes:nil];
    }
}

- (void)handleViewChangedNotification:(NSNotification *)notification {
    if ([[self delegate] respondsToSelector:@selector(snapshotControllerDidChange:)])
        [[self delegate] snapshotControllerDidChange:self];
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
    @try { [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeys:[NSArray arrayWithObjects:SKSnapshotsOnTopKey, SKShouldAntiAliasKey, SKGreekingThresholdKey, SKBackgroundColorKey, SKPageBackgroundColorKey, nil]]; }
    @catch (id e) {}
    if ([[self delegate] respondsToSelector:@selector(snapshotControllerWillClose:)])
        [[self delegate] snapshotControllerWillClose:self];
    [self setDelegate:nil];
    // this is necessary to break a retain loop between the popup and its parent
	[NSAccessibilityUnignoredDescendant([pdfView scalePopUpButton]) accessibilitySetOverrideValue:nil forAttribute:NSAccessibilityParentAttribute];
    if ([[self window] isKeyWindow])
        [[[[self document] mainWindowController] window] makeKeyWindow];
    else if ([[self window] isMainWindow])
        [[[[self document] mainWindowController] window] makeMainWindow];
}

- (void)notifiyDidFinishSetup {
    [[self delegate] snapshotControllerDidFinishSetup:self];
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
        [self performSelector:@selector(notifiyDidFinishSetup) withObject:nil afterDelay:0.1];
    
    if ([self hasWindow])
        [self showWindow:nil];
}

- (void)setPdfDocument:(PDFDocument *)pdfDocument goToPageNumber:(NSInteger)pageNum rect:(NSRect)rect scaleFactor:(CGFloat)factor autoFits:(BOOL)autoFits {
    [self window];
    
    [pdfView setScaleFactor:factor];
    [pdfView setAutoScales:NO];
    [pdfView setDisplaysPageBreaks:NO];
    [pdfView setDisplayBox:kPDFDisplayBoxCropBox];
    [pdfView setShouldAntiAlias:[[NSUserDefaults standardUserDefaults] floatForKey:SKShouldAntiAliasKey]];
    [pdfView setGreekingThreshold:[[NSUserDefaults standardUserDefaults] floatForKey:SKGreekingThresholdKey]];
    [pdfView setBackgroundColor:[[NSUserDefaults standardUserDefaults] colorForKey:SKBackgroundColorKey]];
    [pdfView setDocument:pdfDocument];
    
    PDFPage *page = [pdfDocument pageAtIndex:pageNum];
    NSRect frame = [pdfView convertRect:rect fromPage:page];
    frame = [pdfView convertRect:frame toView:nil];
    
    [self setWindowFrameAutosaveNameOrCascade:SKSnapshotWindowFrameAutosaveName];
    
    frame.size.width += [NSScroller scrollerWidth];
    frame.size.height += [NSScroller scrollerWidth];
    frame = [[self window] frameRectForContentRect:frame];
    frame.origin.x = NSMinX([[self window] frame]);
    frame.origin.y = NSMaxY([[self window] frame]) - NSHeight(frame);
    [[self window] setFrame:NSIntegralRect(frame) display:NO animate:NO];
    
    [pdfView goToPage:page];
    
    NSPoint point;
    point.x = ([page rotation] == 0 || [page rotation] == 90) ? NSMinX(rect) : NSMaxX(rect);
    point.y = ([page rotation] == 90 || [page rotation] == 180) ? NSMinY(rect) : NSMaxY(rect);
    
    PDFDestination *dest = [[[PDFDestination alloc] initWithPage:page atPoint:point] autorelease];
    
    if (autoFits && [pdfView respondsToSelector:@selector(setAutoFits:)])
        [(SKSnapshotPDFView *)pdfView setAutoFits:autoFits];
    
    // Delayed to allow PDFView to finish its bookkeeping 
    // fixes bug of apparently ignoring the point but getting the page right.
    [self performSelector:@selector(goToDestination:) withObject:dest afterDelay:0.1];
}

- (void)setPdfDocument:(PDFDocument *)pdfDocument setup:(NSDictionary *)setup {
    [self setPdfDocument:pdfDocument
          goToPageNumber:[[setup objectForKey:PAGE_KEY] unsignedIntegerValue]
                    rect:NSRectFromString([setup objectForKey:RECT_KEY])
             scaleFactor:[[setup objectForKey:SCALEFACTOR_KEY] doubleValue]
                autoFits:[[setup objectForKey:AUTOFITS_KEY] boolValue]];
    
    [self setHasWindow:[[setup objectForKey:HASWINDOW_KEY] boolValue]];
    if ([setup objectForKey:WINDOWFRAME_KEY])
        [[self window] setFrame:NSRectFromString([setup objectForKey:WINDOWFRAME_KEY]) display:NO];
}

- (BOOL)isPageVisible:(PDFPage *)page {
    return [[page document] isEqual:[pdfView document]] && [[pdfView visiblePages] containsObject:page];
}

#pragma mark Acessors

- (NSRect)bounds {
    NSView *clipView = [[[pdfView documentView] enclosingScrollView] contentView];
    return [pdfView convertRect:[pdfView convertRect:[clipView bounds] fromView:clipView] toPage:[pdfView currentPage]];
}

- (NSUInteger)pageIndex {
    return [[pdfView currentPage] pageIndex];
}

- (void)setPageLabel:(NSString *)newPageLabel {
    if (pageLabel != newPageLabel) {
        [pageLabel release];
        pageLabel = [newPageLabel retain];
        [self synchronizeWindowTitleWithDocumentName];
    }
}

- (NSDictionary *)pageAndWindow {
    return [NSDictionary dictionaryWithObjectsAndKeys:[self pageLabel], SKSnapshotPageCellLabelKey, [NSNumber numberWithBool:[self hasWindow]], SKSnapshotPageCellHasWindowKey, nil];
}

- (void)setForceOnTop:(BOOL)flag {
    forceOnTop = flag;
    BOOL onTop = forceOnTop || [[NSUserDefaults standardUserDefaults] boolForKey:SKSnapshotsOnTopKey];
    [[self window] setLevel:onTop ? NSFloatingWindowLevel : NSNormalWindowLevel];
    [[self window] setHidesOnDeactivate:onTop];
}

- (NSDictionary *)currentSetup {
    NSView *clipView = [[[pdfView documentView] enclosingScrollView] contentView];
    NSRect rect = [pdfView convertRect:[pdfView convertRect:[clipView bounds] fromView:clipView] toPage:[pdfView currentPage]];
    BOOL autoFits = [pdfView respondsToSelector:@selector(autoFits)] && [(SKSnapshotPDFView *)pdfView autoFits];
    return [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInteger:[self pageIndex]], PAGE_KEY, NSStringFromRect(rect), RECT_KEY, [NSNumber numberWithDouble:[pdfView scaleFactor]], SCALEFACTOR_KEY, [NSNumber numberWithBool:autoFits], AUTOFITS_KEY, [NSNumber numberWithBool:[[self window] isVisible]], HASWINDOW_KEY, NSStringFromRect([[self window] frame]), WINDOWFRAME_KEY, nil];
}

#pragma mark Actions

- (IBAction)doZoomIn:(id)sender {
    [pdfView zoomIn:sender];
}

- (IBAction)doZoomOut:(id)sender {
    [pdfView zoomOut:sender];
}

- (IBAction)doZoomToPhysicalSize:(id)sender {
    [pdfView setPhysicalScaleFactor:1.0];
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
        return fabs([pdfView scaleFactor] - 1.0 ) > 0.01;
    } else if (action == @selector(doZoomToPhysicalSize:)) {
        return fabs([pdfView physicalScaleFactor] - 1.0 ) > 0.01;
    } else if (action == @selector(toggleAutoScale:)) {
        [menuItem setState:[pdfView autoFits] ? NSOnState : NSOffState];
        return YES;
    }
    return YES;
}

#pragma mark Thumbnails

- (NSImage *)thumbnailWithSize:(CGFloat)size {
    CGFloat shadowBlurRadius = round(size / 32.0);
    CGFloat shadowOffset = - ceil(shadowBlurRadius * 0.75);
    return  [self thumbnailWithSize:size shadowBlurRadius:shadowBlurRadius shadowOffset:NSMakeSize(0.0, shadowOffset)];
}

- (NSImage *)thumbnailWithSize:(CGFloat)size shadowBlurRadius:(CGFloat)shadowBlurRadius shadowOffset:(NSSize)shadowOffset {
    NSView *clipView = [[[pdfView documentView] enclosingScrollView] contentView];
    NSRect bounds = [pdfView convertRect:[clipView bounds] fromView:clipView];
    NSBitmapImageRep *imageRep = [pdfView bitmapImageRepForCachingDisplayInRect:bounds];
    BOOL isScaled = size > 0.0;
    BOOL hasShadow = shadowBlurRadius > 0.0;
    CGFloat scaleX, scaleY;
    NSSize thumbnailSize;
    NSImage *image;
    
    [pdfView cacheDisplayInRect:bounds toBitmapImageRep:imageRep];
    
    
    if (isScaled) {
        if (NSHeight(bounds) > NSWidth(bounds))
            thumbnailSize = NSMakeSize(round((size - 2.0 * shadowBlurRadius) * NSWidth(bounds) / NSHeight(bounds) + 2.0 * shadowBlurRadius), size);
        else
            thumbnailSize = NSMakeSize(size, round((size - 2.0 * shadowBlurRadius) * NSHeight(bounds) / NSWidth(bounds) + 2.0 * shadowBlurRadius));
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
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationDefault];
    [NSGraphicsContext restoreGraphicsState];
    [imageRep drawInRect:bounds];
    [image unlockFocus];
    
    return [image autorelease];
}

- (NSAttributedString *)thumbnailAttachmentWithSize:(CGFloat)size {
    NSImage *image = [self thumbnailWithSize:size];
    
    NSFileWrapper *wrapper = [[NSFileWrapper alloc] initRegularFileWithContents:[image TIFFRepresentation]];
    NSString *filename = [NSString stringWithFormat:@"snapshot_page_%lu.tiff",(unsigned long)( [self pageIndex] + 1)];
    [wrapper setFilename:filename];
    [wrapper setPreferredFilename:filename];

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

- (void)getMiniRect:(NSRectPointer)miniRect maxiRect:(NSRectPointer)maxiRect forDockingRect:(NSRect)dockRect {
    NSView *clipView = [[[pdfView documentView] enclosingScrollView] contentView];
    NSRect clipRect = [pdfView convertRect:[clipView bounds] fromView:clipView];
    CGFloat thumbRatio = NSHeight(clipRect) / NSWidth(clipRect);
    CGFloat dockRatio = NSHeight(dockRect) / NSWidth(dockRect);
    
    clipRect = [pdfView convertRect:clipRect toView:nil];
    clipRect.origin = [[self window] convertBaseToScreen:clipRect.origin];
    *maxiRect = clipRect;
    
    if (thumbRatio > dockRatio)
        *miniRect = NSInsetRect(dockRect, 0.5 * NSWidth(dockRect) * (1.0 - dockRatio / thumbRatio), 0.0);
    else
        *miniRect = NSInsetRect(dockRect, 0.0, 0.5 * NSHeight(dockRect) * (1.0 - thumbRatio / dockRatio));
}

- (void)miniaturize {
    if ([[self delegate] respondsToSelector:@selector(snapshotController:miniaturizedRect:)]) {
        NSRect startRect, endRect, dockRect = [[self delegate] snapshotController:self miniaturizedRect:YES];
        
        [self getMiniRect:&endRect maxiRect:&startRect forDockingRect:dockRect];
        
        NSImage *image = [self thumbnailWithSize:0.0 shadowBlurRadius:0.0 shadowOffset:NSZeroSize];
        SKBorderlessImageWindow *miniaturizeWindow = [[SKBorderlessImageWindow alloc] initWithContentRect:startRect image:image];
        
        [miniaturizeWindow orderFront:self];
        [[self window] orderOut:self];
        [miniaturizeWindow setFrame:endRect display:YES animate:YES];
        [miniaturizeWindow orderOut:self];
        [miniaturizeWindow release];
    } else {
        [[self window] orderOut:self];
    }
    [self setHasWindow:NO];
}

- (void)deminiaturize {
    if ([[self delegate] respondsToSelector:@selector(snapshotController:miniaturizedRect:)]) {
        NSRect startRect, endRect, dockRect = [[self delegate] snapshotController:self miniaturizedRect:NO];
        
        [self getMiniRect:&startRect maxiRect:&endRect forDockingRect:dockRect];
        
        NSImage *image = [self thumbnailWithSize:0.0 shadowBlurRadius:0.0 shadowOffset:NSZeroSize];
        SKBorderlessImageWindow *miniaturizeWindow = [[SKBorderlessImageWindow alloc] initWithContentRect:startRect image:image];
        
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
    if (context == &SKSnaphotWindowDefaultsObservationContext) {
        NSString *key = [keyPath substringFromIndex:7];
        if ([key isEqualToString:SKSnapshotsOnTopKey]) {
            BOOL keepOnTop = [[NSUserDefaults standardUserDefaults] boolForKey:SKSnapshotsOnTopKey];
            [[self window] setLevel:keepOnTop || forceOnTop ? NSFloatingWindowLevel : NSNormalWindowLevel];
            [[self window] setHidesOnDeactivate:keepOnTop || forceOnTop];
        } else if ([key isEqualToString:SKShouldAntiAliasKey]) {
            [pdfView setShouldAntiAlias:[[NSUserDefaults standardUserDefaults] boolForKey:SKShouldAntiAliasKey]];
        } else if ([key isEqualToString:SKGreekingThresholdKey]) {
            [pdfView setGreekingThreshold:[[NSUserDefaults standardUserDefaults] floatForKey:SKGreekingThresholdKey]];
        } else if ([key isEqualToString:SKBackgroundColorKey]) {
            [pdfView setBackgroundColor:[[NSUserDefaults standardUserDefaults] colorForKey:SKBackgroundColorKey]];
        } else if ([key isEqualToString:SKPageBackgroundColorKey]) {
            [pdfView setNeedsDisplay:YES];
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

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)styleMask backing:(NSBackingStoreType)bufferingType defer:(BOOL)deferCreation {
    self = [super initWithContentRect:contentRect styleMask:styleMask backing:bufferingType defer:deferCreation];
    if (self) {
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
