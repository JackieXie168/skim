//
//  SKPDFView.m
//  Skim
//
//  Created by Michael McCracken on 12/6/06.
/*
 This software is Copyright (c) 2006-2014
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
#import "SKImageToolTipWindow.h"
#import <SkimNotes/SkimNotes.h>
#import "PDFAnnotation_SKExtensions.h"
#import "PDFAnnotationMarkup_SKExtensions.h"
#import "PDFAnnotationInk_SKExtensions.h"
#import "PDFPage_SKExtensions.h"
#import "NSString_SKExtensions.h"
#import "NSCursor_SKExtensions.h"
#import "SKApplication.h"
#import "SKStringConstants.h"
#import "NSUserDefaultsController_SKExtensions.h"
#import "NSUserDefaults_SKExtensions.h"
#import "SKReadingBar.h"
#import "SKTransitionController.h"
#import "SKTextNoteEditor.h"
#import "SKSyncDot.h"
#import "SKLineInspector.h"
#import "SKLineWell.h"
#import "SKTypeSelectHelper.h"
#import "SKAccessibilityFauxUIElement.h"
#import <CoreServices/CoreServices.h>
#import "NSDocument_SKExtensions.h"
#import "PDFSelection_SKExtensions.h"
#import "NSBezierPath_SKExtensions.h"
#import "PDFDocument_SKExtensions.h"
#import "PDFDisplayView_SKExtensions.h"
#import "NSResponder_SKExtensions.h"
#import "NSEvent_SKExtensions.h"
#import "PDFView_SKExtensions.h"
#import "NSMenu_SKExtensions.h"
#import "NSGeometry_SKExtensions.h"
#import "NSGraphics_SKExtensions.h"
#import "NSArray_SKExtensions.h"
#import "NSColor_SKExtensions.h"
#import "NSView_SKExtensions.h"
#import "SKApplication.h"

#define ANNOTATION_MODE_COUNT 9
#define TOOL_MODE_COUNT 5

#define ANNOTATION_MODE_IS_MARKUP (annotationMode == SKHighlightNote || annotationMode == SKUnderlineNote || annotationMode == SKStrikeOutNote)

#define READINGBAR_RESIZE_EDGE_HEIGHT 3.0
#define NAVIGATION_BOTTOM_EDGE_HEIGHT 3.0

#define TEXT_SELECT_MARGIN_SIZE ((NSSize){80.0, 100.0})

#define TOOLTIP_OFFSET_FRACTION 0.3

#define DEFAULT_SNAPSHOT_HEIGHT 200.0

#define MIN_NOTE_SIZE 8.0

#define HANDLE_SIZE 4.0

#define DEFAULT_MAGNIFICATION 2.5
#define SMALL_MAGNIFICATION   1.5
#define LARGE_MAGNIFICATION   4.0

NSString *SKPDFViewToolModeChangedNotification = @"SKPDFViewToolModeChangedNotification";
NSString *SKPDFViewAnnotationModeChangedNotification = @"SKPDFViewAnnotationModeChangedNotification";
NSString *SKPDFViewActiveAnnotationDidChangeNotification = @"SKPDFViewActiveAnnotationDidChangeNotification";
NSString *SKPDFViewDidAddAnnotationNotification = @"SKPDFViewDidAddAnnotationNotification";
NSString *SKPDFViewDidRemoveAnnotationNotification = @"SKPDFViewDidRemoveAnnotationNotification";
NSString *SKPDFViewDidMoveAnnotationNotification = @"SKPDFViewDidMoveAnnotationNotification";
NSString *SKPDFViewReadingBarDidChangeNotification = @"SKPDFViewReadingBarDidChangeNotification";
NSString *SKPDFViewSelectionChangedNotification = @"SKPDFViewSelectionChangedNotification";
NSString *SKPDFViewMagnificationChangedNotification = @"SKPDFViewMagnificationChangedNotification";

NSString *SKPDFViewAnnotationKey = @"annotation";
NSString *SKPDFViewPageKey = @"page";
NSString *SKPDFViewOldPageKey = @"oldPage";
NSString *SKPDFViewNewPageKey = @"newPage";

#define SKSmallMagnificationWidthKey @"SKSmallMagnificationWidth"
#define SKSmallMagnificationHeightKey @"SKSmallMagnificationHeight"
#define SKLargeMagnificationWidthKey @"SKLargeMagnificationWidth"
#define SKLargeMagnificationHeightKey @"SKLargeMagnificationHeight"
#define SKMoveReadingBarModifiersKey @"SKMoveReadingBarModifiers"
#define SKResizeReadingBarModifiersKey @"SKResizeReadingBarModifiers"
#define SKDefaultFreeTextNoteContentsKey @"SKDefaultFreeTextNoteContents"
#define SKDefaultAnchoredNoteContentsKey @"SKDefaultAnchoredNoteContents"
#define SKUseToolModeCursorsKey @"SKUseToolModeCursors"

#define SKReadingBarNumberOfLinesKey @"SKReadingBarNumberOfLines"

#define SKAnnotationKey @"SKAnnotation"

static char SKPDFViewDefaultsObservationContext;
static char SKPDFViewTransitionsObservationContext;

static NSUInteger moveReadingBarModifiers = NSAlternateKeyMask;
static NSUInteger resizeReadingBarModifiers = NSAlternateKeyMask | NSShiftKeyMask;

static BOOL useToolModeCursors = NO;

static inline NSInteger SKIndexOfRectAtYInOrderedRects(CGFloat y,  NSPointerArray *rectArray, BOOL lower);

static inline CGPathRef SKCopyCGPathFromBezierPath(NSBezierPath *bezierPath);

enum {
    SKNavigationNone,
    SKNavigationBottom,
    SKNavigationEverywhere,
};

#pragma mark -

@interface SKPDFView (Private)

- (void)addAnnotationWithType:(SKNoteType)annotationType defaultPoint:(NSPoint)point;
- (void)addAnnotationWithType:(SKNoteType)annotationType contents:(NSString *)text page:(PDFPage *)page bounds:(NSRect)bounds;

- (BOOL)isEditingAnnotation:(PDFAnnotation *)annotation;

- (void)enableNavigation;
- (void)disableNavigation;

- (void)doAutohide:(BOOL)flag;
- (void)showNavWindow:(BOOL)flag;

- (void)doMoveActiveAnnotationForKey:(unichar)eventChar byAmount:(CGFloat)delta;
- (void)doResizeActiveAnnotationForKey:(unichar)eventChar byAmount:(CGFloat)delta;
- (void)doMoveReadingBarForKey:(unichar)eventChar;
- (void)doResizeReadingBarForKey:(unichar)eventChar;

- (BOOL)doSelectAnnotationWithEvent:(NSEvent *)theEvent;
- (void)doDragAnnotationWithEvent:(NSEvent *)theEvent;
- (void)doEditActiveAnnotationWithEvent:(NSEvent *)theEvent;
- (void)doSelectSnapshotWithEvent:(NSEvent *)theEvent;
- (void)doMagnifyWithEvent:(NSEvent *)theEvent;
- (void)doDragWithEvent:(NSEvent *)theEvent;
- (void)doDrawFreehandNoteWithEvent:(NSEvent *)theEvent;
- (void)doEraseAnnotationsWithEvent:(NSEvent *)theEvent;
- (void)doSelectWithEvent:(NSEvent *)theEvent;
- (void)doDragReadingBarWithEvent:(NSEvent *)theEvent;
- (void)doResizeReadingBarWithEvent:(NSEvent *)theEvent;
- (void)doNothingWithEvent:(NSEvent *)theEvent;
- (NSCursor *)cursorForResizeHandle:(SKRectEdges)mask rotation:(NSInteger)rotation;
- (NSCursor *)getCursorForEvent:(NSEvent *)theEvent;
- (void)doUpdateCursor;
- (NSInteger)readingBarAreaForMouse:(NSEvent *)theEvent;

- (void)handlePageChangedNotification:(NSNotification *)notification;
- (void)handleScaleChangedNotification:(NSNotification *)notification;
- (void)handleWindowWillCloseNotification:(NSNotification *)notification;

@end

#pragma mark -

@implementation SKPDFView

@synthesize toolMode, annotationMode, interactionMode, activeAnnotation, hideNotes, readingBar, transitionController, typeSelectHelper;
@synthesize currentMagnification=magnification, isZooming;
@dynamic editTextField, hasReadingBar, currentSelectionPage, currentSelectionRect;

+ (void)initialize {
    SKINITIALIZE;
    
    NSArray *sendTypes = [NSArray arrayWithObjects:NSPasteboardTypePDF, NSPasteboardTypeTIFF, nil];
    [NSApp registerServicesMenuSendTypes:sendTypes returnTypes:nil];
    
    NSNumber *moveReadingBarModifiersNumber = [[NSUserDefaults standardUserDefaults] objectForKey:SKMoveReadingBarModifiersKey];
    NSNumber *resizeReadingBarModifiersNumber = [[NSUserDefaults standardUserDefaults] objectForKey:SKResizeReadingBarModifiersKey];
    if (moveReadingBarModifiersNumber)
        moveReadingBarModifiers = [moveReadingBarModifiersNumber integerValue];
    if (resizeReadingBarModifiersNumber)
        resizeReadingBarModifiers = [resizeReadingBarModifiersNumber integerValue];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Double-click to edit.", @"Default text for new text note"), SKDefaultFreeTextNoteContentsKey, NSLocalizedString(@"New note", @"Default text for new anchored note"), SKDefaultAnchoredNoteContentsKey, nil]];
    
    
    useToolModeCursors = [[NSUserDefaults standardUserDefaults] boolForKey:SKUseToolModeCursorsKey];

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
    selectionRect = NSZeroRect;
    selectionPageIndex = NSNotFound;
    
    syncDot = nil;
    
    magnification = 0.0;
    
    gestureRotation = 0.0;
    gesturePageIndex = NSNotFound;
    
    trackingArea = [[NSTrackingArea alloc] initWithRect:[self bounds] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:nil];
    [self addTrackingArea:trackingArea];
    
    [self registerForDraggedTypes:[NSArray arrayWithObjects:NSPasteboardTypeColor, SKPasteboardTypeLineStyle, nil]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePageChangedNotification:) 
                                                 name:PDFViewPageChangedNotification object:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleScaleChangedNotification:) 
                                                 name:PDFViewScaleChangedNotification object:self];
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeys:
        [NSArray arrayWithObjects:SKReadingBarColorKey, SKReadingBarInvertKey, nil]
        context:&SKPDFViewDefaultsObservationContext];
}

- (id)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        [self commonInitialization];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
    if (self) {
        [self commonInitialization];
    }
    return self;
}

- (void)dealloc {
    [[NSSpellChecker sharedSpellChecker] closeSpellDocumentWithTag:spellingTag];
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeys:
        [NSArray arrayWithObjects:SKReadingBarColorKey, SKReadingBarInvertKey, nil]];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [transitionController removeObserver:self forKeyPath:@"transitionStyle"];
    [transitionController removeObserver:self forKeyPath:@"duration"];
    [transitionController removeObserver:self forKeyPath:@"shouldRestrict"];
    [transitionController removeObserver:self forKeyPath:@"pageTransitions"];
    [self showNavWindow:NO];
    [self doAutohide:NO];
    [[SKImageToolTipWindow sharedToolTipWindow] orderOut:self];
    [self removePDFToolTipRects];
    [syncDot invalidate];
    SKDESTROY(syncDot);
    SKDESTROY(trackingArea);
    SKDESTROY(activeAnnotation);
    SKDESTROY(typeSelectHelper);
    SKDESTROY(transitionController);
    SKDESTROY(navWindow);
    SKDESTROY(readingBar);
    SKDESTROY(accessibilityChildren);
    SKDESTROY(editor);
    [super dealloc];
}

- (NSRect)visibleContentRect {
    NSView *clipView = [[self scrollView] contentView];
    return [clipView convertRect:[clipView visibleRect] toView:self];
}

- (void)resetHistory {
    if ([self respondsToSelector:@selector(currentHistoryIndex)])
        minHistoryIndex = [self currentHistoryIndex];
}

#pragma mark Tool Tips

- (void)removePDFToolTipRects {
    NSView *docView = [self documentView];
    NSArray *trackingAreas = [[[docView trackingAreas] copy] autorelease];
    for (NSTrackingArea *area in trackingAreas) {
        if ([area owner] == self && [[area userInfo] objectForKey:SKAnnotationKey])
            [docView removeTrackingArea:area];
    }
}

- (void)resetPDFToolTipRects {
    [self removePDFToolTipRects];
    
    if ([self document] && [self window] && interactionMode != SKPresentationMode) {
        NSRect visibleRect = [self visibleContentRect];
        NSView *docView = [self documentView];
        BOOL hasLinkToolTips = (toolMode == SKTextToolMode || toolMode == SKMoveToolMode || toolMode == SKNoteToolMode);
        
        for (PDFPage *page in [self visiblePages]) {
            for (PDFAnnotation *annotation in [page annotations]) {
                if ([annotation isNote] || (hasLinkToolTips && [annotation isLink])) {
                    NSRect rect = NSIntersectionRect([self convertRect:[annotation bounds] fromPage:page], visibleRect);
                    if (NSIsEmptyRect(rect) == NO) {
                        rect = [self convertRect:rect toView:docView];
                        NSDictionary *userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:annotation, SKAnnotationKey, nil];
                        NSTrackingArea *area = [[NSTrackingArea alloc] initWithRect:rect options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp owner:self userInfo:userInfo];
                        [docView addTrackingArea:area];
                        [area release];
                        [userInfo release];
                    }
                }
            }
        }
    }
}

#pragma mark Drawing

- (void)drawSelectionForPage:(PDFPage *)pdfPage {
    NSRect bounds = [pdfPage boundsForBox:[self displayBox]];
    CGFloat radius = HANDLE_SIZE / [self scaleFactor];
    BOOL active = [[self window] isKeyWindow] && [[self window] firstResponder] == self;
    NSBezierPath *path = [NSBezierPath bezierPathWithRect:bounds];
    [path appendBezierPathWithRect:selectionRect];
    [[NSColor colorWithCalibratedWhite:0.0 alpha:0.6] setFill];
    [path setWindingRule:NSEvenOddWindingRule];
    [path fill];
    if ([pdfPage pageIndex] != selectionPageIndex) {
        [[NSColor colorWithCalibratedWhite:0.0 alpha:0.3] setFill];
        [NSBezierPath fillRect:selectionRect];
    }
    SKDrawResizeHandles(selectionRect, radius, active);
}

- (void)drawDragHighlight {
    [NSGraphicsContext saveGraphicsState];
    [[NSColor blackColor] setFill];
    NSRect rect = [self convertRect:NSIntegralRect([self convertRect:[highlightAnnotation bounds] fromPage:[highlightAnnotation page]]) toPage:[highlightAnnotation page]];
    NSFrameRectWithWidth(rect, 1.0 / [self scaleFactor]);
    [NSGraphicsContext restoreGraphicsState];
}

- (void)drawPage:(PDFPage *)pdfPage {
    NSImageInterpolation interpolation = [[NSUserDefaults standardUserDefaults] integerForKey:SKImageInterpolationKey];
    // smooth graphics when anti-aliasing
    if (interpolation == NSImageInterpolationDefault)
        interpolation = [self shouldAntiAlias] ? NSImageInterpolationHigh : NSImageInterpolationNone;
    [[NSGraphicsContext currentContext] setImageInterpolation:interpolation];
    
    [PDFAnnotation setCurrentActiveAnnotation:activeAnnotation];
    
    // Let PDFView do most of the hard work.
    [super drawPage: pdfPage];
    
    [PDFAnnotation setCurrentActiveAnnotation:nil];
	
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationDefault];
    
    [NSGraphicsContext saveGraphicsState];
    
    [pdfPage transformContextForBox:[self displayBox]];
    
    if ([[activeAnnotation page] isEqual:pdfPage])
        [activeAnnotation drawSelectionHighlightForView:self];
    
    if (readingBar)
        [readingBar drawForPage:pdfPage withBox:[self displayBox]];
    
    if (selectionPageIndex != NSNotFound)
        [self drawSelectionForPage:pdfPage];
    
    if ([[highlightAnnotation page] isEqual:pdfPage])
        [self drawDragHighlight];
    
    if ([[syncDot page] isEqual:pdfPage])
        [syncDot draw];
    
    [NSGraphicsContext restoreGraphicsState];
}

#pragma mark Accessors

- (void)setDocument:(PDFDocument *)document {
    [readingBar release];
    readingBar = nil;
    selectionRect = NSZeroRect;
    selectionPageIndex = NSNotFound;
    [syncDot invalidate];
    SKDESTROY(syncDot);
    [self removePDFToolTipRects];
    SKDESTROY(accessibilityChildren);
    [[SKImageToolTipWindow sharedToolTipWindow] orderOut:self];
    [super setDocument:document];
    [self resetPDFToolTipRects];
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
        [self resetPDFToolTipRects];
    }
}

- (void)setAnnotationMode:(SKNoteType)newAnnotationMode {
    if (annotationMode != newAnnotationMode) {
        annotationMode = newAnnotationMode;
        [[NSUserDefaults standardUserDefaults] setInteger:annotationMode forKey:SKLastAnnotationModeKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewAnnotationModeChangedNotification object:self];
        // hack to make sure we update the cursor
        [self doUpdateCursor];
    }
}

- (void)setInteractionMode:(SKInteractionMode)newInteractionMode {
    if (interactionMode != newInteractionMode) {
        if (interactionMode == SKPresentationMode && [[self documentView] isHidden])
            [[self documentView] setHidden:NO];
        interactionMode = newInteractionMode;
        if (interactionMode == SKNormalMode)
            [self disableNavigation];
        else
            [self enableNavigation];
        [self resetPDFToolTipRects];
    }
}

- (void)setActiveAnnotation:(PDFAnnotation *)newAnnotation {
	if (newAnnotation != activeAnnotation) {
	
        // Will need to redraw old active anotation.
        if (activeAnnotation != nil) {
            [self setNeedsDisplayForAnnotation:activeAnnotation];
            if ([activeAnnotation isLink])
                [(PDFAnnotationLink *)activeAnnotation setHighlighted:NO];
            if (editor)
                [self commitEditing];
        }
        
        // Assign.
        [activeAnnotation release];
        if (newAnnotation) {
            activeAnnotation = [newAnnotation retain];
            // Force redisplay.
            [self setNeedsDisplayForAnnotation:activeAnnotation];
            if ([activeAnnotation isLink])
                [(PDFAnnotationLink *)activeAnnotation setHighlighted:YES];
        } else {
            activeAnnotation = nil;
        }
        
		[[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewActiveAnnotationDidChangeNotification object:self];
        NSAccessibilityPostNotification(NSAccessibilityUnignoredAncestor([self documentView]), NSAccessibilityFocusedUIElementChangedNotification);
    }
}

- (NSTextField *)editTextField {
    return [editor textField];
}

- (void)setDisplayMode:(PDFDisplayMode)mode {
    if (mode != [self displayMode]) {
        PDFPage *page = [self currentPage];
        [super setDisplayMode:mode];
        if (page && [page isEqual:[self currentPage]] == NO)
            [self goToPage:page];
        [self resetPDFToolTipRects];
        [editor layout];
        SKDESTROY(accessibilityChildren);
    }
}

- (void)setDisplayBox:(PDFDisplayBox)box {
    if (box != [self displayBox]) {
        PDFPage *page = [self currentPage];
        [super setDisplayBox:box];
        if (page && [page isEqual:[self currentPage]] == NO)
            [self goToPage:page];
        [self resetPDFToolTipRects];
        [editor layout];
    }
}

- (void)setDisplaysAsBook:(BOOL)asBook {
    if (asBook != [self displaysAsBook]) {
        [super setDisplaysAsBook:asBook];
        [self resetPDFToolTipRects];
        [editor layout];
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

- (void)setHideNotes:(BOOL)flag {
    if (hideNotes != flag) {
        hideNotes = flag;
        if (hideNotes)
            [self setActiveAnnotation:nil];
        [self setNeedsDisplay:YES];
    }
}

- (SKTransitionController * )transitionController {
    if (transitionController == nil) {
        transitionController = [[SKTransitionController alloc] initForView:self];
        NSKeyValueObservingOptions options = (NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld);
        [transitionController addObserver:self forKeyPath:@"transitionStyle" options:options context:&SKPDFViewTransitionsObservationContext];
        [transitionController addObserver:self forKeyPath:@"duration" options:options context:&SKPDFViewTransitionsObservationContext];
        [transitionController addObserver:self forKeyPath:@"shouldRestrict" options:options context:&SKPDFViewTransitionsObservationContext];
        [transitionController addObserver:self forKeyPath:@"pageTransitions" options:options context:&SKPDFViewTransitionsObservationContext];
    }
    return transitionController;
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
        [self goToRect:NSInsetRect([readingBar currentBounds], 0.0, -20.0) onPage:[readingBar page]];
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
        [[self transitionController] animateForRect:rect];
        if (interactionMode == SKPresentationMode)
            [self doAutohide:YES];
    }
}

- (IBAction)goToNextPage:(id)sender {
    if (interactionMode == SKPresentationMode && [transitionController hasTransition] && [self canGoToNextPage])
        [self animateTransitionForNextPage:YES];
    else
        [super goToNextPage:sender];
}

- (IBAction)goToPreviousPage:(id)sender {
    if (interactionMode == SKPresentationMode && [transitionController hasTransition] && [self canGoToPreviousPage])
        [self animateTransitionForNextPage:NO];
    else
        [super goToPreviousPage:sender];
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
    NSAttributedString *attrString = [[self currentSelection] attributedString];
    NSPasteboardItem *imageItem = nil;
    PDFAnnotation *note = nil;
    
    if ([self hideNotes] == NO && [activeAnnotation isSkimNote] && [activeAnnotation isMovable])
        note = activeAnnotation;
    
    if (toolMode == SKSelectToolMode && NSIsEmptyRect(selectionRect) == NO && selectionPageIndex != NSNotFound) {
        NSRect selRect = NSIntegralRect(selectionRect);
        PDFPage *page = [self currentSelectionPage];
        NSData *pdfData = nil;
        NSData *tiffData = nil;
        
        imageItem = [[[NSPasteboardItem alloc] init] autorelease];
        
        if ([[self document] allowsPrinting] && (pdfData = [page PDFDataForRect:selRect]))
            [imageItem setData:pdfData forType:NSPasteboardTypePDF];
        if ((tiffData = [page TIFFDataForRect:selRect]))
            [imageItem setData:tiffData forType:NSPasteboardTypeTIFF];
        
        /*
         Possible hidden default?  Alternate way of getting a bitmap rep; this varies resolution with zoom level, which is very useful if you want to copy a single figure or equation for a non-PDF-capable program.  The first copy: action has some odd behavior, though (view moves).  Preview produces a fixed resolution bitmap for a given selection area regardless of zoom.
         
        sourceRect = [self convertRect:selectionRect fromPage:[self currentPage]];
        NSBitmapImageRep *imageRep = [self bitmapImageRepForCachingDisplayInRect:sourceRect];
        [self cacheDisplayInRect:sourceRect toBitmapImageRep:imageRep];
        tiffData = [imageRep TIFFRepresentation];
         */
    }
    
    if ([attrString length] > 0  || imageItem || note) {
    
        NSPasteboard *pboard = [NSPasteboard generalPasteboard];
        
        [pboard clearContents];
        
        if ([attrString length] > 0)
            [pboard writeObjects:[NSArray arrayWithObject:attrString]];
        if (imageItem)
            [pboard writeObjects:[NSArray arrayWithObject:imageItem]];
        if (note)
            [pboard writeObjects:[NSArray arrayWithObject:note]];
        
    } else {
        [super copy:sender];
    }
}

