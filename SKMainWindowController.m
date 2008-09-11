//
//  SKMainWindowController.m
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

#import "SKMainWindowController.h"
#import "SKMainWindowController_Toolbar.h"
#import "SKMainWindowController_UI.h"
#import <Quartz/Quartz.h>
#import <Carbon/Carbon.h>
#import "SKStringConstants.h"
#import "SKStringConstants.h"
#import "SKSnapshotWindowController.h"
#import "SKNoteWindowController.h"
#import "SKInfoWindowController.h"
#import "SKBookmarkController.h"
#import "SKFullScreenWindow.h"
#import "SKNavigationWindow.h"
#import "SKSideWindow.h"
#import "PDFPage_SKExtensions.h"
#import "SKPDFDocument.h"
#import "SKThumbnail.h"
#import "SKPDFView.h"
#import "BDSKCollapsibleView.h"
#import "BDSKEdgeView.h"
#import "BDSKGradientView.h"
#import <SkimNotes/SkimNotes.h>
#import "PDFAnnotation_SKExtensions.h"
#import "SKNPDFAnnotationNote_SKExtensions.h"
#import "SKPDFAnnotationTemporary.h"
#import "SKSplitView.h"
#import "NSScrollView_SKExtensions.h"
#import "NSBezierPath_BDSKExtensions.h"
#import "NSUserDefaultsController_SKExtensions.h"
#import "NSUserDefaults_SKExtensions.h"
#import "SKTocOutlineView.h"
#import "SKNoteOutlineView.h"
#import "SKThumbnailTableView.h"
#import "SKFindTableView.h"
#import "SKAnnotationTypeImageCell.h"
#import "NSWindowController_SKExtensions.h"
#import "SKPDFToolTipWindow.h"
#import "PDFSelection_SKExtensions.h"
#import "SKToolbarItem.h"
#import "NSValue_SKExtensions.h"
#import "NSString_SKExtensions.h"
#import "SKReadingBar.h"
#import "SKLineInspector.h"
#import "SKStatusBar.h"
#import "SKTransitionController.h"
#import "SKTypeSelectHelper.h"
#import "NSGeometry_SKExtensions.h"
#import "SKProgressController.h"
#import "SKSecondaryPDFView.h"
#import "SKSheetController.h"
#import "SKColorSwatch.h"
#import "SKRuntime.h"
#import "SKApplicationController.h"
#import "SKCFCallBacks.h"
#import "NSSegmentedControl_SKExtensions.h"
#import "NSImage_SKExtensions.h"
#import "NSMenu_SKExtensions.h"
#import "SKGroupedSearchResult.h"
#import "SKUnarchiveFromDataArrayTransformer.h"
#import "RemoteControl.h"
#import "NSView_SKExtensions.h"
#import "SKPDFOutline.h"

#define MULTIPLICATION_SIGN_CHARACTER 0x00d7

#define PRESENTATION_SIDE_WINDOW_ALPHA 0.95

NSString *SKMainWindowPageLabelsKey = @"pageLabels";
NSString *SKMainWindowSearchResultsKey = @"searchResults";
NSString *SKMainWindowGroupedSearchResultsKey = @"groupedSearchResults";
NSString *SKMainWindowNotesKey = @"notes";
NSString *SKMainWindowThumbnailsKey = @"thumbnails";
NSString *SKMainWindowSnapshotsKey = @"snapshots";

NSString *SKMainWindowPageColumnIdentifer = @"page";
static NSString *SKMainWindowNoteColumnIdentifer = @"note";

static NSString *SKMainWindowRelevanceColumnIdentifer = @"relevance";
static NSString *SKMainWindowResultsColumnIdentifer = @"results";

static NSString *SKMainWindowPageNumberKey = @"pageNumber";
static NSString *SKMainWindowPageLabelKey = @"pageLabel";

static NSString *SKMainWindowFrameKey = @"windowFrame";
static NSString *SKMainWindowLeftSidePaneWidthKey = @"leftSidePaneWidth";
static NSString *SKMainWindowRightSidePaneWidthKey = @"rightSidePaneWidth";
static NSString *SKMainWindowScaleFactorKey = @"scaleFactor";
static NSString *SKMainWindowAutoScalesKey = @"autoScales";
static NSString *SKMainWindowDisplayPageBreaksKey = @"displaysPageBreaks";
static NSString *SKMainWindowDisplayAsBookKey = @"displaysAsBook"; 
static NSString *SKMainWindowDisplayModeKey = @"displayMode";
static NSString *SKMainWindowDisplayBoxKey = @"displayBox" ;
static NSString *SKMainWindowHasHorizontalScrollerKey = @"hasHorizontalScroller";
static NSString *SKMainWindowHasVerticalScrollerKey = @"hasVerticalScroller";
static NSString *SKMainWindowAutoHidesScrollersKey = @"autoHidesScrollers";
static NSString *SKMainWindowPageIndexKey = @"pageIndex";

static float segmentedControlHeight = 23.0;
static float segmentedControlOffset = 1.0;

static NSString *SKMainWindowFrameAutosaveName = @"SKMainWindow";

static void *SKNPDFAnnotationPropertiesObservationContext = (void *)@"SKNPDFAnnotationPropertiesObservationContext";

static void *SKMainWindowDefaultsObservationContext = (void *)@"SKMainWindowDefaultsObservationContext";

NSString *SKLeftSidePaneWidthKey = @"SKLeftSidePaneWidth";
NSString *SKRightSidePaneWidthKey = @"SKRightSidePaneWidth";

static NSString *SKUsesDrawersKey = @"SKUsesDrawers";
static NSString *SKSplitPDFCopiesZoomKey = @"SKSplitPDFCopiesZoom";
static NSString *SKDisableAnimatedSearchHighlightKey = @"SKDisableAnimatedSearchHighlight";


@interface NSResponder (SKExtensions)
- (BOOL)isDescendantOf:(NSView *)aView;
@end

@implementation NSResponder (SKExtensions)
- (BOOL)isDescendantOf:(NSView *)aView { return NO; }
@end


@interface SKMainWindowController (SKPrivate)

- (void)setupToolbar;

- (void)updatePageLabel;
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

- (void)goToFindResults:(NSArray *)findResults scrollToVisible:(BOOL)scroll;
- (void)goToFindResults:(NSArray *)findResults;
- (void)updateFindResultHighlights:(BOOL)scroll;

- (void)updateNoteFilterPredicate;

- (void)replaceSideView:(NSView *)oldView withView:(NSView *)newView animate:(BOOL)animate;

- (void)goToDestination:(PDFDestination *)destination;
- (void)goToPage:(PDFPage *)page;

- (void)registerForDocumentNotifications;
- (void)unregisterForDocumentNotifications;

- (void)registerAsObserver;
- (void)unregisterAsObserver;

- (void)startObservingNotes:(NSArray *)newNotes;
- (void)stopObservingNotes:(NSArray *)oldNotes;

- (void)observeUndoManagerCheckpoint:(NSNotification *)notification;

@end


@implementation SKMainWindowController

+ (void)initialize {
    OBINITIALIZE;
    
    [NSValueTransformer setValueTransformer:[[[SKUnarchiveFromDataArrayTransformer alloc] init] autorelease] forName:SKUnarchiveFromDataArrayTransformerName];
    
    if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_4) {
        segmentedControlHeight = 25.0;
        segmentedControlOffset = 0.0;
    }

    [PDFPage setUsesSequentialPageNumbering:[[NSUserDefaults standardUserDefaults] boolForKey:SKSequentialPageNumberingKey]];
}

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
    if ([key isEqualToString:SKMainWindowPageNumberKey] || [key isEqualToString:SKMainWindowPageLabelKey])
        return NO;
    else
        return [super automaticallyNotifiesObserversForKey:key];
}

- (id)init {
    if (self = [super initWithWindowNibName:@"MainWindow"]) {
        isPresentation = NO;
        searchResults = [[NSMutableArray alloc] init];
        findPanelFind = NO;
        caseInsensitiveSearch = YES;
        wholeWordSearch = NO;
        groupedSearchResults = [[NSMutableArray alloc] init];
        thumbnails = [[NSMutableArray alloc] init];
        notes = [[NSMutableArray alloc] init];
        snapshots = [[NSMutableArray alloc] init];
        dirtySnapshots = [[NSMutableArray alloc] init];
        pageLabels = [[NSMutableArray alloc] init];
        lastViewedPages = [[NSMutableArray alloc] init];
        rowHeights = CFDictionaryCreateMutable(NULL, 0, &kSKPointerEqualObjectDictionaryKeyCallBacks, &kSKFloatDictionaryValueCallBacks);
        savedNormalSetup = [[NSMutableDictionary alloc] init];
        leftSidePaneState = SKThumbnailSidePaneState;
        rightSidePaneState = SKNoteSidePaneState;
        findPaneState = SKSingularFindPaneState;
        temporaryAnnotations = CFSetCreateMutable(kCFAllocatorDefault, 0, &kCFTypeSetCallBacks);
        pageLabel = nil;
        pageNumber = NSNotFound;
        markedPageIndex = NSNotFound;
        beforeMarkedPageIndex = NSNotFound;
        isAnimating = NO;
        updatingColor = NO;
        updatingFont = NO;
        updatingLine = NO;
        usesDrawers = [[NSUserDefaults standardUserDefaults] boolForKey:SKUsesDrawersKey];
    }
    
    return self;
}

