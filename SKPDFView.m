//
//  SKPDFView.m
//  Skim
//
//  Created by Michael McCracken on 12/6/06.
/*
 This software is Copyright (c) 2006-2009
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

#import "SKPDFView.h"
#import "SKNavigationWindow.h"
#import "SKPDFToolTipWindow.h"
#import "SKMainWindowController.h"
#import <SkimNotes/SkimNotes.h>
#import "PDFAnnotation_SKExtensions.h"
#import "PDFAnnotationMarkup_SKExtensions.h"
#import "PDFAnnotationInk_SKExtensions.h"
#import "SKPDFAnnotationTemporary.h"
#import "PDFPage_SKExtensions.h"
#import "NSString_SKExtensions.h"
#import "NSCursor_SKExtensions.h"
#import "SKApplication.h"
#import "SKStringConstants.h"
#import "NSUserDefaultsController_SKExtensions.h"
#import "NSUserDefaults_SKExtensions.h"
#import "SKReadingBar.h"
#import "SKMainDocument.h"
#import "SKPDFSynchronizer.h"
#import "PDFSelection_SKExtensions.h"
#import "NSBezierPath_BDSKExtensions.h"
#import "SKLineWell.h"
#import <CoreServices/CoreServices.h>
#import "NSGeometry_SKExtensions.h"
#import "SKTypeSelectHelper.h"
#import "SKRuntime.h"
#import "NSAffineTransform_SKExtensions.h"
#import "BDSKEdgeView.h"
#import "PDFDocument_SKExtensions.h"
#import "PDFDisplayView_SKExtensions.h"
#import "SKAccessibilityFauxUIElement.h"
#import "NSResponder_SKExtensions.h"
#import "NSEvent_SKExtensions.h"
#import "SKLineInspector.h"

#define ANNOTATION_MODE_COUNT 9
#define TOOL_MODE_COUNT 5

NSString *SKPDFViewToolModeChangedNotification = @"SKPDFViewToolModeChangedNotification";
NSString *SKPDFViewAnnotationModeChangedNotification = @"SKPDFViewAnnotationModeChangedNotification";
NSString *SKPDFViewActiveAnnotationDidChangeNotification = @"SKPDFViewActiveAnnotationDidChangeNotification";
NSString *SKPDFViewDidAddAnnotationNotification = @"SKPDFViewDidAddAnnotationNotification";
NSString *SKPDFViewDidRemoveAnnotationNotification = @"SKPDFViewDidRemoveAnnotationNotification";
NSString *SKPDFViewDidMoveAnnotationNotification = @"SKPDFViewDidMoveAnnotationNotification";
NSString *SKPDFViewReadingBarDidChangeNotification = @"SKPDFViewReadingBarDidChangeNotification";
NSString *SKPDFViewSelectionChangedNotification = @"SKPDFViewSelectionChangedNotification";
NSString *SKPDFViewMagnificationChangedNotification = @"SKPDFViewMagnificationChangedNotification";
NSString *SKPDFViewDisplayModeChangedNotification = @"SKPDFViewDisplayModeChangedNotification";
NSString *SKPDFViewDisplayAsBookChangedNotification = @"SKPDFViewDisplayAsBookChangedNotification";
NSString *SKPDFViewDisplayBoxChangedNotification = @"SKPDFViewDisplayBoxChangedNotification";

NSString *SKPDFViewAnnotationKey = @"annotation";
NSString *SKPDFViewPageKey = @"page";
NSString *SKPDFViewOldPageKey = @"oldPage";
NSString *SKPDFViewNewPageKey = @"newPage";

NSString *SKSkimNotePboardType = @"SKSkimNotePboardType";

#define SKSmallMagnificationWidthKey @"SKSmallMagnificationWidth"
#define SKSmallMagnificationHeightKey @"SKSmallMagnificationHeight"
#define SKLargeMagnificationWidthKey @"SKLargeMagnificationWidth"
#define SKLargeMagnificationHeightKey @"SKLargeMagnificationHeight"
#define SKMoveReadingBarModifiersKey @"SKMoveReadingBarModifiers"
#define SKResizeReadingBarModifiersKey @"SKResizeReadingBarModifiers"
#define SKDisableUpdateContentsFromEnclosedTextKey @"SKDisableUpdateContentsFromEnclosedText"
#define SKDefaultFreeTextNoteContentsKey @"SKDefaultFreeTextNoteContents"
#define SKDefaultAnchoredNoteContentsKey @"SKDefaultAnchoredNoteContents"

#define SKReadingBarNumberOfLinesKey @"SKReadingBarNumberOfLines"

static char SKPDFViewDefaultsObservationContext;

static NSUInteger moveReadingBarModifiers = NSAlternateKeyMask;
static NSUInteger resizeReadingBarModifiers = NSAlternateKeyMask | NSShiftKeyMask;

static inline NSInteger SKIndexOfRectAtYInOrderedRects(CGFloat y,  NSArray *rectValues, BOOL lower);

static CGMutablePathRef SKCGCreatePathWithRoundRectInRect(CGRect rect, CGFloat radius);
static void SKCGContextDrawGrabHandle(CGContextRef context, CGPoint point, CGFloat radius, bool active);
static void SKCGContextDrawGrabHandles(CGContextRef context, CGRect rect, CGFloat radius, NSInteger mask);

enum {
    SKNavigationNone,
    SKNavigationBottom,
    SKNavigationEverywhere,
};

#pragma mark -

@interface PDFView (SKLeopardPrivate)
- (void)addTooltipsForVisiblePages;
- (void)handlePageChangedNotification:(NSNotification *)notification;
- (void)handleScaleChangedNotification:(NSNotification *)notification;
- (void)handleViewChangedNotification:(NSNotification *)notification;
- (void)handleWindowWillCloseNotification:(NSNotification *)notification;
@end

#pragma mark -

@interface SKPDFView (Private)

- (void)addAnnotationWithType:(SKNoteType)annotationType defaultPoint:(NSPoint)point;
- (void)addAnnotationWithType:(SKNoteType)annotationType contents:(NSString *)text page:(PDFPage *)page bounds:(NSRect)bounds;

- (void)transformCGContext:(CGContextRef)context forPage:(PDFPage *)page;

- (NSRange)visiblePageIndexRange;
- (NSRect)visibleContentRect;

- (void)enableNavigationForScreen:(NSScreen *)screen;
- (void)disableNavigation;

- (void)doAutohide:(BOOL)flag;
- (void)showNavWindow:(BOOL)flag;

- (PDFDestination *)destinationForEvent:(NSEvent *)theEvent isLink:(BOOL *)isLink;

- (void)doMoveActiveAnnotationForKey:(unichar)eventChar byAmount:(CGFloat)delta;
- (void)doResizeActiveAnnotationForKey:(unichar)eventChar byAmount:(CGFloat)delta;
- (void)doMoveReadingBarForKey:(unichar)eventChar;
- (void)doResizeReadingBarForKey:(unichar)eventChar;

- (BOOL)doSelectAnnotationWithEvent:(NSEvent *)theEvent;
- (void)doSelectSnapshotWithEvent:(NSEvent *)theEvent;
- (void)doMagnifyWithEvent:(NSEvent *)theEvent;
- (void)doDragWithEvent:(NSEvent *)theEvent;
- (void)doDrawFreehandNoteWithEvent:(NSEvent *)theEvent;
- (void)doSelectWithEvent:(NSEvent *)theEvent;
- (void)doSelectTextWithEvent:(NSEvent *)theEvent;
- (void)doDragReadingBarWithEvent:(NSEvent *)theEvent;
- (void)doResizeReadingBarWithEvent:(NSEvent *)theEvent;
- (void)doPdfsyncWithEvent:(NSEvent *)theEvent;
- (NSCursor *)getCursorForEvent:(NSEvent *)theEvent;
- (void)doUpdateCursor;

- (void)relayoutEditField;

@end

#pragma mark -

@implementation SKPDFView

+ (void)initialize {
    SKINITIALIZE;
    
    NSArray *sendTypes = [NSArray arrayWithObjects:NSPDFPboardType, NSTIFFPboardType, nil];
    [NSApp registerServicesMenuSendTypes:sendTypes returnTypes:nil];
    
    NSNumber *moveReadingBarModifiersNumber = [[NSUserDefaults standardUserDefaults] objectForKey:SKMoveReadingBarModifiersKey];
    NSNumber *resizeReadingBarModifiersNumber = [[NSUserDefaults standardUserDefaults] objectForKey:SKResizeReadingBarModifiersKey];
    if (moveReadingBarModifiersNumber)
        moveReadingBarModifiers = [moveReadingBarModifiersNumber integerValue];
    if (resizeReadingBarModifiersNumber)
        resizeReadingBarModifiers = [resizeReadingBarModifiersNumber integerValue];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Double-click to edit.", @"Default text for new text note"), SKDefaultFreeTextNoteContentsKey, NSLocalizedString(@"New note", @"Default text for new anchored note"), SKDefaultAnchoredNoteContentsKey, nil]];
    
    SKSwizzlePDFDisplayViewMethods();
}

- (void)commonInitialization {
    toolMode = [[NSUserDefaults standardUserDefaults] integerForKey:SKLastToolModeKey];
    annotationMode = [[NSUserDefaults standardUserDefaults] integerForKey:SKLastAnnotationModeKey];
    interactionMode = SKNormalMode;
    
    transitionController = nil;
    
    typeSelectHelper = nil;
    
    spellingTag = [NSSpellChecker uniqueSpellDocumentTag];
    
    hideNotes = NO;
    
    navWindow = nil;
    
    readingBar = nil;
    
    activeAnnotation = nil;
    mouseDownLoc = NSZeroPoint;
    selectionRect = NSZeroRect;
    selectionPageIndex = NSNotFound;
    magnification = 0.0;
    didSelect = NO;
    mouseDownInAnnotation = NO;
    
    gestureRotation = 0.0;
    gesturePageIndex = NSNotFound;
    
    trackingRect = 0;
    PDFToolTipRects = CFArrayCreateMutable(NULL, 0, NULL);
    
    [self registerForDraggedTypes:[NSArray arrayWithObjects:NSColorPboardType, SKLineStylePboardType, nil]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePageChangedNotification:) 
                                                 name:PDFViewPageChangedNotification object:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleScaleChangedNotification:) 
                                                 name:PDFViewScaleChangedNotification object:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleViewChangedNotification:) 
                                                 name:SKPDFViewDisplayModeChangedNotification object:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleViewChangedNotification:) 
                                                 name:SKPDFViewDisplayBoxChangedNotification object:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleViewChangedNotification:) 
                                                 name:SKPDFViewDisplayAsBookChangedNotification object:self];
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeys:
        [NSArray arrayWithObjects:SKReadingBarColorKey, SKReadingBarInvertKey, nil]
        context:&SKPDFViewDefaultsObservationContext];
}

- (id)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        [self commonInitialization];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
        [self commonInitialization];
    }
    return self;
}

- (void)dealloc {
    [[NSSpellChecker sharedSpellChecker] closeSpellDocumentWithTag:spellingTag];
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeys:
        [NSArray arrayWithObjects:SKReadingBarColorKey, SKReadingBarInvertKey, nil]];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self showNavWindow:NO];
    [self doAutohide:NO];
    [[SKPDFToolTipWindow sharedToolTipWindow] orderOut:self];
    [self removePDFToolTipRects];
    CFRelease(PDFToolTipRects);
    [typeSelectHelper setDataSource:nil];
    [typeSelectHelper release];
    [transitionController release];
    [navWindow release];
    [readingBar release];
    [accessibilityChildren release];
    [super dealloc];
}

#pragma mark Tool Tips

- (void)removePDFToolTipRects {
    CFIndex idx = CFArrayGetCount(PDFToolTipRects);
    while (idx--)
        [[self documentView] removeTrackingRect:(NSTrackingRectTag)CFArrayGetValueAtIndex(PDFToolTipRects, idx)];
    CFArrayRemoveAllValues(PDFToolTipRects);
}

- (void)resetPDFToolTipRects {
    [self removePDFToolTipRects];
    
    if ([self document] && [self window]) {
        NSRange range = [self visiblePageIndexRange];
        NSUInteger i, iMax = NSMaxRange(range);
        NSRect visibleRect = [self visibleContentRect];
        
        for (i = range.location; i < iMax; i++) {
            PDFPage *page = [[self document] pageAtIndex:i];
            NSArray *annotations = [page annotations];
            NSUInteger j, jMax = [annotations count];
            for (j = 0; j < jMax; j++) {
                PDFAnnotation *annotation = [annotations objectAtIndex:j];
                if ([[annotation type] isEqualToString:SKNNoteString] || [annotation isLink]) {
                    NSRect rect = NSIntersectionRect([self convertRect:[annotation bounds] fromPage:page], visibleRect);
                    if (NSIsEmptyRect(rect) == NO) {
                        rect = [self convertRect:rect toView:[self documentView]];
                        NSTrackingRectTag tag = [[self documentView] addTrackingRect:rect owner:self userData:annotation assumeInside:NO];
                        CFArrayAppendValue(PDFToolTipRects, (void *)tag);
                    }
                }
            }
        }
    }
}

#pragma mark Drawing

- (void)drawPage:(PDFPage *)pdfPage {
    
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
	
    CGContextSaveGState(context);
    
    // smooth graphics when anti-aliasing
    [[NSGraphicsContext currentContext] setImageInterpolation:[[NSUserDefaults standardUserDefaults] boolForKey:SKShouldAntiAliasKey] ? NSImageInterpolationHigh : NSImageInterpolationDefault];
    
    // Let PDFView do most of the hard work.
    [super drawPage: pdfPage];
	
    [self transformCGContext:context forPage:pdfPage];
    SKCGContextSetDefaultRGBColorSpace(context);
    
    if (bezierPaths && pathPageIndex == [pdfPage pageIndex]) {
        [NSGraphicsContext saveGraphicsState];
        [(pathColor ?: [[NSUserDefaults standardUserDefaults] colorForKey:SKInkNoteColorKey]) setStroke];
        [bezierPaths makeObjectsPerformSelector:@selector(stroke)];
        [NSGraphicsContext restoreGraphicsState];
    }
    
    if ([[activeAnnotation page] isEqual:pdfPage]) {
        BOOL isLink = [activeAnnotation isLink];
        CGFloat lineWidth = isLink ? 2.0 : 1.0;
        NSRect bounds = [activeAnnotation bounds];
        NSRect rect = NSInsetRect(NSIntegralRect(bounds), 0.5 * lineWidth, 0.5 * lineWidth);
        if (isLink) {
            CGMutablePathRef path = SKCGCreatePathWithRoundRectInRect(NSRectToCGRect(rect), SKFloor(0.3 * NSHeight(rect)));
            CGFloat color[4] = { 0.0, 0.0, 0.0, 0.1 };
            CGContextSetFillColor(context, color);
            CGContextBeginPath(context);
            CGContextAddPath(context, path);
            CGContextFillPath(context);
            color[3] = 0.5;
            CGContextSetStrokeColor(context, color);
            CGContextSetLineWidth(context, lineWidth);
            CGContextAddPath(context, path);
            CGContextStrokePath(context);
            CGPathRelease(path);
        } else if ([[activeAnnotation type] isEqualToString:SKNLineString]) {
            NSPoint point = SKAddPoints(bounds.origin, [(PDFAnnotationLine *)activeAnnotation startPoint]);
            SKCGContextDrawGrabHandle(context, NSPointToCGPoint(point), 4.0, dragMask == BDSKMinXEdgeMask);
            point = SKAddPoints(bounds.origin, [(PDFAnnotationLine *)activeAnnotation endPoint]);
            SKCGContextDrawGrabHandle(context, NSPointToCGPoint(point), 4.0, dragMask == BDSKMaxXEdgeMask);
        } else if (editField == nil) {
            CGFloat color[4] = { 0.278477, 0.467857, 0.810941, 1.0 };
            CGContextSetStrokeColor(context, color);
            CGContextStrokeRectWithWidth(context, NSRectToCGRect(rect), lineWidth);
            if ([activeAnnotation isResizable])
                SKCGContextDrawGrabHandles(context, NSRectToCGRect(bounds), 4.0, dragMask);
        }
    }
    
    if ([[highlightAnnotation page] isEqual:pdfPage]) {
        CGFloat color[4] = { 0.0, 0.0, 0.0, 1.0 };
        NSRect bounds = [highlightAnnotation bounds];
        NSRect rect = NSInsetRect(NSIntegralRect(bounds), 0.5, 0.5);
        CGContextSetStrokeColor(context, color);
        CGContextStrokeRectWithWidth(context, NSRectToCGRect(rect), 1.0);
    }
    
    if (readingBar) {
        NSRect rect = [readingBar currentBoundsForBox:[self displayBox]];
        BOOL invert = [[NSUserDefaults standardUserDefaults] boolForKey:SKReadingBarInvertKey];
        NSColor *nsColor = [[NSUserDefaults standardUserDefaults] colorForKey:SKReadingBarColorKey];
        CGFloat color[4] = { [nsColor redComponent], [nsColor greenComponent], [nsColor blueComponent], [nsColor alphaComponent] };
        
        CGContextSetFillColor(context, color);
        
        if (invert) {
            NSRect bounds = [pdfPage boundsForBox:[self displayBox]];
            if (NSEqualRects(rect, NSZeroRect) || [[readingBar page] isEqual:pdfPage] == NO) {
                CGContextFillRect(context, NSRectToCGRect(bounds));
            } else {
                NSRect outRect, ignored;
                NSDivideRect(bounds, &outRect, &ignored, NSMaxY(bounds) - NSMaxY(rect), NSMaxYEdge);
                CGContextFillRect(context, NSRectToCGRect(outRect));
                NSDivideRect(bounds, &outRect, &ignored, NSMinY(rect) - NSMinY(bounds), NSMinYEdge);
                CGContextFillRect(context, NSRectToCGRect(outRect));
            }
        } else if ([[readingBar page] isEqual:pdfPage]) {
            CGContextSetBlendMode(context, kCGBlendModeMultiply);        
            CGContextFillRect(context, NSRectToCGRect(rect));
        }
    }
    
    if (toolMode != SKSelectToolMode && NSIsEmptyRect(selectionRect) == NO) {
        NSRect rect = NSInsetRect([self convertRect:selectionRect toPage:pdfPage], 0.5, 0.5);
        CGFloat color[4] = { 0.0, 0.0, 0.0, 1.0 };
        CGContextSetStrokeColor(context, color);
        CGContextStrokeRect(context, NSRectToCGRect(rect));
    } else if (toolMode == SKSelectToolMode && (didSelect || NSEqualRects(selectionRect, NSZeroRect) == NO)) {
        NSRect bounds = [pdfPage boundsForBox:[self displayBox]];
        CGFloat color[4] = { 0.0, 0.0, 0.0, 0.6 };
        CGFloat radius = 4.0 / [self scaleFactor];
        CGContextBeginPath(context);
        CGContextAddRect(context, NSRectToCGRect(bounds));
        CGContextAddRect(context, NSRectToCGRect(selectionRect));
        CGContextSetFillColor(context, color);
        CGContextEOFillPath(context);
        if ([pdfPage pageIndex] != selectionPageIndex) {
            color[3] = 0.3;
            CGContextSetFillColor(context, color);
            CGContextFillRect(context, NSRectToCGRect(selectionRect));
        }
        SKCGContextDrawGrabHandles(context, NSRectToCGRect(selectionRect), radius, 0);
    }
    
    CGContextRestoreGState(context);
}

- (void)setNeedsDisplayInRect:(NSRect)rect ofPage:(PDFPage *)page {
    NSRect aRect = [self convertRect:rect fromPage:page];
    CGFloat scale = [self scaleFactor];
	CGFloat maxX = SKCeil(NSMaxX(aRect) + scale);
	CGFloat maxY = SKCeil(NSMaxY(aRect) + scale);
	CGFloat minX = SKFloor(NSMinX(aRect) - scale);
	CGFloat minY = SKFloor(NSMinY(aRect) - scale);
	
    aRect = NSIntersectionRect([self bounds], NSMakeRect(minX, minY, maxX - minX, maxY - minY));
    if (NSIsEmptyRect(aRect) == NO)
        [self setNeedsDisplayInRect:aRect];
}

- (void)setNeedsDisplayForAnnotation:(PDFAnnotation *)annotation {
    [self setNeedsDisplayInRect:[annotation displayRectForBounds:[annotation bounds]] ofPage:[annotation page]];
}

#pragma mark Accessors

- (void)setDocument:(PDFDocument *)document {
    [readingBar release];
    readingBar = nil;
    selectionRect = NSZeroRect;
    selectionPageIndex = NSNotFound;
    [self removePDFToolTipRects];
    [accessibilityChildren release];
    accessibilityChildren = nil;
    [[SKPDFToolTipWindow sharedToolTipWindow] orderOut:self];
    [super setDocument:document];
    [self resetPDFToolTipRects];
}

- (SKToolMode)toolMode {
    return toolMode;
}

- (void)setToolMode:(SKToolMode)newToolMode {
    if (toolMode != newToolMode) {
        if ((toolMode == SKTextToolMode || toolMode == SKNoteToolMode) && newToolMode != SKTextToolMode && newToolMode != SKNoteToolMode) {
            if (activeAnnotation)
                [self setActiveAnnotation:nil];
            if ([self currentSelection])
                [self setCurrentSelection:nil];
        } else if (toolMode == SKSelectToolMode && NSEqualRects(selectionRect, NSZeroRect) == NO) {
            [self setCurrentSelectionRect:NSZeroRect];
            [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewSelectionChangedNotification object:self];
        }
        
        toolMode = newToolMode;
        [[NSUserDefaults standardUserDefaults] setInteger:toolMode forKey:SKLastToolModeKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewToolModeChangedNotification object:self];
        [self doUpdateCursor];
    }
}

- (SKNoteType)annotationMode {
    return annotationMode;
}

- (void)setAnnotationMode:(SKNoteType)newAnnotationMode {
    if (annotationMode != newAnnotationMode) {
        annotationMode = newAnnotationMode;
        [[NSUserDefaults standardUserDefaults] setInteger:annotationMode forKey:SKLastAnnotationModeKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewAnnotationModeChangedNotification object:self];
        // hack to make sure we update the cursor
        [[self window] makeFirstResponder:self];
    }
}

- (SKInteractionMode)interactionMode {
    return interactionMode;
}

- (void)setInteractionMode:(SKInteractionMode)newInteractionMode screen:(NSScreen *)screen {
    if (interactionMode != newInteractionMode) {
        if (interactionMode == SKPresentationMode && [[self documentView] isHidden])
            [[self documentView] setHidden:NO];
        interactionMode = newInteractionMode;
        if (interactionMode == SKNormalMode)
            [self disableNavigation];
        else
            [self enableNavigationForScreen:screen];
    }
}

- (PDFAnnotation *)activeAnnotation {
	return activeAnnotation;
}

- (void)setActiveAnnotation:(PDFAnnotation *)newAnnotation {
	BOOL changed = newAnnotation != activeAnnotation;
	
	// Will need to redraw old active anotation.
	if (activeAnnotation != nil) {
		[self setNeedsDisplayForAnnotation:activeAnnotation];
        if (changed && [self isEditing])
            [self commitEditing];
	}
    
	// Assign.
	if (newAnnotation) {
		activeAnnotation = newAnnotation;
		
		// Force redisplay.
		[self setNeedsDisplayForAnnotation:activeAnnotation];
	} else {
		activeAnnotation = nil;
	}
	
	if (changed) {
		[[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewActiveAnnotationDidChangeNotification object:self userInfo:nil];
        NSAccessibilityPostNotification(NSAccessibilityUnignoredAncestor([self documentView]), NSAccessibilityFocusedUIElementChangedNotification);
    }
}

- (BOOL)isEditing {
    return editField != nil;
}

- (void)setDisplayMode:(PDFDisplayMode)mode {
    if (mode != [self displayMode]) {
        PDFPage *page = [self currentPage];
        [super setDisplayMode:mode];
        if (page && NSLocationInRange([page pageIndex], [self visiblePageIndexRange]) == NO)
            [self goToPage:page];
        [self relayoutEditField];
        [accessibilityChildren release];
        accessibilityChildren = nil;
        [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewDisplayModeChangedNotification object:self userInfo:nil];
    }
}

- (void)setDisplaysAsBook:(BOOL)asBook {
    if (asBook != [self displaysAsBook]) {
        [super setDisplaysAsBook:asBook];
        [self relayoutEditField];
        [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewDisplayAsBookChangedNotification object:self userInfo:nil];
    }
}

- (void)setDisplayBox:(PDFDisplayBox)displayBox {
    if (displayBox != [self displayBox]) {
        [super setDisplayBox:displayBox];
        [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewDisplayBoxChangedNotification object:self userInfo:nil];
    }
}

- (NSRect)currentSelectionRect {
    if (toolMode == SKSelectToolMode)
        return selectionRect;
    return NSZeroRect;
}

- (void)setCurrentSelectionRect:(NSRect)rect {
    if (toolMode == SKSelectToolMode) {
        if (NSEqualRects(selectionRect, rect) == NO)
            [self setNeedsDisplay:YES];
        if (NSIsEmptyRect(rect)) {
            selectionRect = NSZeroRect;
            selectionPageIndex = NSNotFound;
        } else {
            selectionRect = rect;
            if (selectionPageIndex == NSNotFound)
                selectionPageIndex = [[self currentPage] pageIndex];
        }
    }
}

- (PDFPage *)currentSelectionPage {
    return selectionPageIndex == NSNotFound ? nil : [[self document] pageAtIndex:selectionPageIndex];
}

- (void)setCurrentSelectionPage:(PDFPage *)page {
    if (toolMode == SKSelectToolMode) {
        if (selectionPageIndex != [page pageIndex] || (page == nil && selectionPageIndex != NSNotFound))
            [self setNeedsDisplay:YES];
        if (page == nil) {
            selectionPageIndex = NSNotFound;
            selectionRect = NSZeroRect;
        } else {
            selectionPageIndex = [page pageIndex];
            if (NSIsEmptyRect(selectionRect))
                selectionRect = [page boundsForBox:kPDFDisplayBoxCropBox];
        }
    }
}

- (CGFloat)currentMagnification {
    return magnification;
}

- (BOOL)hideNotes {
    return hideNotes;
}

- (void)setHideNotes:(BOOL)flag {
    if (hideNotes != flag) {
        hideNotes = flag;
        if (hideNotes)
            [self setActiveAnnotation:nil];
        [self setNeedsDisplay:YES];
    }
}

- (SKTransitionController * )transitionController {
    if (transitionController == nil)
        transitionController = [[SKTransitionController alloc] initWithView:self];
    return transitionController;
}

- (SKTypeSelectHelper *)typeSelectHelper {
    return typeSelectHelper;
}

- (void)setTypeSelectHelper:(SKTypeSelectHelper *)newTypeSelectHelper {
    if (typeSelectHelper != newTypeSelectHelper) {
        [typeSelectHelper release];
        typeSelectHelper = [newTypeSelectHelper retain];
    }
}

#pragma mark Reading bar

- (BOOL)hasReadingBar {
    return readingBar != nil;
}

- (SKReadingBar *)readingBar {
    return readingBar;
}

- (void)toggleReadingBar {
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:[readingBar page], SKPDFViewOldPageKey, nil];
    if (readingBar) {
        [readingBar release];
        readingBar = nil;
    } else {
        readingBar = [[SKReadingBar alloc] initWithPage:[self currentPage]];
        [readingBar setNumberOfLines:MAX(1, [[NSUserDefaults standardUserDefaults] integerForKey:SKReadingBarNumberOfLinesKey])];
        [readingBar goToNextLine];
        [self scrollRect:NSInsetRect([readingBar currentBounds], 0.0, -20.0) inPageToVisible:[readingBar page]];
        [userInfo setValue:[readingBar page] forKey:SKPDFViewNewPageKey];
    }
    [self setNeedsDisplay:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewReadingBarDidChangeNotification object:self userInfo:userInfo];
}

#pragma mark Actions

- (void)animateTransitionForNextPage:(BOOL)next {
    NSUInteger idx = [[self currentPage] pageIndex];
    NSUInteger toIdx = (next ? idx + 1 : idx - 1);
    BOOL shouldAnimate = [transitionController pageTransitions] || [[[self currentPage] label] isEqualToString:[[[self document] pageAtIndex:toIdx] label]] == NO;
    NSRect rect;
    if (shouldAnimate) {
        rect = [self convertRect:[[self currentPage] boundsForBox:[self displayBox]] fromPage:[self currentPage]];
        [[self transitionController] prepareAnimationForRect:rect from:idx to:toIdx];
    }
    if (next)
        [super goToNextPage:self];
    else
        [super goToPreviousPage:self];
    if (shouldAnimate) {
        rect = [self convertRect:[[self currentPage] boundsForBox:[self displayBox]] fromPage:[self currentPage]];
        [[self transitionController] animateForRect:rect forward:next];
        if (interactionMode == SKPresentationMode)
            [self doAutohide:YES];
    }
}

- (IBAction)goToNextPage:(id)sender {
    if (interactionMode == SKPresentationMode && [self canGoToNextPage] && transitionController &&
        ([transitionController transitionStyle] != SKNoTransition || [transitionController pageTransitions]))
        [self animateTransitionForNextPage:YES];
    else
        [super goToNextPage:sender];
}

- (IBAction)goToPreviousPage:(id)sender {
    if (interactionMode == SKPresentationMode && [self canGoToPreviousPage] && transitionController &&
        ([transitionController transitionStyle] != SKNoTransition || [transitionController pageTransitions]))
        [self animateTransitionForNextPage:NO];
    else
        [super goToPreviousPage:sender];
}

- (IBAction)printDocument:(id)sender{
    id document = [[[self window] windowController] document];
    if ([document respondsToSelector:_cmd])
        [document printDocument:sender];
    else if ([[SKPDFView superclass] instancesRespondToSelector:_cmd])
        [(id)super printDocument:sender];
}

- (IBAction)delete:(id)sender
{
	if ([activeAnnotation isSkimNote])
        [self removeActiveAnnotation:self];
    else
        NSBeep();
}

- (IBAction)copy:(id)sender
{
    if ([[self document] allowsCopying]) {
        [super copy:sender];
    } else {
        NSString *string = [[self currentSelection] string];
        if ([string length]) {
            NSPasteboard *pboard = [NSPasteboard generalPasteboard];
            NSAttributedString *attrString = [[self currentSelection] attributedString];
            
            [pboard declareTypes:[NSArray arrayWithObjects:NSStringPboardType, NSRTFPboardType, nil] owner:nil];
            [pboard setString:string forType:NSStringPboardType];
            [pboard setData:[attrString RTFFromRange:NSMakeRange(0, [attrString length]) documentAttributes:nil] forType:NSRTFPboardType];
        }
    }
    
    NSMutableArray *types = [NSMutableArray array];
    NSData *noteData = nil;
    NSData *pdfData = nil;
    NSData *tiffData = nil;
    
    if ([self hideNotes] == NO && [activeAnnotation isSkimNote] && [activeAnnotation isMovable]) {
        if (noteData = [NSKeyedArchiver archivedDataWithRootObject:[activeAnnotation SkimNoteProperties]])
            [types addObject:SKSkimNotePboardType];
    }
    
    if (toolMode == SKSelectToolMode && NSIsEmptyRect(selectionRect) == NO && selectionPageIndex != NSNotFound) {
        NSRect selRect = NSIntegralRect(selectionRect);
        PDFPage *page = [self currentSelectionPage];
        
        if (pdfData = [page PDFDataForRect:selRect])
            [types addObject:NSPDFPboardType];
        if (tiffData = [page TIFFDataForRect:selRect])
            [types addObject:NSTIFFPboardType];
        
        /*
         Possible hidden default?  Alternate way of getting a bitmap rep; this varies resolution with zoom level, which is very useful if you want to copy a single figure or equation for a non-PDF-capable program.  The first copy: action has some odd behavior, though (view moves).  Preview produces a fixed resolution bitmap for a given selection area regardless of zoom.
         
        sourceRect = [self convertRect:selectionRect fromPage:[self currentPage]];
        NSBitmapImageRep *imageRep = [self bitmapImageRepForCachingDisplayInRect:sourceRect];
        [self cacheDisplayInRect:sourceRect toBitmapImageRep:imageRep];
        tiffData = [imageRep TIFFRepresentation];
         */
    }
    
    NSPasteboard *pboard = [NSPasteboard generalPasteboard];
    
    if ([types count]) {
        if ([[self currentSelection] hasCharacters])
            [pboard addTypes:types owner:nil];
        else
            [pboard declareTypes:types owner:nil];
    }
    
    if (noteData)
        [pboard setData:noteData forType:SKSkimNotePboardType];
    if (pdfData)
        [pboard setData:pdfData forType:NSPDFPboardType];
    if (tiffData)
        [pboard setData:tiffData forType:NSTIFFPboardType];
}

