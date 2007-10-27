//
//  SKMainWindowController.m
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

#import "SKMainWindowController.h"
#import <Quartz/Quartz.h>
#import <Carbon/Carbon.h>
#import "SKStringConstants.h"
#import "SKApplication.h"
#import "SKStringConstants.h"
#import "SKSnapshotWindowController.h"
#import "SKNoteWindowController.h"
#import "SKInfoWindowController.h"
#import "SKBookmarkController.h"
#import "SKFullScreenWindow.h"
#import "SKNavigationWindow.h"
#import "SKSideWindow.h"
#import "PDFPage_SKExtensions.h"
#import "SKDocument.h"
#import "SKThumbnail.h"
#import "SKPDFView.h"
#import "BDSKCollapsibleView.h"
#import "BDSKEdgeView.h"
#import "BDSKGradientView.h"
#import "SKPDFAnnotationNote.h"
#import "SKSplitView.h"
#import "NSScrollView_SKExtensions.h"
#import "NSBezierPath_BDSKExtensions.h"
#import "NSUserDefaultsController_SKExtensions.h"
#import "SKTocOutlineView.h"
#import "SKNoteOutlineView.h"
#import "SKThumbnailTableView.h"
#import "SKFindTableView.h"
#import "BDSKImagePopUpButton.h"
#import "NSWindowController_SKExtensions.h"
#import "SKPDFHoverWindow.h"
#import "PDFSelection_SKExtensions.h"
#import "SKToolbarItem.h"
#import "NSValue_SKExtensions.h"
#import "NSString_SKExtensions.h"
#import "SKReadingBar.h"
#import "SKLineInspector.h"
#import "SKColorSwatch.h"
#import "SKStatusBar.h"
#import "SKTransitionController.h"
#import "SKTypeSelectHelper.h"
#import "NSGeometry_SKExtensions.h"
#import "SKProgressController.h"
#import "SKSecondaryPDFView.h"
#import "SKSheetController.h"

#define SEGMENTED_CONTROL_HEIGHT    25.0
#define WINDOW_X_DELTA              0.0
#define WINDOW_Y_DELTA              70.0

#define WINDOW_FRAME_KEY            @"windowFrame"
#define LEFT_SIDE_PANE_WIDTH_KEY    @"leftSidePaneWidth"
#define RIGHT_SIDE_PANE_WIDTH_KEY   @"rightSidePaneWidth"
#define SCALE_FACTOR_KEY            @"scaleFactor"
#define AUTO_SCALES_KEY             @"autoScales"
#define DISPLAYS_PAGE_BREAKS_KEY    @"displaysPageBreaks"
#define DISPLAYS_AS_BOOK_KEY        @"displaysAsBook"    
#define DISPLAY_MODE_KEY            @"displayMode" 
#define DISPLAY_BOX_KEY             @"displayBox"  
#define HAS_HORIZONTAL_SCROLLER_KEY @"hasHorizontalScroller"
#define HAS_VERTICAL_SCROLLER_KEY   @"hasVerticalScroller"
#define AUTO_HIDES_SCROLLERS_KEY    @"autoHidesScrollers"
#define PAGE_INDEX_KEY              @"pageIndex"

static NSString *SKMainWindowFrameAutosaveName = @"SKMainWindow";

static NSString *SKDocumentToolbarIdentifier = @"SKDocumentToolbarIdentifier";

static NSString *SKDocumentToolbarPreviousItemIdentifier = @"SKDocumentPreviousToolbarItemIdentifier";
static NSString *SKDocumentToolbarNextItemIdentifier = @"SKDocumentNextToolbarItemIdentifier";
static NSString *SKDocumentToolbarBackForwardItemIdentifier = @"SKDocumentToolbarBackForwardItemIdentifier";
static NSString *SKDocumentToolbarPageNumberItemIdentifier = @"SKDocumentToolbarPageNumberItemIdentifier";
static NSString *SKDocumentToolbarPageNumberButtonsItemIdentifier = @"SKDocumentToolbarPageNumberButtonsItemIdentifier";
static NSString *SKDocumentToolbarScaleItemIdentifier = @"SKDocumentToolbarScaleItemIdentifier";
static NSString *SKDocumentToolbarZoomInItemIdentifier = @"SKDocumentZoomInToolbarItemIdentifier";
static NSString *SKDocumentToolbarZoomOutItemIdentifier = @"SKDocumentZoomOutToolbarItemIdentifier";
static NSString *SKDocumentToolbarZoomActualItemIdentifier = @"SKDocumentZoomActualToolbarItemIdentifier";
static NSString *SKDocumentToolbarZoomToSelectionItemIdentifier = @"SKDocumentToolbarZoomToSelectionItemIdentifier";
static NSString *SKDocumentToolbarZoomToFitItemIdentifier = @"SKDocumentToolbarZoomToFitItemIdentifier";
static NSString *SKDocumentToolbarRotateRightItemIdentifier = @"SKDocumentRotateRightToolbarItemIdentifier";
static NSString *SKDocumentToolbarRotateLeftItemIdentifier = @"SKDocumentRotateLeftToolbarItemIdentifier";
static NSString *SKDocumentToolbarCropItemIdentifier = @"SKDocumentToolbarCropItemIdentifier";
static NSString *SKDocumentToolbarFullScreenItemIdentifier = @"SKDocumentFullScreenToolbarItemIdentifier";
static NSString *SKDocumentToolbarPresentationItemIdentifier = @"SKDocumentToolbarPresentationItemIdentifier";
static NSString *SKDocumentToolbarNewNoteItemIdentifier = @"SKDocumentToolbarNewNoteItemIdentifier";
static NSString *SKDocumentToolbarNewCircleNoteItemIdentifier = @"SKDocumentToolbarNewCircleNoteItemIdentifier";
static NSString *SKDocumentToolbarNewMarkupItemIdentifier = @"SKDocumentToolbarNewMarkupItemIdentifier";
static NSString *SKDocumentToolbarNewLineItemIdentifier = @"SKDocumentToolbarNewLineItemIdentifier";
static NSString *SKDocumentToolbarNewNotesItemIdentifier = @"SKDocumentToolbarNewNotesItemIdentifier";
static NSString *SKDocumentToolbarInfoItemIdentifier = @"SKDocumentToolbarInfoItemIdentifier";
static NSString *SKDocumentToolbarToolModeItemIdentifier = @"SKDocumentToolbarToolModeItemIdentifier";
static NSString *SKDocumentToolbarDisplayBoxItemIdentifier = @"SKDocumentToolbarDisplayBoxItemIdentifier";
static NSString *SKDocumentToolbarColorSwatchItemIdentifier = @"SKDocumentToolbarColorSwatchItemIdentifier";
static NSString *SKDocumentToolbarColorsItemIdentifier = @"SKDocumentToolbarColorsItemIdentifier";
static NSString *SKDocumentToolbarFontsItemIdentifier = @"SKDocumentToolbarFontsItemIdentifier";
static NSString *SKDocumentToolbarLinesItemIdentifier = @"SKDocumentToolbarLinesItemIdentifier";
static NSString *SKDocumentToolbarContentsPaneItemIdentifier = @"SKDocumentToolbarContentsPaneItemIdentifier";
static NSString *SKDocumentToolbarNotesPaneItemIdentifier = @"SKDocumentToolbarNotesPaneItemIdentifier";

static NSString *SKLeftSidePaneWidthKey = @"SKLeftSidePaneWidth";
static NSString *SKRightSidePaneWidthKey = @"SKRightSidePaneWidth";
static NSString *SKUsesDrawersKey = @"SKUsesDrawers";

static NSString *noteToolAdornImageNames[] = {@"TextNoteToolAdorn", @"AnchoredNoteToolAdorn", @"CircleNoteToolAdorn", @"SquareNoteToolAdorn", @"HighlightNoteToolAdorn", @"UnderlineNoteToolAdorn", @"StrikeOutNoteToolAdorn", @"LineNoteToolAdorn"};

@interface NSResponder (SKExtensions)
- (BOOL)isDescendantOf:(NSView *)aView;
@end

@implementation NSResponder (SKExtensions)
- (BOOL)isDescendantOf:(NSView *)aView { return NO; }
@end

@interface SKMainWindowController (Private)

- (void)setupToolbar;

- (void)updatePageLabelsAndOutline;

- (SKProgressController *)progressController;

- (void)showLeftSideWindowOnScreen:(NSScreen *)screen;
- (void)showRightSideWindowOnScreen:(NSScreen *)screen;
- (void)hideLeftSideWindow;
- (void)hideRightSideWindow;
- (void)showSideWindowsOnScreen:(NSScreen *)screen;
- (void)hideSideWindows;
- (void)goFullScreen;
- (void)removeFullScreen;
- (void)saveNormalSetup;
- (void)enterPresentationMode;
- (void)exitPresentationMode;
- (void)activityTimerFired:(NSTimer *)timer;

- (void)goToSelectedOutlineItem;

- (void)goToFindResults:(NSArray *)findResults;

- (void)showHoverWindowForDestination:(PDFDestination *)dest;

- (void)updateNoteFilterPredicate;

- (void)replaceSideView:(NSView *)oldView withView:(NSView *)newView animate:(BOOL)animate;

- (void)handleApplicationWillTerminateNotification:(NSNotification *)notification;
- (void)handleApplicationDidResignActiveNotification:(NSNotification *)notification;
- (void)handleApplicationWillBecomeActiveNotification:(NSNotification *)notification;
- (void)handlePageChangedNotification:(NSNotification *)notification;
- (void)handleScaleChangedNotification:(NSNotification *)notification;
- (void)handleToolModeChangedNotification:(NSNotification *)notification;
- (void)handleAnnotationModeChangedNotification:(NSNotification *)notification;
- (void)handleSelectionChangedNotification:(NSNotification *)notification;
- (void)handleMagnificationChangedNotification:(NSNotification *)notification;
- (void)handleChangedHistoryNotification:(NSNotification *)notification;
- (void)handleDidChangeActiveAnnotationNotification:(NSNotification *)notification;
- (void)handleDidAddAnnotationNotification:(NSNotification *)notification;
- (void)handleDidRemoveAnnotationNotification:(NSNotification *)notification;
- (void)handleDidMoveAnnotationNotification:(NSNotification *)notification;
- (void)handleDoubleClickedAnnotationNotification:(NSNotification *)notification;
- (void)handleReadingBarDidChangeNotification:(NSNotification *)notification;
- (void)handleAnnotationDidChangeNotification:(NSNotification *)notification;
- (void)handlePageBoundsDidChangeNotification:(NSNotification *)notification;
- (void)handleDocumentBeginWrite:(NSNotification *)notification;
- (void)handleDocumentEndWrite:(NSNotification *)notification;
- (void)handleDocumentEndPageWrite:(NSNotification *)notification;
- (void)handleColorSwatchColorsChangedNotification:(NSNotification *)notification;

@end

@implementation SKMainWindowController

+ (void)initialize {
    [NSValueTransformer setValueTransformer:[[[SKUnarchiveFromDataArrayTransformer alloc] init] autorelease] forName:SKUnarchiveFromDataArrayTransformerName];
}

- (id)initWithWindowNibName:(NSString *)windowNibName owner:(id)owner{
    self = [super initWithWindowNibName:windowNibName owner:owner];
    if(self){
        [self setShouldCloseDocument:YES];
        isPresentation = NO;
        searchResults = [[NSMutableArray alloc] init];
        thumbnails = [[NSMutableArray alloc] init];
        notes = [[NSMutableArray alloc] init];
        snapshots = [[NSMutableArray alloc] init];
        dirtySnapshots = [[NSMutableArray alloc] init];
        pageLabels = [[NSMutableArray alloc] init];
        lastViewedPages = [[NSMutableArray alloc] init];
        // @@ remove or set to nil for Leopard?
        pdfOutlineItems = [[NSMutableArray alloc] init];
        savedNormalSetup = [[NSMutableDictionary alloc] init];
        leftSidePaneState = SKOutlineSidePaneState;
        rightSidePaneState = SKNoteSidePaneState;
        temporaryAnnotations = CFSetCreateMutable(kCFAllocatorDefault, 0, &kCFTypeSetCallBacks);
        isAnimating = NO;
        updatingColor = NO;
        updatingFont = NO;
        updatingLine = NO;
        usesDrawers = [[NSUserDefaults standardUserDefaults] boolForKey:SKUsesDrawersKey];
    }
    
    return self;
}

- (void)dealloc {
    [colorSwatch unbind:@"color"];
	[[NSNotificationCenter defaultCenter] removeObserver: self];
    [self unregisterAsObserver];
    [(id)temporaryAnnotations release];
    [dirtySnapshots release];
	[searchResults release];
    [pdfOutline release];
	[thumbnails release];
	[notes release];
	[snapshots release];
    [pageLabels release];
    [lastViewedPages release];
	[leftSideWindow release];
	[rightSideWindow release];
	[fullScreenWindow release];
    [mainWindow release];
    [statusBar release];
    [toolbarItems release];
    [pdfOutlineItems release];
    [savedNormalSetup release];
    [progressController release];
    [colorAccessoryView release];
    [leftSideDrawer release];
    [rightSideDrawer release];
    [pageSheetController release];
    [scaleSheetController release];
    [passwordSheetController release];
    [bookmarkSheetController release];
    [secondaryPdfEdgeView release];
    [super dealloc];
}

- (void)windowDidLoad{
    NSUserDefaults *sud = [NSUserDefaults standardUserDefaults];
    NSRect frame;
    
    settingUpWindow = YES;
    
    // Set up the panes and subviews, needs to be done before we resize them
    
    [leftSideCollapsibleView setCollapseEdges:BDSKMaxXEdgeMask | BDSKMinYEdgeMask];
    [leftSideCollapsibleView setMinSize:NSMakeSize(111.0, NSHeight([leftSideCollapsibleView frame]))];
    
    [rightSideCollapsibleView setCollapseEdges:BDSKMaxXEdgeMask | BDSKMinYEdgeMask];
    [rightSideCollapsibleView setMinSize:NSMakeSize(111.0, NSHeight([rightSideCollapsibleView frame]))];
    
    [pdfEdgeView setEdges:BDSKMinXEdgeMask | BDSKMaxXEdgeMask | BDSKMinYEdgeMask];
    [leftSideEdgeView setEdges:BDSKMinXEdgeMask | BDSKMaxXEdgeMask];
    [rightSideEdgeView setEdges:BDSKMinXEdgeMask | BDSKMaxXEdgeMask];
    
    if (usesDrawers == NO) {
        frame = [leftSideButton frame];
        frame.size.height = SEGMENTED_CONTROL_HEIGHT;
        [leftSideButton setFrame:frame];
        frame = [rightSideButton frame];
        frame.size.height = SEGMENTED_CONTROL_HEIGHT;
        [rightSideButton setFrame:frame];
    }
    
    [[leftSideButton cell] setToolTip:NSLocalizedString(@"View Thumbnails", @"Tool tip message") forSegment:SKThumbnailSidePaneState];
    [[leftSideButton cell] setToolTip:NSLocalizedString(@"View Table of Contents", @"Tool tip message") forSegment:SKOutlineSidePaneState];
    [[rightSideButton cell] setToolTip:NSLocalizedString(@"View Notes", @"Tool tip message") forSegment:SKNoteSidePaneState];
    [[rightSideButton cell] setToolTip:NSLocalizedString(@"View Snapshots", @"Tool tip message") forSegment:SKSnapshotSidePaneState];
    
    // This gets sometimes messed up in the nib, AppKit bug rdar://5346690
    [leftSideContentView setAutoresizesSubviews:YES];
    [rightSideContentView setAutoresizesSubviews:YES];
    
    [leftSideView setFrame:[leftSideContentView bounds]];
    [leftSideContentView addSubview:leftSideView];
    [rightSideView setFrame:[rightSideContentView bounds]];
    [rightSideContentView addSubview:rightSideView];
    
    [pdfView setFrame:[[pdfEdgeView contentView] bounds]];
    
    if (usesDrawers) {
        leftSideDrawer = [[NSDrawer alloc] initWithContentSize:[leftSideContentView frame].size preferredEdge:NSMinXEdge];
        [leftSideDrawer setParentWindow:[self window]];
        [leftSideDrawer setContentView:leftSideContentView];
        [leftSideEdgeView setEdges:BDSKNoEdgeMask];
        [leftSideDrawer openOnEdge:NSMinXEdge];
        [leftSideDrawer setDelegate:self];
        rightSideDrawer = [[NSDrawer alloc] initWithContentSize:[rightSideContentView frame].size preferredEdge:NSMaxXEdge];
        [rightSideDrawer setParentWindow:[self window]];
        [rightSideDrawer setContentView:rightSideContentView];
        [rightSideEdgeView setEdges:BDSKNoEdgeMask];
        [rightSideDrawer openOnEdge:NSMaxXEdge];
        [rightSideDrawer setDelegate:self];
        [pdfSplitView setFrame:[splitView bounds]];
    } else {
        [pdfSplitView setBlendEnds:YES];
    }
    
    [outlineView setAutoresizesOutlineColumn: NO];
    [self displayOutlineView];
    [self displayNoteView];
    
    // Set up the tool bar
    [self setupToolbar];
    
    // Set up the window
    // we retain as we might replace it with the full screen window
    mainWindow = [[self window] retain];
    
    [self setWindowFrameAutosaveNameOrCascade:SKMainWindowFrameAutosaveName];
    
    [[self window] setBackgroundColor:[NSColor colorWithCalibratedWhite:0.9 alpha:1.0]];
    
    int windowSizeOption = [sud integerForKey:SKInitialWindowSizeOptionKey];
    if (windowSizeOption == SKMaximizeWindowOption)
        [[self window] setFrame:[[NSScreen mainScreen] visibleFrame] display:NO];
    
    if ([sud boolForKey:SKShowStatusBarKey])
        [self toggleStatusBar:nil];
    
    [[self window] makeFirstResponder:[pdfView documentView]];
    
    // Set up the PDF
    [self applyPDFSettings:[sud dictionaryForKey:SKDefaultPDFDisplaySettingsKey]];
    
    [pdfView setShouldAntiAlias:[sud boolForKey:SKShouldAntiAliasKey]];
    [pdfView setGreekingThreshold:[sud floatForKey:SKGreekingThresholdKey]];
    [pdfView setBackgroundColor:[sud colorForKey:SKBackgroundColorKey]];
    
    if ([sud objectForKey:SKLeftSidePaneWidthKey]) {
        float width = [sud floatForKey:SKLeftSidePaneWidthKey];
        if (width >= 0.0) {
            frame = [leftSideContentView frame];
            frame.size.width = width;
            if (usesDrawers == NO) {
                [leftSideContentView setFrame:frame];
            } else if (width > 0.0) {
                [leftSideDrawer setContentSize:frame.size];
                [leftSideDrawer openOnEdge:NSMinXEdge];
            } else {
                [leftSideDrawer close];
            }
        }
        width = [sud floatForKey:SKRightSidePaneWidthKey];
        if (width >= 0.0) {
            frame = [rightSideContentView frame];
            frame.size.width = width;
            if (usesDrawers == NO) {
                frame.origin.x = NSMaxX([splitView frame]) - width;
                [rightSideContentView setFrame:frame];
            } else if (width > 0.0) {
                [rightSideDrawer setContentSize:frame.size];
                [rightSideDrawer openOnEdge:NSMaxXEdge];
            } else {
                [rightSideDrawer close];
            }
        }
        if (usesDrawers == NO) {
            frame = [pdfSplitView frame];
            frame.size.width = NSWidth([splitView frame]) - NSWidth([leftSideContentView frame]) - NSWidth([rightSideContentView frame]) - 2 * [splitView dividerThickness];
            frame.origin.x = NSMaxX([leftSideContentView frame]) + [splitView dividerThickness];
            [pdfSplitView setFrame:frame];
        }
    }
    
    // this needs to be done before loading the PDFDocument
    [self resetThumbnailSizeIfNeeded];
    [self resetSnapshotSizeIfNeeded];
    
    // this needs to be done before loading the PDFDocument
    NSSortDescriptor *pageIndexSortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"pageIndex" ascending:YES] autorelease];
    NSSortDescriptor *boundsSortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"bounds" ascending:YES selector:@selector(boundsCompare:)] autorelease];
    [noteArrayController setSortDescriptors:[NSArray arrayWithObjects:pageIndexSortDescriptor, boundsSortDescriptor, nil]];
    [snapshotArrayController setSortDescriptors:[NSArray arrayWithObjects:pageIndexSortDescriptor, nil]];
    [ownerController setContent:self];
    
    // NB: the next line will load the PDF document and annotations, so necessary setup must be finished first!
    // windowControllerDidLoadNib: is not called automatically because the document overrides makeWindowControllers
    [[self document] windowControllerDidLoadNib:self];
    
    // this is mainly needed when the pdf auto-scales
    [pdfView layoutDocumentView];
    
    // Show/hide left side pane if necessary
    if ([sud boolForKey:SKOpenContentsPaneOnlyForTOCKey] && [self leftSidePaneIsOpen] == (pdfOutline == nil))
        [self toggleLeftSidePane:self];
    if (pdfOutline == nil) {
        [self setLeftSidePaneState:SKThumbnailSidePaneState];
        [leftSideButton setEnabled:NO forSegment:SKOutlineSidePaneState];
    }
    
    // Go to page?
    if ([sud boolForKey:SKRememberLastPageViewedKey]) {
        unsigned int pageIndex = [[SKBookmarkController sharedBookmarkController] pageIndexForRecentDocumentAtPath:[[[self document] fileURL] path]];
        if (pageIndex != NSNotFound && [[pdfView document] pageCount] > pageIndex)
            [pdfView goToPage:[[pdfView document] pageAtIndex:pageIndex]];
    }
    
    // We can fit only after the PDF has been loaded
    if (windowSizeOption == SKFitWindowOption)
        [self performFit:self];
    
    // Open snapshots?
    if ([sud boolForKey:SKRememberSnapshotsKey])
        [self showSnapshotWithSetups:[[SKBookmarkController sharedBookmarkController] snapshotsAtPath:[[[self document] fileURL] path]]];
    
    // typeSelectHelpers
    SKTypeSelectHelper *typeSelectHelper = [[[SKTypeSelectHelper alloc] init] autorelease];
    [typeSelectHelper setMatchesImmediately:NO];
    [typeSelectHelper setCyclesSimilarResults:NO];
    [typeSelectHelper setMatchOption:SKFullStringMatch];
    [typeSelectHelper setDataSource:self];
    [thumbnailTableView setTypeSelectHelper:typeSelectHelper];
    [pdfView setTypeSelectHelper:typeSelectHelper];
    
    typeSelectHelper = [[[SKTypeSelectHelper alloc] init] autorelease];
    [typeSelectHelper setMatchOption:SKSubstringMatch];
    [typeSelectHelper setDataSource:self];
    [noteOutlineView setTypeSelectHelper:typeSelectHelper];
    
    typeSelectHelper = [[[SKTypeSelectHelper alloc] init] autorelease];
    [typeSelectHelper setMatchOption:SKSubstringMatch];
    [typeSelectHelper setDataSource:self];
    [outlineView setTypeSelectHelper:typeSelectHelper];
    
    // This update toolbar item and other states
    [self handleChangedHistoryNotification:nil];
    [self handlePageChangedNotification:nil];
    [self handleScaleChangedNotification:nil];
    [self handleToolModeChangedNotification:nil];
    [self handleAnnotationModeChangedNotification:nil];
    
    // Observe notifications and KVO
    [self registerForNotifications];
    [self registerAsObserver];
    
    settingUpWindow = NO;
}

- (void)registerForNotifications {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    // Application
    [nc addObserver:self selector:@selector(handleApplicationWillTerminateNotification:) 
                             name:SKApplicationStartsTerminatingNotification object:NSApp];
    [nc addObserver:self selector:@selector(handleApplicationDidResignActiveNotification:) 
                             name:NSApplicationDidResignActiveNotification object:NSApp];
    [nc addObserver:self selector:@selector(handleApplicationWillBecomeActiveNotification:) 
                             name:NSApplicationWillBecomeActiveNotification object:NSApp];
    // Document
    [nc addObserver:self selector:@selector(handleDocumentWillSaveNotification:) 
                             name:SKDocumentWillSaveNotification object:[self document]];
    // PDFView
    [nc addObserver:self selector:@selector(handlePageChangedNotification:) 
                             name:PDFViewPageChangedNotification object:pdfView];
    [nc addObserver:self selector:@selector(handleScaleChangedNotification:) 
                             name:PDFViewScaleChangedNotification object:pdfView];
    [nc addObserver:self selector:@selector(handleToolModeChangedNotification:) 
                             name:SKPDFViewToolModeChangedNotification object:pdfView];
    [nc addObserver:self selector:@selector(handleAnnotationModeChangedNotification:) 
                             name:SKPDFViewAnnotationModeChangedNotification object:pdfView];
    [nc addObserver:self selector:@selector(handleSelectionChangedNotification:) 
                             name:SKPDFViewSelectionChangedNotification object:pdfView];
    [nc addObserver:self selector:@selector(handleMagnificationChangedNotification:) 
                             name:SKPDFViewMagnificationChangedNotification object:pdfView];
    [nc addObserver:self selector:@selector(handleChangedHistoryNotification:) 
                             name:PDFViewChangedHistoryNotification object:pdfView];
    [nc addObserver:self selector:@selector(handleDidChangeActiveAnnotationNotification:) 
                             name:SKPDFViewActiveAnnotationDidChangeNotification object:pdfView];
    [nc addObserver:self selector:@selector(handleDidAddAnnotationNotification:) 
                             name:SKPDFViewDidAddAnnotationNotification object:pdfView];
    [nc addObserver:self selector:@selector(handleDidRemoveAnnotationNotification:) 
                             name:SKPDFViewDidRemoveAnnotationNotification object:pdfView];
    [nc addObserver:self selector:@selector(handleDidMoveAnnotationNotification:) 
                             name:SKPDFViewDidMoveAnnotationNotification object:pdfView];
    [nc addObserver:self selector:@selector(handleDoubleClickedAnnotationNotification:) 
                             name:SKPDFViewAnnotationDoubleClickedNotification object:pdfView];
    [nc addObserver:self selector:@selector(handleReadingBarDidChangeNotification:) 
                             name:SKPDFViewReadingBarDidChangeNotification object:pdfView];
    [nc addObserver:self selector:@selector(handleAnnotationDidChangeNotification:) 
                             name:SKAnnotationDidChangeNotification object:nil];
}

- (void)registerForDocumentNotifications {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(handleDocumentBeginWrite:) 
                             name:@"PDFDidBeginDocumentWrite" object:[pdfView document]];
    [nc addObserver:self selector:@selector(handleDocumentEndWrite:) 
                             name:@"PDFDidEndDocumentWrite" object:[pdfView document]];
    [nc addObserver:self selector:@selector(handleDocumentEndPageWrite:) 
                             name:@"PDFDidEndPageWrite" object:[pdfView document]];
    [nc addObserver:self selector:@selector(handlePageBoundsDidChangeNotification:) 
                             name:SKPDFDocumentPageBoundsDidChangeNotification object:[pdfView document]];
}

- (void)unregisterForDocumentNotifications {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:@"PDFDidBeginDocumentWrite" object:[pdfView document]];
    [nc removeObserver:self name:@"PDFDidEndDocumentWrite" object:[pdfView document]];
    [nc removeObserver:self name:@"PDFDidEndPageWrite" object:[pdfView document]];
    [nc removeObserver:self name:SKPDFDocumentPageBoundsDidChangeNotification object:[pdfView document]];
}

- (void)registerAsObserver {
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeys:
        [NSArray arrayWithObjects:SKBackgroundColorKey, SKFullScreenBackgroundColorKey, 
                                  SKSearchHighlightColorKey, SKShouldHighlightSearchResultsKey, 
                                  SKThumbnailSizeKey, SKSnapshotThumbnailSizeKey, 
                                  SKShouldAntiAliasKey, SKGreekingThresholdKey, nil]];
}

- (void)unregisterAsObserver {
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeys:
        [NSArray arrayWithObjects:SKBackgroundColorKey, SKFullScreenBackgroundColorKey, 
                                  SKSearchHighlightColorKey, SKShouldHighlightSearchResultsKey, 
                                  SKThumbnailSizeKey, SKSnapshotThumbnailSizeKey, 
                                  SKShouldAntiAliasKey, SKGreekingThresholdKey, nil]];
}

- (void)setupWindow:(NSDictionary *)setup{
    NSString *rectString;
    NSNumber *number;
    NSRect frame;
    
    if (rectString = [setup objectForKey:WINDOW_FRAME_KEY])
        [[self window] setFrame:NSRectFromString(rectString) display:NO];
    if (number = [setup objectForKey:LEFT_SIDE_PANE_WIDTH_KEY]) {
        frame = [leftSideContentView frame];
        frame.size.width = [number floatValue];
        if (usesDrawers == NO) {
            [leftSideContentView setFrame:frame];
        } else if (NSWidth(frame) > 0.0) {
            [leftSideDrawer setContentSize:frame.size];
            [leftSideDrawer openOnEdge:NSMinXEdge];
        } else {
            [leftSideDrawer close];
        }
    }
    if (number = [setup objectForKey:RIGHT_SIDE_PANE_WIDTH_KEY]) {
        frame = [rightSideContentView frame];
        frame.size.width = [number floatValue];
        frame.origin.x = NSMaxX([splitView frame]) - NSWidth(frame);
        if (usesDrawers == NO) {
            [rightSideContentView setFrame:frame];
        } else if (NSWidth(frame) > 0.0) {
            [rightSideDrawer setContentSize:frame.size];
            [rightSideDrawer openOnEdge:NSMaxXEdge];
        } else {
            [rightSideDrawer close];
        }
    }
    if (usesDrawers == NO) {
        frame = [pdfSplitView frame];
        frame.size.width = NSWidth([splitView frame]) - NSWidth([leftSideContentView frame]) - NSWidth([rightSideContentView frame]) - 2 * [splitView dividerThickness];
        frame.origin.x = NSMaxX([leftSideContentView frame]) + [splitView dividerThickness];
        [pdfSplitView setFrame:frame];
    }
    
    [self applyPDFSettings:setup];
    if (number = [setup objectForKey:PAGE_INDEX_KEY])
        [pdfView goToPage:[[pdfView document] pageAtIndex:[number intValue]]];
}