- (void)dealloc {
    [self stopObservingNotes:[self notes]];
    [undoGroupOldPropertiesPerNote release];
    @try { [colorSwatch unbind:SKColorSwatchColorsKey]; }
    @catch (id e) {}
	[[NSNotificationCenter defaultCenter] removeObserver: self];
    [self unregisterAsObserver];
    [(id)temporaryAnnotations release];
    [dirtySnapshots release];
	[searchResults release];
	[groupedSearchResults release];
    [pdfOutline release];
	[thumbnails release];
	[notes release];
	[snapshots release];
    [pageLabels release];
    [pageLabel release];
	CFRelease(rowHeights);
    [lastViewedPages release];
	[leftSideWindow release];
	[rightSideWindow release];
	[fullScreenWindow release];
    [mainWindow release];
    [statusBar release];
    [toolbarItems release];
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
    BOOL hasWindowSetup = [savedNormalSetup count] > 0;
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
    
    if (usesDrawers == NO || floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_4) {
        [leftSideButton makeTexturedRounded];
        [rightSideButton makeTexturedRounded];
        [findButton makeTexturedRounded];
    }
    
    [leftSideButton setToolTip:NSLocalizedString(@"View Thumbnails", @"Tool tip message") forSegment:SKThumbnailSidePaneState];
    [leftSideButton setToolTip:NSLocalizedString(@"View Table of Contents", @"Tool tip message") forSegment:SKOutlineSidePaneState];
    [rightSideButton setToolTip:NSLocalizedString(@"View Notes", @"Tool tip message") forSegment:SKNoteSidePaneState];
    [rightSideButton setToolTip:NSLocalizedString(@"View Snapshots", @"Tool tip message") forSegment:SKSnapshotSidePaneState];
    [findButton setToolTip:NSLocalizedString(@"Separate search results", @"Tool tip message") forSegment:SKSingularFindPaneState];
    [findButton setToolTip:NSLocalizedString(@"Group search results by page", @"Tool tip message") forSegment:SKGroupedFindPaneState];
    
    // This gets sometimes messed up in the nib, AppKit bug rdar://5346690
    [leftSideContentView setAutoresizesSubviews:YES];
    [rightSideContentView setAutoresizesSubviews:YES];
    
    [leftSideView setFrame:[leftSideContentView bounds]];
    [leftSideContentView addSubview:leftSideView];
    [rightSideView setFrame:[rightSideContentView bounds]];
    [rightSideContentView addSubview:rightSideView];
    
    NSMenu *menu = [[[NSMenu allocWithZone:[NSMenu menuZone]] init] autorelease];
    [menu addItemWithTitle:NSLocalizedString(@"Whole Words Only", @"Menu item title") action:@selector(toggleWholeWordSearch:) target:self];
    [menu addItemWithTitle:NSLocalizedString(@"Ignore Case", @"Menu item title") action:@selector(toggleCaseInsensitiveSearch:) target:self];
    [[searchField cell] setSearchMenuTemplate:menu];
    [[searchField cell] setPlaceholderString:NSLocalizedString(@"Search", @"placeholder")];
    [[noteSearchField cell] setPlaceholderString:NSLocalizedString(@"Search", @"placeholder")];
    
    [[[noteOutlineView tableColumnWithIdentifier:SKMainWindowNoteColumnIdentifer] headerCell] setTitle:NSLocalizedString(@"Note", @"Table header title")];
    [[[noteOutlineView tableColumnWithIdentifier:SKMainWindowPageColumnIdentifer] headerCell] setTitle:NSLocalizedString(@"Page", @"Table header title")];
    [[[findTableView tableColumnWithIdentifier:SKMainWindowPageColumnIdentifer] headerCell] setTitle:NSLocalizedString(@"Page", @"Table header title")];
    [[[groupedFindTableView tableColumnWithIdentifier:SKMainWindowPageColumnIdentifer] headerCell] setTitle:NSLocalizedString(@"Page", @"Table header title")];
    
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
    [noteOutlineView setAutoresizesOutlineColumn: NO];
    [self displayThumbnailView];
    [self displayNoteView];
    
    // Set up the tool bar
    [self setupToolbar];
    
    // Set up the window
    // we retain as we might replace it with the full screen window
    mainWindow = [[self window] retain];
    
    [self setWindowFrameAutosaveNameOrCascade:SKMainWindowFrameAutosaveName];
    
    [[self window] setBackgroundColor:[NSColor colorWithCalibratedWhite:0.9 alpha:1.0]];
    
    if ([sud boolForKey:SKShowStatusBarKey])
        [self toggleStatusBar:nil];
    
    int windowSizeOption = [sud integerForKey:SKInitialWindowSizeOptionKey];
    if (hasWindowSetup) {
        NSString *rectString = [savedNormalSetup objectForKey:SKMainWindowFrameKey];
        if (rectString)
            [[self window] setFrame:NSRectFromString(rectString) display:NO];
    } else if (windowSizeOption == SKMaximizeWindowOption) {
        [[self window] setFrame:[[NSScreen mainScreen] visibleFrame] display:NO];
    }
    
    // Set up the PDF
    [self applyPDFSettings:hasWindowSetup ? savedNormalSetup : [sud dictionaryForKey:SKDefaultPDFDisplaySettingsKey]];
    
    [pdfView setShouldAntiAlias:[sud boolForKey:SKShouldAntiAliasKey]];
    [pdfView setGreekingThreshold:[sud floatForKey:SKGreekingThresholdKey]];
    [pdfView setBackgroundColor:[sud colorForKey:SKBackgroundColorKey]];
    
    [pdfView setDelegate:self];
    
    NSNumber *leftWidth = [savedNormalSetup objectForKey:SKMainWindowLeftSidePaneWidthKey] ?: [sud objectForKey:SKLeftSidePaneWidthKey];
    NSNumber *rightWidth = [savedNormalSetup objectForKey:SKMainWindowRightSidePaneWidthKey] ?: [sud objectForKey:SKRightSidePaneWidthKey];
    
    if (leftWidth && rightWidth) {
        float width = [leftWidth floatValue];
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
        width = [rightWidth floatValue];
        if (width >= 0.0) {
            frame = [rightSideContentView frame];
            frame.size.width = width;
            if (usesDrawers == NO) {
                frame.origin.x = NSMaxX([splitView bounds]) - width;
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
    NSSortDescriptor *pageIndexSortDescriptor = [[[NSSortDescriptor alloc] initWithKey:SKNPDFAnnotationPageIndexKey ascending:YES] autorelease];
    NSSortDescriptor *boundsSortDescriptor = [[[NSSortDescriptor alloc] initWithKey:SKNPDFAnnotationBoundsKey ascending:YES selector:@selector(boundsCompare:)] autorelease];
    [noteArrayController setSortDescriptors:[NSArray arrayWithObjects:pageIndexSortDescriptor, boundsSortDescriptor, nil]];
    [snapshotArrayController setSortDescriptors:[NSArray arrayWithObjects:pageIndexSortDescriptor, nil]];
    [ownerController setContent:self];
    
    NSSortDescriptor *countDescriptor = [[[NSSortDescriptor alloc] initWithKey:SKGroupedSearchResultCountKey ascending:NO] autorelease];
    [groupedFindArrayController setSortDescriptors:[NSArray arrayWithObjects:countDescriptor, nil]];
    [[[groupedFindTableView tableColumnWithIdentifier:SKMainWindowRelevanceColumnIdentifer] dataCell] setEnabled:NO];
        
    // NB: the next line will load the PDF document and annotations, so necessary setup must be finished first!
    // windowControllerDidLoadNib: is not called automatically because the document overrides makeWindowControllers
    [[self document] windowControllerDidLoadNib:self];
    
    // Show/hide left side pane if necessary
    if ([sud boolForKey:SKOpenContentsPaneOnlyForTOCKey] && [self leftSidePaneIsOpen] == (pdfOutline == nil))
        [self toggleLeftSidePane:self];
    if (pdfOutline)
        [self setLeftSidePaneState:SKOutlineSidePaneState];
    else
        [leftSideButton setEnabled:NO forSegment:SKOutlineSidePaneState];
    
    // Due to a bug in Leopard we should only resize and swap in the PDFView after loading the PDFDocument
    [pdfView setFrame:[[pdfEdgeView contentView] bounds]];
    [pdfEdgeView addSubview:pdfView];
    
    [[self window] makeFirstResponder:[pdfView documentView]];
    
    // Go to page?
    unsigned int pageIndex = NSNotFound;
    if (hasWindowSetup)
        pageIndex = [[savedNormalSetup objectForKey:SKMainWindowPageIndexKey] unsignedIntValue];
    else if ([sud boolForKey:SKRememberLastPageViewedKey])
        pageIndex = [[SKBookmarkController sharedBookmarkController] pageIndexForRecentDocumentAtPath:[[[self document] fileURL] path]];
    if (pageIndex != NSNotFound && [[pdfView document] pageCount] > pageIndex)
        [pdfView goToPage:[[pdfView document] pageAtIndex:pageIndex]];
    
    // We can fit only after the PDF has been loaded
    if (windowSizeOption == SKFitWindowOption && hasWindowSetup == NO)
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
    [self handleDisplayBoxChangedNotification:nil];
    [self handleDisplayModeChangedNotification:nil];
    [self handleAnnotationModeChangedNotification:nil];
    
    // Observe notifications and KVO
    [self registerForNotifications];
    [self registerAsObserver];
    
    if (hasWindowSetup)
        [savedNormalSetup removeAllObjects];
    
    settingUpWindow = NO;
}

- (void)setInitialSetup:(NSDictionary *)setup{
    if ([self isWindowLoaded] == NO)
        [savedNormalSetup setDictionary:setup];
    else
        NSLog(@"-[NSMainWindowController setupWindow:] called after window was loaded");
}

- (NSDictionary *)currentSetup {
    NSMutableDictionary *setup = [NSMutableDictionary dictionary];
    
    [setup setObject:NSStringFromRect([mainWindow frame]) forKey:SKMainWindowFrameKey];
    [setup setObject:[NSNumber numberWithFloat:[self leftSidePaneIsOpen] ? NSWidth([leftSideContentView frame]) : 0.0] forKey:SKMainWindowLeftSidePaneWidthKey];
    [setup setObject:[NSNumber numberWithFloat:[self rightSidePaneIsOpen] ? NSWidth([rightSideContentView frame]) : 0.0] forKey:SKMainWindowRightSidePaneWidthKey];
    [setup setObject:[NSNumber numberWithUnsignedInt:[[pdfView currentPage] pageIndex]] forKey:SKMainWindowPageIndexKey];
    if ([self isFullScreen] || [self isPresentation]) {
        [setup addEntriesFromDictionary:savedNormalSetup];
        [setup removeObjectsForKeys:[NSArray arrayWithObjects:SKMainWindowHasHorizontalScrollerKey, SKMainWindowHasVerticalScrollerKey, SKMainWindowAutoHidesScrollersKey, nil]];
    } else {
        [setup addEntriesFromDictionary:[self currentPDFSettings]];
    }
    
    return setup;
}

- (void)applyPDFSettings:(NSDictionary *)setup {
    NSNumber *number;
    if (number = [setup objectForKey:SKMainWindowScaleFactorKey])
        [pdfView setScaleFactor:[number floatValue]];
    if (number = [setup objectForKey:SKMainWindowAutoScalesKey])
        [pdfView setAutoScales:[number boolValue]];
    if (number = [setup objectForKey:SKMainWindowDisplayPageBreaksKey])
        [pdfView setDisplaysPageBreaks:[number boolValue]];
    if (number = [setup objectForKey:SKMainWindowDisplayAsBookKey])
        [pdfView setDisplaysAsBook:[number boolValue]];
    if (number = [setup objectForKey:SKMainWindowDisplayModeKey])
        [pdfView setDisplayMode:[number intValue]];
    if (number = [setup objectForKey:SKMainWindowDisplayBoxKey])
        [pdfView setDisplayBox:[number intValue]];
}

- (NSDictionary *)currentPDFSettings {
    NSMutableDictionary *setup = [NSMutableDictionary dictionary];
    
    if ([self isPresentation]) {
        [setup setDictionary:savedNormalSetup];
        [setup removeObjectsForKeys:[NSArray arrayWithObjects:SKMainWindowHasHorizontalScrollerKey, SKMainWindowHasVerticalScrollerKey, SKMainWindowAutoHidesScrollersKey, nil]];
    } else {
        [setup setObject:[NSNumber numberWithBool:[pdfView displaysPageBreaks]] forKey:SKMainWindowDisplayPageBreaksKey];
        [setup setObject:[NSNumber numberWithBool:[pdfView displaysAsBook]] forKey:SKMainWindowDisplayAsBookKey];
        [setup setObject:[NSNumber numberWithInt:[pdfView displayBox]] forKey:SKMainWindowDisplayBoxKey];
        [setup setObject:[NSNumber numberWithFloat:[pdfView scaleFactor]] forKey:SKMainWindowScaleFactorKey];
        [setup setObject:[NSNumber numberWithBool:[pdfView autoScales]] forKey:SKMainWindowAutoScalesKey];
        [setup setObject:[NSNumber numberWithInt:[pdfView displayMode]] forKey:SKMainWindowDisplayModeKey];
    }
    
    return setup;
}

#pragma mark UI updating

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
            message = [NSString stringWithFormat:@"%.2f %C", magnification, MULTIPLICATION_SIGN_CHARACTER];
        else
           message = @"";
    } else {
        if ([statusBar rightState] == NSOnState) {
            BOOL useMetric = [[[NSLocale currentLocale] objectForKey:NSLocaleUsesMetricSystem] boolValue];
            NSString *units = useMetric ? @"cm" : @"in";
            float factor = useMetric ? 0.035277778 : 0.013888889;
            message = [NSString stringWithFormat:@"%.2f %C %.2f @ (%.2f, %.2f) %@", NSWidth(selRect) * factor, MULTIPLICATION_SIGN_CHARACTER, NSHeight(selRect) * factor, NSMinX(selRect) * factor, NSMinY(selRect) * factor, units];
        } else {
            message = [NSString stringWithFormat:@"%i %C %i @ (%i, %i) pt", (int)NSWidth(selRect), MULTIPLICATION_SIGN_CHARACTER, (int)NSHeight(selRect), (int)NSMinX(selRect), (int)NSMinY(selRect)];
        }
    }
    [statusBar setRightStringValue:message];
}

- (void)updatePageColumnWidthForTableView:(NSTableView *)tv {
    NSTableColumn *tableColumn = [tv tableColumnWithIdentifier:SKMainWindowPageColumnIdentifer];
    id cell = [tableColumn dataCell];
    float labelWidth = 0.0;
    NSEnumerator *labelEnum = [pageLabels objectEnumerator];
    NSString *label;
    
    while (label = [labelEnum nextObject]) {
        [cell setStringValue:label];
        labelWidth = fmaxf(labelWidth, [cell cellSize].width);
    }
    
    [tableColumn setMinWidth:labelWidth];
    [tableColumn setMaxWidth:labelWidth];
    [tableColumn setWidth:labelWidth];
    [tv sizeToFit];
}

- (void)updatePageLabelsAndOutline {
    PDFDocument *pdfDoc = [pdfView document];
    unsigned int i, count = [pdfDoc pageCount];
    
    // update page labels, also update the size of the table columns displaying the labels
    [self willChangeValueForKey:SKMainWindowPageLabelsKey];
    [pageLabels removeAllObjects];
    for (i = 0; i < count; i++)
        [pageLabels addObject:[[pdfDoc pageAtIndex:i] displayLabel]];
    [self didChangeValueForKey:SKMainWindowPageLabelsKey];
    
    [self updatePageLabel];
    
    [self updatePageColumnWidthForTableView:thumbnailTableView];
    [self updatePageColumnWidthForTableView:snapshotTableView];
    [self updatePageColumnWidthForTableView:outlineView];
    
    // this uses the pageLabels
    [[thumbnailTableView typeSelectHelper] rebuildTypeSelectSearchCache];
    
    // these carry a label, moreover when this is called the thumbnails will also be invalid
    [self resetThumbnails];
    [self allSnapshotsNeedUpdate];
    [noteOutlineView reloadData];
    
    // update the outline
    [pdfOutline release];
    pdfOutline = [[SKPDFOutline alloc] initWithOutline:[pdfDoc outlineRoot] parent:nil];
    
    updatingOutlineSelection = YES;
    // If this is a reload following a TeX run and the user just killed the outline for some reason, we get a crash if the outlineView isn't reloaded, so no longer make it conditional on pdfOutline != nil
    [outlineView reloadData];
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
            [pdfView removePDFToolTipRects];
            [pdfView setActiveAnnotation:nil];
            
            // these will be invalid. If needed, the document will restore them
            [self setSearchResults:nil];
            [self setGroupedSearchResults:nil];
            [self removeAllObjectsFromNotes];
            [self removeAllObjectsFromThumbnails];
            
            snapshotDicts = [snapshots valueForKey:SKSnapshotCurrentSetupKey];
            [snapshots makeObjectsPerformSelector:@selector(close)];
            [self removeAllObjectsFromSnapshots];
            
            [pdfOutline release];
            pdfOutline = nil;
            
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
        [self synchronizeWindowTitleWithDocumentName];
        [self updateLeftStatus];
        [self updateRightStatus];
    }
}
    
