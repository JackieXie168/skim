//
//  SKSnapshotWindowController.m
//  Skim
//
//  Created by Michael McCracken on 12/6/06.
/*
 This software is Copyright (c) 2006-2020
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
#import <Quartz/Quartz.h>
#import "SKSnapshotPDFView.h"
#import <SkimNotes/SkimNotes.h>
#import "SKPDFView.h"
#import "SKSnapshotWindow.h"
#import "NSWindowController_SKExtensions.h"
#import "SKStringConstants.h"
#import "NSUserDefaultsController_SKExtensions.h"
#import "NSGeometry_SKExtensions.h"
#import "PDFPage_SKExtensions.h"
#import "SKSnapshotPageCell.h"
#import "PDFAnnotation_SKExtensions.h"
#import "PDFView_SKExtensions.h"
#import "NSUserDefaults_SKExtensions.h"
#import "PDFSelection_SKExtensions.h"
#import "NSImage_SKExtensions.h"
#import "NSShadow_SKExtensions.h"
#import "SKAnimatedBorderlessWindow.h"
#import "NSColor_SKExtensions.h"
#import "NSPasteboard_SKExtensions.h"
#import "NSURL_SKExtensions.h"
#import "NSWindow_SKExtensions.h"
#import "NSView_SKExtensions.h"
#import "NSScreen_SKExtensions.h"
#import "SKApplication.h"

#define EM_DASH_CHARACTER (unichar)0x2014

#define SMALL_DELAY 0.1
#define RESIZE_TIME_FACTOR 1.0

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

#if SDK_BEFORE(10_10)
@interface NSLayoutConstraint (SKYosemiteDeclarations)
@property (getter=isActive) BOOL active;
@end
#endif

@interface SKSnapshotWindowController ()
@property (nonatomic, copy) NSString *pageLabel;
@property (nonatomic) BOOL hasWindow;
@end

@implementation SKSnapshotWindowController

@synthesize pdfView, delegate, thumbnail, pageLabel, string, hasWindow, forceOnTop;
@dynamic pageIndex, pageAndWindow, currentSetup, thumbnailAttachment, thumbnail512Attachment, thumbnail256Attachment, thumbnail128Attachment, thumbnail64Attachment, thumbnail32Attachment;

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
    if ([key isEqualToString:PAGEANDWINDOW_KEY])
        keyPaths = [keyPaths setByAddingObjectsFromSet:[NSSet setWithObjects:PAGELABEL_KEY, HASWINDOW_KEY, nil]];
    return keyPaths;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    delegate = nil;
    SKDESTROY(thumbnail);
    SKDESTROY(pageLabel);
    SKDESTROY(pdfView);
    SKDESTROY(windowImage);
    SKDESTROY(string);
    [super dealloc];
}

- (NSString *)windowNibName {
    return @"SnapshotWindow";
}

- (void)updateWindowLevel {
    BOOL onTop = forceOnTop || [[NSUserDefaults standardUserDefaults] boolForKey:SKSnapshotsOnTopKey];
    [[self window] setLevel:onTop ? NSFloatingWindowLevel : NSNormalWindowLevel];
    [[self window] setHidesOnDeactivate:onTop];
}

- (void)windowDidLoad {
    if ([NSWindow instancesRespondToSelector:@selector(setTabbingMode:)])
        [[self window] setTabbingMode:NSWindowTabbingModeDisallowed];
    [[self window] setCollectionBehavior:[[self window] collectionBehavior] | NSWindowCollectionBehaviorFullScreenAuxiliary];
    if (RUNNING_AFTER(10_9)) {
        // we need to set NSFullSizeContentViewWindowMask, otherwise the pdfview becomes sluggish on some OS versions
        NSView *contentView = [[self window] contentView];
        for (NSLayoutConstraint *constraint in [contentView constraints]) {
            if ([constraint firstItem] == pdfView && [constraint firstAttribute] == NSLayoutAttributeTop) {
                [[self window] setStyleMask:[[self window] styleMask] | NSFullSizeContentViewWindowMask];
                [contentView removeConstraint:constraint];
                constraint = [NSLayoutConstraint constraintWithItem:pdfView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:[[self window] contentLayoutGuide] attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0];
                // contentLayoutGuide may not be a view, so we can't use addConstraint:,
                // but we are on 10.10+ so that's not a problem
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"
                [constraint setActive:YES];
#pragma clang diagnostic pop
                break;
            }
        }
    }
    [self updateWindowLevel];
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeys:[NSArray arrayWithObjects:SKSnapshotsOnTopKey, SKShouldAntiAliasKey, SKGreekingThresholdKey, SKBackgroundColorKey, SKDarkBackgroundColorKey, SKPageBackgroundColorKey, nil] context:&SKSnaphotWindowDefaultsObservationContext];
    // the window is initialially exposed. The windowDidExpose notification is useless, it has nothing to do with showing the window
    [self setHasWindow:YES];
}

// these should never be reached, but just to be sure

- (void)windowDidMiniaturize:(NSNotification *)notification {
    [[self window] orderOut:nil];
    [self setHasWindow:NO];
}

- (void)windowDidDeminiaturize:(NSNotification *)notification {
    [self updateWindowLevel];
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
    [pdfView requiresDisplay];
}

- (void)updateString {
    NSMutableString *mutableString = [NSMutableString string];
    NSView *clipView = [[pdfView scrollView] contentView];
    NSRect rect = [clipView convertRect:[clipView visibleRect] toView:pdfView];
    
    for (PDFPage *page in [pdfView displayedPages]) {
        PDFSelection *sel = [page selectionForRect:[pdfView convertRect:rect toPage:page]];
        if ([sel hasCharacters]) {
            if ([mutableString length] > 0)
                [mutableString appendString:@"\n"];
            [mutableString appendString:[sel string]];
        }
    }
    [self setString:mutableString];
}

- (void)handlePageChangedNotification:(NSNotification *)notification {
    [self setPageLabel:[[pdfView currentPage] displayLabel]];
    [self handlePDFViewFrameChangedNotification:nil];
}

- (void)handleDocumentDidUnlockNotification:(NSNotification *)notification {
    [self setPageLabel:[[pdfView currentPage] displayLabel]];
    [self handlePDFViewFrameChangedNotification:nil];
}

- (void)handlePDFViewFrameChangedNotification:(NSNotification *)notification {
    if ([[self delegate] respondsToSelector:@selector(snapshotControllerDidChange:)]) {
        NSNotification *note = [NSNotification notificationWithName:SKSnapshotViewChangedNotification object:self];
        [[NSNotificationQueue defaultQueue] enqueueNotification:note postingStyle:NSPostWhenIdle coalesceMask:NSNotificationCoalescingOnName forModes:nil];
    }
}

- (void)handleViewChangedNotification:(NSNotification *)notification {
    [self updateString];
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

- (void)handleDarkModeChangedNotification:(NSNotification *)notification {
    [pdfView setBackgroundColor:[PDFView defaultBackgroundColor]];
}

- (void)windowWillClose:(NSNotification *)notification {
    @try { [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeys:[NSArray arrayWithObjects:SKSnapshotsOnTopKey, SKShouldAntiAliasKey, SKGreekingThresholdKey, SKBackgroundColorKey, SKDarkBackgroundColorKey, SKPageBackgroundColorKey, nil]]; }
    @catch (id e) {}
    if ([[self delegate] respondsToSelector:@selector(snapshotControllerWillClose:)])
        [[self delegate] snapshotControllerWillClose:self];
    [self setDelegate:nil];
    // Yosemite and El Capitan have a retain cycle when we leave the PDFView with a document
    if (RUNNING_AFTER(10_9) && RUNNING_BEFORE(10_12))
        [pdfView setDocument:nil];
}

- (void)windowDidMove:(NSNotification *)notification {
    if ([[self delegate] respondsToSelector:@selector(snapshotControllerDidMove:)])
        [[self delegate] snapshotControllerDidMove:self];
}

- (void)goToRect:(NSRect)rect openType:(SKSnapshotOpenType)openType {
    [pdfView goToRect:rect onPage:[pdfView currentPage]];
    [pdfView resetHistory];
    
    [self updateString];
    
    [[self window] makeFirstResponder:pdfView];
	
    [self handlePageChangedNotification:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePageChangedNotification:) 
                                                 name:PDFViewPageChangedNotification object:pdfView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDocumentDidUnlockNotification:) 
                                                 name:PDFDocumentDidUnlockNotification object:[pdfView document]];
    
    NSView *clipView = [[pdfView scrollView] contentView];
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDarkModeChangedNotification:)
                                                 name:SKDarkModeChangedNotification object:nil];
    if ([[self delegate] respondsToSelector:@selector(snapshotController:didFinishSetup:)])
        DISPATCH_MAIN_AFTER_SEC(SMALL_DELAY, ^{
            [[self delegate] snapshotController:self didFinishSetup:openType];
        });
    
    if (openType == SKSnapshotOpenPreview)
        [[self window] orderFront:nil];
    else if ([self hasWindow])
        [self showWindow:nil];
}

- (void)setPdfDocument:(PDFDocument *)pdfDocument goToPageNumber:(NSInteger)pageNum rect:(NSRect)rect scaleFactor:(CGFloat)factor autoFits:(BOOL)autoFits screen:(NSScreen *)screen openType:(SKSnapshotOpenType)openType {
    NSWindow *window = [self window];
    
    [pdfView setScaleFactor:factor];
    [pdfView setAutoScales:NO];
    [pdfView setDisplaysPageBreaks:NO];
    [pdfView setDisplayBox:kPDFDisplayBoxCropBox];
    [pdfView setShouldAntiAlias:[[NSUserDefaults standardUserDefaults] floatForKey:SKShouldAntiAliasKey]];
    [pdfView setGreekingThreshold:[[NSUserDefaults standardUserDefaults] floatForKey:SKGreekingThresholdKey]];
    [pdfView setBackgroundColor:[PDFView defaultBackgroundColor]];
    [pdfView applyDefaultPageBackgroundColor];
    [pdfView applyDefaultInterpolationQuality];
    [pdfView setDocument:pdfDocument];
    
    PDFPage *page = [pdfDocument pageAtIndex:pageNum];
    NSRect frame = [pdfView convertRect:rect fromPage:page];
    frame = [pdfView convertRect:frame toView:nil];
    frame = [NSWindow frameRectForContentRect:frame styleMask:[window styleMask] & ~NSFullSizeContentViewWindowMask];
    
    if (openType == SKSnapshotOpenNormal) {
        [self setWindowFrameAutosaveNameOrCascade:SKSnapshotWindowFrameAutosaveName];
        frame.origin = SKTopLeftPoint([window frame]);
        frame.origin.y -= NSHeight(frame);
    } else if (openType == SKSnapshotOpenFromSetup) {
        frame.origin = SKTopLeftPoint([window frame]);
        frame.origin.y -= NSHeight(frame);
        [self setWindowFrameAutosaveName:SKSnapshotWindowFrameAutosaveName];
    } else if (openType == SKSnapshotOpenPreview) {
        [pdfView setDisplayMode:kPDFDisplaySinglePage];
        frame = SKRectFromCenterAndSize(SKCenterPoint([screen frame]), frame.size);
        [(SKSnapshotWindow *)[self window] setWindowControllerMiniaturizesWindow:NO];
    }
    
    [[self window] setFrame:NSIntegralRect(frame) display:NO animate:NO];
    [pdfView goToPage:page];
    
    if (autoFits) {
        [pdfView setAutoFits:autoFits];
        if (openType == SKSnapshotOpenPreview)
            [pdfView setShouldAutoFit:NO];
    }
    
    // Delayed to allow PDFView to finish its bookkeeping 
    // fixes bug of apparently ignoring the point but getting the page right.
    DISPATCH_MAIN_AFTER_SEC(SMALL_DELAY, ^{
        [self goToRect:rect openType:openType];
    });
}

- (void)setPdfDocument:(PDFDocument *)pdfDocument goToPageNumber:(NSInteger)pageNum rect:(NSRect)rect scaleFactor:(CGFloat)factor autoFits:(BOOL)autoFits {
    [self setPdfDocument:pdfDocument
          goToPageNumber:pageNum
                    rect:rect
             scaleFactor:factor
                autoFits:autoFits
                  screen:nil
                openType:SKSnapshotOpenNormal];
}

- (void)setPdfDocument:(PDFDocument *)pdfDocument previewPageNumber:(NSInteger)pageNum displayOnScreen:(NSScreen *)screen {
    [self setPdfDocument:pdfDocument
          goToPageNumber:pageNum
                    rect:[[pdfDocument pageAtIndex:pageNum] boundsForBox:kPDFDisplayBoxCropBox]
             scaleFactor:1.0
                autoFits:YES
                  screen:screen
                openType:SKSnapshotOpenPreview];
}

- (void)setPdfDocument:(PDFDocument *)pdfDocument setup:(NSDictionary *)setup {
    [self setPdfDocument:pdfDocument
          goToPageNumber:[[setup objectForKey:PAGE_KEY] unsignedIntegerValue]
                    rect:NSRectFromString([setup objectForKey:RECT_KEY])
             scaleFactor:[[setup objectForKey:SCALEFACTOR_KEY] doubleValue]
                autoFits:[[setup objectForKey:AUTOFITS_KEY] boolValue]
                  screen:nil
                openType:SKSnapshotOpenFromSetup];
    
    [self setHasWindow:[[setup objectForKey:HASWINDOW_KEY] boolValue]];
    if ([setup objectForKey:WINDOWFRAME_KEY])
        [[self window] setFrame:NSRectFromString([setup objectForKey:WINDOWFRAME_KEY]) display:NO];
}

- (BOOL)isPageVisible:(PDFPage *)page {
    return [[page document] isEqual:[pdfView document]] && NSLocationInRange([page pageIndex], [pdfView displayedPageIndexRange]);
}

#pragma mark Acessors

- (NSRect)bounds {
    NSView *clipView = [[pdfView scrollView] contentView];
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
    if ([[self window] isVisible])
        [self updateWindowLevel];
}

- (NSDictionary *)currentSetup {
    NSView *clipView = [[pdfView scrollView] contentView];
    NSRect rect = [pdfView convertRect:[pdfView convertRect:[clipView bounds] fromView:clipView] toPage:[pdfView currentPage]];
    BOOL autoFits = [pdfView autoFits];
    return [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInteger:[self pageIndex]], PAGE_KEY, NSStringFromRect(rect), RECT_KEY, [NSNumber numberWithDouble:[pdfView scaleFactor]], SCALEFACTOR_KEY, [NSNumber numberWithBool:autoFits], AUTOFITS_KEY, [NSNumber numberWithBool:[[self window] isVisible]], HASWINDOW_KEY, NSStringFromRect([[self window] frame]), WINDOWFRAME_KEY, nil];
}

#pragma mark Actions

- (IBAction)doGoToNextPage:(id)sender {
    [pdfView goToNextPage:sender];
}

- (IBAction)doGoToPreviousPage:(id)sender {
    [pdfView goToPreviousPage:sender];
}

- (IBAction)doGoToFirstPage:(id)sender {
    [pdfView goToFirstPage:sender];
}

- (IBAction)doGoToLastPage:(id)sender {
    [pdfView goToLastPage:sender];
}

- (IBAction)doGoBack:(id)sender {
    [pdfView goBack:sender];
}

- (IBAction)doGoForward:(id)sender {
    [pdfView goForward:sender];
}

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
    if (action == @selector(doGoToNextPage:)) {
        return [pdfView canGoToNextPage];
    } else if (action == @selector(doGoToPreviousPage:)) {
        return [pdfView canGoToPreviousPage];
    } else if (action == @selector(doGoToFirstPage:)) {
        return [pdfView canGoToFirstPage];
    } else if (action == @selector(doGoToLastPage:)) {
        return [pdfView canGoToLastPage];
    } else if (action == @selector(doGoBack:)) {
        return [pdfView canGoBack];
    } else if (action == @selector(doGoForward:)) {
        return [pdfView canGoForward];
    } else if (action == @selector(doZoomIn:)) {
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
    NSView *clipView = [[pdfView scrollView] contentView];
    NSRect bounds = [pdfView convertRect:[clipView bounds] fromView:clipView];
    NSBitmapImageRep *imageRep = [pdfView bitmapImageRepCachingDisplayInRect:bounds];
    NSAffineTransform *transform = nil;
    NSSize thumbnailSize = thumbnailSize = bounds.size;
    CGFloat shadowBlurRadius = 0.0;
    CGFloat shadowOffset = 0.0;
    NSImage *image;
    
    bounds.origin = NSZeroPoint;
    
    if (size > 0.0) {
        shadowBlurRadius = round(size / 32.0);
        shadowOffset = -ceil(shadowBlurRadius * 0.75);
        if (NSHeight(bounds) > NSWidth(bounds))
            thumbnailSize = NSMakeSize(round((size - 2.0 * shadowBlurRadius) * NSWidth(bounds) / NSHeight(bounds) + 2.0 * shadowBlurRadius), size);
        else
            thumbnailSize = NSMakeSize(size, round((size - 2.0 * shadowBlurRadius) * NSHeight(bounds) / NSWidth(bounds) + 2.0 * shadowBlurRadius));
        transform = [NSAffineTransform transform];
        [transform translateXBy:shadowBlurRadius yBy:shadowBlurRadius - shadowOffset];
        [transform scaleXBy:(thumbnailSize.width - 2.0 * shadowBlurRadius) / NSWidth(bounds) yBy:(thumbnailSize.height - 2.0 * shadowBlurRadius) / NSHeight(bounds)];
    }
    
    image = [[[NSImage alloc] initWithSize:thumbnailSize] autorelease];
    
    [image lockFocus];
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
    [transform concat];
    [NSGraphicsContext saveGraphicsState];
    [[PDFView defaultPageBackgroundColor] set];
    if (shadowBlurRadius > 0.0)
        [NSShadow setShadowWithColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.5] blurRadius:shadowBlurRadius yOffset:shadowOffset];
    NSRectFill(bounds);
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationDefault];
    [NSGraphicsContext restoreGraphicsState];
    [imageRep drawInRect:bounds];
    [image unlockFocus];
    
    return image;
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

- (NSRect)miniaturizedRectForDockingRect:(NSRect)dockRect {
    NSView *clipView = [[pdfView scrollView] contentView];
    NSRect sourceRect = [clipView convertRect:[clipView bounds] toView:nil];
    NSRect targetRect;
    NSSize windowSize = [[self window] frame].size;
    NSSize thumbSize = [thumbnail size];
    CGFloat thumbRatio = thumbSize.height / thumbSize.width;
    CGFloat dockRatio = NSHeight(dockRect) / NSWidth(dockRect);
    CGFloat scaleFactor;
    CGFloat shadowRadius = round(fmax(thumbSize.width, thumbSize.height) / 32.0);
    CGFloat shadowOffset = ceil(0.75 * shadowRadius);
    
    if (thumbRatio > dockRatio) {
        targetRect = NSInsetRect(dockRect, 0.5 * NSWidth(dockRect) * (1.0 - dockRatio / thumbRatio), 0.0);
        scaleFactor = NSHeight(targetRect) / thumbSize.height;
    } else {
        targetRect = NSInsetRect(dockRect, 0.0, 0.5 * NSHeight(dockRect) * (1.0 - thumbRatio / dockRatio));
        scaleFactor = NSWidth(targetRect) / thumbSize.width;
    }
    shadowRadius *= scaleFactor;
    shadowOffset *= scaleFactor;
    targetRect = NSOffsetRect(NSInsetRect(targetRect, shadowRadius, shadowRadius), 0.0, shadowOffset);
    scaleFactor = thumbRatio > dockRatio ? NSHeight(targetRect) / NSHeight(sourceRect) : NSWidth(targetRect) / NSWidth(sourceRect);
    
    return NSMakeRect(NSMinX(targetRect) - scaleFactor * NSMinX(sourceRect), NSMinY(targetRect) - scaleFactor * NSMinY(sourceRect), scaleFactor * windowSize.width, scaleFactor * windowSize.height);
}

- (void)miniaturizeWindowFromRect:(NSRect)startRect toRect:(NSRect)endRect {
    if (windowImage == nil)
        windowImage = [[(SKSnapshotWindow *)[self window] windowImage] retain];
    
    SKAnimatedBorderlessWindow *miniaturizeWindow = [[SKAnimatedBorderlessWindow alloc] initWithContentRect:startRect];
    [miniaturizeWindow setLevel:NSFloatingWindowLevel];
    [miniaturizeWindow setBackgroundImage:windowImage];
    
    [miniaturizeWindow orderFront:nil];
    
    animating = YES;
    
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context){
            [context setDuration:RESIZE_TIME_FACTOR * [miniaturizeWindow animationResizeTime:endRect]];
            [[miniaturizeWindow animator] setFrame:endRect display:YES];
        }
        completionHandler:^{
            if ([self hasWindow]) {
                [[self window] setAnimationBehavior:NSWindowAnimationBehaviorNone];
                [[self window] orderFront:nil];
                [self updateWindowLevel];
                [[self window] setAnimationBehavior:NSWindowAnimationBehaviorDefault];
            }
            [miniaturizeWindow orderOut:nil];
            animating = NO;
    }];
    
    [miniaturizeWindow release];
}

- (void)miniaturize {
    if (animating)
        return;
    if ([[self delegate] respondsToSelector:@selector(snapshotController:miniaturizedRect:)]) {
        NSRect dockRect = [[self delegate] snapshotController:self miniaturizedRect:YES];
        NSRect startRect = [[self window] frame];
        NSRect endRect = [self miniaturizedRectForDockingRect:dockRect];
        
        [self miniaturizeWindowFromRect:startRect toRect:endRect];
        
        [[self window] setAnimationBehavior:NSWindowAnimationBehaviorNone];
    }
    [[self window] orderOut:nil];
    [[self window] setAnimationBehavior:NSWindowAnimationBehaviorDefault];
    [self setHasWindow:NO];
}

- (void)deminiaturize {
    if (animating)
        return;
    if ([[self delegate] respondsToSelector:@selector(snapshotController:miniaturizedRect:)]) {
        NSRect dockRect = [[self delegate] snapshotController:self miniaturizedRect:NO];
        NSRect endRect = [[self window] frame];
        NSRect startRect = [self miniaturizedRectForDockingRect:dockRect];
        
        [self miniaturizeWindowFromRect:startRect toRect:endRect];
        
        SKDESTROY(windowImage);
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
            if ([[self window] isVisible])
                [self updateWindowLevel];
        } else if ([key isEqualToString:SKShouldAntiAliasKey]) {
            [pdfView setShouldAntiAlias:[[NSUserDefaults standardUserDefaults] boolForKey:SKShouldAntiAliasKey]];
            [pdfView applyDefaultInterpolationQuality];
        } else if ([key isEqualToString:SKGreekingThresholdKey]) {
            [pdfView setGreekingThreshold:[[NSUserDefaults standardUserDefaults] floatForKey:SKGreekingThresholdKey]];
        } else if ([key isEqualToString:SKBackgroundColorKey] || [key isEqualToString:SKDarkBackgroundColorKey]) {
            [pdfView setBackgroundColor:[PDFView defaultBackgroundColor]];
        } else if ([key isEqualToString:SKPageBackgroundColorKey]) {
            [pdfView applyDefaultPageBackgroundColor];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark NSPasteboardItemDataProvider protocol

// the controller is set as owner in -[SKRightSideViewController tableView:writeRowsWithIndexestoPasteboard:]
- (void)pasteboard:(NSPasteboard *)pboard item:(NSPasteboardItem *)item provideDataForType:(NSString *)type {
    if ([type isEqualToString:(NSString *)kPasteboardTypeFileURLPromise]) {
        NSURL *dropDestination = [pboard pasteLocationURL];
        PDFPage *page = [[[self pdfView] document] pageAtIndex:[self pageIndex]];
        NSString *filename = [NSString stringWithFormat:@"%@ %c %@", ([[[self document] displayName] stringByDeletingPathExtension] ?: @"PDF"), '-', [NSString stringWithFormat:NSLocalizedString(@"Page %@", @""), [page displayLabel]]];
        NSURL *fileURL = [[dropDestination URLByAppendingPathComponent:filename] URLByAppendingPathExtension:@"tiff"];
        fileURL = [fileURL uniqueFileURL];
        if ([[[self thumbnailWithSize:0.0] TIFFRepresentation] writeToURL:fileURL atomically:YES])
            [item setString:[fileURL absoluteString] forType:type];
    } else if ([type isEqualToString:NSPasteboardTypeTIFF]) {
        [item setData:[[self thumbnailWithSize:0.0] TIFFRepresentation] forType:type];
    }
}

#pragma mark NSFilePromiseProviderDelegate protocol

- (NSString *)filePromiseProvider:(NSFilePromiseProvider *)filePromiseProvider fileNameForType:(NSString *)fileType {
    PDFPage *page = [[[self pdfView] document] pageAtIndex:[self pageIndex]];
    NSString *filename = [NSString stringWithFormat:@"%@ %c %@", ([[[self document] displayName] stringByDeletingPathExtension] ?: @"PDF"), '-', [NSString stringWithFormat:NSLocalizedString(@"Page %@", @""), [page displayLabel]]];
    return [filename stringByAppendingPathExtension:@"tiff"];
}

- (void)filePromiseProvider:(NSFilePromiseProvider *)filePromiseProvider writePromiseToURL:(NSURL *)fileURL completionHandler:(void (^)(NSError *))completionHandler {
    NSError *error = nil;
    [[[self thumbnailWithSize:0.0] TIFFRepresentation] writeToURL:fileURL options:NSDataWritingAtomic error:&error];
    completionHandler(error);
}

@end