- (NSDictionary *)currentSetup {
    NSMutableDictionary *setup = [NSMutableDictionary dictionary];
    
    [setup setObject:NSStringFromRect([mainWindow frame]) forKey:WINDOW_FRAME_KEY];
    [setup setObject:[NSNumber numberWithFloat:[self leftSidePaneIsOpen] ? NSWidth([leftSideContentView frame]) : 0.0] forKey:LEFT_SIDE_PANE_WIDTH_KEY];
    [setup setObject:[NSNumber numberWithFloat:[self rightSidePaneIsOpen] ? NSWidth([rightSideContentView frame]) : 0.0] forKey:RIGHT_SIDE_PANE_WIDTH_KEY];
    [setup setObject:[NSNumber numberWithUnsignedInt:[[pdfView currentPage] pageIndex]] forKey:PAGE_INDEX_KEY];
    if ([self isFullScreen] || [self isPresentation]) {
        [setup addEntriesFromDictionary:savedNormalSetup];
        [setup removeObjectsForKeys:[NSArray arrayWithObjects:HAS_HORIZONTAL_SCROLLER_KEY, HAS_VERTICAL_SCROLLER_KEY, AUTO_HIDES_SCROLLERS_KEY, nil]];
    } else {
        [setup addEntriesFromDictionary:[self currentPDFSettings]];
    }
    
    return setup;
}

- (void)applyPDFSettings:(NSDictionary *)setup {
    NSNumber *number;
    if (number = [setup objectForKey:SCALE_FACTOR_KEY])
        [pdfView setScaleFactor:[number floatValue]];
    if (number = [setup objectForKey:AUTO_SCALES_KEY])
        [pdfView setAutoScales:[number boolValue]];
    if (number = [setup objectForKey:DISPLAYS_PAGE_BREAKS_KEY])
        [pdfView setDisplaysPageBreaks:[number boolValue]];
    if (number = [setup objectForKey:DISPLAYS_AS_BOOK_KEY])
        [pdfView setDisplaysAsBook:[number boolValue]];
    if (number = [setup objectForKey:DISPLAY_MODE_KEY])
        [pdfView setDisplayMode:[number intValue]];
    if (number = [setup objectForKey:DISPLAY_BOX_KEY])
        [pdfView setDisplayBox:[number intValue]];
}

- (NSDictionary *)currentPDFSettings {
    NSMutableDictionary *setup = [NSMutableDictionary dictionary];
    
    if ([self isPresentation]) {
        [setup setDictionary:savedNormalSetup];
        [setup removeObjectsForKeys:[NSArray arrayWithObjects:HAS_HORIZONTAL_SCROLLER_KEY, HAS_VERTICAL_SCROLLER_KEY, AUTO_HIDES_SCROLLERS_KEY, nil]];
    } else {
        [setup setObject:[NSNumber numberWithBool:[pdfView displaysPageBreaks]] forKey:DISPLAYS_PAGE_BREAKS_KEY];
        [setup setObject:[NSNumber numberWithBool:[pdfView displaysAsBook]] forKey:DISPLAYS_AS_BOOK_KEY];
        [setup setObject:[NSNumber numberWithInt:[pdfView displayBox]] forKey:DISPLAY_BOX_KEY];
        [setup setObject:[NSNumber numberWithFloat:[pdfView scaleFactor]] forKey:SCALE_FACTOR_KEY];
        [setup setObject:[NSNumber numberWithBool:[pdfView autoScales]] forKey:AUTO_SCALES_KEY];
        [setup setObject:[NSNumber numberWithInt:[pdfView displayMode]] forKey:DISPLAY_MODE_KEY];
    }
    
    return setup;
}

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName {
    if ([pdfView document]) {
        if ([[pdfView document] pageCount] == 1)
            return [NSString stringWithFormat:NSLocalizedString(@"%@ (1 page)", @"Window title format"), displayName];
        else
            return [NSString stringWithFormat:NSLocalizedString(@"%@ (%i pages)", @"Window title format"), displayName, [[pdfView document] pageCount]];
    } else
        return displayName;
}

- (void)updateFontPanel {
    PDFAnnotation *annotation = [pdfView activeAnnotation];
    
    if ([[self window] isMainWindow]) {
        if ([annotation isNoteAnnotation] && [annotation respondsToSelector:@selector(font)]) {
            updatingFont = YES;
            [[NSFontManager sharedFontManager] setSelectedFont:[(PDFAnnotationFreeText *)annotation font] isMultiple:NO];
            updatingFont = NO;
        }
    }
}

- (void)updateColorPanel {
    PDFAnnotation *annotation = [pdfView activeAnnotation];
    NSColor *color = nil;
    NSView *accessoryView = nil;
    
    if ([[self window] isMainWindow]) {
        if ([annotation isNoteAnnotation]) {
            if ([annotation respondsToSelector:@selector(setInteriorColor:)]) {
                if (colorAccessoryView == nil) {
                    colorAccessoryView = [[NSButton alloc] init];
                    [colorAccessoryView setButtonType:NSSwitchButton];
                    [colorAccessoryView setTitle:NSLocalizedString(@"Fill color", @"Button title")];
                    [[colorAccessoryView cell] setControlSize:NSSmallControlSize];
                    [colorAccessoryView setTarget:self];
                    [colorAccessoryView setAction:@selector(changeColorFill:)];
                    [colorAccessoryView sizeToFit];
                }
                accessoryView = colorAccessoryView;
            }
            if ([annotation respondsToSelector:@selector(setInteriorColor:)] && [colorAccessoryView state] == NSOnState) {
                color = [(id)annotation interiorColor];
                if (color == nil)
                    color = [NSColor clearColor];
            } else {
                color = [annotation color];
            }
        }
        if ([[NSColorPanel sharedColorPanel] accessoryView] != accessoryView)
            [[NSColorPanel sharedColorPanel] setAccessoryView:accessoryView];
    }
    
    if (color) {
        updatingColor = YES;
        [[NSColorPanel sharedColorPanel] setColor:color];
        updatingColor = NO;
    }
}

- (void)updateLineInspector {
    PDFAnnotation *annotation = [pdfView activeAnnotation];
    NSString *type = [annotation type];
    
    if ([[self window] isMainWindow]) {
        if ([annotation isNoteAnnotation] && ([type isEqualToString:SKFreeTextString] || [type isEqualToString:SKCircleString] || [type isEqualToString:SKSquareString] || [type isEqualToString:@""] || [type isEqualToString:SKLineString])) {
            updatingLine = YES;
            [[SKLineInspector sharedLineInspector] setAnnotationStyle:annotation];
            updatingLine = NO;
        }
    }
}

- (void)windowDidBecomeMain:(NSNotification *)notification {
    if ([[self window] isEqual:[notification object]]) {
        [self updateFontPanel];
        [self updateColorPanel];
        [self updateLineInspector];
    }
}

- (void)windowDidResignMain:(NSNotification *)notification {
    if ([[[NSColorPanel sharedColorPanel] accessoryView] isEqual:colorAccessoryView])
        [[NSColorPanel sharedColorPanel] setAccessoryView:nil];
}

- (void)windowWillClose:(NSNotification *)notification {
    if ([[notification object] isEqual:[self window]]) {
        // timers retain their target, so invalidate them now or they may keep firing after the PDF is gone
        if (snapshotTimer) {
            [snapshotTimer invalidate];
            [snapshotTimer release];
            snapshotTimer = nil;
        }
        if (temporaryAnnotationTimer) {
            [temporaryAnnotationTimer invalidate];
            [temporaryAnnotationTimer release];
            temporaryAnnotationTimer = nil;
        }
        
        [ownerController setContent:nil];
    }
}

- (void)windowDidChangeScreen:(NSNotification *)notification {
    if ([[notification object] isEqual:[self window]]) {
        if ([self isFullScreen]) {
            NSScreen *screen = [fullScreenWindow screen];
            [fullScreenWindow setFrame:[screen frame] display:NO];
            
            if ([[leftSideWindow screen] isEqual:screen] == NO) {
                [leftSideWindow orderOut:self];
                [leftSideWindow moveToScreen:screen];
                [leftSideWindow collapse];
                [leftSideWindow orderFront:self];
            }
            if ([[rightSideWindow screen] isEqual:screen] == NO) {
                [rightSideWindow orderOut:self];
                [leftSideWindow moveToScreen:screen];
                [rightSideWindow collapse];
                [rightSideWindow orderFront:self];
            }
        } else if ([self isPresentation]) {
            [fullScreenWindow setFrame:[[fullScreenWindow screen] frame] display:NO];
        }
        [pdfView layoutDocumentView];
        [pdfView setNeedsDisplay:YES];
    }
}

- (void)updateLeftStatus {
    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Page %i of %i", @"Status message"), [self pageNumber], [[pdfView document] pageCount]];
    [statusBar setLeftStringValue:message];
}

- (void)updateRightStatus {
    NSRect selRect = [pdfView currentSelectionRect];
    
    NSString *message;
    if (NSEqualRects(selRect, NSZeroRect)) {
        float magnification = [pdfView currentMagnification];
        if (magnification > 0.0001)
            message = [NSString stringWithFormat:@"%.2f x", magnification];
        else
           message = @"";
    } else {
        if ([statusBar state] == NSOnState) {
            BOOL useMetric = [[NSUserDefaults standardUserDefaults] boolForKey:@"AppleMetricUnits"];
            NSString *units = useMetric ? @"cm" : @"in";
            float factor = useMetric ? 0.035277778 : 0.013888889;
            message = [NSString stringWithFormat:@"%.2f x %.2f %@", NSWidth(selRect) * factor, NSHeight(selRect) * factor, units];
        } else {
            message = [NSString stringWithFormat:@"%i x %i pt", (int)NSWidth(selRect), (int)NSHeight(selRect)];
        }
    }
    [statusBar setRightStringValue:message];
}

- (void)updatePageLabelsAndOutline {
    PDFDocument *pdfDoc = [pdfView document];
    NSTableColumn *tableColumn = [thumbnailTableView tableColumnWithIdentifier:@"page"];
    id cell = [tableColumn dataCell];
    float labelWidth = 0.0;
    int i, count = [pdfDoc pageCount];
    
    // update page labels, also update the size of the table columns displaying the labels
    [self willChangeValueForKey:@"pageLabel"];
    [self willChangeValueForKey:@"pageLabels"];
    [pageLabels removeAllObjects];
    for (i = 0; i < count; i++) {
        NSString *label = [[pdfDoc pageAtIndex:i] label];
        if (label == nil)
            label = [NSString stringWithFormat:@"%i", i+1];
        [pageLabels addObject:label];
        [cell setStringValue:label];
        labelWidth = fmaxf(labelWidth, [cell cellSize].width);
    }
    [self didChangeValueForKey:@"pageLabels"];
    [self didChangeValueForKey:@"pageLabel"];
    
    [tableColumn setMinWidth:labelWidth];
    [tableColumn setMaxWidth:labelWidth];
    [thumbnailTableView sizeToFit];
    tableColumn = [outlineView tableColumnWithIdentifier:@"page"];
    [tableColumn setMinWidth:labelWidth];
    [tableColumn setMaxWidth:labelWidth];
    [outlineView sizeToFit];
    tableColumn = [snapshotTableView tableColumnWithIdentifier:@"page"];
    [tableColumn setMinWidth:labelWidth];
    [tableColumn setMaxWidth:labelWidth];
    [snapshotTableView sizeToFit];
    
    // this uses the pageLabels
    [[thumbnailTableView typeSelectHelper] rebuildTypeSelectSearchCache];
    
    // these carry a label, moreover when this is called the thumbnails will also be invalid
    [self resetThumbnails];
    [self allSnapshotsNeedUpdate];
    [noteOutlineView reloadData];
    
    // update the outline
    [pdfOutline release];
    pdfOutline = [[pdfDoc outlineRoot] retain];
    [pdfOutlineItems removeAllObjects];
    
    updatingOutlineSelection = YES;
    // If this is a reload following a TeX run and the user just killed the outline for some reason, we get a crash if the outlineView isn't reloaded, so no longer make it conditional on pdfOutline != nil
    [outlineView reloadData];
    if ([outlineView numberOfRows] == 1)
        [outlineView expandItem: [outlineView itemAtRow: 0] expandChildren: NO];
    updatingOutlineSelection = NO;
    [self updateOutlineSelection];
    
    // handle the case as above where the outline has disappeared in a reload situation
    if (nil == pdfOutline && currentLeftSideView == tocView) {
        [self fadeInThumbnailView];
        [leftSideButton setSelectedSegment:SKThumbnailSidePaneState];
    }

    [leftSideButton setEnabled:pdfOutline != nil forSegment:SKOutlineSidePaneState];
}

- (SKProgressController *)progressController {
    if (progressController == nil)
        progressController = [[SKProgressController alloc] init];
    return progressController;
}

#pragma mark Accessors

- (PDFDocument *)pdfDocument{
    return [pdfView document];
}

- (void)setPdfDocument:(PDFDocument *)document{

    if ([pdfView document] != document) {
        
        unsigned pageIndex = NSNotFound;
        NSRect visibleRect = NSZeroRect;
        NSArray *snapshotDicts = nil;
        
        if ([pdfView document]) {
            pageIndex = [[pdfView currentPage] pageIndex];
            visibleRect = [pdfView convertRect:[pdfView convertRect:[[pdfView documentView] visibleRect] fromView:[pdfView documentView]] toPage:[pdfView currentPage]];
            
            [[pdfView document] cancelFindString];
            [temporaryAnnotationTimer invalidate];
            [temporaryAnnotationTimer release];
            temporaryAnnotationTimer = nil;
            CFSetRemoveAllValues(temporaryAnnotations);
            
            // make sure these will not be activated, or they can lead to a crash
            [pdfView removeHoverRects];
            [pdfView setActiveAnnotation:nil];
            
            // these will be invalid. If needed, the document will restore them
            [[self mutableArrayValueForKey:@"searchResults"] removeAllObjects];
            [[self mutableArrayValueForKey:@"notes"] removeAllObjects];
            [[self mutableArrayValueForKey:@"thumbnails"] removeAllObjects];
            
            snapshotDicts = [snapshots valueForKey:@"currentSetup"];
            [snapshots makeObjectsPerformSelector:@selector(close)];
            [[self mutableArrayValueForKey:@"snapshots"] removeAllObjects];
            
            [pdfOutline release];
            pdfOutline = nil;
            [pdfOutlineItems removeAllObjects];
            
            [lastViewedPages removeAllObjects];
            
            [self unregisterForDocumentNotifications];
            
            [[pdfView document] setDelegate:nil];
        }
        
        [pdfView setDocument:document];
        [[pdfView document] setDelegate:self];
        
        [secondaryPdfView setDocument:document];
        
        [self registerForDocumentNotifications];
        
        [self updatePageLabelsAndOutline];
        [self updateNoteSelection];
        
        [self showSnapshotWithSetups:snapshotDicts];
        
        if (pageIndex != NSNotFound && [document pageCount]) {
            PDFPage *page = [document pageAtIndex:MIN(pageIndex, [document pageCount] - 1)];
            [pdfView goToPage:page];
            [[pdfView window] disableFlushWindow];
            [pdfView display];
            [[pdfView documentView] scrollRectToVisible:[pdfView convertRect:[pdfView convertRect:visibleRect fromPage:page] toView:[pdfView documentView]]];
            [[pdfView window] enableFlushWindow];
        }
        
        // the number of pages may have changed
        [[self window] setTitle:[self windowTitleForDocumentDisplayName:[[self document] displayName]]];
        [self updateLeftStatus];
        [self updateRightStatus];
    }
}
    
- (void)addAnnotationsFromDictionaries:(NSArray *)noteDicts undoable:(BOOL)undoable{
    NSEnumerator *e = [noteDicts objectEnumerator];
    PDFAnnotation *annotation;
    NSDictionary *dict;
    PDFDocument *pdfDoc = [pdfView document];
    NSMutableArray *observedNotes = [self mutableArrayValueForKey:@"notes"];
    
    // create new annotations from the dictionary and add them to their page and to the document
    while (dict = [e nextObject]) {
        unsigned pageIndex = [[dict objectForKey:@"pageIndex"] unsignedIntValue];
        if (annotation = [[PDFAnnotation alloc] initWithDictionary:dict]) {
            if (pageIndex == NSNotFound)
                pageIndex = 0;
            else if (pageIndex >= [pdfDoc pageCount])
                pageIndex = [pdfDoc pageCount] - 1;
            PDFPage *page = [pdfDoc pageAtIndex:pageIndex];
            if (undoable) {
                [pdfView addAnnotation:annotation toPage:page];
            } else {
                [annotation setShouldDisplay:[pdfView hideNotes] == NO];
                [annotation setShouldPrint:[pdfView hideNotes] == NO];
                [page addAnnotation:annotation];
                [pdfView setNeedsDisplayForAnnotation:annotation];
                [observedNotes addObject:annotation];
            }
            [annotation release];
        }
    }
    [noteOutlineView reloadData];
    [self allThumbnailsNeedUpdate];
    [pdfView resetHoverRects];
}

- (void)setAnnotationsFromDictionaries:(NSArray *)noteDicts undoable:(BOOL)undoable{
    NSEnumerator *e = [[[notes copy] autorelease] objectEnumerator];
    PDFAnnotation *annotation;
    
    [pdfView removeHoverRects];
    
    // remove the current annotations
    [pdfView setActiveAnnotation:nil];
    while (annotation = [e nextObject]) {
        if (undoable) {
            [pdfView removeAnnotation:annotation];
        } else {
            [pdfView setNeedsDisplayForAnnotation:annotation];
            [[annotation page] removeAnnotation:annotation];
        }
    }
    
    if (undoable == NO)
        [[self mutableArrayValueForKey:@"notes"] removeAllObjects];
    
    [self addAnnotationsFromDictionaries:noteDicts undoable:undoable];
}

- (SKPDFView *)pdfView {
    return pdfView;
}

- (unsigned int)pageNumber {
    return [[pdfView currentPage] pageIndex] + 1;
}

- (void)setPageNumber:(unsigned int)pageNumber {
    // Check that the page number exists
    unsigned int pageCount = [[pdfView document] pageCount];
    if (pageNumber > pageCount)
        [pdfView goToPage:[[pdfView document] pageAtIndex:pageCount - 1]];
    else if (pageNumber > 0)
        [pdfView goToPage:[[pdfView document] pageAtIndex:pageNumber - 1]];
}

- (NSString *)pageLabel {
    return [[pdfView currentPage] label];
}

- (void)setPageLabel:(NSString *)label {
    unsigned int index = [pageLabels indexOfObject:label];
    if (index != NSNotFound)
        [pdfView goToPage:[[pdfView document] pageAtIndex:index]];
}

- (BOOL)validatePageLabel:(id *)value error:(NSError **)error {
    if ([pageLabels indexOfObject:*value] == NSNotFound)
        *value = [self pageLabel];
    return YES;
}

- (BOOL)isFullScreen {
    return [self window] == fullScreenWindow && isPresentation == NO;
}

- (BOOL)isPresentation {
    return isPresentation;
}

- (BOOL)autoScales {
    return [pdfView autoScales];
}

- (SKLeftSidePaneState)leftSidePaneState {
    return leftSidePaneState;
}

- (void)setLeftSidePaneState:(SKLeftSidePaneState)newLeftSidePaneState {
    if (leftSidePaneState != newLeftSidePaneState) {
        leftSidePaneState = newLeftSidePaneState;
        
        if ([searchField stringValue] && [[searchField stringValue] isEqualToString:@""] == NO) {
            [searchField setStringValue:@""];
            [self removeTemporaryAnnotations];
        }
        
        if (leftSidePaneState == SKThumbnailSidePaneState)
            [self displayThumbnailView];
        else if (leftSidePaneState == SKOutlineSidePaneState)
            [self displayOutlineView];
    }
}

- (SKRightSidePaneState)rightSidePaneState {
    return rightSidePaneState;
}

- (void)setRightSidePaneState:(SKRightSidePaneState)newRightSidePaneState {
    if (rightSidePaneState != newRightSidePaneState) {
        rightSidePaneState = newRightSidePaneState;
        
        if (rightSidePaneState == SKNoteSidePaneState)
            [self displayNoteView];
        else if (rightSidePaneState == SKSnapshotSidePaneState)
            [self displaySnapshotView];
    }
}

- (BOOL)leftSidePaneIsOpen {
    int state;
    if ([self isFullScreen])
        state = [leftSideWindow state];
    else if (usesDrawers)
        state = [leftSideDrawer state];
    else
        state = NSWidth([leftSideContentView frame]) > 0.0 ? NSDrawerOpenState : NSDrawerClosedState;
    return state == NSDrawerOpenState || state == NSDrawerOpeningState;
}

- (BOOL)rightSidePaneIsOpen {
    int state;
    if ([self isFullScreen])
        state = [rightSideWindow state];
    else if (usesDrawers)
        state = [rightSideDrawer state];
    else
        state = NSWidth([rightSideContentView frame]) > 0.0 ? NSDrawerOpenState : NSDrawerClosedState;
    return state == NSDrawerOpenState || state == NSDrawerOpeningState;
}

- (NSArray *)notes {
    return notes;
}

- (void)setNotes:(NSArray *)newNotes {
    [notes setArray:notes];
    [noteOutlineView reloadData];
}

- (unsigned)countOfNotes {
    return [notes count];
}

- (id)objectInNotesAtIndex:(unsigned)theIndex {
    return [notes objectAtIndex:theIndex];
}

- (void)insertObject:(id)obj inNotesAtIndex:(unsigned)theIndex {
    [notes insertObject:obj atIndex:theIndex];
}

- (void)removeObjectFromNotesAtIndex:(unsigned)theIndex {
    PDFAnnotation *note = [notes objectAtIndex:theIndex];
    NSEnumerator *wcEnum = [[[self document] windowControllers] objectEnumerator];
    NSWindowController *wc = [wcEnum nextObject];
    
    while (wc = [wcEnum nextObject]) {
        if ([wc isKindOfClass:[SKNoteWindowController class]] && [[(SKNoteWindowController *)wc note] isEqual:note]) {
            [[wc window] orderOut:self];
            break;
        }
    }
    
    [notes removeObjectAtIndex:theIndex];
}

- (unsigned)countOfThumbnails {
    return [thumbnails count];
}

- (id)objectInThumbnailsAtIndex:(unsigned)theIndex {
    SKThumbnail *thumbnail = [thumbnails objectAtIndex:theIndex];
    
    if ([thumbnail isDirty] && NO == isAnimating && NO == [thumbnailTableView isScrolling] && [[pdfView document] isLocked] == NO) {
        
        NSSize newSize, oldSize = [[thumbnail image] size];
        PDFDocument *pdfDoc = [pdfView document];
        PDFPage *page = [pdfDoc pageAtIndex:theIndex];
        NSRect readingBarRect = [[[pdfView readingBar] page] isEqual:page] ? [[pdfView readingBar] currentBoundsForBox:[pdfView displayBox]] : NSZeroRect;
        NSImage *image = [page thumbnailWithSize:thumbnailCacheSize forBox:[pdfView displayBox] readingBarRect:readingBarRect];
        
        // setImage: sends a KVO notification that results in calling objectInThumbnailsAtIndex: endlessly, so set dirty to NO first
        [thumbnail setDirty:NO];
        [thumbnail setImage:image];
        
        newSize = [image size];
        if (fabsf(newSize.width - oldSize.width) > 1.0 || fabsf(newSize.height - oldSize.height) > 1.0) {
            [thumbnailTableView performSelector:@selector(noteHeightOfRowsWithIndexesChanged:) withObject:[NSIndexSet indexSetWithIndex:theIndex] afterDelay:0.0];
        }
    }
    return thumbnail;
}

- (void)insertObject:(id)obj inThumbnailsAtIndex:(unsigned)theIndex {
    [thumbnails insertObject:obj atIndex:theIndex];
}

- (void)removeObjectFromThumbnailsAtIndex:(unsigned)theIndex {
    [thumbnails removeObjectAtIndex:theIndex];
}

- (NSArray *)snapshots {
    return snapshots;
}

- (void)setSnapshots:(NSArray *)newSnapshots {
    [snapshots setArray:snapshots];
}

- (unsigned)countOfSnapshots {
    return [snapshots count];
}

- (id)objectInSnapshotsAtIndex:(unsigned)theIndex {
    return [snapshots objectAtIndex:theIndex];
}

- (void)insertObject:(id)obj inSnapshotsAtIndex:(unsigned)theIndex {
    [snapshots insertObject:obj atIndex:theIndex];
}

- (void)removeObjectFromSnapshotsAtIndex:(unsigned)theIndex {
    [dirtySnapshots removeObject:[snapshots objectAtIndex:theIndex]];
    [snapshots removeObjectAtIndex:theIndex];
}

- (PDFAnnotation *)selectedNote {
    int row = [noteOutlineView selectedRow];
    id item = nil;
    if (row != -1) {
        item = [noteOutlineView itemAtRow:row];
        if ([item type] == nil)
            item = [(SKNoteText *)item annotation];
    }
    return item;
}

#pragma mark Actions

- (IBAction)changeColor:(id)sender{
    PDFAnnotation *annotation = [pdfView activeAnnotation];
    if (updatingColor == NO && [annotation isNoteAnnotation]) {
        BOOL isFill = [colorAccessoryView state] == NSOnState && [annotation respondsToSelector:@selector(setInteriorColor:)];
        NSColor *color = isFill ? [(id)annotation interiorColor] : [annotation color];
        if (color == nil)
            color = [NSColor clearColor];
        if ([color isEqual:[sender color]] == NO) {
            updatingColor = YES;
            if (isFill)
                [(id)annotation setInteriorColor:[[sender color] alphaComponent] > 0.0 ? [sender color] : nil];
            else
                [annotation setColor:[sender color]];
            updatingColor = NO;
        }
    }
}

- (IBAction)changeColorFill:(id)sender{
   [self updateColorPanel];
}

- (IBAction)selectColor:(id)sender{
    PDFAnnotation *annotation = [pdfView activeAnnotation];
    if ([annotation isNoteAnnotation]) {
        NSColor *color = [annotation color];
        NSColor *newColor = [sender respondsToSelector:@selector(representedObject)] ? [sender representedObject] : [sender respondsToSelector:@selector(color)] ? [sender color] : nil;
        if (newColor && [color isEqual:newColor] == NO)
            [annotation setColor:newColor];
    }
}

- (IBAction)changeFont:(id)sender{
    PDFAnnotation *annotation = [pdfView activeAnnotation];
    if (updatingFont == NO && [annotation isNoteAnnotation] && [annotation respondsToSelector:@selector(setFont:)] && [annotation respondsToSelector:@selector(font)]) {
        NSFont *font = [sender convertFont:[(PDFAnnotationFreeText *)annotation font]];
        updatingFont = YES;
        [(PDFAnnotationFreeText *)annotation setFont:font];
        updatingFont = NO;
    }
}

- (void)changeLineWidth:(id)sender {
    PDFAnnotation *annotation = [pdfView activeAnnotation];
    NSString *type = [annotation type];
    if (updatingLine == NO && [annotation isNoteAnnotation] && ([type isEqualToString:SKFreeTextString] || [type isEqualToString:SKCircleString] || [type isEqualToString:SKSquareString] || [type isEqualToString:@""] || [type isEqualToString:SKLineString])) {
        [annotation setLineWidth:[sender lineWidth]];
    }
}

- (void)changeLineStyle:(id)sender {
    PDFAnnotation *annotation = [pdfView activeAnnotation];
    NSString *type = [annotation type];
    if (updatingLine == NO && [annotation isNoteAnnotation] && ([type isEqualToString:SKFreeTextString] || [type isEqualToString:SKCircleString] || [type isEqualToString:SKSquareString] || [type isEqualToString:SKLineString])) {
        [annotation setBorderStyle:[sender style]];
    }
}

- (void)changeDashPattern:(id)sender {
    PDFAnnotation *annotation = [pdfView activeAnnotation];
    NSString *type = [annotation type];
    if (updatingLine == NO && [annotation isNoteAnnotation] && ([type isEqualToString:SKFreeTextString] || [type isEqualToString:SKCircleString] || [type isEqualToString:SKSquareString] || [type isEqualToString:SKLineString])) {
        [annotation setDashPattern:[sender dashPattern]];
    }
}

- (void)changeStartLineStyle:(id)sender {
    PDFAnnotation *annotation = [pdfView activeAnnotation];
    NSString *type = [annotation type];
    if (updatingLine == NO && [annotation isNoteAnnotation] && [type isEqualToString:SKLineString]) {
        updatingLine = YES;
        [(SKPDFAnnotationLine *)annotation setStartLineStyle:[sender startLineStyle]];
        updatingLine = NO;
    }
}