- (void)addAnnotationsFromDictionaries:(NSArray *)noteDicts undoable:(BOOL)undoable{
    NSEnumerator *e = [noteDicts objectEnumerator];
    PDFAnnotation *annotation;
    NSDictionary *dict;
    PDFDocument *pdfDoc = [pdfView document];
    NSMutableArray *observedNotes = [self mutableArrayValueForKey:SKMainWindowNotesKey];
    
    // create new annotations from the dictionary and add them to their page and to the document
    while (dict = [e nextObject]) {
        unsigned pageIndex = [[dict objectForKey:SKNPDFAnnotationPageIndexKey] unsignedIntValue];
        if (annotation = [[PDFAnnotation alloc] initSkimNoteWithProperties:dict]) {
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
    // make sure we clear the undo handling
    [self observeUndoManagerCheckpoint:nil];
    [noteOutlineView reloadData];
    [self allThumbnailsNeedUpdate];
    [pdfView resetPDFToolTipRects];
}

- (void)setAnnotationsFromDictionaries:(NSArray *)noteDicts undoable:(BOOL)undoable{
    NSEnumerator *e = [[[notes copy] autorelease] objectEnumerator];
    PDFAnnotation *annotation;
    
    [pdfView removePDFToolTipRects];
    
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
        [self removeAllObjectsFromNotes];
    
    [self addAnnotationsFromDictionaries:noteDicts undoable:undoable];
}

- (SKPDFView *)pdfView {
    return pdfView;
}

- (void)updatePageNumber {
    unsigned int number = [[pdfView currentPage] pageIndex] + 1;
    if (pageNumber != number) {
        [self willChangeValueForKey:SKMainWindowPageNumberKey];
        pageNumber = number;
        [self didChangeValueForKey:SKMainWindowPageNumberKey];
    }
}

- (unsigned int)pageNumber {
    return pageNumber;
}

- (void)setPageNumber:(unsigned int)number {
    // Check that the page number exists
    unsigned int pageCount = [[pdfView document] pageCount];
    if (number > pageCount)
        number = pageCount;
    if (number > 0 && [[pdfView currentPage] pageIndex] != number - 1)
        [self goToPage:[[pdfView document] pageAtIndex:number - 1]];
}

- (void)updatePageLabel {
    NSString *label = [[pdfView currentPage] displayLabel];
    if (label != pageLabel) {
        [self willChangeValueForKey:SKMainWindowPageLabelKey];
        [pageLabel release];
        pageLabel = [label retain];
        [self didChangeValueForKey:SKMainWindowPageLabelKey];
    }
}

- (NSString *)pageLabel {
    return pageLabel;
}

- (void)setPageLabel:(NSString *)label {
    unsigned int idx = [pageLabels indexOfObject:label];
    if (idx != NSNotFound && [[[pdfView currentPage] displayLabel] isEqual:label] == NO)
        [self goToPage:[[pdfView document] pageAtIndex:idx]];
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

- (SKFindPaneState)findPaneState {
    return findPaneState;
}

- (void)setFindPaneState:(SKFindPaneState)newFindPaneState {
    if (findPaneState != newFindPaneState) {
        findPaneState = newFindPaneState;
        
        if (findPaneState == SKSingularFindPaneState) {
            if ([groupedFindView window])
                [self displaySearchView];
        } else if (findPaneState == SKGroupedFindPaneState) {
            if ([findView window])
                [self displayGroupedSearchView];
        }
        [self updateFindResultHighlights:YES];
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

- (void)closeSideWindow:(SKSideWindow *)sideWindow {    
    if ([sideWindow state] == NSDrawerOpenState || [sideWindow state] == NSDrawerOpeningState) {
        if (sideWindow == leftSideWindow) {
            [self toggleLeftSidePane:self];
        } else if (sideWindow == rightSideWindow) {
            [self toggleRightSidePane:self];
        }
    }
}

- (NSArray *)notes {
    return [[notes copy] autorelease];
}
	 
- (unsigned int)countOfNotes {
    return [notes count];
}

- (PDFAnnotation *)objectInNotesAtIndex:(unsigned int)theIndex {
    return [notes objectAtIndex:theIndex];
}

- (void)insertObject:(PDFAnnotation *)note inNotesAtIndex:(unsigned int)theIndex {
    [notes insertObject:note atIndex:theIndex];

    // Start observing the just-inserted notes so that, when they're changed, we can record undo operations.
    [self startObservingNotes:[NSArray arrayWithObject:note]];
}

- (void)removeObjectFromNotesAtIndex:(unsigned int)theIndex {
    PDFAnnotation *note = [notes objectAtIndex:theIndex];
    NSEnumerator *wcEnum = [[[self document] windowControllers] objectEnumerator];
    NSWindowController *wc = [wcEnum nextObject];
    
    while (wc = [wcEnum nextObject]) {
        if ([wc isNoteWindowController] && [[(SKNoteWindowController *)wc note] isEqual:note]) {
            [[wc window] orderOut:self];
            break;
        }
    }
    
    if ([[note texts] count])
        CFDictionaryRemoveValue(rowHeights, (const void *)[[note texts] lastObject]);
    CFDictionaryRemoveValue(rowHeights, (const void *)note);
    
    // Stop observing the removed notes
    [self stopObservingNotes:[NSArray arrayWithObject:note]];
    
    [notes removeObjectAtIndex:theIndex];
}

- (void)removeAllObjectsFromNotes {
    if ([notes count]) {
        NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [notes count])];
        [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:SKMainWindowNotesKey];
        
        NSEnumerator *wcEnum = [[[self document] windowControllers] objectEnumerator];
        NSWindowController *wc = [wcEnum nextObject];
        while (wc = [wcEnum nextObject]) {
            if ([wc isNoteWindowController])
                [[wc window] orderOut:self];
        }
        
        CFDictionaryRemoveAllValues(rowHeights);
        
        [self stopObservingNotes:notes];

        [notes removeAllObjects];
        
        [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:SKMainWindowNotesKey];
        [noteOutlineView reloadData];
    }
}

- (unsigned int)countOfThumbnails {
    return [thumbnails count];
}

- (SKThumbnail *)objectInThumbnailsAtIndex:(unsigned int)theIndex {
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

- (void)insertObject:(SKThumbnail *)thumbnail inThumbnailsAtIndex:(unsigned int)theIndex {
    [thumbnails insertObject:thumbnail atIndex:theIndex];
}

- (void)removeObjectFromThumbnailsAtIndex:(unsigned int)theIndex {
    [thumbnails removeObjectAtIndex:theIndex];
}

- (void)removeAllObjectsFromThumbnails {
    if ([thumbnails count]) {
        NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [thumbnails count])];
        [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:SKMainWindowThumbnailsKey];
        [thumbnails removeAllObjects];
        [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:SKMainWindowThumbnailsKey];
    }
}

- (NSArray *)snapshots {
    return [[snapshots copy] autorelease];
}

- (unsigned int)countOfSnapshots {
    return [snapshots count];
}

- (SKSnapshotWindowController *)objectInSnapshotsAtIndex:(unsigned int)theIndex {
    return [snapshots objectAtIndex:theIndex];
}

- (void)insertObject:(SKSnapshotWindowController *)snapshot inSnapshotsAtIndex:(unsigned int)theIndex {
    [snapshots insertObject:snapshot atIndex:theIndex];
}

- (void)removeObjectFromSnapshotsAtIndex:(unsigned int)theIndex {
    [dirtySnapshots removeObject:[snapshots objectAtIndex:theIndex]];
    [snapshots removeObjectAtIndex:theIndex];
}

- (void)removeAllObjectsFromSnapshots {
    if ([snapshots count]) {
        NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [snapshots count])];
        [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:SKMainWindowSnapshotsKey];
        
        [dirtySnapshots removeAllObjects];
        
        [snapshots removeAllObjects];
        
        [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:SKMainWindowSnapshotsKey];
    }
}

- (NSArray *)selectedNotes {
    NSMutableArray *selectedNotes = [NSMutableArray array];
    NSIndexSet *rowIndexes = [noteOutlineView selectedRowIndexes];
    unsigned int row = [rowIndexes firstIndex];
    id item = nil;
    while (row != NSNotFound) {
        item = [noteOutlineView itemAtRow:row];
        if ([item type] == nil)
            item = [(SKNoteText *)item annotation];
        if ([selectedNotes containsObject:item] == NO)
            [selectedNotes addObject:item];
        row = [rowIndexes indexGreaterThanIndex:row];
    }
    return selectedNotes;
}

- (NSArray *)searchResults {
    return [[searchResults copy] autorelease];
}

- (void)setSearchResults:(NSArray *)newSearchResults {
    [searchResults setArray:newSearchResults];
}

- (unsigned int)countOfSearchResults {
    return [searchResults count];
}

- (PDFSelection *)objectInSearchResultsAtIndex:(unsigned int)theIndex {
    return [searchResults objectAtIndex:theIndex];
}

- (void)insertObject:(PDFSelection *)searchResult inSearchResultsAtIndex:(unsigned int)theIndex {
    [searchResults insertObject:searchResult atIndex:theIndex];
}

- (void)removeObjectFromSearchResultsAtIndex:(unsigned int)theIndex {
    [searchResults removeObjectAtIndex:theIndex];
}

- (NSArray *)groupedSearchResults {
    return [[groupedSearchResults copy] autorelease];
}

- (void)setGroupedSearchResults:(NSArray *)newGroupedSearchResults {
    [groupedSearchResults setArray:newGroupedSearchResults];
}

- (unsigned int)countOfGroupedSearchResults {
    return [groupedSearchResults count];
}

- (SKGroupedSearchResult *)objectInGroupedSearchResultsAtIndex:(unsigned int)theIndex {
    return [groupedSearchResults objectAtIndex:theIndex];
}

- (void)insertObject:(SKGroupedSearchResult *)groupedSearchResult inGroupedSearchResultsAtIndex:(unsigned int)theIndex {
    [groupedSearchResults insertObject:groupedSearchResult atIndex:theIndex];
}

- (void)removeObjectFromGroupedSearchResultsAtIndex:(unsigned int)theIndex {
    [groupedSearchResults removeObjectAtIndex:theIndex];
}

#pragma mark Actions