- (void)pasteNote:(BOOL)preferNote plainText:(BOOL)isPlainText {
    if ([self hideNotes]) {
        NSBeep();
        return;
    }
    
    NSMutableArray *pboardTypes = [NSMutableArray arrayWithObjects:NSStringPboardType, nil];
    if (isPlainText || preferNote)
        [pboardTypes addObject:NSRTFPboardType];
    if (isPlainText == NO)
        [pboardTypes addObject:SKSkimNotePboardType];
    
    NSPasteboard *pboard = [NSPasteboard generalPasteboard];
    NSString *pboardType = [pboard availableTypeFromArray:pboardTypes];
    if (pboardType == nil) {
        NSBeep();
        return;
    }
    
    PDFAnnotation *newAnnotation;
    PDFPage *page;
    
    if ([pboardType isEqualToString:SKSkimNotePboardType]) {
    
        NSData *data = [pboard dataForType:SKSkimNotePboardType];
        NSDictionary *note = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        NSRect bounds;
        
        newAnnotation = [[[PDFAnnotation alloc] initSkimNoteWithProperties:note] autorelease];
        bounds = [newAnnotation bounds];
        page = [self currentPage];
        bounds = SKConstrainRect(bounds, [page boundsForBox:[self displayBox]]);
        
        [newAnnotation setBounds:bounds];
        
    } else {
        
        NSAssert([pboardType isEqualToString:NSStringPboardType] || (isPlainText && [pboardType isEqualToString:NSRTFPboardType]), @"inconsistent pasteboard type");
        
		// First try the current mouse position
        NSPoint center = [self convertPoint:[[self window] mouseLocationOutsideOfEventStream] fromView:nil];
        
        // if the mouse was in the toolbar and there is a page below the toolbar, we get a point outside of the visible rect
        page = NSMouseInRect(center, [[self documentView] convertRect:[[self documentView] visibleRect] toView:self], [self isFlipped]) ? [self pageForPoint:center nearest:NO] : nil;
        
        if (page == nil) {
            // Get center of the PDFView.
            NSRect viewFrame = [self frame];
            center = SKCenterPoint(viewFrame);
            page = [self pageForPoint: center nearest: YES];
        }
		
		// Convert to "page space".
		center = SKIntegralPoint([self convertPoint: center toPage: page]);
        
        CGFloat defaultWidth = [[NSUserDefaults standardUserDefaults] floatForKey:SKDefaultNoteWidthKey];
        CGFloat defaultHeight = [[NSUserDefaults standardUserDefaults] floatForKey:SKDefaultNoteHeightKey];
        NSSize defaultSize = preferNote ? SKNPDFAnnotationNoteSize : ([page rotation] % 180 == 0) ? NSMakeSize(defaultWidth, defaultHeight) : NSMakeSize(defaultHeight, defaultWidth);
        NSRect bounds = SKRectFromCenterAndSize(center, defaultSize);
        
        bounds = SKConstrainRect(bounds, [page boundsForBox:[self displayBox]]);
        
        if (preferNote) {
            newAnnotation = [[[SKNPDFAnnotationNote alloc] initSkimNoteWithBounds:bounds] autorelease];
            NSMutableAttributedString *attrString = nil;
            if ([pboardType isEqualToString:NSStringPboardType])
                attrString = [[[NSMutableAttributedString alloc] initWithString:[pboard stringForType:NSStringPboardType]] autorelease];
            else if ([pboardType isEqualToString:NSRTFPboardType])
                attrString = [[[NSMutableAttributedString alloc] initWithRTF:[pboard dataForType:NSRTFPboardType] documentAttributes:NULL] autorelease];
            if (isPlainText || [pboardType isEqualToString:NSStringPboardType]) {
                NSString *fontName = [[NSUserDefaults standardUserDefaults] stringForKey:SKAnchoredNoteFontNameKey];
                CGFloat fontSize = [[NSUserDefaults standardUserDefaults] floatForKey:SKAnchoredNoteFontSizeKey];
                NSFont *font = fontName ? [NSFont fontWithName:fontName size:fontSize] : [NSFont userFontOfSize:fontSize];
                [attrString setAttributes:[NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, nil] range:NSMakeRange(0, [attrString length])];
            }
            [(SKNPDFAnnotationNote *)newAnnotation setText:attrString];
        } else {
            newAnnotation = [[[PDFAnnotationFreeText alloc] initSkimNoteWithBounds:bounds] autorelease];
            [newAnnotation setString:[pboard stringForType:NSStringPboardType]];
        }
        
    }
    
    [self addAnnotation:newAnnotation toPage:page];
    [[self undoManager] setActionName:NSLocalizedString(@"Add Note", @"Undo action name")];

    [self setActiveAnnotation:newAnnotation];
}

- (IBAction)paste:(id)sender {
    [self pasteNote:NO plainText:NO];
}

- (IBAction)alternatePaste:(id)sender {
    [self pasteNote:YES plainText:NO];
}

- (IBAction)pasteAsPlainText:(id)sender {
    [self pasteNote:YES plainText:YES];
}

- (IBAction)cut:(id)sender
{
	if ([self hideNotes] == NO && [activeAnnotation isSkimNote]) {
        [self copy:sender];
        [self delete:sender];
    } else
        NSBeep();
}

- (IBAction)selectAll:(id)sender {
    if (toolMode == SKTextToolMode)
        [super selectAll:sender];
}

- (IBAction)deselectAll:(id)sender {
    [self setCurrentSelection:nil];
}

- (IBAction)autoSelectContent:(id)sender {
    if (toolMode == SKSelectToolMode) {
        PDFPage *page = [self currentPage];
        selectionRect = NSIntersectionRect(NSUnionRect([page foregroundBox], selectionRect), [page boundsForBox:[self displayBox]]);
        selectionPageIndex = [page pageIndex];
        [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewSelectionChangedNotification object:self];
        [self setNeedsDisplay:YES];
    }
}

- (void)changeToolMode:(id)sender {
    [self setToolMode:[sender tag]];
}

- (void)changeAnnotationMode:(id)sender {
    [self setToolMode:SKNoteToolMode];
    [self setAnnotationMode:[sender tag]];
}

- (void)showColorsForThisAnnotation:(id)sender {
    PDFAnnotation *annotation = [sender representedObject];
    if (annotation)
        [self setActiveAnnotation:annotation];
    [[NSColorPanel sharedColorPanel] orderFront:sender];
}

- (void)showLinesForThisAnnotation:(id)sender {
    PDFAnnotation *annotation = [sender representedObject];
    if (annotation)
        [self setActiveAnnotation:annotation];
    [[[SKLineInspector sharedLineInspector] window] orderFront:sender];
}

- (void)showFontsForThisAnnotation:(id)sender {
    PDFAnnotation *annotation = [sender representedObject];
    if (annotation)
        [self setActiveAnnotation:annotation];
    [[NSFontManager sharedFontManager] orderFrontFontPanel:sender];
}

#pragma mark Event Handling

- (void)keyDown:(NSEvent *)theEvent
{
    unichar eventChar = [theEvent firstCharacter];
	NSUInteger modifiers = [theEvent standardModifierFlags];
    
    if (interactionMode == SKPresentationMode) {
        // Presentation mode
        if ([[[self documentView] enclosingScrollView] hasHorizontalScroller] == NO && 
            (eventChar == NSRightArrowFunctionKey) &&  (modifiers == 0)) {
            [self goToNextPage:self];
        } else if ([[[self documentView] enclosingScrollView] hasHorizontalScroller] == NO && 
                   (eventChar == NSLeftArrowFunctionKey) &&  (modifiers == 0)) {
            [self goToPreviousPage:self];
        } else if ((eventChar == 'p') && (modifiers == 0)) {
            [(SKMainWindowController *)[[self window] windowController] toggleLeftSidePane:self];
        } else if ((eventChar == 'a') && (modifiers == 0)) {
            [(SKMainWindowController *)[[self window] windowController] toggleAutoActualSize:self];
        } else if ((eventChar == 'b') && (modifiers == 0)) {
            NSView *documentView = [self documentView];
            [documentView setHidden:[documentView isHidden] == NO];
        } else {
            [super keyDown:theEvent];
        }
    } else {
        // Normal or fullscreen mode
        BOOL isLeftRightArrow = eventChar == NSRightArrowFunctionKey || eventChar == NSLeftArrowFunctionKey;
        BOOL isUpDownArrow = eventChar == NSUpArrowFunctionKey || eventChar == NSDownArrowFunctionKey;
        BOOL isArrow = isLeftRightArrow || isUpDownArrow;
        
        if ((eventChar == NSDeleteCharacter || eventChar == NSDeleteFunctionKey) &&
            (modifiers == 0)) {
            [self delete:self];
        } else if (([self toolMode] == SKTextToolMode || [self toolMode] == SKNoteToolMode) && activeAnnotation && [self isEditing] == NO && 
                   (eventChar == NSEnterCharacter || eventChar == NSFormFeedCharacter || eventChar == NSNewlineCharacter || eventChar == NSCarriageReturnCharacter) &&
                   (modifiers == 0)) {
            [self editActiveAnnotation:self];
        } else if (([self toolMode] == SKTextToolMode || [self toolMode] == SKNoteToolMode) && 
                   (eventChar == NSTabCharacter) && (modifiers == NSAlternateKeyMask)) {
            [self selectNextActiveAnnotation:self];
        } else if (([self toolMode] == SKTextToolMode || [self toolMode] == SKNoteToolMode) && 
                   (eventChar == SKEscapeCharacter) && (modifiers == NSAlternateKeyMask)) {
            [self setActiveAnnotation:nil];
        // backtab is a bit inconsistent, it seems Shift+Tab gives a Shift-BackTab key event, I would have expected either Shift-Tab (as for the raw event) or BackTab (as for most shift-modified keys)
        } else if (([self toolMode] == SKTextToolMode || [self toolMode] == SKNoteToolMode) && 
                   (((eventChar == NSBackTabCharacter) && ((modifiers & ~NSShiftKeyMask) == NSAlternateKeyMask)) || 
                    ((eventChar == NSTabCharacter) && (modifiers == (NSAlternateKeyMask | NSShiftKeyMask))))) {
            [self selectPreviousActiveAnnotation:self];
        } else if ([self hasReadingBar] && isArrow && (modifiers == moveReadingBarModifiers)) {
            [self doMoveReadingBarForKey:eventChar];
        } else if ([self hasReadingBar] && isUpDownArrow && (modifiers == resizeReadingBarModifiers)) {
            [self doResizeReadingBarForKey:eventChar];
        } else if (isLeftRightArrow && (modifiers == (NSCommandKeyMask | NSAlternateKeyMask))) {
            [self setToolMode:(toolMode + (eventChar == NSRightArrowFunctionKey ? 1 : TOOL_MODE_COUNT - 1)) % TOOL_MODE_COUNT];
        } else if (isUpDownArrow && (modifiers == (NSCommandKeyMask | NSAlternateKeyMask))) {
            [self setAnnotationMode:(annotationMode + (eventChar == NSDownArrowFunctionKey ? 1 : ANNOTATION_MODE_COUNT - 1)) % ANNOTATION_MODE_COUNT];
        } else if ([activeAnnotation isMovable] && isArrow && ((modifiers & ~NSShiftKeyMask) == 0)) {
            [self doMoveActiveAnnotationForKey:eventChar byAmount:(modifiers & NSShiftKeyMask) ? 10.0 : 1.0];
        } else if ([activeAnnotation isResizable] && isArrow && (modifiers == (NSAlternateKeyMask | NSControlKeyMask) || modifiers == (NSShiftKeyMask | NSControlKeyMask))) {
            [self doResizeActiveAnnotationForKey:eventChar byAmount:(modifiers & NSShiftKeyMask) ? 10.0 : 1.0];
        } else if ([self toolMode] == SKNoteToolMode && (eventChar == 't') && (modifiers == 0)) {
            [self setAnnotationMode:SKFreeTextNote];
        } else if ([self toolMode] == SKNoteToolMode && (eventChar == 'n') && (modifiers == 0)) {
            [self setAnnotationMode:SKAnchoredNote];
        } else if ([self toolMode] == SKNoteToolMode && (eventChar == 'c') && (modifiers == 0)) {
            [self setAnnotationMode:SKCircleNote];
        } else if ([self toolMode] == SKNoteToolMode && (eventChar == 'b') && (modifiers == 0)) {
            [self setAnnotationMode:SKSquareNote];
        } else if ([self toolMode] == SKNoteToolMode && (eventChar == 'h') && (modifiers == 0)) {
            [self setAnnotationMode:SKHighlightNote];
        } else if ([self toolMode] == SKNoteToolMode && (eventChar == 'u') && (modifiers == 0)) {
            [self setAnnotationMode:SKUnderlineNote];
        } else if ([self toolMode] == SKNoteToolMode && (eventChar == 's') && (modifiers == 0)) {
            [self setAnnotationMode:SKStrikeOutNote];
        } else if ([self toolMode] == SKNoteToolMode && (eventChar == 'l') && (modifiers == 0)) {
            [self setAnnotationMode:SKLineNote];
        } else if ([self toolMode] == SKNoteToolMode && (eventChar == 'f') && (modifiers == 0)) {
            [self setAnnotationMode:SKInkNote];
        } else if ([typeSelectHelper processKeyDownEvent:theEvent] == NO) {
            [super keyDown:theEvent];
        }
        
    }
}