- (void)changeEndLineStyle:(id)sender {
    PDFAnnotation *annotation = [pdfView activeAnnotation];
    NSString *type = [annotation type];
    if (updatingLine == NO && [annotation isNoteAnnotation] && [type isEqualToString:SKLineString]) {
        updatingLine = YES;
        [(SKPDFAnnotationLine *)annotation setEndLineStyle:[sender endLineStyle]];
        updatingLine = NO;
    }
}

- (IBAction)createNewNote:(id)sender{
    if ([pdfView hideNotes] == NO) {
        int type = [sender respondsToSelector:@selector(selectedSegment)] ? [sender selectedSegment] : [sender tag];
        [pdfView addAnnotationFromSelectionWithType:type];
    } else NSBeep();
}

- (IBAction)editNote:(id)sender{
    if ([pdfView hideNotes] == NO) {
        [pdfView editActiveAnnotation:sender];
    } else NSBeep();
}

- (void)selectSelectedNote{
    if ([pdfView hideNotes] == NO) {
        id annotation = [self selectedNote];
        if (annotation) {
            [pdfView scrollAnnotationToVisible:annotation];
            [pdfView setActiveAnnotation:annotation];
        }
    } else NSBeep();
}

- (IBAction)toggleHideNotes:(id)sender{
    BOOL wasHidden = [pdfView hideNotes];
    NSEnumerator *noteEnum = [notes objectEnumerator];
    PDFAnnotation *note;
    while (note = [noteEnum nextObject]) {
        [note setShouldDisplay:wasHidden];
        [note setShouldPrint:wasHidden];
    }
    [pdfView setHideNotes:wasHidden == NO];
}

- (void)goToSelectedOutlineItem {
    updatingOutlineSelection = YES;
    [pdfView goToDestination: [[outlineView itemAtRow: [outlineView selectedRow]] destination]];
    updatingOutlineSelection = NO;
}

- (IBAction)takeSnapshot:(id)sender{
    [pdfView takeSnapshot:sender];
}

- (IBAction)displaySinglePages:(id)sender {
    PDFDisplayMode displayMode = [pdfView displayMode];
    if (displayMode == kPDFDisplayTwoUp)
        [pdfView setDisplayMode:kPDFDisplaySinglePage];
    else if (displayMode == kPDFDisplayTwoUpContinuous)
        [pdfView setDisplayMode:kPDFDisplaySinglePageContinuous];
}

- (IBAction)displayFacingPages:(id)sender {
    PDFDisplayMode displayMode = [pdfView displayMode];
    if (displayMode == kPDFDisplaySinglePage) 
        [pdfView setDisplayMode:kPDFDisplayTwoUp];
    else if (displayMode == kPDFDisplaySinglePageContinuous)
        [pdfView setDisplayMode:kPDFDisplayTwoUpContinuous];
}

- (IBAction)toggleDisplayContinuous:(id)sender {
    PDFDisplayMode displayMode = [pdfView displayMode];
    if (displayMode == kPDFDisplaySinglePage) 
        displayMode = kPDFDisplaySinglePageContinuous;
    else if (displayMode == kPDFDisplaySinglePageContinuous)
        displayMode = kPDFDisplaySinglePage;
    else if (displayMode == kPDFDisplayTwoUp)
        displayMode = kPDFDisplayTwoUpContinuous;
    else if (displayMode == kPDFDisplayTwoUpContinuous)
        displayMode = kPDFDisplayTwoUp;
    [pdfView setDisplayMode:displayMode];
}

- (IBAction)toggleDisplayAsBook:(id)sender {
    [pdfView setDisplaysAsBook:[pdfView displaysAsBook] == NO];
}

- (IBAction)toggleDisplayPageBreaks:(id)sender {
    [pdfView setDisplaysPageBreaks:[pdfView displaysPageBreaks] == NO];
}

- (IBAction)changeDisplayBox:(id)sender {
    PDFDisplayBox displayBox = [sender tag];
    if ([sender respondsToSelector:@selector(indexOfSelectedItem)])
        displayBox = [sender indexOfSelectedItem] == 0 ? kPDFDisplayBoxMediaBox : kPDFDisplayBoxCropBox;
    [pdfView setDisplayBox:displayBox];
    [displayBoxPopUpButton selectItemWithTag:displayBox];
    [self resetThumbnails];
}

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

- (IBAction)goToFirstOrPreviousPage:(id)sender {
    if ([sender selectedSegment] == 0)
        [pdfView goToFirstPage:sender];
    else
        [pdfView goToPreviousPage:sender];
}

- (IBAction)goToNextOrLastPage:(id)sender {
    if ([sender selectedSegment] == 0)
        [pdfView goToNextPage:sender];
    else
        [pdfView goToLastPage:sender];
}

- (void)pageSheetDidEnd:(SKPageSheetController *)controller returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSOKButton)
        [self setPageLabel:[controller stringValue]];
}

- (IBAction)doGoToPage:(id)sender {
    if (pageSheetController == nil)
        pageSheetController = [[SKPageSheetController alloc] init];
    
    [pageSheetController setObjectValues:pageLabels];
    [pageSheetController setStringValue:[self pageLabel]];
    
    [pageSheetController beginSheetModalForWindow: [self window]
        modalDelegate: self
       didEndSelector: @selector(pageSheetDidEnd:returnCode:contextInfo:)
          contextInfo: nil];
}

- (IBAction)doGoBack:(id)sender {
    [pdfView goBack:sender];
}

- (IBAction)doGoForward:(id)sender {
    [pdfView goForward:sender];
}

- (IBAction)goBackOrForward:(id)sender {
    if ([sender selectedSegment] == 1)
        [pdfView goForward:sender];
    else
        [pdfView goBack:sender];
}

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

- (IBAction)doZoomToSelection:(id)sender {
    NSRect selRect = [pdfView currentSelectionRect];
    if (NSIsEmptyRect(selRect) == NO) {
        NSRect bounds = [pdfView bounds];
        float scale = 1.0;
        bounds.size.width -= [NSScroller scrollerWidth];
        bounds.size.height -= [NSScroller scrollerWidth];
        if (NSWidth(bounds) * NSHeight(selRect) > NSWidth(selRect) * NSHeight(bounds))
            scale = NSHeight(bounds) / NSHeight(selRect);
        else
            scale = NSWidth(bounds) / NSWidth(selRect);
        [pdfView setScaleFactor:scale];
        NSScrollView *scrollView = [[pdfView documentView] enclosingScrollView];
        if ([scrollView hasHorizontalScroller] == NO || [scrollView hasVerticalScroller] == NO) {
            bounds = [pdfView bounds];
            if ([scrollView hasVerticalScroller])
                bounds.size.width -= [NSScroller scrollerWidth];
            if ([scrollView hasHorizontalScroller])
                bounds.size.height -= [NSScroller scrollerWidth];
            if (NSWidth(bounds) * NSHeight(selRect) > NSWidth(selRect) * NSHeight(bounds))
                scale = NSHeight(bounds) / NSHeight(selRect);
            else
                scale = NSWidth(bounds) / NSWidth(selRect);
            [pdfView setScaleFactor:scale];
        }
        [pdfView scrollRect:selRect inPageToVisible:[pdfView currentPage]]; 
    } else NSBeep();
}

- (IBAction)doZoomToFit:(id)sender {
    [pdfView setAutoScales:YES];
    [pdfView setAutoScales:NO];
}

- (IBAction)doAutoScale:(id)sender {
    [pdfView setAutoScales:YES];
}

- (IBAction)toggleAutoScale:(id)sender {
    if ([self isPresentation])
        [self toggleAutoActualSize:sender];
    else
        [pdfView setAutoScales:[pdfView autoScales] == NO];
}

- (IBAction)toggleAutoActualSize:(id)sender {
    if ([pdfView autoScales])
        [self doZoomToActualSize:sender];
    else
        [self doAutoScale:sender];
}

- (void)rotatePageAtIndex:(unsigned int)index by:(int)rotation {
    NSUndoManager *undoManager = [[self document] undoManager];
    [[undoManager prepareWithInvocationTarget:self] rotatePageAtIndex:index by:-rotation];
    [undoManager setActionName:NSLocalizedString(@"Rotate Page", @"Undo action name")];
    [[self document] updateChangeCount:[undoManager isUndoing] ? NSChangeDone : NSChangeUndone];
    
    PDFPage *page = [[pdfView document] pageAtIndex:index];
    [page setRotation:[page rotation] + rotation];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFDocumentPageBoundsDidChangeNotification 
            object:[pdfView document] userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"rotate", @"action", page, @"page", nil]];
}

- (IBAction)rotateRight:(id)sender {
    [self rotatePageAtIndex:[[pdfView currentPage] pageIndex] by:90];
}

- (IBAction)rotateLeft:(id)sender {
    [self rotatePageAtIndex:[[pdfView currentPage] pageIndex] by:-90];
}

- (IBAction)rotateAllRight:(id)sender {
    NSUndoManager *undoManager = [[self document] undoManager];
    [[undoManager prepareWithInvocationTarget:self] rotateAllLeft:nil];
    [undoManager setActionName:NSLocalizedString(@"Rotate", @"Undo action name")];
    [[self document] updateChangeCount:[undoManager isUndoing] ? NSChangeDone : NSChangeUndone];
    
    int i, count = [[pdfView document] pageCount];
    for (i = 0; i < count; i++) {
        [[[pdfView document] pageAtIndex:i] setRotation:[[[pdfView document] pageAtIndex:i] rotation] + 90];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFDocumentPageBoundsDidChangeNotification 
            object:[pdfView document] userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"rotate", @"action", nil]];
}

- (IBAction)rotateAllLeft:(id)sender {
    NSUndoManager *undoManager = [[self document] undoManager];
    [[undoManager prepareWithInvocationTarget:self] rotateAllRight:nil];
    [undoManager setActionName:NSLocalizedString(@"Rotate", @"Undo action name")];
    [[self document] updateChangeCount:[undoManager isUndoing] ? NSChangeDone : NSChangeUndone];
    
    int i, count = [[pdfView document] pageCount];
    for (i = 0; i < count; i++) {
        [[[pdfView document] pageAtIndex:i] setRotation:[[[pdfView document] pageAtIndex:i] rotation] - 90];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFDocumentPageBoundsDidChangeNotification 
            object:[pdfView document] userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"rotate", @"action", nil]];
}

- (void)cropPageAtIndex:(unsigned int)index toRect:(NSRect)rect {
    NSRect oldRect = [[[pdfView document] pageAtIndex:index] boundsForBox:kPDFDisplayBoxCropBox];
    NSUndoManager *undoManager = [[self document] undoManager];
    [[undoManager prepareWithInvocationTarget:self] cropPageAtIndex:index toRect:oldRect];
    [undoManager setActionName:NSLocalizedString(@"Crop Page", @"Undo action name")];
    [[self document] updateChangeCount:[undoManager isUndoing] ? NSChangeDone : NSChangeUndone];
    
    PDFPage *page = [[pdfView document] pageAtIndex:index];
    rect = NSIntersectionRect(rect, [page boundsForBox:kPDFDisplayBoxMediaBox]);
    [page setBounds:rect forBox:kPDFDisplayBoxCropBox];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFDocumentPageBoundsDidChangeNotification 
            object:[pdfView document] userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"crop", @"action", page, @"page", nil]];
}

- (IBAction)crop:(id)sender {
    NSRect rect = NSIntegralRect([pdfView currentSelectionRect]);
    if (NSIsEmptyRect(rect))
        rect = [[pdfView currentPage] foregroundBox];
    [self cropPageAtIndex:[[pdfView currentPage] pageIndex] toRect:rect];
}

- (void)cropPagesToRects:(NSArray *)rects {
    PDFPage *currentPage = [pdfView currentPage];
    NSRect visibleRect = [pdfView convertRect:[pdfView convertRect:[[pdfView documentView] visibleRect] fromView:[pdfView documentView]] toPage:[pdfView currentPage]];
    
    int i, count = [[pdfView document] pageCount];
    int rectCount = [rects count];
    NSMutableArray *oldRects = [NSMutableArray arrayWithCapacity:count];
    for (i = 0; i < count; i++) {
        PDFPage *page = [[pdfView document] pageAtIndex:i];
        NSRect rect = NSIntersectionRect([[rects objectAtIndex:i % rectCount] rectValue], [page boundsForBox:kPDFDisplayBoxMediaBox]);
        [oldRects addObject:[NSValue valueWithRect:[page boundsForBox:kPDFDisplayBoxCropBox]]];
        [page setBounds:rect forBox:kPDFDisplayBoxCropBox];
    }
    
    NSUndoManager *undoManager = [[self document] undoManager];
    [[undoManager prepareWithInvocationTarget:self] cropPagesToRects:oldRects];
    [undoManager setActionName:NSLocalizedString(@"Crop", @"Undo action name")];
    [[self document] updateChangeCount:[undoManager isUndoing] ? NSChangeDone : NSChangeUndone];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFDocumentPageBoundsDidChangeNotification 
            object:[pdfView document] userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"crop", @"action", nil]];
    
    // layout after cropping when you're in the middle of a document can lose the current page
    [pdfView goToPage:currentPage];
    [[pdfView documentView] scrollRectToVisible:[pdfView convertRect:[pdfView convertRect:visibleRect fromPage:currentPage] toView:[pdfView documentView]]];
}

- (IBAction)cropAll:(id)sender {
    NSRect rect[2] = {NSIntegralRect([pdfView currentSelectionRect]), NSZeroRect};
    NSArray *rectArray;
    BOOL emptySelection = NSIsEmptyRect(rect[0]);
    
    if (emptySelection) {
        int i, j, count = [[pdfView document] pageCount];
        rect[0] = rect[1] = NSZeroRect;
        
        [[self progressController] setMaxValue:(double)MIN(18, count)];
        [[self progressController] setDoubleValue:0.0];
        [[self progressController] setMessage:[NSLocalizedString(@"Cropping Pages", @"Message for progress sheet") stringByAppendingEllipsis]];
        [[self progressController] beginSheetModalForWindow:[self window]];
        
        if (count < 18) {
            for (i = 0; i < count; i++) {
                rect[i % 2] = NSUnionRect(rect[i % 2], [[[pdfView document] pageAtIndex:i] foregroundBox]);
                [[self progressController] incrementBy:1.0];
            }
        } else {
            int start[3] = {0, count / 2 - 3, count - 6};
            for (j = 0; j < 3; j++) {
                for (i = start[j]; i < start[j] + 6; i++) {
                    rect[i % 2] = NSUnionRect(rect[i % 2], [[[pdfView document] pageAtIndex:i] foregroundBox]);
                    [[self progressController] setDoubleValue:(double)(3 * j + i)];
                }
            }
        }
        float w = fmaxf(NSWidth(rect[0]), NSWidth(rect[1]));
        float h = fmaxf(NSHeight(rect[0]), NSHeight(rect[1]));
        for (j = 0; j < 2; j++)
            rect[j] = NSMakeRect(floorf(NSMidX(rect[j]) - 0.5 * w), floorf(NSMidY(rect[j]) - 0.5 * h), w, h);
        rectArray = [NSArray arrayWithObjects:[NSValue valueWithRect:rect[0]], [NSValue valueWithRect:rect[1]], nil];
    } else {
        rectArray = [NSArray arrayWithObject:[NSValue valueWithRect:rect[0]]];
    }
    
    [self cropPagesToRects:rectArray];
    [pdfView setCurrentSelectionRect:NSZeroRect];
	
    if (emptySelection) {
        [[self progressController] endSheet];
    }
}

- (IBAction)autoCropAll:(id)sender {
    NSMutableArray *rectArray = [NSMutableArray array];
    PDFDocument *pdfDoc = [pdfView document];
    int i, iMax = [[pdfView document] pageCount];
    
	[[self progressController] setMaxValue:(double)iMax];
	[[self progressController] setDoubleValue:0.0];
	[[self progressController] setMessage:[NSLocalizedString(@"Cropping Pages", @"Message for progress sheet") stringByAppendingEllipsis]];
	[[self progressController] beginSheetModalForWindow:[self window]];
    
    for (i = 0; i < iMax; i++) {
        [rectArray addObject:[NSValue valueWithRect:[[pdfDoc pageAtIndex:i] foregroundBox]]];
        [[self progressController] incrementBy:1.0];
        if (i && i % 10 == 0)
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
    [self cropPagesToRects:rectArray];
	
    [[self progressController] endSheet];
}

- (IBAction)smartAutoCropAll:(id)sender {
    NSMutableArray *rectArray = [NSMutableArray array];
    PDFDocument *pdfDoc = [pdfView document];
    int i, iMax = [pdfDoc pageCount];
    NSSize size = NSZeroSize;
    
	[[self progressController] setMaxValue:1.1 * iMax];
	[[self progressController] setDoubleValue:0.0];
	[[self progressController] setMessage:[NSLocalizedString(@"Cropping Pages", @"Message for progress sheet") stringByAppendingEllipsis]];
	[[self progressController] beginSheetModalForWindow:[self window]];
    
    for (i = 0; i < iMax; i++) {
        NSRect bbox = [[pdfDoc pageAtIndex:i] foregroundBox];
        size.width = fmaxf(size.width, NSWidth(bbox));
        size.height = fmaxf(size.height, NSHeight(bbox));
        [[self progressController] incrementBy:1.0];
        if (i && i % 10 == 0)
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    for (i = 0; i < iMax; i++) {
        PDFPage *page = [pdfDoc pageAtIndex:i];
        NSRect rect = [page foregroundBox];
        NSRect bounds = [page boundsForBox:kPDFDisplayBoxMediaBox];
        if (NSMinX(rect) - NSMinX(bounds) > NSMaxX(bounds) - NSMaxX(rect))
            rect.origin.x = NSMaxX(rect) - size.width;
        rect.origin.y = NSMaxY(rect) - size.height;
        rect.size = size;
        rect = SKConstrainRect(rect, bounds);
        [rectArray addObject:[NSValue valueWithRect:rect]];
        if (i && i % 10 == 0) {
            [[self progressController] incrementBy:1.0];
            if (i && i % 100 == 0)
                [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
        }
    }
    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    [self cropPagesToRects:rectArray];
	
    [[self progressController] endSheet];
}

- (IBAction)autoSelectContent:(id)sender {
    [pdfView autoSelectContent:sender];
}

- (IBAction)getInfo:(id)sender {
    SKInfoWindowController *infoController = [SKInfoWindowController sharedInstance];
    [infoController fillInfoForDocument:[self document]];
    [infoController showWindow:self];
}

- (IBAction)changeScaleFactor:(id)sender {
    int scale = [sender intValue];

	if (scale >= 10.0 && scale <= 500.0 ) {
		[pdfView setScaleFactor:scale / 100.0f];
		[pdfView setAutoScales:NO];
	}
}

- (void)scaleSheetDidEnd:(SKScaleSheetController *)controller returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSOKButton)
        [pdfView setScaleFactor:[[controller textField] intValue]];
}

- (IBAction)chooseScale:(id)sender {
    if (scaleSheetController == nil)
        scaleSheetController = [[SKScaleSheetController alloc] init];
    
    [[scaleSheetController textField] setIntValue:[pdfView scaleFactor]];
    
    [scaleSheetController beginSheetModalForWindow: [self window]
        modalDelegate: self
       didEndSelector: @selector(scaleSheetDidEnd:returnCode:contextInfo:)
          contextInfo: nil];
}

- (IBAction)changeToolMode:(id)sender {
    int newToolMode = [sender respondsToSelector:@selector(selectedSegment)] ? [sender selectedSegment] : [sender tag];
    [pdfView setToolMode:newToolMode];
}

- (IBAction)changeAnnotationMode:(id)sender {
    [pdfView setToolMode:SKNoteToolMode];
    [pdfView setAnnotationMode:[sender tag]];
}

- (IBAction)statusBarClicked:(id)sender {
    [self updateRightStatus];
}

- (IBAction)toggleStatusBar:(id)sender {
    if (statusBar == nil) {
        statusBar = [[SKStatusBar alloc] initWithFrame:NSMakeRect(0.0, 0.0, NSWidth([splitView frame]), 20.0)];
        [statusBar setAutoresizingMask:NSViewWidthSizable | NSViewMaxYMargin];
        [self updateLeftStatus];
        [self updateRightStatus];
        [statusBar setAction:@selector(statusBarClicked:)];
        [statusBar setTarget:self];
    }
    [statusBar toggleBelowView:splitView offset:1.0];
    [[NSUserDefaults standardUserDefaults] setBool:[statusBar isVisible] forKey:SKShowStatusBarKey];
}

- (IBAction)searchPDF:(id)sender {
    if ([self isFullScreen]) {
        if ([leftSideWindow state] == NSDrawerClosedState || [leftSideWindow state] == NSDrawerClosingState)
            [leftSideWindow expand];
    } else if ([self leftSidePaneIsOpen] == NO) {
        [self toggleLeftSidePane:sender];
    }
    [searchField selectText:self];
}

- (IBAction)performFit:(id)sender {
    if ([self isFullScreen] || [self isPresentation]) {
        NSBeep();
        return;
    }
    
    PDFDisplayMode displayMode = [pdfView displayMode];
    NSRect frame = [splitView frame];
    NSRect documentRect = [[[self pdfView] documentView] convertRect:[[[self pdfView] documentView] bounds] toView:nil];
    float bottomOffset = -1.0;
    
    if ([[self pdfView] autoScales]) {
        documentRect.size.width /= [[self pdfView] scaleFactor];
        documentRect.size.height /= [[self pdfView] scaleFactor];
    }
    
    frame.size.width = NSWidth(documentRect);
    if (usesDrawers == NO)
        frame.size.width += NSWidth([leftSideContentView frame]) + NSWidth([rightSideContentView frame]) + 2 * [splitView dividerThickness] + 2.0;
    if (displayMode == kPDFDisplaySinglePage || displayMode == kPDFDisplayTwoUp) {
        frame.size.height = NSHeight(documentRect) + 1.0;
    } else {
        NSRect pageBounds = [[self pdfView] convertRect:[[[self pdfView] currentPage] boundsForBox:[[self pdfView] displayBox]] fromPage:[[self pdfView] currentPage]];
        if ([[self pdfView] autoScales]) {
            pageBounds.size.width /= [[self pdfView] scaleFactor];
            pageBounds.size.height /= [[self pdfView] scaleFactor];
        }
        frame.size.height = NSHeight(pageBounds) + NSWidth(documentRect) - NSWidth(pageBounds) + 1.0;
        frame.size.width += [NSScroller scrollerWidth];
    }
    
    if ([statusBar isVisible])
        bottomOffset = NSHeight([statusBar frame]);
    frame.origin.y -= bottomOffset;
    frame.size.height += bottomOffset;
    
    frame.origin = [[self window] convertBaseToScreen:[[[self window] contentView] convertPoint:frame.origin toView:nil]];
    frame = [[self window] frameRectForContentRect:frame];
    frame = SKConstrainRect(frame, [[[self window] screen] visibleFrame]);
    
    [[self window] setFrame:frame display:[[self window] isVisible]];
}

- (void)passwordSheetDidEnd:(SKPasswordSheetController *)controller returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSOKButton) {
        [pdfView takePasswordFrom:[controller textField]];
        if ([[pdfView document] isLocked] == NO)
            [[self document] savePasswordInKeychain:[controller stringValue]];
    }
}

- (IBAction)password:(id)sender {
    if (passwordSheetController == nil)
        passwordSheetController = [[SKPasswordSheetController alloc] init];
    
    [passwordSheetController beginSheetModalForWindow: [self window]
        modalDelegate:self 
       didEndSelector:@selector(passwordSheetDidEnd:returnCode:contextInfo:)
          contextInfo:NULL];
}

- (IBAction)toggleReadingBar:(id)sender {
    [pdfView toggleReadingBar];
}

- (IBAction)savePDFSettingToDefaults:(id)sender {
    if ([self isFullScreen])
        [[NSUserDefaults standardUserDefaults] setObject:[self currentPDFSettings] forKey:SKDefaultFullScreenPDFDisplaySettingsKey];
    else if ([self isPresentation] == NO)
        [[NSUserDefaults standardUserDefaults] setObject:[self currentPDFSettings] forKey:SKDefaultPDFDisplaySettingsKey];
}

- (IBAction)chooseTransition:(id)sender {
    [[[self pdfView] transitionController] chooseTransitionModalForWindow:[self window]];
}

- (IBAction)toggleLeftSidePane:(id)sender {
    if ([self isFullScreen]) {
        [[SKPDFHoverWindow sharedHoverWindow] hide];
        if ([self leftSidePaneIsOpen])
            [leftSideWindow collapse];
        else
            [leftSideWindow expand];
    } else if ([self isPresentation]) {
        if ([leftSideWindow isVisible])
            [self hideLeftSideWindow];
        else
            [self showLeftSideWindowOnScreen:[[self window] screen]];
    } else if (usesDrawers) {
        if ([self leftSidePaneIsOpen]) {
            if (leftSidePaneState == SKOutlineSidePaneState || [[searchField stringValue] length])
                [[SKPDFHoverWindow sharedHoverWindow] hide];
            [leftSideDrawer close];
        } else {
            [leftSideDrawer openOnEdge:NSMinXEdge];
        }
    } else {
        NSRect sideFrame = [leftSideContentView frame];
        NSRect pdfFrame = [pdfSplitView frame];
        
        if ([self leftSidePaneIsOpen]) {
            if (leftSidePaneState == SKOutlineSidePaneState || [[searchField stringValue] length])
                [[SKPDFHoverWindow sharedHoverWindow] hide];
            lastLeftSidePaneWidth = NSWidth(sideFrame); // cache this
            pdfFrame.size.width += lastLeftSidePaneWidth;
            sideFrame.size.width = 0.0;
        } else {
            if(lastLeftSidePaneWidth <= 0.0)
                lastLeftSidePaneWidth = 250.0; // a reasonable value to start
            if (lastLeftSidePaneWidth > 0.5 * NSWidth(pdfFrame))
                lastLeftSidePaneWidth = floorf(0.5 * NSWidth(pdfFrame));
            pdfFrame.size.width -= lastLeftSidePaneWidth;
            sideFrame.size.width = lastLeftSidePaneWidth;
        }
        pdfFrame.origin.x = NSMaxX(sideFrame) + [splitView dividerThickness];
        [leftSideContentView setFrame:sideFrame];
        [pdfSplitView setFrame:pdfFrame];
        [splitView setNeedsDisplay:YES];
        
        [self splitViewDidResizeSubviews:nil];
    }
}

- (IBAction)toggleRightSidePane:(id)sender {
    if ([self isFullScreen]) {
        if ([self rightSidePaneIsOpen])
            [rightSideWindow collapse];
        else
            [rightSideWindow expand];
    } else if ([self isPresentation]) {
        if ([rightSideWindow isVisible])
            [self hideRightSideWindow];
        else
            [self showRightSideWindowOnScreen:[[self window] screen]];
    } else if (usesDrawers) {
        if ([self rightSidePaneIsOpen])
            [rightSideDrawer close];
        else
            [rightSideDrawer openOnEdge:NSMaxXEdge];
    } else {
        NSRect sideFrame = [rightSideContentView frame];
        NSRect pdfFrame = [pdfSplitView frame];
        
        if ([self rightSidePaneIsOpen]) {
            lastRightSidePaneWidth = NSWidth(sideFrame); // cache this
            pdfFrame.size.width += lastRightSidePaneWidth;
            sideFrame.size.width = 0.0;
        } else {
            if(lastRightSidePaneWidth <= 0.0)
                lastRightSidePaneWidth = 250.0; // a reasonable value to start
            if (lastRightSidePaneWidth > 0.5 * NSWidth(pdfFrame))
                lastRightSidePaneWidth = floorf(0.5 * NSWidth(pdfFrame));
            pdfFrame.size.width -= lastRightSidePaneWidth;
            sideFrame.size.width = lastRightSidePaneWidth;
        }
        sideFrame.origin.x = NSMaxX(pdfFrame) + [splitView dividerThickness];
        [rightSideContentView setFrame:sideFrame];
        [pdfSplitView setFrame:pdfFrame];
        [splitView setNeedsDisplay:YES];
        
        [self splitViewDidResizeSubviews:nil];
    }
}

- (IBAction)changeLeftSidePaneState:(id)sender {
    [self setLeftSidePaneState:[sender tag]];
}

- (IBAction)changeRightSidePaneState:(id)sender {
    [self setRightSidePaneState:[sender tag]];
}

- (void)scrollSecondaryPdfView {
    NSPoint point = [pdfView bounds].origin;
    PDFPage *page = [pdfView pageForPoint:point nearest:YES];
    point = [secondaryPdfView convertPoint:[secondaryPdfView convertPoint:[pdfView convertPoint:point toPage:page] fromPage:page] toView:[secondaryPdfView documentView]];
    [secondaryPdfView goToPage:page];
    [[secondaryPdfView documentView] scrollPoint:point];
    [secondaryPdfView layoutDocumentView];
}

