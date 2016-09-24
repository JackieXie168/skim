//
//  PDFView_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 7/3/11.
/*
 This software is Copyright (c) 2011-2016
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


#if MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_6

@interface NSScreen (SKLionDeclarations)
- (CGFloat)backingScaleFactor;
@end

typedef NSInteger PDFInterpolationQuality;
enum
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

@implementation PDFView (SKExtensions)

@dynamic physicalScaleFactor, scrollView, displayedPageIndexRange, displayedPages;

static void (*original_keyDown)(id, SEL, id) = NULL;

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
        NSView *documentView = [scrollView documentView];
        NSClipView *clipView = [scrollView contentView];
        NSRect docRect = [documentView frame];
        NSRect clipRect = [clipView bounds];
        BOOL flipped = [clipView isFlipped];
        
        if (eventChar == NSDownArrowFunctionKey || eventChar == NSPageDownFunctionKey) {
            if (flipped ? NSMaxY(clipRect) <= NSMaxY(docRect) - 1.0 : NSMinY(clipRect) >= NSMinY(docRect) + 1.0) {
                CGFloat scroll = eventChar == NSDownArrowFunctionKey ? [scrollView verticalLineScroll] : NSHeight(clipRect) - [scrollView verticalPageScroll];
                clipRect.origin.y += flipped ? scroll : -scroll;
                [clipView scrollPoint:clipRect.origin];
            } else if ([self canGoToNextPage]) {
                [self goToNextPage:nil];
                docRect = [documentView frame];
                clipRect = [clipView bounds];
                clipRect.origin.y = flipped ? NSMinY(docRect) : NSMaxY(docRect) - NSHeight(clipRect);
                [clipView scrollPoint:clipRect.origin];
            }
        } else if (eventChar == NSUpArrowFunctionKey || eventChar == NSPageUpFunctionKey) {
            if (flipped ? NSMinY(clipRect) >= NSMinY(docRect) + 1.0 : NSMaxY(clipRect) <= NSMaxY(docRect) - 1.0) {
                CGFloat scroll = eventChar == NSUpArrowFunctionKey ? [scrollView verticalLineScroll] : NSHeight(clipRect) - [scrollView verticalPageScroll];
                clipRect.origin.y += flipped ? -scroll : scroll;
                [clipView scrollPoint:clipRect.origin];
            } else if ([self canGoToPreviousPage]) {
                [self goToPreviousPage:nil];
                docRect = [documentView frame];
                clipRect = [clipView bounds];
                clipRect.origin.y = flipped ? NSMaxY(docRect) - NSHeight(clipRect) : NSMinY(docRect);
                [clipView scrollPoint:clipRect.origin];
            }
        }
    } else {
        original_keyDown(self, _cmd, theEvent);
    }
}

+ (void)load {
    if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_9)
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
        NSView *docView = [self documentView];
        CGFloat scale = [self scaleFactor];
        rect = SKIntegralRect(NSInsetRect([self convertRect:rect fromPage:page], -scale, -scale));
        rect = NSIntersectionRect([docView bounds], [self convertRect:rect toView:docView]);
        if (NSIsEmptyRect(rect) == NO)
            [docView setNeedsDisplayInRect:rect];
    }
}

- (void)setNeedsDisplayForAnnotation:(PDFAnnotation *)annotation onPage:(PDFPage *)page {
    [self setNeedsDisplayInRect:[annotation displayRect] ofPage:page];
    [self annotationsChangedOnPage:page];
}

- (void)setNeedsDisplayForAnnotation:(PDFAnnotation *)annotation {
    [self setNeedsDisplayForAnnotation:annotation onPage:[annotation page]];
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
    PDFDestination *dest = [self currentDestination];
    if (point) {
        if ([page isEqual:[dest page]])
            *point = [dest point];
        else
            *point = [self convertPoint:[self convertPoint:[dest point] fromPage:[dest page]] toPage:page];
    }
    if (rotated) *rotated = [page rotation] != [page intrinsicRotation];
    return [page pageIndex];
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

+ (NSColor *)defaultPageBackgroundColor {
    if ([self respondsToSelector:@selector(setPageColor:)])
        return [[NSUserDefaults standardUserDefaults] colorForKey:SKPageBackgroundColorKey] ?: [NSColor whiteColor];
    return [NSColor whiteColor];
}

- (void)applyDefaultPageBackgroundColor {
    if ([self respondsToSelector:@selector(setPageColor:)])
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