- (void)mouseDown:(NSEvent *)theEvent{
    if ([activeAnnotation isLink])
        [self setActiveAnnotation:nil];
    
    // 10.6 does not automatically make us firstResponder, that's annoying
    [[self window] makeFirstResponder:self];
    
    mouseDownLoc = [theEvent locationInWindow];
	NSUInteger modifiers = [theEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask;
    
    if ([[self document] isLocked]) {
        [super mouseDown:theEvent];
        return;
    } else if (interactionMode == SKPresentationMode) {
        if (hideNotes == NO && ([theEvent subtype] == NSTabletProximityEventSubtype || [theEvent subtype] == NSTabletPointEventSubtype)) {
            [self doDrawFreehandNoteWithEvent:theEvent];
            [self setActiveAnnotation:nil];
        } else if ([self areaOfInterestForMouse:theEvent] & kPDFLinkArea) {
            [super mouseDown:theEvent];
        } else {
            [self goToNextPage:self];
            // Eat up drag events because we don't want to select
            while (YES) {
                if ([[[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask] type] == NSLeftMouseUp)
                    break;
            }
        }
        return;
    }
    
    if (modifiers & NSCommandKeyMask) {
        if (modifiers & NSShiftKeyMask)
            [self doPdfsyncWithEvent:theEvent];
        else
            [self doSelectSnapshotWithEvent:theEvent];
    } else {
        PDFAreaOfInterest area = [self areaOfInterestForMouse:theEvent];
        NSPoint p = mouseDownLoc;
        p = [self convertPoint:p fromView:nil];
        PDFPage *page = [self pageForPoint:p nearest:YES];
        p = [self convertPoint:p toPage:page];
        
        if (readingBar && (area == kPDFNoArea || (toolMode != SKSelectToolMode && toolMode != SKMagnifyToolMode)) && [[readingBar page] isEqual:page] && p.y >= NSMinY([readingBar currentBounds]) && p.y <= NSMaxY([readingBar currentBounds])) {
            if (p.y < NSMinY([readingBar currentBounds]) + 3.0)
                [self doResizeReadingBarWithEvent:theEvent];
            else
                [self doDragReadingBarWithEvent:theEvent];
        } else if (area == kPDFNoArea) {
            [self doDragWithEvent:theEvent];
        } else {
            
            switch (toolMode) {
                case SKTextToolMode:
                case SKNoteToolMode:
                    if ([self doSelectAnnotationWithEvent:theEvent] == NO &&
                        (toolMode == SKTextToolMode || hideNotes || annotationMode == SKHighlightNote || annotationMode == SKUnderlineNote || annotationMode == SKStrikeOutNote)) {
                        if (area == kPDFPageArea && [theEvent standardModifierFlags] == 0 && [[page selectionForRect:NSMakeRect(p.x - 40.0, p.y - 50.0, 80.0, 100.0)] string] == nil) {
                            [self doDragWithEvent:theEvent];
                        } else if (nil == activeAnnotation && mouseDownInAnnotation) {
                            [self doSelectTextWithEvent:theEvent];
                            mouseDownInAnnotation = NO; 	 
                        } else {
                            [super mouseDown:theEvent];
                            if (toolMode == SKNoteToolMode && hideNotes == NO && (annotationMode == SKHighlightNote || annotationMode == SKUnderlineNote || annotationMode == SKStrikeOutNote) && [[self currentSelection] hasCharacters]) {
                                [self addAnnotationWithType:annotationMode];
                                [self setCurrentSelection:nil];
                            }
                        }
                    }
                    break;
                case SKMoveToolMode:
                    if (area & kPDFLinkArea)
                        [super mouseDown:theEvent];
                    else
                        [self doDragWithEvent:theEvent];	
                    break;
                case SKSelectToolMode:
                    [self doSelectWithEvent:theEvent];
                    break;
                case SKMagnifyToolMode:
                    [self doMagnifyWithEvent:theEvent];
                    break;
            }
        }
    }
}

- (void)mouseUp:(NSEvent *)theEvent{
    if ([[self document] isLocked]) {
        [super mouseUp:theEvent];
        return;
    }
    
    switch (toolMode) {
        case SKTextToolMode:
        case SKNoteToolMode:
            if (mouseDownInAnnotation) {
                if (nil == activeAnnotation && NSIsEmptyRect(selectionRect) == NO) { 	 
                     [self setNeedsDisplayInRect:selectionRect]; 	 
                     selectionRect = NSZeroRect;
                     selectionPageIndex = NSNotFound;	 
                     [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewSelectionChangedNotification object:self]; 	 
                 } else if ([activeAnnotation isLink]) { 	 
                     NSPoint p = [self convertPoint:[theEvent locationInWindow] fromView:nil]; 	 
                     PDFPage *page = [self pageForPoint:p nearest:NO]; 	 
                     if (page && NSPointInRect([self convertPoint:p toPage:page], [activeAnnotation bounds])) 	 
                         [self editActiveAnnotation:nil]; 	 
                     else 	 
                         [self setActiveAnnotation:nil]; 	 
                 } 	 
                 mouseDownInAnnotation = NO; 	 
                 dragMask = 0; 	 
            }
            if (toolMode == SKNoteToolMode && hideNotes == NO && (annotationMode == SKHighlightNote || annotationMode == SKUnderlineNote || annotationMode == SKStrikeOutNote) && [[self currentSelection] hasCharacters]) {
                [self addAnnotationWithType:annotationMode];
                [self setCurrentSelection:nil];
                [super mouseUp:theEvent]; // this may be necssary to clean up a selection rect
            } else
                [super mouseUp:theEvent];
            break;
        case SKMoveToolMode:
            [super mouseUp:theEvent];
            break;
        case SKMagnifyToolMode:
        case SKSelectToolMode:
            // shouldn't reach this
            break;
    }
}

- (void)mouseDragged:(NSEvent *)theEvent {
    if ([[self document] isLocked]) {
        [super mouseDragged:theEvent];
        return;
    }
    
    switch (toolMode) {
        case SKTextToolMode:
        case SKNoteToolMode:
            // is this check still necessary?
            if (nil == activeAnnotation)
                [super mouseDragged:theEvent];
            break;
        case SKMoveToolMode:
            [super mouseDragged:theEvent];
            break;
        case SKMagnifyToolMode:
        case SKSelectToolMode:
            // shouldn't reach this
            break;
    }
}

- (void)mouseMoved:(NSEvent *)theEvent {
    NSCursor *cursor = [self getCursorForEvent:theEvent];
    if (cursor)
        [cursor set];
    else
        [super mouseMoved:theEvent];
    
    if ([activeAnnotation isLink]) {
        [[SKPDFToolTipWindow sharedToolTipWindow] fadeOut];
        [self setActiveAnnotation:nil];
    }
    
    if ([navWindow isVisible] == NO) {
        if (navigationMode == SKNavigationEverywhere)
            [navWindow fadeIn];
        else if (navigationMode == SKNavigationBottom && [theEvent locationInWindow].y < 3.0)
            [self showNavWindow:YES];
    }
    if (navigationMode != SKNavigationNone || interactionMode == SKPresentationMode)
        [self doAutohide:YES];
}

- (void)flagsChanged:(NSEvent *)theEvent {
    [super flagsChanged:theEvent];
    [self doUpdateCursor];
}

- (NSMenu *)menuForEvent:(NSEvent *)theEvent {
    NSMenu *menu = [super menuForEvent:theEvent];
    NSMenu *submenu;
    NSMenuItem *item;
    
    // On Leopard the selection is automatically set. In some cases we never want a selection though.
    if ((interactionMode == SKPresentationMode) || (toolMode != SKTextToolMode && [self currentSelection])) {
        static NSSet *selectionActions = nil;
        if (selectionActions == nil)
            selectionActions = [[NSSet alloc] initWithObjects:@"_searchInSpotlight:", @"_searchInGoogle:", @"_searchInDictionary:", nil];
        [self setCurrentSelection:nil];
        while ([menu numberOfItems]) {
            item = [menu itemAtIndex:0];
            if ([item isSeparatorItem] || [self validateMenuItem:item] == NO || [selectionActions containsObject:NSStringFromSelector([item action])])
                [menu removeItemAtIndex:0];
            else
                break;
        }
    }
    
    if (interactionMode == SKPresentationMode)
        return menu;
    
    [menu insertItem:[NSMenuItem separatorItem] atIndex:0];
    
    submenu = [[NSMenu allocWithZone:[menu zone]] init];
    
    item = [submenu addItemWithTitle:NSLocalizedString(@"Text", @"Menu item title") action:@selector(changeToolMode:) keyEquivalent:@""];
    [item setTag:SKTextToolMode];
    [item setTarget:self];

    item = [submenu addItemWithTitle:NSLocalizedString(@"Scroll", @"Menu item title") action:@selector(changeToolMode:) keyEquivalent:@""];
    [item setTag:SKMoveToolMode];
    [item setTarget:self];

    item = [submenu addItemWithTitle:NSLocalizedString(@"Magnify", @"Menu item title") action:@selector(changeToolMode:) keyEquivalent:@""];
    [item setTag:SKMagnifyToolMode];
    [item setTarget:self];
    
    item = [submenu addItemWithTitle:NSLocalizedString(@"Select", @"Menu item title") action:@selector(changeToolMode:) keyEquivalent:@""];
    [item setTag:SKSelectToolMode];
    [item setTarget:self];
    
    [submenu addItem:[NSMenuItem separatorItem]];
    
    item = [submenu addItemWithTitle:NSLocalizedString(@"Text Note", @"Menu item title") action:@selector(changeAnnotationMode:) keyEquivalent:@""];
    [item setTag:SKFreeTextNote];
    [item setTarget:self];

    item = [submenu addItemWithTitle:NSLocalizedString(@"Anchored Note", @"Menu item title") action:@selector(changeAnnotationMode:) keyEquivalent:@""];
    [item setTag:SKAnchoredNote];
    [item setTarget:self];

    item = [submenu addItemWithTitle:NSLocalizedString(@"Circle", @"Menu item title") action:@selector(changeAnnotationMode:) keyEquivalent:@""];
    [item setTag:SKCircleNote];
    [item setTarget:self];
    
    item = [submenu addItemWithTitle:NSLocalizedString(@"Box", @"Menu item title") action:@selector(changeAnnotationMode:) keyEquivalent:@""];
    [item setTag:SKSquareNote];
    [item setTarget:self];
    
    item = [submenu addItemWithTitle:NSLocalizedString(@"Highlight", @"Menu item title") action:@selector(changeAnnotationMode:) keyEquivalent:@""];
    [item setTag:SKHighlightNote];
    [item setTarget:self];
    
    item = [submenu addItemWithTitle:NSLocalizedString(@"Underline", @"Menu item title") action:@selector(changeAnnotationMode:) keyEquivalent:@""];
    [item setTag:SKUnderlineNote];
    [item setTarget:self];
    
    item = [submenu addItemWithTitle:NSLocalizedString(@"Strike Out", @"Menu item title") action:@selector(changeAnnotationMode:) keyEquivalent:@""];
    [item setTag:SKStrikeOutNote];
    [item setTarget:self];
    
    item = [submenu addItemWithTitle:NSLocalizedString(@"Line", @"Menu item title") action:@selector(changeAnnotationMode:) keyEquivalent:@""];
    [item setTag:SKLineNote];
    [item setTarget:self];
    
    item = [submenu addItemWithTitle:NSLocalizedString(@"Freehand", @"Menu item title") action:@selector(changeAnnotationMode:) keyEquivalent:@""];
    [item setTag:SKInkNote];
    [item setTarget:self];
    
    item = [menu insertItemWithTitle:NSLocalizedString(@"Tools", @"Menu item title") action:NULL keyEquivalent:@"" atIndex:0];
    [item setSubmenu:submenu];
    [submenu release];
    
    [menu insertItem:[NSMenuItem separatorItem] atIndex:0];
    
    item = [menu insertItemWithTitle:NSLocalizedString(@"Take Snapshot", @"Menu item title") action:@selector(takeSnapshot:) keyEquivalent:@"" atIndex:0];
    [item setTarget:self];
    
    if (([self toolMode] == SKTextToolMode || [self toolMode] == SKNoteToolMode) && [self hideNotes] == NO) {
        
        [menu insertItem:[NSMenuItem separatorItem] atIndex:0];
        
        submenu = [[NSMenu allocWithZone:[menu zone]] init];
        
        item = [submenu addItemWithTitle:NSLocalizedString(@"Text Note", @"Menu item title") action:@selector(addAnnotation:) keyEquivalent:@""];
        [item setTag:SKFreeTextNote];
        [item setTarget:self];
        
        item = [submenu addItemWithTitle:NSLocalizedString(@"Anchored Note", @"Menu item title") action:@selector(addAnnotation:) keyEquivalent:@""];
        [item setTag:SKAnchoredNote];
        [item setTarget:self];
        
        item = [submenu addItemWithTitle:NSLocalizedString(@"Circle", @"Menu item title") action:@selector(addAnnotation:) keyEquivalent:@""];
        [item setTag:SKCircleNote];
        [item setTarget:self];
        
        item = [submenu addItemWithTitle:NSLocalizedString(@"Box", @"Menu item title") action:@selector(addAnnotation:) keyEquivalent:@""];
        [item setTag:SKSquareNote];
        [item setTarget:self];
        
        if ([[self currentSelection] hasCharacters]) {
            item = [submenu addItemWithTitle:NSLocalizedString(@"Highlight", @"Menu item title") action:@selector(addAnnotation:) keyEquivalent:@""];
            [item setTag:SKHighlightNote];
            [item setTarget:self];
            
            item = [submenu addItemWithTitle:NSLocalizedString(@"Underline", @"Menu item title") action:@selector(addAnnotation:) keyEquivalent:@""];
            [item setTag:SKUnderlineNote];
            [item setTarget:self];
            
            item = [submenu addItemWithTitle:NSLocalizedString(@"Strike Out", @"Menu item title") action:@selector(addAnnotation:) keyEquivalent:@""];
            [item setTag:SKStrikeOutNote];
            [item setTarget:self];
        }
        
        item = [submenu addItemWithTitle:NSLocalizedString(@"Line", @"Menu item title") action:@selector(addAnnotation:) keyEquivalent:@""];
        [item setTag:SKLineNote];
        [item setTarget:self];
        
        item = [menu insertItemWithTitle:NSLocalizedString(@"New Note or Highlight", @"Menu item title") action:NULL keyEquivalent:@"" atIndex:0];
        [item setSubmenu:submenu];
        [submenu release];
        
        [menu insertItem:[NSMenuItem separatorItem] atIndex:0];
        
        NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        PDFPage *page = [self pageForPoint:point nearest:YES];
        PDFAnnotation *annotation = nil;
        
        if (page) {
            annotation = [page annotationAtPoint:[self convertPoint:point toPage:page]];
            if ([annotation isSkimNote] == NO)
                annotation = nil;
        }
        
        if (annotation) {
            if ((annotation != activeAnnotation || [NSFontPanel sharedFontPanelExists] == NO || [[NSFontPanel sharedFontPanel] isVisible] == NO) &&
                [[annotation type] isEqualToString:SKNFreeTextString]) {
                item = [menu insertItemWithTitle:[NSLocalizedString(@"Note Font", @"Menu item title") stringByAppendingEllipsis] action:@selector(showFontsForThisAnnotation:) keyEquivalent:@"" atIndex:0];
                [item setRepresentedObject:annotation];
                [item setTarget:self];
            }
            
            if ((annotation != activeAnnotation || [SKLineInspector sharedLineInspectorExists] == NO || [[[SKLineInspector sharedLineInspector] window] isVisible] == NO) &&
                [annotation isMarkup] == NO && [[annotation type] isEqualToString:SKNNoteString] == NO) {
                item = [menu insertItemWithTitle:[NSLocalizedString(@"Note Line", @"Menu item title") stringByAppendingEllipsis] action:@selector(showLinesForThisAnnotation:) keyEquivalent:@"" atIndex:0];
                [item setRepresentedObject:annotation];
                [item setTarget:self];
            }
            
            if (annotation != activeAnnotation || [NSColorPanel sharedColorPanelExists] == NO || [[NSColorPanel sharedColorPanel] isVisible] == NO) {
                item = [menu insertItemWithTitle:[NSLocalizedString(@"Note Color", @"Menu item title") stringByAppendingEllipsis] action:@selector(showColorsForThisAnnotation:) keyEquivalent:@"" atIndex:0];
                [item setRepresentedObject:annotation];
                [item setTarget:self];
            }
            
            if ((annotation != activeAnnotation || [self isEditing] == NO) && [annotation isEditable]) {
                item = [menu insertItemWithTitle:NSLocalizedString(@"Edit Note", @"Menu item title") action:@selector(editThisAnnotation:) keyEquivalent:@"" atIndex:0];
                [item setRepresentedObject:annotation];
                [item setTarget:self];
            }
            
            item = [menu insertItemWithTitle:NSLocalizedString(@"Remove Note", @"Menu item title") action:@selector(removeThisAnnotation:) keyEquivalent:@"" atIndex:0];
            [item setRepresentedObject:annotation];
            [item setTarget:self];
        } else if ([activeAnnotation isSkimNote]) {
            if (([NSFontPanel sharedFontPanelExists] == NO || [[NSFontPanel sharedFontPanel] isVisible] == NO) &&
                [[activeAnnotation type] isEqualToString:SKNFreeTextString]) {
                item = [menu insertItemWithTitle:[NSLocalizedString(@"Note Font", @"Menu item title") stringByAppendingEllipsis] action:@selector(showFontsForThisAnnotation:) keyEquivalent:@"" atIndex:0];
                [item setTarget:self];
            }
            
            if (([SKLineInspector sharedLineInspectorExists] == NO || [[[SKLineInspector sharedLineInspector] window] isVisible] == NO) &&
                [activeAnnotation isMarkup] == NO && [[activeAnnotation type] isEqualToString:SKNNoteString] == NO) {
                item = [menu insertItemWithTitle:[NSLocalizedString(@"Current Note Line", @"Menu item title") stringByAppendingEllipsis] action:@selector(showLinesForThisAnnotation:) keyEquivalent:@"" atIndex:0];
                [item setTarget:self];
            }
            
            if ([NSColorPanel sharedColorPanelExists] == NO || [[NSColorPanel sharedColorPanel] isVisible] == NO) {
                item = [menu insertItemWithTitle:[NSLocalizedString(@"Current Note Color", @"Menu item title") stringByAppendingEllipsis] action:@selector(showColorsForThisAnnotation:) keyEquivalent:@"" atIndex:0];
                [item setTarget:self];
            }
            
            if ([self isEditing] == NO && [activeAnnotation isEditable]) {
                item = [menu insertItemWithTitle:NSLocalizedString(@"Edit Current Note", @"Menu item title") action:@selector(editActiveAnnotation:) keyEquivalent:@"" atIndex:0];
                [item setTarget:self];
            }
            
            item = [menu insertItemWithTitle:NSLocalizedString(@"Remove Current Note", @"Menu item title") action:@selector(removeActiveAnnotation:) keyEquivalent:@"" atIndex:0];
            [item setTarget:self];
        }
        
        if ([[NSPasteboard generalPasteboard] availableTypeFromArray:[NSArray arrayWithObjects:SKSkimNotePboardType, NSStringPboardType, nil]]) {
            SEL selector = ([theEvent modifierFlags] & NSAlternateKeyMask) ? @selector(alternatePaste:) : @selector(paste:);
            item = [menu insertItemWithTitle:NSLocalizedString(@"Paste", @"Menu item title") action:selector keyEquivalent:@"" atIndex:0];
        }
        
        if (([activeAnnotation isSkimNote] && [activeAnnotation isMovable]) || [[self currentSelection] hasCharacters]) {
            if ([activeAnnotation isSkimNote] && [activeAnnotation isMovable])
                item = [menu insertItemWithTitle:NSLocalizedString(@"Cut", @"Menu item title") action:@selector(copy:) keyEquivalent:@"" atIndex:0];
            item = [menu insertItemWithTitle:NSLocalizedString(@"Copy", @"Menu item title") action:@selector(copy:) keyEquivalent:@"" atIndex:0];
        }
        
        if ([[menu itemAtIndex:0] isSeparatorItem])
            [menu removeItemAtIndex:0];
        
    } else if ((toolMode == SKSelectToolMode && NSIsEmptyRect(selectionRect) == NO) || ([self toolMode] == SKTextToolMode && [self hideNotes] && [[self currentSelection] hasCharacters])) {
        
        [menu insertItem:[NSMenuItem separatorItem] atIndex:0];
        
        item = [menu insertItemWithTitle:NSLocalizedString(@"Copy", @"Menu item title") action:@selector(copy:) keyEquivalent:@"" atIndex:0];
        
    }
    
    return menu;
}

- (void)magnifyWheel:(NSEvent *)theEvent {
    CGFloat dy = [theEvent deltaY];
    dy = dy > 0 ? SKMin(0.2, dy) : SKMax(-0.2, dy);
    [self setScaleFactor:[self scaleFactor] + 0.5 * dy];
}

- (void)mouseEntered:(NSEvent *)theEvent {
    NSTrackingRectTag trackingNumber = [theEvent trackingNumber];
    [super mouseEntered:theEvent];
    if (trackingNumber == trackingRect) {
        [[self window] setAcceptsMouseMovedEvents:YES];
    } else if ([NSApp isActive] && -1 != CFArrayGetFirstIndexOfValue(PDFToolTipRects, CFRangeMake(0, CFArrayGetCount(PDFToolTipRects)), (void *)trackingNumber)) {
        [[SKPDFToolTipWindow sharedToolTipWindow] showForPDFContext:(id)[theEvent userData] atPoint:NSZeroPoint];
        PDFToolTipRect = trackingNumber;
    }
}
 
- (void)mouseExited:(NSEvent *)theEvent {
    NSTrackingRectTag trackingNumber = [theEvent trackingNumber];
    [super mouseExited:theEvent];
    if (trackingNumber == trackingRect) {
        [[self window] setAcceptsMouseMovedEvents:([self interactionMode] == SKFullScreenMode)];
    } else if (PDFToolTipRect == trackingNumber) {
        [[SKPDFToolTipWindow sharedToolTipWindow] fadeOut];
        PDFToolTipRect = 0;
    }
}

- (void)rotatePageAtIndex:(NSUInteger)idx by:(NSInteger)rotation {
    NSUndoManager *undoManager = [self undoManager];
    [[undoManager prepareWithInvocationTarget:self] rotatePageAtIndex:idx by:-rotation];
    [undoManager setActionName:NSLocalizedString(@"Rotate Page", @"Undo action name")];
    [[[[self window] windowController] document] undoableActionDoesntDirtyDocument];
    
    PDFPage *page = [[self document] pageAtIndex:idx];
    [page setRotation:[page rotation] + rotation];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFPageBoundsDidChangeNotification 
            object:[self document] userInfo:[NSDictionary dictionaryWithObjectsAndKeys:SKPDFPageActionRotate, SKPDFPageActionKey, page, SKPDFPagePageKey, nil]];
}

- (void)beginGestureWithEvent:(NSEvent *)theEvent {
    if ([[SKPDFView superclass] instancesRespondToSelector:_cmd])
        [super beginGestureWithEvent:theEvent];
    gestureRotation = 0.0;
    gesturePageIndex = [[self currentPage] pageIndex];
}

- (void)endGestureWithEvent:(NSEvent *)theEvent {
    if ([[SKPDFView superclass] instancesRespondToSelector:_cmd])
        [super endGestureWithEvent:theEvent];
    gestureRotation = 0.0;
    gesturePageIndex = NSNotFound;
}

- (void)rotateWithEvent:(NSEvent *)theEvent {
    if (interactionMode == SKPresentationMode)
        return;
    if ([theEvent respondsToSelector:@selector(rotation)])
        gestureRotation -= [theEvent rotation];
    if (SKAbs(gestureRotation) > 45.0 && gesturePageIndex != NSNotFound) {
        [self rotatePageAtIndex:gesturePageIndex by:90.0 * SKRound(gestureRotation / 90.0)];
        gestureRotation -= 90.0 * SKRound(gestureRotation / 90.0);
    }
}

- (void)magnifyWithEvent:(NSEvent *)theEvent {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKDisablePinchZoomKey] == NO && interactionMode != SKPresentationMode && [[SKPDFView superclass] instancesRespondToSelector:_cmd])
        [super magnifyWithEvent:theEvent];
}

- (void)swipeWithEvent:(NSEvent *)theEvent {
    if (interactionMode == SKPresentationMode && transitionController &&
        ([transitionController transitionStyle] != SKNoTransition || [transitionController pageTransitions])) {
        if ([theEvent deltaX] < 0.0 || [theEvent deltaY] < 0.0) {
            if ([self canGoToNextPage])
                [self goToNextPage:nil];
        } else if ([theEvent deltaX] > 0.0 || [theEvent deltaY] > 0.0) {
            if ([self canGoToPreviousPage])
                [self goToPreviousPage:nil];
        }
    } else if ([[SKPDFView superclass] instancesRespondToSelector:_cmd]) {
        [super swipeWithEvent:theEvent];
    }
}

- (void)checkSpellingStartingAtIndex:(NSInteger)anIndex onPage:(PDFPage *)page {
    NSUInteger i, first = [page pageIndex];
    NSUInteger count = [[self document] pageCount];
    BOOL didWrap = NO;
    i = first;
    NSRange range = NSMakeRange(NSNotFound, 0);
    
    while (YES) {
        range = [[NSSpellChecker sharedSpellChecker] checkSpellingOfString:[page string] startingAt:anIndex language:nil wrap:NO inSpellDocumentWithTag:spellingTag wordCount:NULL];
        if (range.location != NSNotFound) break;
        if (didWrap && i == first) break;
        if (++i >= count) {
            i = 0;
            didWrap = YES;
        }
        page = [[self document] pageAtIndex:i];
        anIndex = 0;
    }
    
    if (range.location != NSNotFound) {
        PDFSelection *selection = [page selectionForRange:range];
        [self setCurrentSelection:selection];
        [self scrollRect:[selection boundsForPage:page] inPageToVisible:page];
        [[NSSpellChecker sharedSpellChecker] updateSpellingPanelWithMisspelledWord:[selection string]];
    } else NSBeep();
}

- (void)checkSpelling:(id)sender {
    PDFSelection *selection = [self currentSelection];
    PDFPage *page = [self currentPage];
    NSUInteger idx = 0;
    if ([selection hasCharacters]) {
        page = [[selection pages] lastObject];
        idx = [selection safeIndexOfLastCharacterOnPage:page];
        if (idx == NSNotFound)
            idx = 0;
    }
    [self checkSpellingStartingAtIndex:idx onPage:page];
}

- (void)showGuessPanel:(id)sender {
    PDFSelection *selection = [self currentSelection];
    PDFPage *page = [self currentPage];
    NSUInteger idx = 0;
    if ([selection hasCharacters]) {
        page = [[selection pages] objectAtIndex:0];
        idx = [selection safeIndexOfFirstCharacterOnPage:page];
        if (idx == NSNotFound)
            idx = 0;
    }
    [self checkSpellingStartingAtIndex:idx onPage:page];
    [[[NSSpellChecker sharedSpellChecker] spellingPanel] orderFront:self];
}

- (void)ignoreSpelling:(id)sender {
    [[NSSpellChecker sharedSpellChecker] ignoreWord:[[sender selectedCell] stringValue] inSpellDocumentWithTag:spellingTag];
}

// we cannot use PDFAction and subclasses, because those are Leopard only
- (void)performAction:(id)action {
    // PDFView does not handle the PDFActionRemoteGoTo, so we do it
    if ([action isKindOfClass:NSClassFromString(@"PDFActionRemoteGoTo")]) {
        NSURL *fileURL = [action URL];
        NSError *error = nil;
        NSDocumentController *sdc = [NSDocumentController sharedDocumentController];
        id document = nil;
        if ([sdc documentClassForType:[sdc typeForContentsOfURL:fileURL error:&error]] == [SKMainDocument class]) {
            if (document = [sdc openDocumentWithContentsOfURL:fileURL display:YES error:&error]) {
                NSUInteger pageIndex = [action pageIndex];
                if (pageIndex < [[document pdfDocument] pageCount]) {
                    PDFPage *page = [[document pdfDocument] pageAtIndex:pageIndex];
                    PDFDestination *dest = [[[PDFDestination alloc] initWithPage:page atPoint:[action point]] autorelease];
                    [[document pdfView] goToDestination:dest];
                }
            } else if (error) {
                [NSApp presentError:error];
            }
        } else if (fileURL) {
            // fall back to just opening the file and ignore the destination
            [[NSWorkspace sharedWorkspace] openURL:fileURL];
        }
    } else {
        [super performAction:action];
    }
}

#pragma mark Tracking mousemoved fix

- (void)resetBoundsTrackingRect {
    if ([self window] && trackingRect)
        [self removeTrackingRect:trackingRect];
    trackingRect = [self addTrackingRect:[self bounds] owner:self userData:NULL assumeInside:NO];
}

- (void)setFrame:(NSRect)frame {
    [super setFrame:frame];
    [self resetBoundsTrackingRect];
}

- (void)setFrameSize:(NSSize)size {
    [super setFrameSize:size];
    [self resetBoundsTrackingRect];
}
 
- (void)setBounds:(NSRect)bounds {
    [super setBounds:bounds];
    [self resetBoundsTrackingRect];
}
 
- (void)setBoundsSize:(NSSize)size {
    [super setBoundsSize:size];
    [self resetBoundsTrackingRect];
}

- (void)viewWillMoveToWindow:(NSWindow *)newWindow {
    if ([self window] && trackingRect)
        [self removeTrackingRect:trackingRect];
    if ([self isEditing] && [self commitEditing] == NO)
        [self discardEditing];
}

- (void)viewDidMoveToWindow {
    trackingRect = [self addTrackingRect:[self bounds] owner:self userData:NULL assumeInside:NO];
}