- (IBAction)toggleSplitPDF:(id)sender {
    if ([secondaryPdfView window]) {
        
        [secondaryPdfEdgeView removeFromSuperview];
        
    } else {
        
        NSRect frame1, frame2, tmpFrame = [pdfSplitView bounds];
        
        NSDivideRect(tmpFrame, &frame1, &frame2, roundf(0.7 * NSHeight(tmpFrame)), NSMaxYEdge);
        NSDivideRect(frame2, &tmpFrame, &frame2, [pdfSplitView dividerThickness], NSMaxYEdge);
        
        [pdfEdgeView setFrame:frame1];
        
        if (secondaryPdfView == nil) {
            secondaryPdfEdgeView = [[BDSKEdgeView alloc] initWithFrame:frame2];
            [secondaryPdfEdgeView setEdges:BDSKEveryEdgeMask];
            [secondaryPdfEdgeView setColor:[NSColor lightGrayColor] forEdge:NSMaxYEdge];
            secondaryPdfView = [[SKSecondaryPDFView alloc] initWithFrame:[[secondaryPdfEdgeView contentView] bounds]];
            [secondaryPdfView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
            [secondaryPdfEdgeView addSubview:secondaryPdfView];
            [secondaryPdfView release];
            [pdfSplitView addSubview:secondaryPdfEdgeView];
            // Because of a PDFView bug, display properties can not be changed before it is placed in a window
            [secondaryPdfView setBackgroundColor:[pdfView backgroundColor]];
            [secondaryPdfView setDisplaysPageBreaks:NO];
            [secondaryPdfView setAutoScales:YES];
            [secondaryPdfView setDocument:[pdfView document]];
        } else {
            [secondaryPdfEdgeView setFrame:frame2];
            [pdfSplitView addSubview:secondaryPdfEdgeView];
        }
        
        [self performSelector:@selector(scrollSecondaryPdfView) withObject:nil afterDelay:0.0];
    }
    
    [pdfSplitView adjustSubviews];
    [[self window] recalculateKeyViewLoop];
}

- (IBAction)toggleFullScreen:(id)sender {
    if ([self isFullScreen])
        [self exitFullScreen:sender];
    else
        [self enterFullScreen:sender];
}

- (IBAction)togglePresentation:(id)sender {
    if ([self isPresentation])
        [self exitFullScreen:sender];
    else
        [self enterPresentation:sender];
}

#pragma mark Full Screen support

- (void)showLeftSideWindowOnScreen:(NSScreen *)screen {
    if (leftSideWindow == nil)
        leftSideWindow = [[SKSideWindow alloc] initWithMainController:self edge:NSMinXEdge];
    
    [leftSideWindow moveToScreen:screen];
    
    if ([[[leftSideView window] firstResponder] isDescendantOf:leftSideView])
        [[leftSideView window] makeFirstResponder:nil];
    [leftSideWindow setMainView:leftSideView];
    
    if (usesDrawers == NO) {
        [leftSideEdgeView setEdges:BDSKNoEdgeMask];
    }
    
    if ([self isPresentation]) {
        savedLeftSidePaneState = [self leftSidePaneState];
        [self setLeftSidePaneState:SKThumbnailSidePaneState];
        [leftSideWindow setLevel:[[self window] level] + 1];
        [leftSideWindow setAlphaValue:0.95];
        [leftSideWindow setEnabled:NO];
        [leftSideWindow makeFirstResponder:thumbnailTableView];
        [leftSideWindow expand];
    } else {
        [leftSideWindow makeFirstResponder:searchField];
        [leftSideWindow collapse];
        [leftSideWindow orderFront:self];
    }
}

- (void)showRightSideWindowOnScreen:(NSScreen *)screen {
    if (rightSideWindow == nil) 
        rightSideWindow = [[SKSideWindow alloc] initWithMainController:self edge:NSMaxXEdge];
    
    [rightSideWindow moveToScreen:screen];
    
    if ([[[rightSideView window] firstResponder] isDescendantOf:rightSideView])
        [[rightSideView window] makeFirstResponder:nil];
    [rightSideWindow setMainView:rightSideView];
    
    if (usesDrawers == NO) {
        [rightSideEdgeView setEdges:BDSKNoEdgeMask];
    }
    
    if ([self isPresentation]) {
        [rightSideWindow expand];
        [leftSideWindow setLevel:[[self window] level] + 1];
        [leftSideWindow setAlphaValue:0.95];
        [leftSideWindow setEnabled:NO];
    } else {
        [rightSideWindow collapse];
    }
    
    [rightSideWindow orderFront:self];
}

- (void)hideLeftSideWindow {
    if ([[leftSideView window] isEqual:leftSideWindow]) {
        [leftSideWindow orderOut:self];
        
        if ([[leftSideWindow firstResponder] isDescendantOf:leftSideView])
            [leftSideWindow makeFirstResponder:nil];
        [leftSideView setFrame:[leftSideContentView bounds]];
        [leftSideContentView addSubview:leftSideView];
        
        if (usesDrawers == NO) {
            [leftSideEdgeView setEdges:BDSKMinXEdgeMask | BDSKMaxXEdgeMask];
        }
        
        if ([self isPresentation]) {
            [self setLeftSidePaneState:savedLeftSidePaneState];
            [leftSideWindow setLevel:NSFloatingWindowLevel];
            [leftSideWindow setAlphaValue:1.0];
            [leftSideWindow setEnabled:YES];
        }
    }
}

- (void)hideRightSideWindow {
    if ([[rightSideView window] isEqual:rightSideWindow]) {
        [rightSideWindow orderOut:self];
        
        if ([[rightSideWindow firstResponder] isDescendantOf:rightSideView])
            [rightSideWindow makeFirstResponder:nil];
        [rightSideView setFrame:[rightSideContentView bounds]];
        [rightSideContentView addSubview:rightSideView];
        
        if (usesDrawers == NO) {
            [rightSideEdgeView setEdges:BDSKMinXEdgeMask | BDSKMaxXEdgeMask];
        }
        
        if ([self isPresentation]) {
            [rightSideWindow setLevel:NSFloatingWindowLevel];
            [rightSideWindow setAlphaValue:1.0];
            [rightSideWindow setEnabled:YES];
        }
    }
}

- (void)showSideWindowsOnScreen:(NSScreen *)screen {
    [self showLeftSideWindowOnScreen:screen];
    [self showRightSideWindowOnScreen:screen];
    
    [pdfView setFrame:NSInsetRect([[pdfView superview] bounds], 9.0, 0.0)];
    [[pdfView superview] setNeedsDisplay:YES];
}

- (void)hideSideWindows {
    [self hideLeftSideWindow];
    [self hideRightSideWindow];
    
    [pdfView setFrame:[[pdfView superview] bounds]];
}

- (void)goFullScreen {
    NSScreen *screen = [[self window] screen]; // @@ screen: or should we use the main screen?
    NSColor *backgroundColor = [self isPresentation] ? [NSColor blackColor] : [[NSUserDefaults standardUserDefaults] colorForKey:SKFullScreenBackgroundColorKey];
    
    if (screen == nil) // @@ screen: can this ever happen?
        screen = [NSScreen mainScreen];
        
    // Create the full-screen window if it does not already  exist.
    if (fullScreenWindow == nil) {
        fullScreenWindow = [[SKFullScreenWindow alloc] initWithScreen:screen];
    }
        
    // explicitly set window frame; screen may have moved, or may be nil (in which case [fullScreenWindow frame] is wrong, which is weird); the first time through this method, [fullScreenWindow screen] is nil
    [fullScreenWindow setFrame:[screen frame] display:NO];
    
    if ([[mainWindow firstResponder] isDescendantOf:pdfView])
        [mainWindow makeFirstResponder:nil];
    [fullScreenWindow setMainView:pdfView];
    [fullScreenWindow setBackgroundColor:backgroundColor];
    [fullScreenWindow setLevel:[self isPresentation] ? NSPopUpMenuWindowLevel : NSNormalWindowLevel];
    [pdfView setBackgroundColor:backgroundColor];
    [pdfView layoutDocumentView];
    [pdfView setNeedsDisplay:YES];
    
    NSEnumerator *wcEnum = [[[self document] windowControllers] objectEnumerator];
    NSWindowController *wc = [wcEnum nextObject];
    
    while (wc = [wcEnum nextObject]) {
        if ([wc isKindOfClass:[SKNoteWindowController class]] || [wc isKindOfClass:[SKSnapshotWindowController class]])
            [(id)wc setForceOnTop:YES];
    }
        
    if (NO == [self isPresentation] && [[NSUserDefaults standardUserDefaults] boolForKey:SKBlankAllScreensInFullScreenKey] && [[NSScreen screens] count] > 1) {
        if (nil == blankingWindows)
            blankingWindows = [[NSMutableArray alloc] init];
        [blankingWindows removeAllObjects];
        NSEnumerator *screenEnum = [[NSScreen screens] objectEnumerator];
        NSScreen *screenToBlank;
        while (screenToBlank = [screenEnum nextObject]) {
            if ([screenToBlank isEqual:screen] == NO) {
                SKFullScreenWindow *window = [[SKFullScreenWindow alloc] initWithScreen:screenToBlank];
                [window setBackgroundColor:backgroundColor];
                [window setLevel:NSFloatingWindowLevel];
                [window setFrame:[screenToBlank frame] display:YES];
                [window orderFront:nil];
                [window setReleasedWhenClosed:YES];
                [window setHidesOnDeactivate:YES];
                [blankingWindows addObject:window];
                [window release];
            }
        }
    }
    
    [mainWindow setDelegate:nil];
    [self setWindow:fullScreenWindow];
    [fullScreenWindow makeKeyAndOrderFront:self];
    [fullScreenWindow makeFirstResponder:pdfView];
    [fullScreenWindow setAcceptsMouseMovedEvents:YES];
    [fullScreenWindow recalculateKeyViewLoop];
    [mainWindow orderOut:self];    
    [fullScreenWindow setDelegate:self];
}

- (void)removeFullScreen {
    [pdfView setBackgroundColor:[[NSUserDefaults standardUserDefaults] colorForKey:SKBackgroundColorKey]];
    [pdfView layoutDocumentView];
    
    NSEnumerator *wcEnum = [[[self document] windowControllers] objectEnumerator];
    NSWindowController *wc = [wcEnum nextObject];
    
    while (wc = [wcEnum nextObject]) {
        if ([wc isKindOfClass:[SKNoteWindowController class]] || [wc isKindOfClass:[SKSnapshotWindowController class]])
            [(id)wc setForceOnTop:NO];
    }
    
    [fullScreenWindow setDelegate:nil];
    [self setWindow:mainWindow];
    [mainWindow orderWindow:NSWindowBelow relativeTo:[fullScreenWindow windowNumber]];
    [mainWindow makeKeyWindow];
    [mainWindow display];
    
    NSDictionary *fadeOutDict = [[NSDictionary alloc] initWithObjectsAndKeys:fullScreenWindow, NSViewAnimationTargetKey, NSViewAnimationFadeOutEffect, NSViewAnimationEffectKey, nil];
    NSViewAnimation *animation = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObjects:fadeOutDict, nil]];
    [fadeOutDict release];
    
    [animation setAnimationBlockingMode:NSAnimationBlocking];
    [animation setDuration:0.5];
    [animation startAnimation];
    [animation release];
    [fullScreenWindow orderOut:self];
    [fullScreenWindow setAlphaValue:1.0];
    [mainWindow makeKeyAndOrderFront:self];
    [mainWindow makeFirstResponder:pdfView];
    [mainWindow recalculateKeyViewLoop];
    [mainWindow setDelegate:self];
    
    NSEnumerator *blankScreenEnumerator = [blankingWindows objectEnumerator];
    NSWindow *window;
    while (window = [blankScreenEnumerator nextObject]) {
        NSDictionary *fadeOutDict = [[NSDictionary alloc] initWithObjectsAndKeys:window, NSViewAnimationTargetKey, NSViewAnimationFadeOutEffect, NSViewAnimationEffectKey, nil];
        NSViewAnimation *animation = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObject:fadeOutDict]];
        [fadeOutDict release];
        [animation setAnimationBlockingMode:NSAnimationNonblockingThreaded];
        [animation setDelegate:self];
        [animation setDuration:0.5];
        [animation startAnimation];
        [animation release];        
    }
}

- (void)saveNormalSetup {
    if ([self isPresentation] == NO && [self isFullScreen] == NO) {
        NSScrollView *scrollView = [[pdfView documentView] enclosingScrollView];
        [savedNormalSetup setDictionary:[self currentPDFSettings]];
        [savedNormalSetup setObject:[NSNumber numberWithBool:[scrollView hasHorizontalScroller]] forKey:HAS_HORIZONTAL_SCROLLER_KEY];
        [savedNormalSetup setObject:[NSNumber numberWithBool:[scrollView hasVerticalScroller]] forKey:HAS_VERTICAL_SCROLLER_KEY];
        [savedNormalSetup setObject:[NSNumber numberWithBool:[scrollView autohidesScrollers]] forKey:AUTO_HIDES_SCROLLERS_KEY];
    }
    
    NSDictionary *fullScreenSetup = [[NSUserDefaults standardUserDefaults] objectForKey:SKDefaultFullScreenPDFDisplaySettingsKey];
    if ([fullScreenSetup count])
        [self applyPDFSettings:fullScreenSetup];
}

- (void)activityTimerFired:(NSTimer *)timer {
    UpdateSystemActivity(UsrActivity);
}

- (void)enterPresentationMode {
    NSScrollView *scrollView = [[pdfView documentView] enclosingScrollView];
    [self saveNormalSetup];
    // Set up presentation mode
    [pdfView setAutoScales:YES];
    [pdfView setDisplayMode:kPDFDisplaySinglePage];
    [pdfView setDisplayBox:kPDFDisplayBoxCropBox];
    [pdfView setDisplaysPageBreaks:YES];
    [scrollView setNeverHasHorizontalScroller:YES];
    [scrollView setNeverHasVerticalScroller:YES];
    [scrollView setAutohidesScrollers:YES];
    
    [pdfView setCurrentSelection:nil];
    if ([pdfView hasReadingBar])
        [pdfView toggleReadingBar];
    
    NSColor *backgroundColor = [NSColor blackColor];
    [pdfView setBackgroundColor:backgroundColor];
    [fullScreenWindow setBackgroundColor:backgroundColor];
    [fullScreenWindow setLevel:NSPopUpMenuWindowLevel];
    
    // periodically send a 'user activity' to prevent sleep mode and screensaver from being activated
    activityTimer = [[NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(activityTimerFired:) userInfo:NULL repeats:YES] retain];
    
    isPresentation = YES;
}

- (void)exitPresentationMode {
    [activityTimer invalidate];
    [activityTimer release];
    activityTimer = nil;
    
    NSScrollView *scrollView = [[pdfView documentView] enclosingScrollView];
    [self applyPDFSettings:savedNormalSetup];
    [scrollView setNeverHasHorizontalScroller:NO];
    [scrollView setHasHorizontalScroller:[[savedNormalSetup objectForKey:HAS_HORIZONTAL_SCROLLER_KEY] boolValue]];
    [scrollView setNeverHasVerticalScroller:NO];
    [scrollView setHasVerticalScroller:[[savedNormalSetup objectForKey:HAS_VERTICAL_SCROLLER_KEY] boolValue]];
    [scrollView setAutohidesScrollers:[[savedNormalSetup objectForKey:AUTO_HIDES_SCROLLERS_KEY] boolValue]];
    
    NSColor *backgroundColor = [[NSUserDefaults standardUserDefaults] colorForKey:SKFullScreenBackgroundColorKey];
    [pdfView setBackgroundColor:backgroundColor];
    [fullScreenWindow setBackgroundColor:backgroundColor];
    [fullScreenWindow setLevel:NSNormalWindowLevel];
    
    [self hideLeftSideWindow];
    
    isPresentation = NO;
}

- (IBAction)enterFullScreen:(id)sender {
    if ([self isFullScreen])
        return;
    
    NSScreen *screen = [[self window] screen]; // @@ screen: or should we use the main screen?
    if (screen == nil) // @@ screen: can this ever happen?
        screen = [NSScreen mainScreen];
    if ([screen isEqual:[[NSScreen screens] objectAtIndex:0]])
        SetSystemUIMode(kUIModeAllHidden, kUIOptionAutoShowMenuBar);
    
    [self saveNormalSetup];
    
    if ([self isPresentation])
        [self exitPresentationMode];
    else
        [self goFullScreen];
    
    NSDictionary *fullScreenSetup = [[NSUserDefaults standardUserDefaults] dictionaryForKey:SKDefaultFullScreenPDFDisplaySettingsKey];
    if ([fullScreenSetup count])
        [self applyPDFSettings:fullScreenSetup];
    
    [pdfView enableNavigationActivatedAtBottom:[[NSUserDefaults standardUserDefaults] boolForKey:SKActivateFullScreenNavigationAtBottomKey] autohidesCursor:NO screen:screen];
    [self showSideWindowsOnScreen:screen];
}

- (IBAction)enterPresentation:(id)sender {
    if ([self isPresentation])
        return;
    
    BOOL wasFullScreen = [self isFullScreen];
    
    [self enterPresentationMode];
    
    NSScreen *screen = [[self window] screen]; // @@ screen: or should we use the main screen?
    if (screen == nil) // @@ screen: can this ever happen?
        screen = [NSScreen mainScreen];
    if ([screen isEqual:[[NSScreen screens] objectAtIndex:0]])
        SetSystemUIMode(kUIModeAllHidden, 0);
    
    if (wasFullScreen)
        [self hideSideWindows];
    else
        [self goFullScreen];
    
    [pdfView enableNavigationActivatedAtBottom:[[NSUserDefaults standardUserDefaults] boolForKey:SKActivatePresentationNavigationAtBottomKey] autohidesCursor:YES screen:screen];
}

- (IBAction)exitFullScreen:(id)sender {
    if ([self isFullScreen] == NO && [self isPresentation] == NO)
        return;

    if ([self isFullScreen])
        [self hideSideWindows];
    
    if ([[fullScreenWindow firstResponder] isDescendantOf:pdfView])
        [fullScreenWindow makeFirstResponder:nil];
    [pdfView disableNavigation];
    [pdfView setFrame:[[pdfEdgeView contentView] bounds]];
    [pdfEdgeView addSubview:pdfView]; // this should be done before exitPresentationMode to get a smooth transition
    
    if ([self isPresentation])
        [self exitPresentationMode];
    else
        [self applyPDFSettings:savedNormalSetup];
   
    SetSystemUIMode(kUIModeNormal, 0);
    
    [self removeFullScreen];
}

#pragma mark Swapping tables

- (void)replaceSideView:(NSView *)oldView withView:(NSView *)newView animate:(BOOL)animate {
    if ([newView window] == nil) {
        BOOL wasFirstResponder = [[[oldView window] firstResponder] isDescendantOf:oldView];
        
        if ([oldView isEqual:tocView] || [oldView isEqual:findView])
            [[SKPDFHoverWindow sharedHoverWindow] orderOut:self];
        
        [newView setFrame:[oldView frame]];
        [newView setHidden:animate];
        [[oldView superview] addSubview:newView];
        
        if (animate) {
            isAnimating = YES;
            NSViewAnimation *animation;
            NSDictionary *fadeOutDict = [[NSDictionary alloc] initWithObjectsAndKeys:oldView, NSViewAnimationTargetKey, NSViewAnimationFadeOutEffect, NSViewAnimationEffectKey, nil];
            NSDictionary *fadeInDict = [[NSDictionary alloc] initWithObjectsAndKeys:newView, NSViewAnimationTargetKey, NSViewAnimationFadeInEffect, NSViewAnimationEffectKey, nil];
            
            animation = [[[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObjects:fadeOutDict, fadeInDict, nil]] autorelease];
            [fadeOutDict release];
            [fadeInDict release];
            
            [animation setAnimationBlockingMode:NSAnimationBlocking];
            [animation setDuration:0.75];
            [animation setAnimationCurve:NSAnimationEaseIn];
            [animation startAnimation];
            isAnimating = NO;
        }
        
        if (wasFirstResponder)
            [[newView window] makeFirstResponder:[newView nextKeyView]];
        [oldView removeFromSuperview];
        [oldView setHidden:NO];
        [[newView window] recalculateKeyViewLoop];
    }
}

- (void)displayOutlineView {
    [self  replaceSideView:currentLeftSideView withView:tocView animate:NO];
    currentLeftSideView = tocView;
    [self updateOutlineSelection];
}

- (void)fadeInOutlineView {
    [self  replaceSideView:currentLeftSideView withView:tocView animate:YES];
    currentLeftSideView = tocView;
    [self updateOutlineSelection];
}

- (void)displayThumbnailView {
    [self  replaceSideView:currentLeftSideView withView:thumbnailView animate:NO];
    currentLeftSideView = thumbnailView;
    [self updateThumbnailSelection];
}

- (void)fadeInThumbnailView {
    [self  replaceSideView:currentLeftSideView withView:thumbnailView animate:YES];
    currentLeftSideView = thumbnailView;
    [self updateThumbnailSelection];
}

- (void)displaySearchView {
    [self  replaceSideView:currentLeftSideView withView:findView animate:NO];
    currentLeftSideView = findView;
}

- (void)fadeInSearchView {
    [self  replaceSideView:currentLeftSideView withView:findView animate:YES];
    currentLeftSideView = findView;
}

- (void)displayNoteView {
    [self  replaceSideView:currentRightSideView withView:noteView animate:NO];
    currentRightSideView = noteView;
}

- (void)displaySnapshotView {
    [self  replaceSideView:currentRightSideView withView:snapshotView animate:NO];
    currentRightSideView = snapshotView;
    [self updateSnapshotsIfNeeded];
}

#pragma mark Searching

- (void)documentDidBeginDocumentFind:(NSNotification *)note {
    if (findPanelFind == NO) {
        [findArrayController removeObjects:searchResults];
        [[[findTableView tableColumnWithIdentifier:@"results"] headerCell] setStringValue:[NSLocalizedString(@"Searching", @"Message in search table header") stringByAppendingEllipsis]];
        [[findTableView headerView] setNeedsDisplay:YES];
        [statusBar setProgressIndicatorStyle:SKProgressIndicatorBarStyle];
        [[statusBar progressIndicator] setMaxValue:[[note object] pageCount]];
        [[statusBar progressIndicator] setDoubleValue:0.0];
        [statusBar startAnimation:self];
    }
}

- (void)documentDidEndDocumentFind:(NSNotification *)note {
    if (findPanelFind == NO) {
        [self willChangeValueForKey:@"searchResults"];
        [self didChangeValueForKey:@"searchResults"];
        [[[findTableView tableColumnWithIdentifier:@"results"] headerCell] setStringValue:[NSString stringWithFormat:NSLocalizedString(@"%i Results", @"Message in search table header"), [searchResults count]]];
        [[findTableView headerView] setNeedsDisplay:YES];
        [statusBar stopAnimation:self];
        [statusBar setProgressIndicatorStyle:SKProgressIndicatorNone];
    }
}

- (void)documentDidEndPageFind:(NSNotification *)note {
    [[statusBar progressIndicator] setDoubleValue:[[[note userInfo] objectForKey:@"PDFDocumentPageIndex"] doubleValue]];
}

- (void)didMatchString:(PDFSelection *)instance {
    if (findPanelFind == NO) {
        [searchResults addObject:instance];
        if ([searchResults count] % 50 == 0) {
            [self willChangeValueForKey:@"searchResults"];
            [self didChangeValueForKey:@"searchResults"];
        }
    }
}

- (void)temporaryAnnotationTimerFired:(NSTimer *)timer {
    [self removeTemporaryAnnotations];
}

- (void)addAnnotationsForSelection:(PDFSelection *)sel {
    NSArray *pages = [sel pages];
    int i, iMax = [pages count];
    NSColor *color = [[NSUserDefaults standardUserDefaults] colorForKey:SKSearchHighlightColorKey];
    
    if (color == nil)
        color = [NSColor redColor];
    
    for (i = 0; i < iMax; i++) {
        PDFPage *page = [pages objectAtIndex:i];
        NSRect bounds = NSInsetRect([sel boundsForPage:page], -4.0, -4.0);
        SKPDFAnnotationTemporary *circle = [[SKPDFAnnotationTemporary alloc] initWithBounds:bounds];
        
        // use a heavier line width at low magnification levels; would be nice if PDFAnnotation did this for us
        PDFBorder *border = [[PDFBorder alloc] init];
        [border setLineWidth:1.5 / ([pdfView scaleFactor])];
        [border setStyle:kPDFBorderStyleSolid];
        [circle setBorder:border];
        [border release];
        [circle setColor:color];
        [page addAnnotation:circle];
        [pdfView setNeedsDisplayForAnnotation:circle];
        [circle release];
        CFSetAddValue(temporaryAnnotations, (void *)circle);
    }
}

- (void)addTemporaryAnnotationForPoint:(NSPoint)point onPage:(PDFPage *)page {
    NSRect bounds = NSMakeRect(point.x - 2.0, point.y - 2.0, 4.0, 4.0);
    SKPDFAnnotationTemporary *circle = [[SKPDFAnnotationTemporary alloc] initWithBounds:bounds];
    NSColor *color = [[NSUserDefaults standardUserDefaults] colorForKey:SKSearchHighlightColorKey];
    
    [self removeTemporaryAnnotations];
    [circle setColor:color];
    [circle setInteriorColor:color];
    [page addAnnotation:circle];
    [pdfView setNeedsDisplayForAnnotation:circle];
    [circle release];
    CFSetAddValue(temporaryAnnotations, (void *)circle);
    temporaryAnnotationTimer = [[NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(temporaryAnnotationTimerFired:) userInfo:NULL repeats:NO] retain];
}

static void removeTemporaryAnnotations(const void *annotation, void *context)
{
    SKMainWindowController *wc = (SKMainWindowController *)context;
    PDFAnnotation *annote = (PDFAnnotation *)annotation;
    [[wc pdfView] setNeedsDisplayForAnnotation:annote];
    [[annote page] removeAnnotation:annote];
    // no need to update thumbnail, since temp annotations are only displayed when the search table is displayed
}

- (void)removeTemporaryAnnotations {
    [temporaryAnnotationTimer invalidate];
    [temporaryAnnotationTimer release];
    temporaryAnnotationTimer = nil;
    // for long documents, this is much faster than iterating all pages and sending -isTemporaryAnnotation to each one
    CFSetApplyFunction(temporaryAnnotations, removeTemporaryAnnotations, self);
    CFSetRemoveAllValues(temporaryAnnotations);
}

- (void)displaySearchResultsForString:(NSString *)string {
    if ([self leftSidePaneIsOpen] == NO)
        [self toggleLeftSidePane:self];
    [searchField setStringValue:string];
    [self search:searchField];
}