- (IBAction)changeColor:(id)sender{
    PDFAnnotation *annotation = [pdfView activeAnnotation];
    if (updatingColor == NO && [annotation isSkimNote]) {
        BOOL isFill = [colorAccessoryView state] == NSOnState && [annotation respondsToSelector:@selector(setInteriorColor:)];
        NSColor *color = (isFill ? [(id)annotation interiorColor] : [annotation color]) ?: [NSColor clearColor];
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

- (IBAction)selectColor:(id)sender{
    PDFAnnotation *annotation = [pdfView activeAnnotation];
    if ([annotation isSkimNote]) {
        NSColor *color = [annotation color];
        NSColor *newColor = [sender respondsToSelector:@selector(representedObject)] ? [sender representedObject] : [sender respondsToSelector:@selector(color)] ? [sender color] : nil;
        if (newColor && [color isEqual:newColor] == NO)
            [annotation setColor:newColor];
    }
}

- (IBAction)changeFont:(id)sender{
    PDFAnnotation *annotation = [pdfView activeAnnotation];
    if (updatingFont == NO && [annotation isSkimNote] && [annotation respondsToSelector:@selector(setFont:)] && [annotation respondsToSelector:@selector(font)]) {
        NSFont *font = [sender convertFont:[(PDFAnnotationFreeText *)annotation font]];
        updatingFont = YES;
        [(PDFAnnotationFreeText *)annotation setFont:font];
        updatingFont = NO;
    }
}

- (IBAction)changeAttributes:(id)sender{
    PDFAnnotation *annotation = [pdfView activeAnnotation];
    if (updatingFontAttributes == NO && [annotation isSkimNote] && [annotation respondsToSelector:@selector(setFontColor:)] && [annotation respondsToSelector:@selector(fontColor)]) {
        NSColor *color = [(PDFAnnotationFreeText *)annotation fontColor];
        NSColor *newColor = [[sender convertAttributes:[NSDictionary dictionaryWithObjectsAndKeys:color, NSForegroundColorAttributeName, nil]] valueForKey:NSForegroundColorAttributeName];
        if ([newColor isEqual:color] == NO) {
            updatingFontAttributes = YES;
            [(PDFAnnotationFreeText *)annotation setFontColor:newColor];
            updatingFontAttributes = NO;
        }
    }
}

- (void)changeLineWidth:(id)sender {
    PDFAnnotation *annotation = [pdfView activeAnnotation];
    NSString *type = [annotation type];
    if (updatingLine == NO && [annotation isSkimNote] && ([type isEqualToString:SKNFreeTextString] || [type isEqualToString:SKNCircleString] || [type isEqualToString:SKNSquareString] || [type isEqualToString:@""] || [type isEqualToString:SKNLineString])) {
        [annotation setLineWidth:[sender lineWidth]];
    }
}

- (void)changeLineStyle:(id)sender {
    PDFAnnotation *annotation = [pdfView activeAnnotation];
    NSString *type = [annotation type];
    if (updatingLine == NO && [annotation isSkimNote] && ([type isEqualToString:SKNFreeTextString] || [type isEqualToString:SKNCircleString] || [type isEqualToString:SKNSquareString] || [type isEqualToString:SKNLineString])) {
        [annotation setBorderStyle:[sender style]];
    }
}

- (void)changeDashPattern:(id)sender {
    PDFAnnotation *annotation = [pdfView activeAnnotation];
    NSString *type = [annotation type];
    if (updatingLine == NO && [annotation isSkimNote] && ([type isEqualToString:SKNFreeTextString] || [type isEqualToString:SKNCircleString] || [type isEqualToString:SKNSquareString] || [type isEqualToString:SKNLineString])) {
        [annotation setDashPattern:[sender dashPattern]];
    }
}

- (void)changeStartLineStyle:(id)sender {
    PDFAnnotation *annotation = [pdfView activeAnnotation];
    NSString *type = [annotation type];
    if (updatingLine == NO && [annotation isSkimNote] && [type isEqualToString:SKNLineString]) {
        updatingLine = YES;
        [(PDFAnnotationLine *)annotation setStartLineStyle:[sender startLineStyle]];
        updatingLine = NO;
    }
}

- (void)changeEndLineStyle:(id)sender {
    PDFAnnotation *annotation = [pdfView activeAnnotation];
    NSString *type = [annotation type];
    if (updatingLine == NO && [annotation isSkimNote] && [type isEqualToString:SKNLineString]) {
        updatingLine = YES;
        [(PDFAnnotationLine *)annotation setEndLineStyle:[sender endLineStyle]];
        updatingLine = NO;
    }
}

- (IBAction)createNewNote:(id)sender{
    if ([pdfView hideNotes] == NO) {
        int type = [sender respondsToSelector:@selector(selectedSegment)] ? [sender selectedSegment] : [sender tag];
        [pdfView addAnnotationWithType:type];
    } else NSBeep();
}

- (IBAction)createNewTextNote:(id)sender{
    if ([pdfView hideNotes] == NO) {
        BOOL isButtonClick = [sender respondsToSelector:@selector(selectedSegment)];
        int type = [sender tag];
        [pdfView addAnnotationWithType:type];
        if (isButtonClick == NO && type != [textNoteButton tag]) {
            [textNoteButton setTag:type];
            NSString *imgName = type == SKFreeTextNote ? SKImageNameToolbarAddTextNoteMenu : SKImageNameToolbarAddAnchoredNoteMenu;
            [textNoteButton setImage:[NSImage imageNamed:imgName] forSegment:0];
        }
    } else NSBeep();
}

- (IBAction)createNewCircleNote:(id)sender{
    if ([pdfView hideNotes] == NO) {
        BOOL isButtonClick = [sender respondsToSelector:@selector(selectedSegment)];
        int type = [sender tag];
        [pdfView addAnnotationWithType:type];
        if (isButtonClick == NO && type != [circleNoteButton tag]) {
            [circleNoteButton setTag:type];
            NSString *imgName = type == SKCircleNote ? SKImageNameToolbarAddCircleNoteMenu : SKImageNameToolbarAddSquareNoteMenu;
            [circleNoteButton setImage:[NSImage imageNamed:imgName] forSegment:0];
        }
    } else NSBeep();
}

- (IBAction)createNewMarkupNote:(id)sender{
    if ([pdfView hideNotes] == NO) {
        BOOL isButtonClick = [sender respondsToSelector:@selector(selectedSegment)];
        int type = [sender tag];
        [pdfView addAnnotationWithType:type];
        if (isButtonClick == NO && type != [markupNoteButton tag]) {
            [markupNoteButton setTag:type];
            NSString *imgName = type == SKHighlightNote ? SKImageNameToolbarAddHighlightNoteMenu : SKUnderlineNote ? SKImageNameToolbarAddUnderlineNoteMenu : SKImageNameToolbarAddStrikeOutNoteMenu;
            [markupNoteButton setImage:[NSImage imageNamed:imgName] forSegment:0];
        }
    } else NSBeep();
}

- (IBAction)createNewLineNote:(id)sender{
    if ([pdfView hideNotes] == NO) {
        [pdfView addAnnotationWithType:SKLineNote];
    } else NSBeep();
}

- (IBAction)editNote:(id)sender{
    if ([pdfView hideNotes] == NO) {
        [pdfView editActiveAnnotation:sender];
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

- (IBAction)changeDisplaySinglePages:(id)sender {
    PDFDisplayMode tag = [sender tag];
    if ([sender respondsToSelector:@selector(selectedTag)])
        tag = [sender selectedTag];
    PDFDisplayMode displayMode = [pdfView displayMode];
    if (displayMode == kPDFDisplaySinglePage && tag == kPDFDisplayTwoUp) 
        [pdfView setDisplayMode:kPDFDisplayTwoUp];
    else if (displayMode == kPDFDisplaySinglePageContinuous && tag == kPDFDisplayTwoUp)
        [pdfView setDisplayMode:kPDFDisplayTwoUpContinuous];
    else if (displayMode == kPDFDisplayTwoUp && tag == kPDFDisplaySinglePage)
        [pdfView setDisplayMode:kPDFDisplaySinglePage];
    else if (displayMode == kPDFDisplayTwoUpContinuous && tag == kPDFDisplaySinglePage)
        [pdfView setDisplayMode:kPDFDisplaySinglePageContinuous];
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

- (IBAction)changeDisplayContinuous:(id)sender {
    PDFDisplayMode tag = [sender tag];
    if ([sender respondsToSelector:@selector(selectedTag)])
        tag = [sender selectedTag];
    PDFDisplayMode displayMode = [pdfView displayMode];
    if (displayMode == kPDFDisplaySinglePage && tag == kPDFDisplaySinglePageContinuous)
        [pdfView setDisplayMode:kPDFDisplaySinglePageContinuous];
    else if (displayMode == kPDFDisplaySinglePageContinuous && tag == kPDFDisplaySinglePage)
        [pdfView setDisplayMode:kPDFDisplaySinglePage];
    else if (displayMode == kPDFDisplayTwoUp && tag == kPDFDisplaySinglePageContinuous)
        [pdfView setDisplayMode:kPDFDisplayTwoUpContinuous];
    else if (displayMode == kPDFDisplayTwoUpContinuous && tag == kPDFDisplaySinglePage)
        [pdfView setDisplayMode:kPDFDisplayTwoUp];
}

- (IBAction)changeDisplayMode:(id)sender {
    PDFDisplayMode displayMode = [sender tag];
    if ([sender respondsToSelector:@selector(selectedTag)])
        displayMode = [sender selectedTag];
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
    else if ([sender respondsToSelector:@selector(selectedSegment)])
        displayBox = [sender selectedSegment];
    [pdfView setDisplayBox:displayBox];
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

- (IBAction)allGoToNextPage:(id)sender {
    [[NSApp valueForKeyPath:@"orderedDocuments.pdfView"] makeObjectsPerformSelector:@selector(goToNextPage:) withObject:sender];
}

- (IBAction)allGoToPreviousPage:(id)sender {
    [[NSApp valueForKeyPath:@"orderedDocuments.pdfView"] makeObjectsPerformSelector:@selector(goToPreviousPage:) withObject:sender];
}

- (IBAction)allGoToFirstPage:(id)sender {
    [[NSApp valueForKeyPath:@"orderedDocuments.pdfView"] makeObjectsPerformSelector:@selector(goToFirstPage:) withObject:sender];
}

- (IBAction)allGoToLastPage:(id)sender {
    [[NSApp valueForKeyPath:@"orderedDocuments.pdfView"] makeObjectsPerformSelector:@selector(goToLastPage:) withObject:sender];
}

- (IBAction)goToPreviousNextFirstLastPage:(id)sender {
    int tag = [sender selectedTag];
    if (tag == -1)
        [pdfView goToPreviousPage:sender];
    else if (tag == 1)
        [pdfView goToNextPage:sender];
    else if (tag == -2)
        [pdfView goToFirstPage:sender];
    else if (tag == 2)
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

- (IBAction)goToMarkedPage:(id)sender {
    PDFDocument *pdfDoc = [pdfView document];
    unsigned int currentPageIndex = [[pdfView currentPage] pageIndex];
    if (markedPageIndex == NSNotFound || [pdfDoc isLocked] || [pdfDoc pageCount] == 0) {
        NSBeep();
    } else if (beforeMarkedPageIndex != NSNotFound) {
        [self goToPage:[pdfDoc pageAtIndex:MIN(beforeMarkedPageIndex, [pdfDoc pageCount] - 1)]];
    } else if (currentPageIndex != markedPageIndex) {
        beforeMarkedPageIndex = currentPageIndex;
        [self goToPage:[pdfDoc pageAtIndex:MIN(markedPageIndex, [pdfDoc pageCount] - 1)]];
    }
}

- (IBAction)markPage:(id)sender {
    markedPageIndex = [[pdfView currentPage] pageIndex];
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
        [pdfView scrollRect:selRect inPageToVisible:[pdfView currentSelectionPage]]; 
    } else NSBeep();
}

- (IBAction)doZoomToFit:(id)sender {
    [pdfView setAutoScales:YES];
    [pdfView setAutoScales:NO];
}

- (IBAction)alternateZoomToFit:(id)sender {
    PDFDisplayMode displayMode = [pdfView displayMode];
    NSRect frame = [pdfView frame];
    float scaleFactor = [pdfView scaleFactor];
    if (displayMode == kPDFDisplaySinglePage || displayMode == kPDFDisplayTwoUp) {
        // zoom to width
        float width = NSWidth([pdfView convertRect:[[pdfView documentView] bounds] fromView:[pdfView documentView]]) / scaleFactor;
        [pdfView setScaleFactor:NSWidth(frame) / width];
    } else {
        // zoom to height
        NSRect pageRect = [[pdfView currentPage] boundsForBox:[pdfView displayBox]];
        float height = NSHeight([pdfView convertRect:pageRect fromPage:[pdfView currentPage]]) / scaleFactor;
        if ([pdfView displaysPageBreaks])
            height += 10.0;
        [pdfView setScaleFactor:NSHeight(frame) / height];
        [pdfView layoutDocumentView];
        [pdfView scrollRect:pageRect inPageToVisible:[pdfView currentPage]];
    }
}

- (IBAction)zoomInActualOut:(id)sender {
    int tag = [sender selectedTag];
    if (tag == -1)
        [pdfView zoomOut:sender];
    else if (tag == 0)
        [pdfView setScaleFactor:1.0];
    else if (tag == 1)
        [pdfView zoomIn:sender];
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

- (void)rotatePageAtIndex:(unsigned int)idx by:(int)rotation {
    NSUndoManager *undoManager = [[self document] undoManager];
    [[undoManager prepareWithInvocationTarget:self] rotatePageAtIndex:idx by:-rotation];
    [undoManager setActionName:NSLocalizedString(@"Rotate Page", @"Undo action name")];
    [[self document] undoableActionDoesntDirtyDocument];
    
    PDFPage *page = [[pdfView document] pageAtIndex:idx];
    [page setRotation:[page rotation] + rotation];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFPageBoundsDidChangeNotification 
            object:[pdfView document] userInfo:[NSDictionary dictionaryWithObjectsAndKeys:SKPDFPageActionRotate, SKPDFPageActionKey, page, SKPDFPagePageKey, nil]];
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
    [[self document] undoableActionDoesntDirtyDocument];
    
    int i, count = [[pdfView document] pageCount];
    for (i = 0; i < count; i++) {
        [[[pdfView document] pageAtIndex:i] setRotation:[[[pdfView document] pageAtIndex:i] rotation] + 90];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFPageBoundsDidChangeNotification 
            object:[pdfView document] userInfo:[NSDictionary dictionaryWithObjectsAndKeys:SKPDFPageActionRotate, SKPDFPageActionKey, nil]];
}

- (IBAction)rotateAllLeftRight:(id)sender {
    if ([sender selectedSegment] == 0)
        [self rotateLeft:sender];
    else
        [self rotateAllRight:sender];
}

- (IBAction)rotateAllLeft:(id)sender {
    NSUndoManager *undoManager = [[self document] undoManager];
    [[undoManager prepareWithInvocationTarget:self] rotateAllRight:nil];
    [undoManager setActionName:NSLocalizedString(@"Rotate", @"Undo action name")];
    [[self document] undoableActionDoesntDirtyDocument];
    
    int i, count = [[pdfView document] pageCount];
    for (i = 0; i < count; i++) {
        [[[pdfView document] pageAtIndex:i] setRotation:[[[pdfView document] pageAtIndex:i] rotation] - 90];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFPageBoundsDidChangeNotification 
            object:[pdfView document] userInfo:[NSDictionary dictionaryWithObjectsAndKeys:SKPDFPageActionRotate, SKPDFPageActionKey, nil]];
}

- (void)cropPageAtIndex:(unsigned int)anIndex toRect:(NSRect)rect {
    NSRect oldRect = [[[pdfView document] pageAtIndex:anIndex] boundsForBox:kPDFDisplayBoxCropBox];
    NSUndoManager *undoManager = [[self document] undoManager];
    [[undoManager prepareWithInvocationTarget:self] cropPageAtIndex:anIndex toRect:oldRect];
    [undoManager setActionName:NSLocalizedString(@"Crop Page", @"Undo action name")];
    [[self document] undoableActionDoesntDirtyDocument];
    
    PDFPage *page = [[pdfView document] pageAtIndex:anIndex];
    rect = NSIntersectionRect(rect, [page boundsForBox:kPDFDisplayBoxMediaBox]);
    [page setBounds:rect forBox:kPDFDisplayBoxCropBox];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFPageBoundsDidChangeNotification 
            object:[pdfView document] userInfo:[NSDictionary dictionaryWithObjectsAndKeys:SKPDFPageActionCrop, SKPDFPageActionKey, page, SKPDFPagePageKey, nil]];
    
    // make sure we show the crop box
    [pdfView setDisplayBox:kPDFDisplayBoxCropBox];
}

- (IBAction)crop:(id)sender {
    NSRect rect = NSIntegralRect([pdfView currentSelectionRect]);
    PDFPage *page = [pdfView currentSelectionPage] ?: [pdfView currentPage];
    if (NSIsEmptyRect(rect))
        rect = [[pdfView currentSelectionPage] foregroundBox];
    [self cropPageAtIndex:[page pageIndex] toRect:rect];
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
    [[self document] undoableActionDoesntDirtyDocument];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFPageBoundsDidChangeNotification 
            object:[pdfView document] userInfo:[NSDictionary dictionaryWithObjectsAndKeys:SKPDFPageActionCrop, SKPDFPageActionKey, nil]];
    
    // make sure we show the crop box
    [pdfView setDisplayBox:kPDFDisplayBoxCropBox];
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
    [[SKInfoWindowController sharedInstance] showWindow:self];
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
        [statusBar setRightAction:[pdfView toolMode] == SKSelectToolMode ? @selector(statusBarClicked:) : NULL];
        [statusBar setRightTarget:self];
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
    float scaleFactor = [[self pdfView] scaleFactor];
    BOOL autoScales = [[self pdfView] autoScales];
    BOOL isSingleRow;
    
    if (displayMode == kPDFDisplaySinglePage || displayMode == kPDFDisplayTwoUp)
        isSingleRow = YES;
    else if (displayMode == kPDFDisplaySinglePageContinuous || [[self pdfView] displaysAsBook])
        isSingleRow = [[[self pdfView] document] pageCount] <= 1;
    else
        isSingleRow = [[[self pdfView] document] pageCount] <= 2;
    
    NSRect frame = [[self window] frame];
    NSSize size, oldSize = [[self pdfView] frame].size;
    NSRect documentRect = [[[self pdfView] documentView] convertRect:[[[self pdfView] documentView] bounds] toView:nil];
    
    // Calculate the new size for the pdfView
    size.width = NSWidth(documentRect);
    if (autoScales)
        size.width /= scaleFactor;
    if (isSingleRow) {
        size.height = NSHeight(documentRect);
    } else {
        size.height = NSHeight([[self pdfView] convertRect:[[[self pdfView] currentPage] boundsForBox:[[self pdfView] displayBox]] fromPage:[[self pdfView] currentPage]]);
        if ([[self pdfView] displaysPageBreaks])
            size.height += 8.0 * scaleFactor;
        size.width += [NSScroller scrollerWidth];
    }
    if (autoScales)
        size.height /= scaleFactor;
    
    // Calculate the new size for the window
    size.width = ceilf(NSWidth(frame) + size.width - oldSize.width);
    size.height = ceilf(NSHeight(frame) + size.height - oldSize.height);
    // Align the window frame from the old topleft point and constrain to the screen
    frame.origin.y = NSMaxY(frame) - size.height;
    frame.size = size;
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

- (void)setupBookmarkSheetDidEnd:(SKBookmarkSheetController *)controller returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSAlertDefaultReturn) {
        SKBookmarkController *bmController = [SKBookmarkController sharedBookmarkController];
        NSDictionary *setup = [[self document] currentDocumentSetup];
        NSString *label = [controller stringValue];
        [bmController addBookmarkForSetup:setup label:label toFolder:[controller selectedFolder]];
    }
}

- (IBAction)addSetupBookmark:(id)sender {
    if (bookmarkSheetController == nil)
        bookmarkSheetController = [[SKBookmarkSheetController alloc] init];
    
	[bookmarkSheetController setStringValue:[[self document] displayName]];
    
    [bookmarkSheetController beginSheetModalForWindow: [self window]
        modalDelegate:self 
       didEndSelector:@selector(setupBookmarkSheetDidEnd:returnCode:contextInfo:)
          contextInfo:NULL];
}

- (void)sessionBookmarkSheetDidEnd:(SKBookmarkSheetController *)controller returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSAlertDefaultReturn) {
        SKBookmarkController *bmController = [SKBookmarkController sharedBookmarkController];
        NSString *label = [controller stringValue];
        NSArray *setups = [[NSApp orderedDocuments] valueForKey:@"currentDocumentSetup"];
        [bmController addBookmarkForSetups:setups label:label toFolder:[controller selectedFolder]];
    }
}

- (IBAction)addSessionBookmark:(id)sender {
    if (bookmarkSheetController == nil)
        bookmarkSheetController = [[SKBookmarkSheetController alloc] init];
    
	[bookmarkSheetController setStringValue:[[self document] displayName]];
    
    [bookmarkSheetController beginSheetModalForWindow: [self window]
        modalDelegate:self 
       didEndSelector:@selector(sessionBookmarkSheetDidEnd:returnCode:contextInfo:)
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

- (IBAction)toggleCaseInsensitiveSearch:(id)sender {
    caseInsensitiveSearch = NO == caseInsensitiveSearch;
    if ([[searchField stringValue] length])
        [self search:searchField];
}

- (IBAction)toggleWholeWordSearch:(id)sender {
    wholeWordSearch = NO == wholeWordSearch;
    if ([[searchField stringValue] length])
        [self search:searchField];
}

- (IBAction)toggleLeftSidePane:(id)sender {
    if ([self isFullScreen]) {
        [[SKPDFToolTipWindow sharedToolTipWindow] fadeOut];
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
                [[SKPDFToolTipWindow sharedToolTipWindow] fadeOut];
            [leftSideDrawer close];
        } else {
            [leftSideDrawer openOnEdge:NSMinXEdge];
        }
    } else {
        NSRect sideFrame = [leftSideContentView frame];
        NSRect pdfFrame = [pdfSplitView frame];
        
        if ([self leftSidePaneIsOpen]) {
            if (leftSidePaneState == SKOutlineSidePaneState || [[searchField stringValue] length])
                [[SKPDFToolTipWindow sharedToolTipWindow] fadeOut];
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
        [[self window] invalidateCursorRectsForView:splitView];
        
        [self splitViewDidResizeSubviews:nil];
    }
    if ([currentLeftSideView isEqual:thumbnailView])
        [thumbnailTableView sizeToFit];
    else if ([currentLeftSideView isEqual:outlineView])
        [outlineView sizeToFit];
    else if ([currentLeftSideView isEqual:findView])
        [findTableView sizeToFit];
    else if ([currentLeftSideView isEqual:groupedFindView])
        [groupedFindTableView sizeToFit];
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
        [[self window] invalidateCursorRectsForView:splitView];
        
        [self splitViewDidResizeSubviews:nil];
    }
    if ([currentRightSideView isEqual:noteView])
        [noteOutlineView sizeToFit];
    else if ([currentRightSideView isEqual:snapshotView])
        [snapshotTableView sizeToFit];
}

- (IBAction)changeLeftSidePaneState:(id)sender {
    [self setLeftSidePaneState:[sender tag]];
}

- (IBAction)changeRightSidePaneState:(id)sender {
    [self setRightSidePaneState:[sender tag]];
}

- (IBAction)changeFindPaneState:(id)sender {
    [self setFindPaneState:[sender tag]];
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
            if ([pdfView autoScales] || [[NSUserDefaults standardUserDefaults] boolForKey:SKSplitPDFCopiesZoomKey] == NO)
                [secondaryPdfView setAutoScales:YES];
            else
                [secondaryPdfView setScaleFactor:[pdfView scaleFactor]];
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
        [leftSideWindow setAlphaValue:PRESENTATION_SIDE_WINDOW_ALPHA];
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
        [leftSideWindow setLevel:[[self window] level] + 1];
        [leftSideWindow setAlphaValue:PRESENTATION_SIDE_WINDOW_ALPHA];
        [leftSideWindow setEnabled:NO];
        [rightSideWindow expand];
    } else {
        [rightSideWindow collapse];
        [rightSideWindow orderFront:self];
    }
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
    NSScreen *screen = [[self window] screen] ?: [NSScreen mainScreen]; // @@ screen: or should we use the main screen?
    NSColor *backgroundColor = [self isPresentation] ? [NSColor blackColor] : [[NSUserDefaults standardUserDefaults] colorForKey:SKFullScreenBackgroundColorKey];
    
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
        if ([wc isNoteWindowController] || [wc isSnapshotWindowController])
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
        if ([wc isNoteWindowController] || [wc isSnapshotWindowController])
            [(id)wc setForceOnTop:NO];
    }
    
    [fullScreenWindow setDelegate:nil];
    [self setWindow:mainWindow];
    [mainWindow orderWindow:NSWindowBelow relativeTo:[fullScreenWindow windowNumber]];
    [mainWindow makeKeyWindow];
    [mainWindow display];
    [fullScreenWindow fadeOut];
    [mainWindow makeFirstResponder:pdfView];
    [mainWindow recalculateKeyViewLoop];
    [mainWindow setDelegate:self];
    
    NSEnumerator *blankScreenEnumerator = [blankingWindows objectEnumerator];
    SKFullScreenWindow *window;
    while (window = [blankScreenEnumerator nextObject])
        [window fadeOut];
}