#pragma mark NSDraggingDestination protocol

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    NSDragOperation dragOp = NSDragOperationNone;
    NSPasteboard *pboard = [sender draggingPasteboard];
    NSString *pboardType = [pboard availableTypeFromArray:[NSArray arrayWithObjects:NSColorPboardType, SKLineStylePboardType, nil]];
    if (pboardType) {
        return [self draggingUpdated:sender];
    } else if ([[SKPDFView superclass] instancesRespondToSelector:_cmd]) {
        dragOp = [super draggingEntered:sender];
    }
    return dragOp;
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender {
    NSDragOperation dragOp = NSDragOperationNone;
    NSPasteboard *pboard = [sender draggingPasteboard];
    NSString *pboardType = [pboard availableTypeFromArray:[NSArray arrayWithObjects:NSColorPboardType, SKLineStylePboardType, nil]];
    if (pboardType) {
        NSPoint location = [self convertPoint:[sender draggingLocation] fromView:nil];
        PDFPage *page = [self pageForPoint:location nearest:NO];
        if (page) {
            NSArray *annotations = [page annotations];
            PDFAnnotation *annotation = nil;
            NSInteger i = [annotations count];
            location = [self convertPoint:location toPage:page];
            while (i-- > 0) {
                annotation = [annotations objectAtIndex:i];
                NSString *type = [annotation type];
                if ([annotation isSkimNote] && [annotation hitTest:location] && 
                    ([pboardType isEqualToString:NSColorPboardType] || [type isEqualToString:SKNFreeTextString] || [type isEqualToString:SKNCircleString] || [type isEqualToString:SKNSquareString] || [type isEqualToString:SKNLineString] || [type isEqualToString:SKNInkString])) {
                    if ([annotation isEqual:highlightAnnotation] == NO) {
                        if (highlightAnnotation)
                            [self setNeedsDisplayForAnnotation:highlightAnnotation];
                        highlightAnnotation = annotation;
                        [self setNeedsDisplayForAnnotation:highlightAnnotation];
                    }
                    dragOp = NSDragOperationGeneric;
                    break;
                }
            }
        }
        if (dragOp == NSDragOperationNone && highlightAnnotation) {
            [self setNeedsDisplayForAnnotation:highlightAnnotation];
            highlightAnnotation = nil;
        }
    } else if ([[SKPDFView superclass] instancesRespondToSelector:_cmd]) {
        dragOp = [super draggingUpdated:sender];
    }
    return dragOp;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard = [sender draggingPasteboard];
    NSString *pboardType = [pboard availableTypeFromArray:[NSArray arrayWithObjects:NSColorPboardType, SKLineStylePboardType, nil]];
    if (pboardType) {
        if (highlightAnnotation) {
            [self setNeedsDisplayForAnnotation:highlightAnnotation];
            highlightAnnotation = nil;
        }
    } else if ([[SKPDFView superclass] instancesRespondToSelector:_cmd]) {
        [super draggingExited:sender];
    }
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    BOOL performedDrag = NO;
    NSPasteboard *pboard = [sender draggingPasteboard];
    NSString *pboardType = [pboard availableTypeFromArray:[NSArray arrayWithObjects:NSColorPboardType, SKLineStylePboardType, nil]];
    if (pboardType) {
        if (highlightAnnotation) {
            NSString *type = [highlightAnnotation type];
            if ([pboardType isEqualToString:NSColorPboardType]) {
                if (([NSEvent standardModifierFlags] & NSAlternateKeyMask) && [highlightAnnotation respondsToSelector:@selector(setInteriorColor:)])
                    [(id)highlightAnnotation setInteriorColor:[NSColor colorFromPasteboard:pboard]];
                else if (([NSEvent standardModifierFlags] & NSAlternateKeyMask) && [highlightAnnotation respondsToSelector:@selector(setFontColor:)])
                    [(id)highlightAnnotation setFontColor:[NSColor colorFromPasteboard:pboard]];
                else
                    [highlightAnnotation setColor:[NSColor colorFromPasteboard:pboard]];
                performedDrag = YES;
            } else if ([type isEqualToString:SKNFreeTextString] || [type isEqualToString:SKNCircleString] || [type isEqualToString:SKNSquareString] || [type isEqualToString:SKNLineString] || [type isEqualToString:SKNInkString]) {
                NSDictionary *dict = [pboard propertyListForType:SKLineStylePboardType];
                NSNumber *number;
                if (number = [dict objectForKey:SKLineWellLineWidthKey])
                    [highlightAnnotation setLineWidth:[number doubleValue]];
                [highlightAnnotation setDashPattern:[dict objectForKey:SKLineWellDashPatternKey]];
                if (number = [dict objectForKey:SKLineWellStyleKey])
                    [highlightAnnotation setBorderStyle:[number integerValue]];
                if ([type isEqualToString:SKNLineString]) {
                    if (number = [dict objectForKey:SKLineWellStartLineStyleKey])
                        [(PDFAnnotationLine *)highlightAnnotation setStartLineStyle:[number integerValue]];
                    if (number = [dict objectForKey:SKLineWellEndLineStyleKey])
                        [(PDFAnnotationLine *)highlightAnnotation setEndLineStyle:[number integerValue]];
                }
                performedDrag = YES;
            }
            [self setNeedsDisplayForAnnotation:highlightAnnotation];
            highlightAnnotation = nil;
        }
    } else if ([[SKPDFView superclass] instancesRespondToSelector:_cmd]) {
        performedDrag = [super performDragOperation:sender];
    }
    return performedDrag;
}

#pragma mark Services

- (BOOL)writeSelectionToPasteboard:(NSPasteboard *)pboard types:(NSArray *)types {
    if ([self toolMode] == SKSelectToolMode && NSIsEmptyRect(selectionRect) == NO && selectionPageIndex != NSNotFound && ([types containsObject:NSPDFPboardType] || [types containsObject:NSTIFFPboardType])) {
        NSMutableArray *writeTypes = [NSMutableArray array];
        NSData *pdfData = nil;
        NSData *tiffData = nil;
        NSRect selRect = NSIntegralRect(selectionRect);
        
        if ([types containsObject:NSPDFPboardType]  &&
            (pdfData = [[self currentSelectionPage] PDFDataForRect:selRect]))
            [writeTypes addObject:NSPDFPboardType];
        
        if ([types containsObject:NSTIFFPboardType] &&
            (tiffData = [[self currentSelectionPage] TIFFDataForRect:selRect]))
            [writeTypes addObject:NSTIFFPboardType];
    
        [pboard declareTypes:writeTypes owner:nil];
        if (pdfData)
            [pboard setData:pdfData forType:NSPDFPboardType];
        if (tiffData)
            [pboard setData:tiffData forType:NSTIFFPboardType];
        
        return YES;
        
    } else if ([[SKPDFView superclass] instancesRespondToSelector:_cmd]) {
        return [super writeSelectionToPasteboard:pboard types:types];
    }
    return NO;
}

- (id)validRequestorForSendType:(NSString *)sendType returnType:(NSString *)returnType {
    if ([self toolMode] == SKSelectToolMode && NSIsEmptyRect(selectionRect) == NO && selectionPageIndex != NSNotFound && returnType == nil && ([sendType isEqualToString:NSPDFPboardType] || [sendType isEqualToString:NSTIFFPboardType])) {
        return self;
    }
    return [super validRequestorForSendType:sendType returnType:returnType];
}

#pragma mark UndoManager

- (NSUndoManager *)undoManager {
    return [[[[self window] windowController] document] undoManager];
}

#pragma mark Annotation management

- (void)addAnnotation:(id)sender {
    NSEvent *event = [NSApp currentEvent];
    NSPoint point = ([[event window] isEqual:[self window]] && ([event type] == NSLeftMouseDown || [event type] == NSRightMouseDown)) ? [event locationInWindow] : [[self window] mouseLocationOutsideOfEventStream];
    [self addAnnotationWithType:[sender tag] defaultPoint:point];
}

- (void)addAnnotationWithType:(SKNoteType)annotationType {
    [self addAnnotationWithType:annotationType defaultPoint:[[self window] mouseLocationOutsideOfEventStream]];
}

- (void)addAnnotationWithType:(SKNoteType)annotationType defaultPoint:(NSPoint)point {
	PDFPage *page = nil;
	NSRect bounds = NSZeroRect;
    PDFSelection *selection = [self currentSelection];
    NSString *text = nil;
	
    if ([selection hasCharacters]) {
        text = [selection cleanedString];
        
		// Get bounds (page space) for selection (first page in case selection spans multiple pages).
		page = [[selection pages] objectAtIndex: 0];
		bounds = [selection boundsForPage: page];
        if (annotationType == SKCircleNote || annotationType == SKSquareNote)
            bounds = NSInsetRect(bounds, -5.0, -5.0);
        else if (annotationType == SKAnchoredNote)
            bounds.size = SKNPDFAnnotationNoteSize;
	} else if (annotationType != SKHighlightNote && annotationType != SKUnderlineNote && annotationType != SKStrikeOutNote) {
        
		// First try the current mouse position
        NSPoint center = [self convertPoint:point fromView:nil];
        
        // if the mouse was in the toolbar and there is a page below the toolbar, we get a point outside of the visible rect
        page = NSMouseInRect(center, [[self documentView] convertRect:[[self documentView] visibleRect] toView:self], [self isFlipped]) ? [self pageForPoint:center nearest:NO] : nil;
        
        if (page == nil) {
            // Get center of the PDFView.
            NSRect viewFrame = [self frame];
            center = SKCenterPoint(viewFrame);
            page = [self pageForPoint: center nearest: YES];
            if (page == nil) {
                // Get center of the current page
                page = [self currentPage];
                center = [self convertPoint:SKCenterPoint([page boundsForBox:[self displayBox]]) fromPage:page];
            }
        }
        
        CGFloat defaultWidth = [[NSUserDefaults standardUserDefaults] floatForKey:SKDefaultNoteWidthKey];
        CGFloat defaultHeight = [[NSUserDefaults standardUserDefaults] floatForKey:SKDefaultNoteHeightKey];
        NSSize defaultSize = (annotationType == SKAnchoredNote) ? SKNPDFAnnotationNoteSize : ([page rotation] % 180 == 0) ? NSMakeSize(defaultWidth, defaultHeight) : NSMakeSize(defaultHeight, defaultWidth);
		
		// Convert to "page space".
		center = SKIntegralPoint([self convertPoint: center toPage: page]);
        bounds = SKRectFromCenterAndSize(center, defaultSize);
        
        // Make sure it fits in the page
        bounds = SKConstrainRect(bounds, [page boundsForBox:[self displayBox]]);
	}
    if (page != nil)
        [self addAnnotationWithType:annotationType contents:text page:page bounds:bounds];
    else NSBeep();
}

- (void)addAnnotationWithType:(SKNoteType)annotationType contents:(NSString *)text page:(PDFPage *)page bounds:(NSRect)bounds {
	PDFAnnotation *newAnnotation = nil;
    PDFSelection *sel = [self currentSelection];
	// Create annotation and add to page.
    switch (annotationType) {
        case SKFreeTextNote:
            newAnnotation = [[PDFAnnotationFreeText alloc] initSkimNoteWithBounds:bounds];
            if (text == nil)
                text = [[NSUserDefaults standardUserDefaults] stringForKey:SKDefaultFreeTextNoteContentsKey];
            break;
        case SKAnchoredNote:
            newAnnotation = [[SKNPDFAnnotationNote alloc] initSkimNoteWithBounds:bounds];
            if (text == nil)
                text = [[NSUserDefaults standardUserDefaults] stringForKey:SKDefaultAnchoredNoteContentsKey];
            break;
        case SKCircleNote:
            newAnnotation = [[PDFAnnotationCircle alloc] initSkimNoteWithBounds:bounds];
            break;
        case SKSquareNote:
            newAnnotation = [[PDFAnnotationSquare alloc] initSkimNoteWithBounds:bounds];
            break;
        case SKHighlightNote:
            if ([[activeAnnotation type] isEqualToString:SKNHighlightString] && [[activeAnnotation page] isEqual:page]) {
                [sel addSelection:[(PDFAnnotationMarkup *)activeAnnotation selection]];
                [self removeActiveAnnotation:nil];
                text = [sel cleanedString];
            }
            newAnnotation = [[PDFAnnotationMarkup alloc] initSkimNoteWithSelection:sel markupType:kPDFMarkupTypeHighlight];
            break;
        case SKUnderlineNote:
            if ([[activeAnnotation type] isEqualToString:SKNUnderlineString] && [[activeAnnotation page] isEqual:page]) {
                [sel addSelection:[(PDFAnnotationMarkup *)activeAnnotation selection]];
                [self removeActiveAnnotation:nil];
                text = [sel cleanedString];
            }
            newAnnotation = [[PDFAnnotationMarkup alloc] initSkimNoteWithSelection:sel markupType:kPDFMarkupTypeUnderline];
            break;
        case SKStrikeOutNote:
            if ([[activeAnnotation type] isEqualToString:SKNStrikeOutString] && [[activeAnnotation page] isEqual:page]) {
                [sel addSelection:[(PDFAnnotationMarkup *)activeAnnotation selection]];
                [self removeActiveAnnotation:nil];
                text = [sel cleanedString];
            }
            newAnnotation = [[PDFAnnotationMarkup alloc] initSkimNoteWithSelection:sel markupType:kPDFMarkupTypeStrikeOut];
            break;
        case SKLineNote:
            newAnnotation = [[PDFAnnotationLine alloc] initSkimNoteWithBounds:bounds];
            break;
        case SKInkNote:
            if (bezierPaths)
                newAnnotation = [[PDFAnnotationInk alloc] initSkimNoteWithPaths:[[[NSArray alloc] initWithArray:bezierPaths copyItems:YES] autorelease]];
            break;
	}
    if (newAnnotation) {
        if (annotationType != SKLineNote && annotationType != SKInkNote) {
            if (text == nil)
                text = [[page selectionForRect:[newAnnotation bounds]] cleanedString];
            if (text)
                [newAnnotation setString:text];
        }
        
        [self addAnnotation:newAnnotation toPage:page];
        [[self undoManager] setActionName:NSLocalizedString(@"Add Note", @"Undo action name")];

        [self setActiveAnnotation:newAnnotation];
        [newAnnotation release];
        if (annotationType == SKAnchoredNote && [[self delegate] respondsToSelector:@selector(PDFView:editAnnotation:)])
            [[self delegate] PDFView:self editAnnotation:activeAnnotation];
    } else NSBeep();
}

- (void)addAnnotation:(PDFAnnotation *)annotation toPage:(PDFPage *)page {
    [self addAnnotation:annotation toPage:page undoable:YES];
}

- (void)addAnnotation:(PDFAnnotation *)annotation toPage:(PDFPage *)page undoable:(BOOL)undoable {
    if (undoable)
        [[[self undoManager] prepareWithInvocationTarget:self] removeAnnotation:annotation];
    [annotation setShouldDisplay:hideNotes == NO];
    [annotation setShouldPrint:hideNotes == NO];
    [page addAnnotation:annotation];
    [self setNeedsDisplayForAnnotation:annotation];
    [self resetPDFToolTipRects];
    [accessibilityChildren release];
    accessibilityChildren = nil;
    [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewDidAddAnnotationNotification object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:page, SKPDFViewPageKey, annotation, SKPDFViewAnnotationKey, nil]];                
}

- (void)removeActiveAnnotation:(id)sender{
    if ([activeAnnotation isSkimNote]) {
        [self removeAnnotation:activeAnnotation];
        [[self undoManager] setActionName:NSLocalizedString(@"Remove Note", @"Undo action name")];
    }
}

- (void)removeThisAnnotation:(id)sender{
    PDFAnnotation *annotation = [sender representedObject];
    
    if (annotation) {
        [self removeAnnotation:annotation];
        [[self undoManager] setActionName:NSLocalizedString(@"Remove Note", @"Undo action name")];
    }
}

- (void)removeAnnotation:(PDFAnnotation *)annotation {
    [self removeAnnotation:annotation undoable:YES];
}

- (void)removeAnnotation:(PDFAnnotation *)annotation undoable:(BOOL)undoable {
    PDFAnnotation *wasAnnotation = [annotation retain];
    PDFPage *page = [wasAnnotation page];
    BOOL wasNote = [[wasAnnotation type] isEqualToString:SKNNoteString];
    
    if (undoable)
        [[[self undoManager] prepareWithInvocationTarget:self] addAnnotation:wasAnnotation toPage:page];
    if ([self isEditing] && activeAnnotation == annotation)
        [self commitEditing];
	if (activeAnnotation == annotation)
		[self setActiveAnnotation:nil];
    [self setNeedsDisplayForAnnotation:wasAnnotation];
    [page removeAnnotation:wasAnnotation];
    [accessibilityChildren release];
    accessibilityChildren = nil;
    if (wasNote)
        [self resetPDFToolTipRects];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewDidRemoveAnnotationNotification object:self 
        userInfo:[NSDictionary dictionaryWithObjectsAndKeys:wasAnnotation, SKPDFViewAnnotationKey, page, SKPDFViewPageKey, nil]];
    [wasAnnotation release];
}

- (void)moveAnnotation:(PDFAnnotation *)annotation toPage:(PDFPage *)page {
    PDFPage *oldPage = [annotation page];
    [[[self undoManager] prepareWithInvocationTarget:self] moveAnnotation:annotation toPage:oldPage];
    [[self undoManager] setActionName:NSLocalizedString(@"Edit Note", @"Undo action name")];
    [self setNeedsDisplayForAnnotation:annotation];
    [annotation retain];
    [oldPage removeAnnotation:annotation];
    [page addAnnotation:annotation];
    [annotation release];
    [self setNeedsDisplayForAnnotation:annotation];
    if ([[annotation type] isEqualToString:SKNNoteString])
        [self resetPDFToolTipRects];
    [accessibilityChildren release];
    accessibilityChildren = nil;
    [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewDidMoveAnnotationNotification object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:oldPage, SKPDFViewOldPageKey, page, SKPDFViewNewPageKey, annotation, SKPDFViewAnnotationKey, nil]];                
}

- (void)editThisAnnotation:(id)sender {
    PDFAnnotation *annotation = [sender representedObject];
    
    if (annotation == nil || ([self isEditing] && activeAnnotation == annotation))
        return;
    
    if ([self isEditing])
        [self commitEditing];
    if (activeAnnotation != annotation)
        [self setActiveAnnotation:annotation];
    [self editActiveAnnotation:sender];
}

- (void)editActiveAnnotation:(id)sender {
    if (nil == activeAnnotation || hideNotes)
        return;
    
    [self commitEditing];
    
    NSString *type = [activeAnnotation type];
    
    if ([activeAnnotation isLink]) {
        
        [[SKPDFToolTipWindow sharedToolTipWindow] orderOut:self];
        if ([activeAnnotation destination])
            [self goToDestination:[(PDFAnnotationLink *)activeAnnotation destination]];
        else if ([(PDFAnnotationLink *)activeAnnotation URL])
            [[NSWorkspace sharedWorkspace] openURL:[(PDFAnnotationLink *)activeAnnotation URL]];
        [self setActiveAnnotation:nil];
        
    } else if ([type isEqualToString:SKNFreeTextString]) {
        
        NSRect editBounds = [activeAnnotation bounds];
        NSFont *font = [(PDFAnnotationFreeText *)activeAnnotation font];
        NSColor *color = [activeAnnotation color];
        NSColor *fontColor = [(PDFAnnotationFreeText *)activeAnnotation fontColor];
        CGFloat alpha = [color alphaComponent];
        if (alpha < 1.0)
            color = [[NSColor controlBackgroundColor] blendedColorWithFraction:alpha ofColor:[color colorWithAlphaComponent:1.0]];
        editBounds = [self convertRect:[self convertRect:editBounds fromPage:[activeAnnotation page]] toView:[self documentView]];
        editField = [[NSTextField alloc] initWithFrame:editBounds];
        [editField setBackgroundColor:color];
        [editField setTextColor:fontColor];
        [editField setFont:[[NSFontManager sharedFontManager] convertFont:font toSize:[font pointSize] * [self scaleFactor]]];
        [editField setStringValue:[activeAnnotation string]];
        [editField setDelegate:self];
        [[self documentView] addSubview:editField];
        [editField selectText:self];
        
        [self setNeedsDisplayForAnnotation:activeAnnotation];
        
        if ([[self delegate] respondsToSelector:@selector(PDFViewDidBeginEditing:)])
            [[self delegate] PDFViewDidBeginEditing:self];
        
    } else if ([activeAnnotation isEditable]) {
        
        [[SKPDFToolTipWindow sharedToolTipWindow] orderOut:self];
        
        if ([[self delegate] respondsToSelector:@selector(PDFView:editAnnotation:)])
            [[self delegate] PDFView:self editAnnotation:activeAnnotation];
        
    }
    
}

- (void)discardEditing {
    if (editField) {
        [editField abortEditing];
        [editField removeFromSuperview];
        [editField release];
        editField = nil;
        
        if ([[activeAnnotation type] isEqualToString:SKNFreeTextString])
            [self setNeedsDisplayForAnnotation:activeAnnotation];
        
        if ([[self delegate] respondsToSelector:@selector(PDFViewDidEndEditing:)])
            [[self delegate] PDFViewDidEndEditing:self];
    }
}

- (BOOL)commitEditing {
    if (editField) {
        if ([[self window] firstResponder] == [editField currentEditor] && [[self window] makeFirstResponder:self] == NO)
            return NO;
        if ([[editField stringValue] isEqualToString:[activeAnnotation string]] == NO)
            [activeAnnotation setString:[editField stringValue]];
        [editField removeFromSuperview];
        [editField release];
        editField = nil;
        
        if ([[activeAnnotation type] isEqualToString:SKNFreeTextString])
            [self setNeedsDisplayForAnnotation:activeAnnotation];
        
        if ([[self delegate] respondsToSelector:@selector(PDFViewDidEndEditing:)])
            [[self delegate] PDFViewDidEndEditing:self];
    }
    return YES;
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)command {
    BOOL rv = NO;
    if ([control isEqual:editField]) {
        if (command == @selector(insertNewline:) || command == @selector(insertTab:) || command == @selector(insertBacktab:)) {
            [self commitEditing];
            [[self window] makeFirstResponder:self];
            rv = YES;
        }
    } else if ([[SKPDFView superclass] instancesRespondToSelector:_cmd]) {
       rv = [super control:control textView:textView doCommandBySelector:command];
    }
    return rv;
}

- (void)selectNextActiveAnnotation:(id)sender {
    PDFDocument *pdfDoc = [self document];
    NSInteger numberOfPages = [pdfDoc pageCount];
    NSInteger i = -1;
    NSInteger pageIndex, startPageIndex = -1;
    PDFAnnotation *annotation = nil;
    
    if (activeAnnotation) {
        if ([self isEditing])
            [self commitEditing];
        pageIndex = [[activeAnnotation page] pageIndex];
        i = [[[activeAnnotation page] annotations] indexOfObject:activeAnnotation];
    } else {
        pageIndex = [[self currentPage] pageIndex];
    }
    while (annotation == nil) {
        NSArray *annotations = [[pdfDoc pageAtIndex:pageIndex] annotations];
        while (++i < (NSInteger)[annotations count] && annotation == nil) {
            annotation = [annotations objectAtIndex:i];
            if (([self hideNotes] || [annotation isSkimNote] == NO) && [annotation isLink] == NO)
                annotation = nil;
        }
        if (startPageIndex == -1)
            startPageIndex = pageIndex;
        else if (pageIndex == startPageIndex)
            break;
        if (++pageIndex == numberOfPages)
            pageIndex = 0;
        i = -1;
    }
    if (annotation) {
        [self scrollAnnotationToVisible:annotation];
        [self setActiveAnnotation:annotation];
        if ([annotation isLink] || [annotation text]) {
            NSRect bounds = [annotation bounds]; 
            NSPoint point = NSMakePoint(NSMinX(bounds) + 0.3 * NSWidth(bounds), NSMinY(bounds) + 0.3 * NSHeight(bounds));
            point = [self convertPoint:[self convertPoint:point fromPage:[annotation page]] toView:nil];
            point = [[self window] convertBaseToScreen:NSMakePoint(SKRound(point.x), SKRound(point.y))];
            [[SKPDFToolTipWindow sharedToolTipWindow] showForPDFContext:annotation atPoint:point];
        } else {
            [[SKPDFToolTipWindow sharedToolTipWindow] orderOut:self];
        }
    }
}

- (void)selectPreviousActiveAnnotation:(id)sender {
    PDFDocument *pdfDoc = [self document];
    NSInteger numberOfPages = [pdfDoc pageCount];
    NSInteger i = -1;
    NSInteger pageIndex, startPageIndex = -1;
    PDFAnnotation *annotation = nil;
    NSArray *annotations = nil;
    
    if (activeAnnotation) {
        if ([self isEditing])
            [self commitEditing];
        pageIndex = [[activeAnnotation page] pageIndex];
        annotations = [[activeAnnotation page] annotations];
        i = [annotations indexOfObject:activeAnnotation];
    } else {
        pageIndex = [[self currentPage] pageIndex];
        annotations = [[self currentPage] annotations];
        i = [annotations count];
    }
    while (annotation == nil) {
        while (--i >= 0 && annotation == nil) {
            annotation = [annotations objectAtIndex:i];
            if (([self hideNotes] || [annotation isSkimNote] == NO) && [annotation isLink] == NO)
                annotation = nil;
        }
        if (startPageIndex == -1)
            startPageIndex = pageIndex;
        else if (pageIndex == startPageIndex)
            break;
        if (--pageIndex == -1)
            pageIndex = numberOfPages - 1;
        annotations = [[pdfDoc pageAtIndex:pageIndex] annotations];
        i = [annotations count];
    }
    if (annotation) {
        [self scrollAnnotationToVisible:annotation];
        [self setActiveAnnotation:annotation];
        if ([annotation isLink] || [annotation text]) {
            NSRect bounds = [annotation bounds]; 
            NSPoint point = NSMakePoint(NSMinX(bounds) + 0.3 * NSWidth(bounds), NSMinY(bounds) + 0.3 * NSHeight(bounds));
            point = [self convertPoint:[self convertPoint:point fromPage:[annotation page]] toView:nil];
            point = [[self window] convertBaseToScreen:NSMakePoint(SKRound(point.x), SKRound(point.y))];
            [[SKPDFToolTipWindow sharedToolTipWindow] showForPDFContext:annotation atPoint:point];
        } else {
            [[SKPDFToolTipWindow sharedToolTipWindow] orderOut:self];
        }
    }
}