- (IBAction)search:(id)sender {

    // cancel any previous find to remove those results, or else they stay around
    if ([[pdfView document] isFinding])
        [[pdfView document] cancelFindString];

    if ([[sender stringValue] isEqualToString:@""]) {
        
        // get rid of temporary annotations
        [self removeTemporaryAnnotations];
        if (leftSidePaneState == SKThumbnailSidePaneState)
            [self fadeInThumbnailView];
        else 
            [self fadeInOutlineView];
    } else {
        [[pdfView document] beginFindString:[sender stringValue] withOptions:NSCaseInsensitiveSearch];
        [self fadeInSearchView];
        
        NSPasteboard *findPboard = [NSPasteboard pasteboardWithName:NSFindPboard];
        [findPboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
        [findPboard setString:[sender stringValue] forType:NSStringPboardType];
    }
}

- (PDFSelection *)findString:(NSString *)string fromSelection:(PDFSelection *)selection withOptions:(int)options {
	findPanelFind = YES;
    selection = [[pdfView document] findString:string fromSelection:selection withOptions:options];
	findPanelFind = NO;
    return selection;
}

- (void)findString:(NSString *)string options:(int)options{
    PDFSelection *sel = [pdfView currentSelection];
    unsigned pageIndex = [[pdfView currentPage] pageIndex];
    while ([sel string] == nil && pageIndex-- > 0) {
        PDFPage *page = [[pdfView document] pageAtIndex:pageIndex];
        sel = [page selectionForRect:[page boundsForBox:kPDFDisplayBoxCropBox]];
    }
    PDFSelection *selection = [self findString:string fromSelection:sel withOptions:options];
    if (selection == nil && [sel string])
        selection = [self findString:string fromSelection:nil withOptions:options];
    if (selection) {
		[pdfView setCurrentSelection:selection];
		[pdfView scrollSelectionToVisible:self];
        [findTableView deselectAll:self];
        if ([[NSUserDefaults standardUserDefaults] boolForKey:SKShouldHighlightSearchResultsKey]) {
            [self removeTemporaryAnnotations];
            [self addAnnotationsForSelection:selection];
            temporaryAnnotationTimer = [[NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(temporaryAnnotationTimerFired:) userInfo:NULL repeats:NO] retain];
        }
	} else {
		NSBeep();
	}
}

- (void)goToFindResults:(NSArray *)findResults {
    BOOL highlight = [[NSUserDefaults standardUserDefaults] boolForKey:SKShouldHighlightSearchResultsKey];
    
    // union all selected objects
    NSEnumerator *selE = [findResults objectEnumerator];
    PDFSelection *sel;
    
    // arm:  PDFSelection is mutable, and using -addSelection on an object from selectedObjects will actually mutate the object in searchResults, which does bad things.  MagicHat indicates that PDFSelection implements copyWithZone: even though it doesn't conform to <NSCopying>, so we'll use that since -init doesn't work (-initWithDocument: does, but it's not listed in the header either).  I filed rdar://problem/4888251 and also noticed that PDFKitViewer sample code uses -[PDFSelection copy].
    PDFSelection *currentSel = [[[selE nextObject] copy] autorelease];
    
    [pdfView setCurrentSelection:currentSel];
    [pdfView scrollSelectionToVisible:self];
    
    [self removeTemporaryAnnotations];
    
    // add an annotation so it's easier to see the search result
    if (highlight)
        [self addAnnotationsForSelection:currentSel];
    
    while (sel = [selE nextObject]) {
        [currentSel addSelection:sel];
        if (highlight)
            [self addAnnotationsForSelection:sel];
    }
}

- (IBAction)searchNotes:(id)sender {
    if ([[sender stringValue] length] && rightSidePaneState != SKNoteSidePaneState)
        [self setRightSidePaneState:SKNoteSidePaneState];
    [self updateNoteFilterPredicate];
    if ([[sender stringValue] length]) {
        NSPasteboard *findPboard = [NSPasteboard pasteboardWithName:NSFindPboard];
        [findPboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
        [findPboard setString:[sender stringValue] forType:NSStringPboardType];
    }
}

#pragma mark Sub- and note- windows

- (void)showSnapshotAtPageNumber:(int)pageNum forRect:(NSRect)rect scaleFactor:(int)scaleFactor autoFits:(BOOL)autoFits {
    SKSnapshotWindowController *swc = [[SKSnapshotWindowController alloc] init];
    BOOL snapshotsOnTop = [[NSUserDefaults standardUserDefaults] boolForKey:SKSnapshotsOnTopKey];
    
    [swc setDelegate:self];
    
    [swc setPdfDocument:[pdfView document]
            scaleFactor:scaleFactor
         goToPageNumber:pageNum
                   rect:rect
               autoFits:autoFits];
    
    [swc setForceOnTop:[self isFullScreen] || [self isPresentation]];
    [[swc window] setHidesOnDeactivate:snapshotsOnTop];
    
    [[self document] addWindowController:swc];
    [swc release];
    
    [swc showWindow:self];
}

- (void)showSnapshotWithSetups:(NSArray *)setups {
    BOOL snapshotsOnTop = [[NSUserDefaults standardUserDefaults] boolForKey:SKSnapshotsOnTopKey];
    NSEnumerator *setupEnum = [setups objectEnumerator];
    NSDictionary *setup;
    
    while (setup = [setupEnum nextObject]) {
        SKSnapshotWindowController *swc = [[SKSnapshotWindowController alloc] init];
        
        [swc setDelegate:self];
        
        [swc setPdfDocument:[pdfView document] setup:setup];
        
        [swc setForceOnTop:[self isFullScreen] || [self isPresentation]];
        [[swc window] setHidesOnDeactivate:snapshotsOnTop];
        
        [[self document] addWindowController:swc];
        [swc release];
    }
}

- (void)toggleSnapshots:(NSArray *)snapshotArray {
    // there should only be a single snapshot
    SKSnapshotWindowController *controller = [snapshotArray lastObject];
    
    if ([[controller window] isVisible])
        [controller miniaturize];
    else
        [controller deminiaturize];
}

- (void)snapshotControllerDidFinishSetup:(SKSnapshotWindowController *)controller {
    NSImage *image = [controller thumbnailWithSize:snapshotCacheSize];
    
    [controller setThumbnail:image];
    [[self mutableArrayValueForKey:@"snapshots"] addObject:controller];
}

- (void)snapshotControllerWindowWillClose:(SKSnapshotWindowController *)controller {
    [[self mutableArrayValueForKey:@"snapshots"] removeObject:controller];
}

- (void)snapshotControllerViewDidChange:(SKSnapshotWindowController *)controller {
    [self snapshotNeedsUpdate:controller];
}

- (void)hideRightSideWindow:(NSTimer *)timer {
    [rightSideWindow collapse];
}

- (NSRect)snapshotControllerTargetRectForMiniaturize:(SKSnapshotWindowController *)controller {
    if ([self isPresentation] == NO) {
        if ([self isFullScreen] == NO && [self rightSidePaneIsOpen] == NO) {
            [self toggleRightSidePane:self];
        } else if ([self isFullScreen] && ([rightSideWindow state] == NSDrawerClosedState || [rightSideWindow state] == NSDrawerClosingState)) {
            [rightSideWindow expand];
            [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(hideRightSideWindow:) userInfo:NULL repeats:NO];
        }
        [self setRightSidePaneState:SKSnapshotSidePaneState];
    }
    
    int row = [[snapshotArrayController arrangedObjects] indexOfObject:controller];
    
    [snapshotTableView scrollRowToVisible:row];
    
    NSRect rect = [snapshotTableView frameOfCellAtColumn:0 row:row];
    
    rect = [snapshotTableView convertRect:rect toView:nil];
    rect.origin = [[snapshotTableView window] convertBaseToScreen:rect.origin];
    
    return rect;
}

- (NSRect)snapshotControllerSourceRectForDeminiaturize:(SKSnapshotWindowController *)controller {
    [[self document] addWindowController:controller];
    
    int row = [[snapshotArrayController arrangedObjects] indexOfObject:controller];
    NSRect rect = [snapshotTableView frameOfCellAtColumn:0 row:row];
        
    rect = [snapshotTableView convertRect:rect toView:nil];
    rect.origin = [[snapshotTableView window] convertBaseToScreen:rect.origin];
    
    return rect;
}

- (void)showNote:(PDFAnnotation *)annotation {
    NSWindowController *wc = nil;
    NSEnumerator *wcEnum = [[[self document] windowControllers] objectEnumerator];
    
    while (wc = [wcEnum nextObject]) {
        if ([wc isKindOfClass:[SKNoteWindowController class]] && [(SKNoteWindowController *)wc note] == annotation)
            break;
    }
    if (wc == nil) {
        wc = [[SKNoteWindowController alloc] initWithNote:annotation];
        [(SKNoteWindowController *)wc setForceOnTop:[self isFullScreen] || [self isPresentation]];
        [[self document] addWindowController:wc];
        [wc release];
    }
    [wc showWindow:self];
}

- (void)showHoverWindowForDestination:(PDFDestination *)dest {
        PDFAnnotationLink *link = [[[PDFAnnotationLink alloc] initWithBounds:NSZeroRect] autorelease];
        NSPoint point = [dest point];
        switch ([[dest page] rotation]) {
            case 0:
                point.x -= 50.0;
                point.y += 20.0;
                break;
            case 90:
                point.x -= 20.0;
                point.y -= 50.0;
                break;
            case 180:
                point.x += 50.0;
                point.y -= 20.0;
                break;
            case 270:
                point.x += 20.0;
                point.y += 50.0;
                break;
        }
        [link setDestination:[[[PDFDestination alloc] initWithPage:[dest page] atPoint:point] autorelease]];
        [[SKPDFHoverWindow sharedHoverWindow] showForAnnotation:link atPoint:NSZeroPoint];
}

#pragma mark Bookmarks

- (void)bookmarkSheetDidEnd:(SKBookmarkSheetController *)controller returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSAlertDefaultReturn) {
        SKBookmarkController *bmController = [SKBookmarkController sharedBookmarkController];
        NSString *path = [[self document] fileName];
        NSString *label = [controller stringValue];
        unsigned int pageIndex = [[pdfView currentPage] pageIndex];
        [bmController addBookmarkForPath:path pageIndex:pageIndex label:label toFolder:[controller selectedFolder]];
    }
}

- (IBAction)addBookmark:(id)sender {
    if (bookmarkSheetController == nil)
        bookmarkSheetController = [[SKBookmarkSheetController alloc] init];
    
	[bookmarkSheetController setStringValue:[[self document] displayName]];
    
    [bookmarkSheetController beginSheetModalForWindow: [self window]
        modalDelegate:self 
       didEndSelector:@selector(bookmarkSheetDidEnd:returnCode:contextInfo:)
          contextInfo:NULL];
}

#pragma mark Notification handlers

- (void)handleChangedHistoryNotification:(NSNotification *)notification {
    [backForwardButton setEnabled:[pdfView canGoBack] forSegment:0];
    [backForwardButton setEnabled:[pdfView canGoForward] forSegment:1];
}

- (void)handlePageChangedNotification:(NSNotification *)notification {
    [lastViewedPages insertObject:[NSNumber numberWithInt:[[pdfView currentPage] pageIndex]] atIndex:0];
    if ([lastViewedPages count] > 5)
        [lastViewedPages removeLastObject];
    [thumbnailTableView setNeedsDisplay:YES];
    [outlineView setNeedsDisplay:YES];
    
    [self willChangeValueForKey:@"pageNumber"];
    [self willChangeValueForKey:@"pageLabel"];
    [self didChangeValueForKey:@"pageLabel"];
    [self didChangeValueForKey:@"pageNumber"];
    
    [previousPageButton setEnabled:[pdfView canGoToFirstPage] forSegment:0];
    [previousPageButton setEnabled:[pdfView canGoToPreviousPage] forSegment:1];
    [nextPageButton setEnabled:[pdfView canGoToNextPage] forSegment:0];
    [nextPageButton setEnabled:[pdfView canGoToLastPage] forSegment:1];
    
    [self updateOutlineSelection];
    [self updateNoteSelection];
    [self updateThumbnailSelection];
    
    [self updateLeftStatus];
}

- (void)handleScaleChangedNotification:(NSNotification *)notification {
    [scaleField setFloatValue:[pdfView scaleFactor] * 100.0];
}

- (void)handleToolModeChangedNotification:(NSNotification *)notification {
    [toolModeButton selectSegmentWithTag:[pdfView toolMode]];
}

- (void)handleAnnotationModeChangedNotification:(NSNotification *)notification {
    [toolModeButton setImage:[NSImage imageNamed:noteToolAdornImageNames[[pdfView annotationMode]]] forSegment:SKNoteToolMode];
}

- (void)handleSelectionChangedNotification:(NSNotification *)notification {
    [self updateRightStatus];
}

- (void)handleMagnificationChangedNotification:(NSNotification *)notification {
    [self updateRightStatus];
}

- (void)handleApplicationWillTerminateNotification:(NSNotification *)notification {
    if ([self isFullScreen] || [self isPresentation])
        [self exitFullScreen:self];
}

- (void)handleApplicationDidResignActiveNotification:(NSNotification *)notification {
    if ([self isPresentation]) {
        [fullScreenWindow setLevel:NSNormalWindowLevel];
    }
}

- (void)handleApplicationWillBecomeActiveNotification:(NSNotification *)notification {
    if ([self isPresentation]) {
        [fullScreenWindow setLevel:NSPopUpMenuWindowLevel];
    }
}

- (void)handleDocumentWillSaveNotification:(NSNotification *)notification {
    [pdfView endAnnotationEdit:self];
}

- (void)handleDidChangeActiveAnnotationNotification:(NSNotification *)notification {
    PDFAnnotation *annotation = [pdfView activeAnnotation];
    
    if ([[self window] isMainWindow]) {
        [self updateFontPanel];
        [self updateColorPanel];
        [self updateLineInspector];
    }
    if ([annotation isNoteAnnotation]) {
        if ([self selectedNote] != annotation) {
            [noteOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:[noteOutlineView rowForItem:annotation]] byExtendingSelection:NO];
        }
    } else {
        [noteOutlineView deselectAll:self];
    }
    [noteOutlineView reloadData];
}

- (void)handleDidAddAnnotationNotification:(NSNotification *)notification {
    PDFAnnotation *annotation = [[notification userInfo] objectForKey:@"annotation"];
    PDFPage *page = [[notification userInfo] objectForKey:@"page"];
    
    if (annotation) {
        updatingNoteSelection = YES;
        [[self mutableArrayValueForKey:@"notes"] addObject:annotation];
        [noteArrayController rearrangeObjects]; // doesn't seem to be done automatically
        updatingNoteSelection = NO;
    }
    if (page) {
        [self updateThumbnailAtPageIndex:[page pageIndex]];
        NSEnumerator *snapshotEnum = [snapshots objectEnumerator];
        SKSnapshotWindowController *wc;
        while (wc = [snapshotEnum nextObject]) {
            if ([wc isPageVisible:page])
                [self snapshotNeedsUpdate:wc];
        }
        [secondaryPdfView setNeedsDisplayForAnnotation:annotation onPage:page];
    }
    [noteOutlineView reloadData];
}

- (void)handleDidRemoveAnnotationNotification:(NSNotification *)notification {
    PDFAnnotation *annotation = [[notification userInfo] objectForKey:@"annotation"];
    PDFPage *page = [[notification userInfo] objectForKey:@"page"];
    
    if ([self selectedNote] == annotation)
        [noteOutlineView deselectAll:self];
    
    if (annotation) {
        NSWindowController *wc = nil;
        NSEnumerator *wcEnum = [[[self document] windowControllers] objectEnumerator];
        
        while (wc = [wcEnum nextObject]) {
            if ([wc isKindOfClass:[SKNoteWindowController class]] && [(SKNoteWindowController *)wc note] == annotation) {
                [wc close];
                break;
            }
        }
        [[self mutableArrayValueForKey:@"notes"] removeObject:annotation];
        [noteArrayController rearrangeObjects];
    }
    if (page) {
        [self updateThumbnailAtPageIndex:[page pageIndex]];
        NSEnumerator *snapshotEnum = [snapshots objectEnumerator];
        SKSnapshotWindowController *wc;
        while (wc = [snapshotEnum nextObject]) {
            if ([wc isPageVisible:page])
                [self snapshotNeedsUpdate:wc];
        }
        [secondaryPdfView setNeedsDisplayForAnnotation:annotation onPage:page];
    }
    [noteOutlineView reloadData];
}

- (void)handleDidMoveAnnotationNotification:(NSNotification *)notification {
    PDFPage *oldPage = [[notification userInfo] objectForKey:@"oldPage"];
    PDFPage *newPage = [[notification userInfo] objectForKey:@"newPage"];
    
    if (oldPage || newPage) {
        if (oldPage)
            [self updateThumbnailAtPageIndex:[oldPage pageIndex]];
        if (newPage)
            [self updateThumbnailAtPageIndex:[newPage pageIndex]];
        NSEnumerator *snapshotEnum = [snapshots objectEnumerator];
        SKSnapshotWindowController *wc;
        while (wc = [snapshotEnum nextObject]) {
            if ([wc isPageVisible:oldPage] || [wc isPageVisible:newPage])
                [self snapshotNeedsUpdate:wc];
        }
        [secondaryPdfView setNeedsDisplay:YES];
    }
    
    [noteArrayController rearrangeObjects];
    [noteOutlineView reloadData];
}

- (void)handleDoubleClickedAnnotationNotification:(NSNotification *)notification {
    PDFAnnotation *annotation = [[notification userInfo] objectForKey:@"annotation"];
    
    [self showNote:annotation];
}

- (void)handleReadingBarDidChangeNotification:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    PDFPage *oldPage = [userInfo objectForKey:@"oldPage"];
    PDFPage *newPage = [userInfo objectForKey:@"newPage"];
    if (oldPage)
        [self updateThumbnailAtPageIndex:[oldPage pageIndex]];
    if (newPage && [newPage isEqual:oldPage] == NO)
        [self updateThumbnailAtPageIndex:[newPage pageIndex]];
}

- (void)handleAnnotationDidChangeNotification:(NSNotification *)notification {
    PDFAnnotation *annotation = [notification object];
    if ([[[annotation page] document] isEqual:[[self pdfView] document]]) {
        [self updateThumbnailAtPageIndex:[annotation pageIndex]];

        NSEnumerator *snapshotEnum = [snapshots objectEnumerator];
        SKSnapshotWindowController *wc;
        while (wc = [snapshotEnum nextObject]) {
            if ([wc isPageVisible:[annotation page]])
                [self snapshotNeedsUpdate:wc];
        }
        
        [secondaryPdfView setNeedsDisplayForAnnotation:annotation onPage:[annotation page]];
        
        [noteArrayController rearrangeObjects];
        [noteOutlineView reloadData];
    }
    if ([[self window] isMainWindow] && [annotation isEqual:[pdfView activeAnnotation]]) {
        NSString *key = [[notification userInfo] objectForKey:@"key"];
        if (updatingColor == NO && ([key isEqualToString:@"color"] || [key isEqualToString:@"interiorColor"])) {
            updatingColor = YES;
            [[NSColorPanel sharedColorPanel] setColor:[annotation color]];
            updatingColor = NO;
        }
        if (updatingFont == NO && ([key isEqualToString:@"font"] || [key isEqualToString:@"fontName"] || [key isEqualToString:@"fontSize"])) {
            updatingFont = YES;
            [[NSFontManager sharedFontManager] setSelectedFont:[(PDFAnnotationFreeText *)annotation font] isMultiple:NO];
            updatingFont = NO;
        }
        if (updatingLine == NO && ([key isEqualToString:@"border"] || [key isEqualToString:@"lineWidth"] || [key isEqualToString:@"borderStyle"] || [key isEqualToString:@"dashPattern"] || [key isEqualToString:@"startLineStyle"] || [key isEqualToString:@"endLineStyle"])) {
            updatingLine = YES;
            [[SKLineInspector sharedLineInspector] setAnnotationStyle:annotation];
            updatingLine = NO;
        }
    }
}

- (void)handlePageBoundsDidChangeNotification:(NSNotification *)notification {
    NSDictionary *info = [notification userInfo];
    PDFPage *page = [info objectForKey:@"page"];
    BOOL displayChanged = [[info objectForKey:@"action"] isEqualToString:@"rotate"] || [pdfView displayBox] == kPDFDisplayBoxCropBox;
    
    if (displayChanged)
        [pdfView layoutDocumentView];
    if (page) {
        unsigned int index = [page pageIndex];
        NSEnumerator *snapshotEnum = [snapshots objectEnumerator];
        SKSnapshotWindowController *wc;
        while (wc = [snapshotEnum nextObject]) {
            if ([wc isPageVisible:page]) {
                [self snapshotNeedsUpdate:wc];
                [wc redisplay];
            }
        }
        if (displayChanged)
            [self updateThumbnailAtPageIndex:index];
    } else {
        [snapshots makeObjectsPerformSelector:@selector(redisplay)];
        [self allSnapshotsNeedUpdate];
        if (displayChanged)
            [self allThumbnailsNeedUpdate];
    }
    
    [secondaryPdfView setNeedsDisplay:YES];
}

- (void)handleDocumentBeginWrite:(NSNotification *)notification {
	// Establish maximum and current value for progress bar.
	[[self progressController] setMaxValue:(double)[[pdfView document] pageCount]];
	[[self progressController] setDoubleValue:0.0];
	[[self progressController] setMessage:[NSLocalizedString(@"Exporting PDF", @"Message for progress sheet") stringByAppendingEllipsis]];
	
	// Bring up the save panel as a sheet.
	[[self progressController] beginSheetModalForWindow:[self window]];
}

- (void)handleDocumentEndWrite:(NSNotification *)notification {
	[[self progressController] endSheet];
}

- (void)handleDocumentEndPageWrite:(NSNotification *)notification {
	[[self progressController] setDoubleValue: [[[notification userInfo] objectForKey:@"PDFDocumentPageIndex"] floatValue]];
}

- (void)documentDidUnlock:(NSNotification *)notification {
    [self updatePageLabelsAndOutline];
}

- (void)handleColorSwatchColorsChangedNotification:(NSNotification *)notification {
    NSMenu *menu = [[[toolbarItems objectForKey:SKDocumentToolbarColorSwatchItemIdentifier] menuFormRepresentation] submenu];
    
    int i = [menu numberOfItems];
    while (i--)
        [menu removeItemAtIndex:i];
    
    NSEnumerator *colorEnum = [[colorSwatch colors] objectEnumerator];
    NSColor *color;
    NSRect rect = NSMakeRect(0.0, 0.0, 16.0, 16.0);
    NSRect lineRect = NSInsetRect(rect, 0.5, 0.5);
    NSRect swatchRect = NSInsetRect(rect, 1.0, 1.0);
    
    while (color = [colorEnum nextObject]) {
        NSImage *image = [[NSImage alloc] initWithSize:rect.size];
        NSMenuItem *item = [menu addItemWithTitle:@"" action:@selector(selectColor:) keyEquivalent:@""];
        
        [image lockFocus];
        [[NSColor lightGrayColor] setStroke];
        [NSBezierPath strokeRect:lineRect];
        [color drawSwatchInRect:swatchRect];
        [image unlockFocus];
        [item setTarget:self];
        [item setRepresentedObject:color];
        [item setImage:image];
        [image release];
    }
    
    if (colorSwatchToolbarItem)
        [[colorSwatchToolbarItem menuFormRepresentation] setSubmenu:[NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:menu]]];
}

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == [NSUserDefaultsController sharedUserDefaultsController]) {
        if (NO == [keyPath hasPrefix:@"values."])
            return;
        NSString *key = [keyPath substringFromIndex:7];
        if ([key isEqualToString:SKBackgroundColorKey]) {
            if ([self isFullScreen] == NO && [self isPresentation] == NO)
                [pdfView setBackgroundColor:[[NSUserDefaults standardUserDefaults] colorForKey:SKBackgroundColorKey]];
            [secondaryPdfView setBackgroundColor:[[NSUserDefaults standardUserDefaults] colorForKey:SKBackgroundColorKey]];
        } else if ([key isEqualToString:SKFullScreenBackgroundColorKey]) {
            if ([self isFullScreen]) {
                NSColor *color = [[NSUserDefaults standardUserDefaults] colorForKey:SKFullScreenBackgroundColorKey];
                if (color) {
                    [pdfView setBackgroundColor:color];
                    [fullScreenWindow setBackgroundColor:color];
                    [[fullScreenWindow contentView] setNeedsDisplay:YES];
                    
                    if ([blankingWindows count]) {
                        NSWindow *window;
                        NSEnumerator *windowEnum = [blankingWindows objectEnumerator];
                        while (window = [windowEnum nextObject]) {
                            [window setBackgroundColor:color];
                            [[window contentView] setNeedsDisplay:YES];
                        }
                    }
                }
            }
        } else if ([key isEqualToString:SKSearchHighlightColorKey]) {
            if ([[NSUserDefaults standardUserDefaults] boolForKey:SKShouldHighlightSearchResultsKey] && 
                [[searchField stringValue] length] && [findTableView numberOfSelectedRows]) {
                // clear the selection
                [self removeTemporaryAnnotations];
                
                NSEnumerator *selE = [[findArrayController selectedObjects] objectEnumerator];
                PDFSelection *sel;
                
                while (sel = [selE nextObject])
                    [self addAnnotationsForSelection:sel];
            }
        } else if ([key isEqualToString:SKShouldHighlightSearchResultsKey]) {
            if ([[searchField stringValue] length] && [findTableView numberOfSelectedRows]) {
                // clear the selection
                [self removeTemporaryAnnotations];
                
                if ([[NSUserDefaults standardUserDefaults] boolForKey:SKShouldHighlightSearchResultsKey]) {
                    NSEnumerator *selE = [[findArrayController selectedObjects] objectEnumerator];
                    PDFSelection *sel;
                    
                    while (sel = [selE nextObject])
                        [self addAnnotationsForSelection:sel];
                }
            }
        } else if ([key isEqualToString:SKThumbnailSizeKey]) {
            [self resetThumbnailSizeIfNeeded];
            [thumbnailTableView noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self countOfThumbnails])]];
        } else if ([key isEqualToString:SKSnapshotThumbnailSizeKey]) {
            [self resetSnapshotSizeIfNeeded];
            [snapshotTableView noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self countOfSnapshots])]];
        } else if ([key isEqualToString:SKShouldAntiAliasKey]) {
            [pdfView setShouldAntiAlias:[[NSUserDefaults standardUserDefaults] boolForKey:SKShouldAntiAliasKey]];
        } else if ([key isEqualToString:SKGreekingThresholdKey]) {
            [pdfView setGreekingThreshold:[[NSUserDefaults standardUserDefaults] floatForKey:SKGreekingThresholdKey]];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark NSOutlineView methods

- (int)outlineView:(NSOutlineView *)ov numberOfChildrenOfItem:(id)item{
    if ([ov isEqual:outlineView]) {
        if (item == nil){
            if ((pdfOutline) && ([[pdfView document] isLocked] == NO)){
                return [pdfOutline numberOfChildren];
            }else{
                return 0;
            }
        }else{
            return [(PDFOutline *)item numberOfChildren];
        }
    } else if ([ov isEqual:noteOutlineView]) {
        if (item == nil) {
            return [[noteArrayController arrangedObjects] count];
        } else {
            return [[item texts] count];
        }
    }
    return 0;
}

- (id)outlineView:(NSOutlineView *)ov child:(int)index ofItem:(id)item{
    if ([ov isEqual:outlineView]) {
        if (item == nil){
            if ((pdfOutline) && ([[pdfView document] isLocked] == NO)){
                // Apple's sample code retains this object before returning it, which prevents a crash, but also causes a leak.  We could rewrite PDFOutline, but it's easier just to collect these objects and release them in -dealloc.
                id obj = [pdfOutline childAtIndex:index];
                if (obj)
                    [pdfOutlineItems addObject:obj];
                return obj;
                
            }else{
                return nil;
            }
        }else{
            id obj = [(PDFOutline *)item childAtIndex:index];
            if (obj)
                [pdfOutlineItems addObject:obj];
            return obj;
        }
    } else if ([ov isEqual:noteOutlineView]) {
        if (item == nil) {
            return [[noteArrayController arrangedObjects] objectAtIndex:index];
        } else {
            return [[item texts] lastObject];
        }
    }
    return nil;
}


- (BOOL)outlineView:(NSOutlineView *)ov isItemExpandable:(id)item{
    if ([ov isEqual:outlineView]) {
        if (item == nil){
            if ((pdfOutline) && ([[pdfView document] isLocked] == NO)){
                return ([pdfOutline numberOfChildren] > 0);
            }else{
                return NO;
            }
        }else{
            return ([(PDFOutline *)item numberOfChildren] > 0);
        }
    } else if ([ov isEqual:noteOutlineView]) {
        return [[item texts] count] > 0;
    }
    return NO;
}


- (id)outlineView:(NSOutlineView *)ov objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item{
    if ([ov isEqual:outlineView]) {
        NSString *tcID = [tableColumn identifier];
        if([tcID isEqualToString:@"label"]){
            return [(PDFOutline *)item label];
        }else if([tcID isEqualToString:@"page"]){
            return [[[(PDFOutline *)item destination] page] label];
        }else{
            [NSException raise:@"Unexpected tablecolumn identifier" format:@" - %@ ", tcID];
            return nil;
        }
    } else if ([ov isEqual:noteOutlineView]) {
        NSString *tcID = [tableColumn  identifier];
        if ([tcID isEqualToString:@"note"]) {
            return [item contents];
        } else if([tcID isEqualToString:@"type"]) {
            return [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:item == [pdfView activeAnnotation]], @"active", [item type], @"type", nil];
        } else if([tcID isEqualToString:@"page"]) {
            return [[item page] label];
        }
    }
    return nil;
}

- (void)outlineView:(NSOutlineView *)ov setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item{
    if ([ov isEqual:noteOutlineView]) {
        if ([[tableColumn identifier] isEqualToString:@"note"]) {
            if ([object isEqualToString:[item contents]] == NO)
                [item setContents:object];
        }
    }
}

- (BOOL)outlineView:(NSOutlineView *)ov shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item{
    if ([ov isEqual:noteOutlineView]) {
        if ([[tableColumn identifier] isEqualToString:@"note"]) {
            if ([item type] == nil) {
                if ([pdfView hideNotes] == NO) {
                    PDFAnnotation *annotation = [(SKNoteText *)item annotation];
                    [pdfView scrollAnnotationToVisible:annotation];
                    [pdfView setActiveAnnotation:annotation];
                    [self showNote:annotation];
                }
                return NO;
            } else {
                return YES;
            }
        }
    }
    return NO;
}

- (void)outlineView:(NSOutlineView *)ov didClickTableColumn:(NSTableColumn *)tableColumn {
    if ([ov isEqual:noteOutlineView]) {
        NSTableColumn *oldTableColumn = [ov highlightedTableColumn];
        NSArray *sortDescriptors = nil;
        BOOL ascending = YES;
        if ([oldTableColumn isEqual:tableColumn]) {
            sortDescriptors = [[noteArrayController sortDescriptors] valueForKey:@"reversedSortDescriptor"];
            ascending = [[sortDescriptors lastObject] ascending];
        } else {
            NSString *tcID = [tableColumn identifier];
            NSSortDescriptor *pageIndexSortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"pageIndex" ascending:ascending] autorelease];
            NSSortDescriptor *boundsSortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"bounds" ascending:ascending selector:@selector(boundsCompare:)] autorelease];
            NSMutableArray *sds = [NSMutableArray arrayWithObjects:pageIndexSortDescriptor, boundsSortDescriptor, nil];
            if ([tcID isEqualToString:@"type"]) {
                [sds insertObject:[[[NSSortDescriptor alloc] initWithKey:@"noteType" ascending:YES selector:@selector(caseInsensitiveCompare:)] autorelease] atIndex:0];
            } else if ([tcID isEqualToString:@"note"]) {
                [sds insertObject:[[[NSSortDescriptor alloc] initWithKey:@"contents" ascending:YES selector:@selector(localizedCaseInsensitiveNumericCompare:)] autorelease] atIndex:0];
            } else if ([tcID isEqualToString:@"page"]) {
                if (oldTableColumn == nil)
                    ascending = NO;
            }
            sortDescriptors = sds;
            if (oldTableColumn)
                [ov setIndicatorImage:nil inTableColumn:oldTableColumn];
            [ov setHighlightedTableColumn:tableColumn]; 
        }
        [noteArrayController setSortDescriptors:sortDescriptors];
        [ov setIndicatorImage:[NSImage imageNamed:ascending ? @"NSAscendingSortIndicator" : @"NSDescendingSortIndicator"]
                inTableColumn:tableColumn];
        [ov reloadData];
    }
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification{
	// Get the destination associated with the search result list. Tell the PDFView to go there.
	if ([[notification object] isEqual:outlineView] && (updatingOutlineSelection == NO)){
        updatingOutlineSelection = YES;
		[pdfView goToDestination: [[outlineView itemAtRow: [outlineView selectedRow]] destination]];
        updatingOutlineSelection = NO;
        if ([self isPresentation] && [[NSUserDefaults standardUserDefaults] boolForKey:SKAutoHidePresentationContentsKey])
            [self hideLeftSideWindow];
    }
}