- (void)saveNormalSetup {
    if ([self isPresentation] == NO && [self isFullScreen] == NO) {
        NSScrollView *scrollView = [[pdfView documentView] enclosingScrollView];
        [savedNormalSetup setDictionary:[self currentPDFSettings]];
        [savedNormalSetup setObject:[NSNumber numberWithBool:[scrollView hasHorizontalScroller]] forKey:SKMainWindowHasHorizontalScrollerKey];
        [savedNormalSetup setObject:[NSNumber numberWithBool:[scrollView hasVerticalScroller]] forKey:SKMainWindowHasVerticalScrollerKey];
        [savedNormalSetup setObject:[NSNumber numberWithBool:[scrollView autohidesScrollers]] forKey:SKMainWindowAutoHidesScrollersKey];
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
    [scrollView setAutohidesScrollers:YES];
    [scrollView setHasHorizontalScroller:NO];
    [scrollView setHasVerticalScroller:NO];
    
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
    [scrollView setHasHorizontalScroller:[[savedNormalSetup objectForKey:SKMainWindowHasHorizontalScrollerKey] boolValue]];
    [scrollView setHasVerticalScroller:[[savedNormalSetup objectForKey:SKMainWindowHasVerticalScrollerKey] boolValue]];
    [scrollView setAutohidesScrollers:[[savedNormalSetup objectForKey:SKMainWindowAutoHidesScrollersKey] boolValue]];
    
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
    
    NSScreen *screen = [[self window] screen] ?: [NSScreen mainScreen]; // @@ screen: or should we use the main screen?
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
    
    [pdfView setInteractionMode:SKFullScreenMode screen:screen];
    [self showSideWindowsOnScreen:screen];
}

- (IBAction)enterPresentation:(id)sender {
    if ([self isPresentation])
        return;
    
    BOOL wasFullScreen = [self isFullScreen];
    
    [self enterPresentationMode];
    
    NSScreen *screen = [[self window] screen] ?: [NSScreen mainScreen]; // @@ screen: or should we use the main screen?
    if ([screen isEqual:[[NSScreen screens] objectAtIndex:0]])
        SetSystemUIMode(kUIModeAllHidden, 0);
    
    if (wasFullScreen)
        [self hideSideWindows];
    else
        [self goFullScreen];
    
    [pdfView setInteractionMode:SKPresentationMode screen:screen];
}

- (IBAction)exitFullScreen:(id)sender {
    if ([self isFullScreen] == NO && [self isPresentation] == NO)
        return;

    if ([self isFullScreen])
        [self hideSideWindows];
    
    if ([[fullScreenWindow firstResponder] isDescendantOf:pdfView])
        [fullScreenWindow makeFirstResponder:nil];
    [pdfView setInteractionMode:SKNormalMode screen:[[self window] screen]];
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

- (void)replaceSideView:(NSView *)newView atLeft:(BOOL)left animate:(BOOL)animate {
    if ([newView window] == nil) {
        NSView *oldView = nil;
        if (left) {
            oldView = currentLeftSideView;
            currentLeftSideView = newView;
        } else {
            oldView = currentRightSideView;
            currentRightSideView = newView;
        }
        
        NSResponder *oldFirstResponder = [[oldView window] firstResponder];
        BOOL wasFind = [oldView isEqual:findView] || [oldView isEqual:groupedFindView];
        BOOL isFind = [newView isEqual:findView] || [newView isEqual:groupedFindView];
        NSSegmentedControl *oldButton = wasFind ? findButton : leftSideButton;
        NSSegmentedControl *newButton = isFind ? findButton : leftSideButton;
        NSView *containerView = [newButton superview];
        
        if ([oldView isEqual:tocView] || [oldView isEqual:findView] || [oldView isEqual:groupedFindView])
            [[SKPDFToolTipWindow sharedToolTipWindow] orderOut:self];
        
        if (wasFind != isFind) {
            [newButton setFrame:[oldButton frame]];
            [newButton setHidden:animate];
            [[oldButton superview] addSubview:newButton];
        }
        
        [newView setFrame:[oldView frame]];
        [newView setHidden:animate];
        [[oldView superview] addSubview:newView];
        
        if (animate) {
            NSArray *viewAnimations = [NSArray arrayWithObjects:
                [NSDictionary dictionaryWithObjectsAndKeys:oldView, NSViewAnimationTargetKey, NSViewAnimationFadeOutEffect, NSViewAnimationEffectKey, nil],
                [NSDictionary dictionaryWithObjectsAndKeys:newView, NSViewAnimationTargetKey, NSViewAnimationFadeInEffect, NSViewAnimationEffectKey, nil], nil];
            
            NSViewAnimation *animation = [[[NSViewAnimation alloc] initWithViewAnimations:viewAnimations] autorelease];
            [animation setAnimationBlockingMode:NSAnimationBlocking];
            [animation setDuration:0.7];
            [animation setAnimationCurve:NSAnimationEaseIn];
            isAnimating = YES;
            [animation startAnimation];
            isAnimating = NO;
            
            if (wasFind != isFind) {
                viewAnimations = [NSArray arrayWithObjects:
                    [NSDictionary dictionaryWithObjectsAndKeys:oldButton, NSViewAnimationTargetKey, NSViewAnimationFadeOutEffect, NSViewAnimationEffectKey, nil],
                    [NSDictionary dictionaryWithObjectsAndKeys:newButton, NSViewAnimationTargetKey, NSViewAnimationFadeInEffect, NSViewAnimationEffectKey, nil], nil];
                
                animation = [[[NSViewAnimation alloc] initWithViewAnimations:viewAnimations] autorelease];
                [animation setAnimationBlockingMode:NSAnimationBlocking];
                [animation setDuration:0.3];
                [animation setAnimationCurve:NSAnimationEaseIn];
                [animation startAnimation];
            }
        }
        
        if ([oldFirstResponder isDescendantOf:oldView])
            [[newView window] makeFirstResponder:[newView nextKeyView]];
        [oldView removeFromSuperview];
        [oldView setHidden:NO];
        [[newView window] recalculateKeyViewLoop];
        
        if (wasFind != isFind) {
            [containerView addSubview:oldButton];
            [oldButton setHidden:NO];
            [newButton setHidden:NO];
            if ([oldFirstResponder isEqual:oldButton])
                [[newButton window] makeFirstResponder:newButton];
        }
    }
}

- (void)displayOutlineView {
    [self replaceSideView:tocView atLeft:YES animate:NO];
    [self updateOutlineSelection];
}

- (void)fadeInOutlineView {
    [self replaceSideView:tocView atLeft:YES animate:YES];
    [self updateOutlineSelection];
}

- (void)displayThumbnailView {
    [self replaceSideView:thumbnailView atLeft:YES animate:NO];
    [self updateThumbnailSelection];
}

- (void)fadeInThumbnailView {
    [self replaceSideView:thumbnailView atLeft:YES animate:YES];
    [self updateThumbnailSelection];
}

- (void)displaySearchView {
    [self replaceSideView:findView atLeft:YES animate:NO];
}

- (void)fadeInSearchView {
    [self replaceSideView:findView atLeft:YES animate:YES];
}

- (void)displayGroupedSearchView {
    [self replaceSideView:groupedFindView atLeft:YES animate:NO];
}

- (void)fadeInGroupedSearchView {
    [self replaceSideView:groupedFindView atLeft:YES animate:YES];
}

- (void)displayNoteView {
    [self replaceSideView:noteView atLeft:NO animate:NO];
}

- (void)displaySnapshotView {
    [self replaceSideView:snapshotView atLeft:NO animate:NO];
    [self updateSnapshotsIfNeeded];
}

#pragma mark Searching

- (void)temporaryAnnotationTimerFired:(NSTimer *)timer {
    [self removeTemporaryAnnotations];
}

- (void)addAnnotationsForSelection:(PDFSelection *)sel {
    NSArray *pages = [sel pages];
    int i, iMax = [pages count];
    NSColor *color = [[NSUserDefaults standardUserDefaults] colorForKey:SKSearchHighlightColorKey] ?: [NSColor redColor];
    
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
    // strip extra search criteria, such as kind:pdf
    NSRange range = [string rangeOfString:@":"];
    if (range.location != NSNotFound) {
        range = [string rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet] options:NSBackwardsSearch range:NSMakeRange(0, range.location)];
        if (range.location != NSNotFound && range.location > 0)
            string = [string substringWithRange:NSMakeRange(0, range.location)];
    }
    [searchField setStringValue:string];
    [searchField sendAction:[searchField action] to:[searchField target]];
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
        int options = caseInsensitiveSearch ? NSCaseInsensitiveSearch : 0;
        if (wholeWordSearch && [[pdfView document] respondsToSelector:@selector(beginFindStrings:withOptions:)]) {
            NSMutableArray *words = [NSMutableArray array];
            NSEnumerator *wordEnum = [[[sender stringValue] componentsSeparatedByString:@" "] objectEnumerator];
            NSString *word;
            while (word = [wordEnum nextObject]) {
                if ([word isEqualToString:@""] == NO)
                    [words addObject:word];
            }
            [[pdfView document] beginFindStrings:words withOptions:options];
        } else {
            [[pdfView document] beginFindString:[sender stringValue] withOptions:options];
        }
        if (findPaneState == SKSingularFindPaneState)
            [self fadeInSearchView];
        else
            [self fadeInGroupedSearchView];
        
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
        [groupedFindTableView deselectAll:self];
        if ([[NSUserDefaults standardUserDefaults] boolForKey:SKShouldHighlightSearchResultsKey]) {
            [self removeTemporaryAnnotations];
            [self addAnnotationsForSelection:selection];
            temporaryAnnotationTimer = [[NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(temporaryAnnotationTimerFired:) userInfo:NULL repeats:NO] retain];
        }
        if ([pdfView respondsToSelector:@selector(setCurrentSelection:animate:)] && [[NSUserDefaults standardUserDefaults] boolForKey:SKDisableAnimatedSearchHighlightKey] == NO)
            [pdfView setCurrentSelection:selection animate:YES];
	} else {
		NSBeep();
	}
}