- (void)scrollRect:(NSRect)rect inPageToVisible:(PDFPage *)page {
    rect = [self convertRect:[self convertRect:rect fromPage:page] toView:[self documentView]];
    if ([[self currentPage] isEqual:page] == NO)
        [self goToPage:page];
    [[self documentView] scrollRectToVisible:rect];
}

- (void)scrollAnnotationToVisible:(PDFAnnotation *)annotation {
    [self scrollRect:[annotation bounds] inPageToVisible:[annotation page]];
}

- (void)displayLineAtPoint:(NSPoint)point inPageAtIndex:(NSUInteger)pageIndex showReadingBar:(BOOL)showBar {
    if (pageIndex < [[self document] pageCount]) {
        PDFPage *page = [[self document] pageAtIndex:pageIndex];
        PDFSelection *sel = [page selectionForLineAtPoint:point];
        NSRect rect = sel ? [sel boundsForPage:page] : SKRectFromCenterAndSize(point, SKMakeSquareSize(10.0));
        
        if (interactionMode != SKPresentationMode) {
            if (showBar) {
                NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:[readingBar page], SKPDFViewOldPageKey, nil];
                if ([self hasReadingBar] == NO)
                    [self toggleReadingBar];
                [readingBar setPage:page];
                [readingBar goToPageForPoint:point];
                [self setNeedsDisplay:YES];
                [userInfo setObject:page forKey:SKPDFViewNewPageKey];
                [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewReadingBarDidChangeNotification object:self userInfo:userInfo];
            } else if (sel && ([self toolMode] == SKTextToolMode || [self toolMode] == SKNoteToolMode)) {
                [self setCurrentSelection:sel];
            }
        }
        [self scrollRect:rect inPageToVisible:page];
    }
}

- (NSArray *)accessibilityChildren {
    if (accessibilityChildren == nil) {
        PDFDocument *pdfDoc = [self document];
        NSUInteger pageCount = [pdfDoc pageCount];
        NSRange range = NSMakeRange(0, pageCount);
        if (pageCount && ([self displayMode] == kPDFDisplaySinglePage || [self displayMode] == kPDFDisplayTwoUp)) {
            range = NSMakeRange([[self currentPage] pageIndex], 1);
            if ([self displayMode] == kPDFDisplayTwoUp) {
                range.length = 2;
                if ((NSUInteger)[self displaysAsBook] != (range.location % 2)) {
                    if (range.location == 0)
                        range.length = 1;
                    else
                        range.location -= 1;
                }
                if (NSMaxRange(range) == pageCount)
                    range.length = 1;
            }
        }
        
        NSMutableArray *children = [NSMutableArray array];
        
        //[children addObject:[SKAccessibilityPDFDisplayViewElement elementWithParent:[self documentView]]];
        
        NSUInteger i;
        for (i = range.location; i < NSMaxRange(range); i++) {
            PDFPage *page = [pdfDoc pageAtIndex:i];
            NSEnumerator *annotationEnum = [[page annotations] objectEnumerator];
            PDFAnnotation *annotation;
            while (annotation = [annotationEnum nextObject]) {
                if ([annotation isLink] || [annotation isSkimNote])
                    [children addObject:[SKAccessibilityProxyFauxUIElement elementWithObject:annotation parent:[self documentView]]];
            }
        }
        accessibilityChildren = [children mutableCopy];
    }
    if ([self isEditing])
        return [accessibilityChildren arrayByAddingObject:editField];
    else
        return accessibilityChildren;
}

- (id)accessibilityChildAtPoint:(NSPoint)point {
    NSPoint localPoint = [self convertPoint:[[self window] convertScreenToBase:point] fromView:nil];
    id child = nil;
    if ([self isEditing] && NSMouseInRect([self convertPoint:localPoint toView:[self documentView]], [editField frame], [[self documentView] isFlipped])) {
        child = NSAccessibilityUnignoredDescendant(editField);
    } else {
        PDFPage *page = [self pageForPoint:localPoint nearest:NO];
        if (page) {
            PDFAnnotation *annotation = [page annotationAtPoint:[self convertPoint:localPoint toPage:page]];
            if ([annotation isLink] || [annotation isSkimNote])
                child = NSAccessibilityUnignoredAncestor([SKAccessibilityProxyFauxUIElement elementWithObject:annotation parent:[self documentView]]);
        }
    }
    //if (child == nil)
    //    child = NSAccessibilityUnignoredAncestor([SKAccessibilityPDFDisplayViewElement elementWithParent:[self documentView]]);
    return [child accessibilityHitTest:point];
}

- (id)accessibilityFocusedChild {
    id child = nil;
    if ([self isEditing])
        child = NSAccessibilityUnignoredDescendant(editField);
    else if (activeAnnotation)
        child = NSAccessibilityUnignoredAncestor([SKAccessibilityProxyFauxUIElement elementWithObject:activeAnnotation parent:[self documentView]]);
    //else
    //    child = NSAccessibilityUnignoredAncestor([SKAccessibilityPDFDisplayViewElement elementWithParent:[self documentView]]);
    return [child accessibilityFocusedUIElement];
}

#pragma mark Snapshots

- (void)takeSnapshot:(id)sender {
    NSEvent *event;
    NSPoint point;
    PDFPage *page = nil;
    NSRect rect = NSZeroRect;
    BOOL autoFits = NO;
    
    if (toolMode == SKSelectToolMode && NSIsEmptyRect(selectionRect) == NO && selectionPageIndex != NSNotFound) {
        page = [self currentSelectionPage];
        rect = NSIntersectionRect(selectionRect, [page boundsForBox:kPDFDisplayBoxCropBox]);
        autoFits = YES;
	}
    if (NSIsEmptyRect(rect)) {
        // First try the current mouse position
        event = [NSApp currentEvent];
        point = ([[event window] isEqual:[self window]] && ([event type] == NSLeftMouseDown || [event type] == NSRightMouseDown)) ? [event locationInWindow] : [[self window] mouseLocationOutsideOfEventStream];
        page = [self pageForPoint:point nearest:NO];
        if (page == nil) {
            // Get the center
            NSRect viewFrame = [self frame];
            point = SKCenterPoint(viewFrame);
            page = [self pageForPoint:point nearest:YES];
        }
        
        point = [self convertPoint:point toPage:page];
        
        rect = [self convertRect:[page boundsForBox:kPDFDisplayBoxCropBox] fromPage:page];
        rect.origin.y = point.y - 100.0;
        rect.size.height = 200.0;
        
        rect = [self convertRect:rect toPage:page];
    }
    
    SKMainWindowController *controller = [[self window] windowController];
    
    [controller showSnapshotAtPageNumber:[page pageIndex] forRect:rect scaleFactor:[self scaleFactor] autoFits:autoFits];
}

#pragma mark Notification handling

- (void)handlePageChangedNotification:(NSNotification *)notification {
    if ([self displayMode] == kPDFDisplaySinglePage || [self displayMode] == kPDFDisplayTwoUp) {
        if ([self isEditing])
            [self relayoutEditField];
        [self resetPDFToolTipRects];
        [accessibilityChildren release];
        accessibilityChildren = nil;
    }
}

- (void)handleScaleChangedNotification:(NSNotification *)notification {
    [self resetPDFToolTipRects];
    if ([self isEditing]) {
        NSRect editBounds = [self convertRect:[self convertRect:[activeAnnotation bounds] fromPage:[activeAnnotation page]] toView:[self documentView]];
        [editField setFrame:editBounds];
        if ([activeAnnotation respondsToSelector:@selector(font)]) {
            NSFont *font = [(PDFAnnotationFreeText *)activeAnnotation font];
            [editField setFont:[[NSFontManager sharedFontManager] convertFont:font toSize:[font pointSize] * [self scaleFactor]]];
        }
    }
}

- (void)handleViewChangedNotification:(NSNotification *)notification {
    [self resetPDFToolTipRects];
}

#pragma mark Menu validation

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    SEL action = [menuItem action];
    if (action == @selector(changeToolMode:)) {
        [menuItem setState:[self toolMode] == (SKToolMode)[menuItem tag] ? NSOnState : NSOffState];
        return YES;
    } else if (action == @selector(changeAnnotationMode:)) {
        if ([[menuItem menu] numberOfItems] > 8)
            [menuItem setState:[self toolMode] == SKNoteToolMode && [self annotationMode] == (SKToolMode)[menuItem tag] ? NSOnState : NSOffState];
        else
            [menuItem setState:[self annotationMode] == (SKToolMode)[menuItem tag] ? NSOnState : NSOffState];
        return YES;
    } else if (action == @selector(copy:)) {
        if ([[self currentSelection] hasCharacters])
            return YES;
        if ([activeAnnotation isSkimNote] && [activeAnnotation isMovable])
            return YES;
        if (toolMode == SKSelectToolMode && NSIsEmptyRect(selectionRect) == NO && selectionPageIndex != NSNotFound)
            return YES;
        return NO;
    } else if (action == @selector(cut:)) {
        if ([activeAnnotation isSkimNote] && [activeAnnotation isMovable])
            return YES;
        return NO;
    } else if (action == @selector(paste:)) {
        return nil != [[NSPasteboard generalPasteboard] availableTypeFromArray:[NSArray arrayWithObjects:SKSkimNotePboardType, NSStringPboardType, nil]];
    } else if (action == @selector(alternatePaste:)) {
        return nil != [[NSPasteboard generalPasteboard] availableTypeFromArray:[NSArray arrayWithObjects:SKSkimNotePboardType, NSRTFPboardType, NSStringPboardType, nil]];
    } else if (action == @selector(pasteAsPlainText:)) {
        return nil != [[NSPasteboard generalPasteboard] availableTypeFromArray:[NSArray arrayWithObjects:NSRTFPboardType, NSStringPboardType, nil]];
    } else if (action == @selector(delete:)) {
        return [activeAnnotation isSkimNote];
    } else if (action == @selector(printDocument:)) {
        return [[self document] allowsPrinting];
    } else if (action == @selector(selectAll:)) {
        return toolMode == SKTextToolMode;
    } else if (action == @selector(deselectAll:)) {
        return [[self currentSelection] hasCharacters] != 0;
    } else if (action == @selector(autoSelectContent:)) {
        return toolMode == SKSelectToolMode;
    } else {
        return [super validateMenuItem:menuItem];
    }
}

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == &SKPDFViewDefaultsObservationContext) {
        NSString *key = [keyPath substringFromIndex:7];
        if ([key isEqualToString:SKReadingBarColorKey] || [key isEqualToString:SKReadingBarInvertKey]) {
            if (readingBar) {
                [self setNeedsDisplay:YES];
                [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewReadingBarDidChangeNotification 
                    object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[readingBar page], SKPDFViewOldPageKey, [readingBar page], SKPDFViewNewPageKey, nil]];
            }
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)transformCGContext:(CGContextRef)context forPage:(PDFPage *)page {
    NSRect boxRect = [page boundsForBox:[self displayBox]];
    
    switch ([page rotation]) {
        case 0:
            CGContextTranslateCTM(context, -NSMinX(boxRect), -NSMinY(boxRect));
            break;
        case 90:
            CGContextRotateCTM(context, - M_PI / 2);
            CGContextTranslateCTM(context, -NSMaxX(boxRect), -NSMinY(boxRect));
            break;
        case 180:
            CGContextRotateCTM(context, M_PI);
            CGContextTranslateCTM(context, -NSMaxX(boxRect), -NSMaxY(boxRect));
            break;
        case 270:
            CGContextRotateCTM(context, M_PI / 2);
            CGContextTranslateCTM(context, -NSMinX(boxRect), -NSMaxY(boxRect));
            break;
    }
}

- (NSRect)visibleContentRect {
    NSView *clipView = [[[self documentView] enclosingScrollView] contentView];
    return [clipView convertRect:[clipView visibleRect] toView:self];
}

- (NSRange)visiblePageIndexRange {
    NSRange range = NSMakeRange(NSNotFound, 0);
    NSArray *pages = [self visiblePages];
    if ([pages count]) {
        NSUInteger first = [[pages objectAtIndex:0] pageIndex];
        NSUInteger last = [[pages lastObject] pageIndex];
        range = NSMakeRange(first, last - first + 1);
    }
    return range;
}

#pragma mark FullScreen navigation and autohide

- (void)handleWindowWillCloseNotification:(NSNotification *)notification {
    if ([self isEditing] && [self commitEditing] == NO)
        [self discardEditing];
    [navWindow orderOut:self];
}

- (void)enableNavigationForScreen:(NSScreen *)screen {
    navigationMode = [[NSUserDefaults standardUserDefaults] integerForKey:interactionMode == SKPresentationMode ? SKPresentationNavigationOptionKey : SKFullScreenNavigationOptionKey];
    
    // always recreate the navWindow, since moving between screens of different resolution can mess up the location (in spite of moveToScreen:)
    if (navWindow != nil)
        [navWindow release];
    else
        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(handleWindowWillCloseNotification:) 
                                                     name: NSWindowWillCloseNotification object: [self window]];
    navWindow = [[SKNavigationWindow alloc] initWithPDFView:self hasSlider:interactionMode == SKFullScreenMode];
    [navWindow moveToScreen:screen];
    [navWindow setLevel:[[self window] level] + 1];
    
    [self doAutohide:YES];
}

- (void)disableNavigation {
    navigationMode = SKNavigationNone;
    
    [self showNavWindow:NO];
    [self doAutohide:NO];
    [navWindow orderOut:self];
}

- (void)doAutohideDelayed {
    if (NSPointInRect([NSEvent mouseLocation], [navWindow frame]))
        return;
    if (interactionMode == SKPresentationMode)
        [NSCursor setHiddenUntilMouseMoves:YES];
    if (interactionMode != SKNormalMode)
        [navWindow fadeOut];
}

- (void)doAutohide:(BOOL)flag {
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(doAutohideDelayed) object:nil];
    if (flag)
        [self performSelector:@selector(doAutohideDelayed) withObject:nil afterDelay:3.0];
}

- (void)showNavWindowDelayed {
    if ([navWindow isVisible] == NO && [[self window] mouseLocationOutsideOfEventStream].y < 3.0)
        [navWindow fadeIn];
}

- (void)showNavWindow:(BOOL)flag {
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(showNavWindowDelayed) object:nil];
    if (flag)
        [self performSelector:@selector(showNavWindowDelayed) withObject:nil afterDelay:0.25];
}

#pragma mark Event handling

- (PDFDestination *)destinationForEvent:(NSEvent *)theEvent isLink:(BOOL *)isLink {
    NSPoint windowMouseLoc = [theEvent locationInWindow];
    
    NSPoint viewMouseLoc = [self convertPoint:windowMouseLoc fromView:nil];
    PDFPage *page = [self pageForPoint:viewMouseLoc nearest:YES];
    NSPoint pageSpaceMouseLoc = [self convertPoint:viewMouseLoc toPage:page];  
    PDFDestination *dest = [[[PDFDestination alloc] initWithPage:page atPoint:pageSpaceMouseLoc] autorelease];
    BOOL doLink = NO;
    
    if (([self areaOfInterestForMouse: theEvent] &  kPDFLinkArea) != 0) {
        PDFAnnotation *ann = [page annotationAtPoint:pageSpaceMouseLoc];
        if (ann != NULL && [[ann destination] page]){
            dest = [ann destination];
            doLink = YES;
        } 
        // Set link = NO if the annotation links outside the document (e.g. for a URL); currently this is only used for the tool tip window.  We could do something clever like show a URL icon in the tool tip window (or a WebView!), but for now we'll just ignore these links.
    }
    
    if (isLink) *isLink = doLink;
    return dest;
}

- (void)doMoveActiveAnnotationForKey:(unichar)eventChar byAmount:(CGFloat)delta {
    NSRect bounds = [activeAnnotation bounds];
    NSRect newBounds = bounds;
    PDFPage *page = [activeAnnotation page];
    NSRect pageBounds = [page boundsForBox:[self displayBox]];
    
    switch ([page rotation]) {
        case 0:
            if (eventChar == NSRightArrowFunctionKey) {
                if (NSMaxX(bounds) + delta <= NSMaxX(pageBounds))
                    newBounds.origin.x += delta;
                else if (NSMaxX(bounds) < NSMaxX(pageBounds))
                    newBounds.origin.x += NSMaxX(pageBounds) - NSMaxX(bounds);
            } else if (eventChar == NSLeftArrowFunctionKey) {
                if (NSMinX(bounds) - delta >= NSMinX(pageBounds))
                    newBounds.origin.x -= delta;
                else if (NSMinX(bounds) > NSMinX(pageBounds))
                    newBounds.origin.x -= NSMinX(bounds) - NSMinX(pageBounds);
            } else if (eventChar == NSUpArrowFunctionKey) {
                if (NSMaxY(bounds) + delta <= NSMaxY(pageBounds))
                    newBounds.origin.y += delta;
                else if (NSMaxY(bounds) < NSMaxY(pageBounds))
                    newBounds.origin.y += NSMaxY(pageBounds) - NSMaxY(bounds);
            } else if (eventChar == NSDownArrowFunctionKey) {
                if (NSMinY(bounds) - delta >= NSMinY(pageBounds))
                    newBounds.origin.y -= delta;
                else if (NSMinY(bounds) > NSMinY(pageBounds))
                    newBounds.origin.y -= NSMinY(bounds) - NSMinY(pageBounds);
            }
            break;
        case 90:
            if (eventChar == NSRightArrowFunctionKey) {
                if (NSMaxY(bounds) + delta <= NSMaxY(pageBounds))
                    newBounds.origin.y += delta;
            } else if (eventChar == NSLeftArrowFunctionKey) {
                if (NSMinY(bounds) - delta >= NSMinY(pageBounds))
                    newBounds.origin.y -= delta;
            } else if (eventChar == NSUpArrowFunctionKey) {
                if (NSMinX(bounds) - delta >= NSMinX(pageBounds))
                    newBounds.origin.x -= delta;
            } else if (eventChar == NSDownArrowFunctionKey) {
                if (NSMaxX(bounds) + delta <= NSMaxX(pageBounds))
                    newBounds.origin.x += delta;
            }
            break;
        case 180:
            if (eventChar == NSRightArrowFunctionKey) {
                if (NSMinX(bounds) - delta >= NSMinX(pageBounds))
                    newBounds.origin.x -= delta;
            } else if (eventChar == NSLeftArrowFunctionKey) {
                if (NSMaxX(bounds) + delta <= NSMaxX(pageBounds))
                    newBounds.origin.x += delta;
            } else if (eventChar == NSUpArrowFunctionKey) {
                if (NSMinY(bounds) - delta >= NSMinY(pageBounds))
                    newBounds.origin.y -= delta;
            } else if (eventChar == NSDownArrowFunctionKey) {
                if (NSMaxY(bounds) + delta <= NSMaxY(pageBounds))
                    newBounds.origin.y += delta;
            }
            break;
        case 270:
            if (eventChar == NSRightArrowFunctionKey) {
                if (NSMinY(bounds) - delta >= NSMinY(pageBounds))
                    newBounds.origin.y -= delta;
            } else if (eventChar == NSLeftArrowFunctionKey) {
                if (NSMaxY(bounds) + delta <= NSMaxY(pageBounds))
                    newBounds.origin.y += delta;
            } else if (eventChar == NSUpArrowFunctionKey) {
                if (NSMaxX(bounds) + delta <= NSMaxX(pageBounds))
                    newBounds.origin.x += delta;
            } else if (eventChar == NSDownArrowFunctionKey) {
                if (NSMinX(bounds) - delta >= NSMinX(pageBounds))
                    newBounds.origin.x -= delta;
            }
            break;
    }
    
    if (NSEqualRects(bounds, newBounds) == NO) {
        [activeAnnotation setBounds:newBounds];
        if ([[NSUserDefaults standardUserDefaults] boolForKey:SKDisableUpdateContentsFromEnclosedTextKey] == NO &&
            ([[activeAnnotation type] isEqualToString:SKNCircleString] || [[activeAnnotation type] isEqualToString:SKNSquareString])) {
            NSString *selString = [[[activeAnnotation page] selectionForRect:newBounds] cleanedString];
            if ([selString length])
                [activeAnnotation setString:selString];
        }
    }
}