- (NSString *)outlineView:(NSOutlineView *)ov toolTipForCell:(NSCell *)cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)tableColumn item:(id)item mouseLocation:(NSPoint)mouseLocation {
    if ([ov isEqual:noteOutlineView] && [[tableColumn identifier] isEqualToString:@"note"]) {
        return [item type] ? [(PDFAnnotation *)item contents] : [[(SKNoteText *)item contents] string];
    }
    return nil;
}

- (void)outlineViewItemDidExpand:(NSNotification *)notification{
    if ([[notification object] isEqual:outlineView]) {
        [self updateOutlineSelection];
    }
}


- (void)outlineViewItemDidCollapse:(NSNotification *)notification{
    if ([[notification object] isEqual:outlineView]) {
        [self updateOutlineSelection];
    }
}

- (void)outlineViewNoteTypesDidChange:(NSOutlineView *)ov {
    if ([ov isEqual:noteOutlineView]) {
        [self updateNoteFilterPredicate];
    }
}

- (float)outlineView:(NSOutlineView *)ov heightOfRowByItem:(id)item {
    if ([ov isEqual:outlineView]) {
        return 17.0;
    } else if ([ov isEqual:noteOutlineView]) {
        // the item is an opaque wrapper object used for binding. The actual note is is given by -observedeObject. I don't know of any alternative (read public) way to get the actual item
        if ([item respondsToSelector:@selector(rowHeight)] == NO)
            return 17.0;
        else
            return [item rowHeight];
    }
    return 17.0;
}

- (BOOL)outlineView:(NSOutlineView *)ov canResizeRowByItem:(id)item {
    if ([ov isEqual:noteOutlineView]) {
        if ([item respondsToSelector:@selector(setRowHeight:)] == NO)
            return NO;
        else
            return YES;
    }
    return NO;
}

- (void)outlineView:(NSOutlineView *)ov setHeightOfRow:(int)newHeight byItem:(id)item {
    [item setRowHeight:newHeight];
}

- (NSArray *)noteItems:(NSArray *)items {
    NSEnumerator *itemEnum = [items objectEnumerator];
    PDFAnnotation *item;
    NSMutableArray *noteItems = [NSMutableArray array];
    
    while (item = [itemEnum nextObject]) {
        if ([item type] == nil) {
            item = [(SKNoteText *)item annotation];
        }
        if ([noteItems containsObject:item] == NO)
            [noteItems addObject:item];
    }
    return noteItems;
}

- (void)outlineView:(NSOutlineView *)ov deleteItems:(NSArray *)items  {
    if ([ov isEqual:noteOutlineView] && [items count]) {
        NSEnumerator *itemEnum = [[self noteItems:items] objectEnumerator];
        PDFAnnotation *item;
        while (item = [itemEnum nextObject])
            [pdfView removeAnnotation:item];
        [[[self document] undoManager] setActionName:NSLocalizedString(@"Remove Note", @"Undo action name")];
    }
}

- (BOOL)outlineView:(NSOutlineView *)ov canDeleteItems:(NSArray *)items  {
    if ([ov isEqual:noteOutlineView]) {
        return [items count] > 0;
    }
    return NO;
}

- (void)outlineView:(NSOutlineView *)ov copyItems:(NSArray *)items  {
    if ([ov isEqual:noteOutlineView] && [items count]) {
        NSEnumerator *itemEnum = [[self noteItems:items] objectEnumerator];
        PDFAnnotation *item = nil;
        id firstItem = [items objectAtIndex:0];
        while (item = [itemEnum nextObject])
            if ([item isMovable]) break;
        NSPasteboard *pboard = [NSPasteboard generalPasteboard];
        NSMutableArray *types = [NSMutableArray array];
        NSData *noteData = item ? [NSKeyedArchiver archivedDataWithRootObject:[item dictionaryValue]] : nil;
        NSAttributedString *attrString = [firstItem type] ? nil : [(SKNoteText *)firstItem contents];
        NSString *string = [firstItem type] ? [firstItem contents] : [attrString string];
        if (noteData)
            [types addObject:SKSkimNotePboardType];
        if (string)
            [types addObject:NSStringPboardType];
        if (attrString)
            [types addObject:NSRTFPboardType];
        if ([types count])
            [pboard declareTypes:types owner:nil];
        if (noteData)
            [pboard setData:noteData forType:SKSkimNotePboardType];
        if (string)
            [pboard setString:string forType:NSStringPboardType];
        if (attrString)
            [pboard setData:[attrString RTFFromRange:NSMakeRange(0, [string length]) documentAttributes:nil] forType:NSRTFPboardType];
    }
}

- (BOOL)outlineView:(NSOutlineView *)ov canCopyItems:(NSArray *)items  {
    if ([ov isEqual:noteOutlineView]) {
        return [items count] > 0;
    }
    return NO;
}

- (NSArray *)outlineViewHighlightedRows:(NSOutlineView *)ov {
    if ([ov isEqual:outlineView]) {
        NSMutableArray *array = [NSMutableArray array];
        NSEnumerator *rowEnum = [lastViewedPages objectEnumerator];
        NSNumber *rowNumber;
        
        while (rowNumber = [rowEnum nextObject]) {
            int row = [self outlineRowForPageIndex:[rowNumber intValue]];
            if (row != -1)
                [array addObject:[NSNumber numberWithInt:row]];
        }
        
        return array;
    }
    return nil;
}

- (BOOL)outlineView:(NSOutlineView *)ov shouldTrackTableColumn:(NSTableColumn *)aTableColumn item:(id)item {
    return YES;
}

- (void)outlineView:(NSOutlineView *)ov mouseEnteredTableColumn:(NSTableColumn *)aTableColumn item:(id)item {
    if ([ov isEqual:outlineView]) {
        [self showHoverWindowForDestination:[item destination]];
    }
}

- (void)outlineView:(NSOutlineView *)ov mouseExitedTableColumn:(NSTableColumn *)aTableColumn item:(id)item {
    if ([ov isEqual:outlineView]) {
        [[SKPDFHoverWindow sharedHoverWindow] hide];
    }
}

- (void)deleteNote:(id)sender {
    PDFAnnotation *annotation = [sender representedObject];
    [self outlineView:noteOutlineView deleteItems:[NSArray arrayWithObjects:annotation, nil]];
}

- (void)copyNote:(id)sender {
    PDFAnnotation *annotation = [sender representedObject];
    [self outlineView:noteOutlineView copyItems:[NSArray arrayWithObjects:annotation, nil]];
}

- (void)selectNote:(id)sender {
    PDFAnnotation *annotation = [sender representedObject];
    [pdfView setActiveAnnotation:annotation];
}

- (void)deselectNote:(id)sender {
    [pdfView setActiveAnnotation:nil];
}

- (void)autoSizeNoteRows:(id)sender {
    NSTableColumn *tableColumn = [noteOutlineView tableColumnWithIdentifier:@"note"];
    id cell = [tableColumn dataCell];
    float width = NSWidth([cell drawingRectForBounds:NSMakeRect(0.0, 0.0, [tableColumn width] - 17.0, 17.0)]);
    NSSize size = NSMakeSize(width, FLT_MAX);
    
    NSMutableArray *items = [NSMutableArray array];
    id item = [sender representedObject];
    
    if (item) {
        [items addObject:item];
    } else {
        [items addObjectsFromArray:[self notes]];
        [items addObjectsFromArray:[[self notes] valueForKeyPath:@"@unionOfArrays.texts"]];
    }
    
    int i, count = [items count];
    NSMutableIndexSet *rowIndexes = [NSMutableIndexSet indexSet];
    int row;
    
    for (i = 0; i < count; i++) {
        item = [items objectAtIndex:i];
        [cell setObjectValue:[item contents]];
        NSAttributedString *attrString = [cell attributedStringValue];
        NSRect rect = [attrString boundingRectWithSize:size options:NSStringDrawingUsesLineFragmentOrigin];
        [item setRowHeight:fmaxf(NSHeight(rect) + 3.0, 19.0)];
        row = [noteOutlineView rowForItem:item];
        if (row != -1)
            [rowIndexes addIndex:row];
    }
    // don't use noteHeightOfRowsWithIndexesChanged: as this only updates the visible rows and the scrollers
    [noteOutlineView reloadData];
}

- (NSMenu *)outlineView:(NSOutlineView *)ov menuForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    NSMenu *menu = nil;
    NSMenuItem *menuItem;
    
    if ([ov isEqual:noteOutlineView]) {
        [noteOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:[noteOutlineView rowForItem:item]] byExtendingSelection:NO];
        
        PDFAnnotation *annotation = [item type] ? item : [(SKNoteText *)item annotation];
        menu = [[[NSMenu allocWithZone:[NSMenu menuZone]] init] autorelease];
        if ([self outlineView:ov canDeleteItems:[NSArray arrayWithObjects:item, nil]]) {
            menuItem = [menu addItemWithTitle:NSLocalizedString(@"Delete", @"Menu item title") action:@selector(deleteNote:) keyEquivalent:@""];
            [menuItem setTarget:self];
            [menuItem setRepresentedObject:item];
        }
        if ([self outlineView:ov canCopyItems:[NSArray arrayWithObjects:item, nil]]) {
            menuItem = [menu addItemWithTitle:NSLocalizedString(@"Copy", @"Menu item title") action:@selector(copyNote:) keyEquivalent:@""];
            [menuItem setTarget:self];
            [menuItem setRepresentedObject:item];
        }
        if ([pdfView hideNotes] == NO) {
            if ([annotation isEditable]) {
                menuItem = [menu addItemWithTitle:NSLocalizedString(@"Edit", @"Menu item title") action:@selector(editThisAnnotation:) keyEquivalent:@""];
                [menuItem setTarget:pdfView];
                [menuItem setRepresentedObject:annotation];
            }
            if ([pdfView activeAnnotation] == annotation)
                menuItem = [menu addItemWithTitle:NSLocalizedString(@"Deselect", @"Menu item title") action:@selector(deselectNote:) keyEquivalent:@""];
            else
                menuItem = [menu addItemWithTitle:NSLocalizedString(@"Select", @"Menu item title") action:@selector(selectNote:) keyEquivalent:@""];
            [menuItem setTarget:self];
            [menuItem setRepresentedObject:annotation];
        }
        if ([menu numberOfItems] > 0)
            [menu addItem:[NSMenuItem separatorItem]];
        menuItem = [menu addItemWithTitle:NSLocalizedString(@"Auto Size Row", @"Menu item title") action:@selector(autoSizeNoteRows:) keyEquivalent:@""];
        [menuItem setTarget:self];
        [menuItem setRepresentedObject:item];
        menuItem = [menu addItemWithTitle:NSLocalizedString(@"Auto Size All", @"Menu item title") action:@selector(autoSizeNoteRows:) keyEquivalent:@""];
        [menuItem setTarget:self];
    }
    return menu;
}

#pragma mark NSTableView delegate protocol

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
    if ([[aNotification object] isEqual:findTableView]) {
        [self goToFindResults:[findArrayController selectedObjects]];
        
        if ([self isPresentation] && [[NSUserDefaults standardUserDefaults] boolForKey:SKAutoHidePresentationContentsKey])
            [self hideLeftSideWindow];
    } else if ([[aNotification object] isEqual:thumbnailTableView]) {
        if (updatingThumbnailSelection == NO) {
            int row = [thumbnailTableView selectedRow];
            if (row != -1)
                [pdfView goToPage:[[pdfView document] pageAtIndex:row]];
            
            if ([self isPresentation] && [[NSUserDefaults standardUserDefaults] boolForKey:SKAutoHidePresentationContentsKey])
                [self hideLeftSideWindow];
        }
    } else if ([[aNotification object] isEqual:snapshotTableView]) {
        int row = [snapshotTableView selectedRow];
        if (row != -1) {
            SKSnapshotWindowController *controller = [[snapshotArrayController arrangedObjects] objectAtIndex:row];
            if ([[controller window] isVisible])
                [[controller window] orderFront:self];
        }
    }
}

// AppKit bug: need a dummy NSTableDataSource implementation, otherwise some NSTableView delegate methods are ignored
- (int)numberOfRowsInTableView:(NSTableView *)tv { return 0; }

- (id)tableView:(NSTableView *)tv objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row { return nil; }

- (BOOL)tableView:(NSTableView *)tv commandSelectRow:(int)row {
    if ([tv isEqual:thumbnailTableView]) {
        NSRect rect = [[[pdfView document] pageAtIndex:row] boundsForBox:kPDFDisplayBoxCropBox];
        
        rect.origin.y = NSMidY(rect) - 100.0;
        rect.size.height = 200.0;
        [self showSnapshotAtPageNumber:row forRect:rect scaleFactor:[pdfView scaleFactor] autoFits:NO];
        return YES;
    }
    return NO;
}

- (float)tableView:(NSTableView *)tv heightOfRow:(int)row {
    if ([tv isEqual:thumbnailTableView]) {
        NSSize thumbSize = [[[thumbnails objectAtIndex:row] image] size];
        NSSize cellSize = NSMakeSize([[tv tableColumnWithIdentifier:@"image"] width], 
                                     fminf(thumbSize.height, roundedThumbnailSize));
        if (thumbSize.height < 1.0)
            return 1.0;
        else if (thumbSize.width / thumbSize.height < cellSize.width / cellSize.height)
            return cellSize.height;
        else
            return fmaxf(1.0, fminf(cellSize.width, thumbSize.width) * thumbSize.height / thumbSize.width);
    } else if ([tv isEqual:snapshotTableView]) {
        NSSize thumbSize = [[[[snapshotArrayController arrangedObjects] objectAtIndex:row] thumbnail] size];
        NSSize cellSize = NSMakeSize([[tv tableColumnWithIdentifier:@"image"] width], 
                                     fminf(thumbSize.height, roundedSnapshotThumbnailSize));
        if (thumbSize.height < 1.0)
            return 1.0;
        else if (thumbSize.width / thumbSize.height < cellSize.width / cellSize.height)
            return cellSize.height;
        else
            return fmaxf(32.0, fminf(cellSize.width, thumbSize.width) * thumbSize.height / thumbSize.width);
    }
    return 17.0;
}

- (void)tableView:(NSTableView *)tv deleteRowsWithIndexes:(NSIndexSet *)rowIndexes {
    if ([tv isEqual:snapshotTableView]) {
        NSArray *controllers = [[snapshotArrayController arrangedObjects] objectsAtIndexes:rowIndexes];
        [[controllers valueForKey:@"window"] makeObjectsPerformSelector:@selector(orderOut:) withObject:self];
        [[self mutableArrayValueForKey:@"snapshots"] removeObjectsInArray:controllers];
    }
}

- (BOOL)tableView:(NSTableView *)tv canDeleteRowsWithIndexes:(NSIndexSet *)rowIndexes {
    if ([tv isEqual:snapshotTableView]) {
        return [rowIndexes count] > 0;
    }
    return NO;
}

- (void)tableView:(NSTableView *)tv copyRowsWithIndexes:(NSIndexSet *)rowIndexes {
    if ([tv isEqual:thumbnailTableView]) {
        unsigned int index = [rowIndexes firstIndex];
        if (index != NSNotFound) {
            PDFPage *page = [[pdfView document] pageAtIndex:index];
            NSData *pdfData = [page dataRepresentation];
            NSData *tiffData = [[page imageForBox:[pdfView displayBox]] TIFFRepresentation];
            NSPasteboard *pboard = [NSPasteboard generalPasteboard];
            [pboard declareTypes:[NSArray arrayWithObjects:NSPDFPboardType, NSTIFFPboardType, nil] owner:nil];
            [pboard setData:pdfData forType:NSPDFPboardType];
            [pboard setData:tiffData forType:NSTIFFPboardType];
        }
    }
}

- (BOOL)tableView:(NSTableView *)tv canCopyRowsWithIndexes:(NSIndexSet *)rowIndexes {
    if ([tv isEqual:thumbnailTableView]) {
        return [rowIndexes count] > 0;
    }
    return NO;
}

- (NSArray *)tableViewHighlightedRows:(NSTableView *)tv {
    if ([tv isEqual:thumbnailTableView]) {
        return lastViewedPages;
    }
    return nil;
}

- (BOOL)tableView:(NSTableView *)tv shouldTrackTableColumn:(NSTableColumn *)aTableColumn row:(int)row {
    if ([tv isEqual:findTableView]) {
        return YES;
    }
    return NO;
}

- (void)tableView:(NSTableView *)tv mouseEnteredTableColumn:(NSTableColumn *)aTableColumn row:(int)row {
    if ([tv isEqual:findTableView]) {
        PDFDestination *dest = [[[findArrayController arrangedObjects] objectAtIndex:row] destination];
        [self showHoverWindowForDestination:dest];
    }
}

- (void)tableView:(NSTableView *)tv mouseExitedTableColumn:(NSTableColumn *)aTableColumn row:(int)row {
    if ([tv isEqual:findTableView]) {
        [[SKPDFHoverWindow sharedHoverWindow] hide];
    }
}

- (void)copyPage:(id)sender {
    PDFPage *page = [sender representedObject];
    NSData *pdfData = [page dataRepresentation];
    NSData *tiffData = [[page imageForBox:[pdfView displayBox]] TIFFRepresentation];
    NSPasteboard *pboard = [NSPasteboard generalPasteboard];
    [pboard declareTypes:[NSArray arrayWithObjects:NSPDFPboardType, NSTIFFPboardType, nil] owner:nil];
    [pboard setData:pdfData forType:NSPDFPboardType];
    [pboard setData:tiffData forType:NSTIFFPboardType];
}

- (void)deleteSnapshot:(id)sender {
    SKSnapshotWindowController *controller = [sender representedObject];
    [[controller window] orderOut:self];
    [[self mutableArrayValueForKey:@"snapshots"] removeObject:controller];
}

- (void)showSnapshot:(id)sender {
    SKSnapshotWindowController *controller = [sender representedObject];
    if ([[controller window] isVisible])
        [[controller window] orderFront:self];
    else
        [controller deminiaturize];
}

- (void)hideSnapshot:(id)sender {
    SKSnapshotWindowController *controller = [sender representedObject];
    if ([[controller window] isVisible])
        [controller miniaturize];
}

- (NSMenu *)tableView:(NSTableView *)tv menuForTableColumn:(NSTableColumn *)tableColumn row:(int)row {
    NSMenu *menu = nil;
    if ([tv isEqual:thumbnailTableView]) {
        menu = [[[NSMenu allocWithZone:[NSMenu menuZone]] init] autorelease];
        NSMenuItem *menuItem = [menu addItemWithTitle:NSLocalizedString(@"Copy", @"Menu item title") action:@selector(copyPage:) keyEquivalent:@""];
        [menuItem setTarget:self];
        [menuItem setRepresentedObject:[[pdfView document] pageAtIndex:row]];
    } else if ([tv isEqual:snapshotTableView]) {
        [snapshotTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
        
        menu = [[[NSMenu allocWithZone:[NSMenu menuZone]] init] autorelease];
        SKSnapshotWindowController *controller = [[snapshotArrayController arrangedObjects] objectAtIndex:row];
        NSMenuItem *menuItem = [menu addItemWithTitle:NSLocalizedString(@"Delete", @"Menu item title") action:@selector(deleteSnapshot:) keyEquivalent:@""];
        [menuItem setTarget:self];
        [menuItem setRepresentedObject:controller];
        menuItem = [menu addItemWithTitle:NSLocalizedString(@"Show", @"Menu item title") action:@selector(showSnapshot:) keyEquivalent:@""];
        [menuItem setTarget:self];
        [menuItem setRepresentedObject:controller];
        if ([[controller window] isVisible]) {
            menuItem = [menu addItemWithTitle:NSLocalizedString(@"Hide", @"Menu item title") action:@selector(hideSnapshot:) keyEquivalent:@""];
            [menuItem setTarget:self];
            [menuItem setRepresentedObject:controller];
        }
    }
    return menu;
}

#pragma mark SKTypeSelectHelper datasource protocol

- (NSArray *)typeSelectHelperSelectionItems:(SKTypeSelectHelper *)typeSelectHelper {
    if ([typeSelectHelper isEqual:[thumbnailTableView typeSelectHelper]] || [typeSelectHelper isEqual:[pdfView typeSelectHelper]]) {
        return pageLabels;
    } else if ([typeSelectHelper isEqual:[noteOutlineView typeSelectHelper]]) {
        int i, count = [noteOutlineView numberOfRows];
        NSMutableArray *texts = [NSMutableArray arrayWithCapacity:count];
        for (i = 0; i < count; i++) {
            id item = [noteOutlineView itemAtRow:i];
            NSString *contents = [item type] ? [(PDFAnnotation *)item contents] : [[(SKNoteText *)item contents] string];
            [texts addObject:contents ? contents : @""];
        }
        return texts;
    } else if ([typeSelectHelper isEqual:[outlineView typeSelectHelper]]) {
        int i, count = [outlineView numberOfRows];
        NSMutableArray *array = [NSMutableArray arrayWithCapacity:count];
        for (i = 0; i < count; i++) 
            [array addObject:[[(PDFOutline *)[outlineView itemAtRow:i] label] lossyASCIIString]];
        return array;
    }
    return nil;
}

- (unsigned int)typeSelectHelperCurrentlySelectedIndex:(SKTypeSelectHelper *)typeSelectHelper {
    if ([typeSelectHelper isEqual:[thumbnailTableView typeSelectHelper]] || [typeSelectHelper isEqual:[pdfView typeSelectHelper]]) {
        return [[thumbnailTableView selectedRowIndexes] lastIndex];
    } else if ([typeSelectHelper isEqual:[noteOutlineView typeSelectHelper]]) {
        int row = [noteOutlineView selectedRow];
        return row == -1 ? NSNotFound : row;
    } else if ([typeSelectHelper isEqual:[outlineView typeSelectHelper]]) {
        int row = [outlineView selectedRow];
        return row == -1 ? NSNotFound : row;
    }
    return NSNotFound;
}

- (void)typeSelectHelper:(SKTypeSelectHelper *)typeSelectHelper selectItemAtIndex:(unsigned int)itemIndex {
    if ([typeSelectHelper isEqual:[thumbnailTableView typeSelectHelper]] || [typeSelectHelper isEqual:[pdfView typeSelectHelper]]) {
        [self setPageNumber:itemIndex + 1];
    } else if ([typeSelectHelper isEqual:[noteOutlineView typeSelectHelper]]) {
        [noteOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:itemIndex] byExtendingSelection:NO];
        [noteOutlineView scrollRowToVisible:itemIndex];
    } else if ([typeSelectHelper isEqual:[outlineView typeSelectHelper]]) {
        [outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:itemIndex] byExtendingSelection:NO];
        [noteOutlineView scrollRowToVisible:itemIndex];
    }
}

- (void)typeSelectHelper:(SKTypeSelectHelper *)typeSelectHelper didFailToFindMatchForSearchString:(NSString *)searchString {
    if ([typeSelectHelper isEqual:[thumbnailTableView typeSelectHelper]] || [typeSelectHelper isEqual:[pdfView typeSelectHelper]]) {
        [statusBar setLeftStringValue:[NSString stringWithFormat:NSLocalizedString(@"No match: \"%@\"", @"Status message"), searchString]];
    } else if ([typeSelectHelper isEqual:[noteOutlineView typeSelectHelper]]) {
        [statusBar setRightStringValue:[NSString stringWithFormat:NSLocalizedString(@"No match: \"%@\"", @"Status message"), searchString]];
    } else if ([typeSelectHelper isEqual:[outlineView typeSelectHelper]]) {
        [statusBar setLeftStringValue:[NSString stringWithFormat:NSLocalizedString(@"No match: \"%@\"", @"Status message"), searchString]];
    }
}

- (void)typeSelectHelper:(SKTypeSelectHelper *)typeSelectHelper updateSearchString:(NSString *)searchString {
    if ([typeSelectHelper isEqual:[thumbnailTableView typeSelectHelper]] || [typeSelectHelper isEqual:[pdfView typeSelectHelper]]) {
        if (searchString)
            [statusBar setLeftStringValue:[NSString stringWithFormat:NSLocalizedString(@"Go to page: %@", @"Status message"), searchString]];
        else
            [self updateLeftStatus];
    } else if ([typeSelectHelper isEqual:[noteOutlineView typeSelectHelper]]) {
        if (searchString)
            [statusBar setRightStringValue:[NSString stringWithFormat:NSLocalizedString(@"Finding note: \"%@\"", @"Status message"), searchString]];
        else
            [self updateRightStatus];
    } else if ([typeSelectHelper isEqual:[outlineView typeSelectHelper]]) {
        if (searchString)
            [statusBar setLeftStringValue:[NSString stringWithFormat:NSLocalizedString(@"Finding: \"%@\"", @"Status message"), searchString]];
        else
            [self updateLeftStatus];
    }
}

#pragma mark Outline

- (int)outlineRowForPageIndex:(unsigned int)pageIndex {
    if (pdfOutline == nil)
        return -1;
    
	int i, numRows = [outlineView numberOfRows];
	for (i = 0; i < numRows; i++) {
		// Get the destination of the given row....
		PDFOutline *outlineItem = (PDFOutline *)[outlineView itemAtRow: i];
		
		if ([[[outlineItem destination] page ] pageIndex] == pageIndex) {
            break;
        } else if ([[[outlineItem destination] page] pageIndex] > pageIndex) {
			if (i > 0) --i;
            break;	
		}
	}
    if (i == numRows)
        i--;
    return i;
}

- (void)updateOutlineSelection{

	// Skip out if this PDF has no outline.
	if (pdfOutline == nil || updatingOutlineSelection)
		return;
	
	// Get index of current page.
	unsigned int pageIndex = [[pdfView currentPage] pageIndex];
    
	// Test that the current selection is still valid.
	int row = [outlineView selectedRow];
    if (row == -1 || [[[[outlineView itemAtRow:row] destination] page] pageIndex] != pageIndex) {
        row = [self outlineRowForPageIndex:pageIndex];
        if (row != -1) {
            updatingOutlineSelection = YES;
            [outlineView selectRow:row byExtendingSelection: NO];
            updatingOutlineSelection = NO;
        }
    }
}

#pragma mark Thumbnails

- (void)updateThumbnailSelection {
	// Get index of current page.
	unsigned pageIndex = [[pdfView currentPage] pageIndex];
    updatingThumbnailSelection = YES;
    [thumbnailTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:pageIndex] byExtendingSelection:NO];
    [thumbnailTableView scrollRowToVisible:pageIndex];
    updatingThumbnailSelection = NO;
}

- (void)resetThumbnails {
    unsigned i, count = [pageLabels count];
    [self willChangeValueForKey:@"thumbnails"];
    [thumbnails removeAllObjects];
    if (count) {
        PDFPage *emptyPage = [[[PDFPage alloc] init] autorelease];
        [emptyPage setBounds:[[[pdfView document] pageAtIndex:0] boundsForBox:kPDFDisplayBoxCropBox] forBox:kPDFDisplayBoxCropBox];
        [emptyPage setBounds:[[[pdfView document] pageAtIndex:0] boundsForBox:kPDFDisplayBoxMediaBox] forBox:kPDFDisplayBoxMediaBox];
        NSImage *image = [emptyPage thumbnailWithSize:thumbnailCacheSize forBox:[pdfView displayBox]];
        [image lockFocus];
        NSRect imgRect = NSZeroRect;
        imgRect.size = [image size];
        float width = 0.8 * fminf(NSWidth(imgRect), NSHeight(imgRect));
        imgRect = NSInsetRect(imgRect, 0.5 * (NSWidth(imgRect) - width), 0.5 * (NSHeight(imgRect) - width));
        [[NSImage imageNamed:@"NSApplicationIcon"] drawInRect:imgRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:0.5];
        [image unlockFocus];
        
        for (i = 0; i < count; i++) {
            SKThumbnail *thumbnail = [[SKThumbnail alloc] initWithImage:image label:[pageLabels objectAtIndex:i]];
            [thumbnail setDirty:YES];
            [thumbnails addObject:thumbnail];
            [thumbnail release];
        }
    }
    [self didChangeValueForKey:@"thumbnails"];
    [self allThumbnailsNeedUpdate];
}

- (void)resetThumbnailSizeIfNeeded {
    roundedThumbnailSize = roundf([[NSUserDefaults standardUserDefaults] floatForKey:SKThumbnailSizeKey]);

    float defaultSize = roundedThumbnailSize;
    float thumbnailSize = (defaultSize < 32.1) ? 32.0 : (defaultSize < 64.1) ? 64.0 : (defaultSize < 128.1) ? 128.0 : 256.0;
    
    if (fabsf(thumbnailSize - thumbnailCacheSize) > 0.1) {
        thumbnailCacheSize = thumbnailSize;
        
        if ([self countOfThumbnails])
            [self allThumbnailsNeedUpdate];
    }
}

