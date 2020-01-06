//
//  SKPDFView.m
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
#import "SKAnimatedBorderlessWindow.h"
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
#import "NSPointerArray_SKExtensions.h"
#import "NSImage_SKExtensions.h"
#import "NSShadow_SKExtensions.h"
#import "SKSnapshotWindowController.h"
#import "SKMainWindowController.h"
#import "PDFAnnotationLine_SKExtensions.h"
#import "NSScroller_SKExtensions.h"
#import "SKColorMenuView.h"

#define ANNOTATION_MODE_COUNT 9
#define TOOL_MODE_COUNT 5

#define ANNOTATION_MODE_IS_MARKUP (annotationMode == SKHighlightNote || annotationMode == SKUnderlineNote || annotationMode == SKStrikeOutNote)

#define READINGBAR_RESIZE_EDGE_HEIGHT 3.0
#define NAVIGATION_BOTTOM_EDGE_HEIGHT 5.0

#define TEXT_SELECT_MARGIN_SIZE ((NSSize){80.0, 100.0})

#define TOOLTIP_OFFSET_FRACTION 0.3

#define DEFAULT_SNAPSHOT_HEIGHT 200.0

#define MIN_NOTE_SIZE 8.0

#define HANDLE_SIZE 4.0

#define DEFAULT_MAGNIFICATION 2.5
#define SMALL_MAGNIFICATION   1.5
#define LARGE_MAGNIFICATION   4.0

#define AUTO_HIDE_DELAY 3.0
#define SHOW_NAV_DELAY  0.25

NSString *SKPDFViewDisplaysAsBookChangedNotification = @"SKPDFViewDisplaysAsBookChangedNotification";
NSString *SKPDFViewDisplaysPageBreaksChangedNotification = @"SKPDFViewDisplaysPageBreaksChangedNotification";
NSString *SKPDFViewToolModeChangedNotification = @"SKPDFViewToolModeChangedNotification";
NSString *SKPDFViewAnnotationModeChangedNotification = @"SKPDFViewAnnotationModeChangedNotification";
NSString *SKPDFViewActiveAnnotationDidChangeNotification = @"SKPDFViewActiveAnnotationDidChangeNotification";
NSString *SKPDFViewDidAddAnnotationNotification = @"SKPDFViewDidAddAnnotationNotification";
NSString *SKPDFViewDidRemoveAnnotationNotification = @"SKPDFViewDidRemoveAnnotationNotification";
NSString *SKPDFViewDidMoveAnnotationNotification = @"SKPDFViewDidMoveAnnotationNotification";
NSString *SKPDFViewReadingBarDidChangeNotification = @"SKPDFViewReadingBarDidChangeNotification";
NSString *SKPDFViewSelectionChangedNotification = @"SKPDFViewSelectionChangedNotification";
NSString *SKPDFViewMagnificationChangedNotification = @"SKPDFViewMagnificationChangedNotification";
NSString *SKPDFViewCurrentSelectionChangedNotification = @"SKPDFViewCurrentSelectionChangedNotification";

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
#define SKMagnifyWithMousePressedKey @"SKMagnifyWithMousePressed"

#define SKAnnotationKey @"SKAnnotation"

static char SKPDFViewDefaultsObservationContext;
static char SKPDFViewTransitionsObservationContext;

static NSUInteger moveReadingBarModifiers = NSAlternateKeyMask;
static NSUInteger resizeReadingBarModifiers = NSAlternateKeyMask | NSShiftKeyMask;

static BOOL useToolModeCursors = NO;

static inline PDFAreaOfInterest SKAreaOfInterestForResizeHandle(SKRectEdges mask, PDFPage *page);

static inline NSInteger SKIndexOfRectAtPointInOrderedRects(NSPoint point,  NSPointerArray *rectArray, NSInteger lineAngle, BOOL lower);

enum {
    SKNavigationNone,
    SKNavigationBottom,
    SKNavigationEverywhere,
};

#if SDK_BEFORE(10_12)
@interface PDFView (SKSierraDeclarations)
- (void)drawPage:(PDFPage *)page toContext:(CGContextRef)context;
@end
@interface PDFAnnotation (SKPrivateDeclarations)
- (void)drawWithBox:(PDFDisplayBox)box inContext:(CGContextRef)context;
@end
#endif

#pragma mark -

@interface SKPDFView ()
@property (retain) SKReadingBar *readingBar;
@property (retain) SKSyncDot *syncDot;
@property (retain) PDFAnnotation *highlightAnnotation;
@end

@interface SKPDFView (Private)

- (void)addAnnotationWithType:(SKNoteType)annotationType selection:(PDFSelection *)selection point:(NSValue *)pointValue;
- (BOOL)addAnnotationWithType:(SKNoteType)annotationType selection:(PDFSelection *)selection page:(PDFPage *)page bounds:(NSRect)bounds;

- (BOOL)isEditingAnnotation:(PDFAnnotation *)annotation;

- (void)beginNewUndoGroupIfNeeded;

- (void)enableNavigation;
- (void)disableNavigation;

- (void)doAutoHide;
- (void)showNavWindow;
- (void)performSelectorOnce:(SEL)aSelector afterDelay:(NSTimeInterval)delay;

- (void)doMoveActiveAnnotationForKey:(unichar)eventChar byAmount:(CGFloat)delta;
- (void)doResizeActiveAnnotationForKey:(unichar)eventChar byAmount:(CGFloat)delta;
- (void)doMoveReadingBarForKey:(unichar)eventChar;
- (void)doResizeReadingBarForKey:(unichar)eventChar;

- (BOOL)doSelectAnnotationWithEvent:(NSEvent *)theEvent;
- (void)doDragAnnotationWithEvent:(NSEvent *)theEvent;
- (void)doClickLinkWithEvent:(NSEvent *)theEvent;
- (void)doSelectSnapshotWithEvent:(NSEvent *)theEvent;
- (void)doMagnifyWithEvent:(NSEvent *)theEvent;
- (void)doDrawFreehandNoteWithEvent:(NSEvent *)theEvent;
- (void)doEraseAnnotationsWithEvent:(NSEvent *)theEvent;
- (void)doSelectWithEvent:(NSEvent *)theEvent;
- (void)doDragReadingBarWithEvent:(NSEvent *)theEvent;
- (void)doResizeReadingBarWithEvent:(NSEvent *)theEvent;
- (void)doMarqueeZoomWithEvent:(NSEvent *)theEvent;
- (BOOL)doDragMouseWithEvent:(NSEvent *)theEvent;
- (BOOL)doDragTextWithEvent:(NSEvent *)theEvent;
- (void)setCursorForMouse:(NSEvent *)theEvent;

- (void)updateMagnifyWithEvent:(NSEvent *)theEvent;
- (void)updateLoupeBackgroundColor;
- (void)removeLoupeWindow;

- (void)handlePageChangedNotification:(NSNotification *)notification;
- (void)handleScaleChangedNotification:(NSNotification *)notification;
- (void)handleUndoGroupOpenedOrClosedNotification:(NSNotification *)notification;
- (void)handleScrollerStyleChangedNotification:(NSNotification *)notification;
- (void)handleWindowWillCloseNotification:(NSNotification *)notification;

@end

#if DEPLOYMENT_BEFORE(10_14)
@interface NSView (SKMojaveExtensions)
- (void)viewDidChangeEffectiveAppearance;
@end
#endif

#pragma mark -

@implementation SKPDFView

@synthesize toolMode, annotationMode, interactionMode, activeAnnotation, hideNotes, readingBar, transitionController, typeSelectHelper, syncDot, highlightAnnotation;
@synthesize currentMagnification=magnification, zooming;
@dynamic editTextField, hasReadingBar, currentSelectionPage, currentSelectionRect, needsRewind;

+ (void)initialize {
    SKINITIALIZE;
    
    NSArray *sendTypes = [NSArray arrayWithObjects:NSPasteboardTypePDF, NSPasteboardTypeTIFF, NSPasteboardTypeString, NSPasteboardTypeRTF, nil];
    [NSApp registerServicesMenuSendTypes:sendTypes returnTypes:[NSArray array]];
    
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

+ (NSArray *)defaultKeysToObserve {
    return [NSArray arrayWithObjects:SKReadingBarColorKey, SKReadingBarInvertKey, nil];
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
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(handlePageChangedNotification:)
                                                 name:PDFViewPageChangedNotification object:self];
    [nc addObserver:self selector:@selector(handleScaleChangedNotification:)
                                                 name:PDFViewScaleChangedNotification object:self];
    [nc addObserver:self selector:@selector(handleUndoGroupOpenedOrClosedNotification:)
                                                 name:NSUndoManagerDidOpenUndoGroupNotification object:nil];
    [nc addObserver:self selector:@selector(handleUndoGroupOpenedOrClosedNotification:)
                                                 name:NSUndoManagerDidCloseUndoGroupNotification object:nil];
    [nc addObserver:self selector:@selector(handleScrollerStyleChangedNotification:)
                                                 name:NSPreferredScrollerStyleDidChangeNotification object:nil];
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeys:[[self class] defaultKeysToObserve] context:&SKPDFViewDefaultsObservationContext];
    
    [self handleScrollerStyleChangedNotification:nil];
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
    // we should have been cleaned up in setDelegate:nil which is called from windowWillClose:
    SKDESTROY(syncDot);
    SKDESTROY(trackingArea);
    SKDESTROY(activeAnnotation);
    SKDESTROY(typeSelectHelper);
    SKDESTROY(transitionController);
    SKDESTROY(navWindow);
    SKDESTROY(readingBar);
    SKDESTROY(editor);
    SKDESTROY(highlightAnnotation);
    SKDESTROY(rewindPage);
    SKDESTROY(backgroundColor);
    [super dealloc];
}

- (void)cleanup {
    [[NSSpellChecker sharedSpellChecker] closeSpellDocumentWithTag:spellingTag];
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeys:[[self class] defaultKeysToObserve]];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [transitionController removeObserver:self forKeyPath:@"transitionStyle"];
    [transitionController removeObserver:self forKeyPath:@"duration"];
    [transitionController removeObserver:self forKeyPath:@"shouldRestrict"];
    [transitionController removeObserver:self forKeyPath:@"pageTransitions"];
    [self disableNavigation];
    [[SKImageToolTipWindow sharedToolTipWindow] orderOut:self];
    [self removePDFToolTipRects];
    [syncDot invalidate];
    SKDESTROY(syncDot);
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
                if ([annotation isNote] || (hasLinkToolTips && [annotation linkDestination])) {
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

- (void)drawSelectionForPage:(PDFPage *)pdfPage inContext:(CGContextRef)context {
    NSRect rect;
    NSUInteger pageIndex;
    @synchronized (self) {
        pageIndex = selectionPageIndex;
        rect = selectionRect;
    }
    if (pageIndex != NSNotFound) {
        BOOL active = RUNNING_AFTER(10_12) ? YES : [[self window] isKeyWindow] && [[[self window] firstResponder] isDescendantOf:self];
        NSRect bounds = [pdfPage boundsForBox:[self displayBox]];
        CGFloat radius = HANDLE_SIZE * [self unitWidthOnPage:pdfPage];
        CGColorRef color = CGColorCreateGenericGray(0.0, 0.6);
        CGContextSetFillColorWithColor(context, color);
        CGColorRelease(color);
        CGContextBeginPath(context);
        CGContextAddRect(context, NSRectToCGRect(bounds));
        CGContextAddRect(context, NSRectToCGRect(rect));
        CGContextEOFillPath(context);
        if ([pdfPage pageIndex] != pageIndex) {
            color = CGColorCreateGenericGray(0.0, 0.3);
            CGContextSetFillColorWithColor(context, color);
            CGColorRelease(color);
            CGContextFillRect(context, NSRectToCGRect(rect));
        }
        SKDrawResizeHandles(context, rect, radius, active);
    }
}

- (void)drawDragHighlightInContext:(CGContextRef)context {
    PDFAnnotation *annotation = [self highlightAnnotation];
    if (annotation) {
        PDFPage *page = [annotation page];
        CGFloat width = [self unitWidthOnPage:page];
        CGContextSaveGState(context);
        CGContextSetStrokeColorWithColor(context, CGColorGetConstantColor(kCGColorBlack));
        NSRect rect = [self integralRect:[annotation bounds] onPage:page];
        CGContextStrokeRectWithWidth(context, CGRectInset(NSRectToCGRect(rect), 0.5 * width, 0.5 * width), width);
        CGContextRestoreGState(context);
    }
}

- (void)drawPageHighlights:(PDFPage *)pdfPage toContext:(CGContextRef)context {
    CGContextSaveGState(context);
    
    [pdfPage transformContext:context forBox:[self displayBox]];
    
    [[self readingBar] drawForPage:pdfPage withBox:[self displayBox] inContext:context];
    
    PDFAnnotation *annotation = nil;
    @synchronized (self) {
        annotation = [[activeAnnotation retain] autorelease];
    }
    
    if ([[annotation page] isEqual:pdfPage])
        [annotation drawSelectionHighlightForView:self inContext:context];
    
    [self drawSelectionForPage:pdfPage inContext:context];
    
    [self drawDragHighlightInContext:context];
    
    SKSyncDot *aSyncDot = [self syncDot];
    if ([[aSyncDot page] isEqual:pdfPage])
        [aSyncDot drawInContext:context];
    
    CGContextRestoreGState(context);
}

- (void)drawPage:(PDFPage *)pdfPage toContext:(CGContextRef)context {
    // Let PDFView do most of the hard work.
    [super drawPage:pdfPage toContext:context];
    [self drawPageHighlights:pdfPage toContext:context];
}

- (void)drawPage:(PDFPage *)pdfPage {
    if ([PDFView instancesRespondToSelector:@selector(drawPage:toContext:)]) {
        // on 10.12 this should be called from drawPage:toContext:
        [super drawPage:pdfPage];
    } else {
        // Let PDFView do most of the hard work.
        [super drawPage:pdfPage];
        [self drawPageHighlights:pdfPage toContext:[[NSGraphicsContext currentContext] graphicsPort]];
    }
}

#pragma mark Accessors

- (void)setDocument:(PDFDocument *)document {
    SKDESTROY(rewindPage);
    
    [syncDot invalidate];
    [self setSyncDot:nil];
    
    @synchronized (self) {
        selectionRect = NSZeroRect;
        selectionPageIndex = NSNotFound;
    }
    
    [self removePDFToolTipRects];
    [[SKImageToolTipWindow sharedToolTipWindow] orderOut:self];
    
    NSUInteger readingBarPageIndex = NSNotFound;
    NSInteger readingBarLine = -1;
    if ([self hasReadingBar]) {
        readingBarPageIndex = [[readingBar page] pageIndex];
        readingBarLine = [readingBar currentLine];
        [self setReadingBar:nil];
    }
    
    [super setDocument:document];
    
    [self resetPDFToolTipRects];
    
    if (readingBarPageIndex != NSNotFound) {
        PDFPage *page = nil;
        if (readingBarPageIndex < [document pageCount]) {
            page = [document pageAtIndex:readingBarPageIndex];
        } else if ([document pageCount] > 0) {
            page = [document pageAtIndex:[document pageCount] - 1];
            readingBarLine = 0;
        }
        if (page) {
            SKReadingBar *aReadingBar = [[SKReadingBar alloc] initWithPage:page];
            if (readingBarLine <= [aReadingBar maxLine])
                [aReadingBar setCurrentLine:readingBarLine];
            else
                [aReadingBar goToNextLine];
            [self setReadingBar:aReadingBar];
            [aReadingBar release];
        }
    }
    
    if ([loupeWindow parentWindow])
        [self updateMagnifyWithEvent:nil];
}

- (void)setBackgroundColor:(NSColor *)newBackgroundColor {
    [super setBackgroundColor:newBackgroundColor];
    if (backgroundColor != newBackgroundColor) {
        [backgroundColor release];
        backgroundColor = [newBackgroundColor retain];
    }
    [self updateLoupeBackgroundColor];
}

- (NSColor *)backgroundColor {
    return [super backgroundColor] ?: backgroundColor;
}

- (void)setToolMode:(SKToolMode)newToolMode {
    if (toolMode != newToolMode) {
        if (toolMode == SKTextToolMode || toolMode == SKNoteToolMode) {
            if (newToolMode != SKTextToolMode) {
                if (newToolMode != SKNoteToolMode && activeAnnotation)
                    [self setActiveAnnotation:nil];
                if ([[self currentSelection] hasCharacters])
                    [self setCurrentSelection:nil];
            }
        } else if (toolMode == SKSelectToolMode) {
            if (NSEqualRects(selectionRect, NSZeroRect) == NO) {
                [self setCurrentSelectionRect:NSZeroRect];
                [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewSelectionChangedNotification object:self];
            }
        } else if (toolMode == SKMagnifyToolMode) {
            if (loupeWindow)
                [self removeLoupeWindow];
        }
        
        toolMode = newToolMode;
        
        [[NSUserDefaults standardUserDefaults] setInteger:toolMode forKey:SKLastToolModeKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewToolModeChangedNotification object:self];
        [self setCursorForMouse:nil];
        [self resetPDFToolTipRects];
        if (toolMode == SKMagnifyToolMode && [[NSUserDefaults standardUserDefaults] boolForKey:SKMagnifyWithMousePressedKey] == NO)
            [self doMagnifyWithEvent:nil];
    }
}

- (void)setAnnotationMode:(SKNoteType)newAnnotationMode {
    if (annotationMode != newAnnotationMode) {
        annotationMode = newAnnotationMode;
        [[NSUserDefaults standardUserDefaults] setInteger:annotationMode forKey:SKLastAnnotationModeKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewAnnotationModeChangedNotification object:self];
        // hack to make sure we update the cursor
        [self setCursorForMouse:nil];
    }
}

- (void)setInteractionMode:(SKInteractionMode)newInteractionMode {
    if (interactionMode != newInteractionMode) {
        if (interactionMode == SKPresentationMode) {
            cursorHidden = NO;
            [NSCursor setHiddenUntilMouseMoves:NO];
            if ([[self documentView] isHidden])
                [[self documentView] setHidden:NO];
        }
        interactionMode = newInteractionMode;
        if (interactionMode == SKPresentationMode) {
            if (toolMode == SKTextToolMode || toolMode == SKNoteToolMode) {
                if (activeAnnotation)
                    [self setActiveAnnotation:nil];
                if ([[self currentSelection] hasCharacters])
                    [self setCurrentSelection:nil];
            } else if (toolMode == SKSelectToolMode && NSEqualRects(selectionRect, NSZeroRect) == NO) {
                [self setCurrentSelectionRect:NSZeroRect];
                [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewSelectionChangedNotification object:self];
            }
        }
        // always clean up navWindow and hanging perform requests
        [self disableNavigation];
        if (interactionMode == SKPresentationMode || interactionMode == SKLegacyFullScreenMode)
            [self enableNavigation];
        [self resetPDFToolTipRects];
    }
}

- (void)setActiveAnnotation:(PDFAnnotation *)newAnnotation {
	if (newAnnotation != activeAnnotation) {
        PDFAnnotation *wasAnnotation = activeAnnotation;
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"
        
        // Will need to redraw old active anotation.
        if (activeAnnotation != nil) {
            [self setNeedsDisplayForAnnotation:activeAnnotation];
            if ([activeAnnotation isLink] && [activeAnnotation respondsToSelector:@selector(setHighlighted:)])
                [(PDFAnnotationLink *)activeAnnotation setHighlighted:NO];
            NSInteger level = [[self undoManager] groupingLevel];
            if (editor && [self commitEditing] == NO)
                [self discardEditing];
            if ([[self undoManager] groupingLevel] > level)
                wantsNewUndoGroup = YES;
        }
        
        // Assign.
        @synchronized (self) {
            [activeAnnotation release];
            activeAnnotation = [newAnnotation retain];
        }
        if (newAnnotation) {
            // Force redisplay.
            [self setNeedsDisplayForAnnotation:activeAnnotation];
            if ([activeAnnotation isLink] && [activeAnnotation respondsToSelector:@selector(setHighlighted:)])
                [(PDFAnnotationLink *)activeAnnotation setHighlighted:YES];
        }
        
#pragma clang diagnostic pop
        
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:wasAnnotation, SKPDFViewAnnotationKey, nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewActiveAnnotationDidChangeNotification object:self userInfo:userInfo];
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
    }
}
    