- (void)doResizeActiveAnnotationForKey:(unichar)eventChar byAmount:(CGFloat)delta {
    NSRect bounds = [activeAnnotation bounds];
    NSRect newBounds = bounds;
    PDFPage *page = [activeAnnotation page];
    NSRect pageBounds = [page boundsForBox:[self displayBox]];
    
    if ([[activeAnnotation type] isEqualToString:SKNLineString]) {
        
        PDFAnnotationLine *annotation = (PDFAnnotationLine *)activeAnnotation;
        NSPoint startPoint = SKIntegralPoint(SKAddPoints([annotation startPoint], bounds.origin));
        NSPoint endPoint = SKIntegralPoint(SKAddPoints([annotation endPoint], bounds.origin));
        NSPoint oldEndPoint = endPoint;
        
        // Resize the annotation.
        switch ([page rotation]) {
            case 0:
                if (eventChar == NSRightArrowFunctionKey) {
                    endPoint.x += delta;
                    if (endPoint.x > NSMaxX(pageBounds))
                        endPoint.x = NSMaxX(pageBounds);
                } else if (eventChar == NSLeftArrowFunctionKey) {
                    endPoint.x -= delta;
                    if (endPoint.x < NSMinX(pageBounds))
                        endPoint.x = NSMinX(pageBounds);
                } else if (eventChar == NSUpArrowFunctionKey) {
                    endPoint.y += delta;
                    if (endPoint.y > NSMaxY(pageBounds))
                        endPoint.y = NSMaxY(pageBounds);
                } else if (eventChar == NSDownArrowFunctionKey) {
                    endPoint.y -= delta;
                    if (endPoint.y < NSMinY(pageBounds))
                        endPoint.y = NSMinY(pageBounds);
                }
                break;
            case 90:
                if (eventChar == NSRightArrowFunctionKey) {
                    endPoint.y += delta;
                    if (endPoint.y > NSMaxY(pageBounds))
                        endPoint.y = NSMaxY(pageBounds);
                } else if (eventChar == NSLeftArrowFunctionKey) {
                    endPoint.y -= delta;
                    if (endPoint.y < NSMinY(pageBounds))
                        endPoint.y = NSMinY(pageBounds);
                } else if (eventChar == NSUpArrowFunctionKey) {
                    endPoint.x -= delta;
                    if (endPoint.x < NSMinX(pageBounds))
                        endPoint.x = NSMinX(pageBounds);
                } else if (eventChar == NSDownArrowFunctionKey) {
                    endPoint.x += delta;
                    if (endPoint.x > NSMaxX(pageBounds))
                        endPoint.x = NSMaxX(pageBounds);
                }
                break;
            case 180:
                if (eventChar == NSRightArrowFunctionKey) {
                    endPoint.x -= delta;
                    if (endPoint.x < NSMinX(pageBounds))
                        endPoint.x = NSMinX(pageBounds);
                } else if (eventChar == NSLeftArrowFunctionKey) {
                    endPoint.x += delta;
                    if (endPoint.x > NSMaxX(pageBounds))
                        endPoint.x = NSMaxX(pageBounds);
                } else if (eventChar == NSUpArrowFunctionKey) {
                    endPoint.y -= delta;
                    if (endPoint.y < NSMinY(pageBounds))
                        endPoint.y = NSMinY(pageBounds);
                } else if (eventChar == NSDownArrowFunctionKey) {
                    endPoint.y += delta;
                    if (endPoint.y > NSMaxY(pageBounds))
                        endPoint.y = NSMaxY(pageBounds);
                }
                break;
            case 270:
                if (eventChar == NSRightArrowFunctionKey) {
                    endPoint.y -= delta;
                    if (endPoint.y < NSMinY(pageBounds))
                        endPoint.y = NSMinY(pageBounds);
                } else if (eventChar == NSLeftArrowFunctionKey) {
                    endPoint.y += delta;
                    if (endPoint.y > NSMaxY(pageBounds))
                        endPoint.y = NSMaxY(pageBounds);
                } else if (eventChar == NSUpArrowFunctionKey) {
                    endPoint.x += delta;
                    if (endPoint.x > NSMaxX(pageBounds))
                        endPoint.x = NSMaxX(pageBounds);
                } else if (eventChar == NSDownArrowFunctionKey) {
                    endPoint.x -= delta;
                    if (endPoint.x < NSMinX(pageBounds))
                        endPoint.x = NSMinX(pageBounds);
                }
                break;
        }
        
        endPoint.x = SKFloor(endPoint.x);
        endPoint.y = SKFloor(endPoint.y);
        
        if (NSEqualPoints(endPoint, oldEndPoint) == NO) {
            newBounds = SKIntegralRectFromPoints(startPoint, endPoint);
            
            if (NSWidth(newBounds) < 8.0) {
                newBounds.size.width = 8.0;
                newBounds.origin.x = SKFloor(0.5 * (startPoint.x + endPoint.x) - 4.0);
            }
            if (NSHeight(newBounds) < 8.0) {
                newBounds.size.height = 8.0;
                newBounds.origin.y = SKFloor(0.5 * (startPoint.y + endPoint.y) - 4.0);
            }
            
            startPoint = SKSubstractPoints(startPoint, newBounds.origin);
            endPoint = SKSubstractPoints(endPoint, newBounds.origin);
            
            [annotation setBounds:newBounds];
            [annotation setStartPoint:startPoint];
            [annotation setEndPoint:endPoint];
        }
        
    } else {
        
        switch ([page rotation]) {
            case 0:
                if (eventChar == NSRightArrowFunctionKey) {
                    if (NSMaxX(bounds) + delta <= NSMaxX(pageBounds)) {
                        newBounds.size.width += delta;
                    } else if (NSMaxX(bounds) < NSMaxX(pageBounds)) {
                        newBounds.size.width += NSMaxX(pageBounds) - NSMaxX(bounds);
                    }
                } else if (eventChar == NSLeftArrowFunctionKey) {
                    newBounds.size.width -= delta;
                    if (NSWidth(newBounds) < 8.0) {
                        newBounds.size.width = 8.0;
                    }
                } else if (eventChar == NSUpArrowFunctionKey) {
                    newBounds.origin.y += delta;
                    newBounds.size.height -= delta;
                    if (NSHeight(newBounds) < 8.0) {
                        newBounds.origin.y += NSHeight(newBounds) - 8.0;
                        newBounds.size.height = 8.0;
                    }
                } else if (eventChar == NSDownArrowFunctionKey) {
                    if (NSMinY(bounds) - delta >= NSMinY(pageBounds)) {
                        newBounds.origin.y -= delta;
                        newBounds.size.height += delta;
                    } else if (NSMinY(bounds) > NSMinY(pageBounds)) {
                        newBounds.origin.y -= NSMinY(bounds) - NSMinY(pageBounds);
                        newBounds.size.height += NSMinY(bounds) - NSMinY(pageBounds);
                    }
                }
                break;
            case 90:
                if (eventChar == NSRightArrowFunctionKey) {
                    if (NSMinY(bounds) + delta <= NSMaxY(pageBounds)) {
                        newBounds.size.height += delta;
                    } else if (NSMinY(bounds) < NSMaxY(pageBounds)) {
                        newBounds.size.height += NSMaxY(pageBounds) - NSMinY(bounds);
                    }
                } else if (eventChar == NSLeftArrowFunctionKey) {
                    newBounds.size.height -= delta;
                    if (NSHeight(newBounds) < 8.0) {
                        newBounds.size.height = 8.0;
                    }
                } else if (eventChar == NSUpArrowFunctionKey) {
                    newBounds.size.width -= delta;
                    if (NSWidth(newBounds) < 8.0) {
                        newBounds.size.width = 8.0;
                    }
                } else if (eventChar == NSDownArrowFunctionKey) {
                    if (NSMaxX(bounds) + delta <= NSMaxX(pageBounds)) {
                        newBounds.size.width += delta;
                    } else if (NSMaxX(bounds) < NSMaxX(pageBounds)) {
                        newBounds.size.width += NSMaxX(pageBounds) - NSMaxX(bounds);
                    }
                }
                break;
            case 180:
                if (eventChar == NSRightArrowFunctionKey) {
                    if (NSMinX(bounds) - delta >= NSMinX(pageBounds)) {
                        newBounds.origin.x -= delta;
                        newBounds.size.width += delta;
                    } else if (NSMinX(bounds) > NSMinX(pageBounds)) {
                        newBounds.origin.x -= NSMinX(bounds) - NSMinX(pageBounds);
                        newBounds.size.width += NSMinX(bounds) - NSMinX(pageBounds);
                    }
                } else if (eventChar == NSLeftArrowFunctionKey) {
                    newBounds.origin.x += delta;
                    newBounds.size.width -= delta;
                    if (NSWidth(newBounds) < 8.0) {
                        newBounds.origin.x += NSWidth(newBounds) - 8.0;
                        newBounds.size.width = 8.0;
                    }
                } else if (eventChar == NSUpArrowFunctionKey) {
                    newBounds.size.height -= delta;
                    if (NSHeight(newBounds) < 8.0) {
                        newBounds.size.height = 8.0;
                    }
                } else if (eventChar == NSDownArrowFunctionKey) {
                    if (NSMaxY(bounds) + delta <= NSMaxY(pageBounds)) {
                        newBounds.size.height += delta;
                    } else if (NSMaxY(bounds) < NSMaxY(pageBounds)) {
                        newBounds.size.height += NSMaxY(pageBounds) - NSMaxY(bounds);
                    }
                }
                break;
            case 270:
                if (eventChar == NSRightArrowFunctionKey) {
                    if (NSMinY(bounds) - delta >= NSMinY(pageBounds)) {
                        newBounds.origin.y -= delta;
                        newBounds.size.height += delta;
                    } else if (NSMinY(bounds) > NSMinY(pageBounds)) {
                        newBounds.origin.y -= NSMinY(bounds) - NSMinY(pageBounds);
                        newBounds.size.height += NSMinY(bounds) - NSMinY(pageBounds);
                    }
                } else if (eventChar == NSLeftArrowFunctionKey) {
                    newBounds.origin.y += delta;
                    newBounds.size.height -= delta;
                    if (NSHeight(newBounds) < 8.0) {
                        newBounds.origin.y += NSHeight(newBounds) - 8.0;
                        newBounds.size.height = 8.0;
                    }
                } else if (eventChar == NSUpArrowFunctionKey) {
                    newBounds.origin.x += delta;
                    newBounds.size.width -= delta;
                    if (NSWidth(newBounds) < 8.0) {
                        newBounds.origin.x += NSWidth(newBounds) - 8.0;
                        newBounds.size.width = 8.0;
                    }
                } else if (eventChar == NSDownArrowFunctionKey) {
                    if (NSMinX(bounds) - delta >= NSMinX(pageBounds)) {
                        newBounds.origin.x -= delta;
                        newBounds.size.width += delta;
                    } else if (NSMinX(bounds) > NSMinX(pageBounds)) {
                        newBounds.origin.x -= NSMinX(bounds) - NSMinX(pageBounds);
                        newBounds.size.width += NSMinX(bounds) - NSMinX(pageBounds);
                    }
                }
                break;
        }
        
        if (NSEqualRects(bounds, newBounds) == NO) {
            [activeAnnotation setBounds:newBounds];
            if ([[NSUserDefaults standardUserDefaults] boolForKey:SKDisableUpdateContentsFromEnclosedTextKey] == NO &&
                ([[activeAnnotation type] isEqualToString:SKNCircleString] || [[activeAnnotation type] isEqualToString:SKNSquareString])) {
                NSString *selString = [[[activeAnnotation page] selectionForRect:newBounds] cleanedString];
                if ([selString length])
                    [activeAnnotation setString:selString];
            }
        }
    }
}

- (void)doMoveReadingBarForKey:(unichar)eventChar {
    BOOL moved = NO;
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:[readingBar page], SKPDFViewOldPageKey, nil];
    if (eventChar == NSDownArrowFunctionKey)
        moved = [readingBar goToNextLine];
    else if (eventChar == NSUpArrowFunctionKey)
        moved = [readingBar goToPreviousLine];
    else if (eventChar == NSRightArrowFunctionKey)
        moved = [readingBar goToNextPage];
    else if (eventChar == NSLeftArrowFunctionKey)
        moved = [readingBar goToPreviousPage];
    if (moved) {
        NSRect rect = NSInsetRect([readingBar currentBounds], 0.0, -20.0) ;
        if ([self displayMode] == kPDFDisplaySinglePageContinuous || [self displayMode] == kPDFDisplayTwoUpContinuous) {
            NSRect visibleRect = [self convertRect:[[self documentView] visibleRect] fromView:[self documentView]];
            visibleRect = [self convertRect:visibleRect toPage:[readingBar page]];
            rect = NSInsetRect(rect, 0.0, - SKFloor( ( NSHeight(visibleRect) - NSHeight(rect) ) / 2.0 ) );
        }
        [self scrollRect:rect inPageToVisible:[readingBar page]];
        [self setNeedsDisplay:YES];
        [userInfo setObject:[readingBar page] forKey:SKPDFViewNewPageKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewReadingBarDidChangeNotification object:self userInfo:userInfo];
    }
}

- (void)doResizeReadingBarForKey:(unichar)eventChar {
    NSInteger numberOfLines = [readingBar numberOfLines];
    if (eventChar == NSDownArrowFunctionKey)
        numberOfLines++;
    else if (eventChar == NSUpArrowFunctionKey)
        numberOfLines--;
    if (numberOfLines > 0) {
        [self setNeedsDisplayInRect:[readingBar currentBoundsForBox:[self displayBox]] ofPage:[readingBar page]];
        [readingBar setNumberOfLines:numberOfLines];
        [[NSUserDefaults standardUserDefaults] setInteger:numberOfLines forKey:SKReadingBarNumberOfLinesKey];
        [self setNeedsDisplayInRect:[readingBar currentBoundsForBox:[self displayBox]] ofPage:[readingBar page]];
        [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewReadingBarDidChangeNotification object:self 
            userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[readingBar page], SKPDFViewOldPageKey, [readingBar page], SKPDFViewNewPageKey, nil]];
    }
}

- (void)doDragAnnotationWithEvent:(NSEvent *)theEvent originalBounds:(NSRect)originalBounds originalStartPoint:(NSPoint)originalStartPoint originalEndPoint:(NSPoint)originalEndPoint offset:(NSPoint)offset {
    PDFPage *page = [activeAnnotation page];
    NSRect newBounds;
    NSRect currentBounds = [activeAnnotation bounds];
    NSRect pageBounds = [page  boundsForBox:[self displayBox]];
    
    if (dragMask != 0) {
        NSPoint mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        NSPoint startPoint = [self convertPoint:[self convertPoint:mouseDownLoc fromView:nil] toPage:page];
        NSPoint endPt = [self convertPoint:mouseLoc toPage:page];
        NSPoint relPoint = SKSubstractPoints(endPt, startPoint);
        newBounds = originalBounds;
        
        if ([[activeAnnotation type] isEqualToString:SKNLineString]) {
            
            PDFAnnotationLine *annotation = (PDFAnnotationLine *)activeAnnotation;
            NSPoint endPoint = originalEndPoint;
            startPoint = originalStartPoint;
            NSPoint *draggedPoint = (dragMask & BDSKMinXEdgeMask) ? &startPoint : &endPoint;
            
            *draggedPoint = SKConstrainPointInRect(SKAddPoints(*draggedPoint, relPoint), pageBounds);
            draggedPoint->x = SKFloor(draggedPoint->x);
            draggedPoint->y = SKFloor(draggedPoint->y);
            
            newBounds = SKIntegralRectFromPoints(startPoint, endPoint);
            
            if (NSWidth(newBounds) < 8.0) {
                newBounds.size.width = 8.0;
                newBounds.origin.x = SKFloor(0.5 * (startPoint.x + endPoint.x) - 4.0);
            }
            if (NSHeight(newBounds) < 8.0) {
                newBounds.size.height = 8.0;
                newBounds.origin.y = SKFloor(0.5 * (startPoint.y + endPoint.y) - 4.0);
            }
            
            if ([theEvent modifierFlags] & NSShiftKeyMask) {
                NSPoint *fixedPoint = (dragMask & BDSKMinXEdgeMask) ? &endPoint : &startPoint;
                NSPoint diffPoint = SKSubstractPoints(*draggedPoint, *fixedPoint);
                CGFloat dx = SKAbs(diffPoint.x), dy = SKAbs(diffPoint.y);
                
                if (dx < 0.4 * dy) {
                    diffPoint.x = 0.0;
                } else if (dy < 0.4 * dx) {
                    diffPoint.y = 0.0;
                } else {
                    dx = SKMin(dx, dy);
                    diffPoint.x = diffPoint.x < 0.0 ? -dx : dx;
                    diffPoint.y = diffPoint.y < 0.0 ? -dx : dx;
                }
                *draggedPoint = SKAddPoints(*fixedPoint, diffPoint);
            }
            
            startPoint = SKSubstractPoints(startPoint, newBounds.origin);
            endPoint = SKSubstractPoints(endPoint, newBounds.origin);
            
            [annotation setStartPoint:startPoint];
            [annotation setEndPoint:endPoint];
            
        } else {
            
            if ((dragMask & BDSKMinXEdgeMask) && (dragMask & BDSKMaxXEdgeMask))
                dragMask &= relPoint.x < 0.0 ? ~BDSKMaxXEdgeMask : ~BDSKMinXEdgeMask;
            if ((dragMask & BDSKMinYEdgeMask) && (dragMask & BDSKMaxYEdgeMask))
                dragMask &= relPoint.y <= 0.0 ? ~BDSKMaxYEdgeMask : ~BDSKMinYEdgeMask;
            
            if ([theEvent modifierFlags] & NSShiftKeyMask) {
                CGFloat width = NSWidth(newBounds);
                CGFloat height = NSHeight(newBounds);
                
                if (dragMask & BDSKMaxXEdgeMask)
                    width = SKMax(8.0, width + relPoint.x);
                else if (dragMask & BDSKMinXEdgeMask)
                    width = SKMax(8.0, width - relPoint.x);
                if (dragMask & BDSKMaxYEdgeMask)
                    height = SKMax(8.0, height + relPoint.y);
                else if (dragMask & BDSKMinYEdgeMask)
                    height = SKMax(8.0, height - relPoint.y);
                
                if (dragMask & (BDSKMinXEdgeMask | BDSKMaxXEdgeMask)) {
                    if (dragMask & (BDSKMinYEdgeMask | BDSKMaxYEdgeMask))
                        width = height = SKMax(width, height);
                    else
                        height = width;
                } else {
                    width = height;
                }
                
                if (dragMask & BDSKMinXEdgeMask) {
                    if (NSMaxX(newBounds) - width < NSMinX(pageBounds))
                        width = height = SKMax(8.0, NSMaxX(newBounds) - NSMinX(pageBounds));
                } else {
                    if (NSMinX(newBounds) + width > NSMaxX(pageBounds))
                        width = height = SKMax(8.0, NSMaxX(pageBounds) - NSMinX(newBounds));
                }
                if (dragMask & BDSKMinYEdgeMask) {
                    if (NSMaxY(newBounds) - height < NSMinY(pageBounds))
                        width = height = SKMax(8.0, NSMaxY(newBounds) - NSMinY(pageBounds));
                } else {
                    if (NSMinY(newBounds) + height > NSMaxY(pageBounds))
                        width = height = SKMax(8.0, NSMaxY(pageBounds) - NSMinY(newBounds));
                }
                
                if (dragMask & BDSKMinXEdgeMask)
                    newBounds.origin.x = NSMaxX(newBounds) - width;
                if (dragMask & BDSKMinYEdgeMask)
                    newBounds.origin.y = NSMaxY(newBounds) - height;
                newBounds.size.width = width;
                newBounds.size.height = height;
               
            } else {
                if (dragMask & BDSKMaxXEdgeMask) {
                    newBounds.size.width += relPoint.x;
                    if (NSMaxX(newBounds) > NSMaxX(pageBounds))
                        newBounds.size.width = NSMaxX(pageBounds) - NSMinX(newBounds);
                    if (NSWidth(newBounds) < 8.0) {
                        newBounds.size.width = 8.0;
                    }
                } else if (dragMask & BDSKMinXEdgeMask) {
                    newBounds.origin.x += relPoint.x;
                    newBounds.size.width -= relPoint.x;
                    if (NSMinX(newBounds) < NSMinX(pageBounds)) {
                        newBounds.size.width = NSMaxX(newBounds) - NSMinX(pageBounds);
                        newBounds.origin.x = NSMinX(pageBounds);
                    }
                    if (NSWidth(newBounds) < 8.0) {
                        newBounds.origin.x = NSMaxX(newBounds) - 8.0;
                        newBounds.size.width = 8.0;
                    }
                }
                if (dragMask & BDSKMaxYEdgeMask) {
                    newBounds.size.height += relPoint.y;
                    if (NSMaxY(newBounds) > NSMaxY(pageBounds)) {
                        newBounds.size.height = NSMaxY(pageBounds) - NSMinY(newBounds);
                    }
                    if (NSHeight(newBounds) < 8.0) {
                        newBounds.size.height = 8.0;
                    }
                } else if (dragMask & BDSKMinYEdgeMask) {
                    newBounds.origin.y += relPoint.y;
                    newBounds.size.height -= relPoint.y;
                    if (NSMinY(newBounds) < NSMinY(pageBounds)) {
                        newBounds.size.height = NSMaxY(newBounds) - NSMinY(pageBounds);
                        newBounds.origin.y = NSMinY(pageBounds);
                    }
                    if (NSHeight(newBounds) < 8.0) {
                        newBounds.origin.y = NSMaxY(newBounds) - 8.0;
                        newBounds.size.height = 8.0;
                    }
                }
            }
            // Keep integer.
            newBounds = NSIntegralRect(newBounds);
            
        }
    } else {
        // Move annotation.
        [[self documentView] autoscroll:theEvent];
        
        NSPoint mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        PDFPage *newActivePage = [self pageForPoint:mouseLoc nearest:YES];
        
        pageBounds = [newActivePage  boundsForBox:[self displayBox]];
        
        if (newActivePage == nil) {
            // this should never happen, but just to be sure
            newBounds = originalBounds;
        } else {
            if (newActivePage != page) {
                // move the annotation to the new page
                [self moveAnnotation:activeAnnotation toPage:newActivePage];
                page = newActivePage;
            }
            
            newBounds = currentBounds;
            newBounds.origin = SKIntegralPoint(SKSubstractPoints([self convertPoint:mouseLoc toPage:page], offset));
            // constrain bounds inside page bounds
            newBounds = SKConstrainRect(newBounds, pageBounds);
        }
    }
    
    // Change annotation's location.
    [activeAnnotation setBounds:newBounds];
}

- (BOOL)doSelectAnnotationWithEvent:(NSEvent *)theEvent {
    PDFAnnotation *newActiveAnnotation = nil;
    NSArray *annotations;
    NSInteger i;
    NSPoint pagePoint;
    PDFPage *page;
    
    // Mouse in display view coordinates.
    mouseDownLoc = [theEvent locationInWindow];
    
    NSPoint mouseDownOnPage = [self convertPoint:mouseDownLoc fromView:nil];
    
    // Page we're on.
    page = [self pageForPoint:mouseDownOnPage nearest:YES];
    
    // Get mouse in "page space".
    pagePoint = [self convertPoint:mouseDownOnPage toPage:page];
    
    // Hit test for annotation.
    annotations = [page annotations];
    i = [annotations count];
    
    while (i-- > 0) {
        PDFAnnotation *annotation = [annotations objectAtIndex:i];
        NSRect bounds = [annotation bounds];
        
        // Hit test annotation.
        if ([annotation isSkimNote]) {
            if ([annotation hitTest:pagePoint] && (editField == nil || annotation != activeAnnotation)) {
                mouseDownInAnnotation = YES;
                newActiveAnnotation = annotation;
                break;
            } else if (NSPointInRect(pagePoint, bounds)) {
                // register this, so we can do our own selection later
                mouseDownInAnnotation = YES;
            }
        } else if (NSPointInRect(pagePoint, bounds)) {
            if ([annotation isTemporaryAnnotation]) {
                // register this, so we can do our own selection later
                mouseDownInAnnotation = YES;
            } else if ([annotation isLink]) {
                if (mouseDownInAnnotation && (toolMode == SKTextToolMode || annotationMode == SKHighlightNote || annotationMode == SKUnderlineNote || annotationMode == SKStrikeOutNote))
                    newActiveAnnotation = annotation;
                break;
            }
        }
    }
    
    if (hideNotes == NO && page != nil) {
        if (([theEvent modifierFlags] & NSAlternateKeyMask) && [newActiveAnnotation isMovable]) {
            // select a new copy of the annotation
            PDFAnnotation *newAnnotation = [[PDFAnnotation alloc] initSkimNoteWithProperties:[newActiveAnnotation SkimNoteProperties]];
            [self addAnnotation:newAnnotation toPage:page];
            [[self undoManager] setActionName:NSLocalizedString(@"Add Note", @"Undo action name")];
            newActiveAnnotation = newAnnotation;
            [newAnnotation release];
        } else if (toolMode == SKNoteToolMode && newActiveAnnotation == nil &&
                   annotationMode != SKHighlightNote && annotationMode != SKUnderlineNote && annotationMode != SKStrikeOutNote && annotationMode != SKInkNote &&
                   NSPointInRect(pagePoint, [page boundsForBox:[self displayBox]])) {
            // add a new annotation immediately, unless this is just a click
            if (annotationMode == SKAnchoredNote || NSLeftMouseDragged == [[NSApp nextEventMatchingMask:(NSLeftMouseUpMask | NSLeftMouseDraggedMask) untilDate:[NSDate distantFuture] inMode:NSEventTrackingRunLoopMode dequeue:NO] type]) {
                NSSize size = annotationMode == SKAnchoredNote ? SKNPDFAnnotationNoteSize : NSZeroSize;
                NSRect bounds = SKRectFromCenterAndSize(pagePoint, size);
                [self addAnnotationWithType:annotationMode contents:nil page:page bounds:bounds];
                newActiveAnnotation = activeAnnotation;
                mouseDownInAnnotation = YES;
            }
        } else if ([newActiveAnnotation isMarkup] && NSLeftMouseDragged == [[NSApp nextEventMatchingMask:(NSLeftMouseUpMask | NSLeftMouseDraggedMask) untilDate:[NSDate distantFuture] inMode:NSEventTrackingRunLoopMode dequeue:NO] type]) {
            newActiveAnnotation = nil;
            mouseDownInAnnotation = YES;
        } else if (([theEvent modifierFlags] & NSShiftKeyMask) && [activeAnnotation isEqual:newActiveAnnotation] == NO && [[activeAnnotation page] isEqual:[newActiveAnnotation page]] && [[activeAnnotation type] isEqualToString:[newActiveAnnotation type]]) {
            if ([activeAnnotation isMarkup]) {
                NSInteger markupType = [(PDFAnnotationMarkup *)activeAnnotation markupType];
                PDFSelection *sel = [(PDFAnnotationMarkup *)activeAnnotation selection];
                [sel addSelection:[(PDFAnnotationMarkup *)newActiveAnnotation selection]];
                
                [self removeActiveAnnotation:nil];
                [self removeAnnotation:newActiveAnnotation];
                [accessibilityChildren release];
                accessibilityChildren = nil;
                
                newActiveAnnotation = [[[PDFAnnotationMarkup alloc] initSkimNoteWithSelection:sel markupType:markupType] autorelease];
                [newActiveAnnotation setString:[sel cleanedString]];
                [self addAnnotation:newActiveAnnotation toPage:page];
                [[self undoManager] setActionName:NSLocalizedString(@"Join Notes", @"Undo action name")];
            } else if ([[activeAnnotation type] isEqualToString:SKNInkString]) {
                NSMutableArray *paths = [[NSMutableArray alloc] initWithArray:[(PDFAnnotationInk *)activeAnnotation paths] copyItems:YES];
                NSArray *newPaths = [[NSArray alloc] initWithArray:[(PDFAnnotationInk *)newActiveAnnotation paths] copyItems:YES];
                
                NSAffineTransform *transform = [NSAffineTransform transform];
                NSRect bounds = [activeAnnotation bounds];
                [transform translateXBy:NSMinX(bounds) yBy:NSMinY(bounds)];
                [paths makeObjectsPerformSelector:@selector(transformUsingAffineTransform:) withObject:transform];
                transform = [NSAffineTransform transform];
                bounds = [newActiveAnnotation bounds];
                [transform translateXBy:NSMinX(bounds) yBy:NSMinY(bounds)];
                [newPaths makeObjectsPerformSelector:@selector(transformUsingAffineTransform:) withObject:transform];
                [paths addObjectsFromArray:newPaths];
                [newPaths release];
                
                [self removeAnnotation:newActiveAnnotation];
                newActiveAnnotation = [[[PDFAnnotationInk alloc] initSkimNoteWithPaths:paths] autorelease];
                [(PDFAnnotationInk *)newActiveAnnotation setString:[activeAnnotation string]];
                [(PDFAnnotationInk *)newActiveAnnotation setColor:[activeAnnotation color]];
                [(PDFAnnotationInk *)newActiveAnnotation setBorder:[activeAnnotation border]];
                [self removeActiveAnnotation:nil];
                [self addAnnotation:newActiveAnnotation toPage:page];
                [[self undoManager] setActionName:NSLocalizedString(@"Join Notes", @"Undo action name")];
                
                [paths release];
            }
        }
    }
    
    if (newActiveAnnotation) {
        
        if (activeAnnotation != newActiveAnnotation)
            [self setActiveAnnotation:newActiveAnnotation];
        
        if ([theEvent clickCount] == 2 && [activeAnnotation isSkimNote]) {
            [self editActiveAnnotation:self];
        } else { 
            // Old (current) annotation location and click point relative to it
            NSRect originalBounds = [activeAnnotation bounds];
            
            // Hit-test for resize box.
            dragMask = 0;
            if ([[activeAnnotation type] isEqualToString:SKNLineString]) {
                if (NSPointInRect(pagePoint, SKRectFromCenterAndSize(SKAddPoints(originalBounds.origin, [(PDFAnnotationLine *)activeAnnotation endPoint]), SKMakeSquareSize(8.0))))
                    dragMask = BDSKMaxXEdgeMask;
                else if (NSPointInRect(pagePoint, SKRectFromCenterAndSize(SKAddPoints(originalBounds.origin, [(PDFAnnotationLine *)activeAnnotation startPoint]), SKMakeSquareSize(8.0))))
                    dragMask = BDSKMinXEdgeMask;
            }  else if ([activeAnnotation isResizable]) {
                if (NSWidth(originalBounds) < 2.0) {
                    dragMask |= BDSKMinXEdgeMask | BDSKMaxXEdgeMask;
                } else if ([page rotation] < 180) {
                    if (pagePoint.x >= NSMaxX(originalBounds) - 4.0)
                        dragMask |= BDSKMaxXEdgeMask;
                    else if (pagePoint.x <= NSMinX(originalBounds) + 4.0)
                        dragMask |= BDSKMinXEdgeMask;
                } else {
                    if (pagePoint.x <= NSMinX(originalBounds) + 4.0)
                        dragMask |= BDSKMinXEdgeMask;
                    else if (pagePoint.x >= NSMaxX(originalBounds) - 4.0)
                        dragMask |= BDSKMaxXEdgeMask;
                }
                if (NSHeight(originalBounds) < 2.0) {
                    dragMask |= BDSKMinYEdgeMask | BDSKMaxYEdgeMask;
                } else if ([page rotation] % 270 != 0) {
                    if (pagePoint.y >= NSMaxY(originalBounds) - 4.0)
                        dragMask |= BDSKMaxYEdgeMask;
                    else if (pagePoint.y <= NSMinY(originalBounds) + 4.0)
                        dragMask |= BDSKMinYEdgeMask;
                } else {
                    if (pagePoint.y <= NSMinY(originalBounds) + 4.0)
                        dragMask |= BDSKMinYEdgeMask;
                    else if (pagePoint.y >= NSMaxY(originalBounds) - 4.0)
                        dragMask |= BDSKMaxYEdgeMask;
                }
            }
            if (dragMask)
                [self setNeedsDisplayForAnnotation:activeAnnotation];
            
            if ([activeAnnotation isMovable]) {
                // we move or resize the annotation in an event loop, which ensures it's enclosed in a single undo group
                BOOL draggedAnnotation = NO;
                NSEvent *lastMouseEvent = theEvent;
                NSPoint offset = SKSubstractPoints(pagePoint, originalBounds.origin);
                NSPoint originalStartPoint = NSZeroPoint;
                NSPoint originalEndPoint = NSZeroPoint;
                
                if ([[activeAnnotation type] isEqualToString:SKNLineString]) {
                    originalStartPoint = SKIntegralPoint(SKAddPoints([(PDFAnnotationLine *)activeAnnotation startPoint], originalBounds.origin));
                    originalEndPoint = SKIntegralPoint(SKAddPoints([(PDFAnnotationLine *)activeAnnotation endPoint], originalBounds.origin));
                }
                
                [NSEvent startPeriodicEventsAfterDelay:0.1 withPeriod:0.1];
                while (YES) {
                    theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSPeriodicMask];
                    if ([theEvent type] == NSLeftMouseUp)
                        break;
                    if ([theEvent type] == NSLeftMouseDragged) {
                        lastMouseEvent = theEvent;
                        draggedAnnotation = YES;
                    }
                    [self doDragAnnotationWithEvent:lastMouseEvent originalBounds:originalBounds originalStartPoint:originalStartPoint originalEndPoint:originalEndPoint offset:offset];
                }
                [NSEvent stopPeriodicEvents];
                if (toolMode == SKNoteToolMode && NSEqualSizes(originalBounds.size, NSZeroSize) && [[activeAnnotation type] isEqualToString:SKNFreeTextString])
                    [self editActiveAnnotation:self]; 	 
                if (draggedAnnotation && 
                    [[NSUserDefaults standardUserDefaults] boolForKey:SKDisableUpdateContentsFromEnclosedTextKey] == NO &&
                    ([[activeAnnotation type] isEqualToString:SKNCircleString] || [[activeAnnotation type] isEqualToString:SKNSquareString])) {
                    NSString *selString = [[[activeAnnotation page] selectionForRect:[activeAnnotation bounds]] cleanedString];
                    if ([selString length])
                        [activeAnnotation setString:selString];
                }
                [self setNeedsDisplayForAnnotation:activeAnnotation];
                mouseDownInAnnotation = NO;
                dragMask = 0;
            }
        }
        
        return YES;
        
    } else if (toolMode == SKNoteToolMode && annotationMode == SKInkNote && hideNotes == NO && page != nil) {
        
        [self doDrawFreehandNoteWithEvent:theEvent];
        
        return YES;
        
    } else {
        // no new active annotation
        [self setActiveAnnotation:nil];
        return NO;
    }
}