- (void)updateThumbnailAtPageIndex:(unsigned)index {
    [[self objectInThumbnailsAtIndex:index] setDirty:YES];
    [thumbnailTableView reloadData];
}

- (void)allThumbnailsNeedUpdate {
    NSEnumerator *te = [thumbnails objectEnumerator];
    SKThumbnail *tn;
    while (tn = [te nextObject])
        [tn setDirty:YES];
    [thumbnailTableView reloadData];
}

#pragma mark Notes

- (void)updateNoteSelection {

    NSArray *orderedNotes = [noteArrayController arrangedObjects];
    PDFAnnotation *annotation, *selAnnotation = nil;
    unsigned int pageIndex = [[pdfView currentPage] pageIndex];
	int i, count = [orderedNotes count];
    unsigned int selPageIndex = [noteOutlineView selectedRow] != -1 ? [[self selectedNote] pageIndex] : NSNotFound;
    
    if (count == 0 || selPageIndex == pageIndex)
		return;
	
	// Walk outline view looking for best firstpage number match.
	for (i = 0; i < count; i++) {
		// Get the destination of the given row....
        annotation = [orderedNotes objectAtIndex:i];
		
		if ([annotation pageIndex] == pageIndex) {
            selAnnotation = annotation;
			break;
		} else if ([annotation pageIndex] > pageIndex) {
			if (i == 0)
				selAnnotation = [orderedNotes objectAtIndex:0];
			else if ([[orderedNotes objectAtIndex:i - 1] pageIndex] != selPageIndex)
                selAnnotation = [orderedNotes objectAtIndex:i - 1];
			break;
		}
	}
    if (selAnnotation) {
        updatingNoteSelection = YES;
        [noteOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:[noteOutlineView rowForItem:selAnnotation]] byExtendingSelection:NO];
        updatingNoteSelection = NO;
    }
}

- (void)updateNoteFilterPredicate {
    NSPredicate *filterPredicate = nil;
    NSPredicate *typePredicate = nil;
    NSPredicate *searchPredicate = nil;
    NSArray *types = [noteOutlineView noteTypes];
    NSString *searchString = [noteSearchField stringValue];
    if ([types count] < 8) {
        NSExpression *lhs = [NSExpression expressionForKeyPath:@"type"];
        NSMutableArray *predicateArray = [NSMutableArray array];
        NSEnumerator *typeEnum = [types objectEnumerator];
        NSString *type;
        
        while (type = [typeEnum nextObject]) {
            NSExpression *rhs = [NSExpression expressionForConstantValue:type];
            NSPredicate *predicate = [NSComparisonPredicate predicateWithLeftExpression:lhs rightExpression:rhs modifier:NSDirectPredicateModifier type:NSEqualToPredicateOperatorType options:0];
            [predicateArray addObject:predicate];
        }
        typePredicate = [NSCompoundPredicate orPredicateWithSubpredicates:predicateArray];
    }
    if (searchString && [searchString isEqualToString:@""] == NO) {
        NSExpression *lhs = [NSExpression expressionForConstantValue:searchString];
        NSExpression *rhs = [NSExpression expressionForKeyPath:@"contents"];
        NSPredicate *contentsPredicate = [NSComparisonPredicate predicateWithLeftExpression:lhs rightExpression:rhs modifier:NSDirectPredicateModifier type:NSInPredicateOperatorType options:NSCaseInsensitivePredicateOption | NSDiacriticInsensitivePredicateOption];
        rhs = [NSExpression expressionForKeyPath:@"text.string"];
        NSPredicate *textPredicate = [NSComparisonPredicate predicateWithLeftExpression:lhs rightExpression:rhs modifier:NSDirectPredicateModifier type:NSInPredicateOperatorType options:NSCaseInsensitivePredicateOption | NSDiacriticInsensitivePredicateOption];
        searchPredicate = [NSCompoundPredicate orPredicateWithSubpredicates:[NSArray arrayWithObjects:contentsPredicate, textPredicate, nil]];
    }
    if (typePredicate) {
        if (searchPredicate)
            filterPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:typePredicate, searchPredicate, nil]];
        else
            filterPredicate = typePredicate;
    } else if (searchPredicate) {
        filterPredicate = searchPredicate;
    }
    [noteArrayController setFilterPredicate:filterPredicate];
    [noteOutlineView reloadData];
}

#pragma mark Snapshots

- (void)resetSnapshotSizeIfNeeded {
    roundedSnapshotThumbnailSize = roundf([[NSUserDefaults standardUserDefaults] floatForKey:SKSnapshotThumbnailSizeKey]);
    float defaultSize = roundedSnapshotThumbnailSize;
    float snapshotSize = (defaultSize < 32.1) ? 32.0 : (defaultSize < 64.1) ? 64.0 : (defaultSize < 128.1) ? 128.0 : 256.0;
    
    if (fabsf(snapshotSize - snapshotCacheSize) > 0.1) {
        snapshotCacheSize = snapshotSize;
        
        if (snapshotTimer) {
            [snapshotTimer invalidate];
            [snapshotTimer release];
            snapshotTimer = nil;
        }
        
        if ([self countOfSnapshots])
            [self allSnapshotsNeedUpdate];
    }
}

- (void)snapshotNeedsUpdate:(SKSnapshotWindowController *)dirtySnapshot {
    if ([dirtySnapshots containsObject:dirtySnapshot] == NO) {
        [dirtySnapshots addObject:dirtySnapshot];
        [self updateSnapshotsIfNeeded];
    }
}

- (void)allSnapshotsNeedUpdate {
    [dirtySnapshots setArray:[self snapshots]];
    [self updateSnapshotsIfNeeded];
}

- (void)updateSnapshotsIfNeeded {
    if ([snapshotTableView window] != nil && [dirtySnapshots count] > 0 && snapshotTimer == nil)
        snapshotTimer = [[NSTimer scheduledTimerWithTimeInterval:0.03 target:self selector:@selector(updateSnapshot:) userInfo:NULL repeats:YES] retain];
}

- (void)updateSnapshot:(NSTimer *)timer {
    if ([dirtySnapshots count]) {
        SKSnapshotWindowController *controller = [dirtySnapshots objectAtIndex:0];
        NSSize newSize, oldSize = [[controller thumbnail] size];
        NSImage *image = [controller thumbnailWithSize:snapshotCacheSize];
        
        [controller setThumbnail:image];
        [dirtySnapshots removeObject:controller];
        
        newSize = [image size];
        if (fabsf(newSize.width - oldSize.width) > 1.0 || fabsf(newSize.height - oldSize.height) > 1.0) {
            unsigned index = [[snapshotArrayController arrangedObjects] indexOfObject:controller];
            [snapshotTableView noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:index]];
        }
    }
    if ([dirtySnapshots count] == 0) {
        [snapshotTimer invalidate];
        [snapshotTimer release];
        snapshotTimer = nil;
    }
}

#pragma mark Toolbar

