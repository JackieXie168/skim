//
//  PDFView_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 7/3/11.
/*
 This software is Copyright (c) 2011-2017
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

#import "PDFView_SKExtensions.h"
#import "PDFAnnotation_SKExtensions.h"
#import "SKMainDocument.h"
#import "SKPDFSynchronizer.h"
#import "PDFPage_SKExtensions.h"
#import "PDFSelection_SKExtensions.h"
#import "NSEvent_SKExtensions.h"
#import "SKRuntime.h"
#import "NSGeometry_SKExtensions.h"
#import "NSUserDefaults_SKExtensions.h"
#import "SKStringConstants.h"
#import <SkimNotes/SkimNotes.h>


#if SDK_BEFORE(10_7)

@interface NSScreen (SKLionDeclarations)
- (CGFloat)backingScaleFactor;
@end

typedef NS_ENUM(NSInteger, PDFInterpolationQuality)
{
    kPDFInterpolationQualityNone = 0,
    kPDFInterpolationQualityLow = 1,
    kPDFInterpolationQualityHigh = 2
};

@interface PDFView (SKLionDeclarations)
- (void)setInterpolationQuality:(PDFInterpolationQuality)quality;
- (PDFInterpolationQuality)interpolationQuality;
@end

#endif

#if SDK_BEFORE(10_12)

@interface PDFView (SKSierraDeclarations)
- (void)drawPage:(PDFPage *)page toContext:(CGContextRef)context;
@end

#endif

#if SDK_BEFORE(10_13)

@interface PDFView (SKHighSierraDeclarations)
- (CGFloat)minScaleFactor;
- (CGFloat)maxScaleFactor;
@end

#endif

@implementation PDFView (SKExtensions)

@dynamic physicalScaleFactor, scrollView, displayedPageIndexRange, displayedPages, minimumScaleFactor, maximumScaleFactor;

static void (*original_keyDown)(id, SEL, id) = NULL;
static void (*original_drawPage_toContext)(id, SEL, id, CGContextRef) = NULL;

// on Yosemite, the arrow up/down and page up/down keys in non-continuous mode switch pages the wrong way
- (void)replacement_keyDown:(NSEvent *)theEvent {
    unichar eventChar = [theEvent firstCharacter];
    NSUInteger modifiers = [theEvent standardModifierFlags];
    
    if ((eventChar == SKSpaceCharacter) && ((modifiers & ~NSShiftKeyMask) == 0)) {
        eventChar = modifiers == NSShiftKeyMask ? NSPageUpFunctionKey : NSPageDownFunctionKey;
        modifiers = 0;
    }
    
    if ((([self displayMode] & kPDFDisplaySinglePageContinuous) == 0) &&
        (eventChar == NSDownArrowFunctionKey || eventChar == NSUpArrowFunctionKey || eventChar == NSPageDownFunctionKey || eventChar == NSPageUpFunctionKey) &&
        (modifiers == 0)) {
        
        NSScrollView *scrollView = [self scrollView];
        NSClipView *clipView = [scrollView contentView];
        NSRect clipRect = [clipView bounds];
        BOOL flipped = [clipView isFlipped];
        CGFloat scroll = eventChar == NSUpArrowFunctionKey || eventChar == NSDownArrowFunctionKey ? [scrollView verticalLineScroll] : NSHeight([self convertRect:clipRect fromView:clipView]) - 6.0 * [scrollView verticalPageScroll];
        NSPoint point = [self convertPoint:clipRect.origin fromView:clipView];
        CGFloat margin = [self convertSize:NSMakeSize(1.0, 1.0) toView:clipView].height;
        
        if (eventChar == NSDownArrowFunctionKey || eventChar == NSPageDownFunctionKey) {
            point.y -= scroll;
            [clipView scrollPoint:[self convertPoint:point toView:clipView]];
            if (fabs(NSMinY(clipRect) - NSMinY([clipView bounds])) <= margin && [self canGoToNextPage]) {
                [self goToNextPage:nil];
                NSRect docRect = [[scrollView documentView] frame];
                clipRect = [clipView bounds];
                clipRect.origin.y = flipped ? NSMinY(docRect) : NSMaxY(docRect) - NSHeight(clipRect);
                [clipView scrollPoint:clipRect.origin];
            }
        } else if (eventChar == NSUpArrowFunctionKey || eventChar == NSPageUpFunctionKey) {
            point.y += scroll;
            [clipView scrollPoint:[self convertPoint:point toView:clipView]];
            if (fabs(NSMinY(clipRect) - NSMinY([clipView bounds])) <= margin && [self canGoToPreviousPage]) {
                [self goToPreviousPage:nil];
                NSRect docRect = [[scrollView documentView] frame];
                clipRect = [clipView bounds];
                clipRect.origin.y = flipped ? NSMaxY(docRect) - NSHeight(clipRect) : NSMinY(docRect);
                [clipView scrollPoint:clipRect.origin];
            }
        }
    } else {
        original_keyDown(self, _cmd, theEvent);
    }
}

- (void)replacement_drawPage:(PDFPage *)pdfPage toContext:(CGContextRef)context {
    original_drawPage_toContext(self, _cmd, pdfPage, context);
    
    // On (High) Sierra note annotations don't draw at all
    if (RUNNING_AFTER(10_11)) {
        for (PDFAnnotation *annotation in [[[pdfPage annotations] copy] autorelease]) {
            if ([annotation shouldDisplay] && ([annotation isNote] || [[annotation type] isEqualToString:SKNTextString]))
                [annotation drawWithBox:[self displayBox] inContext:context];
        }
    }
}

+ (void)load {
    if (RUNNING_AFTER(10_11))
        original_drawPage_toContext = (void (*)(id, SEL, id, CGContextRef))SKReplaceInstanceMethodImplementationFromSelector(self, @selector(drawPage:toContext:), @selector(replacement_drawPage:toContext:));
    else if (RUNNING_AFTER(10_9))
        original_keyDown = (void (*)(id, SEL, id))SKReplaceInstanceMethodImplementationFromSelector(self, @selector(keyDown:), @selector(replacement_keyDown:));
}

static inline CGFloat physicalScaleFactorForView(NSView *view) {
    NSScreen *screen = [[view window] screen];
    NSDictionary *deviceDescription = [screen deviceDescription];
	CGDirectDisplayID displayID = (CGDirectDisplayID)[[deviceDescription objectForKey:@"NSScreenNumber"] unsignedIntValue];
	CGSize physicalSize = CGDisplayScreenSize(displayID);
    NSSize resolution = [[deviceDescription objectForKey:NSDeviceResolution] sizeValue];
    CGFloat backingScaleFactor = [NSScreen instancesRespondToSelector: @selector(backingScaleFactor)] ? [screen backingScaleFactor] : 1.0;
	return CGSizeEqualToSize(physicalSize, CGSizeZero) ? 1.0 : (physicalSize.width * resolution.width) / (CGDisplayPixelsWide(displayID) * backingScaleFactor * 25.4f);
}

- (CGFloat)physicalScaleFactor {
    return [self scaleFactor] * physicalScaleFactorForView(self);
}

- (void)setPhysicalScaleFactor:(CGFloat)scale {
    [self setScaleFactor:scale / physicalScaleFactorForView(self)];
}

- (NSScrollView *)scrollView {
    return [[self documentView] enclosingScrollView];
}

- (void)setNeedsDisplayInRect:(NSRect)rect ofPage:(PDFPage *)page {
    if (NSLocationInRange([page pageIndex], [self displayedPageIndexRange])) {
        // for some versions we need to dirty the documentView, otherwise it won't redisplay when scrolled out of view,
        // for 10.12 dirtying the documentView dioes not do anything
        NSView *view = RUNNING_BEFORE(10_12) ? [self documentView] : self;
        rect = NSIntegralRect([self convertRect:NSInsetRect(rect, -1.0, -1.0) fromPage:page]);
        rect = NSIntersectionRect([view bounds], [self convertRect:rect toView:view]);
        if (NSIsEmptyRect(rect) == NO)
            [view setNeedsDisplayInRect:rect];
    }
}

- (void)setNeedsDisplayForAnnotation:(PDFAnnotation *)annotation onPage:(PDFPage *)page {
    [self setNeedsDisplayInRect:[annotation displayRect] ofPage:page];
    [self annotationsChangedOnPage:page];
}

- (void)setNeedsDisplayForAnnotation:(PDFAnnotation *)annotation {
    [self setNeedsDisplayForAnnotation:annotation onPage:[annotation page]];
}

- (void)requiresDisplay {
    NSView *view = RUNNING_BEFORE(10_12) ? [self documentView] : self;
    [view setNeedsDisplay:YES];
}

- (void)doPdfsyncWithEvent:(NSEvent *)theEvent {
    // eat up mouseDragged/mouseUp events, so we won't get their event handlers
    while (YES) {
        if ([[[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask] type] == NSLeftMouseUp)
            break;
    }
    
    SKMainDocument *document = (SKMainDocument *)[[[self window] windowController] document];
    
    if ([document respondsToSelector:@selector(synchronizer)]) {
        
        NSPoint location = NSZeroPoint;
        PDFPage *page = [self pageAndPoint:&location forEvent:theEvent nearest:YES];
        NSUInteger pageIndex = [page pageIndex];
        PDFSelection *sel = [page selectionForLineAtPoint:location];
        NSRect rect = [sel hasCharacters] ? [sel boundsForPage:page] : NSMakeRect(location.x - 20.0, location.y - 5.0, 40.0, 10.0);
        
        [[document synchronizer] findFileAndLineForLocation:location inRect:rect pageBounds:[page boundsForBox:kPDFDisplayBoxMediaBox] atPageIndex:pageIndex];
    }
}

- (void)doDragWithEvent:(NSEvent *)theEvent {
    NSView *contentView = [[self scrollView] contentView];
	NSPoint startLocation = [theEvent locationInView:contentView];
	
    [[NSCursor closedHandCursor] push];
    
	while (YES) {
        
		theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask];
        if ([theEvent type] == NSLeftMouseUp)
            break;
        
        // convert takes flipping and scaling into account
        NSPoint	newLocation = [theEvent locationInView:contentView];
        NSPoint	point = SKAddPoints([contentView bounds].origin, SKSubstractPoints(startLocation, newLocation));
        
        [contentView scrollPoint:point];
	}
    
    [NSCursor pop];
    // ??? PDFView's delayed layout seems to reset the cursor to an arrow
    [self performSelector:@selector(mouseMoved:) withObject:theEvent afterDelay:0];
}

- (PDFPage *)pageAndPoint:(NSPoint *)point forEvent:(NSEvent *)event nearest:(BOOL)nearest {
    NSPoint p = [event locationInView:self];
    PDFPage *page = [self pageForPoint:p nearest:nearest];
    if (page && point)
        *point = [self convertPoint:p toPage:page];
    return page;
}

- (NSUInteger)currentPageIndexAndPoint:(NSPoint *)point rotated:(BOOL *)rotated {
    PDFPage *page = [self currentPage];
    // don't use currentDestination, as that always gives the top-left of the page in non-continuous mode, rather than the visible area
    if (point) *point = [self convertPoint:SKTopLeftPoint([self bounds]) toPage:page];
    if (rotated) *rotated = [page rotation] != [page intrinsicRotation];
    return [page pageIndex];
}

- (void)goToPageAtIndex:(NSUInteger)pageIndex point:(NSPoint)point {
    PDFPage *page = [[self document] pageAtIndex:pageIndex];
    if (RUNNING_AFTER(10_12)) {
        NSView *docView = [self documentView];
        if (NSLocationInRange(pageIndex, [self displayedPageIndexRange]) == NO)
            [self goToPage:page];
        point = [self convertPoint:[self convertPoint:point fromPage:page] toView:docView];
        if ([[[docView enclosingScrollView] contentView] isFlipped] == NO)
            point.y -= [docView isFlipped] ? -NSHeight([docView visibleRect]) : NSHeight([docView visibleRect]);
        [docView scrollPoint:point];
    } else {
        [self goToDestination:[[[PDFDestination alloc] initWithPage:page atPoint:point] autorelease]];
    }
}

- (NSRange)displayedPageIndexRange {
    NSUInteger pageCount = [[self document] pageCount];
    PDFDisplayMode displayMode = [self displayMode];
    NSRange range = NSMakeRange(0, pageCount);
    if (pageCount > 0 && (displayMode == kPDFDisplaySinglePage || displayMode == kPDFDisplayTwoUp)) {
        range = NSMakeRange([[self currentPage] pageIndex], 1);
        if (displayMode == kPDFDisplayTwoUp) {
            if ([self displaysAsBook] == (BOOL)(range.location % 2)) {
                if (NSMaxRange(range) < pageCount)
                    range.length = 2;
            } else if (range.location > 0) {
                range.location -= 1;
                range.length = 2;
            }
        }
    }
    return range;
}

- (NSArray *)displayedPages {
    NSMutableArray *displayedPages = [NSMutableArray array];
    PDFDocument *pdfDoc = [self document];
    NSRange range = [self displayedPageIndexRange];
    NSUInteger i;
    for (i = range.location; i < NSMaxRange(range); i++)
        [displayedPages addObject:[pdfDoc pageAtIndex:i]];
    return displayedPages;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"

- (CGFloat)minimumScaleFactor {
    if ([self respondsToSelector:@selector(minScaleFactor)])
        return [self minScaleFactor];
    return 0.1;
}

- (CGFloat)maximumScaleFactor {
    if ([self respondsToSelector:@selector(maxScaleFactor)])
        return [self maxScaleFactor];
    return 20.0;
}

#pragma clang diagnostic pop

- (NSRect)integralRect:(NSRect)rect onPage:(PDFPage *)page {
    // we'd like to use backingAlignedRect, but that is not thread safe, and we need this for drawing
    return [self convertRect:[self convertRect:rect fromPage:page] toPage:page];
}

- (CGFloat)unitWidthOnPage:(PDFPage *)page {
    return NSWidth([self convertRect:NSMakeRect(0.0, 0.0, 1.0, 1.0) toPage:page]);
}

+ (NSColor *)defaultPageBackgroundColor {
    if ([self instancesRespondToSelector:@selector(setPageColor:)] && RUNNING_BEFORE(10_12))
        return [[NSUserDefaults standardUserDefaults] colorForKey:SKPageBackgroundColorKey] ?: [NSColor whiteColor];
    return [NSColor whiteColor];
}

- (void)applyDefaultPageBackgroundColor {
    if ([self respondsToSelector:@selector(setPageColor:)] && RUNNING_BEFORE(10_12))
        [self setPageColor:[[self class] defaultPageBackgroundColor]];
}

- (void)applyDefaultInterpolationQuality {
    if ([self respondsToSelector:@selector(setInterpolationQuality:)]) {
        NSImageInterpolation interpolation = [[NSUserDefaults standardUserDefaults] integerForKey:SKImageInterpolationKey];
        // smooth graphics when anti-aliasing
        if (interpolation == NSImageInterpolationDefault)
            interpolation = [self shouldAntiAlias] ? NSImageInterpolationHigh : NSImageInterpolationNone;
        [self setInterpolationQuality:interpolation == NSImageInterpolationHigh ? kPDFInterpolationQualityHigh : interpolation == NSImageInterpolationLow ? kPDFInterpolationQualityLow : kPDFInterpolationQualityNone];
    }
}

@end