- (void)doDrawFreehandNoteWithEvent:(NSEvent *)theEvent {
    NSPoint mouseDownOnPage = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    PDFPage *page = [self pageForPoint:mouseDownOnPage nearest:YES];
    NSPoint pagePoint = [self convertPoint:mouseDownOnPage toPage:page];
    NSString *text = nil;
    PDFBorder *border = nil;
    NSBezierPath *path;
    BOOL didDraw = NO;
    BOOL isExtension = ([theEvent modifierFlags] & NSShiftKeyMask) && [[activeAnnotation type] isEqualToString:SKNInkString] && [[activeAnnotation page] isEqual:page];
    
    if (isExtension) {
        bezierPaths = [[NSArray alloc] initWithArray:[(PDFAnnotationInk *)activeAnnotation paths] copyItems:YES];
        NSAffineTransform *transform = [NSAffineTransform transform];
        NSRect bounds = [activeAnnotation bounds];
        [transform translateXBy:NSMinX(bounds) yBy:NSMinY(bounds)];
        [bezierPaths makeObjectsPerformSelector:@selector(transformUsingAffineTransform:) withObject:transform];
        text = [[[activeAnnotation string] retain] autorelease];
        border = [[[activeAnnotation border] retain] autorelease];
        pathColor = [[activeAnnotation color] retain];
        NSEnumerator *pathEnum = [bezierPaths objectEnumerator];
        while (path = [pathEnum nextObject]) {
            [path setLineCapStyle:NSRoundLineCapStyle];
            [path setLineJoinStyle:NSRoundLineJoinStyle];
            [path setLineWidth:[border lineWidth]];
        }
        [self removeActiveAnnotation:nil];
        path = [bezierPaths lastObject];
        [path lineToPoint:pagePoint];
        [self setNeedsDisplayInRect:[self convertRect:NSInsetRect([path nonEmptyBounds], -8.0, -8.0) fromPage:page]];
        didDraw = YES;
    } else {
        path = [NSBezierPath bezierPath];
        [path setLineCapStyle:NSRoundLineCapStyle];
        [path setLineJoinStyle:NSRoundLineJoinStyle];
        [path setLineWidth:[[NSUserDefaults standardUserDefaults] floatForKey:SKInkNoteLineWidthKey]];
        [path moveToPoint:pagePoint];
        bezierPaths = [[NSArray alloc] initWithObjects:path, nil];
    }
    pathPageIndex = [page pageIndex];
    
    [self setActiveAnnotation:nil];
    
    while (YES) {
        theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask];
        if ([theEvent type] == NSLeftMouseUp)
            break;
        [path lineToPoint:[self convertPoint:[self convertPoint:[theEvent locationInWindow] fromView:nil] toPage:page]];
        [self setNeedsDisplayInRect:[self convertRect:NSInsetRect([path nonEmptyBounds], -8.0, -8.0) fromPage:page]];
        didDraw = YES;
    }
    
    if (didDraw) {
        [self addAnnotationWithType:SKInkNote contents:nil page:page bounds:NSZeroRect];
        if (activeAnnotation) {
            if (isExtension) {
                [activeAnnotation setColor:pathColor];
                [activeAnnotation setBorder:border];
                [activeAnnotation setString:text];
            }
            [[self undoManager] setActionName:NSLocalizedString(@"Add Note", @"Undo action name")];
        }
    }
    
    [bezierPaths release];
    bezierPaths = nil;
    [pathColor release];
    pathColor = nil;
}

- (void)doDragWithEvent:(NSEvent *)theEvent {
	NSPoint initialLocation = [theEvent locationInWindow];
	NSRect visibleRect = [[self documentView] visibleRect];
	
    [[NSCursor closedHandCursor] push];
    
	while (YES) {
        
		theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask];
        if ([theEvent type] == NSLeftMouseUp)
            break;
        
        // dragging
        NSPoint	newLocation = [theEvent locationInWindow];
        NSPoint	delta = SKSubstractPoints(initialLocation, newLocation);
        NSRect	newVisibleRect;
        
        if ([self isFlipped])
            delta.y = -delta.y;
        
        newVisibleRect = NSOffsetRect (visibleRect, delta.x, delta.y);
        [[self documentView] scrollRectToVisible: newVisibleRect];
	}
    
    [NSCursor pop];
    // ??? PDFView's delayed layout seems to reset the cursor to an arrow
    [[self getCursorForEvent:theEvent] performSelector:@selector(set) withObject:nil afterDelay:0];
}

- (void)doSelectWithEvent:(NSEvent *)theEvent {
    NSPoint mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    
    PDFPage *page = [self pageForPoint:mouseLoc nearest:NO];
    CGFloat margin = 4.0 / [self scaleFactor];
    
    if (page == nil) {
        selectionRect = NSZeroRect;
        [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewSelectionChangedNotification object:self];
        [self setNeedsDisplay:YES];
        return;
    } else if ([page pageIndex] != selectionPageIndex && selectionPageIndex != NSNotFound) {
        [self setNeedsDisplayInRect:NSInsetRect(selectionRect, -margin, -margin) ofPage:[self currentSelectionPage]];
        [self setNeedsDisplayInRect:NSInsetRect(selectionRect, -margin, -margin) ofPage:page];
    }
    
    selectionPageIndex = [page pageIndex];
    
	NSPoint initialPoint = [self convertPoint:mouseLoc toPage:page];
    
    dragMask = 0;
    
    if (NSIsEmptyRect(selectionRect) || NSPointInRect(initialPoint, NSInsetRect(selectionRect, -margin, -margin)) == NO) {
        if (NSIsEmptyRect(selectionRect)) {
            didSelect = NO;
        } else {
            [self setNeedsDisplay:YES];
            didSelect = YES;
        }
        selectionRect.origin = initialPoint;
        selectionRect.size = NSZeroSize;
        dragMask = BDSKMaxXEdgeMask | BDSKMinYEdgeMask;
    } else {
        if (initialPoint.x > NSMaxX(selectionRect) - margin)
            dragMask |= BDSKMaxXEdgeMask;
        else if (initialPoint.x < NSMinX(selectionRect) + margin)
            dragMask |= BDSKMinXEdgeMask;
        if (initialPoint.y < NSMinY(selectionRect) + margin)
            dragMask |= BDSKMinYEdgeMask;
        else if (initialPoint.y > NSMaxY(selectionRect) - margin)
            dragMask |= BDSKMaxYEdgeMask;
        didSelect = YES;
    }
    
	NSRect initialRect = selectionRect;
    NSRect pageBounds = [page boundsForBox:[self displayBox]];
    
    if (dragMask == 0) {
        [[NSCursor closedHandCursor] push];
    } else {
        [[NSCursor crosshairCursor] push];
        [self setNeedsDisplayInRect:NSInsetRect(selectionRect, -margin, -margin) ofPage:page];
    }
    
	while (YES) {
        
		theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask];
        if ([theEvent type] == NSLeftMouseUp)
            break;
		
        // we must be dragging
        NSPoint	newPoint;
        NSRect	newRect = initialRect;
        NSPoint delta;
        
        newPoint = [self convertPoint:[self convertPoint:[theEvent locationInWindow] fromView:nil] toPage:page];
        delta = SKSubstractPoints(newPoint, initialPoint);
        
        if (dragMask == 0) {
            newRect.origin = SKAddPoints(newRect.origin, delta);
        } else if ([theEvent modifierFlags] & NSShiftKeyMask) {
            CGFloat width = NSWidth(newRect);
            CGFloat height = NSHeight(newRect);
            CGFloat square;
            
            if (dragMask & BDSKMaxXEdgeMask)
                width += delta.x;
            else if (dragMask & BDSKMinXEdgeMask)
                width -= delta.x;
            if (dragMask & BDSKMaxYEdgeMask)
                height += delta.y;
            else if (dragMask & BDSKMinYEdgeMask)
                height -= delta.y;
            
            if (dragMask & (BDSKMinXEdgeMask | BDSKMaxXEdgeMask)) {
                if (dragMask & (BDSKMinYEdgeMask | BDSKMaxYEdgeMask))
                    square = SKMax(SKAbs(width), SKAbs(height));
                else
                    square = SKAbs(width);
            } else {
                square = SKAbs(height);
            }
            
            if (dragMask & BDSKMinXEdgeMask) {
                if (width >= 0.0 && NSMaxX(newRect) - square < NSMinX(pageBounds))
                    square = NSMaxX(newRect) - NSMinX(pageBounds);
                else if (width < 0.0 && NSMaxX(newRect) + square > NSMaxX(pageBounds))
                    square =  NSMaxX(pageBounds) - NSMaxX(newRect);
            } else {
                if (width >= 0.0 && NSMinX(newRect) + square > NSMaxX(pageBounds))
                    square = NSMaxX(pageBounds) - NSMinX(newRect);
                else if (width < 0.0 && NSMinX(newRect) - square < NSMinX(pageBounds))
                    square = NSMinX(newRect) - NSMinX(pageBounds);
            }
            if (dragMask & BDSKMinYEdgeMask) {
                if (height >= 0.0 && NSMaxY(newRect) - square < NSMinY(pageBounds))
                    square = NSMaxY(newRect) - NSMinY(pageBounds);
                else if (height < 0.0 && NSMaxY(newRect) + square > NSMaxY(pageBounds))
                    square = NSMaxY(pageBounds) - NSMaxY(newRect);
            } else {
                if (height >= 0.0 && NSMinY(newRect) + square > NSMaxY(pageBounds))
                    square = NSMaxY(pageBounds) - NSMinY(newRect);
                if (height < 0.0 && NSMinY(newRect) - square < NSMinY(pageBounds))
                    square = NSMinY(newRect) - NSMinY(pageBounds);
            }
            
            if (dragMask & BDSKMinXEdgeMask)
                newRect.origin.x = width < 0.0 ? NSMaxX(newRect) : NSMaxX(newRect) - square;
            else if (width < 0.0 && (dragMask & BDSKMaxXEdgeMask))
                newRect.origin.x = NSMinX(newRect) - square;
            if (dragMask & BDSKMinYEdgeMask)
                newRect.origin.y = height < 0.0 ? NSMaxY(newRect) : NSMaxY(newRect) - square;
            else if (height < 0.0 && (dragMask & BDSKMaxYEdgeMask))
                newRect.origin.y = NSMinY(newRect) - square;
            newRect.size.width = newRect.size.height = square;
        } else {
            if (dragMask & BDSKMaxXEdgeMask) {
                newRect.size.width += delta.x;
                if (NSWidth(newRect) < 0.0) {
                    newRect.size.width *= -1.0;
                    newRect.origin.x -= NSWidth(newRect);
                }
            } else if (dragMask & BDSKMinXEdgeMask) {
                newRect.origin.x += delta.x;
                newRect.size.width -= delta.x;
                if (NSWidth(newRect) < 0.0) {
                    newRect.size.width *= -1.0;
                    newRect.origin.x -= NSWidth(newRect);
                }
            }
            
            if (dragMask & BDSKMaxYEdgeMask) {
                newRect.size.height += delta.y;
                if (NSHeight(newRect) < 0.0) {
                    newRect.size.height *= -1.0;
                    newRect.origin.y -= NSHeight(newRect);
                }
            } else if (dragMask & BDSKMinYEdgeMask) {
                newRect.origin.y += delta.y;
                newRect.size.height -= delta.y;
                if (NSHeight(newRect) < 0.0) {
                    newRect.size.height *= -1.0;
                    newRect.origin.y -= NSHeight(newRect);
                }
            }
        }
        
        // don't use NSIntersectionRect, because we want to keep empty rects
        newRect = SKIntersectionRect(newRect, pageBounds);
        if (didSelect) {
            NSRect dirtyRect = NSUnionRect(NSInsetRect(selectionRect, -margin, -margin), NSInsetRect(newRect, -margin, -margin));
            NSRange r = [self visiblePageIndexRange];
            NSUInteger i;
            for (i = r.location; i < NSMaxRange(r); i++)
                [self setNeedsDisplayInRect:dirtyRect ofPage:[[self document] pageAtIndex:i]];
        } else {
            [self setNeedsDisplay:YES];
            didSelect = YES;
        }
        selectionRect = newRect;
        [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewSelectionChangedNotification object:self];
	}
    
    didSelect = NO;
    
    if (NSIsEmptyRect(selectionRect)) {
        selectionRect = NSZeroRect;
        selectionPageIndex = NSNotFound;
        [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewSelectionChangedNotification object:self];
        [self setNeedsDisplay:YES];
    } else if (dragMask) {
        [self setNeedsDisplayInRect:NSInsetRect(selectionRect, -margin, -margin) ofPage:page];
    }
    dragMask = 0;
    
    [NSCursor pop];
    // ??? PDFView's delayed layout seems to reset the cursor to an arrow
    [[self getCursorForEvent:theEvent] performSelector:@selector(set) withObject:nil afterDelay:0];
}

- (void)doSelectTextWithEvent:(NSEvent *)theEvent {
    // reimplement text selection behavior so we can select text inside markup annotation bounds rectangles (and have a highlight and strikeout on the same line, for instance), but don't select inside an existing markup annotation
    PDFSelection *wasSelection = nil;
    NSUInteger modifiers = [theEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask;
    BOOL rectSelection = (modifiers & NSAlternateKeyMask) != 0;
    BOOL extendSelection = NO;
    
    if (rectSelection) {
        [self setCurrentSelection:nil];
    } else if ([theEvent clickCount] > 1) {
        extendSelection = YES;
        NSPoint p = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        PDFPage *page = [self pageForPoint:p nearest:YES];
        p = [self convertPoint:p toPage:page];
        if ([theEvent clickCount] == 2)
            wasSelection = [[page selectionForWordAtPoint:p] retain];
        else if ([theEvent clickCount] == 3)
            wasSelection = [[page selectionForLineAtPoint:p] retain];
        else
            wasSelection = nil;
        [self setCurrentSelection:wasSelection];
    } else if (modifiers & NSShiftKeyMask) {
        extendSelection = YES;
        if ([[self currentSelection] hasCharacters])
            wasSelection = [[self currentSelection] retain];
        NSPoint p = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        PDFPage *page = [self pageForPoint:p nearest:YES];
        p = [self convertPoint:p toPage:page];
        [self setCurrentSelection:[[self document] selectionByExtendingSelection:wasSelection toPage:page atPoint:p]];
    } else {
        [self setCurrentSelection:nil];
    }
    
    while (YES) {
		
        theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask];
		if ([theEvent type] == NSLeftMouseUp)
            break;
        
        // dragging
        // if we autoscroll, the mouseDownLoc is no longer correct as a starting point
        NSPoint mouseDownLocInDoc = [[self documentView] convertPoint:mouseDownLoc fromView:nil];
        if ([[self documentView] autoscroll:theEvent])
            mouseDownLoc = [[self documentView] convertPoint:mouseDownLocInDoc toView:nil];

        NSPoint p1 = [self convertPoint:mouseDownLoc fromView:nil];
        PDFPage *page1 = [self pageForPoint:p1 nearest:YES];
        p1 = [self convertPoint:p1 toPage:page1];

        NSPoint p2 = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        PDFPage *page2 = [self pageForPoint:p2 nearest:YES];
        p2 = [self convertPoint:p2 toPage:page2];
        
        PDFSelection *sel = nil;
        if (rectSelection) {
            // how to handle multipage selection?  Preview.app's behavior is screwy as well, so we'll do the same thing
            NSRect selRect = SKRectFromPoints(p1, p2);
            sel = [page1 selectionForRect:selRect];
            if (NSIsEmptyRect(selectionRect) == NO)
                [self setNeedsDisplayInRect:selectionRect];
            selectionRect = NSIntegralRect([self convertRect:selRect fromPage:page1]);
            [self setNeedsDisplayInRect:selectionRect];
            [[self window] flushWindow];
        } else if (extendSelection) {
            sel = [[self document] selectionByExtendingSelection:wasSelection toPage:page2 atPoint:p2];
        } else {
            sel = [[self document] selectionFromPage:page1 atPoint:p1 toPage:page2 atPoint:p2];
        }

        [self setCurrentSelection:sel];
        
    }
    
    if (rectSelection)  {
        if (NSIsEmptyRect(selectionRect) == NO) {
            [self setNeedsDisplayInRect:selectionRect];
            selectionRect = NSZeroRect;
            [[self window] flushWindow];
        } else {
            selectionRect = NSZeroRect;
        }
    }
    
    if (toolMode == SKNoteToolMode && hideNotes == NO && (annotationMode == SKHighlightNote || annotationMode == SKUnderlineNote || annotationMode == SKStrikeOutNote) && [[self currentSelection] hasCharacters]) {
        [self addAnnotationWithType:annotationMode];
        [self setCurrentSelection:nil];
    }
}

- (void)doDragReadingBarWithEvent:(NSEvent *)theEvent {
    PDFPage *page = [readingBar page];
    NSArray *lineRects = [page lineRects];
	NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:page, SKPDFViewOldPageKey, nil];
    
    NSEvent *lastMouseEvent = theEvent;
    NSPoint lastMouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    NSPoint point = [self convertPoint:lastMouseLoc toPage:page];
    NSInteger lineOffset = SKIndexOfRectAtYInOrderedRects(point.y, lineRects, YES) - [readingBar currentLine];
    NSDate *lastPageChangeDate = [NSDate distantPast];
    
    lastMouseLoc = [self convertPoint:lastMouseLoc toView:[self documentView]];
    
    [[NSCursor closedHandCursor] push];
    
    [NSEvent startPeriodicEventsAfterDelay:0.1 withPeriod:0.1];
    
	while (YES) {
		
        theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSPeriodicMask];
		
        if ([theEvent type] == NSLeftMouseUp)
            break;
		if ([theEvent type] == NSLeftMouseDragged)
            lastMouseEvent = theEvent;
        
        // dragging
        NSPoint mouseLocInWindow = [lastMouseEvent locationInWindow];
        NSPoint mouseLoc = [self convertPoint:mouseLocInWindow fromView:nil];
        if ([[self documentView] autoscroll:lastMouseEvent] == NO &&
            ([self displayMode] == kPDFDisplaySinglePage || [self displayMode] == kPDFDisplayTwoUp) &&
            [[NSDate date] timeIntervalSinceDate:lastPageChangeDate] > 0.7) {
            if (mouseLoc.y < NSMinY([self bounds])) {
                if ([self canGoToNextPage]) {
                    [self goToNextPage:self];
                    lastMouseLoc.y = NSMaxY([[self documentView] bounds]);
                    lastPageChangeDate = [NSDate date];
                }
            } else if (mouseLoc.y > NSMaxY([self bounds])) {
                if ([self canGoToPreviousPage]) {
                    [self goToPreviousPage:self];
                    lastMouseLoc.y = NSMinY([[self documentView] bounds]);
                    lastPageChangeDate = [NSDate date];
                }
            }
        }
        
        mouseLoc = [self convertPoint:mouseLocInWindow fromView:nil];
        
        PDFPage *currentPage = [self pageForPoint:mouseLoc nearest:YES];
        NSPoint mouseLocInPage = [self convertPoint:mouseLoc toPage:currentPage];
        NSPoint mouseLocInDocument = [self convertPoint:mouseLoc toView:[self documentView]];
        NSInteger currentLine;
        
        if ([currentPage isEqual:page] == NO) {
            page = currentPage;
            lineRects = [page lineRects];
        }
        
        if ([lineRects count] == 0)
            continue;
        
        currentLine = SKIndexOfRectAtYInOrderedRects(mouseLocInPage.y, lineRects, mouseLocInDocument.y < lastMouseLoc.y) - lineOffset;
        currentLine = MIN((NSInteger)[lineRects count] - (NSInteger)[readingBar numberOfLines], currentLine);
        currentLine = MAX(0, currentLine);
        
        if ([page isEqual:[readingBar page]] == NO || currentLine != [readingBar currentLine]) {
            [userInfo setObject:[readingBar page] forKey:SKPDFViewOldPageKey];
            [self setNeedsDisplayInRect:[readingBar currentBoundsForBox:[self displayBox]] ofPage:[readingBar page]];
            [readingBar setPage:currentPage];
            [readingBar setCurrentLine:currentLine];
            [self setNeedsDisplayInRect:[readingBar currentBoundsForBox:[self displayBox]] ofPage:[readingBar page]];
            [userInfo setObject:[readingBar page] forKey:SKPDFViewNewPageKey];
            [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewReadingBarDidChangeNotification object:self userInfo:userInfo];
            lastMouseLoc = mouseLocInDocument;
        }
    }
    
    [NSEvent stopPeriodicEvents];
    
    [NSCursor pop];
    // ??? PDFView's delayed layout seems to reset the cursor to an arrow
    [[self getCursorForEvent:lastMouseEvent] performSelector:@selector(set) withObject:nil afterDelay:0];
}