- (void)pasteNote:(BOOL)preferNote plainText:(BOOL)isPlainText {
    if ([self hideNotes]) {
        NSBeep();
        return;
    }
    
    NSPasteboard *pboard = [NSPasteboard generalPasteboard];
    NSDictionary *options = [NSDictionary dictionary];
    NSArray *newAnnotations = nil;
    PDFPage *page;
    
    if (isPlainText == NO)
        newAnnotations = [pboard readObjectsForClasses:[NSArray arrayWithObject:[PDFAnnotation class]] options:options];
    
    if ([newAnnotations count] > 0) {
        
        for (PDFAnnotation *newAnnotation in newAnnotations) {
            
            NSRect bounds = [newAnnotation bounds];
            page = [self currentPage];
            bounds = SKConstrainRect(bounds, [page boundsForBox:[self displayBox]]);
            
            [newAnnotation setBounds:bounds];
            
            [newAnnotation registerUserName];
            [self addAnnotation:newAnnotation toPage:page];
            
            [self setActiveAnnotation:newAnnotation];

        }
        
        [[self undoManager] setActionName:NSLocalizedString(@"Add Note", @"Undo action name")];
        
    } else {
        
        id str = nil;
        
        if (isPlainText || preferNote)
            str = [[pboard readObjectsForClasses:[NSArray arrayWithObjects:[NSAttributedString class], [NSString class], nil] options:options] firstObject];
        else
            str = [[pboard readObjectsForClasses:[NSArray arrayWithObjects:[NSString class], nil] options:options] firstObject];
        
        
        if (str) {
            
            // First try the current mouse position
            NSPoint center = [self convertPoint:[[self window] mouseLocationOutsideOfEventStream] fromView:nil];
            
            // if the mouse was in the toolbar and there is a page below the toolbar, we get a point outside of the visible rect
            page = NSMouseInRect(center, [self visibleContentRect], [self isFlipped]) ? [self pageForPoint:center nearest:NO] : nil;
            
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
            
            PDFAnnotation *newAnnotation = nil;
            
            if (preferNote) {
                newAnnotation = [[[SKNPDFAnnotationNote alloc] initSkimNoteWithBounds:bounds] autorelease];
                NSMutableAttributedString *attrString = nil;
                if ([str isKindOfClass:[NSString class]])
                    attrString = [[[NSMutableAttributedString alloc] initWithString:str] autorelease];
                else if ([str isKindOfClass:[NSAttributedString class]])
                    attrString = [[[NSMutableAttributedString alloc] initWithAttributedString:str] autorelease];
                if (isPlainText || [str isKindOfClass:[NSString class]]) {
                    NSString *fontName = [[NSUserDefaults standardUserDefaults] stringForKey:SKAnchoredNoteFontNameKey];
                    CGFloat fontSize = [[NSUserDefaults standardUserDefaults] floatForKey:SKAnchoredNoteFontSizeKey];
                    NSFont *font = fontName ? [NSFont fontWithName:fontName size:fontSize] : [NSFont userFontOfSize:fontSize];
                    [attrString setAttributes:[NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, nil] range:NSMakeRange(0, [attrString length])];
                }
                [(SKNPDFAnnotationNote *)newAnnotation setText:attrString];
            } else {
                newAnnotation = [[[PDFAnnotationFreeText alloc] initSkimNoteWithBounds:bounds] autorelease];
                [newAnnotation setString:([str isKindOfClass:[NSAttributedString class]] ? [str string] : str)];
            }
            
            [newAnnotation registerUserName];
            [self addAnnotation:newAnnotation toPage:page];
            [[self undoManager] setActionName:NSLocalizedString(@"Add Note", @"Undo action name")];

            [self setActiveAnnotation:newAnnotation];
            
        } else {
            
            NSBeep();
            
        }
    }
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

- (IBAction)changeToolMode:(id)sender {
    [self setToolMode:[sender tag]];
}

- (IBAction)changeAnnotationMode:(id)sender {
    [self setToolMode:SKNoteToolMode];
    [self setAnnotationMode:[sender tag]];
}

- (void)zoomLog:(id)sender {
    [self setScaleFactor:exp([sender doubleValue])];
}

- (void)toggleAutoActualSize:(id)sender {
    if ([self autoScales])
        [self setScaleFactor:1.0];
    else
        [self setAutoScales:YES];
}

- (void)exitFullscreen:(id)sender {
    if ([[self delegate] respondsToSelector:@selector(PDFViewExitFullscreen:)])
        [[self delegate] PDFViewExitFullscreen:self];
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

- (void)zoomIn:(id)sender {
    isZooming = YES;
    [super zoomIn:sender];
    isZooming = NO;
}

- (void)zoomOut:(id)sender {
    isZooming = YES;
    [super zoomOut:sender];
    isZooming = NO;
}

- (void)setScaleFactor:(CGFloat)scale {
    isZooming = YES;
    [super setScaleFactor:scale];
    isZooming = NO;
}

// we don't want to steal the printDocument: action from the responder chain
- (void)printDocument:(id)sender{}

- (BOOL)respondsToSelector:(SEL)aSelector {
    return aSelector != @selector(printDocument:) && [super respondsToSelector:aSelector];
}

- (BOOL)canZoomIn {
    return [[self document] isLocked] == NO && [super canZoomIn];
}

- (BOOL)canZoomOut {
    return [[self document] isLocked] == NO && [super canZoomOut];
}

- (BOOL)canGoToNextPage {
    return [[self document] isLocked] == NO && [super canGoToNextPage];
}

- (BOOL)canGoToPreviousPage {
    return [[self document] isLocked] == NO && [super canGoToPreviousPage];
}

- (BOOL)canGoToFirstPage {
    return [[self document] isLocked] == NO && [super canGoToFirstPage];
}

- (BOOL)canGoToLastPage {
    return [[self document] isLocked] == NO && [super canGoToLastPage];
}

- (BOOL)canGoBack {
    if ([[self document] isLocked])
        return NO;
    else if ([self respondsToSelector:@selector(currentHistoryIndex)] && minHistoryIndex > 0)
        return minHistoryIndex < [self currentHistoryIndex];
    else
        return [super canGoBack];
}

- (BOOL)canGoForward {
    return [[self document] isLocked] == NO && [super canGoForward];
}

- (void)checkSpelling:(id)sender {
    PDFSelection *selection = [self currentSelection];
    PDFPage *page;
    NSUInteger idx, i, first, iMax = [[self document] pageCount];
    BOOL didWrap = NO;
    NSRange range = NSMakeRange(NSNotFound, 0);
    
    if ([selection hasCharacters]) {
        page = [selection safeLastPage];
        idx = [selection safeIndexOfLastCharacterOnPage:page];
        if (idx == NSNotFound)
            idx = 0;
    } else {
        page = [self currentPage];
        idx = 0;
    }
    
    i = first = [page pageIndex];
    while (YES) {
        range = [[NSSpellChecker sharedSpellChecker] checkSpellingOfString:[page string] startingAt:idx language:nil wrap:NO inSpellDocumentWithTag:spellingTag wordCount:NULL];
        if (range.location != NSNotFound) break;
        if (didWrap && i == first) break;
        if (++i >= iMax) {
            i = 0;
            didWrap = YES;
        }
        page = [[self document] pageAtIndex:i];
        idx = 0;
    }
    
    if (range.location != NSNotFound) {
        selection = [page selectionForRange:range];
        [self setCurrentSelection:selection];
        [self goToRect:[selection boundsForPage:page] onPage:page];
        [[NSSpellChecker sharedSpellChecker] updateSpellingPanelWithMisspelledWord:[selection string]];
    } else NSBeep();
}

- (void)showGuessPanel:(id)sender {
    [self checkSpelling:sender];
    [[[NSSpellChecker sharedSpellChecker] spellingPanel] orderFront:self];
}

- (void)ignoreSpelling:(id)sender {
    [[NSSpellChecker sharedSpellChecker] ignoreWord:[[sender selectedCell] stringValue] inSpellDocumentWithTag:spellingTag];
}

#pragma mark Event Handling

// PDFView has duplicated key equivalents for Cmd-+/- as well as Opt-Cmd-+/-, which is totoally unnecessary and harmful
- (BOOL)performKeyEquivalent:(NSEvent *)theEvent { return NO; }

- (void)keyDown:(NSEvent *)theEvent
{
    unichar eventChar = [theEvent firstCharacter];
	NSUInteger modifiers = [theEvent standardModifierFlags];
    
    if (interactionMode == SKPresentationMode) {
        // Presentation mode
        if ([[self scrollView] hasHorizontalScroller] == NO && 
            (eventChar == NSRightArrowFunctionKey) &&  (modifiers == 0)) {
            [self goToNextPage:self];
        } else if ([[self scrollView] hasHorizontalScroller] == NO && 
                   (eventChar == NSLeftArrowFunctionKey) &&  (modifiers == 0)) {
            [self goToPreviousPage:self];
        } else if ((eventChar == 'p') && (modifiers == 0)) {
            if ([[self delegate] respondsToSelector:@selector(PDFViewToggleContents:)])
                [[self delegate] PDFViewToggleContents:self];
        } else if ((eventChar == 'a') && (modifiers == 0)) {
            [self toggleAutoActualSize:self];
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
        } else if (([self toolMode] == SKTextToolMode || [self toolMode] == SKNoteToolMode) && activeAnnotation && editor == nil && 
                   (eventChar == NSEnterCharacter || eventChar == NSFormFeedCharacter || eventChar == NSNewlineCharacter || eventChar == NSCarriageReturnCharacter) &&
                   (modifiers == 0)) {
            [self editActiveAnnotation:self];
        } else if (([self toolMode] == SKTextToolMode || [self toolMode] == SKNoteToolMode) && 
                   (eventChar == SKEscapeCharacter) && (modifiers == NSAlternateKeyMask)) {
            [self setActiveAnnotation:nil];
        } else if (([self toolMode] == SKTextToolMode || [self toolMode] == SKNoteToolMode) && 
                   (eventChar == NSTabCharacter) && (modifiers == NSAlternateKeyMask)) {
            [self selectNextActiveAnnotation:self];
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
        } else if ([typeSelectHelper handleEvent:theEvent] == NO) {
            [super keyDown:theEvent];
        }
        
    }
}

- (BOOL)hasTextNearMouse:(NSEvent *)theEvent {
    NSPoint p = NSZeroPoint;
    PDFPage *page = [self pageAndPoint:&p forEvent:theEvent nearest:YES];
    return [[page selectionForRect:SKRectFromCenterAndSize(p, TEXT_SELECT_MARGIN_SIZE)] hasCharacters];
}

#define IS_TABLET_EVENT(theEvent, deviceType) (([theEvent subtype] == NSTabletProximityEventSubtype || [theEvent subtype] == NSTabletPointEventSubtype) && [NSEvent currentPointingDeviceType] == deviceType)

- (void)mouseDown:(NSEvent *)theEvent{
    if ([activeAnnotation isLink])
        [self setActiveAnnotation:nil];
    
    // 10.6 does not automatically make us firstResponder, that's annoying
    // but we don't want an edited text note to stop editing when we're resizing it
    if ([[[self window] firstResponder] isDescendantOf:self] == NO)
        [[self window] makeFirstResponder:self];
    
	NSUInteger modifiers = [theEvent standardModifierFlags];
    PDFAreaOfInterest area = [self extendedAreaOfInterestForMouse:theEvent];
    
    if ([[self document] isLocked]) {
        [super mouseDown:theEvent];
    } else if (interactionMode == SKPresentationMode) {
        if (hideNotes == NO && IS_TABLET_EVENT(theEvent, NSPenPointingDevice)) {
            [self doDrawFreehandNoteWithEvent:theEvent];
            [self setActiveAnnotation:nil];
        } else if ((area & kPDFLinkArea)) {
            [super mouseDown:theEvent];
        } else {
            [self goToNextPage:self];
            // Eat up drag events because we don't want to select
            [self doNothingWithEvent:theEvent];
        }
    } else if (modifiers == NSCommandKeyMask) {
        [self doSelectSnapshotWithEvent:theEvent];
    } else if (modifiers == (NSCommandKeyMask | NSShiftKeyMask)) {
        [self doPdfsyncWithEvent:theEvent];
    } else if ((area & SKReadingBarArea) && (area & kPDFLinkArea) == 0 && ((area & kPDFPageArea) == 0 || (toolMode != SKSelectToolMode && toolMode != SKMagnifyToolMode))) {
        if ((area & SKReadingBarResizeArea))
            [self doResizeReadingBarWithEvent:theEvent];
        else
            [self doDragReadingBarWithEvent:theEvent];
    } else if ((area & kPDFPageArea) == 0) {
        [self doDragWithEvent:theEvent];
    } else if (toolMode == SKMoveToolMode) {
        [self setCurrentSelection:nil];                
        if ((area & kPDFLinkArea))
            [super mouseDown:theEvent];
        else
            [self doDragWithEvent:theEvent];	
    } else if (toolMode == SKSelectToolMode) {
        [self setCurrentSelection:nil];                
        [self doSelectWithEvent:theEvent];
    } else if (toolMode == SKMagnifyToolMode) {
        [self setCurrentSelection:nil];
        [self doMagnifyWithEvent:theEvent];
    } else if (hideNotes == NO && IS_TABLET_EVENT(theEvent, NSEraserPointingDevice)) {
        [self doEraseAnnotationsWithEvent:theEvent];
    } else if ([self doSelectAnnotationWithEvent:theEvent]) {
        if ([activeAnnotation isLink] || ([theEvent clickCount] == 2 && [activeAnnotation isEditable]))
            [self doEditActiveAnnotationWithEvent:theEvent];
        else if ([activeAnnotation isMovable])
            [self doDragAnnotationWithEvent:theEvent];
        else
            [self doNothingWithEvent:theEvent];
    } else if (toolMode == SKNoteToolMode && hideNotes == NO && ANNOTATION_MODE_IS_MARKUP == NO) {
        if (annotationMode == SKInkNote) {
            [self doDrawFreehandNoteWithEvent:theEvent];
        } else {
            [self setActiveAnnotation:nil];
            [self doDragAnnotationWithEvent:theEvent];
        }
    } else if (area == kPDFPageArea && modifiers == 0 && [self hasTextNearMouse:theEvent] == NO) {
        [self setActiveAnnotation:nil];
        [self doDragWithEvent:theEvent];
    } else {
        [self setActiveAnnotation:nil];
        [super mouseDown:theEvent];
        if (toolMode == SKNoteToolMode && hideNotes == NO && ANNOTATION_MODE_IS_MARKUP && [[self currentSelection] hasCharacters]) {
            [self addAnnotationWithType:annotationMode];
            [self setCurrentSelection:nil];
        }
    }
}

- (void)mouseMoved:(NSEvent *)theEvent {
    [super mouseMoved:theEvent];
    [[self getCursorForEvent:theEvent] set];
    
    if ([activeAnnotation isLink]) {
        [[SKImageToolTipWindow sharedToolTipWindow] fadeOut];
        [self setActiveAnnotation:nil];
    }
    
    if ([navWindow isVisible] == NO) {
        if (navigationMode == SKNavigationEverywhere) {
            if ([navWindow parentWindow] == nil) {
                [navWindow setAlphaValue:0.0];
                [[self window] addChildWindow:navWindow ordered:NSWindowAbove];
            }
            [navWindow fadeIn];
        } else if (navigationMode == SKNavigationBottom && [theEvent locationInWindow].y < NAVIGATION_BOTTOM_EDGE_HEIGHT) {
            [self showNavWindow:YES];
        }
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
    
    NSInteger copyIdx = [menu indexOfItemWithTarget:self andAction:@selector(copy:)];
    if (copyIdx != -1) {
        [menu removeItemAtIndex:copyIdx];
        if ([menu numberOfItems] > copyIdx && [[menu itemAtIndex:copyIdx] isSeparatorItem] && (copyIdx == 0 || [[menu itemAtIndex:copyIdx - 1] isSeparatorItem]))
            [menu removeItemAtIndex:copyIdx];
        if (copyIdx > 0 && copyIdx == [menu numberOfItems] && [[menu itemAtIndex:copyIdx - 1] isSeparatorItem])
            [menu removeItemAtIndex:copyIdx - 1];
    }
    
    [menu insertItem:[NSMenuItem separatorItem] atIndex:0];
    
    item = [menu insertItemWithSubmenuAndTitle:NSLocalizedString(@"Tools", @"Menu item title") atIndex:0];
    submenu = [item submenu];
    
    item = [submenu addItemWithTitle:NSLocalizedString(@"Text", @"Menu item title") action:@selector(changeToolMode:) target:self tag:SKTextToolMode];

    item = [submenu addItemWithTitle:NSLocalizedString(@"Scroll", @"Menu item title") action:@selector(changeToolMode:) target:self tag:SKMoveToolMode];

    item = [submenu addItemWithTitle:NSLocalizedString(@"Magnify", @"Menu item title") action:@selector(changeToolMode:) target:self tag:SKMagnifyToolMode];
    
    item = [submenu addItemWithTitle:NSLocalizedString(@"Select", @"Menu item title") action:@selector(changeToolMode:) target:self tag:SKSelectToolMode];
    
    [submenu addItem:[NSMenuItem separatorItem]];
    
    item = [submenu addItemWithTitle:NSLocalizedString(@"Text Note", @"Menu item title") action:@selector(changeAnnotationMode:) target:self tag:SKFreeTextNote];

    item = [submenu addItemWithTitle:NSLocalizedString(@"Anchored Note", @"Menu item title") action:@selector(changeAnnotationMode:) target:self tag:SKAnchoredNote];

    item = [submenu addItemWithTitle:NSLocalizedString(@"Circle", @"Menu item title") action:@selector(changeAnnotationMode:) target:self tag:SKCircleNote];
    
    item = [submenu addItemWithTitle:NSLocalizedString(@"Box", @"Menu item title") action:@selector(changeAnnotationMode:) target:self tag:SKSquareNote];
    
    item = [submenu addItemWithTitle:NSLocalizedString(@"Highlight", @"Menu item title") action:@selector(changeAnnotationMode:) target:self tag:SKHighlightNote];
    
    item = [submenu addItemWithTitle:NSLocalizedString(@"Underline", @"Menu item title") action:@selector(changeAnnotationMode:) target:self tag:SKUnderlineNote];
    
    item = [submenu addItemWithTitle:NSLocalizedString(@"Strike Out", @"Menu item title") action:@selector(changeAnnotationMode:) target:self tag:SKStrikeOutNote];
    
    item = [submenu addItemWithTitle:NSLocalizedString(@"Line", @"Menu item title") action:@selector(changeAnnotationMode:) target:self tag:SKLineNote];
    
    item = [submenu addItemWithTitle:NSLocalizedString(@"Freehand", @"Menu item title") action:@selector(changeAnnotationMode:) target:self tag:SKInkNote];
    
    [menu insertItem:[NSMenuItem separatorItem] atIndex:0];
    
    item = [menu insertItemWithTitle:NSLocalizedString(@"Take Snapshot", @"Menu item title") action:@selector(takeSnapshot:) target:self atIndex:0];
    [item setRepresentedObject:theEvent];
    
    if (([self toolMode] == SKTextToolMode || [self toolMode] == SKNoteToolMode) && [self hideNotes] == NO) {
        
        [menu insertItem:[NSMenuItem separatorItem] atIndex:0];
        
        item = [menu insertItemWithSubmenuAndTitle:NSLocalizedString(@"New Note or Highlight", @"Menu item title") atIndex:0];
        submenu = [item submenu];
        
        item = [submenu addItemWithTitle:NSLocalizedString(@"Text Note", @"Menu item title") action:@selector(addAnnotation:) target:self tag:SKFreeTextNote];
        [item setRepresentedObject:theEvent];
        
        item = [submenu addItemWithTitle:NSLocalizedString(@"Anchored Note", @"Menu item title") action:@selector(addAnnotation:) target:self tag:SKAnchoredNote];
        [item setRepresentedObject:theEvent];
        
        item = [submenu addItemWithTitle:NSLocalizedString(@"Circle", @"Menu item title") action:@selector(addAnnotation:) target:self tag:SKCircleNote];
        [item setRepresentedObject:theEvent];
        
        item = [submenu addItemWithTitle:NSLocalizedString(@"Box", @"Menu item title") action:@selector(addAnnotation:) target:self tag:SKSquareNote];
        [item setRepresentedObject:theEvent];
        
        if ([[self currentSelection] hasCharacters]) {
            item = [submenu addItemWithTitle:NSLocalizedString(@"Highlight", @"Menu item title") action:@selector(addAnnotation:) target:self tag:SKHighlightNote];
            [item setRepresentedObject:theEvent];
            
            item = [submenu addItemWithTitle:NSLocalizedString(@"Underline", @"Menu item title") action:@selector(addAnnotation:) target:self tag:SKUnderlineNote];
            [item setRepresentedObject:theEvent];
            
            item = [submenu addItemWithTitle:NSLocalizedString(@"Strike Out", @"Menu item title") action:@selector(addAnnotation:) target:self tag:SKStrikeOutNote];
            [item setRepresentedObject:theEvent];
        }
        
        item = [submenu addItemWithTitle:NSLocalizedString(@"Line", @"Menu item title") action:@selector(addAnnotation:) target:self tag:SKLineNote];
        [item setRepresentedObject:theEvent];
        
        [menu insertItem:[NSMenuItem separatorItem] atIndex:0];
        
        NSPoint point = NSZeroPoint;
        PDFPage *page = [self pageAndPoint:&point forEvent:theEvent nearest:YES];
        PDFAnnotation *annotation = nil;
        
        if (page) {
            annotation = [page annotationAtPoint:[self convertPoint:point toPage:page]];
            if ([annotation isSkimNote] == NO)
                annotation = nil;
        }
        
        if (annotation) {
            if ((annotation != activeAnnotation || [NSFontPanel sharedFontPanelExists] == NO || [[NSFontPanel sharedFontPanel] isVisible] == NO) &&
                [[annotation type] isEqualToString:SKNFreeTextString]) {
                item = [menu insertItemWithTitle:[NSLocalizedString(@"Note Font", @"Menu item title") stringByAppendingEllipsis] action:@selector(showFontsForThisAnnotation:) target:self atIndex:0];
                [item setRepresentedObject:annotation];
            }
            
            if ((annotation != activeAnnotation || [SKLineInspector sharedLineInspectorExists] == NO || [[[SKLineInspector sharedLineInspector] window] isVisible] == NO) &&
                [annotation isMarkup] == NO && [annotation isNote] == NO) {
                item = [menu insertItemWithTitle:[NSLocalizedString(@"Note Line", @"Menu item title") stringByAppendingEllipsis] action:@selector(showLinesForThisAnnotation:) target:self atIndex:0];
                [item setRepresentedObject:annotation];
            }
            
            if (annotation != activeAnnotation || [NSColorPanel sharedColorPanelExists] == NO || [[NSColorPanel sharedColorPanel] isVisible] == NO) {
                item = [menu insertItemWithTitle:[NSLocalizedString(@"Note Color", @"Menu item title") stringByAppendingEllipsis] action:@selector(showColorsForThisAnnotation:) target:self atIndex:0];
                [item setRepresentedObject:annotation];
            }
            
            if ([self isEditingAnnotation:annotation] == NO && [annotation isEditable]) {
                item = [menu insertItemWithTitle:NSLocalizedString(@"Edit Note", @"Menu item title") action:@selector(editThisAnnotation:) target:self atIndex:0];
                [item setRepresentedObject:annotation];
            }
            
            item = [menu insertItemWithTitle:NSLocalizedString(@"Remove Note", @"Menu item title") action:@selector(removeThisAnnotation:) target:self atIndex:0];
            [item setRepresentedObject:annotation];
        } else if ([activeAnnotation isSkimNote]) {
            if (([NSFontPanel sharedFontPanelExists] == NO || [[NSFontPanel sharedFontPanel] isVisible] == NO) &&
                [[activeAnnotation type] isEqualToString:SKNFreeTextString]) {
                item = [menu insertItemWithTitle:[NSLocalizedString(@"Note Font", @"Menu item title") stringByAppendingEllipsis] action:@selector(showFontsForThisAnnotation:) target:self atIndex:0];
            }
            
            if (([SKLineInspector sharedLineInspectorExists] == NO || [[[SKLineInspector sharedLineInspector] window] isVisible] == NO) &&
                [activeAnnotation isMarkup] == NO && [activeAnnotation isNote] == NO) {
                item = [menu insertItemWithTitle:[NSLocalizedString(@"Current Note Line", @"Menu item title") stringByAppendingEllipsis] action:@selector(showLinesForThisAnnotation:) target:self atIndex:0];
            }
            
            if ([NSColorPanel sharedColorPanelExists] == NO || [[NSColorPanel sharedColorPanel] isVisible] == NO) {
                item = [menu insertItemWithTitle:[NSLocalizedString(@"Current Note Color", @"Menu item title") stringByAppendingEllipsis] action:@selector(showColorsForThisAnnotation:) target:self atIndex:0];
            }
            
            if (editor == nil && [activeAnnotation isEditable]) {
                item = [menu insertItemWithTitle:NSLocalizedString(@"Edit Current Note", @"Menu item title") action:@selector(editActiveAnnotation:) target:self atIndex:0];
            }
            
            item = [menu insertItemWithTitle:NSLocalizedString(@"Remove Current Note", @"Menu item title") action:@selector(removeActiveAnnotation:) target:self atIndex:0];
        }
        
        if ([[NSPasteboard generalPasteboard] canReadObjectForClasses:[NSArray arrayWithObjects:[PDFAnnotation class], [NSString class], nil] options:[NSDictionary dictionary]]) {
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
    dy = dy > 0 ? fmin(0.2, dy) : fmax(-0.2, dy);
    [self setScaleFactor:[self scaleFactor] + 0.5 * dy];
}

- (void)mouseEntered:(NSEvent *)theEvent {
    NSTrackingArea *eventArea = [theEvent trackingArea];
    PDFAnnotation *annotation;
    if ([eventArea owner] == self && [eventArea isEqual:trackingArea]) {
        [[self window] setAcceptsMouseMovedEvents:YES];
    } else if ([eventArea owner] == self && (annotation = [[eventArea userInfo] objectForKey:SKAnnotationKey])) {
        [[SKImageToolTipWindow sharedToolTipWindow] showForImageContext:annotation atPoint:NSZeroPoint];
    } else {
        [super mouseEntered:theEvent];
    }
}
 
- (void)mouseExited:(NSEvent *)theEvent {
    NSTrackingArea *eventArea = [theEvent trackingArea];
    PDFAnnotation *annotation;
    if ([eventArea owner] == self && [eventArea isEqual:trackingArea]) {
        [[self window] setAcceptsMouseMovedEvents:([self interactionMode] == SKFullScreenMode)];
    } else if ([eventArea owner] == self && (annotation = [[eventArea userInfo] objectForKey:SKAnnotationKey])) {
        if ([annotation isEqual:[[SKImageToolTipWindow sharedToolTipWindow] currentImageContext]])
            [[SKImageToolTipWindow sharedToolTipWindow] fadeOut];
    } else {
        [super mouseExited:theEvent];
    }
}

- (void)rotatePageAtIndex:(NSUInteger)idx by:(NSInteger)rotation {
    NSUndoManager *undoManager = [self undoManager];
    [[undoManager prepareWithInvocationTarget:self] rotatePageAtIndex:idx by:-rotation];
    [undoManager setActionName:NSLocalizedString(@"Rotate Page", @"Undo action name")];
    [[[[self window] windowController] document] undoableActionIsDiscardable];
    
    PDFPage *page = [[self document] pageAtIndex:idx];
    [page setRotation:[page rotation] + rotation];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFPageBoundsDidChangeNotification 
            object:[self document] userInfo:[NSDictionary dictionaryWithObjectsAndKeys:SKPDFPageActionRotate, SKPDFPageActionKey, page, SKPDFPagePageKey, nil]];
}

- (void)beginGestureWithEvent:(NSEvent *)theEvent {
    [super beginGestureWithEvent:theEvent];
    PDFPage *page = [self pageAndPoint:NULL forEvent:theEvent nearest:YES];
    gestureRotation = 0.0;
    gesturePageIndex = [(page ?: [self currentPage]) pageIndex];
}

- (void)endGestureWithEvent:(NSEvent *)theEvent {
    [super endGestureWithEvent:theEvent];
    gestureRotation = 0.0;
    gesturePageIndex = NSNotFound;
}

- (void)rotateWithEvent:(NSEvent *)theEvent {
    if (interactionMode == SKPresentationMode)
        return;
    if ([theEvent respondsToSelector:@selector(rotation)])
        gestureRotation -= [theEvent rotation];
    if (fabs(gestureRotation) > 45.0 && gesturePageIndex != NSNotFound) {
        [self rotatePageAtIndex:gesturePageIndex by:90.0 * round(gestureRotation / 90.0)];
        gestureRotation -= 90.0 * round(gestureRotation / 90.0);
    }
}

- (void)magnifyWithEvent:(NSEvent *)theEvent {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKDisablePinchZoomKey] == NO && interactionMode != SKPresentationMode)
        [super magnifyWithEvent:theEvent];
}

- (void)swipeWithEvent:(NSEvent *)theEvent {
    if (interactionMode == SKPresentationMode && [transitionController hasTransition]) {
        if ([theEvent deltaX] < 0.0 || [theEvent deltaY] < 0.0) {
            if ([self canGoToNextPage])
                [self goToNextPage:nil];
        } else if ([theEvent deltaX] > 0.0 || [theEvent deltaY] > 0.0) {
            if ([self canGoToPreviousPage])
                [self goToPreviousPage:nil];
        }
    } else {
        [super swipeWithEvent:theEvent];
    }
}

#pragma mark NSDraggingDestination protocol

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    NSDragOperation dragOp = NSDragOperationNone;
    NSPasteboard *pboard = [sender draggingPasteboard];
    if ([pboard canReadItemWithDataConformingToTypes:[NSArray arrayWithObjects:NSPasteboardTypeColor, SKPasteboardTypeLineStyle, nil]]) {
        return [self draggingUpdated:sender];
    } else if ([[SKPDFView superclass] instancesRespondToSelector:_cmd]) {
        dragOp = [super draggingEntered:sender];
    }
    return dragOp;
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender {
    NSDragOperation dragOp = NSDragOperationNone;
    NSPasteboard *pboard = [sender draggingPasteboard];
    if ([pboard canReadItemWithDataConformingToTypes:[NSArray arrayWithObjects:NSPasteboardTypeColor, SKPasteboardTypeLineStyle, nil]]) {
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
                    ([pboard canReadItemWithDataConformingToTypes:[NSArray arrayWithObjects:NSPasteboardTypeColor, nil]] || [type isEqualToString:SKNFreeTextString] || [type isEqualToString:SKNCircleString] || [type isEqualToString:SKNSquareString] || [type isEqualToString:SKNLineString] || [type isEqualToString:SKNInkString])) {
                    if ([annotation isEqual:highlightAnnotation] == NO) {
                        if (highlightAnnotation) {
                            [self setNeedsDisplayForAnnotation:highlightAnnotation];
                            highlightAnnotation = nil;
                        }
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
    if ([pboard canReadItemWithDataConformingToTypes:[NSArray arrayWithObjects:NSPasteboardTypeColor, SKPasteboardTypeLineStyle, nil]]) {
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
    if ([pboard canReadItemWithDataConformingToTypes:[NSArray arrayWithObjects:NSPasteboardTypeColor, SKPasteboardTypeLineStyle, nil]]) {
        if (highlightAnnotation) {
            NSString *type = [highlightAnnotation type];
            if ([pboard canReadItemWithDataConformingToTypes:[NSArray arrayWithObjects:NSPasteboardTypeColor, nil]]) {
                if (([NSEvent standardModifierFlags] & NSAlternateKeyMask) && [highlightAnnotation respondsToSelector:@selector(setInteriorColor:)])
                    [(id)highlightAnnotation setInteriorColor:[NSColor colorFromPasteboard:pboard]];
                else if (([NSEvent standardModifierFlags] & NSAlternateKeyMask) && [highlightAnnotation respondsToSelector:@selector(setFontColor:)])
                    [(id)highlightAnnotation setFontColor:[NSColor colorFromPasteboard:pboard]];
                else
                    [highlightAnnotation setColor:[NSColor colorFromPasteboard:pboard]];
                performedDrag = YES;
            } else if ([type isEqualToString:SKNFreeTextString] || [type isEqualToString:SKNCircleString] || [type isEqualToString:SKNSquareString] || [type isEqualToString:SKNLineString] || [type isEqualToString:SKNInkString]) {
                [pboard types];
                NSDictionary *dict = [pboard propertyListForType:SKPasteboardTypeLineStyle];
                NSNumber *number;
                if ((number = [dict objectForKey:SKLineWellLineWidthKey]))
                    [highlightAnnotation setLineWidth:[number doubleValue]];
                [highlightAnnotation setDashPattern:[dict objectForKey:SKLineWellDashPatternKey]];
                if ((number = [dict objectForKey:SKLineWellStyleKey]))
                    [highlightAnnotation setBorderStyle:[number integerValue]];
                if ([type isEqualToString:SKNLineString]) {
                    if ((number = [dict objectForKey:SKLineWellStartLineStyleKey]))
                        [(PDFAnnotationLine *)highlightAnnotation setStartLineStyle:[number integerValue]];
                    if ((number = [dict objectForKey:SKLineWellEndLineStyleKey]))
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
    if ([self toolMode] == SKSelectToolMode && NSIsEmptyRect(selectionRect) == NO && selectionPageIndex != NSNotFound && 
        (([[self document] allowsPrinting] && [types containsObject:NSPasteboardTypePDF]) || [types containsObject:NSPasteboardTypeTIFF])) {
        NSMutableArray *writeTypes = [NSMutableArray array];
        NSData *pdfData = nil;
        NSData *tiffData = nil;
        NSRect selRect = NSIntegralRect(selectionRect);
        
        if ([types containsObject:NSPasteboardTypePDF]  &&
            [[self document] allowsPrinting] &&
            (pdfData = [[self currentSelectionPage] PDFDataForRect:selRect]))
            [writeTypes addObject:NSPasteboardTypePDF];
        
        if ([types containsObject:NSPasteboardTypeTIFF] &&
            (tiffData = [[self currentSelectionPage] TIFFDataForRect:selRect]))
            [writeTypes addObject:NSPasteboardTypeTIFF];
        
        if ([writeTypes count] > 0) {
            [pboard declareTypes:writeTypes owner:nil];
            if (pdfData)
                [pboard setData:pdfData forType:NSPasteboardTypePDF];
            if (tiffData)
                [pboard setData:tiffData forType:NSPasteboardTypeTIFF];
            
            return YES;
        } else {
            return NO;
        }
        
    } else if ([[SKPDFView superclass] instancesRespondToSelector:_cmd]) {
        return [super writeSelectionToPasteboard:pboard types:types];
    }
    return NO;
}

- (id)validRequestorForSendType:(NSString *)sendType returnType:(NSString *)returnType {
    if ([self toolMode] == SKSelectToolMode && NSIsEmptyRect(selectionRect) == NO && selectionPageIndex != NSNotFound && returnType == nil && 
        (([[self document] allowsPrinting] && [sendType isEqualToString:NSPasteboardTypePDF]) || [sendType isEqualToString:NSPasteboardTypeTIFF])) {
        return self;
    }
    return [super validRequestorForSendType:sendType returnType:returnType];
}

#pragma mark Annotation management

- (void)addAnnotation:(id)sender {
    NSEvent *event = [sender representedObject] ?: [NSApp currentEvent];
    NSPoint point = ([[event window] isEqual:[self window]] && ([event type] == NSLeftMouseDown || [event type] == NSRightMouseDown)) ? [event locationInWindow] : [[self window] mouseLocationOutsideOfEventStream];
    [self addAnnotationWithType:[sender tag] defaultPoint:point];
}

- (void)addAnnotationWithType:(SKNoteType)annotationType {
    [self addAnnotationWithType:annotationType defaultPoint:[[self window] mouseLocationOutsideOfEventStream]];
}

// y=primaryOutset(x) approximately solves x*secondaryOutset(y)=y
// y=cubrt(1/2x^2)+..., x->0; y=sqrt(2)-1+1/2(sqrt(2)-1)(x-1)+..., x->1
// 0.436947024419157 = 4/3cubrt(1/2)-3/2(sqrt(2)-1)
// 0.057460060808152 = 1/3cubrt(1/2)-1/2(sqrt(2)-1)
static inline CGFloat primaryOutset(CGFloat x) {
    return pow(M_SQRT1_2 * x, 2.0/3.0) - 0.436947024419157 * x + 0.057460060808152 * x * x;
}

// an ellipse outset by 1/2*w*x and 1/2*h*secondaryOutset(x) circumscribes a rect with size {w,h} for any x
static inline CGFloat secondaryOutset(CGFloat x) {
    return (x + 1.0) / sqrt(x * (x + 2.0)) - 1.0;
}

- (void)addAnnotationWithType:(SKNoteType)annotationType defaultPoint:(NSPoint)point {
	PDFPage *page = nil;
	NSRect bounds = NSZeroRect;
    PDFSelection *selection = [self currentSelection];
    NSString *text = nil;
	
    if ([selection hasCharacters]) {
        text = [selection cleanedString];
        
		// Get bounds (page space) for selection (first page in case selection spans multiple pages).
		page = [selection safeFirstPage];
		bounds = [selection boundsForPage: page];
        if (annotationType == SKCircleNote) {
            CGFloat dw, dh, w = NSWidth(bounds), h = NSHeight(bounds);
            if (h < w) {
                dw = primaryOutset(h / w);
                dh = secondaryOutset(dw);
            } else {
                dh = primaryOutset(w / h);
                dw = secondaryOutset(dh);
            }
            bounds = NSInsetRect(bounds, -0.5 * w * dw - 4.0, -0.5 * h * dh - 4.0);
        } else if (annotationType == SKSquareNote) {
            bounds = NSInsetRect(bounds, -5.0, -5.0);
        } else if (annotationType == SKAnchoredNote) {
            switch ([page rotation]) {
                case 0:
                    bounds.origin.x = floor(NSMinX(bounds)) - SKNPDFAnnotationNoteSize.width;
                    bounds.origin.y = floor(NSMaxY(bounds)) - SKNPDFAnnotationNoteSize.height;
                    break;
                case 90:
                    bounds.origin.x = ceil(NSMinX(bounds));
                    bounds.origin.y = floor(NSMinY(bounds)) - SKNPDFAnnotationNoteSize.height;
                    break;
                case 180:
                    bounds.origin.x = ceil(NSMaxX(bounds));
                    bounds.origin.y = ceil(NSMinY(bounds));
                    break;
                case 270:
                    bounds.origin.x = floor(NSMaxX(bounds)) - SKNPDFAnnotationNoteSize.height;
                    bounds.origin.y = ceil(NSMaxY(bounds));
                    break;
                default:
                    break;
            }
            bounds.size = SKNPDFAnnotationNoteSize;
        }
        bounds = NSIntegralRect(bounds);
	} else if (annotationType != SKHighlightNote && annotationType != SKUnderlineNote && annotationType != SKStrikeOutNote) {
        
		// First try the current mouse position
        NSPoint center = [self convertPoint:point fromView:nil];
        
        // if the mouse was in the toolbar and there is a page below the toolbar, we get a point outside of the visible rect
        page = NSMouseInRect(center, [self visibleContentRect], [self isFlipped]) ? [self pageForPoint:center nearest:NO] : nil;
        
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
            // we need a drawn path to add an ink note
            break;
	}
    if (newAnnotation) {
        if (annotationType != SKLineNote && annotationType != SKInkNote) {
            if (text == nil)
                text = [[page selectionForRect:[newAnnotation bounds]] cleanedString];
            if (text)
                [newAnnotation setString:text];
        }
        
        [newAnnotation registerUserName];
        [self addAnnotation:newAnnotation toPage:page];
        [[self undoManager] setActionName:NSLocalizedString(@"Add Note", @"Undo action name")];

        [self setActiveAnnotation:newAnnotation];
        [newAnnotation release];
        if (annotationType == SKAnchoredNote && [[self delegate] respondsToSelector:@selector(PDFView:editAnnotation:)])
            [[self delegate] PDFView:self editAnnotation:activeAnnotation];
    } else NSBeep();
}

- (void)addAnnotation:(PDFAnnotation *)annotation toPage:(PDFPage *)page {
    [[[self undoManager] prepareWithInvocationTarget:self] removeAnnotation:annotation];
    [annotation setShouldDisplay:hideNotes == NO || [annotation isSkimNote] == NO];
    [annotation setShouldPrint:hideNotes == NO || [annotation isSkimNote] == NO];
    [page addAnnotation:annotation];
    [self setNeedsDisplayForAnnotation:annotation];
    [self annotationsChangedOnPage:page];
    [self resetPDFToolTipRects];
    if ([annotation isSkimNote])
        SKDESTROY(accessibilityChildren);
    [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewDidAddAnnotationNotification object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:page, SKPDFViewPageKey, annotation, SKPDFViewAnnotationKey, nil]];                
    NSAccessibilityPostNotification([SKAccessibilityProxyFauxUIElement elementWithObject:annotation parent:[self documentView]], NSAccessibilityCreatedNotification);
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
    PDFAnnotation *wasAnnotation = [annotation retain];
    PDFPage *page = [[wasAnnotation page] retain];
    
    [[[self undoManager] prepareWithInvocationTarget:self] addAnnotation:wasAnnotation toPage:page];
    if ([self isEditingAnnotation:annotation])
        [self commitEditing];
	if (activeAnnotation == annotation)
		[self setActiveAnnotation:nil];
    [self setNeedsDisplayForAnnotation:wasAnnotation];
    [page removeAnnotation:wasAnnotation];
    if ([wasAnnotation isSkimNote])
        SKDESTROY(accessibilityChildren);
    [self annotationsChangedOnPage:page];
    if ([wasAnnotation isNote])
        [self resetPDFToolTipRects];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewDidRemoveAnnotationNotification object:self 
        userInfo:[NSDictionary dictionaryWithObjectsAndKeys:wasAnnotation, SKPDFViewAnnotationKey, page, SKPDFViewPageKey, nil]];
    NSAccessibilityPostNotification([SKAccessibilityProxyFauxUIElement elementWithObject:wasAnnotation parent:[self documentView]], NSAccessibilityUIElementDestroyedNotification);
    [wasAnnotation release];
    [page release];
}

- (void)moveAnnotation:(PDFAnnotation *)annotation toPage:(PDFPage *)page {
    PDFPage *oldPage = [[annotation page] retain];
    [[[self undoManager] prepareWithInvocationTarget:self] moveAnnotation:annotation toPage:oldPage];
    [[self undoManager] setActionName:NSLocalizedString(@"Edit Note", @"Undo action name")];
    [self setNeedsDisplayForAnnotation:annotation];
    [annotation retain];
    [oldPage removeAnnotation:annotation];
    [page addAnnotation:annotation];
    [annotation release];
    [self setNeedsDisplayForAnnotation:annotation];
    [self annotationsChangedOnPage:oldPage];
    [self annotationsChangedOnPage:page];
    if ([annotation isNote])
        [self resetPDFToolTipRects];
    if ([self isEditingAnnotation:annotation])
        [editor layout];
    SKDESTROY(accessibilityChildren);
    [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewDidMoveAnnotationNotification object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:oldPage, SKPDFViewOldPageKey, page, SKPDFViewNewPageKey, annotation, SKPDFViewAnnotationKey, nil]];                
    [oldPage release];
}

- (void)editThisAnnotation:(id)sender {
    PDFAnnotation *annotation = [sender representedObject];
    
    if (annotation == nil || [self isEditingAnnotation:annotation])
        return;
    
    [self commitEditing];
    if (activeAnnotation != annotation)
        [self setActiveAnnotation:annotation];
    [self editActiveAnnotation:sender];
}

- (void)editActiveAnnotation:(id)sender {
    if (nil == activeAnnotation)
        return;
    
    [self commitEditing];
    
    NSString *type = [activeAnnotation type];
    
    if ([activeAnnotation isLink]) {
        
        [[SKImageToolTipWindow sharedToolTipWindow] orderOut:self];
        if ([activeAnnotation destination])
            [self goToDestination:[(PDFAnnotationLink *)activeAnnotation destination]];
        else if ([(PDFAnnotationLink *)activeAnnotation URL])
            [[NSWorkspace sharedWorkspace] openURL:[(PDFAnnotationLink *)activeAnnotation URL]];
        [self setActiveAnnotation:nil];
        
    } else if (hideNotes == NO && [type isEqualToString:SKNFreeTextString]) {
        
        editor = [[SKTextNoteEditor alloc] initWithPDFView:self annotation:(PDFAnnotationFreeText *)activeAnnotation];
        [[self window] makeFirstResponder:self];
        [editor layout];
        
        [self setNeedsDisplayForAnnotation:activeAnnotation];
        
        if ([[self delegate] respondsToSelector:@selector(PDFViewDidBeginEditing:)])
            [[self delegate] PDFViewDidBeginEditing:self];
        
    } else if (hideNotes == NO && [activeAnnotation isEditable]) {
        
        [[SKImageToolTipWindow sharedToolTipWindow] orderOut:self];
        
        if ([[self delegate] respondsToSelector:@selector(PDFView:editAnnotation:)])
            [[self delegate] PDFView:self editAnnotation:activeAnnotation];
        
    }
    
}

- (void)textNoteEditorDidEndEditing:(SKTextNoteEditor *)textNoteEditor {
    SKDESTROY(editor);
    
    [self setNeedsDisplayForAnnotation:activeAnnotation];
    
    if ([[self delegate] respondsToSelector:@selector(PDFViewDidEndEditing:)])
        [[self delegate] PDFViewDidEndEditing:self];
}

- (void)discardEditing {
    [editor discardEditing];
}

- (BOOL)commitEditing {
    if (editor)
        return [editor commitEditing];
    return YES;
}

- (void)selectNextActiveAnnotation:(id)sender {
    PDFDocument *pdfDoc = [self document];
    NSInteger numberOfPages = [pdfDoc pageCount];
    NSInteger i = -1;
    NSInteger pageIndex, startPageIndex = -1;
    PDFAnnotation *annotation = nil;
    
    if (activeAnnotation) {
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
            NSPoint point = NSMakePoint(NSMinX(bounds) + TOOLTIP_OFFSET_FRACTION * NSWidth(bounds), NSMinY(bounds) + TOOLTIP_OFFSET_FRACTION * NSHeight(bounds));
            point = [self convertPoint:[self convertPoint:point fromPage:[annotation page]] toView:nil];
            point = [[self window] convertBaseToScreen:NSMakePoint(round(point.x), round(point.y))];
            [[SKImageToolTipWindow sharedToolTipWindow] showForImageContext:annotation atPoint:point];
        } else {
            [[SKImageToolTipWindow sharedToolTipWindow] orderOut:self];
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
            NSPoint point = NSMakePoint(NSMinX(bounds) + TOOLTIP_OFFSET_FRACTION * NSWidth(bounds), NSMinY(bounds) + TOOLTIP_OFFSET_FRACTION * NSHeight(bounds));
            point = [self convertPoint:[self convertPoint:point fromPage:[annotation page]] toView:nil];
            point = [[self window] convertBaseToScreen:NSMakePoint(round(point.x), round(point.y))];
            [[SKImageToolTipWindow sharedToolTipWindow] showForImageContext:annotation atPoint:point];
        } else {
            [[SKImageToolTipWindow sharedToolTipWindow] orderOut:self];
        }
    }
}

- (BOOL)isEditingAnnotation:(PDFAnnotation *)annotation {
    return editor && activeAnnotation == annotation;
}

- (void)scrollPageToVisible:(PDFPage *)page {
    NSRect rect = [page boundsForBox:[self displayBox]];
    if ([[self currentPage] isEqual:page] == NO)
        [self goToPage:page];
    rect = SKSliceRect([self convertRect:rect fromPage:page], 1.0, NSMaxYEdge);
    [self goToRect:[self convertRect:rect toPage:page] onPage:page];
}

- (void)scrollAnnotationToVisible:(PDFAnnotation *)annotation {
    [self goToRect:[annotation bounds] onPage:[annotation page]];
}

- (void)setNeedsDisplayForAnnotation:(PDFAnnotation *)annotation onPage:(PDFPage *)page {
    NSRect rect = [annotation displayRect];
    if (annotation == activeAnnotation && [annotation isResizable]) {
        CGFloat margin = HANDLE_SIZE / [self scaleFactor];
        rect = NSInsetRect(rect, -margin, -margin);
    }
    [self setNeedsDisplayInRect:rect ofPage:page];
    [self annotationsChangedOnPage:page];
}

#pragma mark Sync

- (void)displayLineAtPoint:(NSPoint)point inPageAtIndex:(NSUInteger)pageIndex showReadingBar:(BOOL)showBar {
    if (pageIndex < [[self document] pageCount]) {
        PDFPage *page = [[self document] pageAtIndex:pageIndex];
        PDFSelection *sel = [page selectionForLineAtPoint:point];
        NSRect rect = [sel hasCharacters] ? [sel boundsForPage:page] : SKRectFromCenterAndSquareSize(point, 10.0);
        
        if (interactionMode != SKPresentationMode) {
            if (showBar) {
                NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:[readingBar page], SKPDFViewOldPageKey, nil];
                if ([self hasReadingBar] == NO)
                    [self toggleReadingBar];
                [readingBar setPage:page];
                [readingBar goToLineForPoint:point];
                [self setNeedsDisplay:YES];
                [userInfo setObject:page forKey:SKPDFViewNewPageKey];
                [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewReadingBarDidChangeNotification object:self userInfo:userInfo];
            } else if ([sel hasCharacters] && [self toolMode] == SKTextToolMode) {
                [self setCurrentSelection:sel];
            }
        }
        if ([self displayMode] == kPDFDisplaySinglePageContinuous || [self displayMode] == kPDFDisplayTwoUpContinuous) {
            NSRect visibleRect = [self convertRect:[self visibleContentRect] toPage:page];
            rect = NSInsetRect(rect, 0.0, - floor( ( NSHeight(visibleRect) - NSHeight(rect) ) / 2.0 ) );
            if (NSWidth(rect) > NSWidth(visibleRect)) {
                if (NSMaxX(rect) < point.x + 0.5 * NSWidth(visibleRect))
                    rect.origin.x = NSMaxX(rect) - NSWidth(visibleRect);
                else if (NSMinX(rect) < point.x - 0.5 * NSWidth(visibleRect))
                    rect.origin.x = floor( point.x - 0.5 * NSWidth(visibleRect) );
                rect.size.width = NSWidth(visibleRect);
            }
        }
        [self goToRect:rect onPage:page];
        
        if (syncDot) {
            [syncDot invalidate];
            SKDESTROY(syncDot);
        }
        syncDot = [[SKSyncDot alloc] initWithPoint:point page:page updateHandler:^(BOOL finished){
                [self setNeedsDisplayInRect:[syncDot bounds] ofPage:[syncDot page]];
                if (finished)
                    SKDESTROY(syncDot);
            }];
    }
}

#pragma mark Accessibility

- (NSArray *)accessibilityChildren {
    if (accessibilityChildren == nil) {
        PDFDocument *pdfDoc = [self document];
        NSRange range = [self displayedPageIndexRange];
        NSMutableArray *children = [NSMutableArray array];
        
        //[children addObject:[SKAccessibilityPDFDisplayViewElement elementWithParent:[self documentView]]];
        
        NSUInteger i;
        for (i = range.location; i < NSMaxRange(range); i++) {
            PDFPage *page = [pdfDoc pageAtIndex:i];
            for (PDFAnnotation *annotation in [page annotations]) {
                if ([annotation isLink] || [annotation isSkimNote]) {
                    SKAccessibilityProxyFauxUIElement *element = [[SKAccessibilityProxyFauxUIElement alloc] initWithObject:annotation parent:[self documentView]];
                    [children addObject:element];
                    [element release];
                }
            }
        
        }
        accessibilityChildren = [children copy];
    }
    if ([[editor textField] superview])
        return [accessibilityChildren arrayByAddingObject:[editor textField]];
    else
        return accessibilityChildren;
}

- (id)accessibilityChildAtPoint:(NSPoint)point {
    NSPoint localPoint = [self convertPoint:[[self window] convertScreenToBase:point] fromView:nil];
    id child = nil;
    if ([[editor textField] superview] && NSMouseInRect([self convertPoint:localPoint toView:[self documentView]], [[editor textField] frame], [[self documentView] isFlipped])) {
        child = NSAccessibilityUnignoredDescendant([editor textField]);
    } else {
        PDFPage *page = [self pageForPoint:localPoint nearest:NO];
        if (page) {
            PDFAnnotation *annotation = [page annotationAtPoint:[self convertPoint:localPoint toPage:page]];
            if ([annotation isLink] || [annotation isSkimNote])
                child = NSAccessibilityUnignoredDescendant([SKAccessibilityProxyFauxUIElement elementWithObject:annotation parent:[self documentView]]);
        }
    }
    //if (child == nil)
    //    child = NSAccessibilityUnignoredDescendant([SKAccessibilityPDFDisplayViewElement elementWithParent:[self documentView]]);
    return [child accessibilityHitTest:point];
}

- (id)accessibilityFocusedChild {
    id child = nil;
    if ([[editor textField] superview])
        child = NSAccessibilityUnignoredDescendant([editor textField]);
    else if (activeAnnotation)
        child = NSAccessibilityUnignoredDescendant([SKAccessibilityProxyFauxUIElement elementWithObject:activeAnnotation parent:[self documentView]]);
    //else
    //    child = NSAccessibilityUnignoredDescendant([SKAccessibilityPDFDisplayViewElement elementWithParent:[self documentView]]);
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
        event = [sender representedObject] ?: [NSApp currentEvent];
        point = ([[event window] isEqual:[self window]] && ([event type] == NSLeftMouseDown || [event type] == NSRightMouseDown)) ? [event locationInWindow] : [[self window] mouseLocationOutsideOfEventStream];
        point = [self convertPoint:point fromView:nil];
        page = [self pageForPoint:point nearest:NO];
        if (page == nil) {
            // Get the center
            NSRect viewFrame = [self frame];
            point = SKCenterPoint(viewFrame);
            page = [self pageForPoint:point nearest:YES];
        }
        
        point = [self convertPoint:point toPage:page];
        
        rect = [self convertRect:[page boundsForBox:kPDFDisplayBoxCropBox] fromPage:page];
        rect.origin.y = point.y - 0.5 * DEFAULT_SNAPSHOT_HEIGHT;
        rect.size.height = DEFAULT_SNAPSHOT_HEIGHT;
        
        rect = [self convertRect:rect toPage:page];
    }
    
    if ([[self delegate] respondsToSelector:@selector(PDFView:showSnapshotAtPageNumber:forRect:scaleFactor:autoFits:)])
        [[self delegate] PDFView:self showSnapshotAtPageNumber:[page pageIndex] forRect:rect scaleFactor:[self scaleFactor] autoFits:autoFits];
}

#pragma mark Notification handling

- (void)handlePageChangedNotification:(NSNotification *)notification {
    if ([self displayMode] == kPDFDisplaySinglePage || [self displayMode] == kPDFDisplayTwoUp) {
        [editor layout];
        [self resetPDFToolTipRects];
        SKDESTROY(accessibilityChildren);
    }
}

- (void)handleScaleChangedNotification:(NSNotification *)notification {
    [self resetPDFToolTipRects];
}

- (void)handleKeyStateChangedNotification:(NSNotification *)notification {
    if (selectionPageIndex != NSNotFound) {
        CGFloat margin = HANDLE_SIZE / [self scaleFactor];
        for (PDFPage *page in [self visiblePages])
            [self setNeedsDisplayInRect:NSInsetRect(selectionRect, -margin, -margin) ofPage:page];
    }
    if (activeAnnotation)
        [self setNeedsDisplayForAnnotation:activeAnnotation];
}

#pragma mark Key and window changes

- (void)viewWillMoveToWindow:(NSWindow *)newWindow {
    if (editor && [self commitEditing] == NO)
        [self discardEditing];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    NSWindow *oldWindow = [self window];
    if (oldWindow) {
        [nc removeObserver:self name:NSWindowDidBecomeKeyNotification object:oldWindow];
        [nc removeObserver:self name:NSWindowDidResignKeyNotification object:oldWindow];
    }
    if (newWindow) {
        [nc addObserver:self selector:@selector(handleKeyStateChangedNotification:) name:NSWindowDidBecomeKeyNotification object:newWindow];
        [nc addObserver:self selector:@selector(handleKeyStateChangedNotification:) name:NSWindowDidResignKeyNotification object:newWindow];
    }
    
    [super viewWillMoveToWindow:newWindow];
}

- (BOOL)becomeFirstResponder {
    NSTextField *textField = [self subviewOfClass:[NSTextField class]];
    if ([textField isEditable]) {
        [textField selectText:nil];
        [self handleKeyStateChangedNotification:nil];
        return YES;
    }
    
    if ([super becomeFirstResponder]) {
        [self handleKeyStateChangedNotification:nil];
        return YES;
    }
    return NO;
}

- (BOOL)resignFirstResponder {
    if ([super resignFirstResponder]) {
        [self handleKeyStateChangedNotification:nil];
        return YES;
    }
    return NO;
}

#pragma mark Menu validation

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    SEL action = [menuItem action];
    if (action == @selector(changeToolMode:)) {
        [menuItem setState:[self toolMode] == (SKToolMode)[menuItem tag] ? NSOnState : NSOffState];
        return YES;
    } else if (action == @selector(changeAnnotationMode:)) {
        if ([[menuItem menu] numberOfItems] > ANNOTATION_MODE_COUNT)
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
        return [[NSPasteboard generalPasteboard] canReadObjectForClasses:[NSArray arrayWithObjects:[PDFAnnotation class], [NSString class], nil] options:[NSDictionary dictionary]];
    } else if (action == @selector(alternatePaste:)) {
        return [[NSPasteboard generalPasteboard] canReadObjectForClasses:[NSArray arrayWithObjects:[PDFAnnotation class], [NSAttributedString class], [NSString class], nil] options:[NSDictionary dictionary]];
    } else if (action == @selector(pasteAsPlainText:)) {
        return [[NSPasteboard generalPasteboard] canReadObjectForClasses:[NSArray arrayWithObjects:[NSAttributedString class], [NSString class], nil] options:[NSDictionary dictionary]];
    } else if (action == @selector(delete:)) {
        return [activeAnnotation isSkimNote];
    } else if (action == @selector(selectAll:)) {
        return toolMode == SKTextToolMode;
    } else if (action == @selector(deselectAll:)) {
        return [[self currentSelection] hasCharacters] != 0;
    } else if (action == @selector(autoSelectContent:)) {
        return toolMode == SKSelectToolMode;
    } else if (action == @selector(takeSnapshot:)) {
        return [[self document] isLocked] == NO;
    } else {
        return [super validateMenuItem:menuItem];
    }
}

#pragma mark KVO

- (void)setTransitionControllerValue:(id)value forKey:(NSString *)key {
    [transitionController setValue:value forKey:key];
}

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
    } else if (context == &SKPDFViewTransitionsObservationContext) {
        id oldValue = [change objectForKey:NSKeyValueChangeOldKey];
        if ([oldValue isEqual:[NSNull null]]) oldValue = nil;
        [[[self undoManager] prepareWithInvocationTarget:self] setTransitionControllerValue:oldValue forKey:keyPath];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark FullScreen navigation and autohide

- (void)handleWindowWillCloseNotification:(NSNotification *)notification {
    if (editor && [self commitEditing] == NO)
        [self discardEditing];
    [navWindow remove];
}

- (void)enableNavigation {
    navigationMode = [[NSUserDefaults standardUserDefaults] integerForKey:interactionMode == SKPresentationMode ? SKPresentationNavigationOptionKey : SKFullScreenNavigationOptionKey];
    
    // always recreate the navWindow, since moving between screens of different resolution can mess up the location (in spite of moveToScreen:)
    if (navWindow != nil) {
        [navWindow remove];
        [navWindow release];
    } else {
        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(handleWindowWillCloseNotification:) 
                                                     name: NSWindowWillCloseNotification object: [self window]];
    }
    navWindow = [[SKNavigationWindow alloc] initWithPDFView:self];
    
    [self doAutohide:YES];
}

- (void)disableNavigation {
    navigationMode = SKNavigationNone;
    
    [self showNavWindow:NO];
    [self doAutohide:NO];
    [navWindow remove];
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
    if ([navWindow isVisible] == NO && [[self window] mouseLocationOutsideOfEventStream].y < NAVIGATION_BOTTOM_EDGE_HEIGHT) {
        if ([navWindow parentWindow] == nil) {
            [navWindow setAlphaValue:0.0];
            [[self window] addChildWindow:navWindow ordered:NSWindowAbove];
        }
        [navWindow fadeIn];
    }
}

- (void)showNavWindow:(BOOL)flag {
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(showNavWindowDelayed) object:nil];
    if (flag)
        [self performSelector:@selector(showNavWindowDelayed) withObject:nil afterDelay:0.25];
}