- (void)removeHighlightedSelections:(NSTimer *)timer {
    [highlightTimer invalidate];
    [highlightTimer release];
    highlightTimer = nil;
    [pdfView setHighlightedSelections:nil];
}

- (void)goToFindResults:(NSArray *)findResults scrollToVisible:(BOOL)scroll {
    NSEnumerator *selE = [findResults objectEnumerator];
    PDFSelection *sel;
    
    // arm:  PDFSelection is mutable, and using -addSelection on an object from selectedObjects will actually mutate the object in searchResults, which does bad things.  MagicHat indicates that PDFSelection implements copyWithZone: even though it doesn't conform to <NSCopying>, so we'll use that since -init doesn't work (-initWithDocument: does, but it's not listed in the header either).  I filed rdar://problem/4888251 and also noticed that PDFKitViewer sample code uses -[PDFSelection copy].
    PDFSelection *firstSel = [selE nextObject];
    PDFSelection *currentSel = [[firstSel copy] autorelease];
    
    while (sel = [selE nextObject])
        [currentSel addSelection:sel];
    
    if (scroll && firstSel) {
        [pdfView setCurrentSelection:currentSel];
        [pdfView scrollSelectionToVisible:self];
    }
    
    [self removeTemporaryAnnotations];
    
    // add an annotation so it's easier to see the search result
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKShouldHighlightSearchResultsKey]) {
        selE = [findResults objectEnumerator];
        while (sel = [selE nextObject])
            [self addAnnotationsForSelection:sel];
    }
    
    if (highlightTimer)
        [self removeHighlightedSelections:highlightTimer];
    if ([pdfView respondsToSelector:@selector(setHighlightedSelections:)] && [[NSUserDefaults standardUserDefaults] boolForKey:SKDisableAnimatedSearchHighlightKey] == NO && [currentSel respondsToSelector:@selector(setColor:)] && [findResults count] > 1) {
        PDFSelection *tmpSel = [[currentSel copy] autorelease];
        [tmpSel setColor:[NSColor yellowColor]];
        [pdfView setHighlightedSelections:[NSArray arrayWithObject:tmpSel]];
        highlightTimer = [[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(removeHighlightedSelections:) userInfo:nil repeats:NO] retain];
    }
    
    if ([pdfView respondsToSelector:@selector(setCurrentSelection:animate:)] && [[NSUserDefaults standardUserDefaults] boolForKey:SKDisableAnimatedSearchHighlightKey] == NO && firstSel)
        [pdfView setCurrentSelection:firstSel animate:YES];
    
    if (currentSel)
        [pdfView setCurrentSelection:currentSel];
}