- (void)setDisplayModeAndRewind:(PDFDisplayMode)mode {
    if (mode != [self displayMode]) {
        [self setNeedsRewind:YES];
        [self setDisplayMode:mode];
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

- (void)setDisplayBoxAndRewind:(PDFDisplayBox)box {
    if (box != [self displayBox]) {
        [self setNeedsRewind:YES];
        [self setDisplayBox:box];
    }
}

- (void)setDisplaysAsBook:(BOOL)asBook {
    if (asBook != [self displaysAsBook]) {
        PDFPage *page = [self currentPage];
        [super setDisplaysAsBook:asBook];
        if (page && [page isEqual:[self currentPage]] == NO)
            [self goToPage:page];
        [self resetPDFToolTipRects];
        [editor layout];
		[[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewDisplaysAsBookChangedNotification object:self];
    }
}

- (void)setDisplaysAsBookAndRewind:(BOOL)asBook {
    if (asBook != [self displaysAsBook]) {
        [self setNeedsRewind:YES];
        [self setDisplaysAsBook:asBook];
    }
}

- (void)setDisplaysPageBreaks:(BOOL)pageBreaks {
    if (pageBreaks != [self displaysPageBreaks]) {
        [super setDisplaysPageBreaks:pageBreaks];
        [self resetPDFToolTipRects];
        [editor layout];
		[[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewDisplaysPageBreaksChangedNotification object:self];
    }
}

- (void)setCurrentSelection:(PDFSelection *)selection {
    if (toolMode == SKNoteToolMode && annotationMode == SKHighlightNote)
        [selection setColor:[[NSUserDefaults standardUserDefaults] colorForKey:SKHighlightNoteColorKey]];
    if (RUNNING(10_12) && selection == nil)
        selection = [[[PDFSelection alloc] initWithDocument:[self document]] autorelease];
    [super setCurrentSelection:selection];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewCurrentSelectionChangedNotification object:self];
}

- (NSRect)currentSelectionRect {
    if (toolMode == SKSelectToolMode)
        return selectionRect;
    return NSZeroRect;
}

- (void)setCurrentSelectionRect:(NSRect)rect {
    if (toolMode == SKSelectToolMode) {
        if (NSEqualRects(selectionRect, rect) == NO)
            [self requiresDisplay];
        @synchronized (self) {
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
}

- (PDFPage *)currentSelectionPage {
    return selectionPageIndex == NSNotFound ? nil : [[self document] pageAtIndex:selectionPageIndex];
}

- (void)setCurrentSelectionPage:(PDFPage *)page {
    if (toolMode == SKSelectToolMode) {
        if (selectionPageIndex != [page pageIndex] || (page == nil && selectionPageIndex != NSNotFound))
            [self requiresDisplay];
        @synchronized (self) {
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
}

- (void)setHideNotes:(BOOL)flag {
    if (hideNotes != flag) {
        hideNotes = flag;
        if (hideNotes)
            [self setActiveAnnotation:nil];
        [self requiresDisplay];
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

- (void)toggleReadingBar {
    PDFPage *page = nil;
    NSRect bounds = NSZeroRect;
    NSDictionary *userInfo = nil;
    if (readingBar) {
        page = [readingBar page];
        bounds = [readingBar currentBoundsForBox:[self displayBox]];
        [self setReadingBar:nil];
        userInfo = [NSDictionary dictionaryWithObjectsAndKeys:page, SKPDFViewOldPageKey, nil];
    } else {
        page = [self currentPage];
        SKReadingBar *aReadingBar = [[SKReadingBar alloc] initWithPage:page];
        [aReadingBar goToNextLine];
        bounds = [aReadingBar currentBoundsForBox:[self displayBox]];
        [self goToRect:NSInsetRect([aReadingBar currentBounds], 0.0, -20.0) onPage:page];
        [self setReadingBar:aReadingBar];
        [aReadingBar release];
        userInfo = [NSDictionary dictionaryWithObjectsAndKeys:page, SKPDFViewNewPageKey, nil];
    }
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKReadingBarInvertKey])
        [self requiresDisplay];
    else
        [self setNeedsDisplayInRect:bounds ofPage:page];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewReadingBarDidChangeNotification object:self userInfo:userInfo];
}

#pragma mark Actions

- (void)animateTransitionForNextPage:(BOOL)next {
    PDFPage *fromPage = [self currentPage];
    NSUInteger idx = [fromPage pageIndex];
    NSUInteger toIdx = (next ? idx + 1 : idx - 1);
    PDFPage *toPage = [[self document] pageAtIndex:toIdx];
    if ([transitionController pageTransitions] ||
        ([fromPage label] && [toPage label] && [[fromPage label] isEqualToString:[toPage label]] == NO)) {
        NSRect rect = [self convertRect:[fromPage boundsForBox:[self displayBox]] fromPage:fromPage];
        [[self transitionController] animateForRect:rect from:idx to:toIdx change:^{
            if (next)
                [super goToNextPage:self];
            else
                [super goToPreviousPage:self];
            return [self convertRect:[toPage boundsForBox:[self displayBox]] fromPage:toPage];
        }];
    } else if (next) {
        [super goToNextPage:self];
    } else {
        [super goToPreviousPage:self];
    }
}

- (void)doAutoHideCursor {
    [[NSCursor emptyCursor] set];
    [NSCursor setHiddenUntilMouseMoves:YES];
}

- (IBAction)goToNextPage:(id)sender {
    if (interactionMode == SKPresentationMode && [transitionController hasTransition] && [self canGoToNextPage])
        [self animateTransitionForNextPage:YES];
    else
        [super goToNextPage:sender];
    if (interactionMode == SKPresentationMode && cursorHidden) {
        [self performSelector:@selector(doAutoHideCursor) withObject:nil afterDelay:0.0];
        [self performSelector:@selector(doAutoHideCursor) withObject:nil afterDelay:0.1];
    }
}

- (IBAction)goToPreviousPage:(id)sender {
    if (interactionMode == SKPresentationMode && [transitionController hasTransition] && [self canGoToPreviousPage])
        [self animateTransitionForNextPage:NO];
    else
        [super goToPreviousPage:sender];
    if (interactionMode == SKPresentationMode && cursorHidden) {
        [self performSelector:@selector(doAutoHideCursor) withObject:nil afterDelay:0.0];
        [self performSelector:@selector(doAutoHideCursor) withObject:nil afterDelay:0.1];
    }
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
                    NSFont *font = [[NSUserDefaults standardUserDefaults] fontForNameKey:SKAnchoredNoteFontNameKey sizeKey:SKAnchoredNoteFontSizeKey];
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
        @synchronized (self) {
            selectionRect = NSIntersectionRect(NSUnionRect([page foregroundBox], selectionRect), [page boundsForBox:[self displayBox]]);
            selectionPageIndex = [page pageIndex];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewSelectionChangedNotification object:self];
        [self requiresDisplay];
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
    if (interactionMode == SKPresentationMode && cursorHidden) {
        [self performSelector:@selector(doAutoHideCursor) withObject:nil afterDelay:0.0];
        [self performSelector:@selector(doAutoHideCursor) withObject:nil afterDelay:0.1];
    }
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
    zooming = YES;
    [super zoomIn:sender];
    zooming = NO;
}

- (void)zoomOut:(id)sender {
    zooming = YES;
    [super zoomOut:sender];
    zooming = NO;
}

- (void)setScaleFactor:(CGFloat)scale {
    zooming = YES;
    [super setScaleFactor:scale];
    zooming = NO;
}

- (void)zoomToPhysicalSize:(id)sender {
    [self setPhysicalScaleFactor:1.0];
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
    NSRange range;
    
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

#pragma mark Rewind

- (BOOL)needsRewind {
    return rewindPage != nil;
}

- (void)setNeedsRewind:(BOOL)flag {
    if (flag) {
        [rewindPage release];
        rewindPage = [[self currentPage] retain];
        DISPATCH_MAIN_AFTER_SEC(0.25, ^{
            if (rewindPage) {
                if ([[self currentPage] isEqual:rewindPage] == NO)
                    [self goToPage:rewindPage];
                SKDESTROY(rewindPage);
            }
        });
    } else {
        SKDESTROY(rewindPage);
    }
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
        } else if (isLeftRightArrow && (modifiers == NSAlternateKeyMask)) {
            [self setToolMode:(toolMode + (eventChar == NSRightArrowFunctionKey ? 1 : TOOL_MODE_COUNT - 1)) % TOOL_MODE_COUNT];
        } else if (isUpDownArrow && (modifiers == NSAlternateKeyMask)) {
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

#define IS_TABLET_EVENT(theEvent, deviceType) (([theEvent subtype] == NSTabletProximityEventSubtype || [theEvent subtype] == NSTabletPointEventSubtype) && [NSEvent currentPointingDeviceType] == deviceType)

- (void)mouseDown:(NSEvent *)theEvent{
    if ([activeAnnotation isLink])
        [self setActiveAnnotation:nil];
    
    // 10.6 does not automatically make us firstResponder, that's annoying
    // but we don't want an edited text note to stop editing when we're resizing it
    if ([[[self window] firstResponder] isDescendantOf:self] == NO)
        [[self window] makeFirstResponder:self];
    
	NSUInteger modifiers = [theEvent standardModifierFlags];
    PDFAreaOfInterest area = [self areaOfInterestForMouse:theEvent];
    
    if ([[self document] isLocked]) {
        [super mouseDown:theEvent];
    } else if (interactionMode == SKPresentationMode) {
        if (hideNotes == NO && [[self document] allowsNotes] && IS_TABLET_EVENT(theEvent, NSPenPointingDevice)) {
            [self doDrawFreehandNoteWithEvent:theEvent];
            [self setActiveAnnotation:nil];
        } else if ((area & kPDFLinkArea)) {
            [super mouseDown:theEvent];
        } else {
            [self goToNextPage:self];
            // Eat up drag events because we don't want to select
            [self doDragMouseWithEvent:theEvent];
        }
    } else if (modifiers == NSCommandKeyMask) {
        [self doSelectSnapshotWithEvent:theEvent];
    } else if (modifiers == (NSCommandKeyMask | NSShiftKeyMask)) {
        [self doPdfsyncWithEvent:theEvent];
    } else if (modifiers == (NSCommandKeyMask | NSAlternateKeyMask)) {
        [self doMarqueeZoomWithEvent:theEvent];
    } else if ((area & SKReadingBarArea) && (area & kPDFLinkArea) == 0) {
        if ((area & (SKResizeUpDownArea | SKResizeLeftRightArea)))
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
    } else if (hideNotes == NO && [[self document] allowsNotes] && IS_TABLET_EVENT(theEvent, NSEraserPointingDevice)) {
        [self doEraseAnnotationsWithEvent:theEvent];
    } else if ([self doSelectAnnotationWithEvent:theEvent]) {
        if ([activeAnnotation isLink]) {
            [self doClickLinkWithEvent:theEvent];
        } else if ([theEvent clickCount] == 2 && [activeAnnotation isEditable]) {
            if ([self doDragMouseWithEvent:theEvent] == NO)
                [self editActiveAnnotation:nil];
        } else if ([activeAnnotation isMovable]) {
            [self doDragAnnotationWithEvent:theEvent];
        } else {
            [self doDragMouseWithEvent:theEvent];
        }
    } else if (toolMode == SKNoteToolMode && hideNotes == NO && [[self document] allowsNotes] && ANNOTATION_MODE_IS_MARKUP == NO) {
        if (annotationMode == SKInkNote) {
            [self doDrawFreehandNoteWithEvent:theEvent];
        } else {
            [self setActiveAnnotation:nil];
            [self doDragAnnotationWithEvent:theEvent];
        }
    } else if ((area & SKDragArea)) {
        [self setActiveAnnotation:nil];
        [self doDragWithEvent:theEvent];
    } else if ([self doDragTextWithEvent:theEvent] == NO) {
        [self setActiveAnnotation:nil];
        [super mouseDown:theEvent];
        if ((toolMode == SKNoteToolMode && hideNotes == NO && [[self document] allowsNotes] && ANNOTATION_MODE_IS_MARKUP) && [[self currentSelection] hasCharacters]) {
            [self addAnnotationWithType:annotationMode];
            [self setCurrentSelection:nil];
        }
    }
}

- (void)mouseMoved:(NSEvent *)theEvent {
    cursorHidden = NO;
    
    [super mouseMoved:theEvent];
    
    if (toolMode == SKMagnifyToolMode && loupeWindow) {
        [self updateMagnifyWithEvent:theEvent];
    } else {
        
        // make sure the cursor is set, at least outside the pages this does not happen
        [self setCursorForMouse:theEvent];
        
        if ([activeAnnotation isLink]) {
            [[SKImageToolTipWindow sharedToolTipWindow] fadeOut];
            [self setActiveAnnotation:nil];
        }
    }
    
    if (navWindow && [navWindow isVisible] == NO) {
        if (navigationMode == SKNavigationEverywhere) {
            if ([navWindow parentWindow] == nil) {
                [navWindow setAlphaValue:0.0];
                [[self window] addChildWindow:navWindow ordered:NSWindowAbove];
            }
            [navWindow fadeIn];
        } else if (navigationMode == SKNavigationBottom && [theEvent locationInWindow].y < NAVIGATION_BOTTOM_EDGE_HEIGHT) {
            [self performSelectorOnce:@selector(showNavWindow) afterDelay:SHOW_NAV_DELAY];
        }
    }
    if (navigationMode != SKNavigationNone || interactionMode == SKPresentationMode)
        [self performSelectorOnce:@selector(doAutoHide) afterDelay:AUTO_HIDE_DELAY];
}

- (void)flagsChanged:(NSEvent *)theEvent {
    [super flagsChanged:theEvent];
    [self setCursorForMouse:nil];
}

- (NSMenu *)menuForEvent:(NSEvent *)theEvent {
    NSMenu *menu = [super menuForEvent:theEvent];
    NSMenu *submenu;
    NSMenuItem *item;
    NSInteger i = 0;
    
    if ([[menu itemAtIndex:0] view] != nil) {
        [menu removeItemAtIndex:0];
        if ([[menu itemAtIndex:0] isSeparatorItem])
            [menu removeItemAtIndex:0];
    }
    
    // On Leopard the selection is automatically set. In some cases we never want a selection though.
    if ((interactionMode == SKPresentationMode) || (toolMode != SKTextToolMode && [[self currentSelection] hasCharacters])) {
        static NSSet *selectionActions = nil;
        if (selectionActions == nil)
            selectionActions = [[NSSet alloc] initWithObjects:@"_searchInSpotlight:", @"_searchInGoogle:", @"_searchInDictionary:", @"_revealSelection:", nil];
        [self setCurrentSelection:nil];
        BOOL allowsSeparator = NO;
        while ([menu numberOfItems] > i) {
            item = [menu itemAtIndex:i];
            if ([item isSeparatorItem]) {
                if (allowsSeparator) {
                    i++;
                    allowsSeparator = NO;
                } else {
                    [menu removeItemAtIndex:i];
                }
            } else if ([self validateMenuItem:item] == NO || [selectionActions containsObject:NSStringFromSelector([item action])]) {
                [menu removeItemAtIndex:i];
            } else {
                i++;
                allowsSeparator = YES;
            }
        }
    }
    
    if (interactionMode == SKPresentationMode)
        return menu;
    
    NSValue *pointValue = [NSValue valueWithPoint:[theEvent locationInView:self]];
    
    i = [menu indexOfItemWithTarget:self andAction:@selector(copy:)];
    if (i != -1) {
        [menu removeItemAtIndex:i];
        if ([menu numberOfItems] > i && [[menu itemAtIndex:i] isSeparatorItem] && (i == 0 || [[menu itemAtIndex:i - 1] isSeparatorItem]))
            [menu removeItemAtIndex:i];
        if (i > 0 && i == [menu numberOfItems] && [[menu itemAtIndex:i - 1] isSeparatorItem])
            [menu removeItemAtIndex:i - 1];
    }
    
    i = [menu indexOfItemWithTarget:self andAction:NSSelectorFromString(@"_setActualSize:")];
    if (i != -1) {
        item = [menu insertItemWithTitle:NSLocalizedString(@"Physical Size", @"Menu item title") action:@selector(zoomToPhysicalSize:) target:self atIndex:i + 1];
        [item setKeyEquivalentModifierMask:NSAlternateKeyMask];
        [item setAlternate:YES];
    }
    
    [menu insertItem:[NSMenuItem separatorItem] atIndex:0];
    
    item = [menu insertItemWithSubmenuAndTitle:NSLocalizedString(@"Tools", @"Menu item title") atIndex:0];
    submenu = [item submenu];
    
    [submenu addItemWithTitle:NSLocalizedString(@"Text", @"Menu item title") action:@selector(changeToolMode:) target:self tag:SKTextToolMode];

    [submenu addItemWithTitle:NSLocalizedString(@"Scroll", @"Menu item title") action:@selector(changeToolMode:) target:self tag:SKMoveToolMode];

    [submenu addItemWithTitle:NSLocalizedString(@"Magnify", @"Menu item title") action:@selector(changeToolMode:) target:self tag:SKMagnifyToolMode];
    
    [submenu addItemWithTitle:NSLocalizedString(@"Select", @"Menu item title") action:@selector(changeToolMode:) target:self tag:SKSelectToolMode];
    
    [submenu addItem:[NSMenuItem separatorItem]];
    
    [submenu addItemWithTitle:NSLocalizedString(@"Text Note", @"Menu item title") action:@selector(changeAnnotationMode:) target:self tag:SKFreeTextNote];

    [submenu addItemWithTitle:NSLocalizedString(@"Anchored Note", @"Menu item title") action:@selector(changeAnnotationMode:) target:self tag:SKAnchoredNote];

    [submenu addItemWithTitle:NSLocalizedString(@"Circle", @"Menu item title") action:@selector(changeAnnotationMode:) target:self tag:SKCircleNote];
    
    [submenu addItemWithTitle:NSLocalizedString(@"Box", @"Menu item title") action:@selector(changeAnnotationMode:) target:self tag:SKSquareNote];
    
    [submenu addItemWithTitle:NSLocalizedString(@"Highlight", @"Menu item title") action:@selector(changeAnnotationMode:) target:self tag:SKHighlightNote];
    
    [submenu addItemWithTitle:NSLocalizedString(@"Underline", @"Menu item title") action:@selector(changeAnnotationMode:) target:self tag:SKUnderlineNote];
    
    [submenu addItemWithTitle:NSLocalizedString(@"Strike Out", @"Menu item title") action:@selector(changeAnnotationMode:) target:self tag:SKStrikeOutNote];
    
    [submenu addItemWithTitle:NSLocalizedString(@"Line", @"Menu item title") action:@selector(changeAnnotationMode:) target:self tag:SKLineNote];
    
    [submenu addItemWithTitle:NSLocalizedString(@"Freehand", @"Menu item title") action:@selector(changeAnnotationMode:) target:self tag:SKInkNote];
    
    [menu insertItem:[NSMenuItem separatorItem] atIndex:0];
    
    item = [menu insertItemWithTitle:NSLocalizedString(@"Take Snapshot", @"Menu item title") action:@selector(takeSnapshot:) target:self atIndex:0];
    [item setRepresentedObject:pointValue];
    
    if (([self toolMode] == SKTextToolMode || [self toolMode] == SKNoteToolMode) && [self hideNotes] == NO && [[self document] allowsNotes]) {
        
        [menu insertItem:[NSMenuItem separatorItem] atIndex:0];
        
        item = [menu insertItemWithSubmenuAndTitle:NSLocalizedString(@"New Note or Highlight", @"Menu item title") atIndex:0];
        submenu = [item submenu];
        
        item = [submenu addItemWithTitle:NSLocalizedString(@"Text Note", @"Menu item title") action:@selector(addAnnotation:) target:self tag:SKFreeTextNote];
        [item setRepresentedObject:pointValue];
        
        item = [submenu addItemWithTitle:NSLocalizedString(@"Anchored Note", @"Menu item title") action:@selector(addAnnotation:) target:self tag:SKAnchoredNote];
        [item setRepresentedObject:pointValue];
        
        item = [submenu addItemWithTitle:NSLocalizedString(@"Circle", @"Menu item title") action:@selector(addAnnotation:) target:self tag:SKCircleNote];
        [item setRepresentedObject:pointValue];
        
        item = [submenu addItemWithTitle:NSLocalizedString(@"Box", @"Menu item title") action:@selector(addAnnotation:) target:self tag:SKSquareNote];
        [item setRepresentedObject:pointValue];
        
        if ([[self currentSelection] hasCharacters]) {
            item = [submenu addItemWithTitle:NSLocalizedString(@"Highlight", @"Menu item title") action:@selector(addAnnotation:) target:self tag:SKHighlightNote];
            [item setRepresentedObject:pointValue];
            
            item = [submenu addItemWithTitle:NSLocalizedString(@"Underline", @"Menu item title") action:@selector(addAnnotation:) target:self tag:SKUnderlineNote];
            [item setRepresentedObject:pointValue];
            
            item = [submenu addItemWithTitle:NSLocalizedString(@"Strike Out", @"Menu item title") action:@selector(addAnnotation:) target:self tag:SKStrikeOutNote];
            [item setRepresentedObject:pointValue];
        }
        
        item = [submenu addItemWithTitle:NSLocalizedString(@"Line", @"Menu item title") action:@selector(addAnnotation:) target:self tag:SKLineNote];
        [item setRepresentedObject:pointValue];
        
        [menu insertItem:[NSMenuItem separatorItem] atIndex:0];
        
        NSPoint point = NSZeroPoint;
        PDFPage *page = [self pageAndPoint:&point forEvent:theEvent nearest:YES];
        PDFAnnotation *annotation = nil;
        
        if (page) {
            annotation = [page annotationAtPoint:point];
            if ([annotation isSkimNote] == NO)
                annotation = nil;
        }
        
        if (annotation) {
            SKColorMenuView *menuView = [[[SKColorMenuView alloc] initWithAnnotation:annotation] autorelease];
            item = [menu insertItemWithTitle:@"" action:NULL target:nil atIndex:0];
            [item setView:menuView];
            
            [menu insertItem:[NSMenuItem separatorItem] atIndex:0];
            
            if ((annotation != activeAnnotation || [NSFontPanel sharedFontPanelExists] == NO || [[NSFontPanel sharedFontPanel] isVisible] == NO) &&
                [annotation isText]) {
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
            SKColorMenuView *menuView = [[[SKColorMenuView alloc] initWithAnnotation:activeAnnotation] autorelease];
            item = [menu insertItemWithTitle:@"" action:NULL target:nil atIndex:0];
            [item setView:menuView];
            
            [menu insertItem:[NSMenuItem separatorItem] atIndex:0];
            
            if (([NSFontPanel sharedFontPanelExists] == NO || [[NSFontPanel sharedFontPanel] isVisible] == NO) &&
                [activeAnnotation isText]) {
                [menu insertItemWithTitle:[NSLocalizedString(@"Note Font", @"Menu item title") stringByAppendingEllipsis] action:@selector(showFontsForThisAnnotation:) target:self atIndex:0];
            }
            
            if (([SKLineInspector sharedLineInspectorExists] == NO || [[[SKLineInspector sharedLineInspector] window] isVisible] == NO) &&
                [activeAnnotation isMarkup] == NO && [activeAnnotation isNote] == NO) {
                [menu insertItemWithTitle:[NSLocalizedString(@"Current Note Line", @"Menu item title") stringByAppendingEllipsis] action:@selector(showLinesForThisAnnotation:) target:self atIndex:0];
            }
            
            if ([NSColorPanel sharedColorPanelExists] == NO || [[NSColorPanel sharedColorPanel] isVisible] == NO) {
                [menu insertItemWithTitle:[NSLocalizedString(@"Current Note Color", @"Menu item title") stringByAppendingEllipsis] action:@selector(showColorsForThisAnnotation:) target:self atIndex:0];
            }
            
            if (editor == nil && [activeAnnotation isEditable]) {
                [menu insertItemWithTitle:NSLocalizedString(@"Edit Current Note", @"Menu item title") action:@selector(editActiveAnnotation:) target:self atIndex:0];
            }
            
            [menu insertItemWithTitle:NSLocalizedString(@"Remove Current Note", @"Menu item title") action:@selector(removeActiveAnnotation:) target:self atIndex:0];
        }
        
        if ([[NSPasteboard generalPasteboard] canReadObjectForClasses:[NSArray arrayWithObjects:[PDFAnnotation class], [NSString class], nil] options:[NSDictionary dictionary]]) {
            [menu insertItemWithTitle:NSLocalizedString(@"Paste", @"Menu item title") action:@selector(paste:) keyEquivalent:@"" atIndex:0];
            item = [menu insertItemWithTitle:NSLocalizedString(@"Paste", @"Menu item title") action:@selector(alternatePaste:) keyEquivalent:@"" atIndex:1];
            [item setKeyEquivalentModifierMask:NSAlternateKeyMask];
            [item setAlternate:YES];
        }
        
        if (([activeAnnotation isSkimNote] && [activeAnnotation isMovable]) || [[self currentSelection] hasCharacters]) {
            if ([activeAnnotation isSkimNote] && [activeAnnotation isMovable])
                [menu insertItemWithTitle:NSLocalizedString(@"Cut", @"Menu item title") action:@selector(cut:) keyEquivalent:@"" atIndex:0];
            [menu insertItemWithTitle:NSLocalizedString(@"Copy", @"Menu item title") action:@selector(copy:) keyEquivalent:@"" atIndex:0];
        }
        
        if ([[menu itemAtIndex:0] isSeparatorItem])
            [menu removeItemAtIndex:0];
        
    } else if ((toolMode == SKSelectToolMode && NSIsEmptyRect(selectionRect) == NO) || ([self toolMode] == SKTextToolMode && [self hideNotes] && [[self currentSelection] hasCharacters])) {
        
        [menu insertItem:[NSMenuItem separatorItem] atIndex:0];
        
        [menu insertItemWithTitle:NSLocalizedString(@"Copy", @"Menu item title") action:@selector(copy:) keyEquivalent:@"" atIndex:0];
        
    }
    
    return menu;
}

- (void)magnifyWheel:(NSEvent *)theEvent {
    CGFloat dy = [theEvent deltaY];
    dy = dy > 0 ? fmin(0.2, dy) : fmax(-0.2, dy);
    [self setScaleFactor:[self scaleFactor] * exp(0.5 * dy)];
}

- (void)mouseEntered:(NSEvent *)theEvent {
    NSTrackingArea *eventArea = [theEvent trackingArea];
    PDFAnnotation *annotation;
    if ([eventArea owner] == self && [eventArea isEqual:trackingArea]) {
        [[self window] setAcceptsMouseMovedEvents:YES];
    } else if ([eventArea owner] == self && (annotation = [[eventArea userInfo] objectForKey:SKAnnotationKey])) {
        [[SKImageToolTipWindow sharedToolTipWindow] showForImageContext:annotation atPoint:NSZeroPoint];
    } else if ([[SKPDFView superclass] instancesRespondToSelector:_cmd]) {
        [super mouseEntered:theEvent];
    }
}
 
- (void)mouseExited:(NSEvent *)theEvent {
    NSTrackingArea *eventArea = [theEvent trackingArea];
    PDFAnnotation *annotation;
    if ([eventArea owner] == self && [eventArea isEqual:trackingArea]) {
        [[self window] setAcceptsMouseMovedEvents:([self interactionMode] == SKLegacyFullScreenMode)];
        [[NSCursor arrowCursor] set];
        if (toolMode == SKMagnifyToolMode && [loupeWindow parentWindow]) {
            [NSCursor unhide];
            [[self window] removeChildWindow:loupeWindow];
            [loupeWindow orderOut:nil];
        }
    } else if ([eventArea owner] == self && (annotation = [[eventArea userInfo] objectForKey:SKAnnotationKey])) {
        if ([annotation isEqual:[[SKImageToolTipWindow sharedToolTipWindow] currentImageContext]])
            [[SKImageToolTipWindow sharedToolTipWindow] fadeOut];
    } else if ([[SKPDFView superclass] instancesRespondToSelector:_cmd]) {
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
    if ([theEvent phase] == NSEventPhaseBegan) {
        PDFPage *page = [self pageAndPoint:NULL forEvent:theEvent nearest:YES];
        gestureRotation = 0.0;
        gesturePageIndex = [(page ?: [self currentPage]) pageIndex];
    }
    gestureRotation -= [theEvent rotation];
    if (fabs(gestureRotation) > 45.0 && gesturePageIndex != NSNotFound) {
        [self rotatePageAtIndex:gesturePageIndex by:90.0 * round(gestureRotation / 90.0)];
        gestureRotation -= 90.0 * round(gestureRotation / 90.0);
    }
    if (([theEvent phase] == NSEventPhaseEnded || [theEvent phase] == NSEventPhaseCancelled)) {
         gestureRotation = 0.0;
        gesturePageIndex = NSNotFound;
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
                if ([annotation isSkimNote] && [annotation hitTest:location] &&
                    ([pboard canReadItemWithDataConformingToTypes:[NSArray arrayWithObjects:NSPasteboardTypeColor, nil]] || [annotation hasBorder])) {
                    if ([annotation isEqual:highlightAnnotation] == NO) {
                        if (highlightAnnotation)
                            [self setNeedsDisplayForAnnotation:highlightAnnotation];
                        [self setHighlightAnnotation:annotation];
                        [self setNeedsDisplayForAnnotation:highlightAnnotation];
                    }
                    dragOp = NSDragOperationGeneric;
                    break;
                }
            }
        }
        if (dragOp == NSDragOperationNone && highlightAnnotation) {
            [self setNeedsDisplayForAnnotation:highlightAnnotation];
            [self setHighlightAnnotation:nil];
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
            [self setHighlightAnnotation:nil];
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
            if ([pboard canReadItemWithDataConformingToTypes:[NSArray arrayWithObjects:NSPasteboardTypeColor, nil]]) {
                BOOL isShift = ([NSEvent standardModifierFlags] & NSShiftKeyMask) != 0;
                BOOL isAlt = ([NSEvent standardModifierFlags] & NSAlternateKeyMask) != 0;
                [highlightAnnotation setColor:[NSColor colorFromPasteboard:pboard] alternate:isAlt updateDefaults:isShift];
                performedDrag = YES;
            } else if ([highlightAnnotation hasBorder]) {
                [pboard types];
                NSDictionary *dict = [pboard propertyListForType:SKPasteboardTypeLineStyle];
                NSNumber *number;
                if ((number = [dict objectForKey:SKLineWellLineWidthKey]))
                    [highlightAnnotation setLineWidth:[number doubleValue]];
                [highlightAnnotation setDashPattern:[dict objectForKey:SKLineWellDashPatternKey]];
                if ((number = [dict objectForKey:SKLineWellStyleKey]))
                    [highlightAnnotation setBorderStyle:[number integerValue]];
                if ([highlightAnnotation isLine]) {
                    if ((number = [dict objectForKey:SKLineWellStartLineStyleKey]))
                        [(PDFAnnotationLine *)highlightAnnotation setStartLineStyle:[number integerValue]];
                    if ((number = [dict objectForKey:SKLineWellEndLineStyleKey]))
                        [(PDFAnnotationLine *)highlightAnnotation setEndLineStyle:[number integerValue]];
                }
                performedDrag = YES;
            }
            [self setNeedsDisplayForAnnotation:highlightAnnotation];
            [self setHighlightAnnotation:nil];
        }
    } else if ([[SKPDFView superclass] instancesRespondToSelector:_cmd]) {
        performedDrag = [super performDragOperation:sender];
    }
    return performedDrag;
}

#pragma mark Services

- (BOOL)writeSelectionToPasteboard:(NSPasteboard *)pboard types:(NSArray *)types {
    if ([self toolMode] == SKSelectToolMode && NSIsEmptyRect(selectionRect) == NO && selectionPageIndex != NSNotFound) {
        NSMutableArray *writeTypes = [NSMutableArray array];
        NSString *pdfType = nil;
        NSData *pdfData = nil;
        NSString *tiffType = nil;
        NSData *tiffData = nil;
        NSRect selRect = NSIntegralRect(selectionRect);
        
        // Unfortunately only old PboardTypes are requested rather than preferred UTIs, even if we only validate and the Service only requests UTIs, so we need to support both
        if ([[self document] allowsPrinting] && [[self document] isLocked] == NO) {
            if ([types containsObject:NSPasteboardTypePDF])
                pdfType = NSPasteboardTypePDF;
            else if ([types containsObject:NSPDFPboardType])
                pdfType = NSPDFPboardType;
            if (pdfType && (pdfData = [[self currentSelectionPage] PDFDataForRect:selRect]))
                [writeTypes addObject:pdfType];
        }
        if ([types containsObject:NSPasteboardTypeTIFF])
            tiffType = NSPasteboardTypeTIFF;
        else if ([types containsObject:NSTIFFPboardType])
            tiffType = NSTIFFPboardType;
        if (tiffType && (tiffData = [[self currentSelectionPage] TIFFDataForRect:selRect]))
            [writeTypes addObject:tiffType];
        if ([writeTypes count] > 0) {
            [pboard declareTypes:writeTypes owner:nil];
            if (pdfData)
                [pboard setData:pdfData forType:pdfType];
            if (tiffData)
                [pboard setData:tiffData forType:tiffType];
            return YES;
        }
    }
    if ([[self currentSelection] hasCharacters]) {
        if ([types containsObject:NSPasteboardTypeRTF] || [types containsObject:NSRTFPboardType]) {
            [pboard clearContents];
            [pboard writeObjects:[NSArray arrayWithObjects:[[self currentSelection] attributedString], nil]];
            return YES;
        } else if ([types containsObject:NSPasteboardTypeString] || [types containsObject:NSStringPboardType]) {
            [pboard clearContents];
            [pboard writeObjects:[NSArray arrayWithObjects:[[self currentSelection] string], nil]];
            return YES;
        }
    }
    if ([[SKPDFView superclass] instancesRespondToSelector:_cmd])
        return [super writeSelectionToPasteboard:pboard types:types];
    return NO;
}

- (id)validRequestorForSendType:(NSString *)sendType returnType:(NSString *)returnType {
    if ([self toolMode] == SKSelectToolMode && NSIsEmptyRect(selectionRect) == NO && selectionPageIndex != NSNotFound && returnType == nil && 
        (([[self document] allowsPrinting] && [[self document] isLocked] == NO && [sendType isEqualToString:NSPasteboardTypePDF]) || [sendType isEqualToString:NSPasteboardTypeTIFF])) {
        return self;
    }
    if ([[self currentSelection] hasCharacters] && returnType == nil && ([sendType isEqualToString:NSPasteboardTypeString] || [sendType isEqualToString:NSPasteboardTypeRTF])) {
        return self;
    }
    return [super validRequestorForSendType:sendType returnType:returnType];
}

#pragma mark Annotation management

- (void)addAnnotation:(id)sender {
    [self addAnnotationWithType:[sender tag] selection:nil point:[sender representedObject]];
}

- (void)addAnnotationWithType:(SKNoteType)annotationType {
    [self addAnnotationWithType:annotationType selection:nil point:nil];
}

- (void)addAnnotationWithType:(SKNoteType)annotationType selection:(PDFSelection *)selection {
    [self addAnnotationWithType:annotationType selection:selection point:nil];
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

- (void)addAnnotationWithType:(SKNoteType)annotationType selection:(PDFSelection *)selection point:(NSValue *)pointValue {
	PDFPage *page = nil;
	NSRect bounds = NSZeroRect;
    BOOL noSelection = selection == nil;
    BOOL isMarkup = (annotationType == SKHighlightNote || annotationType == SKUnderlineNote || annotationType == SKStrikeOutNote);
    
    if (noSelection)
        selection = [self currentSelection];
	page = [selection safeFirstPage];
    
	if (isMarkup) {
        
        // add new markup to the active markup if it's the same type on the same page, unless we add a specific selection
        if (noSelection && page && [[activeAnnotation page] isEqual:page] &&
            [[activeAnnotation type] isEqualToString:(annotationType == SKHighlightNote ? SKNHighlightString : annotationType == SKUnderlineNote ? SKNUnderlineString : annotationType == SKStrikeOutNote ? SKNStrikeOutString : nil)]) {
            selection = [[selection copy] autorelease];
            [selection addSelection:[(PDFAnnotationMarkup *)activeAnnotation selection]];
            [self removeActiveAnnotation:nil];
        }
        
    } else if (page) {
        
		// Get bounds (page space) for selection (first page in case selection spans multiple pages)
		bounds = [selection boundsForPage:page];
        if (annotationType == SKCircleNote) {
            CGFloat dw, dh, w = NSWidth(bounds), h = NSHeight(bounds);
            if (h < w) {
                dw = primaryOutset(h / w);
                dh = secondaryOutset(dw);
            } else {
                dh = primaryOutset(w / h);
                dw = secondaryOutset(dh);
            }
            CGFloat lw = [[NSUserDefaults standardUserDefaults] doubleForKey:SKCircleNoteLineWidthKey];
            bounds = NSInsetRect(bounds, -0.5 * w * dw - lw, -0.5 * h * dh - lw);
        } else if (annotationType == SKSquareNote) {
            CGFloat lw = [[NSUserDefaults standardUserDefaults] doubleForKey:SKSquareNoteLineWidthKey];
            bounds = NSInsetRect(bounds, -lw, -lw);
        } else if (annotationType == SKAnchoredNote) {
            switch ([page intrinsicRotation]) {
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
        
	} else {
        
		// First try the current mouse position
        NSPoint center = pointValue ? [pointValue pointValue] : [self convertPoint:[[self window] mouseLocationOutsideOfEventStream] fromView:nil];
        
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
    
    if (page != nil && [self addAnnotationWithType:annotationType selection:selection page:page bounds:bounds]) {
        if (annotationType == SKAnchoredNote || annotationType == SKFreeTextNote)
            [self editActiveAnnotation:self];
        else if (isMarkup && noSelection)
            [self setCurrentSelection:nil];
    } else NSBeep();
}

- (BOOL)addAnnotationWithType:(SKNoteType)annotationType selection:(PDFSelection *)selection page:(PDFPage *)page bounds:(NSRect)bounds {
    PDFAnnotation *newAnnotation = nil;
    NSArray *newAnnotations = nil;
    NSString *text = [selection cleanedString];
    BOOL isInitial = NSEqualSizes(bounds.size, NSZeroSize) && selection == nil;
    
    // new note added by note tool mode, don't add actual zero sized notes
    if (isInitial)
        bounds = annotationType == SKAnchoredNote ? SKRectFromCenterAndSize(bounds.origin, SKNPDFAnnotationNoteSize) : SKRectFromCenterAndSquareSize(bounds.origin, MIN_NOTE_SIZE);
    
	// Create annotation and add to page.
    switch (annotationType) {
        case SKFreeTextNote:
            newAnnotation = [[PDFAnnotationFreeText alloc] initSkimNoteWithBounds:bounds];
            break;
        case SKAnchoredNote:
            newAnnotation = [[SKNPDFAnnotationNote alloc] initSkimNoteWithBounds:bounds];
            break;
        case SKCircleNote:
            newAnnotation = [[PDFAnnotationCircle alloc] initSkimNoteWithBounds:bounds];
            break;
        case SKSquareNote:
            newAnnotation = [[PDFAnnotationSquare alloc] initSkimNoteWithBounds:bounds];
            break;
        case SKHighlightNote:
            newAnnotations = [PDFAnnotationMarkup SkimNotesAndPagesWithSelection:selection markupType:kPDFMarkupTypeHighlight];
            break;
        case SKUnderlineNote:
            newAnnotations = [PDFAnnotationMarkup SkimNotesAndPagesWithSelection:selection markupType:kPDFMarkupTypeUnderline];
            break;
        case SKStrikeOutNote:
            newAnnotations = [PDFAnnotationMarkup SkimNotesAndPagesWithSelection:selection markupType:kPDFMarkupTypeStrikeOut];
            break;
        case SKLineNote:
            newAnnotation = [[PDFAnnotationLine alloc] initSkimNoteWithBounds:bounds];
            break;
        case SKInkNote:
            // we need a drawn path to add an ink note
            break;
	}
    
    if ([newAnnotations count] == 1) {
        newAnnotation = [[[newAnnotations firstObject] firstObject] retain];
        page = [[newAnnotations firstObject] lastObject];
        newAnnotations = nil;
    }
    
    if ([newAnnotations count] > 0) {
        for (NSArray *annotationAndPage in newAnnotations) {
            newAnnotation = [annotationAndPage firstObject];
            page = [annotationAndPage lastObject];
            if ([text length] > 0 || [newAnnotation string] == nil)
                [newAnnotation setString:text ?: @""];
            [newAnnotation registerUserName];
            [self addAnnotation:newAnnotation toPage:page];
            if ([text length] == 0 && isInitial == NO)
                [newAnnotation autoUpdateString];
        }
        [[self undoManager] setActionName:NSLocalizedString(@"Add Note", @"Undo action name")];

        [self setActiveAnnotation:newAnnotation];
        
        return YES;
    } else if (newAnnotation) {
        if (annotationType != SKLineNote && annotationType != SKInkNote && [text length] > 0)
            [newAnnotation setString:text];
        [newAnnotation registerUserName];
        [self addAnnotation:newAnnotation toPage:page];
        if ([text length] == 0 && isInitial == NO)
            [newAnnotation autoUpdateString];
        if ([newAnnotation string] == nil)
            [newAnnotation setString:@""];
        [[self undoManager] setActionName:NSLocalizedString(@"Add Note", @"Undo action name")];

        [self setActiveAnnotation:newAnnotation];
        [newAnnotation release];
        
        return YES;
    } else {
        return NO;
    }
}

- (void)addAnnotation:(PDFAnnotation *)annotation toPage:(PDFPage *)page {
    [self beginNewUndoGroupIfNeeded];
    
    [[[self undoManager] prepareWithInvocationTarget:self] removeAnnotation:annotation];
    [annotation setShouldDisplay:hideNotes == NO || [annotation isSkimNote] == NO];
    [annotation setShouldPrint:hideNotes == NO || [annotation isSkimNote] == NO];
    [page addAnnotation:annotation];
    [self setNeedsDisplayForAnnotation:annotation];
    [self annotationsChangedOnPage:page];
    [self resetPDFToolTipRects];
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
    
    if (annotation)
        [self removeAnnotation:annotation];
}

- (void)removeAnnotation:(PDFAnnotation *)annotation {
    [self beginNewUndoGroupIfNeeded];
    
    PDFAnnotation *wasAnnotation = [annotation retain];
    PDFPage *page = [[wasAnnotation page] retain];
    
    [[[self undoManager] prepareWithInvocationTarget:self] addAnnotation:wasAnnotation toPage:page];
	if (activeAnnotation == annotation)
		[self setActiveAnnotation:nil];
    [self setNeedsDisplayForAnnotation:wasAnnotation];
    [page removeAnnotation:wasAnnotation];
    [self annotationsChangedOnPage:page];
    if ([wasAnnotation isNote]) {
        if (RUNNING(10_12) && [[page annotations] containsObject:wasAnnotation])
            [page removeAnnotation:wasAnnotation];
        [self resetPDFToolTipRects];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewDidRemoveAnnotationNotification object:self
        userInfo:[NSDictionary dictionaryWithObjectsAndKeys:wasAnnotation, SKPDFViewAnnotationKey, page, SKPDFViewPageKey, nil]];
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
    [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewDidMoveAnnotationNotification object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:oldPage, SKPDFViewOldPageKey, page, SKPDFViewNewPageKey, annotation, SKPDFViewAnnotationKey, nil]];                
    [oldPage release];
}

- (void)editThisAnnotation:(id)sender {
    [self editAnnotation:[sender representedObject]];
}

- (void)editAnnotation:(PDFAnnotation *)annotation {
    if (annotation == nil || [self isEditingAnnotation:annotation])
        return;
    
    if (activeAnnotation != annotation)
        [self setActiveAnnotation:annotation];
    [self editActiveAnnotation:nil];
}

- (void)editActiveAnnotation:(id)sender {
    if (nil == activeAnnotation || [self isEditingAnnotation:activeAnnotation])
        return;
    
    [self commitEditing];
    
    if ([activeAnnotation isLink]) {
        
        [[SKImageToolTipWindow sharedToolTipWindow] orderOut:self];
        PDFDestination *dest = [activeAnnotation linkDestination];
        NSURL *url;
        if (dest)
            [self goToDestination:dest];
        else if ((url = [activeAnnotation linkURL]))
            [[NSWorkspace sharedWorkspace] openURL:url];
        [self setActiveAnnotation:nil];
        
    } else if (hideNotes == NO && [activeAnnotation isText]) {
        
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

- (void)beginNewUndoGroupIfNeeded {
    if (wantsNewUndoGroup) {
        NSUndoManager *undoManger = [self undoManager];
        if ([undoManger groupingLevel] > 0) {
            [undoManger endUndoGrouping];
            [undoManger beginUndoGrouping];
        }
    }
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
            point = [self convertPoint:point fromPage:[annotation page]];
            point = [self convertPointToScreen:NSMakePoint(round(point.x), round(point.y))];
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
            point = [self convertPoint:point fromPage:[annotation page]] ;
            point = [self convertPointToScreen:NSMakePoint(round(point.x), round(point.y))];
            [[SKImageToolTipWindow sharedToolTipWindow] showForImageContext:annotation atPoint:point];
        } else {
            [[SKImageToolTipWindow sharedToolTipWindow] orderOut:self];
        }
    }
}

- (BOOL)isEditingAnnotation:(PDFAnnotation *)annotation {
    return editor && activeAnnotation == annotation;
}

- (void)scrollAnnotationToVisible:(PDFAnnotation *)annotation {
    [self goToRect:[annotation bounds] onPage:[annotation page]];
}

- (void)setNeedsDisplayForAnnotation:(PDFAnnotation *)annotation onPage:(PDFPage *)page {
    NSRect rect = [annotation displayRect];
    if (annotation == activeAnnotation) {
        CGFloat margin = ([annotation isResizable] ? HANDLE_SIZE  : 1.0) / [self scaleFactor];
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
        NSRect lineRect = [sel hasCharacters] ? [sel boundsForPage:page] : SKRectFromCenterAndSquareSize(point, 10.0);
        NSRect rect = lineRect;
        NSRect visibleRect;
        BOOL wasPageDisplayed = NSLocationInRange(pageIndex, [self displayedPageIndexRange]);
        
        if (wasPageDisplayed == NO)
            [self goToPage:page];
        
        if (interactionMode != SKPresentationMode) {
            if (showBar) {
                BOOL invert = [[NSUserDefaults standardUserDefaults] boolForKey:SKReadingBarInvertKey];
                PDFPage *oldPage = nil;
                NSRect oldRect = NSZeroRect;
                if ([self hasReadingBar] == NO) {
                    SKReadingBar *aReadingBar = [[SKReadingBar alloc] initWithPage:page];
                    if (NO == [aReadingBar goToLineForPoint:point])
                        [aReadingBar goToNextLine];
                    [self setReadingBar:aReadingBar];
                    [aReadingBar release];
                    if (invert)
                        [self requiresDisplay];
                    else
                        [self setNeedsDisplayInRect:[readingBar currentBoundsForBox:[self displayBox]] ofPage:[readingBar page]];
                } else {
                    oldPage = [readingBar page];
                    oldRect = [readingBar currentBoundsForBox:[self displayBox]];
                    [readingBar setPage:page];
                    if (NO == [readingBar goToLineForPoint:point])
                        [readingBar goToNextLine];
                    [self setNeedsDisplayInRect:oldRect ofPage:oldPage];
                    [self setNeedsDisplayInRect:[readingBar currentBoundsForBox:[self displayBox]] ofPage:[readingBar page]];
                }
                NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[readingBar page], SKPDFViewNewPageKey, oldPage, SKPDFViewOldPageKey, nil];
                [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewReadingBarDidChangeNotification object:self userInfo:userInfo];
            } else if ([sel hasCharacters] && [self toolMode] == SKTextToolMode) {
                [self setCurrentSelection:sel];
            }
        }
        
        visibleRect = [self convertRect:[self visibleContentRect] toPage:page];
        
        if (wasPageDisplayed == NO || NSContainsRect(visibleRect, lineRect) == NO) {
            if ([self displayMode] == kPDFDisplaySinglePageContinuous || [self displayMode] == kPDFDisplayTwoUpContinuous)
                rect = NSInsetRect(lineRect, 0.0, - floor( ( NSHeight(visibleRect) - NSHeight(rect) ) / 2.0 ) );
            if (NSWidth(rect) > NSWidth(visibleRect)) {
                if (NSMaxX(rect) < point.x + 0.5 * NSWidth(visibleRect))
                    rect.origin.x = NSMaxX(rect) - NSWidth(visibleRect);
                else if (NSMinX(rect) < point.x - 0.5 * NSWidth(visibleRect))
                    rect.origin.x = floor( point.x - 0.5 * NSWidth(visibleRect) );
                rect.size.width = NSWidth(visibleRect);
            }
            rect = [self convertRect:[self convertRect:rect fromPage:page] toView:[self documentView]];
            [[self documentView] scrollRectToVisible:rect];
        }
        
        [syncDot invalidate];
        [self setSyncDot:[[[SKSyncDot alloc] initWithPoint:point page:page updateHandler:^(BOOL finished){
                [self setNeedsDisplayInRect:[syncDot bounds] ofPage:[syncDot page]];
                if (finished)
                    [self setSyncDot:nil];
            }] autorelease]];
    }
}

#pragma mark Snapshots

- (void)takeSnapshot:(id)sender {
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
        // the represented object should be the location for the menu event
        point = [sender representedObject] ? [[sender representedObject] pointValue] : [self convertPoint:[[self window] mouseLocationOutsideOfEventStream] fromView:nil];
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

#pragma mark Zooming

- (void)zoomToRect:(NSRect)rect onPage:(PDFPage *)page {
    if (NSIsEmptyRect(rect) == NO) {
        CGFloat scrollerWidth = [NSScroller effectiveScrollerWidth];
        NSRect bounds = [self bounds];
        CGFloat scale = 1.0;
        bounds.size.width -= scrollerWidth;
        bounds.size.height -= scrollerWidth;
        if (NSWidth(bounds) * NSHeight(rect) > NSWidth(rect) * NSHeight(bounds))
            scale = NSHeight(bounds) / NSHeight(rect);
        else
            scale = NSWidth(bounds) / NSWidth(rect);
        [self setScaleFactor:scale];
        NSScrollView *scrollView = [self scrollView];
        if (scrollerWidth > 0.0 && ([scrollView hasHorizontalScroller] == NO || [scrollView hasVerticalScroller] == NO)) {
            if ([scrollView hasVerticalScroller])
                bounds.size.width -= scrollerWidth;
            if ([scrollView hasHorizontalScroller])
                bounds.size.height -= scrollerWidth;
            if (NSWidth(bounds) * NSHeight(rect) > NSWidth(rect) * NSHeight(bounds))
                scale = NSHeight(bounds) / NSHeight(rect);
            else
                scale = NSWidth(bounds) / NSWidth(rect);
            [self setScaleFactor:scale];
        }
        [self goToRect:rect onPage:page];
    }
}

#pragma mark Notification handling

- (void)handlePageChangedNotification:(NSNotification *)notification {
    if ([self displayMode] == kPDFDisplaySinglePage || [self displayMode] == kPDFDisplayTwoUp) {
        [editor layout];
        [self resetPDFToolTipRects];
        if (toolMode == SKMagnifyToolMode && [loupeWindow parentWindow])
            [self updateMagnifyWithEvent:nil];
    }
}

- (void)handleScaleChangedNotification:(NSNotification *)notification {
    [self resetPDFToolTipRects];
}

- (void)handlePDFContentViewFrameChangedNotification:(NSNotification *)notification {
    if (toolMode == SKMagnifyToolMode && [loupeWindow parentWindow])
        [self performSelectorOnce:@selector(updateMagnifyWithEvent:) afterDelay:0.0];
}

- (void)handleUndoGroupOpenedOrClosedNotification:(NSNotification *)notification {
    if ([notification object] == [self undoManager])
        wantsNewUndoGroup = NO;
}

- (void)handleScrollerStyleChangedNotification:(NSNotification *)notification {
    if ([NSScroller preferredScrollerStyle] == NSScrollerStyleLegacy)
        SKSetHasDefaultAppearance(self);
    else
        SKSetHasLightAppearance(self);
}

- (void)handleKeyStateChangedNotification:(NSNotification *)notification {
    if (selectionPageIndex != NSNotFound) {
        CGFloat margin = HANDLE_SIZE / [self scaleFactor];
        for (PDFPage *page in [self displayedPages])
            [self setNeedsDisplayInRect:NSInsetRect(selectionRect, -margin, -margin) ofPage:page];
    }
    if (activeAnnotation)
        [self setNeedsDisplayForAnnotation:activeAnnotation];
}

#pragma mark Key and window changes

- (void)viewWillMoveToWindow:(NSWindow *)newWindow {
    if (editor && [self commitEditing] == NO)
        [self discardEditing];
    
    if (loupeWindow)
        [self removeLoupeWindow];
    
    if (RUNNING_BEFORE(10_13)) {
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
    }
    
    [super viewWillMoveToWindow:newWindow];
}

- (BOOL)becomeFirstResponder {
    NSTextField *textField = [self subviewOfClass:[NSTextField class]];
    if ([textField isEditable]) {
        [textField selectText:nil];
        if (RUNNING_BEFORE(10_13))
            [self handleKeyStateChangedNotification:nil];
        return YES;
    }
    
    if ([super becomeFirstResponder]) {
        if (RUNNING_BEFORE(10_13))
            [self handleKeyStateChangedNotification:nil];
        return YES;
    }
    return NO;
}

- (BOOL)resignFirstResponder {
    if ([super resignFirstResponder]) {
        if (RUNNING_BEFORE(10_13))
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
            [menuItem setState:[self toolMode] == SKNoteToolMode && [self annotationMode] == (SKNoteType)[menuItem tag] ? NSOnState : NSOffState];
        else
            [menuItem setState:[self annotationMode] == (SKNoteType)[menuItem tag] ? NSOnState : NSOffState];
        return YES;
    } else if (action == @selector(copy:)) {
        if ([[self currentSelection] hasCharacters])
            return YES;
        if ([activeAnnotation isSkimNote] && [activeAnnotation isMovable])
            return YES;
        if (toolMode == SKSelectToolMode && NSIsEmptyRect(selectionRect) == NO && selectionPageIndex != NSNotFound && [[self document] isLocked] == NO)
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
    } else if (action == @selector(zoomToPhysicalSize:)) {
        [menuItem setState:([self autoScales] || fabs([self physicalScaleFactor] - 1.0 ) > 0.01) ? NSOffState : NSOnState];
        return YES;
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
                if ([key isEqualToString:SKReadingBarInvertKey] || [[NSUserDefaults standardUserDefaults] boolForKey:SKReadingBarInvertKey])
                    [self requiresDisplay];
                else
                    [self setNeedsDisplayInRect:[readingBar currentBoundsForBox:[self displayBox]] ofPage:[readingBar page]];
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

- (void)enableNavigation {
    navigationMode = [[NSUserDefaults standardUserDefaults] integerForKey:interactionMode == SKPresentationMode ? SKPresentationNavigationOptionKey : SKFullScreenNavigationOptionKey];
    
    if (navigationMode != SKNavigationNone)
        navWindow = [[SKNavigationWindow alloc] initWithPDFView:self];
    
    [self performSelectorOnce:@selector(doAutoHide) afterDelay:AUTO_HIDE_DELAY];
}

- (void)disableNavigation {
    navigationMode = SKNavigationNone;
    
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(showNavWindow) object:nil];
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(doAutoHide) object:nil];
    if (navWindow) {
        [navWindow remove];
        SKDESTROY(navWindow);
    }
}

- (void)doAutoHide {
    if ([navWindow isVisible] && NSPointInRect([NSEvent mouseLocation], [navWindow frame]))
        return;
    if (interactionMode == SKLegacyFullScreenMode || interactionMode == SKPresentationMode) {
        if (interactionMode == SKPresentationMode) {
            [[NSCursor emptyCursor] set];
            cursorHidden = YES;
            [NSCursor setHiddenUntilMouseMoves:YES];
        }
        [navWindow fadeOut];
    }
}

- (void)showNavWindow {
    if ([navWindow isVisible] == NO && [[self window] mouseLocationOutsideOfEventStream].y < NAVIGATION_BOTTOM_EDGE_HEIGHT) {
        if ([navWindow parentWindow] == nil) {
            [navWindow setAlphaValue:0.0];
            [[self window] addChildWindow:navWindow ordered:NSWindowAbove];
        }
        [navWindow fadeIn];
    }
}

- (void)performSelectorOnce:(SEL)aSelector afterDelay:(NSTimeInterval)delay {
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:aSelector object:nil];
    [self performSelector:aSelector withObject:nil afterDelay:delay];
}

#pragma mark Event handling

- (NSWindow *)newOverlayLayer:(CALayer *)layer wantsAdded:(BOOL)wantsAdded {
    NSWindow *overlay = nil;
    if (wantsAdded && [self wantsLayer]) {
        [[self layer] addSublayer:layer];
    } else {
        overlay = [[SKAnimatedBorderlessWindow alloc] initWithContentRect:[self convertRectToScreen:[self bounds]]];
        [overlay setIgnoresMouseEvents:YES];
        [[overlay contentView] setWantsLayer:YES];
        [[[overlay contentView] layer] addSublayer:layer];
        if (wantsAdded)
            [[self window] addChildWindow:overlay ordered:NSWindowAbove];
    }
    return overlay;
}

- (void)removeLayer:(CALayer *)layer overlay:(NSWindow *)overlay {
    if (overlay) {
        [[self window] removeChildWindow:overlay];
        [overlay orderOut:nil];
    } else {
        [layer removeFromSuperlayer];
    }
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
            [annotation setObservedStartPoint:startPoint];
            [annotation setObservedEndPoint:endPoint];
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
    PDFPage *oldPage = [readingBar page];
    NSRect oldBounds = [readingBar currentBoundsForBox:[self displayBox]];
    BOOL moved = NO;
    if (eventChar == NSDownArrowFunctionKey)
        moved = [readingBar goToNextLine];
    else if (eventChar == NSUpArrowFunctionKey)
        moved = [readingBar goToPreviousLine];
    else if (eventChar == NSRightArrowFunctionKey)
        moved = [readingBar goToNextPage];
    else if (eventChar == NSLeftArrowFunctionKey)
        moved = [readingBar goToPreviousPage];
    if (moved) {
        PDFPage *newPage = [readingBar page];
        NSRect newBounds = [readingBar currentBoundsForBox:[self displayBox]];
        NSRect rect = [readingBar currentBounds];
        NSInteger lineAngle = [newPage lineDirectionAngle];
        if ((lineAngle % 180)) {
            rect = NSInsetRect(rect, 0.0, -20.0) ;
            if (([self displayMode] & kPDFDisplaySinglePageContinuous)) {
                NSRect visibleRect = [self convertRect:[self visibleContentRect] toPage:newPage];
                rect = NSInsetRect(rect, 0.0, - floor( ( NSHeight(visibleRect) - NSHeight(rect) ) / 2.0 ) );
                if (NSWidth(rect) <= NSWidth(visibleRect)) {
                    if (NSMinX(rect) > NSMinX(visibleRect))
                        rect.origin.x = fmax(NSMinX(visibleRect), NSMaxX(rect) - NSWidth(visibleRect));
                } else if (lineAngle == 90) {
                    rect.origin.x = NSMaxX(rect) - NSWidth(visibleRect);
                }
                rect.size.width = NSWidth(visibleRect);
            }
        } else {
            rect = NSInsetRect(rect, -20.0, 0.0) ;
            if (([self displayMode] & kPDFDisplaySinglePageContinuous)) {
                NSRect visibleRect = [self convertRect:[self visibleContentRect] toPage:newPage];
                rect = NSInsetRect(rect, - floor( ( NSWidth(visibleRect) - NSWidth(rect) ) / 2.0 ), 0.0 );
                if (NSHeight(rect) <= NSHeight(visibleRect)) {
                    if (NSMinY(rect) > NSMinY(visibleRect))
                        rect.origin.y = fmax(NSMinY(visibleRect), NSMaxY(rect) - NSHeight(visibleRect));
                } else if (lineAngle == 180) {
                    rect.origin.y = NSMaxY(rect) - NSHeight(visibleRect);
                }
                rect.size.height = NSHeight(visibleRect);
            }
        }
        [self goToRect:rect onPage:newPage];
        if ([oldPage isEqual:newPage]) {
            [self setNeedsDisplayInRect:NSUnionRect(oldBounds, newBounds) ofPage:oldPage];
        } else {
            [self setNeedsDisplayInRect:oldBounds ofPage:oldPage];
            [self setNeedsDisplayInRect:newBounds ofPage:newPage];
        }
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:oldPage, SKPDFViewOldPageKey, newPage, SKPDFViewNewPageKey, nil];
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
        PDFPage *page = [readingBar page];
        NSRect rect = [readingBar currentBoundsForBox:[self displayBox]];
        [readingBar setNumberOfLines:numberOfLines];
        [self setNeedsDisplayInRect:NSUnionRect(rect, [readingBar currentBoundsForBox:[self displayBox]]) ofPage:page];
        [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewReadingBarDidChangeNotification object:self 
            userInfo:[NSDictionary dictionaryWithObjectsAndKeys:page, SKPDFViewOldPageKey, page, SKPDFViewNewPageKey, nil]];
    }
}

- (void)doMoveAnnotationWithEvent:(NSEvent *)theEvent offset:(NSPoint)offset {
    // Move annotation.
    [[[self scrollView] contentView] autoscroll:theEvent];
    
    NSPoint point = NSZeroPoint;
    PDFPage *newActivePage = [self pageAndPoint:&point forEvent:theEvent nearest:YES];
    
    if (newActivePage) { // newActivePage should never be nil, but just to be sure
        if (newActivePage != [activeAnnotation page]) {
            // move the annotation to the new page
            [self moveAnnotation:activeAnnotation toPage:newActivePage];
        }
        
        NSRect newBounds = [activeAnnotation bounds];
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
    
    if (NSEqualPoints(startPoint, endPoint) == NO) {
        NSRect newBounds = SKIntegralRectFromPoints(startPoint, endPoint);
        
        if (NSWidth(newBounds) < MIN_NOTE_SIZE) {
            newBounds.size.width = MIN_NOTE_SIZE;
            newBounds.origin.x = floor(0.5 * ((startPoint.x + endPoint.x) - MIN_NOTE_SIZE));
        }
        if (NSHeight(newBounds) < MIN_NOTE_SIZE) {
            newBounds.size.height = MIN_NOTE_SIZE;
            newBounds.origin.y = floor(0.5 * ((startPoint.y + endPoint.y) - MIN_NOTE_SIZE));
        }
        
        [(PDFAnnotationLine *)activeAnnotation setObservedStartPoint:SKSubstractPoints(startPoint, newBounds.origin)];
        [(PDFAnnotationLine *)activeAnnotation setObservedEndPoint:SKSubstractPoints(endPoint, newBounds.origin)];
        [activeAnnotation setBounds:newBounds];
    }
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
            [self setCursorForAreaOfInterest:SKAreaOfInterestForResizeHandle(resizeHandle, page)];
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

- (void)updateCursorForMouse:(NSEvent *)theEvent {
    [self setCursorForAreaOfInterest:[self areaOfInterestForMouse:theEvent]];
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
            [self addAnnotationWithType:SKAnchoredNote selection:nil page:page bounds:SKRectFromCenterAndSquareSize(SKIntegralPoint(pagePoint), 0.0)];
            originalBounds = [[self activeAnnotation] bounds];
        } else {
            originalBounds = SKRectFromCenterAndSquareSize(SKIntegralPoint(pagePoint), 0.0);
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
    
    [self setCursorForAreaOfInterest:SKAreaOfInterestForResizeHandle(resizeHandle, page)];
    if (resizeHandle == 0) {
        [NSEvent startPeriodicEventsAfterDelay:0.1 withPeriod:0.1];
        eventMask |= NSPeriodicMask;
    }
    
    while (YES) {
        theEvent = [[self window] nextEventMatchingMask:eventMask];
        if ([theEvent type] == NSLeftMouseUp) {
            break;
        } else if ([theEvent type] == NSLeftMouseDragged) {
            if (activeAnnotation == nil) {
                [self addAnnotationWithType:annotationMode selection:nil page:page bounds:SKRectFromCenterAndSquareSize(originalBounds.origin, 0.0)];
            }
            lastMouseEvent = theEvent;
            draggedAnnotation = YES;
        } else if (activeAnnotation == nil) {
            continue;
        }
        [self beginNewUndoGroupIfNeeded];
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
        
        if (shouldAddAnnotation && toolMode == SKNoteToolMode && (annotationMode == SKAnchoredNote || annotationMode == SKFreeTextNote))
            [self editActiveAnnotation:self]; 	 
        
        [self setNeedsDisplayForAnnotation:activeAnnotation];
    }
    
    // ??? PDFView's delayed layout seems to reset the cursor to an arrow
    [self performSelector:@selector(setCursorForMouse:) withObject:theEvent afterDelay:0];
}

- (void)doClickLinkWithEvent:(NSEvent *)theEvent {
	PDFAnnotation *annotation = activeAnnotation;
    PDFPage *annotationPage = [annotation page];
    NSRect bounds = [annotation bounds];
    
    while (YES) {
		theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask];
        
        if ([theEvent type] == NSLeftMouseUp)
            break;
        
        NSPoint point = NSZeroPoint;
        PDFPage *page = [self pageAndPoint:&point forEvent:theEvent nearest:NO];
        if (page == annotationPage && NSPointInRect(point, bounds))
            [self setActiveAnnotation:annotation];
        else
            [self setActiveAnnotation:nil];
	}
    
    if (activeAnnotation)
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
        id annotations = RUNNING(10_12) ? [page annotations] : [[page annotations] reverseObjectEnumerator];
        
        // Hit test for annotation.
        for (PDFAnnotation *annotation in annotations) {
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
    
    if (hideNotes == NO && [[self document] allowsNotes] && page != nil && newActiveAnnotation != nil) {
        BOOL isInk = toolMode == SKNoteToolMode && annotationMode == SKInkNote;
        NSUInteger modifiers = [theEvent modifierFlags];
        if ((modifiers & NSAlternateKeyMask) && [newActiveAnnotation isMovable] &&
            [newActiveAnnotation resizeHandleForPoint:point scaleFactor:[self scaleFactor]] == 0) {
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
                NSString *string1 = [activeAnnotation string];
                NSString *string2 = [newActiveAnnotation string];
                
                newAnnotation = [[[PDFAnnotationInk alloc] initSkimNoteWithPaths:paths] autorelease];
                [newAnnotation setString:[string2 length] == 0 ? string1 : [string1 length] == 0 ? string2 : [NSString stringWithFormat:@"%@ %@", string1, string2]];
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
        } else if (newActiveAnnotation == activeAnnotation && [activeAnnotation isText] && [theEvent clickCount] == 1 && [NSApp willDragMouse] == NO) {
            [self editActiveAnnotation:self];
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
    BOOL wasMouseCoalescingEnabled = [NSEvent isMouseCoalescingEnabled];
    BOOL isOption = ([theEvent modifierFlags] & NSAlternateKeyMask) != 0;
    BOOL wasOption = NO;
    BOOL wantsBreak = isOption;
    NSBezierPath *bezierPath = nil;
    CAShapeLayer *layer = nil;
    NSWindow *overlay = nil;
    
    NSRect boxBounds = NSIntersectionRect([page boundsForBox:[self displayBox]], [self convertRect:[self visibleContentRect] toPage:page]);
    CGAffineTransform t = CGAffineTransformRotate(CGAffineTransformMakeScale([self scaleFactor], [self scaleFactor]), -M_PI_2 * [page rotation] / 90.0);
    layer = [CAShapeLayer layer];
    // transform and place so that the path is in page coordinates
    [layer setBounds:NSRectToCGRect(boxBounds)];
    [layer setAnchorPoint:CGPointZero];
    [layer setPosition:NSPointToCGPoint([self convertPoint:boxBounds.origin fromPage:page])];
    [layer setAffineTransform:t];
    [layer setZPosition:1.0];
    [layer setMasksToBounds:YES];
    [layer setFillColor:NULL];
    [layer setLineJoin:kCALineJoinRound];
    [layer setLineCap:kCALineCapRound];
    if (([theEvent modifierFlags] & (NSShiftKeyMask | NSAlphaShiftKeyMask)) && [[activeAnnotation type] isEqualToString:SKNInkString] && [[activeAnnotation page] isEqual:page]) {
        [layer setStrokeColor:[[activeAnnotation color] CGColor]];
        [layer setLineWidth:[activeAnnotation lineWidth]];
        if ([activeAnnotation borderStyle] == kPDFBorderStyleDashed) {
            [layer setLineDashPattern:[activeAnnotation dashPattern]];
            [layer setLineCap:kCALineCapButt];
        }
        [layer setShadowRadius:2.0 / [self scaleFactor]];
        [layer setShadowOffset:CGSizeApplyAffineTransform(CGSizeMake(0.0, -2.0), CGAffineTransformInvert(t))];
        [layer setShadowOpacity:0.33333];
    } else {
        [self setActiveAnnotation:nil];
        NSUserDefaults *sud = [NSUserDefaults standardUserDefaults];
        [layer setStrokeColor:[[sud colorForKey:SKInkNoteColorKey] CGColor]];
        [layer setLineWidth:[sud floatForKey:SKInkNoteLineWidthKey]];
        if ((PDFBorderStyle)[sud integerForKey:SKInkNoteLineStyleKey] == kPDFBorderStyleDashed) {
            [layer setLineDashPattern:[sud arrayForKey:SKInkNoteDashPatternKey]];
            [layer setLineCap:kCALineCapButt];
        }
    }
    
    overlay = [self newOverlayLayer:layer wantsAdded:YES];
    
    // don't coalesce mouse event from mouse while drawing,
    // but not from tablets because those fire very rapidly and lead to serious delays
    if ([NSEvent currentPointingDeviceType] == NSUnknownPointingDevice)
        [NSEvent setMouseCoalescingEnabled:NO];
    
    while (YES) {
        theEvent = [window nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSFlagsChangedMask];
        
        if ([theEvent type] == NSLeftMouseUp) {
            
            break;
            
        } else if ([theEvent type] == NSLeftMouseDragged) {
            
            if (bezierPath == nil) {
                bezierPath = [NSBezierPath bezierPath];
                [bezierPath moveToPoint:point];
            } else if (wantsBreak && NO == NSEqualPoints(point, [bezierPath associatedPointForElementAtIndex:[bezierPath elementCount] - 2])) {
                [PDFAnnotationInk addPoint:point toSkimNotesPath:bezierPath];
            }
            
            point = [self convertPoint:[theEvent locationInView:self] toPage:page];
            
            if (isOption && wantsBreak == NO) {
                NSInteger eltCount = [bezierPath elementCount];
                NSPoint points[3] = {point, point, point};
                if (NSCurveToBezierPathElement == [bezierPath elementAtIndex:eltCount - 1]) {
                    points[0] = [bezierPath associatedPointForElementAtIndex:eltCount - 2];
                    points[0].x += ( point.x - points[0].x ) / 3.0;
                    points[0].y += ( point.y - points[0].y ) / 3.0;
                }
                [bezierPath setAssociatedPoints:points atIndex:eltCount - 1];
            } else {
                [PDFAnnotationInk addPoint:point toSkimNotesPath:bezierPath];
            }
            
            wasOption = isOption;
            wantsBreak = NO;
            
            [layer setPath:[bezierPath CGPath]];
            
        } else if ((([theEvent modifierFlags] & NSAlternateKeyMask) != 0) != isOption) {
            
            isOption = isOption == NO;
            wantsBreak = isOption || wasOption;
            
        }
    }
    
    [self removeLayer:layer overlay:overlay];
    [overlay release];
    
    [NSEvent setMouseCoalescingEnabled:wasMouseCoalescingEnabled];
    
    if (bezierPath) {
        NSMutableArray *paths = [[NSMutableArray alloc] init];
        if (activeAnnotation)
            [paths addObjectsFromArray:[(PDFAnnotationInk *)activeAnnotation pagePaths]];
        [paths addObject:bezierPath];
        
        PDFAnnotationInk *annotation = [[PDFAnnotationInk alloc] initSkimNoteWithPaths:paths];
        if (activeAnnotation) {
            [annotation setColor:[activeAnnotation color]];
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
        id annotations = RUNNING(10_12) ? [page annotations] : [[page annotations] reverseObjectEnumerator];
        
        for (PDFAnnotation *annotation in annotations) {
            if ([annotation isSkimNote] && [annotation hitTest:point] && [self isEditingAnnotation:annotation] == NO) {
                [self removeAnnotation:annotation];
                [[self undoManager] setActionName:NSLocalizedString(@"Remove Note", @"Undo action name")];
                break;
            }
        }
    }
}

- (void)doSelectWithEvent:(NSEvent *)theEvent {
    NSPoint initialPoint = NSZeroPoint;
    PDFPage *page = [self pageAndPoint:&initialPoint forEvent:theEvent nearest:NO];
    if (page == nil) {
        // should never get here, see mouseDown:
        [self doDragMouseWithEvent:theEvent];
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
            [self requiresDisplay];
    }
    
	NSRect initialRect = selectionRect;
    NSRect pageBounds = [page boundsForBox:[self displayBox]];
    SKRectEdges newEffectiveResizeHandle, effectiveResizeHandle = resizeHandle;
    
    [self setCursorForAreaOfInterest:SKAreaOfInterestForResizeHandle(resizeHandle, page)];
    
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
                [self setCursorForAreaOfInterest:SKAreaOfInterestForResizeHandle(effectiveResizeHandle, page)];
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
            for (PDFPage *p in [self displayedPages])
                [self setNeedsDisplayInRect:dirtyRect ofPage:p];
        } else {
            [self requiresDisplay];
            didSelect = YES;
        }
        @synchronized (self) {
            selectionRect = newRect;
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewSelectionChangedNotification object:self];
	}
    
    if (NSIsEmptyRect(selectionRect)) {
        @synchronized (self) {
            selectionRect = NSZeroRect;
            selectionPageIndex = NSNotFound;
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewSelectionChangedNotification object:self];
        [self requiresDisplay];
    } else if (resizeHandle) {
        [self setNeedsDisplayInRect:NSInsetRect(selectionRect, -margin, -margin) ofPage:page];
    }
    
    // ??? PDFView's delayed layout seems to reset the cursor to an arrow
    [self performSelector:@selector(setCursorForMouse:) withObject:theEvent afterDelay:0];
}

- (void)doDragReadingBarWithEvent:(NSEvent *)theEvent {
    PDFPage *readingBarPage = [readingBar page];
    PDFPage *page = readingBarPage;
    NSPointerArray *lineRects = [page lineRects];
	NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:page, SKPDFViewOldPageKey, nil];
    NSInteger lineAngle = [page lineDirectionAngle];
    
    NSEvent *lastMouseEvent = theEvent;
    NSPoint lastMouseLoc = [theEvent locationInView:self];
    NSPoint point = [self convertPoint:lastMouseLoc toPage:page];
    NSInteger lineOffset = SKIndexOfRectAtPointInOrderedRects(point, lineRects, lineAngle, YES) - [readingBar currentLine];
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
        
        PDFPage *mousePage = [self pageForPoint:mouseLoc nearest:YES];
        NSPoint mouseLocInPage = [self convertPoint:mouseLoc toPage:mousePage];
        NSPoint mouseLocInDocument = [self convertPoint:mouseLoc toView:[self documentView]];
        NSInteger currentLine;
        
        if ([mousePage isEqual:page] == NO) {
            page = mousePage;
            lineRects = [page lineRects];
            lineAngle = [page lineDirectionAngle];
        }
        
        if ([lineRects count] == 0)
            continue;
        
        currentLine = SKIndexOfRectAtPointInOrderedRects(mouseLocInPage, lineRects, lineAngle, mouseLocInDocument.y < lastMouseLoc.y) - lineOffset;
        currentLine = MIN((NSInteger)[lineRects count] - (NSInteger)[readingBar numberOfLines], currentLine);
        currentLine = MAX(0, currentLine);
        
        if ([page isEqual:readingBarPage] == NO || currentLine != [readingBar currentLine]) {
            NSRect newRect, oldRect = [readingBar currentBoundsForBox:[self displayBox]];
            [self setNeedsDisplayInRect:[readingBar currentBoundsForBox:[self displayBox]] ofPage:readingBarPage];
            [readingBar setPage:page];
            [readingBar setCurrentLine:currentLine];
            newRect = [readingBar currentBoundsForBox:[self displayBox]];
            if ([page isEqual:readingBarPage]) {
                [self setNeedsDisplayInRect:NSUnionRect(oldRect, newRect) ofPage:page];
            } else {
                [self setNeedsDisplayInRect:oldRect ofPage:readingBarPage];
                [self setNeedsDisplayInRect:newRect ofPage:page];
            }
            [userInfo setObject:readingBarPage forKey:SKPDFViewOldPageKey];
            [userInfo setObject:page forKey:SKPDFViewNewPageKey];
            readingBarPage = page;
            [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewReadingBarDidChangeNotification object:self userInfo:userInfo];
            lastMouseLoc = mouseLocInDocument;
        }
    }
    
    [NSEvent stopPeriodicEvents];
    
    [NSCursor pop];
    // ??? PDFView's delayed layout seems to reset the cursor to an arrow
    [self performSelector:@selector(setCursorForMouse:) withObject:lastMouseEvent afterDelay:0];
}

- (void)doResizeReadingBarWithEvent:(NSEvent *)theEvent {
    PDFPage *page = [readingBar page];
    NSInteger firstLine = [readingBar currentLine];
    NSPointerArray *lineRects = [page lineRects];
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:page, SKPDFViewOldPageKey, page, SKPDFViewNewPageKey, nil];
    NSInteger lineAngle = [page lineDirectionAngle];

    [[NSCursor resizeUpDownCursor] push];
    
	while (YES) {
		
        theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask];
		if ([theEvent type] == NSLeftMouseUp)
            break;
        
        // dragging
        NSPoint point = NSZeroPoint;
        if ([[self pageAndPoint:&point forEvent:theEvent nearest:YES] isEqual:page] == NO)
            continue;
        
        NSInteger numberOfLines = MAX(0, SKIndexOfRectAtPointInOrderedRects(point, lineRects, lineAngle, YES)) - firstLine + 1;
        
        if (numberOfLines > 0 && numberOfLines != (NSInteger)[readingBar numberOfLines]) {
            NSRect oldRect = [readingBar currentBoundsForBox:[self displayBox]];
            [readingBar setNumberOfLines:numberOfLines];
            [self setNeedsDisplayInRect:NSUnionRect(oldRect, [readingBar currentBoundsForBox:[self displayBox]]) ofPage:page];
            [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewReadingBarDidChangeNotification object:self userInfo:userInfo];
        }
    }
    
    [NSCursor pop];
    // ??? PDFView's delayed layout seems to reset the cursor to an arrow
    [self performSelector:@selector(setCursorForMouse:) withObject:theEvent afterDelay:0];
}

- (void)doSelectSnapshotWithEvent:(NSEvent *)theEvent {
    NSPoint mouseLoc = [theEvent locationInWindow];
	NSPoint startPoint = [[self documentView] convertPoint:mouseLoc fromView:nil];
	NSPoint	currentPoint;
    NSRect selRect = {startPoint, NSZeroSize};
    BOOL dragged = NO;
    CAShapeLayer *layer = nil;
    NSWindow *overlay = nil;
    NSWindow *window = [self window];
    
    [[NSCursor cameraCursor] set];
	
    CGRect layerRect = NSRectToCGRect([self visibleContentRect]);
    layer = [CAShapeLayer layer];
    [layer setStrokeColor:CGColorGetConstantColor(kCGColorBlack)];
    [layer setFillColor:NULL];
    [layer setLineWidth:1.0];
    [layer setFrame:layerRect];
    [layer setBounds:layerRect];
    [layer setMasksToBounds:YES];
    [layer setZPosition:1.0];
    
    overlay = [self newOverlayLayer:layer wantsAdded:YES];
    
	while (YES) {
		theEvent = [window nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSFlagsChangedMask];
        
        if ([theEvent type] == NSLeftMouseUp)
            break;
        
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
        
        CGPathRef path = CGPathCreateWithRect(NSRectToCGRect(NSInsetRect(NSIntegralRect([self convertRect:selRect fromView:[self documentView]]), 0.5, 0.5)), NULL);
        [layer setPath:path];
        CGPathRelease(path);
    }
    
    [self removeLayer:layer overlay:overlay];
    [overlay release];

	[self setCursorForMouse:theEvent];
    
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
            PDFDestination *destination = [annotation linkDestination];
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

- (void)updateMagnifyWithEvent:(NSEvent *)theEvent {
    if (loupeWindow == nil)
        return;
    
    // get the current mouse location
    NSRect visibleRect = [self visibleContentRect];
    NSPoint mouseLoc;
    if (theEvent && [theEvent type] != NSFlagsChanged)
        mouseLoc = [theEvent locationInView:self];
    else
        mouseLoc = [self convertPointFromScreen:[NSEvent mouseLocation]];
    
    if ([self mouse:mouseLoc inRect:visibleRect]) {
        
        // define rect for magnification in view coordinate
        NSRect magRect;
        if (loupeLevel > 2) {
            magRect = visibleRect;
        } else {
            NSUserDefaults *sud = [NSUserDefaults standardUserDefaults];
            NSSize magSize;
            if (loupeLevel == 2)
                magSize = NSMakeSize([sud floatForKey:SKLargeMagnificationWidthKey], [sud floatForKey:SKLargeMagnificationHeightKey]);
            else
                magSize = NSMakeSize([sud floatForKey:SKSmallMagnificationWidthKey], [sud floatForKey:SKSmallMagnificationHeightKey]);
            magRect = NSIntegralRect(SKRectFromCenterAndSize(mouseLoc, magSize));
        }
        
        NSShadow *aShadow = nil;
        if ([self displaysPageBreaks]) {
            aShadow = [[[NSShadow alloc] init] autorelease];
            // @@ Dark mode
            [aShadow setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:RUNNING_AFTER(10_8) ? 0.3 : 1.0]];
            if (RUNNING_AFTER(10_8)) {
                [aShadow setShadowBlurRadius:4.0 * magnification * [self scaleFactor]];
                [aShadow setShadowOffset:NSMakeSize(0.0, -1.0 * magnification * [self scaleFactor])];
            } else {
                [aShadow setShadowBlurRadius:4.0 * magnification];
                [aShadow setShadowOffset:NSMakeSize(0.0, -4.0 * magnification)];
            }
        }
        
        NSImage *image;
        NSRange pageRange;
        NSAffineTransform *transform = [NSAffineTransform transform];
        NSImageInterpolation interpolation = [[NSUserDefaults standardUserDefaults] integerForKey:SKImageInterpolationKey];
        
        // smooth graphics when anti-aliasing
        if (interpolation == NSImageInterpolationDefault)
            interpolation = [self shouldAntiAlias] ? NSImageInterpolationHigh : NSImageInterpolationNone;
        
        [transform translateXBy:mouseLoc.x yBy:mouseLoc.y];
        [transform scaleBy:1.0 / magnification];
        [transform translateXBy:-mouseLoc.x yBy:-mouseLoc.y];
        pageRange.location = [[self pageForPoint:[transform transformPoint:SKTopLeftPoint(magRect)] nearest:YES] pageIndex];
        pageRange.length = [[self pageForPoint:[transform transformPoint:SKBottomRightPoint(magRect)] nearest:YES] pageIndex] + 1 - pageRange.location;
        
        transform = [NSAffineTransform transform];
        [transform translateXBy:mouseLoc.x - NSMinX(magRect) yBy:mouseLoc.y - NSMinY(magRect)];
        [transform scaleBy:magnification];
        [transform translateXBy:-mouseLoc.x yBy:-mouseLoc.y];
        
        image = [NSImage bitmapImageWithSize:magRect.size scale:[self backingScale] drawingHandler:^(NSRect rect){
            
            NSRect imageRect = rect;
            NSUInteger i;
            
            if (aShadow)
                imageRect = NSOffsetRect(NSInsetRect(imageRect, -[aShadow shadowBlurRadius], -[aShadow shadowBlurRadius]), -[aShadow shadowOffset].width, -[aShadow shadowOffset].height);
            
            for (i = pageRange.location; i < NSMaxRange(pageRange); i++) {
                PDFPage *page = [[self document] pageAtIndex:i];
                NSRect pageRect = [self convertRect:[page boundsForBox:[self displayBox]] fromPage:page];
                NSPoint pageOrigin = pageRect.origin;
                NSAffineTransform *pageTransform;
                
                pageRect = SKRectFromPoints([transform transformPoint:SKBottomLeftPoint(pageRect)], [transform transformPoint:SKTopRightPoint(pageRect)]);
                
                // only draw the page when there is something to draw
                if (NSIntersectsRect(imageRect, pageRect) == NO)
                    continue;
                
                // draw page background, simulate the private method -drawPagePre:
                [NSGraphicsContext saveGraphicsState];
                [[[self class] defaultPageBackgroundColor] set];
                [NSShadow setShadowWithColor:[aShadow shadowColor] blurRadius:[aShadow shadowBlurRadius] offset:[aShadow shadowOffset]];
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
                [[NSGraphicsContext currentContext] setImageInterpolation:interpolation];
                if ([PDFView instancesRespondToSelector:@selector(drawPage:toContext:)])
                    [self drawPage:page toContext:[[NSGraphicsContext currentContext] graphicsPort]];
                else
                    [self drawPage:page];
                [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationDefault];
                [NSGraphicsContext restoreGraphicsState];
            }
            
        }];
        
        [[[[[loupeWindow contentView] layer] sublayers] firstObject] setContents:image];
        [loupeWindow setFrame:[self convertRectToScreen:magRect] display:YES];
        if ([loupeWindow parentWindow] == nil) {
            [NSCursor hide];
            [[self window] addChildWindow:loupeWindow ordered:NSWindowAbove];
        }
        
    } else { // mouse is not in the rect
        
        // show cursor
        if ([loupeWindow parentWindow]) {
            [NSCursor unhide];
            [[self window] removeChildWindow:loupeWindow];
            [loupeWindow orderOut:nil];
        }
        
    }
}

- (void)updateLoupeBackgroundColor {
    if (loupeWindow == nil)
        return;
    CALayer *loupeLayer = [[[[loupeWindow contentView] layer] sublayers] firstObject];
    SKRunWithAppearance(self, ^{
        NSColor *bgColor = [self backgroundColor];
        if ([bgColor alphaComponent] < 1.0)
            bgColor = [[NSColor blackColor] blendedColorWithFraction:[backgroundColor alphaComponent] ofColor:[bgColor colorWithAlphaComponent:1.0]];
        [loupeLayer setBackgroundColor:[bgColor CGColor]];
    });
}

- (void)removeLoupeWindow {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewBoundsDidChangeNotification object:[[self scrollView] contentView]];
    
    magnification = 0.0;
    loupeLevel = 0;
    [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewMagnificationChangedNotification object:self];
    
    if ([loupeWindow parentWindow]) {
        [[self window] removeChildWindow:loupeWindow];
        [loupeWindow orderOut:nil];
        [NSCursor unhide];
    }
    
    SKDESTROY(loupeWindow);
}

- (void)doMagnifyWithEvent:(NSEvent *)theEvent {
    if (loupeWindow && [theEvent clickCount] == 1) {
        
        [self removeLoupeWindow];
        
        // ??? PDFView's delayed layout seems to reset the cursor to an arrow
        [self performSelector:@selector(setCursorForMouse:) withObject:theEvent afterDelay:0];
        
        // eat up mouse moved and mouse up events
        [self doDragMouseWithEvent:theEvent];
        
    } else {
        
        NSWindow *window = [self window];
        
        if (loupeWindow == nil) {
            
            // @@ Dark mode
            CALayer *loupeLayer = [CALayer layer];
            CGColorRef borderColor = CGColorCreateGenericGray(0.2, 1.0);
            [loupeLayer setBorderColor:borderColor];
            [loupeLayer setBorderWidth:2.0];
            [loupeLayer setCornerRadius:16.0];
            [loupeLayer setMasksToBounds:YES];
            [loupeLayer setActions:[NSDictionary dictionaryWithObjectsAndKeys:[NSNull null], @"contents", nil]];
            [loupeLayer setAutoresizingMask:kCALayerWidthSizable | kCALayerHeightSizable];
            [loupeLayer setFrame:NSRectToCGRect([self bounds])];
            CGColorRelease(borderColor);
            
            loupeWindow = [self newOverlayLayer:loupeLayer wantsAdded:NO];
            [loupeWindow setHasShadow:YES];
            [self updateLoupeBackgroundColor];
            
            [[NSNotificationCenter defaultCenter] addObserver:self
                selector:@selector(handlePDFContentViewFrameChangedNotification:)
                    name:NSViewBoundsDidChangeNotification object:[[self scrollView] contentView]];

        }
        
        NSInteger startLevel = MAX(1, [theEvent clickCount]);
        
        [theEvent retain];
        while ([theEvent type] != NSLeftMouseUp) {
            NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
            
            if ([theEvent type] != NSLeftMouseUp && [theEvent type] != NSLeftMouseDragged) {
                // set up the currentLevel and magnification
                NSUInteger modifierFlags = [theEvent modifierFlags];
                CGFloat newMagnification = (modifierFlags & NSAlternateKeyMask) ? LARGE_MAGNIFICATION : (modifierFlags & NSControlKeyMask) ? SMALL_MAGNIFICATION : DEFAULT_MAGNIFICATION;
                if ((modifierFlags & NSShiftKeyMask))
                    newMagnification = 1.0 / newMagnification;
                if (fabs(magnification - newMagnification) > 0.0001) {
                    magnification = newMagnification;
                    [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewMagnificationChangedNotification object:self];
                }
                loupeLevel = (modifierFlags & NSCommandKeyMask) ? startLevel + 1 : startLevel;
            }
            
            [self updateMagnifyWithEvent:theEvent];
            
            [pool drain];

            if (theEvent == nil)
                break;
            
            [theEvent release];
            theEvent = [[window nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSFlagsChangedMask] retain];
        }
        [theEvent release];
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:SKMagnifyWithMousePressedKey])
            [self removeLoupeWindow];
    }
}

- (void)doMarqueeZoomWithEvent:(NSEvent *)theEvent {
    NSPoint mouseLoc = [theEvent locationInWindow];
    NSPoint startPoint = [[self documentView] convertPoint:mouseLoc fromView:nil];
    NSPoint	currentPoint;
    NSRect selRect = {startPoint, NSZeroSize};
    BOOL dragged = NO;
    CAShapeLayer *layer = nil;
    NSWindow *overlay = nil;
    NSWindow *window = [self window];
    
    [[NSCursor zoomInCursor] set];
    
    CGRect layerRect = NSRectToCGRect([self visibleContentRect]);
    layer = [CAShapeLayer layer];
    [layer setStrokeColor:CGColorGetConstantColor(kCGColorBlack)];
    [layer setFillColor:NULL];
    [layer setLineWidth:1.0];
    [layer setFrame:layerRect];
    [layer setBounds:layerRect];
    [layer setMasksToBounds:YES];
    [layer setZPosition:1.0];
    
    overlay = [self newOverlayLayer:layer wantsAdded:YES];
    
    while (YES) {
        theEvent = [window nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSFlagsChangedMask];
        
        if ([theEvent type] == NSLeftMouseUp)
            break;
        
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
        
        CGPathRef path = CGPathCreateWithRect(NSRectToCGRect(NSInsetRect(NSIntegralRect([self convertRect:selRect fromView:[self documentView]]), 0.5, 0.5)), NULL);
        [layer setPath:path];
        CGPathRelease(path);
    }
    
    [self removeLayer:layer overlay:overlay];
    [overlay release];
    
    [self setCursorForMouse:theEvent];
    
    if (dragged && NSIsEmptyRect(selRect) == NO) {
        
        NSPoint point = [self convertPoint:SKCenterPoint(selRect) fromView:[self documentView]];
        PDFPage *page = [self pageForPoint:point nearest:YES];
        NSRect rect = [self convertRect:[self convertRect:selRect fromView:[self documentView]] toPage:page];
        
        [self zoomToRect:rect onPage:page];
    }
}

- (BOOL)doDragMouseWithEvent:(NSEvent *)theEvent {
    BOOL didDrag = NO;;
    // eat up mouseDragged/mouseUp events, so we won't get their event handlers
    while (YES) {
        if ([[[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask] type] == NSLeftMouseUp)
            break;
        didDrag = YES;
    }
    return didDrag;
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

- (PDFAreaOfInterest)areaOfInterestForMouse:(NSEvent *)theEvent {
    PDFAreaOfInterest area = [super areaOfInterestForMouse:theEvent];
    NSPoint p = [theEvent locationInWindow];
    NSInteger modifiers = [theEvent standardModifierFlags];
    
    if ([[self document] isLocked]) {
    } else if (NSPointInRect(p, [self convertRect:[self visibleContentRect] toView:nil]) == NO || ([navWindow isVisible] && NSPointInRect([theEvent locationOnScreen], [navWindow frame]))) {
        area = kPDFNoArea;
    } else if (interactionMode == SKPresentationMode) {
        area &= (kPDFPageArea | kPDFLinkArea);
    } else if ((modifiers == NSCommandKeyMask || modifiers == (NSCommandKeyMask | NSShiftKeyMask) || modifiers == (NSCommandKeyMask | NSAlternateKeyMask))) {
        area = (area & kPDFPageArea) | SKSpecialToolArea;
    } else {
        
        SKRectEdges resizeHandle = SKNoEdgeMask;
        PDFPage *page = [self pageAndPoint:&p forEvent:theEvent nearest:YES];
        
        if (readingBar && [[readingBar page] isEqual:page]) {
            NSRect bounds = [readingBar currentBounds];
            NSInteger lineAngle = [page lineDirectionAngle];
            if ((lineAngle % 180)) {
                if (p.y >= NSMinY(bounds) && p.y <= NSMaxY(bounds)) {
                    area |= SKReadingBarArea;
                    if ((lineAngle == 270 && p.y < NSMinY(bounds) + READINGBAR_RESIZE_EDGE_HEIGHT) || (lineAngle == 90 && p.y > NSMaxY(bounds) - READINGBAR_RESIZE_EDGE_HEIGHT))
                        area |= ([page rotation] % 180) ? SKResizeLeftRightArea : SKResizeUpDownArea;
                }
            } else {
                if (p.x >= NSMinX(bounds) && p.x <= NSMaxX(bounds)) {
                    area |= SKReadingBarArea;
                    if ((lineAngle == 0 && p.x > NSMaxX(bounds) - READINGBAR_RESIZE_EDGE_HEIGHT) || (lineAngle == 180 && p.x < NSMinX(bounds) + READINGBAR_RESIZE_EDGE_HEIGHT))
                        area |= ([page rotation] % 180) ? SKResizeUpDownArea : SKResizeLeftRightArea;
                }
            }
        }
        
        if ((area & kPDFPageArea) == 0 || toolMode == SKMoveToolMode) {
            if ((area & SKReadingBarArea) == 0)
                area |= SKDragArea;
        } else if (toolMode == SKTextToolMode || toolMode == SKNoteToolMode) {
            if (toolMode == SKNoteToolMode)
                area &= ~kPDFLinkArea;
            if (editor && [[activeAnnotation page] isEqual:page] && NSPointInRect(p, [activeAnnotation bounds])) {
                area = kPDFTextFieldArea;
            } else if ((area & SKReadingBarArea) == 0) {
                if ([[activeAnnotation page] isEqual:page] && [activeAnnotation isMovable] && 
                    ((resizeHandle = [activeAnnotation resizeHandleForPoint:p scaleFactor:[self scaleFactor]]) || [activeAnnotation hitTest:p]))
                    area |= SKAreaOfInterestForResizeHandle(resizeHandle, page);
                else if ((toolMode == SKTextToolMode || hideNotes || ANNOTATION_MODE_IS_MARKUP) && area == kPDFPageArea && modifiers == 0 && 
                         [[page selectionForRect:SKRectFromCenterAndSize(p, TEXT_SELECT_MARGIN_SIZE)] hasCharacters] == NO)
                    area |= SKDragArea;
            }
        } else {
            area = kPDFPageArea;
            if (toolMode == SKSelectToolMode && NSIsEmptyRect(selectionRect) == NO &&
                ((resizeHandle = SKResizeHandleForPointFromRect(p, selectionRect, HANDLE_SIZE / [self scaleFactor])) || NSPointInRect(p, selectionRect)))
                area |= SKAreaOfInterestForResizeHandle(resizeHandle, page);
        }
    }
    
    return area;
}

- (void)setCursorForAreaOfInterest:(PDFAreaOfInterest)area {
    if ((area & kPDFLinkArea))
        [[NSCursor pointingHandCursor] set];
    else if (interactionMode == SKPresentationMode)
        [cursorHidden ? [NSCursor emptyCursor] : [NSCursor arrowCursor] set];
    else if ((area & SKSpecialToolArea))
        [[NSCursor arrowCursor] set];
    else if ((area & SKDragArea))
        [[NSCursor openHandCursor] set];
    else if ((area & SKResizeUpDownArea))
        [[NSCursor resizeUpDownCursor] set];
    else if ((area & SKResizeLeftRightArea))
        [[NSCursor resizeLeftRightCursor] set];
    else if ((area & SKResizeDiagonal45Area))
        [[NSCursor resizeDiagonal45Cursor] set];
    else if ((area & SKResizeDiagonal135Area))
        [[NSCursor resizeDiagonal135Cursor] set];
    else if ((area & SKReadingBarArea))
        [[NSCursor openHandBarCursor] set];
    else if (area == kPDFTextFieldArea)
        [[NSCursor IBeamCursor] set];
    else if (toolMode == SKNoteToolMode && (area & kPDFPageArea))
        [[self cursorForNoteToolMode] set];
    else if (toolMode == SKSelectToolMode && (area & kPDFPageArea))
        [[NSCursor crosshairCursor] set];
    else if (toolMode == SKMagnifyToolMode && (area & kPDFPageArea))
        [(([NSEvent standardModifierFlags] & NSShiftKeyMask) ? [NSCursor zoomOutCursor] : [NSCursor zoomInCursor]) set];
    else
        [super setCursorForAreaOfInterest:area & ~kPDFIconArea];
}

- (void)setCursorForMouse:(NSEvent *)theEvent {
    if (theEvent == nil)
        theEvent = [NSEvent mouseEventWithType:NSMouseMoved
                                      location:[[self window] mouseLocationOutsideOfEventStream]
                                 modifierFlags:[NSEvent standardModifierFlags]
                                     timestamp:0
                                  windowNumber:[[self window] windowNumber]
                                       context:nil
                                   eventNumber:0
                                    clickCount:1
                                      pressure:0.0];
    [self setCursorForAreaOfInterest:[self areaOfInterestForMouse:theEvent]];
}

- (id <SKPDFViewDelegate>)delegate {
    return (id <SKPDFViewDelegate>)[super delegate];
}

- (void)setDelegate:(id <SKPDFViewDelegate>)newDelegate {
    if ([self delegate] && newDelegate == nil)
        [self cleanup];
    [super setDelegate:newDelegate];
}

@end

static inline PDFAreaOfInterest SKAreaOfInterestForResizeHandle(SKRectEdges mask, PDFPage *page) {
    BOOL rotated = ([page rotation] % 180 != 0);
    if (mask == 0)
        return SKDragArea;
    else if (mask == SKMaxXEdgeMask || mask == SKMinXEdgeMask)
        return rotated ? SKResizeUpDownArea : SKResizeLeftRightArea;
    else if (mask == (SKMaxXEdgeMask | SKMaxYEdgeMask) || mask == (SKMinXEdgeMask | SKMinYEdgeMask))
        return rotated ? SKResizeDiagonal135Area : SKResizeDiagonal45Area;
    else if (mask == SKMaxYEdgeMask || mask == SKMinYEdgeMask)
        return rotated ? SKResizeLeftRightArea : SKResizeUpDownArea;
    else if (mask == (SKMaxXEdgeMask | SKMinYEdgeMask) || mask == (SKMinXEdgeMask | SKMaxYEdgeMask))
        return rotated ? SKResizeDiagonal45Area : SKResizeDiagonal135Area;
    else
        return kPDFNoArea;
}

static inline NSInteger SKIndexOfRectAtPointInOrderedRects(NSPoint point,  NSPointerArray *rectArray, NSInteger lineAngle, BOOL lower)
{
    NSInteger i = 0, iMax = [rectArray count];
    
    for (i = 0; i < iMax; i++) {
        NSRect rect = [rectArray rectAtIndex:i];
        NSInteger pos;
        switch (lineAngle) {
            case 0:   pos = point.x > NSMaxX(rect) ? -1 : point.x > NSMinX(rect) ? 0 : 1; break;
            case 90:  pos = point.y > NSMaxY(rect) ? -1 : point.y > NSMinY(rect) ? 0 : 1; break;
            case 180: pos = point.x < NSMinX(rect) ? -1 : point.x < NSMaxX(rect) ? 0 : 1; break;
            case 270: pos = point.y < NSMinY(rect) ? -1 : point.y < NSMaxY(rect) ? 0 : 1; break;
            default:  pos = point.y < NSMinY(rect) ? -1 : point.y < NSMaxY(rect) ? 0 : 1; break;
        }
        if (pos != -1) {
            if (pos == 1 && lower && i > 0) i--;
            break;
        }
    }
    return MIN(i, iMax - 1);
}