#pragma mark Event handling

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
        [activeAnnotation autoUpdateString];
    }
}

- (void)doResizeActiveAnnotationForKey:(unichar)eventChar byAmount:(CGFloat)delta {
    NSRect bounds = [activeAnnotation bounds];
    NSRect newBounds = bounds;
    PDFPage *page = [activeAnnotation page];
    NSRect pageBounds = [page boundsForBox:[self displayBox]];
    
    if ([activeAnnotation isLine]) {
        
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
        
        endPoint.x = floor(endPoint.x);
        endPoint.y = floor(endPoint.y);
        
        if (NSEqualPoints(endPoint, oldEndPoint) == NO) {
            newBounds = SKIntegralRectFromPoints(startPoint, endPoint);
            
            if (NSWidth(newBounds) < MIN_NOTE_SIZE) {
                newBounds.size.width = MIN_NOTE_SIZE;
                newBounds.origin.x = floor(0.5 * ((startPoint.x + endPoint.x) - MIN_NOTE_SIZE));
            }
            if (NSHeight(newBounds) < MIN_NOTE_SIZE) {
                newBounds.size.height = MIN_NOTE_SIZE;
                newBounds.origin.y = floor(0.5 * ((startPoint.y + endPoint.y) - MIN_NOTE_SIZE));
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
                    if (NSWidth(newBounds) < MIN_NOTE_SIZE) {
                        newBounds.size.width = MIN_NOTE_SIZE;
                    }
                } else if (eventChar == NSUpArrowFunctionKey) {
                    newBounds.origin.y += delta;
                    newBounds.size.height -= delta;
                    if (NSHeight(newBounds) < MIN_NOTE_SIZE) {
                        newBounds.origin.y += NSHeight(newBounds) - MIN_NOTE_SIZE;
                        newBounds.size.height = MIN_NOTE_SIZE;
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
                    if (NSHeight(newBounds) < MIN_NOTE_SIZE) {
                        newBounds.size.height = MIN_NOTE_SIZE;
                    }
                } else if (eventChar == NSUpArrowFunctionKey) {
                    newBounds.size.width -= delta;
                    if (NSWidth(newBounds) < MIN_NOTE_SIZE) {
                        newBounds.size.width = MIN_NOTE_SIZE;
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
                    if (NSWidth(newBounds) < MIN_NOTE_SIZE) {
                        newBounds.origin.x += NSWidth(newBounds) - MIN_NOTE_SIZE;
                        newBounds.size.width = MIN_NOTE_SIZE;
                    }
                } else if (eventChar == NSUpArrowFunctionKey) {
                    newBounds.size.height -= delta;
                    if (NSHeight(newBounds) < MIN_NOTE_SIZE) {
                        newBounds.size.height = MIN_NOTE_SIZE;
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
                    if (NSHeight(newBounds) < MIN_NOTE_SIZE) {
                        newBounds.origin.y += NSHeight(newBounds) - MIN_NOTE_SIZE;
                        newBounds.size.height = MIN_NOTE_SIZE;
                    }
                } else if (eventChar == NSUpArrowFunctionKey) {
                    newBounds.origin.x += delta;
                    newBounds.size.width -= delta;
                    if (NSWidth(newBounds) < MIN_NOTE_SIZE) {
                        newBounds.origin.x += NSWidth(newBounds) - MIN_NOTE_SIZE;
                        newBounds.size.width = MIN_NOTE_SIZE;
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
            [activeAnnotation autoUpdateString];
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
            NSRect visibleRect = [self convertRect:[self visibleContentRect] toPage:[readingBar page]];
            rect = NSInsetRect(rect, 0.0, - floor( ( NSHeight(visibleRect) - NSHeight(rect) ) / 2.0 ) );
        }
        [self goToRect:rect onPage:[readingBar page]];
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

- (void)doMoveAnnotationWithEvent:(NSEvent *)theEvent offset:(NSPoint)offset {
    PDFPage *page = [activeAnnotation page];
    NSRect currentBounds = [activeAnnotation bounds];
    
    // Move annotation.
    [[[self scrollView] contentView] autoscroll:theEvent];
    
    NSPoint point = NSZeroPoint;
    PDFPage *newActivePage = [self pageAndPoint:&point forEvent:theEvent nearest:YES];
    
    if (newActivePage) { // newActivePage should never be nil, but just to be sure
        if (newActivePage != page) {
            // move the annotation to the new page
            [self moveAnnotation:activeAnnotation toPage:newActivePage];
            page = newActivePage;
        }
        
        NSRect newBounds = currentBounds;
        newBounds.origin = SKIntegralPoint(SKSubstractPoints(point, offset));
        // constrain bounds inside page bounds
        newBounds = SKConstrainRect(newBounds, [newActivePage  boundsForBox:[self displayBox]]);
        
        // Change annotation's location.
        [activeAnnotation setBounds:newBounds];
    }
}

- (void)doResizeLineAnnotationWithEvent:(NSEvent *)theEvent fromPoint:(NSPoint)originalPagePoint originalStartPoint:(NSPoint)originalStartPoint originalEndPoint:(NSPoint)originalEndPoint resizeHandle:(SKRectEdges)resizeHandle {
    PDFPage *page = [activeAnnotation page];
    NSRect pageBounds = [page  boundsForBox:[self displayBox]];
    NSPoint currentPagePoint = [self convertPoint:[theEvent locationInView:self] toPage:page];
    NSPoint relPoint = SKSubstractPoints(currentPagePoint, originalPagePoint);
    NSPoint endPoint = originalEndPoint;
    NSPoint startPoint = originalStartPoint;
    NSPoint *draggedPoint = (resizeHandle & SKMinXEdgeMask) ? &startPoint : &endPoint;
    
    *draggedPoint = SKConstrainPointInRect(SKAddPoints(*draggedPoint, relPoint), pageBounds);
    draggedPoint->x = floor(draggedPoint->x);
    draggedPoint->y = floor(draggedPoint->y);
    
    if (([theEvent modifierFlags] & NSShiftKeyMask)) {
        NSPoint *fixedPoint = (resizeHandle & SKMinXEdgeMask) ? &endPoint : &startPoint;
        NSPoint diffPoint = SKSubstractPoints(*draggedPoint, *fixedPoint);
        CGFloat dx = fabs(diffPoint.x), dy = fabs(diffPoint.y);
        
        if (dx < 0.4 * dy) {
            diffPoint.x = 0.0;
        } else if (dy < 0.4 * dx) {
            diffPoint.y = 0.0;
        } else {
            dx = fmin(dx, dy);
            diffPoint.x = diffPoint.x < 0.0 ? -dx : dx;
            diffPoint.y = diffPoint.y < 0.0 ? -dx : dx;
        }
        *draggedPoint = SKAddPoints(*fixedPoint, diffPoint);
    }
    
    NSRect newBounds = SKIntegralRectFromPoints(startPoint, endPoint);
    
    if (NSWidth(newBounds) < MIN_NOTE_SIZE) {
        newBounds.size.width = MIN_NOTE_SIZE;
        newBounds.origin.x = floor(0.5 * ((startPoint.x + endPoint.x) - MIN_NOTE_SIZE));
    }
    if (NSHeight(newBounds) < MIN_NOTE_SIZE) {
        newBounds.size.height = MIN_NOTE_SIZE;
        newBounds.origin.y = floor(0.5 * ((startPoint.y + endPoint.y) - MIN_NOTE_SIZE));
    }
    
    [(PDFAnnotationLine *)activeAnnotation setStartPoint:SKSubstractPoints(startPoint, newBounds.origin)];
    [(PDFAnnotationLine *)activeAnnotation setEndPoint:SKSubstractPoints(endPoint, newBounds.origin)];
    [activeAnnotation setBounds:newBounds];
}

- (void)doResizeAnnotationWithEvent:(NSEvent *)theEvent fromPoint:(NSPoint)originalPagePoint originalBounds:(NSRect)originalBounds resizeHandle:(SKRectEdges *)resizeHandlePtr {
    PDFPage *page = [activeAnnotation page];
    NSRect newBounds = originalBounds;
    NSRect pageBounds = [page  boundsForBox:[self displayBox]];
    NSPoint currentPagePoint = [self convertPoint:[theEvent locationInView:self] toPage:page];
    NSPoint relPoint = SKSubstractPoints(currentPagePoint, originalPagePoint);
    SKRectEdges resizeHandle = *resizeHandlePtr;
    
    if (NSEqualSizes(originalBounds.size, NSZeroSize)) {
        SKRectEdges currentResizeHandle = (relPoint.x < 0.0 ? SKMinXEdgeMask : SKMaxXEdgeMask) | (relPoint.y <= 0.0 ? SKMinYEdgeMask : SKMaxYEdgeMask);
        if (currentResizeHandle != resizeHandle) {
            *resizeHandlePtr = resizeHandle = currentResizeHandle;
            [NSCursor pop];
            [[self cursorForResizeHandle:resizeHandle rotation:[page rotation]] push];
        }
    }
    
    if (([theEvent modifierFlags] & NSShiftKeyMask)) {
        CGFloat width = NSWidth(newBounds);
        CGFloat height = NSHeight(newBounds);
        
        if ((resizeHandle & SKMaxXEdgeMask))
            width = fmax(MIN_NOTE_SIZE, width + relPoint.x);
        else if ((resizeHandle & SKMinXEdgeMask))
            width = fmax(MIN_NOTE_SIZE, width - relPoint.x);
        if ((resizeHandle & SKMaxYEdgeMask))
            height = fmax(MIN_NOTE_SIZE, height + relPoint.y);
        else if ((resizeHandle & SKMinYEdgeMask))
            height = fmax(MIN_NOTE_SIZE, height - relPoint.y);
        
        if ((resizeHandle & (SKMinXEdgeMask | SKMaxXEdgeMask)) == 0)
            width = height;
        else if ((resizeHandle & (SKMinYEdgeMask | SKMaxYEdgeMask)) == 0)
            height = width;
        else
            width = height = fmax(width, height);
        
        if ((resizeHandle & SKMinXEdgeMask)) {
            if (NSMaxX(newBounds) - width < NSMinX(pageBounds))
                width = height = fmax(MIN_NOTE_SIZE, NSMaxX(newBounds) - NSMinX(pageBounds));
        } else {
            if (NSMinX(newBounds) + width > NSMaxX(pageBounds))
                width = height = fmax(MIN_NOTE_SIZE, NSMaxX(pageBounds) - NSMinX(newBounds));
        }
        if ((resizeHandle & SKMinYEdgeMask)) {
            if (NSMaxY(newBounds) - height < NSMinY(pageBounds))
                width = height = fmax(MIN_NOTE_SIZE, NSMaxY(newBounds) - NSMinY(pageBounds));
        } else {
            if (NSMinY(newBounds) + height > NSMaxY(pageBounds))
                width = height = fmax(MIN_NOTE_SIZE, NSMaxY(pageBounds) - NSMinY(newBounds));
        }
        
        if ((resizeHandle & SKMinXEdgeMask))
            newBounds.origin.x = NSMaxX(newBounds) - width;
        if ((resizeHandle & SKMinYEdgeMask))
            newBounds.origin.y = NSMaxY(newBounds) - height;
        newBounds.size.width = width;
        newBounds.size.height = height;
       
    } else {
        if ((resizeHandle & SKMaxXEdgeMask)) {
            newBounds.size.width += relPoint.x;
            if (NSMaxX(newBounds) > NSMaxX(pageBounds))
                newBounds.size.width = NSMaxX(pageBounds) - NSMinX(newBounds);
            if (NSWidth(newBounds) < MIN_NOTE_SIZE) {
                newBounds.size.width = MIN_NOTE_SIZE;
            }
        } else if ((resizeHandle & SKMinXEdgeMask)) {
            newBounds.origin.x += relPoint.x;
            newBounds.size.width -= relPoint.x;
            if (NSMinX(newBounds) < NSMinX(pageBounds)) {
                newBounds.size.width = NSMaxX(newBounds) - NSMinX(pageBounds);
                newBounds.origin.x = NSMinX(pageBounds);
            }
            if (NSWidth(newBounds) < MIN_NOTE_SIZE) {
                newBounds.origin.x = NSMaxX(newBounds) - MIN_NOTE_SIZE;
                newBounds.size.width = MIN_NOTE_SIZE;
            }
        }
        if ((resizeHandle & SKMaxYEdgeMask)) {
            newBounds.size.height += relPoint.y;
            if (NSMaxY(newBounds) > NSMaxY(pageBounds)) {
                newBounds.size.height = NSMaxY(pageBounds) - NSMinY(newBounds);
            }
            if (NSHeight(newBounds) < MIN_NOTE_SIZE) {
                newBounds.size.height = MIN_NOTE_SIZE;
            }
        } else if ((resizeHandle & SKMinYEdgeMask)) {
            newBounds.origin.y += relPoint.y;
            newBounds.size.height -= relPoint.y;
            if (NSMinY(newBounds) < NSMinY(pageBounds)) {
                newBounds.size.height = NSMaxY(newBounds) - NSMinY(pageBounds);
                newBounds.origin.y = NSMinY(pageBounds);
            }
            if (NSHeight(newBounds) < MIN_NOTE_SIZE) {
                newBounds.origin.y = NSMaxY(newBounds) - MIN_NOTE_SIZE;
                newBounds.size.height = MIN_NOTE_SIZE;
            }
        }
    }
    
    [activeAnnotation setBounds:NSIntegralRect(newBounds)];
}

- (void)doDragAnnotationWithEvent:(NSEvent *)theEvent {
    // activeAnnotation should be movable, or nil to be added in an appropriate note tool mode
    
    // Old (current) annotation location and click point relative to it
    NSRect originalBounds = [activeAnnotation bounds];
    BOOL isLine = [activeAnnotation isLine];
    NSPoint pagePoint = NSZeroPoint;
    PDFPage *page = [self pageAndPoint:&pagePoint forEvent:theEvent nearest:YES];
    BOOL shouldAddAnnotation = activeAnnotation == nil;
    NSPoint originalStartPoint = NSZeroPoint;
    NSPoint originalEndPoint = NSZeroPoint;
    
    // Hit-test for resize box.
    SKRectEdges resizeHandle = [activeAnnotation resizeHandleForPoint:pagePoint scaleFactor:[self scaleFactor]];
    
    if (shouldAddAnnotation) {
        if (annotationMode == SKAnchoredNote) {
            originalBounds = SKRectFromCenterAndSize(SKIntegralPoint(pagePoint), SKNPDFAnnotationNoteSize);
            [self addAnnotationWithType:SKAnchoredNote contents:nil page:page bounds:originalBounds];
        } else {
            originalBounds = SKRectFromCenterAndSize(SKIntegralPoint(pagePoint), NSZeroSize);
            if (annotationMode == SKLineNote) {
                isLine = YES;
                resizeHandle = SKMaxXEdgeMask;
                originalStartPoint = originalEndPoint = originalBounds.origin;
            } else {
                resizeHandle = SKMaxXEdgeMask | SKMinYEdgeMask;
            }
        }
    } else if (isLine) {
        originalStartPoint = SKIntegralPoint(SKAddPoints([(PDFAnnotationLine *)activeAnnotation startPoint], originalBounds.origin));
        originalEndPoint = SKIntegralPoint(SKAddPoints([(PDFAnnotationLine *)activeAnnotation endPoint], originalBounds.origin));
    }
    
    // we move or resize the annotation in an event loop, which ensures it's enclosed in a single undo group
    BOOL draggedAnnotation = NO;
    NSEvent *lastMouseEvent = theEvent;
    NSPoint offset = SKSubstractPoints(pagePoint, originalBounds.origin);
    NSUInteger eventMask = NSLeftMouseUpMask | NSLeftMouseDraggedMask;
    
    if (resizeHandle == 0) {
        [[NSCursor closedHandCursor] push];
        [NSEvent startPeriodicEventsAfterDelay:0.1 withPeriod:0.1];
        eventMask |= NSPeriodicMask;
    } else {
        [[self cursorForResizeHandle:resizeHandle rotation:[page rotation]] push];
    }
    
    while (YES) {
        theEvent = [[self window] nextEventMatchingMask:eventMask];
        if ([theEvent type] == NSLeftMouseUp) {
            break;
        } else if ([theEvent type] == NSLeftMouseDragged) {
            if (activeAnnotation == nil)
                [self addAnnotationWithType:annotationMode contents:nil page:page bounds:SKRectFromCenterAndSquareSize(originalBounds.origin, MIN_NOTE_SIZE)];
            lastMouseEvent = theEvent;
            draggedAnnotation = YES;
        }
        if (resizeHandle == 0)
            [self doMoveAnnotationWithEvent:lastMouseEvent offset:offset];
        else if (isLine)
            [self doResizeLineAnnotationWithEvent:lastMouseEvent fromPoint:pagePoint originalStartPoint:originalStartPoint originalEndPoint:originalEndPoint resizeHandle:resizeHandle];
        else
            [self doResizeAnnotationWithEvent:lastMouseEvent fromPoint:pagePoint originalBounds:originalBounds resizeHandle:&resizeHandle];
    }
    
    if (resizeHandle == 0)
        [NSEvent stopPeriodicEvents];
    
    if (activeAnnotation) {
        if (draggedAnnotation)
            [activeAnnotation autoUpdateString];
        
        if (shouldAddAnnotation && toolMode == SKNoteToolMode && annotationMode == SKFreeTextNote)
            [self editActiveAnnotation:self]; 	 
        
        [self setNeedsDisplayForAnnotation:activeAnnotation];
    }
    
    [NSCursor pop];
    // ??? PDFView's delayed layout seems to reset the cursor to an arrow
    [[self getCursorForEvent:theEvent] performSelector:@selector(set) withObject:nil afterDelay:0];
}

- (void)doEditActiveAnnotationWithEvent:(NSEvent *)theEvent {
	PDFAnnotation *annotation = activeAnnotation;
    PDFPage *annotationPage = [annotation page];
    NSRect bounds = [annotation bounds];
    BOOL didDrag = NO, isLink = [annotation isLink];
    
    while (YES) {
		theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask];
        
        if ([theEvent type] == NSLeftMouseUp)
            break;
        
        didDrag = YES;
        
        if (isLink) {
            NSPoint point = NSZeroPoint;
            PDFPage *page = [self pageAndPoint:&point forEvent:theEvent nearest:NO];
            if (page == annotationPage && NSPointInRect(point, bounds))
                [self setActiveAnnotation:annotation];
            else
                [self setActiveAnnotation:nil];
        }
	}
    
    if ((didDrag == NO || isLink) && activeAnnotation)
        [self editActiveAnnotation:nil];
}

- (BOOL)doSelectAnnotationWithEvent:(NSEvent *)theEvent {
    PDFAnnotation *newActiveAnnotation = nil;
    NSPoint point = NSZeroPoint;
    PDFPage *page = [self pageAndPoint:&point forEvent:theEvent nearest:YES];
    
    if ([activeAnnotation page] == page && [activeAnnotation isResizable] && [activeAnnotation resizeHandleForPoint:point scaleFactor:[self scaleFactor]] != 0) {
        newActiveAnnotation = activeAnnotation;
    } else {
        
        PDFAnnotation *linkAnnotation = nil;
        BOOL foundCoveringAnnotation = NO;
        
        // Hit test for annotation.
        for (PDFAnnotation *annotation in [[page annotations] reverseObjectEnumerator]) {
            if ([annotation isSkimNote] && [annotation hitTest:point] && [self isEditingAnnotation:annotation] == NO) {
                newActiveAnnotation = annotation;
                break;
            } else if ([annotation shouldDisplay] && NSPointInRect(point, [annotation bounds]) && (toolMode == SKTextToolMode || ANNOTATION_MODE_IS_MARKUP) && linkAnnotation == nil) {
                if ([annotation isLink])
                    linkAnnotation = annotation;
                else
                    foundCoveringAnnotation = YES;
            }
        }
        
        // if we did not find a Skim note, get the first link covered by another annotation to click
        if (newActiveAnnotation == nil && linkAnnotation && foundCoveringAnnotation)
            newActiveAnnotation = linkAnnotation;
    }
    
    if (hideNotes == NO && page != nil && newActiveAnnotation != nil) {
        BOOL isInk = toolMode == SKNoteToolMode && annotationMode == SKInkNote;
        NSUInteger modifiers = [theEvent modifierFlags];
        if ((modifiers & NSAlternateKeyMask) && [newActiveAnnotation isMovable]) {
            // select a new copy of the annotation
            PDFAnnotation *newAnnotation = [[PDFAnnotation alloc] initSkimNoteWithProperties:[newActiveAnnotation SkimNoteProperties]];
            [newAnnotation registerUserName];
            [self addAnnotation:newAnnotation toPage:page];
            [[self undoManager] setActionName:NSLocalizedString(@"Add Note", @"Undo action name")];
            newActiveAnnotation = newAnnotation;
            [newAnnotation release];
        } else if (([newActiveAnnotation isMarkup] || 
                    (isInk && (newActiveAnnotation != activeAnnotation || (modifiers & (NSShiftKeyMask | NSAlphaShiftKeyMask))))) && 
                   [NSApp willDragMouse]) {
            // don't drag markup notes or in freehand tool mode, unless the note was previously selected, so we can select text or draw freehand strokes
            newActiveAnnotation = nil;
        } else if ((modifiers & NSShiftKeyMask) && activeAnnotation != newActiveAnnotation && [[activeAnnotation page] isEqual:[newActiveAnnotation page]] && [[activeAnnotation type] isEqualToString:[newActiveAnnotation type]]) {
            PDFAnnotation *newAnnotation = nil;
            if ([activeAnnotation isMarkup]) {
                NSInteger markupType = [(PDFAnnotationMarkup *)activeAnnotation markupType];
                PDFSelection *sel = [(PDFAnnotationMarkup *)activeAnnotation selection];
                [sel addSelection:[(PDFAnnotationMarkup *)newActiveAnnotation selection]];
                
                newAnnotation = [[[PDFAnnotationMarkup alloc] initSkimNoteWithSelection:sel markupType:markupType] autorelease];
                [newAnnotation setString:[sel cleanedString]];
            } else if ([[activeAnnotation type] isEqualToString:SKNInkString]) {
                NSMutableArray *paths = [[(PDFAnnotationInk *)activeAnnotation pagePaths] mutableCopy];
                [paths addObjectsFromArray:[(PDFAnnotationInk *)newActiveAnnotation pagePaths]];
                
                newAnnotation = [[[PDFAnnotationInk alloc] initSkimNoteWithPaths:paths] autorelease];
                [newAnnotation setString:[activeAnnotation string]];
                [newAnnotation setBorder:[activeAnnotation border]];
                
                [paths release];
            }
            if (newAnnotation) {
                [newAnnotation setColor:[activeAnnotation color]];
                [newAnnotation registerUserName];
                [self removeAnnotation:newActiveAnnotation];
                [self removeActiveAnnotation:nil];
                [self addAnnotation:newAnnotation toPage:page];
                [[self undoManager] setActionName:NSLocalizedString(@"Join Notes", @"Undo action name")];
                newActiveAnnotation = newAnnotation;
            }
        }
    }
    
    if (newActiveAnnotation && newActiveAnnotation != activeAnnotation)
        [self setActiveAnnotation:newActiveAnnotation];
    
    return newActiveAnnotation != nil;
}

- (void)doDrawFreehandNoteWithEvent:(NSEvent *)theEvent {
    NSPoint point = NSZeroPoint;
    PDFPage *page = [self pageAndPoint:&point forEvent:theEvent nearest:YES];
    NSWindow *window = [self window];
    BOOL didDraw = NO;
    BOOL wasMouseCoalescingEnabled = [NSEvent isMouseCoalescingEnabled];
    NSBezierPath *bezierPath = [NSBezierPath bezierPath];
    NSColor *pathColor = nil;
    NSShadow *pathShadow = nil;
    CAShapeLayer *layer = nil;
    NSAffineTransform *transform = nil;
    
    [bezierPath moveToPoint:point];
    [bezierPath setLineCapStyle:NSRoundLineCapStyle];
    [bezierPath setLineJoinStyle:NSRoundLineJoinStyle];
    
    if (([theEvent modifierFlags] & (NSShiftKeyMask | NSAlphaShiftKeyMask)) && [[activeAnnotation type] isEqualToString:SKNInkString] && [[activeAnnotation page] isEqual:page]) {
        pathColor = [activeAnnotation color];
        [bezierPath setLineWidth:[activeAnnotation lineWidth]];
        if ([activeAnnotation borderStyle] == kPDFBorderStyleDashed) {
            [bezierPath setDashPattern:[activeAnnotation dashPattern]];
            [bezierPath setLineCapStyle:NSButtLineCapStyle];
        }
        pathShadow = [[[NSShadow alloc] init] autorelease];
        [pathShadow setShadowBlurRadius:2.0];
        [pathShadow setShadowOffset:NSMakeSize(0.0, -2.0)];
    } else {
        [self setActiveAnnotation:nil];
        NSUserDefaults *sud = [NSUserDefaults standardUserDefaults];
        pathColor = [sud colorForKey:SKInkNoteColorKey];
        [bezierPath setLineWidth:[sud floatForKey:SKInkNoteLineWidthKey]];
        if ((PDFBorderStyle)[sud integerForKey:SKInkNoteLineStyleKey] == kPDFBorderStyleDashed) {
            [bezierPath setDashPattern:[sud arrayForKey:SKInkNoteDashPatternKey]];
            [bezierPath setLineCapStyle:NSButtLineCapStyle];
        }
    }
    
    if ([self wantsLayer]) {
        NSRect boxBounds = NSIntersectionRect([page boundsForBox:[self displayBox]], [self convertRect:[self visibleContentRect] toPage:page]);
        CGAffineTransform t = CGAffineTransformRotate(CGAffineTransformMakeScale([self scaleFactor], [self scaleFactor]), -M_PI_2 * [page rotation] / 90.0);
        layer = [CAShapeLayer layer];
        [layer setStrokeColor:[pathColor CGColor]];
        [layer setFillColor:NULL];
        [layer setLineWidth:[bezierPath lineWidth]];
        [layer setLineDashPattern:[bezierPath dashPattern]];
        [layer setLineCap:[bezierPath lineCapStyle] == NSButtLineCapStyle ? kCALineCapButt : kCALineCapRound];
        [layer setLineJoin:kCALineJoinRound];
        [layer setMasksToBounds:YES];
        if (pathShadow) {
            [layer setShadowRadius:[pathShadow shadowBlurRadius] / [self scaleFactor]];
            [layer setShadowOffset:CGSizeApplyAffineTransform(NSSizeToCGSize([pathShadow shadowOffset]), CGAffineTransformInvert(t))];
            [layer setShadowColor:[[pathShadow shadowColor] CGColor]];
            [layer setShadowOpacity:1.0];
        }
        // transform and place so that the path is in page coordinates
        [layer setBounds:NSRectToCGRect(boxBounds)];
        [layer setAnchorPoint:CGPointZero];
        [layer setPosition:NSPointToCGPoint([self convertPoint:boxBounds.origin fromPage:page])];
        [layer setAffineTransform:t];
        [[self layer] addSublayer:layer];
    } else {
        NSRect rect = [self convertRect:[self convertRect:[page boundsForBox:[self displayBox]] fromPage:page] toView:[self documentView]];
        transform = [NSAffineTransform transform];
        [transform translateXBy:NSMinX(rect) yBy:NSMinY(rect)];
        [transform scaleBy:[self scaleFactor]];
        [transform prependTransform:[page affineTransformForBox:[self displayBox]]];
    }
    
    // don't coalesce mouse event from mouse while drawing, 
    // but not from tablets because those fire very rapidly and lead to serious delays
    if ([NSEvent currentPointingDeviceType] == NSUnknownPointingDevice)
        [NSEvent setMouseCoalescingEnabled:NO];
    
    if (layer == nil) {
        [self displayIfNeeded];
        [window cacheImageInRect:[self convertRect:[self visibleContentRect] toView:nil]];
    }
    
    while (YES) {
        theEvent = [window nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask];
        if ([theEvent type] == NSLeftMouseUp)
            break;
        
        [PDFAnnotationInk addPoint:[self convertPoint:[theEvent locationInView:self] toPage:page] toSkimNotesPath:bezierPath];
        
        if (layer) {
            
            CGPathRef path = SKCopyCGPathFromBezierPath(bezierPath);
            [layer setPath:path];
            CGPathRelease(path);
            
        } else {
        
            [window restoreCachedImage];
            
            if ([[self documentView] lockFocusIfCanDraw]) {
                [NSGraphicsContext saveGraphicsState];
                [[NSGraphicsContext currentContext] setShouldAntialias:[self shouldAntiAlias]];
                [transform concat];
                [pathColor setStroke];
                [pathShadow set];
                [bezierPath stroke];
                [NSGraphicsContext restoreGraphicsState];
                [[self documentView] unlockFocus];
            }
            [window flushWindow];
            
        }
        
        didDraw = YES;
    }
    
    if (layer)
        [layer removeFromSuperlayer];
    else
        [window discardCachedImage];
    
    [NSEvent setMouseCoalescingEnabled:wasMouseCoalescingEnabled];
    
    if (didDraw) {
        NSMutableArray *paths = [[NSMutableArray alloc] init];
        if (activeAnnotation)
            [paths addObjectsFromArray:[(PDFAnnotationInk *)activeAnnotation pagePaths]];
        [paths addObject:bezierPath];
        
        PDFAnnotationInk *annotation = [[PDFAnnotationInk alloc] initSkimNoteWithPaths:paths];
        if (activeAnnotation) {
            [annotation setColor:pathColor];
            [annotation setBorder:[activeAnnotation border]];
            [annotation setString:[activeAnnotation string]];
        }
        [annotation registerUserName]; 
        [self addAnnotation:annotation toPage:page];
        [[self undoManager] setActionName:NSLocalizedString(@"Add Note", @"Undo action name")];
        
        [paths release];
        [annotation release];
        
        if (activeAnnotation) {
            [self removeActiveAnnotation:nil];
            [self setActiveAnnotation:annotation];
        } else if (([theEvent modifierFlags] & (NSShiftKeyMask | NSAlphaShiftKeyMask))) {
            [self setActiveAnnotation:annotation];
        }
    } else if (([theEvent modifierFlags] & NSAlphaShiftKeyMask)) {
        [self setActiveAnnotation:nil];
    }
    
}

- (void)doEraseAnnotationsWithEvent:(NSEvent *)theEvent {
    while (YES) {
        theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask];
        if ([theEvent type] == NSLeftMouseUp)
            break;
        
        NSPoint point = NSZeroPoint;
        PDFPage *page = [self pageAndPoint:&point forEvent:theEvent nearest:YES];
        NSArray *annotations = [page annotations];
        NSInteger i = [annotations count];
        
        while (i-- > 0) {
            PDFAnnotation *annotation = [annotations objectAtIndex:i];
            if ([annotation isSkimNote] && [annotation hitTest:point] && [self isEditingAnnotation:annotation] == NO) {
                [self removeAnnotation:annotation];
                [[self undoManager] setActionName:NSLocalizedString(@"Remove Note", @"Undo action name")];
                break;
            }
        }
    }
}

- (void)doDragWithEvent:(NSEvent *)theEvent {
	NSPoint initialLocation = [theEvent locationInWindow];
    NSView *documentView = [[self scrollView] documentView];
	NSRect visibleRect = [documentView visibleRect];
	
    [[NSCursor closedHandCursor] push];
    
	while (YES) {
        
		theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask];
        if ([theEvent type] == NSLeftMouseUp)
            break;
        
        // convert takes flipping and scaling into account
        NSPoint	startLocation = [documentView convertPoint:initialLocation fromView:nil];
        NSPoint	newLocation = [documentView convertPoint:[theEvent locationInWindow] fromView:nil];
        NSPoint	delta = SKSubstractPoints(startLocation, newLocation);
        
        [documentView scrollRectToVisible:NSOffsetRect(visibleRect, delta.x, delta.y)];
	}
    
    [NSCursor pop];
    // ??? PDFView's delayed layout seems to reset the cursor to an arrow
    [[self getCursorForEvent:theEvent] performSelector:@selector(set) withObject:nil afterDelay:0];
}

- (void)doSelectWithEvent:(NSEvent *)theEvent {
    NSPoint initialPoint = NSZeroPoint;
    PDFPage *page = [self pageAndPoint:&initialPoint forEvent:theEvent nearest:NO];
    if (page == nil) {
        // should never get here, see mouseDown:
        [self doNothingWithEvent:theEvent];
        return;
    }
    
    CGFloat margin = HANDLE_SIZE / [self scaleFactor];
    
    if (selectionPageIndex != NSNotFound && [page pageIndex] != selectionPageIndex) {
        [self setNeedsDisplayInRect:NSInsetRect(selectionRect, -margin, -margin) ofPage:[self currentSelectionPage]];
        [self setNeedsDisplayInRect:NSInsetRect(selectionRect, -margin, -margin) ofPage:page];
    }
    
    selectionPageIndex = [page pageIndex];
    
    BOOL didSelect = (NO == NSIsEmptyRect(selectionRect));
    
    SKRectEdges resizeHandle = didSelect ? SKResizeHandleForPointFromRect(initialPoint, selectionRect, margin) : 0;
    
    if (resizeHandle == 0 && (didSelect == NO || NSPointInRect(initialPoint, selectionRect) == NO)) {
        selectionRect.origin = initialPoint;
        selectionRect.size = NSZeroSize;
        resizeHandle = SKMaxXEdgeMask | SKMinYEdgeMask;
        if (didSelect)
            [self setNeedsDisplay:YES];
    }
    
	NSRect initialRect = selectionRect;
    NSRect pageBounds = [page boundsForBox:[self displayBox]];
    SKRectEdges newEffectiveResizeHandle, effectiveResizeHandle = resizeHandle;
    
    if (resizeHandle == 0)
        [[NSCursor closedHandCursor] push];
    else
        [[self cursorForResizeHandle:resizeHandle rotation:[page rotation]] push];
    
	while (YES) {
        
		theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask];
        if ([theEvent type] == NSLeftMouseUp)
            break;
		
        // we must be dragging
        NSPoint	newPoint;
        NSRect	newRect = initialRect;
        NSPoint delta;
        
        newPoint = [self convertPoint:[theEvent locationInView:self] toPage:page];
        delta = SKSubstractPoints(newPoint, initialPoint);
        
        if (resizeHandle) {
            newEffectiveResizeHandle = 0;
            if ((resizeHandle & SKMaxXEdgeMask))
                newEffectiveResizeHandle |= newPoint.x < NSMinX(initialRect) ? SKMinXEdgeMask : SKMaxXEdgeMask;
            else if ((resizeHandle & SKMinXEdgeMask))
                newEffectiveResizeHandle |= newPoint.x > NSMaxX(initialRect) ? SKMaxXEdgeMask : SKMinXEdgeMask;
            if ((resizeHandle & SKMaxYEdgeMask))
                newEffectiveResizeHandle |= newPoint.y < NSMinY(initialRect) ? SKMinYEdgeMask : SKMaxYEdgeMask;
            else if ((resizeHandle & SKMinYEdgeMask))
                newEffectiveResizeHandle |= newPoint.y > NSMaxY(initialRect) ? SKMaxYEdgeMask : SKMinYEdgeMask;
            if (newEffectiveResizeHandle != effectiveResizeHandle) {
                effectiveResizeHandle = newEffectiveResizeHandle;
                [NSCursor pop];
                [[self cursorForResizeHandle:effectiveResizeHandle rotation:[page rotation]] push];
            }
        }
        
        if (resizeHandle == 0) {
            newRect.origin = SKAddPoints(newRect.origin, delta);
        } else if (([theEvent modifierFlags] & NSShiftKeyMask)) {
            CGFloat width = NSWidth(newRect);
            CGFloat height = NSHeight(newRect);
            CGFloat square;
            
            if ((resizeHandle & SKMaxXEdgeMask))
                width += delta.x;
            else if ((resizeHandle & SKMinXEdgeMask))
                width -= delta.x;
            if ((resizeHandle & SKMaxYEdgeMask))
                height += delta.y;
            else if ((resizeHandle & SKMinYEdgeMask))
                height -= delta.y;
            
            if (0 == (resizeHandle & (SKMinXEdgeMask | SKMaxXEdgeMask)))
                square = fabs(height);
            else if (0 == (resizeHandle & (SKMinYEdgeMask | SKMaxYEdgeMask)))
                square = fabs(width);
            else
                square = fmax(fabs(width), fabs(height));
            
            if ((resizeHandle & SKMinXEdgeMask)) {
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
            if ((resizeHandle & SKMinYEdgeMask)) {
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
            
            if ((resizeHandle & SKMinXEdgeMask))
                newRect.origin.x = width < 0.0 ? NSMaxX(newRect) : NSMaxX(newRect) - square;
            else if (width < 0.0 && (resizeHandle & SKMaxXEdgeMask))
                newRect.origin.x = NSMinX(newRect) - square;
            if ((resizeHandle & SKMinYEdgeMask))
                newRect.origin.y = height < 0.0 ? NSMaxY(newRect) : NSMaxY(newRect) - square;
            else if (height < 0.0 && (resizeHandle & SKMaxYEdgeMask))
                newRect.origin.y = NSMinY(newRect) - square;
            newRect.size.width = newRect.size.height = square;
        } else {
            if ((resizeHandle & SKMaxXEdgeMask)) {
                newRect.size.width += delta.x;
                if (NSWidth(newRect) < 0.0) {
                    newRect.size.width *= -1.0;
                    newRect.origin.x -= NSWidth(newRect);
                }
            } else if ((resizeHandle & SKMinXEdgeMask)) {
                newRect.origin.x += delta.x;
                newRect.size.width -= delta.x;
                if (NSWidth(newRect) < 0.0) {
                    newRect.size.width *= -1.0;
                    newRect.origin.x -= NSWidth(newRect);
                }
            }
            
            if ((resizeHandle & SKMaxYEdgeMask)) {
                newRect.size.height += delta.y;
                if (NSHeight(newRect) < 0.0) {
                    newRect.size.height *= -1.0;
                    newRect.origin.y -= NSHeight(newRect);
                }
            } else if ((resizeHandle & SKMinYEdgeMask)) {
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
            for (PDFPage *p in [self visiblePages])
                [self setNeedsDisplayInRect:dirtyRect ofPage:p];
        } else {
            [self setNeedsDisplay:YES];
            didSelect = YES;
        }
        selectionRect = newRect;
        [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewSelectionChangedNotification object:self];
	}
    
    if (NSIsEmptyRect(selectionRect)) {
        selectionRect = NSZeroRect;
        selectionPageIndex = NSNotFound;
        [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewSelectionChangedNotification object:self];
        [self setNeedsDisplay:YES];
    } else if (resizeHandle) {
        [self setNeedsDisplayInRect:NSInsetRect(selectionRect, -margin, -margin) ofPage:page];
    }
    
    [NSCursor pop];
    // ??? PDFView's delayed layout seems to reset the cursor to an arrow
    [[self getCursorForEvent:theEvent] performSelector:@selector(set) withObject:nil afterDelay:0];
}

- (void)doDragReadingBarWithEvent:(NSEvent *)theEvent {
    PDFPage *page = [readingBar page];
    NSPointerArray *lineRects = [page lineRects];
	NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:page, SKPDFViewOldPageKey, nil];
    
    NSEvent *lastMouseEvent = theEvent;
    NSPoint lastMouseLoc = [theEvent locationInView:self];
    NSPoint point = [self convertPoint:lastMouseLoc toPage:page];
    NSInteger lineOffset = SKIndexOfRectAtYInOrderedRects(point.y, lineRects, YES) - [readingBar currentLine];
    NSDate *lastPageChangeDate = [NSDate distantPast];
    
    lastMouseLoc = [self convertPoint:lastMouseLoc toView:[self documentView]];
    
    [[NSCursor closedHandBarCursor] push];
    
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
        if ([[[self scrollView] contentView] autoscroll:lastMouseEvent] == NO &&
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
    NSPointerArray *lineRects = [page lineRects];
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:page, SKPDFViewOldPageKey, page, SKPDFViewNewPageKey, nil];
    
    [[NSCursor resizeUpDownCursor] push];
    
	while (YES) {
		
        theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask];
		if ([theEvent type] == NSLeftMouseUp)
            break;
        
        // dragging
        NSPoint point = NSZeroPoint;
        if ([[self pageAndPoint:&point forEvent:theEvent nearest:YES] isEqual:page] == NO)
            continue;
        
        NSInteger numberOfLines = MAX(0, SKIndexOfRectAtYInOrderedRects(point.y, lineRects, YES)) - firstLine + 1;
        
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
    CAShapeLayer *layer = nil;
    
    [[NSCursor cameraCursor] set];
	
    if ([self wantsLayer]) {
        CGRect rect = NSRectToCGRect([self visibleContentRect]);
        layer = [CAShapeLayer layer];
        [layer setStrokeColor:CGColorGetConstantColor(kCGColorBlack)];
        [layer setFillColor:NULL];
        [layer setLineWidth:1.0];
        [layer setFrame:rect];
        [layer setBounds:rect];
        [layer setMasksToBounds:YES];
        [[self layer] addSublayer:layer];
    } else {
        [[self window] discardCachedImage];
    }
    
	while (YES) {
		theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSFlagsChangedMask];
        
        if (layer == nil) {
            [[self window] disableFlushWindow];
            [[self window] restoreCachedImage];
		}
        
        if ([theEvent type] == NSLeftMouseUp) {
            if (layer == nil) {
                [[self window] enableFlushWindow];
                [[self window] flushWindow];
            }
            break;
        }
        
        if ([theEvent type] == NSLeftMouseDragged) {
            // change mouseLoc
            [[[self scrollView] contentView] autoscroll:theEvent];
            mouseLoc = [theEvent locationInWindow];
            dragged = YES;
        }
        
        // dragging or flags changed
        
        currentPoint = [[self documentView] convertPoint:mouseLoc fromView:nil];
        
        // center around startPoint when holding down the Shift key
        if (([theEvent modifierFlags] & NSShiftKeyMask))
            selRect = SKRectFromCenterAndPoint(startPoint, currentPoint);
        else
            selRect = SKRectFromPoints(startPoint, currentPoint);
        
        // intersect with the bounds, project on the bounds if necessary and allow zero width or height
        selRect = SKIntersectionRect(selRect, [[self documentView] bounds]);
        
        if (layer) {
            
            CGMutablePathRef path = CGPathCreateMutable();
            CGPathAddRect(path, NULL, NSRectToCGRect(NSInsetRect(NSIntegralRect([self convertRect:selRect fromView:[self documentView]]), 0.5, 0.5)));
            [layer setPath:path];
            CGPathRelease(path);
            
        } else {
            
            [[self window] cacheImageInRect:NSInsetRect([[self documentView] convertRect:selRect toView:nil], -2.0, -2.0)];
            
            if ([[self documentView] lockFocusIfCanDraw]) {;
                [[NSColor blackColor] set];
                [NSBezierPath setDefaultLineWidth:1.0];
                [NSBezierPath strokeRect:NSInsetRect(NSIntegralRect(selRect), 0.5, 0.5)];
                [[self documentView] unlockFocus];
            }
            [[self window] enableFlushWindow];
            [[self window] flushWindow];
            
        }
    }
    
    if (layer)
        [layer removeFromSuperlayer];
    else
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
        
        PDFAnnotation *annotation = [page annotationAtPoint:[self convertPoint:point toPage:page]];
        if ([annotation isLink]) {
            PDFDestination *destination = [annotation destination];
            if ([destination page]) {
                page = [destination page];
                point = [self convertPoint:[destination point] fromPage:page];
                point.y -= 0.5 * DEFAULT_SNAPSHOT_HEIGHT;
            }
        }
        
        rect = [self convertRect:[page boundsForBox:kPDFDisplayBoxCropBox] fromPage:page];
        rect.origin.y = point.y - 0.5 * DEFAULT_SNAPSHOT_HEIGHT;
        rect.size.height = DEFAULT_SNAPSHOT_HEIGHT;
        
    }
    
    if ([[self delegate] respondsToSelector:@selector(PDFView:showSnapshotAtPageNumber:forRect:scaleFactor:autoFits:)])
        [[self delegate] PDFView:self showSnapshotAtPageNumber:[page pageIndex] forRect:[self convertRect:rect toPage:page] scaleFactor:[self scaleFactor] * factor autoFits:autoFits];
}

- (void)doMagnifyWithEvent:(NSEvent *)theEvent {
	NSPoint mouseLoc = [theEvent locationInWindow];
	NSEvent *lastMouseEvent = [theEvent retain];
    NSScrollView *scrollView = [self scrollView];
    NSView *documentView = [scrollView documentView];
    NSWindow *window = [self window];
	NSRect originalBounds = [documentView bounds];
    NSRect visibleRect = [self convertRect:[self visibleContentRect] toView: nil];
    NSRect magRect;
    NSInteger mouseInside = -1;
	NSInteger currentLevel = 0;
    NSInteger originalLevel = [theEvent clickCount]; // this should be at least 1
	BOOL postNotification = [documentView postsBoundsChangedNotifications];
    NSUserDefaults *sud = [NSUserDefaults standardUserDefaults];
    NSSize smallSize = NSMakeSize([sud floatForKey:SKSmallMagnificationWidthKey], [sud floatForKey:SKSmallMagnificationHeightKey]);
    NSSize largeSize = NSMakeSize([sud floatForKey:SKLargeMagnificationWidthKey], [sud floatForKey:SKLargeMagnificationHeightKey]);
    NSRect smallMagRect = SKRectFromCenterAndSize(NSZeroPoint, smallSize);
    NSRect largeMagRect = SKRectFromCenterAndSize(NSZeroPoint, largeSize);
    CALayer *loupeLayer = nil;
    NSAutoreleasePool *pool = nil;
    NSColor *borderColor = [NSColor colorWithCalibratedWhite:0.2 alpha:1.0];
    NSColor *backgroundColor = [self backgroundColor];
    NSShadow *aShadow = nil;
    
    if ([backgroundColor alphaComponent] < 1.0)
        backgroundColor = [[NSColor blackColor] blendedColorWithFraction:[backgroundColor alphaComponent] ofColor:[backgroundColor colorWithAlphaComponent:1.0]];
    
    if ([self wantsLayer]) {
        
        loupeLayer = [CALayer layer];
        [loupeLayer setBackgroundColor:[backgroundColor CGColor]];
        [loupeLayer setBorderColor:[borderColor CGColor]];
        [loupeLayer setBorderWidth:3.0];
        [loupeLayer setCornerRadius:16.0];
        [loupeLayer setActions:[NSDictionary dictionaryWithObjectsAndKeys:
                                [NSNull null], @"contents",
                                [NSNull null], @"position",
                                [NSNull null], @"bounds",
                                [NSNull null], @"hidden",
                                nil]];
        [loupeLayer setShadowRadius:4.0];
        [loupeLayer setShadowOffset:CGSizeMake(0.0, -2.0)];
        [loupeLayer setShadowOpacity:0.5];
        [loupeLayer setHidden:YES];
        [[self layer] addSublayer:loupeLayer];
        
        if ([self displaysPageBreaks]) {
            aShadow = [[[NSShadow alloc] init] autorelease];
            [aShadow setShadowColor:[NSColor blackColor]];
        }
        
    } else {
        
        [documentView setPostsBoundsChangedNotifications:NO];
        
        [window discardCachedImage]; // make sure not to use the cached image
        
        aShadow = [[[NSShadow alloc] init] autorelease];
        [aShadow setShadowBlurRadius:4.0];
        [aShadow setShadowOffset:NSMakeSize(0.0, -2.0)];
        [aShadow setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.5]];
        
    }
    
    [theEvent retain];
    while ([theEvent type] != NSLeftMouseUp) {
        
        pool = [[NSAutoreleasePool alloc] init];
        
        if ([theEvent type] == NSLeftMouseDown || [theEvent type] == NSFlagsChanged) {	
            // set up the currentLevel and magnification
            NSUInteger modifierFlags = [theEvent modifierFlags];
            currentLevel = originalLevel + ((modifierFlags & NSAlternateKeyMask) ? 1 : 0);
            magnification = (modifierFlags & NSCommandKeyMask) ? LARGE_MAGNIFICATION : (modifierFlags & NSControlKeyMask) ? SMALL_MAGNIFICATION : DEFAULT_MAGNIFICATION;
            if ((modifierFlags & NSShiftKeyMask)) {
                magnification = 1.0 / magnification;
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewMagnificationChangedNotification object:self];
            [[self getCursorForEvent:theEvent] set];
            if (loupeLayer) {
                [aShadow setShadowBlurRadius:4.0 * magnification];
                [aShadow setShadowOffset:NSMakeSize(0.0, -4.0 * magnification)];
            } else {
                [window displayIfNeeded];
                if (currentLevel > 2) {
                    [window restoreCachedImage];
                    [window cacheImageInRect:visibleRect];
                }
            }
        } else if ([theEvent type] == NSLeftMouseDragged) {
            // get Mouse location and check if it is with the view's rect
            mouseLoc = [theEvent locationInWindow];
            [lastMouseEvent release];
            lastMouseEvent = [theEvent retain];
        }
        
        if ([self mouse:mouseLoc inRect:visibleRect]) {
            
            if (mouseInside != 1) {
                // stop periodic events for auto scrolling
                if (mouseInside == 0)
                    [NSEvent stopPeriodicEvents];
                mouseInside = 1;
                [NSCursor hide];
                if (loupeLayer) {
                    [loupeLayer setHidden:NO];
                } else {
                    // make sure we flush the complete drawing to avoid flickering
                    [window disableFlushWindow];
                }
            }
            
            // define rect for magnification in window coordinate
            if (currentLevel > 2) { 
                magRect = visibleRect;
            } else {
                magRect = currentLevel == 2 ? largeMagRect : smallMagRect;
                magRect.origin = SKAddPoints(magRect.origin, mouseLoc);
                magRect = NSIntegralRect(magRect);
                // restore the cached image in order to clear the rect
                [window restoreCachedImage];
                [window cacheImageInRect:NSIntersectionRect(NSInsetRect(magRect, -8.0, -8.0), visibleRect)];
            }
            
            if (loupeLayer) {
                magRect = [self convertRect:magRect fromView:nil];
                
                NSPoint mouseLocSelf = [self convertPoint:mouseLoc fromView:nil];
                NSRect imageRect = {NSZeroPoint, magRect.size};
                NSImage *image = [[NSImage alloc] initWithSize:imageRect.size];
                NSAffineTransform *transform = [NSAffineTransform transform];
                NSArray *pages = magnification < 1.0 ? [self displayedPages] : [self visiblePages];
                
                [transform translateXBy:mouseLocSelf.x - NSMinX(magRect) yBy:mouseLocSelf.y - NSMinY(magRect)];
                [transform scaleBy:magnification];
                [transform translateXBy:-mouseLocSelf.x yBy:-mouseLocSelf.y];
                
                [image lockFocus];
                
                [[NSBezierPath bezierPathWithRoundedRect:imageRect xRadius:loupeLayer.cornerRadius yRadius:loupeLayer.cornerRadius] setClip];
                
                if (aShadow)
                    imageRect = NSOffsetRect(NSInsetRect(imageRect, -[aShadow shadowBlurRadius], -[aShadow shadowBlurRadius]), -[aShadow shadowOffset].width, -[aShadow shadowOffset].height);
                
                for (PDFPage *page in pages) {
                    NSRect pageRect = [self convertRect:[page boundsForBox:[self displayBox]] fromPage:page];
                    NSPoint pageOrigin = pageRect.origin;
                    NSAffineTransform *pageTransform;
                    
                    pageRect = SKRectFromPoints([transform transformPoint:SKBottomLeftPoint(pageRect)], [transform transformPoint:SKTopRightPoint(pageRect)]);
                    
                    // only draw the page when there is something to draw
                    if (NSIntersectsRect(imageRect, pageRect) == NO)
                        continue;
                    
                    // draw page background, simulate the private method -drawPagePre:
                    [NSGraphicsContext saveGraphicsState];
                    [[NSColor whiteColor] set];
                    [aShadow set];
                    NSRectFill(SKIntegralRect(pageRect));
                    [NSGraphicsContext restoreGraphicsState];
                    
                    // draw page contents
                    [NSGraphicsContext saveGraphicsState];
                    pageTransform = [transform copy];
                    [pageTransform translateXBy:pageOrigin.x yBy:pageOrigin.y];
                    [pageTransform scaleBy:[self scaleFactor]];
                    [pageTransform concat];
                    [pageTransform release];
                    [[NSGraphicsContext currentContext] setShouldAntialias:[self shouldAntiAlias]];
                    [self drawPage:page];
                    [NSGraphicsContext restoreGraphicsState];
                }
                [image unlockFocus];
                
                [loupeLayer setContents:image];
                [loupeLayer setFrame:NSRectToCGRect(magRect)];
                [image release];
                
            } else {
                
                NSRect magBounds, outlineRect;
                NSBezierPath *path;
                
                // resize bounds around mouseLoc
                magBounds.origin = [documentView convertPoint:mouseLoc fromView:nil];
                magBounds = NSMakeRect(NSMinX(magBounds) + (NSMinX(originalBounds) - NSMinX(magBounds)) / magnification, 
                                       NSMinY(magBounds) + (NSMinY(originalBounds) - NSMinY(magBounds)) / magnification, 
                                       NSWidth(originalBounds) / magnification, NSHeight(originalBounds) / magnification);
                
                outlineRect = [documentView convertRect:magRect fromView:nil];
                if ([documentView lockFocusIfCanDraw]) {
                    [aShadow set];
                    [backgroundColor set];
                    path = [NSBezierPath bezierPathWithRoundedRect:outlineRect xRadius:9.5 yRadius:9.5];
                    [path fill];
                    [documentView unlockFocus];
                }
                
                if ([documentView canDraw]) {
                    [documentView setBounds:magBounds];
                    [self displayRect:[self convertRect:NSInsetRect(magRect, 3.0, 3.0) fromView:nil]]; // this flushes the buffer
                    [documentView setBounds:originalBounds];
                }
                
                outlineRect = NSInsetRect(outlineRect, 1.5, 1.5);
                if ([documentView lockFocusIfCanDraw]) {
                    [borderColor set];
                    path = [NSBezierPath bezierPathWithRoundedRect:outlineRect xRadius:8.0 yRadius:8.0];
                    [path setLineWidth:3.0];
                    [path stroke];
                    [documentView unlockFocus];
                }
                
                [window enableFlushWindow];
                [window flushWindowIfNeeded];
                [window disableFlushWindow];
                
            }
            
        } else { // mouse is not in the rect
            
            // show cursor 
            if (mouseInside == 1) {
                mouseInside = 0;
                [NSCursor unhide];
                // start periodic events for auto scrolling
                [NSEvent startPeriodicEventsAfterDelay:0.1 withPeriod:0.1];
                if (loupeLayer) {
                    [loupeLayer setHidden:YES];
                } else {
                    // restore the cached image in order to clear the rect
                    [window restoreCachedImage];
                    [window enableFlushWindow];
                    [window flushWindowIfNeeded];
                }
            }
            if ([theEvent type] == NSLeftMouseDragged || [theEvent type] == NSPeriodic)
                [documentView autoscroll:lastMouseEvent];
            if (loupeLayer == nil) {
                if (currentLevel > 2)
                    [window cacheImageInRect:visibleRect];
                else
                    [window discardCachedImage];
            }
            
        }
        
        [theEvent release];
        theEvent = [[window nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSFlagsChangedMask | NSPeriodicMask] retain];
        
        [pool drain];
        pool = nil;
	}
    
    if (mouseInside == 1)
        [NSEvent stopPeriodicEvents];
    
    magnification = 0.0;
    [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewMagnificationChangedNotification object:self];
	
    if (loupeLayer) {
        [loupeLayer removeFromSuperlayer];
    } else {
        [window restoreCachedImage];
        if (mouseInside == 1)
            [window enableFlushWindow];
        [window flushWindowIfNeeded];
        [documentView setPostsBoundsChangedNotifications:postNotification];
	}
    
    [NSCursor unhide];
    // ??? PDFView's delayed layout seems to reset the cursor to an arrow
    [[self getCursorForEvent:theEvent] performSelector:@selector(set) withObject:nil afterDelay:0];
    [theEvent release];
    [lastMouseEvent release];
}

- (void)doNothingWithEvent:(NSEvent *)theEvent {
    // eat up mouseDragged/mouseUp events, so we won't get their event handlers
    while (YES) {
        if ([[[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask] type] == NSLeftMouseUp)
            break;
    }
}

- (NSCursor *)cursorForNoteToolMode {
    if (useToolModeCursors) {
        switch (annotationMode) {
            case SKFreeTextNote:  return [NSCursor textNoteCursor];
            case SKAnchoredNote:  return [NSCursor anchoredNoteCursor];
            case SKCircleNote:    return [NSCursor circleNoteCursor];
            case SKSquareNote:    return [NSCursor squareNoteCursor];
            case SKHighlightNote: return [NSCursor highlightNoteCursor];
            case SKUnderlineNote: return [NSCursor underlineNoteCursor];
            case SKStrikeOutNote: return [NSCursor strikeOutNoteCursor];
            case SKLineNote:      return [NSCursor lineNoteCursor];
            case SKInkNote:       return [NSCursor inkNoteCursor];
            default:              return [NSCursor arrowCursor];
        }
    }
    return [NSCursor arrowCursor];
}

- (NSCursor *)cursorForResizeHandle:(SKRectEdges)mask rotation:(NSInteger)rotation {
    BOOL rotated = (rotation % 180 != 0);
    switch (mask) {
        case SKMaxXEdgeMask:
        case SKMinXEdgeMask:
            return rotated ? [NSCursor resizeUpDownCursor] : [NSCursor resizeLeftRightCursor];
        case SKMaxXEdgeMask | SKMaxYEdgeMask:
        case SKMinXEdgeMask | SKMinYEdgeMask:
            return rotated ? [NSCursor resizeDiagonal135Cursor] : [NSCursor resizeDiagonal45Cursor];
        case SKMaxYEdgeMask:
        case SKMinYEdgeMask:
            return rotated ? [NSCursor resizeLeftRightCursor] : [NSCursor resizeUpDownCursor];
        case SKMaxXEdgeMask | SKMinYEdgeMask:
        case SKMinXEdgeMask | SKMaxYEdgeMask:
            return rotated ? [NSCursor resizeDiagonal45Cursor] : [NSCursor resizeDiagonal135Cursor];
        default:
            return nil;
    }
}

- (NSCursor *)getCursorForEvent:(NSEvent *)theEvent {
    NSPoint p = [theEvent locationInView:self];
    NSCursor *cursor = nil;
    
    if ([[self document] isLocked]) {
    } else if (interactionMode == SKPresentationMode) {
        if (([self areaOfInterestForMouse:theEvent] & kPDFLinkArea))
            cursor = [NSCursor pointingHandCursor];
        else
            cursor = [NSCursor arrowCursor];
    } else if (NSMouseInRect(p, [self visibleContentRect], [self isFlipped]) == NO || ([navWindow isVisible] && NSPointInRect([[self window] convertBaseToScreen:[theEvent locationInWindow]], [navWindow frame]))) {
        cursor = [NSCursor arrowCursor];
    } else if (([theEvent modifierFlags] & NSCommandKeyMask)) {
        cursor = [NSCursor arrowCursor];
    } else {
        PDFAreaOfInterest area = [self extendedAreaOfInterestForMouse:theEvent];
        PDFPage *page = [self pageForPoint:p nearest:YES];
        p = [self convertPoint:p toPage:page];
        SKRectEdges resizeHandle;
        
        switch (toolMode) {
            case SKTextToolMode:
            case SKNoteToolMode:
            {
                BOOL isOnActiveAnnotationPage = [[activeAnnotation page] isEqual:page];
                
                if ((area & kPDFLinkArea) == 0 && (area & SKReadingBarArea))
                    cursor = (area & SKReadingBarResizeArea) ? [NSCursor resizeUpDownCursor] : [NSCursor openHandBarCursor];
                else if (editor && isOnActiveAnnotationPage && NSPointInRect(p, [activeAnnotation bounds]))
                    cursor = [NSCursor IBeamCursor];
                else if (isOnActiveAnnotationPage && [activeAnnotation isResizable] && (resizeHandle = [activeAnnotation resizeHandleForPoint:p scaleFactor:[self scaleFactor]]) != 0)
                    cursor = [self cursorForResizeHandle:resizeHandle rotation:[page rotation]];
                else if (isOnActiveAnnotationPage && [activeAnnotation isMovable] && [activeAnnotation hitTest:p])
                    cursor = [NSCursor openHandCursor];
                else if ((area & kPDFPageArea) == 0 || ((toolMode == SKTextToolMode || hideNotes || ANNOTATION_MODE_IS_MARKUP) && area == kPDFPageArea && [theEvent standardModifierFlags] == 0 && [self hasTextNearMouse:theEvent] == NO))
                    cursor = [NSCursor openHandCursor];
                else if (toolMode == SKNoteToolMode)
                    cursor = [self cursorForNoteToolMode];
                break;
            }
            case SKMoveToolMode:
                if ((area & kPDFLinkArea))
                    cursor = [NSCursor pointingHandCursor];
                else if ((area == SKReadingBarArea) == 0)
                    cursor = [NSCursor openHandCursor];
                else if ((area & SKReadingBarResizeArea))
                    cursor = [NSCursor resizeUpDownCursor];
                else
                    cursor = [NSCursor openHandBarCursor];
                break;
            case SKSelectToolMode:
                if ((area & kPDFPageArea) == 0) {
                    if ((area == SKReadingBarArea) == 0)
                        cursor = [NSCursor openHandCursor];
                    else if ((area & SKReadingBarResizeArea))
                        cursor = [NSCursor resizeUpDownCursor];
                    else
                        cursor = [NSCursor openHandBarCursor];
                } else {
                    resizeHandle = SKResizeHandleForPointFromRect(p, selectionRect, HANDLE_SIZE / [self scaleFactor]);
                    cursor = [self cursorForResizeHandle:resizeHandle rotation:[page rotation]];
                    if (cursor == nil)
                        cursor = NSPointInRect(p, selectionRect) ? [NSCursor openHandCursor] : [NSCursor crosshairCursor];
                }
                break;
            case SKMagnifyToolMode:
                if ((area & kPDFPageArea) == 0) {
                    if ((area == SKReadingBarArea) == 0)
                        cursor = [NSCursor openHandCursor];
                    else if ((area & SKReadingBarResizeArea))
                        cursor = [NSCursor resizeUpDownCursor];
                    else
                        cursor = [NSCursor openHandBarCursor];
                } else if (([theEvent modifierFlags] & NSShiftKeyMask)) {
                    cursor = [NSCursor zoomOutCursor];
                } else {
                    cursor = [NSCursor zoomInCursor];
                }
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

- (PDFAreaOfInterest)extendedAreaOfInterestForMouse:(NSEvent *)theEvent {
    PDFAreaOfInterest area = [self areaOfInterestForMouse:theEvent];
    if (readingBar) {
        NSPoint p = NSZeroPoint;
        PDFPage *page = [self pageAndPoint:&p forEvent:theEvent nearest:YES];
        if ([[readingBar page] isEqual:page]) {
            NSRect bounds = [readingBar currentBounds];
            if (p.y >= NSMinY(bounds) && p.y <= NSMaxY(bounds)) {
                area |= SKReadingBarArea;
                if (p.y < NSMinY(bounds) + READINGBAR_RESIZE_EDGE_HEIGHT)
                    area |= SKReadingBarResizeArea;
            }
        }
    }
    return area;
}

@end

static inline NSInteger SKIndexOfRectAtYInOrderedRects(CGFloat y,  NSPointerArray *rectArray, BOOL lower) 
{
    NSInteger i = 0, iMax = [rectArray count];
    
    for (i = 0; i < iMax; i++) {
        NSRect rect = *(NSRectPointer)[rectArray pointerAtIndex:i];
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

static inline CGPathRef SKCopyCGPathFromBezierPath(NSBezierPath *bezierPath)
{
    CGMutablePathRef path = CGPathCreateMutable();
    NSInteger numElements = [bezierPath elementCount];
    NSPoint points[3];
    NSInteger i;
    
    for (i = 0; i < numElements; i++) {
        switch ([bezierPath elementAtIndex:i associatedPoints:points]) {
            case NSMoveToBezierPathElement:
                CGPathMoveToPoint(path, NULL, points[0].x, points[0].y);
                break;
            case NSLineToBezierPathElement:
                CGPathAddLineToPoint(path, NULL, points[0].x, points[0].y);
                break;
            case NSCurveToBezierPathElement:
                CGPathAddCurveToPoint(path, NULL, points[0].x, points[0].y,points[1].x, points[1].y, points[2].x, points[2].y);
                break;
            case NSClosePathBezierPathElement:
                CGPathCloseSubpath(path);
                break;
        }
    }
    
    return path;
}