- (void)doResizeReadingBarWithEvent:(NSEvent *)theEvent {
    PDFPage *page = [readingBar page];
    NSInteger firstLine = [readingBar currentLine];
    NSArray *lineRects = [page lineRects];
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:page, SKPDFViewOldPageKey, page, SKPDFViewNewPageKey, nil];
    
    [[NSCursor resizeUpDownCursor] push];
    
	while (YES) {
		
        theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask];
		if ([theEvent type] == NSLeftMouseUp)
            break;
        
        // dragging
        NSPoint mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        if ([[self pageForPoint:mouseLoc nearest:YES] isEqual:page] == NO)
            continue;
        
        mouseLoc = [self convertPoint:mouseLoc toPage:page];
        NSInteger numberOfLines = MAX(0, SKIndexOfRectAtYInOrderedRects(mouseLoc.y, lineRects, YES)) - firstLine + 1;
        
        if (numberOfLines > 0 && numberOfLines != (NSInteger)[readingBar numberOfLines]) {
            [self setNeedsDisplayInRect:[readingBar currentBoundsForBox:[self displayBox]] ofPage:[readingBar page]];
            [readingBar setNumberOfLines:numberOfLines];
            [[NSUserDefaults standardUserDefaults] setInteger:numberOfLines forKey:SKReadingBarNumberOfLinesKey];
            [self setNeedsDisplayInRect:[readingBar currentBoundsForBox:[self displayBox]] ofPage:[readingBar page]];
            [self setNeedsDisplay:YES];
            [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewReadingBarDidChangeNotification object:self userInfo:userInfo];
        }
    }
    
    [NSCursor pop];
    // ??? PDFView's delayed layout seems to reset the cursor to an arrow
    [[self getCursorForEvent:theEvent] performSelector:@selector(set) withObject:nil afterDelay:0];
}

- (void)doSelectSnapshotWithEvent:(NSEvent *)theEvent {
    NSPoint mouseLoc = [theEvent locationInWindow];
	NSPoint startPoint = [[self documentView] convertPoint:mouseLoc fromView:nil];
	NSPoint	currentPoint;
    NSRect selRect = {startPoint, NSZeroSize};
    BOOL dragged = NO;
	
    [[self window] discardCachedImage];
    
    [[NSCursor cameraCursor] set];
    
	while (YES) {
		theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSFlagsChangedMask];
        
        [[self window] disableFlushWindow];
        [[self window] restoreCachedImage];
		
        if ([theEvent type] == NSLeftMouseUp) {
            [[self window] enableFlushWindow];
            [[self window] flushWindow];
            break;
        }
        
        if ([theEvent type] == NSLeftMouseDragged) {
            // change mouseLoc
            [[self documentView] autoscroll:theEvent];
            mouseLoc = [theEvent locationInWindow];
            dragged = YES;
        }
        
        // dragging or flags changed
        
        currentPoint = [[self documentView] convertPoint:mouseLoc fromView:nil];
        
        // center around startPoint when holding down the Shift key
        if ([theEvent modifierFlags] & NSShiftKeyMask)
            selRect = SKRectFromCenterAndPoint(startPoint, currentPoint);
        else
            selRect = SKRectFromPoints(startPoint, currentPoint);
        
        // intersect with the bounds, project on the bounds if necessary and allow zero width or height
        selRect = SKIntersectionRect(selRect, [[self documentView] bounds]);
        
        [[self window] cacheImageInRect:NSInsetRect([[self documentView] convertRect:selRect toView:nil], -2.0, -2.0)];
        
        [self lockFocus];
        [[NSColor blackColor] set];
        [NSBezierPath setDefaultLineWidth:1.0];
        [NSBezierPath strokeRect:NSInsetRect(NSIntegralRect([self convertRect:selRect fromView:[self documentView]]), 0.5, 0.5)];
        [self unlockFocus];
        [[self window] enableFlushWindow];
        [[self window] flushWindow];
        
    }
    
    [[self window] discardCachedImage];
	[[self getCursorForEvent:theEvent] set];
    
    NSPoint point = [self convertPoint:SKCenterPoint(selRect) fromView:[self documentView]];
    PDFPage *page = [self pageForPoint:point nearest:YES];
    NSRect rect = [self convertRect:selRect fromView:[self documentView]];
    NSRect bounds;
    NSInteger factor = 1;
    BOOL autoFits = NO;
    
    if (dragged) {
    
        bounds = [self convertRect:[[self documentView] bounds] fromView:[self documentView]];
        
        if (NSWidth(rect) < 40.0 && NSHeight(rect) < 40.0)
            factor = 3;
        else if (NSWidth(rect) < 60.0 && NSHeight(rect) < 60.0)
            factor = 2;
        
        if (factor * NSWidth(rect) < 60.0) {
            rect = NSInsetRect(rect, 0.5 * (NSWidth(rect) - 60.0 / factor), 0.0);
            if (NSMinX(rect) < NSMinX(bounds))
                rect.origin.x = NSMinX(bounds);
            if (NSMaxX(rect) > NSMaxX(bounds))
                rect.origin.x = NSMaxX(bounds) - NSWidth(rect);
        }
        if (factor * NSHeight(rect) < 60.0) {
            rect = NSInsetRect(rect, 0.0, 0.5 * (NSHeight(rect) - 60.0 / factor));
            if (NSMinY(rect) < NSMinY(bounds))
                rect.origin.y = NSMinY(bounds);
            if (NSMaxX(rect) > NSMaxY(bounds))
                rect.origin.y = NSMaxY(bounds) - NSHeight(rect);
        }
        
        autoFits = YES;
        
    } else if (toolMode == SKSelectToolMode && NSIsEmptyRect(selectionRect) == NO) {
        
        rect = NSIntersectionRect(selectionRect, [page boundsForBox:kPDFDisplayBoxCropBox]);
        rect = [self convertRect:rect fromPage:page];
        autoFits = YES;
        
    } else {
        
        BOOL isLink = NO;
        PDFDestination *dest = [self destinationForEvent:theEvent isLink:&isLink];
        
        if (isLink) {
            page = [dest page];
            point = [self convertPoint:[dest point] fromPage:page];
            point.y -= 100.0;
        }
        
        rect = [self convertRect:[page boundsForBox:kPDFDisplayBoxCropBox] fromPage:page];
        rect.origin.y = point.y - 100.0;
        rect.size.height = 200.0;
        
    }
    
    SKMainWindowController *controller = [[self window] windowController];
    
    [controller showSnapshotAtPageNumber:[page pageIndex] forRect:[self convertRect:rect toPage:page] scaleFactor:[self scaleFactor] * factor autoFits:autoFits];
}

- (void)doMagnifyWithEvent:(NSEvent *)theEvent {
	NSPoint mouseLoc = [theEvent locationInWindow];
	NSEvent *lastMouseEvent = theEvent;
    NSScrollView *scrollView = [[self documentView] enclosingScrollView];
    NSView *documentView = [scrollView documentView];
    NSView *clipView = [scrollView contentView];
	NSRect originalBounds = [documentView bounds];
    NSRect visibleRect = [clipView convertRect:[clipView visibleRect] toView: nil];
    NSRect magBounds, magRect, outlineRect;
    BOOL mouseInside = NO;
	NSInteger currentLevel = 0;
    NSInteger originalLevel = [theEvent clickCount]; // this should be at least 1
	BOOL postNotification = [documentView postsBoundsChangedNotifications];
    NSUserDefaults *sud = [NSUserDefaults standardUserDefaults];
    NSSize smallSize = NSMakeSize([sud floatForKey:SKSmallMagnificationWidthKey], [sud floatForKey:SKSmallMagnificationHeightKey]);
    NSSize largeSize = NSMakeSize([sud floatForKey:SKLargeMagnificationWidthKey], [sud floatForKey:SKLargeMagnificationHeightKey]);
    NSRect smallMagRect = SKRectFromCenterAndSize(NSZeroPoint, smallSize);
    NSRect largeMagRect = SKRectFromCenterAndSize(NSZeroPoint, largeSize);
    NSBezierPath *path;
    NSColor *color = [NSColor colorWithCalibratedWhite:0.2 alpha:1.0];
    NSShadow *aShadow = [[[NSShadow alloc] init] autorelease];
    [aShadow setShadowBlurRadius:4.0];
    [aShadow setShadowOffset:NSMakeSize(0.0, -2.0)];
    [aShadow setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.5]];
    
    [documentView setPostsBoundsChangedNotifications: NO];
	
	[[self window] discardCachedImage]; // make sure not to use the cached image
    
    [NSEvent startPeriodicEventsAfterDelay:0.1 withPeriod:0.1];
    
    while ([theEvent type] != NSLeftMouseUp) {
        
        if ([theEvent type] == NSLeftMouseDown || [theEvent type] == NSFlagsChanged) {	
            // set up the currentLevel and magnification
            NSUInteger modifierFlags = [theEvent modifierFlags];
            currentLevel = originalLevel + ((modifierFlags & NSAlternateKeyMask) ? 1 : 0);
            if (currentLevel > 2) {
                [[self window] restoreCachedImage];
                [[self window] cacheImageInRect:visibleRect];
            }
            magnification = (modifierFlags & NSCommandKeyMask) ? 4.0 : (modifierFlags & NSControlKeyMask) ? 1.5 : 2.5;
            if (modifierFlags & NSShiftKeyMask) {
                magnification = 1.0 / magnification;
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewMagnificationChangedNotification object:self];
            [[self getCursorForEvent:theEvent] set];
        } else if ([theEvent type] == NSLeftMouseDragged) {
            // get Mouse location and check if it is with the view's rect
            mouseLoc = [theEvent locationInWindow];
            lastMouseEvent = theEvent;
        }
        
        if ([self mouse:mouseLoc inRect:visibleRect]) {
            if (mouseInside == NO) {
                mouseInside = YES;
                [NSCursor hide];
                // make sure we flush the complete drawing to avoid flickering
                [[self window] disableFlushWindow];
            }
            // define rect for magnification in window coordinate
            if (currentLevel > 2) { 
                magRect = (visibleRect);
            } else {
                magRect = currentLevel == 2 ? largeMagRect : smallMagRect;
                magRect.origin = SKAddPoints(magRect.origin, mouseLoc);
                magRect = NSIntegralRect(magRect);
                // restore the cached image in order to clear the rect
                [[self window] restoreCachedImage];
                [[self window] cacheImageInRect:NSIntersectionRect(NSInsetRect(magRect, -8.0, -8.0), visibleRect)];
            }
            
            // resize bounds around mouseLoc
            magBounds.origin = [documentView convertPoint:mouseLoc fromView:nil];
            magBounds = NSMakeRect(NSMinX(magBounds) + (NSMinX(originalBounds) - NSMinX(magBounds)) / magnification, 
                                   NSMinY(magBounds) + (NSMinY(originalBounds) - NSMinY(magBounds)) / magnification, 
                                   NSWidth(originalBounds) / magnification, NSHeight(originalBounds) / magnification);
            
            [clipView lockFocus];
            outlineRect = [clipView convertRect:magRect fromView:nil];
            [aShadow set];
            [color set];
            path = [NSBezierPath bezierPathWithRoundRectInRect:outlineRect radius:9.5];
            [path fill];
            [clipView unlockFocus];
            
            [documentView setBounds:magBounds];
            [self displayRect:[self convertRect:NSInsetRect(magRect, 3.0, 3.0) fromView:nil]]; // this flushes the buffer
            [documentView setBounds:originalBounds];
            
            [clipView lockFocus];
            outlineRect = NSInsetRect(outlineRect, 1.5, 1.5);
            [color set];
            path = [NSBezierPath bezierPathWithRoundRectInRect:outlineRect radius:8.0];
            [path setLineWidth:3.0];
            [path stroke];
            [clipView unlockFocus];
            
            [[self window] enableFlushWindow];
            [[self window] flushWindowIfNeeded];
            [[self window] disableFlushWindow];
            
        } else { // mouse is not in the rect
            // show cursor 
            if (mouseInside) {
                mouseInside = NO;
                [NSCursor unhide];
                // restore the cached image in order to clear the rect
                [[self window] restoreCachedImage];
                [[self window] enableFlushWindow];
                [[self window] flushWindowIfNeeded];
            }
            if ([theEvent type] == NSLeftMouseDragged || [theEvent type] == NSPeriodic)
                [documentView autoscroll:lastMouseEvent];
            if (currentLevel > 2)
                [[self window] cacheImageInRect:visibleRect];
            else
                [[self window] discardCachedImage];
        }
        theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSFlagsChangedMask | NSPeriodicMask];
	}
    
    [NSEvent stopPeriodicEvents];
    
    magnification = 0.0;
    [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewMagnificationChangedNotification object:self];
	
    
	[[self window] restoreCachedImage];
    if (mouseInside)
        [[self window] enableFlushWindow];
	[[self window] flushWindowIfNeeded];
	[NSCursor unhide];
	[documentView setPostsBoundsChangedNotifications:postNotification];
    // ??? PDFView's delayed layout seems to reset the cursor to an arrow
    [[self getCursorForEvent:theEvent] performSelector:@selector(set) withObject:nil afterDelay:0];
}

- (void)doPdfsyncWithEvent:(NSEvent *)theEvent {
    // eat up mouseDragged/mouseUp events, so we won't get their event handlers
    while (YES) {
        if ([[[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask] type] == NSLeftMouseUp)
            break;
    }
    
    SKMainDocument *document = (SKMainDocument *)[[[self window] windowController] document];
    
    if ([document respondsToSelector:@selector(synchronizer)]) {
        
        NSPoint mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        PDFPage *page = [self pageForPoint:mouseLoc nearest:YES];
        NSPoint location = [self convertPoint:mouseLoc toPage:page];
        NSUInteger pageIndex = [page pageIndex];
        PDFSelection *sel = [page selectionForLineAtPoint:location];
        NSRect rect = sel ? [sel boundsForPage:page] : NSMakeRect(location.x - 20.0, location.y - 5.0, 40.0, 10.0);
        
        [[document synchronizer] findFileAndLineForLocation:location inRect:rect pageBounds:[page boundsForBox:kPDFDisplayBoxMediaBox] atPageIndex:pageIndex];
    }
}

- (NSCursor *)getCursorForEvent:(NSEvent *)theEvent {
    NSPoint p = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    NSCursor *cursor = nil;
    
    if ([[self document] isLocked]) {
    } else if (interactionMode == SKPresentationMode) {
        if ([self areaOfInterestForMouse:theEvent] & kPDFLinkArea)
            cursor = [NSCursor pointingHandCursor];
        else
            cursor = [NSCursor arrowCursor];
    } else if (NSMouseInRect(p, [self visibleContentRect], [self isFlipped]) == NO || ([navWindow isVisible] && NSPointInRect([[self window] convertBaseToScreen:[theEvent locationInWindow]], [navWindow frame]))) {
        cursor = [NSCursor arrowCursor];
    } else if ([theEvent modifierFlags] & NSCommandKeyMask) {
        if ([theEvent modifierFlags] & NSShiftKeyMask)
            cursor = [NSCursor arrowCursor];
        else
            cursor = [NSCursor arrowCursor];
    } else {
        switch (toolMode) {
            case SKTextToolMode:
            case SKNoteToolMode:
            {
                PDFPage *page = [self pageForPoint:p nearest:NO];
                p = [self convertPoint:p toPage:page];
                PDFAreaOfInterest area = [self areaOfInterestForMouse:theEvent];
                if ([activeAnnotation isResizable] && [[activeAnnotation page] isEqual:page] && [activeAnnotation hitTest:p])
                    area = kPDFAnnotationArea;
                BOOL canSelectOrDrag = area == kPDFNoArea || toolMode == SKTextToolMode || hideNotes || annotationMode == SKHighlightNote || annotationMode == SKUnderlineNote || annotationMode == SKStrikeOutNote;
                if (readingBar && [[readingBar page] isEqual:page] && NSPointInRect(p, [readingBar currentBoundsForBox:[self displayBox]]))
                    cursor = p.y < NSMinY([readingBar currentBounds]) + 3.0 ? [NSCursor resizeUpDownCursor] : [NSCursor openHandCursor];
                else if (area == kPDFNoArea || (canSelectOrDrag && area == kPDFPageArea && [theEvent standardModifierFlags] == 0 && [[page selectionForRect:NSMakeRect(p.x - 40.0, p.y - 50.0, 80.0, 100.0)] string] == nil))
                    cursor = [NSCursor openHandCursor];
                else if (toolMode == SKNoteToolMode && annotationMode != SKHighlightNote && annotationMode != SKUnderlineNote && annotationMode != SKStrikeOutNote)
                    cursor = [NSCursor arrowCursor];
                break;
            }
            case SKMoveToolMode:
                if ([self areaOfInterestForMouse:theEvent] & kPDFLinkArea)
                    cursor = [NSCursor pointingHandCursor];
                else
                    cursor = [NSCursor openHandCursor];
                break;
            case SKSelectToolMode:
                if ([self areaOfInterestForMouse:theEvent] == kPDFNoArea) {
                    cursor = [NSCursor openHandCursor];
                } else {
                    CGFloat margin = 4.0 / [self scaleFactor];
                    PDFPage *page = [self pageForPoint:p nearest:NO];
                    p = [self convertPoint:p toPage:page];
                    if (NSIsEmptyRect(selectionRect) || NSPointInRect(p, NSInsetRect(selectionRect, -margin, -margin)) == NO) {
                        cursor = [NSCursor crosshairCursor];
                    } else {
                        NSInteger angle = 360;
                        if (p.x > NSMaxX(selectionRect) - margin) {
                            if (p.y < NSMinY(selectionRect) + margin)
                                angle = 45;
                            else if (p.y > NSMaxY(selectionRect) - margin)
                                angle = 315;
                            else
                                angle = 0;
                        } else if (p.x < NSMinX(selectionRect) + margin) {
                            if (p.y < NSMinY(selectionRect) + margin)
                                angle = 135;
                            else if (p.y > NSMaxY(selectionRect) - margin)
                                angle = 225;
                            else
                                angle = 180;
                        } else if (p.y < NSMinY(selectionRect) + margin) {
                            angle = 90;
                        } else if (p.y > NSMaxY(selectionRect) - margin) {
                            angle = 270;
                        } else {
                            cursor = [NSCursor openHandCursor];
                        }
                        if (angle != 360) {
                            angle = (360 + angle + [page rotation]) % 360;
                            switch (angle) {
                                case 0: case 180: cursor = [NSCursor resizeLeftRightCursor]; break;
                                case 45: cursor = [NSCursor resizeRightDownCursor]; break;
                                case 90: case 270: cursor = [NSCursor resizeUpDownCursor]; break;
                                case 135: cursor = [NSCursor resizeLeftDownCursor]; break;
                                case 225: cursor = [NSCursor resizeLeftUpCursor]; break;
                                case 315: cursor = [NSCursor resizeRightUpCursor]; break;
                            }
                        }
                    }
                }
                break;
            case SKMagnifyToolMode:
                if ([self areaOfInterestForMouse:theEvent] == kPDFNoArea)
                    cursor = [NSCursor openHandCursor];
                else
                    cursor = ([theEvent modifierFlags] & NSShiftKeyMask) ? [NSCursor zoomOutCursor] : [NSCursor zoomInCursor];
                break;
        }
    }
    return cursor;
}

- (void)doUpdateCursor {
    NSEvent *event = [NSEvent mouseEventWithType:NSMouseMoved
                                        location:[[self window] mouseLocationOutsideOfEventStream]
                                   modifierFlags:[NSEvent standardModifierFlags]
                                       timestamp:0
                                    windowNumber:[[self window] windowNumber]
                                         context:nil
                                     eventNumber:0
                                      clickCount:1
                                        pressure:0.0];
    [[self getCursorForEvent:event] set];
}

- (void)relayoutEditField {
    if (editField) {
        PDFDisplayMode displayMode = [self displayMode];
        PDFPage *page = [activeAnnotation page];
        PDFPage *currentPage = [self currentPage];
        BOOL isVisible = YES;
        if ([page isEqual:currentPage] == NO && displayMode != kPDFDisplaySinglePageContinuous && displayMode != kPDFDisplayTwoUpContinuous) {
            if (displayMode == kPDFDisplayTwoUp) {
                NSInteger currentPageIndex = [currentPage pageIndex];
                NSInteger facingPageIndex = currentPageIndex;
                if ([self displaysAsBook] == (BOOL)(currentPageIndex % 2))
                    facingPageIndex++;
                else
                    facingPageIndex--;
                if ((NSInteger)[page pageIndex] != facingPageIndex)
                    isVisible = NO;
            } else {
                isVisible = NO;
            }
        }
        if (isVisible) {
            NSRect editBounds = [self convertRect:[self convertRect:[activeAnnotation bounds] fromPage:[activeAnnotation page]] toView:[self documentView]];
            [editField setFrame:editBounds];
            if ([editField superview] == nil) {
                [[self documentView] addSubview:editField];
                if ([[[self window] firstResponder] isEqual:self])
                    [editField selectText:self];
            }
        } else if ([editField superview]) {
            BOOL wasFirstResponder = [[[self window] firstResponder] isEqual:[editField currentEditor]];
            [editField removeFromSuperview];
            if (wasFirstResponder)
                [[self window] makeFirstResponder:self];
        }
    }
}

@end

static inline NSInteger SKIndexOfRectAtYInOrderedRects(CGFloat y,  NSArray *rectValues, BOOL lower) 
{
    NSInteger i = 0, iMax = [rectValues count];
    
    for (i = 0; i < iMax; i++) {
        NSRect rect = [[rectValues objectAtIndex:i] rectValue];
        if (NSMaxY(rect) > y) {
            if (NSMinY(rect) <= y)
                break;
        } else {
            if (lower && i > 0)
                i--;
            break;
        }
    }
    return MIN(i, iMax - 1);
}

#pragma mark Core Graphics extension

static CGMutablePathRef SKCGCreatePathWithRoundRectInRect(CGRect rect, CGFloat radius)
{
    // Make sure radius doesn't exceed a maximum size to avoid artifacts:
    radius = SKMin(radius, 0.5f * SKMin(rect.size.width, rect.size.height));
    
    CGMutablePathRef path = CGPathCreateMutable();
    
    // Make sure silly values simply lead to un-rounded corners:
    if(radius <= 0) {
        CGPathAddRect(path, NULL, rect);
    } else {
        // Now draw our rectangle:
        CGPathMoveToPoint(path, NULL, rect.origin.x, rect.origin.y + radius);
        // Bottom left (origin):
        CGPathAddArcToPoint(path, NULL, rect.origin.x, rect.origin.y, rect.origin.x + rect.size.width, rect.origin.y, radius);
        // Bottom edge and bottom right:
        CGPathAddArcToPoint(path, NULL, rect.origin.x + rect.size.width, rect.origin.y, rect.origin.x + rect.size.width, rect.origin.y + rect.size.height, radius);
        // Right edge and top right:
        CGPathAddArcToPoint(path, NULL, rect.origin.x + rect.size.width, rect.origin.y + rect.size.height, rect.origin.x, rect.origin.y + rect.size.height, radius);
        // Top edge and top left:
        CGPathAddArcToPoint(path, NULL, rect.origin.x, rect.origin.y + rect.size.height, rect.origin.x, rect.origin.y, radius);
        // Left edge:
        CGPathCloseSubpath(path);
    }
    return path;
}

static void SKCGContextDrawGrabHandle(CGContextRef context, CGPoint point, CGFloat radius, bool active)
{
    CGFloat fillColor[4] = { 0.737118, 0.837339, 0.983108, active ? 1.0 : 0.8 };
    CGFloat strokeColor[4] = { 0.278477, 0.467857, 0.810941, active ? 1.0 : 0.8 };
    CGRect rect = CGRectMake(point.x - 0.875 * radius, point.y - 0.875 * radius, 1.75 * radius, 1.75 * radius);
    CGContextSetLineWidth(context, 0.25 * radius);
    CGContextSetFillColor(context, fillColor);
    CGContextFillEllipseInRect(context, rect);
    CGContextSetStrokeColor(context, strokeColor);
    CGContextStrokeEllipseInRect(context, rect);
}

static void SKCGContextDrawGrabHandles(CGContextRef context, CGRect rect, CGFloat radius, NSInteger mask)
{
    SKCGContextDrawGrabHandle(context, CGPointMake(CGRectGetMinX(rect), CGRectGetMidY(rect)), radius, mask == BDSKMinXEdgeMask);
    SKCGContextDrawGrabHandle(context, CGPointMake(CGRectGetMaxX(rect), CGRectGetMidY(rect)), radius, mask == BDSKMaxXEdgeMask);
    SKCGContextDrawGrabHandle(context, CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect)), radius, mask == BDSKMaxYEdgeMask);
    SKCGContextDrawGrabHandle(context, CGPointMake(CGRectGetMidX(rect), CGRectGetMinY(rect)), radius, mask == BDSKMinYEdgeMask);
    SKCGContextDrawGrabHandle(context, CGPointMake(CGRectGetMinX(rect), CGRectGetMaxY(rect)), radius, mask == (BDSKMinXEdgeMask | BDSKMaxYEdgeMask));
    SKCGContextDrawGrabHandle(context, CGPointMake(CGRectGetMinX(rect), CGRectGetMinY(rect)), radius, mask == (BDSKMinXEdgeMask | BDSKMinYEdgeMask));
    SKCGContextDrawGrabHandle(context, CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect)), radius, mask == (BDSKMaxXEdgeMask | BDSKMaxYEdgeMask));
    SKCGContextDrawGrabHandle(context, CGPointMake(CGRectGetMaxX(rect), CGRectGetMinY(rect)), radius, mask == (BDSKMaxXEdgeMask | BDSKMinYEdgeMask));
}