- (void)goToFindResults:(NSArray *)findResults {
    [self goToFindResults:findResults scrollToVisible:YES];
}

- (void)updateFindResultHighlights:(BOOL)scroll {
    NSArray *findResults = nil;
    
    if (findPaneState == SKSingularFindPaneState && [findView window])
        findResults = [findArrayController selectedObjects];
    else if (findPaneState == SKGroupedFindPaneState && [groupedFindView window])
        findResults = [[groupedFindArrayController selectedObjects] valueForKeyPath:@"@unionOfArrays.matches"];
    [self goToFindResults:findResults scrollToVisible:scroll];
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

#pragma mark PDFDocument delegate

- (void)didMatchString:(PDFSelection *)instance {
    if (findPanelFind == NO) {
        if (wholeWordSearch) {
            PDFSelection *copy = [[instance copy] autorelease];
            NSString *string = [instance string];
            unsigned int l = [string length];
            [copy extendSelectionAtEnd:1];
            string = [copy string];
            if ([string length] > l && [[NSCharacterSet letterCharacterSet] characterIsMember:[string characterAtIndex:l]])
                return;
            l = [string length];
            [copy extendSelectionAtStart:1];
            string = [copy string];
            if ([string length] > l && [[NSCharacterSet letterCharacterSet] characterIsMember:[string characterAtIndex:0]])
                return;
        }
        [searchResults addObject:instance];
        
        PDFPage *page = [[instance pages] objectAtIndex:0];
        SKGroupedSearchResult *result = [groupedSearchResults lastObject];
        unsigned int maxCount = [result maxCount];
        if ([[result page] isEqual:page] == NO) {
            result = [SKGroupedSearchResult groupedSearchResultWithPage:page maxCount:maxCount];
            [groupedSearchResults addObject:result];
        }
        [result addMatch:instance];
        
        if ([result count] > maxCount) {
            NSEnumerator *resultEnum = [groupedSearchResults objectEnumerator];
            maxCount = [result count];
            while (result = [resultEnum nextObject])
                [result setMaxCount:maxCount];
        }
    }
}

- (void)documentDidBeginDocumentFind:(NSNotification *)note {
    if (findPanelFind == NO) {
        NSString *message = [NSLocalizedString(@"Searching", @"Message in search table header") stringByAppendingEllipsis];
        [findArrayController removeObjects:searchResults];
        [[[findTableView tableColumnWithIdentifier:SKMainWindowResultsColumnIdentifer] headerCell] setStringValue:message];
        [[findTableView headerView] setNeedsDisplay:YES];
        [[[groupedFindTableView tableColumnWithIdentifier:SKMainWindowRelevanceColumnIdentifer] headerCell] setStringValue:message];
        [[groupedFindTableView headerView] setNeedsDisplay:YES];
        [groupedFindArrayController removeObjects:groupedSearchResults];
        [statusBar setProgressIndicatorStyle:SKProgressIndicatorBarStyle];
        [[statusBar progressIndicator] setMaxValue:[[note object] pageCount]];
        [[statusBar progressIndicator] setDoubleValue:0.0];
        [statusBar startAnimation:self];
        [self willChangeValueForKey:SKMainWindowSearchResultsKey];
        [self willChangeValueForKey:SKMainWindowGroupedSearchResultsKey];
    }
}

- (void)documentDidEndDocumentFind:(NSNotification *)note {
    if (findPanelFind == NO) {
        NSString *message = [NSString stringWithFormat:NSLocalizedString(@"%i Results", @"Message in search table header"), [searchResults count]];
        [self didChangeValueForKey:SKMainWindowGroupedSearchResultsKey];
        [self didChangeValueForKey:SKMainWindowSearchResultsKey];
        [[[findTableView tableColumnWithIdentifier:SKMainWindowResultsColumnIdentifer] headerCell] setStringValue:message];
        [[findTableView headerView] setNeedsDisplay:YES];
        [[[groupedFindTableView tableColumnWithIdentifier:SKMainWindowRelevanceColumnIdentifer] headerCell] setStringValue:message];
        [[groupedFindTableView headerView] setNeedsDisplay:YES];
        [statusBar stopAnimation:self];
        [statusBar setProgressIndicatorStyle:SKProgressIndicatorNone];
    }
}

- (void)documentDidEndPageFind:(NSNotification *)note {
    NSNumber *pageIndex = [[note userInfo] objectForKey:@"PDFDocumentPageIndex"];
    [[statusBar progressIndicator] setDoubleValue:[pageIndex doubleValue]];
    if ([pageIndex unsignedIntValue] % 50 == 0) {
        [self didChangeValueForKey:SKMainWindowGroupedSearchResultsKey];
        [self didChangeValueForKey:SKMainWindowSearchResultsKey];
        [self willChangeValueForKey:SKMainWindowSearchResultsKey];
        [self willChangeValueForKey:SKMainWindowGroupedSearchResultsKey];
    }
}

- (void)documentDidUnlock:(NSNotification *)notification {
    [self updatePageLabelsAndOutline];
}

#pragma mark PDFDocument notifications

- (void)handlePageBoundsDidChangeNotification:(NSNotification *)notification {
    NSDictionary *info = [notification userInfo];
    PDFPage *page = [info objectForKey:SKPDFPagePageKey];
    BOOL displayChanged = [[info objectForKey:SKPDFPageActionKey] isEqualToString:SKPDFPageActionRotate] || [pdfView displayBox] == kPDFDisplayBoxCropBox;
    
    if (displayChanged)
        [pdfView layoutDocumentView];
    if (page) {
        unsigned int idx = [page pageIndex];
        NSEnumerator *snapshotEnum = [snapshots objectEnumerator];
        SKSnapshotWindowController *wc;
        while (wc = [snapshotEnum nextObject]) {
            if ([wc isPageVisible:page]) {
                [self snapshotNeedsUpdate:wc];
                [wc redisplay];
            }
        }
        if (displayChanged)
            [self updateThumbnailAtPageIndex:idx];
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

- (void)registerForDocumentNotifications {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(handleDocumentBeginWrite:) 
                             name:@"PDFDidBeginDocumentWrite" object:[pdfView document]];
    [nc addObserver:self selector:@selector(handleDocumentEndWrite:) 
                             name:@"PDFDidEndDocumentWrite" object:[pdfView document]];
    [nc addObserver:self selector:@selector(handleDocumentEndPageWrite:) 
                             name:@"PDFDidEndPageWrite" object:[pdfView document]];
    [nc addObserver:self selector:@selector(handlePageBoundsDidChangeNotification:) 
                             name:SKPDFPageBoundsDidChangeNotification object:[pdfView document]];
}

- (void)unregisterForDocumentNotifications {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:@"PDFDidBeginDocumentWrite" object:[pdfView document]];
    [nc removeObserver:self name:@"PDFDidEndDocumentWrite" object:[pdfView document]];
    [nc removeObserver:self name:@"PDFDidEndPageWrite" object:[pdfView document]];
    [nc removeObserver:self name:SKPDFPageBoundsDidChangeNotification object:[pdfView document]];
}

#pragma mark Tiger history fixes

- (void)registerDestinationHistory:(PDFDestination *)destination {
    if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_4) {
        @try {
            NSMutableArray *destinationHistory = [pdfView valueForKeyPath:@"pdfPriv.destinationHistory"];
            int historyIndex = [[pdfView valueForKeyPath:@"pdfPriv.historyIndex"] intValue];
            if (historyIndex < (int)[destinationHistory count])
                [destinationHistory removeObjectsInRange:NSMakeRange(historyIndex, [destinationHistory count] - historyIndex)];
            [destinationHistory addObject:destination];
            [pdfView setValue:[NSNumber numberWithInt:++historyIndex] forKeyPath:@"pdfPriv.historyIndex"];
            [[NSNotificationCenter defaultCenter] postNotificationName:PDFViewChangedHistoryNotification object:pdfView];
        }
        @catch (id exception) {}
    }
}

- (void)goToDestination:(PDFDestination *)destination {
    PDFDestination *dest = [pdfView currentDestination];
    [pdfView goToDestination:destination];
    [self registerDestinationHistory:dest];
}

- (void)goToPage:(PDFPage *)page {
    PDFDestination *dest = [pdfView currentDestination];
    [pdfView goToPage:page];
    [self registerDestinationHistory:dest];
}

#pragma mark Subwindows

- (void)showSnapshotAtPageNumber:(int)pageNum forRect:(NSRect)rect scaleFactor:(float)scaleFactor autoFits:(BOOL)autoFits {
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
    [[self mutableArrayValueForKey:SKMainWindowSnapshotsKey] addObject:controller];
}

- (void)snapshotControllerWindowWillClose:(SKSnapshotWindowController *)controller {
    [[self mutableArrayValueForKey:SKMainWindowSnapshotsKey] removeObject:controller];
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
        if ([wc isNoteWindowController] && [(SKNoteWindowController *)wc note] == annotation)
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

#pragma mark Observer registration

- (void)registerAsObserver {
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeys:
        [NSArray arrayWithObjects:SKBackgroundColorKey, SKFullScreenBackgroundColorKey, 
                                  SKSearchHighlightColorKey, SKShouldHighlightSearchResultsKey, 
                                  SKThumbnailSizeKey, SKSnapshotThumbnailSizeKey, 
                                  SKShouldAntiAliasKey, SKGreekingThresholdKey, 
                                  SKTableFontSizeKey, nil]
        context:SKMainWindowDefaultsObservationContext];
}

- (void)unregisterAsObserver {
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeys:
        [NSArray arrayWithObjects:SKBackgroundColorKey, SKFullScreenBackgroundColorKey, 
                                  SKSearchHighlightColorKey, SKShouldHighlightSearchResultsKey, 
                                  SKThumbnailSizeKey, SKSnapshotThumbnailSizeKey, 
                                  SKShouldAntiAliasKey, SKGreekingThresholdKey, 
                                  SKTableFontSizeKey, nil]];
}

#pragma mark Undo

- (void)startObservingNotes:(NSArray *)newNotes {
    // Each note can have a different set of properties that need to be observed.
    NSEnumerator *noteEnum = [newNotes objectEnumerator];
    PDFAnnotation *note;
    while (note = [noteEnum nextObject]) {
        NSEnumerator *keyEnumerator = [[note keysForValuesToObserveForUndo] objectEnumerator];
        NSString *key;
        while (key = [keyEnumerator nextObject]) {
            // We use NSKeyValueObservingOptionOld because when something changes we want to record the old value, which is what has to be set in the undo operation. We use NSKeyValueObservingOptionNew because we compare the new value against the old value in an attempt to ignore changes that aren't really changes.
            [note addObserver:self forKeyPath:key options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:SKNPDFAnnotationPropertiesObservationContext];
        }
    }
}

- (void)stopObservingNotes:(NSArray *)oldNotes {
    // Do the opposite of what's done in -startObservingNotes:.
    NSEnumerator *noteEnum = [oldNotes objectEnumerator];
    PDFAnnotation *note;
    while (note = [noteEnum nextObject]) {
        NSEnumerator *keyEnumerator = [[note keysForValuesToObserveForUndo] objectEnumerator];
        NSString *key;
        while (key = [keyEnumerator nextObject])
            [note removeObserver:self forKeyPath:key];
    }
}

- (void)setNoteProperties:(NSDictionary *)propertiesPerNote {
    // The passed-in dictionary is keyed by note...
    NSEnumerator *noteEnum = [propertiesPerNote keyEnumerator];
    PDFAnnotation *note;
    while (note = [noteEnum nextObject]) {
        // ...with values that are dictionaries of properties, keyed by key-value coding key.
        NSDictionary *noteProperties = [propertiesPerNote objectForKey:note];
        // Use a relatively unpopular method. Here we're effectively "casting" a key path to a key (see how these dictionaries get built in -observeValueForKeyPath:ofObject:change:context:). It had better really be a key or things will get confused. For example, this is one of the things that would need updating if -[SKTNote keysForValuesToObserveForUndo] someday becomes -[SKTNote keyPathsForValuesToObserveForUndo].
        [note setValuesForKeysWithDictionary:noteProperties];
    }
}