- (void)setupToolbar {
    // Create a new toolbar instance, and attach it to our document window
    NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier:SKDocumentToolbarIdentifier] autorelease];
    SKToolbarItem *item;
    NSRect frame;
    NSMenu *menu;
    NSMenuItem *menuItem;
    
    toolbarItems = [[NSMutableDictionary alloc] initWithCapacity:9];
    
    // Set up toolbar properties: Allow customization, give a default display mode, and remember state in user defaults
    [toolbar setAllowsUserCustomization: YES];
    [toolbar setAutosavesConfiguration: YES];
    [toolbar setDisplayMode: NSToolbarDisplayModeDefault];
    
    // We are the delegate
    [toolbar setDelegate: self];
    
    // Add template toolbar items
    
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarPreviousItemIdentifier];
    [item setLabels:NSLocalizedString(@"Previous", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Go To Previous Page", @"Tool tip message")];
    [item setImageNamed:@"ToolbarPrevious"];
    [item setTarget:self];
    [item setAction:@selector(doGoToPreviousPage:)];
    [toolbarItems setObject:item forKey:SKDocumentToolbarPreviousItemIdentifier];
    [item release];
    
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarNextItemIdentifier];
    [item setLabels:NSLocalizedString(@"Next", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Go To Next Page", @"Tool tip message")];
    [item setImageNamed:@"ToolbarNext"];
    [item setTarget:self];
    [item setAction:@selector(doGoToNextPage:)];
    [toolbarItems setObject:item forKey:SKDocumentToolbarNextItemIdentifier];
    [item release];
    
    
    menu = [[[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:@""] autorelease];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Back", @"Menu item title") action:@selector(doGoBack:) keyEquivalent:@""];
	[menuItem setTarget:self];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Forward", @"Menu item title") action:@selector(doGoForward:) keyEquivalent:@""];
	[menuItem setTarget:self];
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Back/Forward", @"Toolbar item label") action:NULL keyEquivalent:@""] autorelease];
    [menuItem setSubmenu:menu];
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarBackForwardItemIdentifier];
    [item setLabels:NSLocalizedString(@"Back/Forward", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Back/Forward", @"Tool tip message")];
    [[backForwardButton cell] setToolTip:NSLocalizedString(@"Go Back", @"Tool tip message") forSegment:0];
    [[backForwardButton cell] setToolTip:NSLocalizedString(@"Go Forward", @"Tool tip message") forSegment:1];
    frame = [backForwardButton frame];
    frame.size.height = SEGMENTED_CONTROL_HEIGHT;
    [backForwardButton setFrame:frame];
    [item setViewWithSizes:backForwardButton];
    [item setMenuFormRepresentation:menuItem];
    [toolbarItems setObject:item forKey:SKDocumentToolbarBackForwardItemIdentifier];
    [item release];
    
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Page", @"Menu item title") action:@selector(doGoToPage:) keyEquivalent:@""] autorelease];
	[menuItem setTarget:self];
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarPageNumberItemIdentifier];
    [item setLabels:NSLocalizedString(@"Page", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Go To Page", @"Tool tip message")];
    [item setViewWithSizes:pageNumberView];
    [item setMenuFormRepresentation:menuItem];
    [toolbarItems setObject:item forKey:SKDocumentToolbarPageNumberItemIdentifier];
    [item release];
    
    menu = [[[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:@""] autorelease];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Previous", @"Menu item title") action:@selector(doGoToPreviousPage:) keyEquivalent:@""];
	[menuItem setTarget:self];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Next", @"Menu item title") action:@selector(doGoToNextPage:) keyEquivalent:@""];
	[menuItem setTarget:self];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"First", @"Menu item title") action:@selector(doGoToFirstPage:) keyEquivalent:@""];
	[menuItem setTarget:self];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Last", @"Menu item title") action:@selector(doGoToLastPage:) keyEquivalent:@""];
	[menuItem setTarget:self];
    menuItem = [menu addItemWithTitle:[NSLocalizedString(@"Page", @"Menu item title") stringByAppendingEllipsis] action:@selector(doGoToPage:) keyEquivalent:@""];
	[menuItem setTarget:self];
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Page", @"Toolbar item label") action:NULL keyEquivalent:@""] autorelease];
    [menuItem setSubmenu:menu];
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarPageNumberButtonsItemIdentifier];
    [item setLabels:NSLocalizedString(@"Page", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Go To Page", @"Tool tip message")];
    [[previousPageButton cell] setToolTip:NSLocalizedString(@"Go To First page", @"Tool tip message") forSegment:0];
    [[previousPageButton cell] setToolTip:NSLocalizedString(@"Go To Previous Page", @"Tool tip message") forSegment:1];
    [[nextPageButton cell] setToolTip:NSLocalizedString(@"Go To Next Page", @"Tool tip message") forSegment:0];
    [[nextPageButton cell] setToolTip:NSLocalizedString(@"Go To Last page", @"Tool tip message") forSegment:1];
    frame = [previousPageButton frame];
    frame.size.height = SEGMENTED_CONTROL_HEIGHT;
    [previousPageButton setFrame:frame];
    frame = [nextPageButton frame];
    frame.size.height = SEGMENTED_CONTROL_HEIGHT;
    [nextPageButton setFrame:frame];
    [item setViewWithSizes:pageNumberButtonsView];
    [item setMenuFormRepresentation:menuItem];
    [toolbarItems setObject:item forKey:SKDocumentToolbarPageNumberButtonsItemIdentifier];
    [item release];
    
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Scale", @"Menu item title") action:@selector(chooseScale:) keyEquivalent:@""] autorelease];
	[menuItem setTarget:self];
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarScaleItemIdentifier];
    [item setLabels:NSLocalizedString(@"Scale", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Scale", @"Tool tip message")];
    [item setViewWithSizes:scaleField];
    [item setMenuFormRepresentation:menuItem];
    [toolbarItems setObject:item forKey:SKDocumentToolbarScaleItemIdentifier];
    [item release];
    
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarZoomInItemIdentifier];
    [item setLabels:NSLocalizedString(@"Zoom In", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Zoom In", @"Tool tip message")];
    [item setImageNamed:@"ToolbarZoomIn"];
    [item setTarget:self];
    [item setAction:@selector(doZoomIn:)];
    [toolbarItems setObject:item forKey:SKDocumentToolbarZoomInItemIdentifier];
    [item release];
    
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarZoomOutItemIdentifier];
    [item setLabels:NSLocalizedString(@"Zoom Out", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Zoom Out", @"Tool tip message")];
    [item setImageNamed:@"ToolbarZoomOut"];
    [item setTarget:self];
    [item setAction:@selector(doZoomOut:)];
    [toolbarItems setObject:item forKey:SKDocumentToolbarZoomOutItemIdentifier];
    [item release];
    
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarZoomActualItemIdentifier];
    [item setLabels:NSLocalizedString(@"Actual Size", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Zoom To Actual Size", @"Tool tip message")];
    [item setImageNamed:@"ToolbarZoomActual"];
    [item setTarget:self];
    [item setAction:@selector(doZoomToActualSize:)];
    [toolbarItems setObject:item forKey:SKDocumentToolbarZoomActualItemIdentifier];
    [item release];
    
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarZoomToSelectionItemIdentifier];
    [item setLabels:NSLocalizedString(@"Zoom To Selection", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Zoom To Selection", @"Tool tip message")];
    [item setImageNamed:@"ToolbarZoomToSelection"];
    [item setTarget:self];
    [item setAction:@selector(doZoomToSelection:)];
    [toolbarItems setObject:item forKey:SKDocumentToolbarZoomToSelectionItemIdentifier];
    [item release];
    
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarZoomToFitItemIdentifier];
    [item setLabels:NSLocalizedString(@"Zoom To Fit", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Zoom To Fit", @"Tool tip message")];
    [item setImageNamed:@"ToolbarZoomToFit"];
    [item setTarget:self];
    [item setAction:@selector(doZoomToFit:)];
    [toolbarItems setObject:item forKey:SKDocumentToolbarZoomToFitItemIdentifier];
    [item release];
    
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarRotateRightItemIdentifier];
    [item setLabels:NSLocalizedString(@"Rotate Right", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Rotate Right", @"Tool tip message")];
    [item setImageNamed:@"ToolbarRotateRight"];
    [item setTarget:self];
    [item setAction:@selector(rotateAllRight:)];
    [toolbarItems setObject:item forKey:SKDocumentToolbarRotateRightItemIdentifier];
    [item release];
    
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarRotateLeftItemIdentifier];
    [item setLabels:NSLocalizedString(@"Rotate Left", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Rotate Left", @"Tool tip message")];
    [item setImageNamed:@"ToolbarRotateLeft"];
    [item setTarget:self];
    [item setAction:@selector(rotateAllLeft:)];
    [toolbarItems setObject:item forKey:SKDocumentToolbarRotateLeftItemIdentifier];
    [item release];
    
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarCropItemIdentifier];
    [item setLabels:NSLocalizedString(@"Crop", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Crop", @"Tool tip message")];
    [item setImageNamed:@"ToolbarCrop"];
    [item setTarget:self];
    [item setAction:@selector(cropAll:)];
    [toolbarItems setObject:item forKey:SKDocumentToolbarCropItemIdentifier];
    [item release];
    
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarFullScreenItemIdentifier];
    [item setLabels:NSLocalizedString(@"Full Screen", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Full Screen", @"Tool tip message")];
    [item setImageNamed:@"ToolbarFullScreen"];
    [item setTarget:self];
    [item setAction:@selector(enterFullScreen:)];
    [toolbarItems setObject:item forKey:SKDocumentToolbarFullScreenItemIdentifier];
    [item release];
    
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarPresentationItemIdentifier];
    [item setLabels:NSLocalizedString(@"Presentation", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Presentation", @"Tool tip message")];
    [item setImageNamed:@"ToolbarPresentation"];
    [item setTarget:self];
    [item setAction:@selector(enterPresentation:)];
    [toolbarItems setObject:item forKey:SKDocumentToolbarPresentationItemIdentifier];
    [item release];
    
    menu = [[[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:@""] autorelease];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Text Note", @"Menu item title") action:@selector(createNewNote:) keyEquivalent:@""];
    [menuItem setTag:SKFreeTextNote];
    [menuItem setImage:[NSImage imageNamed:@"ToolbarTextNote"]];
    [menuItem setTarget:self];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Anchored Note", @"Menu item title") action:@selector(createNewNote:) keyEquivalent:@""];
    [menuItem setTag:SKAnchoredNote];
    [menuItem setImage:[NSImage imageNamed:@"ToolbarNote"]];
    [menuItem setTarget:self];
    menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Add Note", @"Toolbar item label") action:NULL keyEquivalent:@""] autorelease];
    [menuItem setSubmenu:menu];
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarNewNoteItemIdentifier];
    [item setLabels:NSLocalizedString(@"Add Note", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Add New Note", @"Tool tip message")];
    [item setTarget:self];
    [item setViewWithSizes:notePopUpButton];
    [item setMenuFormRepresentation:menuItem];
    [toolbarItems setObject:item forKey:SKDocumentToolbarNewNoteItemIdentifier];
    [item release];
    
    [notePopUpButton setShowsMenuWhenIconClicked:NO];
    [[notePopUpButton cell] setAltersStateOfSelectedItem:YES];
    [[notePopUpButton cell] setAlwaysUsesFirstItemAsSelected:NO];
    [[notePopUpButton cell] setUsesItemFromMenu:YES];
    [notePopUpButton setRefreshesMenu:NO];
    [notePopUpButton setMenu:menu];
    
    menu = [[[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:@""] autorelease];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Circle", @"Menu item title") action:@selector(createNewNote:) keyEquivalent:@""];
    [menuItem setTag:SKCircleNote];
    [menuItem setImage:[NSImage imageNamed:@"ToolbarCircleNote"]];
    [menuItem setTarget:self];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Box", @"Menu item title") action:@selector(createNewNote:) keyEquivalent:@""];
    [menuItem setTag:SKSquareNote];
    [menuItem setImage:[NSImage imageNamed:@"ToolbarSquareNote"]];
    [menuItem setTarget:self];
    menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Add Shape", @"Toolbar item label") action:NULL keyEquivalent:@""] autorelease];
    [menuItem setSubmenu:menu];
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarNewCircleNoteItemIdentifier];
    [item setLabels:NSLocalizedString(@"Add Shape", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Add New Circle or Box", @"Tool tip message")];
    [item setTarget:self];
    [item setViewWithSizes:circlePopUpButton];
    [item setMenuFormRepresentation:menuItem];
    [toolbarItems setObject:item forKey:SKDocumentToolbarNewCircleNoteItemIdentifier];
    [item release];
    
    [circlePopUpButton setShowsMenuWhenIconClicked:NO];
    [[circlePopUpButton cell] setAltersStateOfSelectedItem:YES];
    [[circlePopUpButton cell] setAlwaysUsesFirstItemAsSelected:NO];
    [[circlePopUpButton cell] setUsesItemFromMenu:YES];
    [circlePopUpButton setRefreshesMenu:NO];
    [circlePopUpButton setMenu:menu];
    
    menu = [[[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:@""] autorelease];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Highlight", @"Menu item title") action:@selector(createNewNote:) keyEquivalent:@""];
    [menuItem setTag:SKHighlightNote];
    [menuItem setImage:[NSImage imageNamed:@"ToolbarHighlightNote"]];
    [menuItem setTarget:self];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Underline", @"Menu item title") action:@selector(createNewNote:) keyEquivalent:@""];
    [menuItem setTag:SKUnderlineNote];
    [menuItem setTarget:self];
    [menuItem setImage:[NSImage imageNamed:@"ToolbarUnderlineNote"]];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Strike Out", @"Menu item title") action:@selector(createNewNote:) keyEquivalent:@""];
    [menuItem setTag:SKStrikeOutNote];
    [menuItem setImage:[NSImage imageNamed:@"ToolbarStrikeOutNote"]];
    [menuItem setTarget:self];
    menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Add Markup", @"Toolbar item label") action:NULL keyEquivalent:@""] autorelease];
    [menuItem setSubmenu:menu];
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarNewMarkupItemIdentifier];
    [item setLabels:NSLocalizedString(@"Add Markup", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Add New Markup", @"Tool tip message")];
    [item setTarget:self];
    [item setViewWithSizes:markupPopUpButton];
    [item setMenuFormRepresentation:menuItem];
    [toolbarItems setObject:item forKey:SKDocumentToolbarNewMarkupItemIdentifier];
    [item release];
    
    [markupPopUpButton setShowsMenuWhenIconClicked:NO];
    [[markupPopUpButton cell] setAltersStateOfSelectedItem:YES];
    [[markupPopUpButton cell] setAlwaysUsesFirstItemAsSelected:NO];
    [[markupPopUpButton cell] setUsesItemFromMenu:YES];
    [markupPopUpButton setRefreshesMenu:NO];
    [markupPopUpButton setMenu:menu];
    
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarNewLineItemIdentifier];
    [item setLabels:NSLocalizedString(@"Add Line", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Add New Line", @"Tool tip message")];
    [item setTag:SKLineNote];
    [item setTarget:self];
    [item setAction:@selector(createNewNote:)];
    [item setImageNamed:@"ToolbarLineNote"];
    [toolbarItems setObject:item forKey:SKDocumentToolbarNewLineItemIdentifier];
    [item release];
    
    menu = [[[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:@""] autorelease];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Text Note", @"Menu item title") action:@selector(createNewNote:) keyEquivalent:@""];
	[menuItem setTarget:self];
	[menuItem setTag:SKFreeTextNote];
	[menuItem setImage:[NSImage imageNamed:@"TextNoteAdorn"]];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Anchored Note", @"Menu item title") action:@selector(createNewNote:) keyEquivalent:@""];
	[menuItem setTarget:self];
	[menuItem setTag:SKAnchoredNote];
	[menuItem setImage:[NSImage imageNamed:@"AnchoredNoteAdorn"]];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Circle", @"Menu item title") action:@selector(createNewNote:) keyEquivalent:@""];
	[menuItem setTarget:self];
	[menuItem setTag:SKCircleNote];
	[menuItem setImage:[NSImage imageNamed:@"CircleNoteAdorn"]];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Box", @"Menu item title") action:@selector(createNewNote:) keyEquivalent:@""];
	[menuItem setTarget:self];
	[menuItem setTag:SKSquareNote];
	[menuItem setImage:[NSImage imageNamed:@"SquareNoteAdorn"]];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Highlight", @"Menu item title") action:@selector(createNewNote:) keyEquivalent:@""];
	[menuItem setTarget:self];
	[menuItem setTag:SKHighlightNote];
	[menuItem setImage:[NSImage imageNamed:@"HighlightNoteAdorn"]];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Underline", @"Menu item title") action:@selector(createNewNote:) keyEquivalent:@""];
	[menuItem setTarget:self];
	[menuItem setTag:SKUnderlineNote];
	[menuItem setImage:[NSImage imageNamed:@"UnderlineNoteAdorn"]];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Strike Out", @"Menu item title") action:@selector(createNewNote:) keyEquivalent:@""];
	[menuItem setTarget:self];
	[menuItem setTag:SKStrikeOutNote];
	[menuItem setImage:[NSImage imageNamed:@"StrikeOutNoteAdorn"]];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Line", @"Menu item title") action:@selector(createNewNote:) keyEquivalent:@""];
	[menuItem setTarget:self];
	[menuItem setTag:SKLineNote];
	[menuItem setImage:[NSImage imageNamed:@"LineNoteAdorn"]];
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Add Note", @"Toolbar item label") action:NULL keyEquivalent:@""] autorelease];
    [menuItem setSubmenu:menu];
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarNewNotesItemIdentifier];
    [item setLabels:NSLocalizedString(@"Add Note", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Add New Note", @"Tool tip message")];
    [[noteButton cell] setToolTip:NSLocalizedString(@"Add New Text Note", @"Tool tip message") forSegment:SKFreeTextNote];
    [[noteButton cell] setToolTip:NSLocalizedString(@"Add New Anchored Note", @"Tool tip message") forSegment:SKAnchoredNote];
    [[noteButton cell] setToolTip:NSLocalizedString(@"Add New Circle", @"Tool tip message") forSegment:SKCircleNote];
    [[noteButton cell] setToolTip:NSLocalizedString(@"Add New Box", @"Tool tip message") forSegment:SKSquareNote];
    [[noteButton cell] setToolTip:NSLocalizedString(@"Add New Highlight", @"Tool tip message") forSegment:SKHighlightNote];
    [[noteButton cell] setToolTip:NSLocalizedString(@"Add New Underline", @"Tool tip message") forSegment:SKUnderlineNote];
    [[noteButton cell] setToolTip:NSLocalizedString(@"Add New Strike Out", @"Tool tip message") forSegment:SKStrikeOutNote];
    [[noteButton cell] setToolTip:NSLocalizedString(@"Add New Line", @"Tool tip message") forSegment:SKLineNote];
    frame = [noteButton frame];
    frame.size.height = SEGMENTED_CONTROL_HEIGHT;
    [noteButton setFrame:frame];
    [item setViewWithSizes:noteButton];
    [item setMenuFormRepresentation:menuItem];
    [toolbarItems setObject:item forKey:SKDocumentToolbarNewNotesItemIdentifier];
    [item release];
    
    menu = [[[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:@""] autorelease];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Text Tool", @"Menu item title") action:@selector(changeToolMode:) keyEquivalent:@""];
	[menuItem setTarget:self];
	[menuItem setTag:SKTextToolMode];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Scroll Tool", @"Menu item title") action:@selector(changeToolMode:) keyEquivalent:@""];
	[menuItem setTarget:self];
	[menuItem setTag:SKMoveToolMode];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Magnify Tool", @"Menu item title") action:@selector(changeToolMode:) keyEquivalent:@""];
	[menuItem setTarget:self];
	[menuItem setTag:SKMagnifyToolMode];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Select Tool", @"Menu item title") action:@selector(changeToolMode:) keyEquivalent:@""];
	[menuItem setTarget:self];
	[menuItem setTag:SKSelectToolMode];
    [menu addItem:[NSMenuItem separatorItem]];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Text Note Tool", @"Menu item title") action:@selector(changeAnnotationMode:) keyEquivalent:@""];
	[menuItem setTarget:self];
	[menuItem setTag:SKFreeTextNote];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Anchored Note Tool", @"Menu item title") action:@selector(changeAnnotationMode:) keyEquivalent:@""];
	[menuItem setTarget:self];
	[menuItem setTag:SKAnchoredNote];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Circle Tool", @"Menu item title") action:@selector(changeAnnotationMode:) keyEquivalent:@""];
	[menuItem setTarget:self];
	[menuItem setTag:SKCircleNote];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Box Tool", @"Menu item title") action:@selector(changeAnnotationMode:) keyEquivalent:@""];
	[menuItem setTarget:self];
	[menuItem setTag:SKSquareNote];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Highlight Tool", @"Menu item title") action:@selector(changeAnnotationMode:) keyEquivalent:@""];
	[menuItem setTarget:self];
	[menuItem setTag:SKHighlightNote];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Underline Tool", @"Menu item title") action:@selector(changeAnnotationMode:) keyEquivalent:@""];
	[menuItem setTarget:self];
	[menuItem setTag:SKUnderlineNote];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Strike Out Tool", @"Menu item title") action:@selector(changeAnnotationMode:) keyEquivalent:@""];
	[menuItem setTarget:self];
	[menuItem setTag:SKStrikeOutNote];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Line Tool", @"Menu item title") action:@selector(changeAnnotationMode:) keyEquivalent:@""];
	[menuItem setTarget:self];
	[menuItem setTag:SKLineNote];
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Tool Mode", @"Toolbar item label") action:NULL keyEquivalent:@""] autorelease];
    [menuItem setSubmenu:menu];
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarToolModeItemIdentifier];
    [item setLabels:NSLocalizedString(@"Tool Mode", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Tool Mode", @"Tool tip message")];
    [[toolModeButton cell] setToolTip:NSLocalizedString(@"Text Tool", @"Tool tip message") forSegment:SKTextToolMode];
    [[toolModeButton cell] setToolTip:NSLocalizedString(@"Scroll Tool", @"Tool tip message") forSegment:SKMoveToolMode];
    [[toolModeButton cell] setToolTip:NSLocalizedString(@"Magnify Tool", @"Tool tip message") forSegment:SKMagnifyToolMode];
    [[toolModeButton cell] setToolTip:NSLocalizedString(@"Select Tool", @"Tool tip message") forSegment:SKSelectToolMode];
    [[toolModeButton cell] setToolTip:NSLocalizedString(@"Note Tool", @"Tool tip message") forSegment:SKNoteToolMode];
    frame = [toolModeButton frame];
    frame.size.height = SEGMENTED_CONTROL_HEIGHT;
    [toolModeButton setFrame:frame];
    [item setViewWithSizes:toolModeButton];
    [item setMenuFormRepresentation:menuItem];
    [toolbarItems setObject:item forKey:SKDocumentToolbarToolModeItemIdentifier];
    [item release];
    menu = [[[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:@""] autorelease];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Text Note", @"Menu item title") action:@selector(changeAnnotationMode:) keyEquivalent:@""];
	[menuItem setTarget:self];
	[menuItem setTag:SKFreeTextNote];
	[menuItem setImage:[NSImage imageNamed:@"TextNoteAdorn"]];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Anchored Note", @"Menu item title") action:@selector(changeAnnotationMode:) keyEquivalent:@""];
	[menuItem setTarget:self];
	[menuItem setTag:SKAnchoredNote];
	[menuItem setImage:[NSImage imageNamed:@"AnchoredNoteAdorn"]];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Circle", @"Menu item title") action:@selector(changeAnnotationMode:) keyEquivalent:@""];
	[menuItem setTarget:self];
	[menuItem setTag:SKCircleNote];
	[menuItem setImage:[NSImage imageNamed:@"CircleNoteAdorn"]];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Box", @"Menu item title") action:@selector(changeAnnotationMode:) keyEquivalent:@""];
	[menuItem setTarget:self];
	[menuItem setTag:SKSquareNote];
	[menuItem setImage:[NSImage imageNamed:@"SquareNoteAdorn"]];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Highlight", @"Menu item title") action:@selector(changeAnnotationMode:) keyEquivalent:@""];
	[menuItem setTarget:self];
	[menuItem setTag:SKHighlightNote];
	[menuItem setImage:[NSImage imageNamed:@"HighlightNoteAdorn"]];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Underline", @"Menu item title") action:@selector(changeAnnotationMode:) keyEquivalent:@""];
	[menuItem setTarget:self];
	[menuItem setTag:SKUnderlineNote];
	[menuItem setImage:[NSImage imageNamed:@"UnderlineNoteAdorn"]];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Strike Out", @"Menu item title") action:@selector(changeAnnotationMode:) keyEquivalent:@""];
	[menuItem setTarget:self];
	[menuItem setTag:SKStrikeOutNote];
	[menuItem setImage:[NSImage imageNamed:@"StrikeOutNoteAdorn"]];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Line", @"Menu item title") action:@selector(changeAnnotationMode:) keyEquivalent:@""];
	[menuItem setTarget:self];
	[menuItem setTag:SKLineNote];
	[menuItem setImage:[NSImage imageNamed:@"LineNoteAdorn"]];
    [toolModeButton setMenu:menu forSegment:SKNoteToolMode];
    
    menu = [[[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:@""] autorelease];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Media Box", @"Menu item title") action:@selector(changeDisplayBox:) keyEquivalent:@""];
	[menuItem setTarget:self];
	[menuItem setTag:kPDFDisplayBoxMediaBox];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Crop Box", @"Menu item title") action:@selector(changeDisplayBox:) keyEquivalent:@""];
	[menuItem setTarget:self];
	[menuItem setTag:kPDFDisplayBoxCropBox];
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Display Box", @"Toolbar item label") action:NULL keyEquivalent:@""] autorelease];
    [menuItem setSubmenu:menu];
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarDisplayBoxItemIdentifier];
    [item setLabels:NSLocalizedString(@"Display Box", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Display Box", @"Tool tip message")];
    [item setViewWithSizes:displayBoxPopUpButton];
    [item setMenuFormRepresentation:menuItem];
    [toolbarItems setObject:item forKey:SKDocumentToolbarDisplayBoxItemIdentifier];
    [item release];
    
    NSDictionary *options = [NSDictionary dictionaryWithObject:SKUnarchiveFromDataArrayTransformerName forKey:NSValueTransformerNameBindingOption];
    [colorSwatch bind:@"colors" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:[NSString stringWithFormat:@"values.%@", SKSwatchColorsKey] options:options];
    [colorSwatch sizeToFit];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleColorSwatchColorsChangedNotification:) 
                                                 name:SKColorSwatchColorsChangedNotification object:colorSwatch];
    menu = [[[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:@""] autorelease];
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Colors", @"Toolbar item label") action:@selector(orderFrontColorPanel:) keyEquivalent:@""] autorelease];
    [menuItem setSubmenu:menu];
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarColorSwatchItemIdentifier];
    [item setLabels:NSLocalizedString(@"Favorite Colors", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Favorite Colors", @"Tool tip message")];
    [item setViewWithSizes:colorSwatch];
    [item setMenuFormRepresentation:menuItem];
    [toolbarItems setObject:item forKey:SKDocumentToolbarColorSwatchItemIdentifier];
    [item release];
    [self handleColorSwatchColorsChangedNotification:nil];
    
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarColorsItemIdentifier];
    [item setLabels:NSLocalizedString(@"Colors", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Colors", @"Tool tip message")];
    [item setImageNamed:@"ToolbarColors"];
    [item setAction:@selector(orderFrontColorPanel:)];
    [toolbarItems setObject:item forKey:SKDocumentToolbarColorsItemIdentifier];
    [item release];
    
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarFontsItemIdentifier];
    [item setLabels:NSLocalizedString(@"Fonts", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Fonts", @"Tool tip message")];
    [item setImageNamed:@"ToolbarFonts"];
    [item setTarget:[NSFontManager sharedFontManager]];
    [item setAction:@selector(orderFrontFontPanel:)];
    [toolbarItems setObject:item forKey:SKDocumentToolbarFontsItemIdentifier];
    [item release];
    
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarLinesItemIdentifier];
    [item setLabels:NSLocalizedString(@"Lines", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Lines", @"Tool tip message")];
    [item setImageNamed:@"ToolbarLines"];
    [item setAction:@selector(orderFrontLineInspector:)];
    [toolbarItems setObject:item forKey:SKDocumentToolbarLinesItemIdentifier];
    [item release];
    
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarInfoItemIdentifier];
    [item setLabels:NSLocalizedString(@"Info", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Get Document Info", @"Tool tip message")];
    [item setImageNamed:@"ToolbarInfo"];
    [item setTarget:self];
    [item setAction:@selector(getInfo:)];
    [toolbarItems setObject:item forKey:SKDocumentToolbarInfoItemIdentifier];
    [item release];
    
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarContentsPaneItemIdentifier];
    [item setLabels:NSLocalizedString(@"Contents Pane", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Toggle Contents Pane", @"Tool tip message")];
    [item setImageNamed:@"ToolbarLeftPane"];
    [item setTarget:self];
    [item setAction:@selector(toggleLeftSidePane:)];
    [toolbarItems setObject:item forKey:SKDocumentToolbarContentsPaneItemIdentifier];
    [item release];
    
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarNotesPaneItemIdentifier];
    [item setLabels:NSLocalizedString(@"Notes Pane", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Toggle Notes Pane", @"Tool tip message")];
    [item setImageNamed:@"ToolbarRightPane"];
    [item setTarget:self];
    [item setAction:@selector(toggleRightSidePane:)];
    [toolbarItems setObject:item forKey:SKDocumentToolbarNotesPaneItemIdentifier];
    [item release];
    
    // Attach the toolbar to the window
    [[self window] setToolbar:toolbar];
}

- (NSToolbarItem *) toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted {

    SKToolbarItem *item = [toolbarItems objectForKey:itemIdent];
    SKToolbarItem *newItem = [[item copy] autorelease];
    // the view should not be copied
    if ([item view] && willBeInserted) {
        [newItem setView:[item view]];
        [newItem setDelegate:self];
    }
    return newItem;
}

- (void)toolbarWillAddItem:(NSNotification *)notification {
    NSToolbarItem *item = [[notification userInfo] objectForKey:@"item"];
    if ([[item itemIdentifier] isEqualToString:SKDocumentToolbarColorSwatchItemIdentifier]) {
        colorSwatchToolbarItem = item;
    }
}

- (void)toolbarDidRemoveItem:(NSNotification *)notification {
    NSToolbarItem *item = [[notification userInfo] objectForKey:@"item"];
    if ([[item itemIdentifier] isEqualToString:SKDocumentToolbarColorSwatchItemIdentifier]) {
        colorSwatchToolbarItem = nil;
    }
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
    return [NSArray arrayWithObjects:
        SKDocumentToolbarPreviousItemIdentifier, 
        SKDocumentToolbarNextItemIdentifier, 
        SKDocumentToolbarPageNumberItemIdentifier, 
        SKDocumentToolbarBackForwardItemIdentifier, 
		NSToolbarSeparatorItemIdentifier, 
        SKDocumentToolbarZoomInItemIdentifier, 
        SKDocumentToolbarZoomOutItemIdentifier, 
        SKDocumentToolbarToolModeItemIdentifier, 
		NSToolbarSeparatorItemIdentifier, 
        SKDocumentToolbarNewNoteItemIdentifier, 
        SKDocumentToolbarNewCircleNoteItemIdentifier, 
        SKDocumentToolbarNewMarkupItemIdentifier,
        SKDocumentToolbarNewLineItemIdentifier, nil];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
    return [NSArray arrayWithObjects: 
        SKDocumentToolbarPreviousItemIdentifier, 
        SKDocumentToolbarNextItemIdentifier, 
        SKDocumentToolbarBackForwardItemIdentifier, 
        SKDocumentToolbarPageNumberItemIdentifier, 
        SKDocumentToolbarPageNumberButtonsItemIdentifier, 
        SKDocumentToolbarScaleItemIdentifier, 
        SKDocumentToolbarZoomInItemIdentifier, 
        SKDocumentToolbarZoomOutItemIdentifier, 
        SKDocumentToolbarZoomActualItemIdentifier, 
        SKDocumentToolbarZoomToSelectionItemIdentifier, 
        SKDocumentToolbarZoomToFitItemIdentifier, 
        SKDocumentToolbarRotateRightItemIdentifier, 
        SKDocumentToolbarRotateLeftItemIdentifier, 
        SKDocumentToolbarCropItemIdentifier, 
        SKDocumentToolbarFullScreenItemIdentifier, 
        SKDocumentToolbarPresentationItemIdentifier, 
        SKDocumentToolbarNewNoteItemIdentifier, 
        SKDocumentToolbarNewCircleNoteItemIdentifier, 
        SKDocumentToolbarNewMarkupItemIdentifier,
        SKDocumentToolbarNewLineItemIdentifier,
        SKDocumentToolbarNewNotesItemIdentifier, 
        SKDocumentToolbarContentsPaneItemIdentifier, 
        SKDocumentToolbarNotesPaneItemIdentifier, 
        SKDocumentToolbarInfoItemIdentifier, 
        SKDocumentToolbarToolModeItemIdentifier, 
        SKDocumentToolbarDisplayBoxItemIdentifier, 
        SKDocumentToolbarColorSwatchItemIdentifier, 
        SKDocumentToolbarColorsItemIdentifier, 
        SKDocumentToolbarFontsItemIdentifier, 
        SKDocumentToolbarLinesItemIdentifier, 
		NSToolbarPrintItemIdentifier,
		NSToolbarFlexibleSpaceItemIdentifier, 
		NSToolbarSpaceItemIdentifier, 
		NSToolbarSeparatorItemIdentifier, 
		NSToolbarCustomizeToolbarItemIdentifier, nil];
}

#pragma mark UI validation

- (BOOL)validateToolbarItem:(NSToolbarItem *) toolbarItem {
    NSString *identifier = [toolbarItem itemIdentifier];
    if ([identifier isEqualToString:SKDocumentToolbarPreviousItemIdentifier]) {
        return [pdfView canGoToPreviousPage];
    } else if ([identifier isEqualToString:SKDocumentToolbarNextItemIdentifier]) {
        return [pdfView canGoToNextPage];
    } else if ([identifier isEqualToString:SKDocumentToolbarZoomInItemIdentifier]) {
        return [pdfView canZoomIn];
    } else if ([identifier isEqualToString:SKDocumentToolbarZoomToSelectionItemIdentifier]) {
        return NSIsEmptyRect([pdfView currentSelectionRect]) == NO;
    } else if ([identifier isEqualToString:SKDocumentToolbarZoomToFitItemIdentifier]) {
        return [pdfView autoScales] == NO;
    } else if ([identifier isEqualToString:SKDocumentToolbarZoomActualItemIdentifier]) {
        return fabsf([pdfView scaleFactor] - 1.0) > 0.01;
    } else if ([identifier isEqualToString:SKDocumentToolbarCropItemIdentifier]) {
        return YES;
    } else if ([identifier isEqualToString:SKDocumentToolbarFullScreenItemIdentifier]) {
        return YES;
    } else if ([identifier isEqualToString:SKDocumentToolbarPresentationItemIdentifier]) {
        return YES;
    } else if ([identifier isEqualToString:SKDocumentToolbarNewNoteItemIdentifier] || [identifier isEqualToString:SKDocumentToolbarNewCircleNoteItemIdentifier] || [identifier isEqualToString:SKDocumentToolbarNewLineItemIdentifier]) {
        return ([pdfView toolMode] == SKTextToolMode || [pdfView toolMode] == SKNoteToolMode) && [pdfView hideNotes] == NO;
    } else if ([identifier isEqualToString:SKDocumentToolbarNewMarkupItemIdentifier]) {
        return ([pdfView toolMode] == SKTextToolMode || [pdfView toolMode] == SKNoteToolMode) && [[[pdfView currentSelection] pages] count] && [pdfView hideNotes] == NO;
    } else if ([identifier isEqualToString:SKDocumentToolbarNewNotesItemIdentifier]) {
        if (([pdfView toolMode] != SKTextToolMode && [pdfView toolMode] != SKNoteToolMode) || [pdfView hideNotes])
            return NO;
        BOOL enabled = [[[pdfView currentSelection] pages] count] > 0;
        [noteButton setEnabled:enabled forSegment:SKHighlightNote];
        [noteButton setEnabled:enabled forSegment:SKUnderlineNote];
        [noteButton setEnabled:enabled forSegment:SKStrikeOutNote];
        return YES;
    } else if ([identifier isEqualToString:SKDocumentToolbarInfoItemIdentifier]) {
        return YES;
    } else {
        return YES;
    }
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    SEL action = [menuItem action];
    if (action == @selector(createNewNote:)) {
        BOOL isMarkup = [menuItem tag] == SKHighlightNote || [menuItem tag] == SKUnderlineNote || [menuItem tag] == SKStrikeOutNote;
        return [self isPresentation] == NO && ([pdfView toolMode] == SKTextToolMode || [pdfView toolMode] == SKNoteToolMode) && (isMarkup == NO || [[[pdfView currentSelection] pages] count]) && [pdfView hideNotes] == NO;
    } else if (action == @selector(editNote:)) {
        PDFAnnotation *annotation = [pdfView activeAnnotation];
        return [self isPresentation] == NO && [annotation isNoteAnnotation] && ([[annotation type] isEqualToString:SKFreeTextString] || [[annotation type] isEqualToString:SKNoteString]);
    } else if (action == @selector(toggleHideNotes:)) {
        if ([pdfView hideNotes])
            [menuItem setTitle:NSLocalizedString(@"Show Notes", @"Menu item title")];
        else
            [menuItem setTitle:NSLocalizedString(@"Hide Notes", @"Menu item title")];
        return YES;
    } else if (action == @selector(displaySinglePages:)) {
        BOOL displaySinglePages = [pdfView displayMode] == kPDFDisplaySinglePage || [pdfView displayMode] == kPDFDisplaySinglePageContinuous;
        [menuItem setState:displaySinglePages ? NSOnState : NSOffState];
        return [self isPresentation] == NO;
    } else if (action == @selector(displayFacingPages:)) {
        BOOL displayFacingPages = [pdfView displayMode] == kPDFDisplayTwoUp || [pdfView displayMode] == kPDFDisplayTwoUpContinuous;
        [menuItem setState:displayFacingPages ? NSOnState : NSOffState];
        return [self isPresentation] == NO;
    } else if (action == @selector(toggleDisplayContinuous:)) {
        BOOL displayContinuous = [pdfView displayMode] == kPDFDisplaySinglePageContinuous || [pdfView displayMode] == kPDFDisplayTwoUpContinuous;
        [menuItem setState:displayContinuous ? NSOnState : NSOffState];
        return [self isPresentation] == NO;
    } else if (action == @selector(toggleDisplayAsBook:)) {
        [menuItem setState:[pdfView displaysAsBook] ? NSOnState : NSOffState];
        return [self isPresentation] == NO && ([pdfView displayMode] == kPDFDisplayTwoUp || [pdfView displayMode] == kPDFDisplayTwoUpContinuous);
    } else if (action == @selector(toggleDisplayPageBreaks:)) {
        [menuItem setState:[pdfView displaysPageBreaks] ? NSOnState : NSOffState];
        return [self isPresentation] == NO;
    } else if (action == @selector(changeDisplayBox:)) {
        [menuItem setState:[pdfView displayBox] == [menuItem tag] ? NSOnState : NSOffState];
        return [self isPresentation] == NO;
    } else if (action == @selector(changeToolMode:)) {
        [menuItem setState:[pdfView toolMode] == (unsigned)[menuItem tag] ? NSOnState : NSOffState];
        return YES;
    } else if (action == @selector(changeAnnotationMode:)) {
        if ([[menuItem menu] numberOfItems] > 8)
            [menuItem setState:[pdfView toolMode] == SKNoteToolMode && [pdfView annotationMode] == (unsigned)[menuItem tag] ? NSOnState : NSOffState];
        else
            [menuItem setState:[pdfView annotationMode] == (unsigned)[menuItem tag] ? NSOnState : NSOffState];
        return YES;
    } else if (action == @selector(doGoToNextPage:)) {
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
        return [self isPresentation] == NO && [pdfView canZoomIn];
    } else if (action == @selector(doZoomOut:)) {
        return [self isPresentation] == NO && [pdfView canZoomOut];
    } else if (action == @selector(doZoomToActualSize:)) {
        return fabsf([pdfView scaleFactor] - 1.0 ) > 0.01;
    } else if (action == @selector(doZoomToPhysicalSize:)) {
        return [self isPresentation] == NO;
    } else if (action == @selector(doZoomToSelection:)) {
        return [self isPresentation] == NO && NSIsEmptyRect([pdfView currentSelectionRect]) == NO;
    } else if (action == @selector(doZoomToFit:)) {
        return [self isPresentation] == NO && [pdfView autoScales] == NO;
    } else if (action == @selector(doAutoScale:)) {
        return [pdfView autoScales] == NO;
    } else if (action == @selector(toggleAutoScale:)) {
        [menuItem setState:[pdfView autoScales] ? NSOnState : NSOffState];
        return YES;
    } else if (action == @selector(cropAll:) || action == @selector(crop:) || action == @selector(autoCropAll:) || action == @selector(smartAutoCropAll:)) {
        return [self isPresentation] == NO;
    } else if (action == @selector(autoSelectContent:)) {
        return [self isPresentation] == NO && [pdfView toolMode] == SKSelectToolMode;
    } else if (action == @selector(toggleLeftSidePane:)) {
        if ([self leftSidePaneIsOpen])
            [menuItem setTitle:NSLocalizedString(@"Hide Contents Pane", @"Menu item title")];
        else
            [menuItem setTitle:NSLocalizedString(@"Show Contents Pane", @"Menu item title")];
        return YES;
    } else if (action == @selector(toggleRightSidePane:)) {
        if ([self rightSidePaneIsOpen])
            [menuItem setTitle:NSLocalizedString(@"Hide Notes Pane", @"Menu item title")];
        else
            [menuItem setTitle:NSLocalizedString(@"Show Notes Pane", @"Menu item title")];
        return [self isPresentation] == NO;
    } else if (action == @selector(changeLeftSidePaneState:)) {
        [menuItem setState:(int)leftSidePaneState == [menuItem tag] ? ([findTableView window] ? NSMixedState : NSOnState) : NSOffState];
        return [menuItem tag] == SKThumbnailSidePaneState || pdfOutline;
    } else if (action == @selector(changeRightSidePaneState:)) {
        [menuItem setState:(int)rightSidePaneState == [menuItem tag] ? NSOnState : NSOffState];
        return [self isPresentation] == NO;
    } else if (action == @selector(toggleSplitPDF:)) {
        if ([secondaryPdfView window])
            [menuItem setTitle:NSLocalizedString(@"Hide Split PDF", @"Menu item title")];
        else
            [menuItem setTitle:NSLocalizedString(@"Show Split PDF", @"Menu item title")];
        return [self isPresentation] == NO && [self isFullScreen] == NO;
    } else if (action == @selector(toggleStatusBar:)) {
        if ([statusBar isVisible])
            [menuItem setTitle:NSLocalizedString(@"Hide Status Bar", @"Menu item title")];
        else
            [menuItem setTitle:NSLocalizedString(@"Show Status Bar", @"Menu item title")];
        return [self isPresentation] == NO;
    } else if (action == @selector(searchPDF:)) {
        return [self isPresentation] == NO;
    } else if (action == @selector(toggleFullScreen:)) {
        if ([self isFullScreen])
            [menuItem setTitle:NSLocalizedString(@"Remove Full Screen", @"Menu item title")];
        else
            [menuItem setTitle:NSLocalizedString(@"Full Screen", @"Menu item title")];
        return [[self pdfDocument] isLocked] == NO;
    } else if (action == @selector(togglePresentation:)) {
        if ([self isPresentation])
            [menuItem setTitle:NSLocalizedString(@"Remove Presentation", @"Menu item title")];
        else
            [menuItem setTitle:NSLocalizedString(@"Presentation", @"Menu item title")];
        return [[self pdfDocument] isLocked] == NO;
    } else if (action == @selector(getInfo:)) {
        return [self isPresentation] == NO;
    } else if (action == @selector(performFit:)) {
        return [self isFullScreen] == NO && [self isPresentation] == NO;
    } else if (action == @selector(password:)) {
        return [self isPresentation] == NO && [[self pdfDocument] isLocked];
    } else if (action == @selector(toggleReadingBar:)) {
        if ([[self pdfView] hasReadingBar])
            [menuItem setTitle:NSLocalizedString(@"Hide Reading Bar", @"Menu item title")];
        else
            [menuItem setTitle:NSLocalizedString(@"Show Reading Bar", @"Menu item title")];
        return [self isPresentation] == NO;
    } else if (action == @selector(savePDFSettingToDefaults:)) {
        if ([self isFullScreen])
            [menuItem setTitle:NSLocalizedString(@"Use Current View Settings as Default for Full Screen", @"Menu item title")];
        else
            [menuItem setTitle:NSLocalizedString(@"Use Current View Settings as Default", @"Menu item title")];
        return [self isPresentation] == NO;
    }
    return YES;
}

#pragma mark SKSplitView delegate protocol

- (void)splitView:(SKSplitView *)sender doubleClickedDividerAt:(int)offset{
    if ([sender isEqual:splitView]) {
        if (offset == 0)
            [self toggleLeftSidePane:self];
        else
            [self toggleRightSidePane:self];
    } else if ([sender isEqual:pdfSplitView] && [[sender subviews] count] > 1) {
        NSRect primaryFrame = [pdfEdgeView frame];
        NSRect secondaryFrame = [secondaryPdfEdgeView frame];
        
        if (NSHeight(secondaryFrame) > 0.0) {
            lastSecondaryPdfViewPaneHeight = NSHeight(secondaryFrame); // cache this
            primaryFrame.size.height += lastLeftSidePaneWidth;
            secondaryFrame.size.height = 0.0;
        } else {
            if(lastSecondaryPdfViewPaneHeight <= 0.0)
                lastSecondaryPdfViewPaneHeight = 200.0; // a reasonable value to start
            if (lastSecondaryPdfViewPaneHeight > 0.5 * NSHeight(primaryFrame))
                lastSecondaryPdfViewPaneHeight = floorf(0.5 * NSHeight(primaryFrame));
            primaryFrame.size.height -= lastSecondaryPdfViewPaneHeight;
            secondaryFrame.size.height = lastSecondaryPdfViewPaneHeight;
        }
        primaryFrame.origin.y = NSMaxY(secondaryFrame) + [pdfSplitView dividerThickness];
        [pdfEdgeView setFrame:primaryFrame];
        [secondaryPdfEdgeView setFrame:secondaryFrame];
        [pdfSplitView setNeedsDisplay:YES];
        [secondaryPdfView layoutDocumentView];
        [secondaryPdfView setNeedsDisplay:YES];
    }
}

- (void)splitView:(NSSplitView *)sender resizeSubviewsWithOldSize:(NSSize)oldSize {
    if ([sender isEqual:splitView]) {
        
        if (usesDrawers == NO) {
            NSView *leftView = [[sender subviews] objectAtIndex:0];
            NSView *mainView = [[sender subviews] objectAtIndex:1]; // pdfView
            NSView *rightView = [[sender subviews] objectAtIndex:2];
            NSRect leftFrame = [leftView frame];
            NSRect mainFrame = [mainView frame];
            NSRect rightFrame = [rightView frame];
            float contentWidth = NSWidth([sender frame]) - 2 * [sender dividerThickness];
            
            if (NSWidth(leftFrame) <= 1.0)
                leftFrame.size.width = 0.0;
            if (NSWidth(rightFrame) <= 1.0)
                rightFrame.size.width = 0.0;
            
            if (contentWidth < NSWidth(leftFrame) + NSWidth(rightFrame)) {
                float resizeFactor = contentWidth / (oldSize.width - [sender dividerThickness]);
                leftFrame.size.width = floorf(resizeFactor * NSWidth(leftFrame));
                rightFrame.size.width = floorf(resizeFactor * NSWidth(rightFrame));
            }
            
            mainFrame.size.width = contentWidth - NSWidth(leftFrame) - NSWidth(rightFrame);
            mainFrame.origin.x = NSMaxX(leftFrame) + [sender dividerThickness];
            rightFrame.origin.x =  NSMaxX(mainFrame) + [sender dividerThickness];
            leftFrame.size.height = rightFrame.size.height = mainFrame.size.height = NSHeight([sender frame]);
            [leftView setFrame:leftFrame];
            [rightView setFrame:rightFrame];
            [mainView setFrame:mainFrame];
        }
        
    } else if ([sender isEqual:pdfSplitView]) {
        
        if ([[sender subviews] count] > 1) {
            NSView *primaryView = [[sender subviews] objectAtIndex:0];
            NSView *secondaryView = [[sender subviews] objectAtIndex:1];
            NSRect primaryFrame = [primaryView frame];
            NSRect secondaryFrame = [secondaryView frame];
            float contentHeight = NSHeight([sender frame]) - [sender dividerThickness];
            
            if (NSHeight(secondaryFrame) <= 1.0)
                secondaryFrame.size.height = 0.0;
            
            if (contentHeight < NSHeight(secondaryFrame))
                secondaryFrame.size.height = floorf(NSHeight(secondaryFrame) * contentHeight / (oldSize.height - [sender dividerThickness]));
            
            primaryFrame.size.height = contentHeight - NSHeight(secondaryFrame);
            primaryFrame.origin.x = NSMaxY(secondaryFrame) + [sender dividerThickness];
            primaryFrame.size.width = secondaryFrame.size.width = NSWidth([sender frame]);
            [primaryView setFrame:primaryFrame];
            [secondaryView setFrame:secondaryFrame];
        } else {
            [[[sender subviews] objectAtIndex:0] setFrame:[sender bounds]];
        }
        
    }
    [sender adjustSubviews];
}

- (void)splitViewDidResizeSubviews:(NSNotification *)notification {
    id sender = [notification object];
    if (([sender isEqual:splitView] || sender == nil) && [[self window] frameAutosaveName] && settingUpWindow == NO && usesDrawers == NO) {
        [[NSUserDefaults standardUserDefaults] setFloat:NSWidth([leftSideContentView frame]) forKey:SKLeftSidePaneWidthKey];
        [[NSUserDefaults standardUserDefaults] setFloat:NSWidth([rightSideContentView frame]) forKey:SKRightSidePaneWidthKey];
    }
}

#pragma mark NSDrawer delegate protocol

- (NSSize)drawerWillResizeContents:(NSDrawer *)sender toSize:(NSSize)contentSize {
    if ([[self window] frameAutosaveName] && settingUpWindow == NO) {
        if ([sender isEqual:leftSideDrawer])
            [[NSUserDefaults standardUserDefaults] setFloat:contentSize.width forKey:SKLeftSidePaneWidthKey];
        else if ([sender isEqual:rightSideDrawer])
            [[NSUserDefaults standardUserDefaults] setFloat:contentSize.width forKey:SKRightSidePaneWidthKey];
    }
    return contentSize;
}

- (void)drawerDidOpen:(NSNotification *)notification {
    id sender = [notification object];
    if ([[self window] frameAutosaveName] && settingUpWindow == NO) {
        if ([sender isEqual:leftSideDrawer])
            [[NSUserDefaults standardUserDefaults] setFloat:[sender contentSize].width forKey:SKLeftSidePaneWidthKey];
        else if ([sender isEqual:rightSideDrawer])
            [[NSUserDefaults standardUserDefaults] setFloat:[sender contentSize].width forKey:SKRightSidePaneWidthKey];
    }
}

- (void)drawerDidClose:(NSNotification *)notification {
    id sender = [notification object];
    if ([[self window] frameAutosaveName] && settingUpWindow == NO) {
        if ([sender isEqual:leftSideDrawer])
            [[NSUserDefaults standardUserDefaults] setFloat:0.0 forKey:SKLeftSidePaneWidthKey];
        else if ([sender isEqual:rightSideDrawer])
            [[NSUserDefaults standardUserDefaults] setFloat:0.0 forKey:SKRightSidePaneWidthKey];
    }
}

@end