- (void)observeUndoManagerCheckpoint:(NSNotification *)notification {
    // Start the coalescing of note property changes over.
    [undoGroupOldPropertiesPerNote release];
    undoGroupOldPropertiesPerNote = nil;
}

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == SKMainWindowDefaultsObservationContext) {
        
        // A default value that we are observing has changed
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
                [[searchField stringValue] length] && 
                (([findView window] && [findTableView numberOfSelectedRows]) || ([groupedFindView window] && [groupedFindTableView numberOfSelectedRows]))) {
                // clear the selection
                [self updateFindResultHighlights:NO];
            }
        } else if ([key isEqualToString:SKShouldHighlightSearchResultsKey]) {
            if ([[searchField stringValue] length] &&  ([findTableView numberOfSelectedRows] || [groupedFindTableView numberOfSelectedRows])) {
                // clear the selection
                [self updateFindResultHighlights:NO];
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
        } else if ([key isEqualToString:SKTableFontSizeKey]) {
            NSFont *font = [NSFont systemFontOfSize:[[NSUserDefaults standardUserDefaults] floatForKey:SKTableFontSizeKey]];
            [outlineView setFont:font];
            [noteOutlineView setFont:font];
            [findTableView setFont:font];
            [groupedFindTableView setFont:font];
            [self updatePageColumnWidthForTableView:outlineView];
        }
        
    } else if (context == SKNPDFAnnotationPropertiesObservationContext) {
        
        // The value of some note's property has changed
        PDFAnnotation *note = (PDFAnnotation *)object;
        // Ignore changes that aren't really changes.
        // How much processor time does this memory optimization cost? We don't know, because we haven't measured it. The use of NSKeyValueObservingOptionNew in -startObservingNotes:, which makes NSKeyValueChangeNewKey entries appear in change dictionaries, definitely costs something when KVO notifications are sent (it costs virtually nothing at observer registration time). Regardless, it's probably a good idea to do simple memory optimizations like this as they're discovered and debug just enough to confirm that they're saving the expected memory (and not introducing bugs). Later on it will be easier to test for good responsiveness and sample to hunt down processor time problems than it will be to figure out where all the darn memory went when your app turns out to be notably RAM-hungry (and therefore slowing down _other_ apps on your user's computers too, if the problem is bad enough to cause paging).
        // Is this a premature optimization? No. Leaving out this very simple check, because we're worried about the processor time cost of using NSKeyValueChangeNewKey, would be a premature optimization.
        // We should be adding undo for nil values also. I'm not sure if KVO does this automatically. Note that -setValuesForKeysWithDictionary: converts NSNull back to nil.
        id newValue = [change objectForKey:NSKeyValueChangeNewKey] ?: [NSNull null];
        id oldValue = [change objectForKey:NSKeyValueChangeOldKey] ?: [NSNull null];
        // All values are suppsed to be true value objects that should be compared with isEqual:
        if ([newValue isEqual:oldValue] == NO) {
            
            // Is this the first observed note change in the current undo group?
            NSUndoManager *undoManager = [[self document] undoManager];
            if (undoGroupOldPropertiesPerNote == nil) {
                // We haven't recorded changes for any notes at all since the last undo manager checkpoint. Get ready to start collecting them. We don't want to copy the PDFAnnotations though.
                undoGroupOldPropertiesPerNote = (NSMutableDictionary *)CFDictionaryCreateMutable(NULL, 0, &kSKPointerEqualObjectDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
                // Register an undo operation for any note property changes that are going to be coalesced between now and the next invocation of -observeUndoManagerCheckpoint:.
                [undoManager registerUndoWithTarget:self selector:@selector(setNoteProperties:) object:undoGroupOldPropertiesPerNote];
            }

            // Find the dictionary in which we're recording the old values of properties for the changed note
            NSMutableDictionary *oldNoteProperties = [undoGroupOldPropertiesPerNote objectForKey:note];
            if (oldNoteProperties == nil) {
                // We have to create a dictionary to hold old values for the changed note
                oldNoteProperties = [[NSMutableDictionary alloc] init];
                // -setValue:forKey: copies, even if the callback doesn't, so we need to use CF functions
                CFDictionarySetValue((CFMutableDictionaryRef)undoGroupOldPropertiesPerNote, note, oldNoteProperties);
                [oldNoteProperties release];
            }

            // Record the old value for the changed property, unless an older value has already been recorded for the current undo group. Here we're "casting" a KVC key path to a dictionary key, but that should be OK. -[NSMutableDictionary setObject:forKey:] doesn't know the difference.
            if ([oldNoteProperties objectForKey:keyPath] == nil)
                [oldNoteProperties setObject:oldValue forKey:keyPath];

            // Don't set the undo action name during undoing and redoing
            if ([undoManager isUndoing] == NO && [undoManager isRedoing] == NO)
                [undoManager setActionName:NSLocalizedString(@"Edit Note", @"Undo action name")];
            
            // Update the UI, we should always do that unless the value did not really change
            
            PDFPage *page = [note page];
            NSRect oldRect = NSZeroRect;
            if ([keyPath isEqualToString:SKNPDFAnnotationBoundsKey] && [oldValue isEqual:[NSNull null]] == NO)
                oldRect = [note displayRectForBounds:[oldValue rectValue]];
            
            [self updateThumbnailAtPageIndex:[note pageIndex]];
            
            NSEnumerator *snapshotEnum = [snapshots objectEnumerator];
            SKSnapshotWindowController *wc;
            while (wc = [snapshotEnum nextObject]) {
                if ([wc isPageVisible:[note page]]) {
                    [self snapshotNeedsUpdate:wc];
                    [wc setNeedsDisplayForAnnotation:note onPage:page];
                    if (NSIsEmptyRect(oldRect) == NO)
                        [wc setNeedsDisplayInRect:oldRect ofPage:page];
                }
            }
            
            [pdfView setNeedsDisplayForAnnotation:note];
            [secondaryPdfView setNeedsDisplayForAnnotation:note onPage:page];
            if (NSIsEmptyRect(oldRect) == NO) {
                [pdfView setNeedsDisplayInRect:oldRect ofPage:page];
                [secondaryPdfView setNeedsDisplayInRect:oldRect ofPage:page];
            }
            if ([[note type] isEqualToString:SKNNoteString] && [keyPath isEqualToString:SKNPDFAnnotationBoundsKey])
                [pdfView resetPDFToolTipRects];
            
            if ([keyPath isEqualToString:SKNPDFAnnotationBoundsKey] || [keyPath isEqualToString:SKNPDFAnnotationStringKey] || [keyPath isEqualToString:SKNPDFAnnotationTextKey]) {
                [noteArrayController rearrangeObjects];
                [noteOutlineView reloadData];
            }
            
            // update the various panels if necessary
            if ([[self window] isMainWindow] && [note isEqual:[pdfView activeAnnotation]]) {
                if (updatingColor == NO && ([keyPath isEqualToString:SKNPDFAnnotationColorKey] || [keyPath isEqualToString:SKNPDFAnnotationInteriorColorKey])) {
                    updatingColor = YES;
                    [[NSColorPanel sharedColorPanel] setColor:[note color]];
                    updatingColor = NO;
                }
                if (updatingFont == NO && ([keyPath isEqualToString:SKNPDFAnnotationFontKey])) {
                    updatingFont = YES;
                    [[NSFontManager sharedFontManager] setSelectedFont:[(PDFAnnotationFreeText *)note font] isMultiple:NO];
                    updatingFont = NO;
                }
                if (updatingFontAttributes == NO && ([keyPath isEqualToString:SKNPDFAnnotationFontColorKey])) {
                    updatingFontAttributes = YES;
                    [[NSFontManager sharedFontManager] setSelectedAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[(PDFAnnotationFreeText *)note fontColor], NSForegroundColorAttributeName, nil] isMultiple:NO];
                    updatingFontAttributes = NO;
                }
                if (updatingLine == NO && ([keyPath isEqualToString:SKNPDFAnnotationBorderKey] || [keyPath isEqualToString:SKNPDFAnnotationStartLineStyleKey] || [keyPath isEqualToString:SKNPDFAnnotationEndLineStyleKey])) {
                    updatingLine = YES;
                    [[SKLineInspector sharedLineInspector] setAnnotationStyle:note];
                    updatingLine = NO;
                }
            }
        }

    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark Outline

- (int)outlineRowForPageIndex:(unsigned int)pageIndex {
    if (pdfOutline == nil)
        return -1;
    
	int i, numRows = [outlineView numberOfRows];
	for (i = 0; i < numRows; i++) {
		// Get the destination of the given row....
		SKPDFOutline *outlineItem = [outlineView itemAtRow:i];
        PDFPage *page = [outlineItem page];
		
        if (page == nil) {
            continue;
		} else if ([page pageIndex] == pageIndex) {
            break;
        } else if ([page pageIndex] > pageIndex) {
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
    [self willChangeValueForKey:SKMainWindowThumbnailsKey];
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
    [self didChangeValueForKey:SKMainWindowThumbnailsKey];
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

- (void)updateThumbnailAtPageIndex:(unsigned)anIndex {
    [[self objectInThumbnailsAtIndex:anIndex] setDirty:YES];
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
    NSMutableIndexSet *selPageIndexes = [NSMutableIndexSet indexSet];
    NSEnumerator *selEnum = [[self selectedNotes] objectEnumerator];
    
    while (selAnnotation = [selEnum nextObject])
        [selPageIndexes addIndex:[selAnnotation pageIndex]];
    
    if (count == 0 || [selPageIndexes containsIndex:pageIndex])
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
			else if ([selPageIndexes containsIndex:[[orderedNotes objectAtIndex:i - 1] pageIndex]])
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
        NSExpression *rhs = [NSExpression expressionForKeyPath:@"string"];
        NSPredicate *stringPredicate = [NSComparisonPredicate predicateWithLeftExpression:lhs rightExpression:rhs modifier:NSDirectPredicateModifier type:NSInPredicateOperatorType options:NSCaseInsensitivePredicateOption | NSDiacriticInsensitivePredicateOption];
        rhs = [NSExpression expressionForKeyPath:@"text.string"];
        NSPredicate *textPredicate = [NSComparisonPredicate predicateWithLeftExpression:lhs rightExpression:rhs modifier:NSDirectPredicateModifier type:NSInPredicateOperatorType options:NSCaseInsensitivePredicateOption | NSDiacriticInsensitivePredicateOption];
        searchPredicate = [NSCompoundPredicate orPredicateWithSubpredicates:[NSArray arrayWithObjects:stringPredicate, textPredicate, nil]];
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

- (void)addNote:(PDFAnnotation *)note {
    updatingNoteSelection = YES;
    [[self mutableArrayValueForKey:SKMainWindowNotesKey] addObject:note];
    [noteArrayController rearrangeObjects]; // doesn't seem to be done automatically
    updatingNoteSelection = NO;
    [noteOutlineView reloadData];
}

- (void)removeNote:(PDFAnnotation *)note {
    updatingNoteSelection = YES;
    [[self mutableArrayValueForKey:SKMainWindowNotesKey] removeObject:note];
    [noteArrayController rearrangeObjects]; // doesn't seem to be done automatically
    updatingNoteSelection = NO;
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
            unsigned idx = [[snapshotArrayController arrangedObjects] indexOfObject:controller];
            [snapshotTableView noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:idx]];
        }
    }
    if ([dirtySnapshots count] == 0) {
        [snapshotTimer invalidate];
        [snapshotTimer release];
        snapshotTimer = nil;
    }
}

#pragma mark Remote Control

- (void)remoteButtonPressed:(NSEvent *)theEvent {
    RemoteControlEventIdentifier remoteButton = (RemoteControlEventIdentifier)[theEvent data1];
    BOOL remoteScrolling = (BOOL)[theEvent data2];
    
    switch (remoteButton) {
        case kRemoteButtonPlus:
            if (remoteScrolling)
                [[[self pdfView] documentView] scrollLineUp];
            else if ([self isPresentation])
                [self doAutoScale:nil];
            else
                [self doZoomIn:nil];
            break;
        case kRemoteButtonMinus:
            if (remoteScrolling)
                [[[self pdfView] documentView] scrollLineDown];
            else if ([self isPresentation])
                [self doZoomToActualSize:nil];
            else
                [self doZoomOut:nil];
            break;
        case kRemoteButtonRight_Hold:
        case kRemoteButtonRight:
            if (remoteScrolling)
                [[[self pdfView] documentView] scrollLineRight];
            else 
                [self doGoToNextPage:nil];
            break;
        case kRemoteButtonLeft_Hold:
        case kRemoteButtonLeft:
            if (remoteScrolling)
                [[[self pdfView] documentView] scrollLineLeft];
            else 
                [self doGoToPreviousPage:nil];
            break;
        case kRemoteButtonPlay:        
            [self togglePresentation:nil];
            break;
        default:
            break;
    }
}

@end
