//
//  SKMainWindowController.m
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

#import "SKMainWindowController.h"
#import "SKMainWindowController_Toolbar.h"
#import "SKMainWindowController_UI.h"
#import <Quartz/Quartz.h>
#import <Carbon/Carbon.h>
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
#import "SKNoteText.h"
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
#import "SKPresentationOptionsSheetController.h"
#import "SKTypeSelectHelper.h"
#import "NSGeometry_SKExtensions.h"
#import "SKProgressController.h"
#import "SKSecondaryPDFView.h"
#import "SKSheetController.h"
#import "SKTextFieldSheetController.h"
#import "SKColorSwatch.h"
#import "SKRuntime.h"
#import "SKApplicationController.h"
#import "SKCFCallBacks.h"
#import "NSSegmentedControl_SKExtensions.h"
#import "NSImage_SKExtensions.h"
#import "NSMenu_SKExtensions.h"
#import "SKGroupedSearchResult.h"
#import "NSValueTransformer_SKExtensions.h"
#import "RemoteControl.h"
#import "NSView_SKExtensions.h"
#import "NSResponder_SKExtensions.h"
#import "SKPDFOutline.h"

#define MULTIPLICATION_SIGN_CHARACTER 0x00d7

#define PRESENTATION_SIDE_WINDOW_ALPHA 0.95

#define PAGELABELS_KEY              @"pageLabels"
#define SEARCHRESULTS_KEY           @"searchResults"
#define GROUPEDSEARCHRESULTS_KEY    @"groupedSearchResults"
#define NOTES_KEY                   @"notes"
#define THUMBNAILS_KEY              @"thumbnails"
#define SNAPSHOTS_KEY               @"snapshots"

#define PAGE_COLUMNID @"page"
#define NOTE_COLUMNID @"note"

#define RELEVANCE_COLUMNID  @"relevance"
#define RESULTS_COLUMNID    @"results"

#define PAGENUMBER_KEY  @"pageNumber"
#define PAGELABEL_KEY   @"pageLabel"

#define SKMainWindowFrameKey        @"windowFrame"
#define LEFTSIDEPANEWIDTH_KEY       @"leftSidePaneWidth"
#define RIGHTSIDEPANEWIDTH_KEY      @"rightSidePaneWidth"
#define SCALEFACTOR_KEY             @"scaleFactor"
#define AUTOSCALES_KEY              @"autoScales"
#define DISPLAYPAGEBREAKS_KEY       @"displaysPageBreaks"
#define DISPLAYASBOOK_KEY           @"displaysAsBook" 
#define DISPLAYMODE_KEY             @"displayMode"
#define DISPLAYBOX_KEY              @"displayBox"
#define HASHORIZONTALSCROLLER_KEY   @"hasHorizontalScroller"
#define HASVERTICALSCROLLER_KEY     @"hasVerticalScroller"
#define AUTOHIDESSCROLLERS_KEY      @"autoHidesScrollers"
#define PAGEINDEX_KEY               @"pageIndex"

#define SKMainWindowFrameAutosaveName @"SKMainWindow"

static char SKNPDFAnnotationPropertiesObservationContext;

static char SKMainWindowDefaultsObservationContext;

#define SKLeftSidePaneWidthKey @"SKLeftSidePaneWidth"
#define SKRightSidePaneWidthKey @"SKRightSidePaneWidth"

#define SKUsesDrawersKey @"SKUsesDrawers"
#define SKDisableAnimatedSearchHighlightKey @"SKDisableAnimatedSearchHighlight"

#define SKDisplayNoteBoundsKey @"SKDisplayNoteBounds" 

NSString *SKUnarchiveFromDataArrayTransformerName = @"SKUnarchiveFromDataArrayTransformer";


@interface SKMainWindowController (SKPrivate)

- (void)applyLeftSideWidth:(CGFloat)leftSideWidth rightSideWidth:(CGFloat)rightSideWidth;

- (void)setupToolbar;

- (void)updatePageLabel;

- (SKProgressController *)progressController;

- (void)goToSelectedFindResults:(id)sender;
- (void)updateFindResultHighlights:(BOOL)scroll;

- (void)selectSelectedNote:(id)sender;
- (void)goToSelectedOutlineItem:(id)sender;
- (void)toggleSelectedSnapshots:(id)sender;

- (void)updateNoteFilterPredicate;

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
    SKINITIALIZE;
    
    [NSValueTransformer setValueTransformer:[NSValueTransformer arrayTransformerWithValueTransformerForName:NSUnarchiveFromDataTransformerName]
                                    forName:SKUnarchiveFromDataArrayTransformerName];
    
    [PDFPage setUsesSequentialPageNumbering:[[NSUserDefaults standardUserDefaults] boolForKey:SKSequentialPageNumberingKey]];
}

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
    if ([key isEqualToString:PAGENUMBER_KEY] || [key isEqualToString:PAGELABEL_KEY])
        return NO;
    else
        return [super automaticallyNotifiesObserversForKey:key];
}

- (id)init {
    if (self = [super initWithWindowNibName:@"MainWindow"]) {
        mwcFlags.isPresentation = 0;
        searchResults = [[NSMutableArray alloc] init];
        mwcFlags.findPanelFind = 0;
        mwcFlags.caseInsensitiveSearch = 1;
        mwcFlags.wholeWordSearch = 0;
        mwcFlags.caseInsensitiveNoteSearch = 1;
        groupedSearchResults = [[NSMutableArray alloc] init];
        thumbnails = [[NSMutableArray alloc] init];
        notes = [[NSMutableArray alloc] init];
        tags = [[NSArray alloc] init];
        rating = 0.0;
        snapshots = [[NSMutableArray alloc] init];
        dirtySnapshots = [[NSMutableArray alloc] init];
        pageLabels = [[NSMutableArray alloc] init];
        lastViewedPages = [[NSMutableArray alloc] init];
        rowHeights = CFDictionaryCreateMutable(NULL, 0, &kSKPointerEqualObjectDictionaryKeyCallBacks, &kSKFloatDictionaryValueCallBacks);
        savedNormalSetup = [[NSMutableDictionary alloc] init];
        mwcFlags.leftSidePaneState = SKThumbnailSidePaneState;
        mwcFlags.rightSidePaneState = SKNoteSidePaneState;
        mwcFlags.findPaneState = SKSingularFindPaneState;
        temporaryAnnotations = CFSetCreateMutable(kCFAllocatorDefault, 0, &kCFTypeSetCallBacks);
        pageLabel = nil;
        pageNumber = NSNotFound;
        markedPageIndex = NSNotFound;
        beforeMarkedPageIndex = NSNotFound;
        mwcFlags.isAnimating = 0;
        mwcFlags.updatingColor = 0;
        mwcFlags.updatingFont = 0;
        mwcFlags.updatingLine = 0;
        mwcFlags.usesDrawers = [[NSUserDefaults standardUserDefaults] boolForKey:SKUsesDrawersKey];
    }
    
    return self;
}

- (void)dealloc {
    [self stopObservingNotes:[self notes]];
    [undoGroupOldPropertiesPerNote release];
    @try { [colorSwatch unbind:@"colors"]; }
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
	[tags release];
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
    [textColorAccessoryView release];
    [leftSideDrawer release];
    [rightSideDrawer release];
    [secondaryPdfEdgeView release];
    [presentationNotesDocument release];
    [super dealloc];
}

- (void)windowDidLoad{
    NSUserDefaults *sud = [NSUserDefaults standardUserDefaults];
    BOOL hasWindowSetup = [savedNormalSetup count] > 0;
    
    mwcFlags.settingUpWindow = 1;
    
    // Set up the panes and subviews, needs to be done before we resize them
    
    [leftSideCollapsibleView setCollapseEdges:BDSKMaxXEdgeMask | BDSKMinYEdgeMask];
    [leftSideCollapsibleView setMinSize:NSMakeSize(111.0, NSHeight([leftSideCollapsibleView frame]))];
    
    [rightSideCollapsibleView setCollapseEdges:BDSKMaxXEdgeMask | BDSKMinYEdgeMask];
    [rightSideCollapsibleView setMinSize:NSMakeSize(111.0, NSHeight([rightSideCollapsibleView frame]))];
    
    [pdfEdgeView setEdges:BDSKMinXEdgeMask | BDSKMaxXEdgeMask | BDSKMinYEdgeMask];
    [leftSideEdgeView setEdges:BDSKMinXEdgeMask | BDSKMaxXEdgeMask];
    [rightSideEdgeView setEdges:BDSKMinXEdgeMask | BDSKMaxXEdgeMask];
    
    [pdfSplitView setFrame:[pdfContentView bounds]];
    [pdfContentView addSubview:pdfSplitView];
    
    if (mwcFlags.usesDrawers == 0 || floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_4) {
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
    [pdfContentView setAutoresizesSubviews:YES];
    [pdfEdgeView setAutoresizesSubviews:YES];
    
    [leftSideView setFrame:[leftSideContentView bounds]];
    [leftSideContentView addSubview:leftSideView];
    [rightSideView setFrame:[rightSideContentView bounds]];
    [rightSideContentView addSubview:rightSideView];
    
    NSMenu *menu = [[[NSMenu allocWithZone:[NSMenu menuZone]] init] autorelease];
    [menu addItemWithTitle:NSLocalizedString(@"Whole Words Only", @"Menu item title") action:@selector(toggleWholeWordSearch:) target:self];
    [menu addItemWithTitle:NSLocalizedString(@"Ignore Case", @"Menu item title") action:@selector(toggleCaseInsensitiveSearch:) target:self];
    [[searchField cell] setSearchMenuTemplate:menu];
    [[searchField cell] setPlaceholderString:NSLocalizedString(@"Search", @"placeholder")];
    
    menu = [[[NSMenu allocWithZone:[NSMenu menuZone]] init] autorelease];
    [menu addItemWithTitle:NSLocalizedString(@"Ignore Case", @"Menu item title") action:@selector(toggleCaseInsensitiveNoteSearch:) target:self];
    [[noteSearchField cell] setSearchMenuTemplate:menu];
    [[noteSearchField cell] setPlaceholderString:NSLocalizedString(@"Search", @"placeholder")];
    
    [[[noteOutlineView tableColumnWithIdentifier:NOTE_COLUMNID] headerCell] setTitle:NSLocalizedString(@"Note", @"Table header title")];
    [[[noteOutlineView tableColumnWithIdentifier:PAGE_COLUMNID] headerCell] setTitle:NSLocalizedString(@"Page", @"Table header title")];
    [[[findTableView tableColumnWithIdentifier:PAGE_COLUMNID] headerCell] setTitle:NSLocalizedString(@"Page", @"Table header title")];
    [[[groupedFindTableView tableColumnWithIdentifier:PAGE_COLUMNID] headerCell] setTitle:NSLocalizedString(@"Page", @"Table header title")];
    
    [noteOutlineView setDoubleAction:@selector(selectSelectedNote:)];
    [noteOutlineView setTarget:self];
    [outlineView setDoubleAction:@selector(goToSelectedOutlineItem:)];
    [outlineView setTarget:self];
    [snapshotTableView setDoubleAction:@selector(toggleSelectedSnapshots:)];
    [snapshotTableView setTarget:self];
    [findTableView setDoubleAction:@selector(goToSelectedFindResults:)];
    [findTableView setTarget:self];
    [groupedFindTableView setDoubleAction:@selector(goToSelectedFindResults:)];
    [groupedFindTableView setTarget:self];
    
    [pdfView setFrame:[[pdfEdgeView contentView] bounds]];
    
    if (mwcFlags.usesDrawers) {
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
        [pdfContentView setFrame:[splitView bounds]];
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
    
    NSInteger windowSizeOption = [sud integerForKey:SKInitialWindowSizeOptionKey];
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
    
    NSNumber *leftWidth = [savedNormalSetup objectForKey:LEFTSIDEPANEWIDTH_KEY] ?: [sud objectForKey:SKLeftSidePaneWidthKey];
    NSNumber *rightWidth = [savedNormalSetup objectForKey:RIGHTSIDEPANEWIDTH_KEY] ?: [sud objectForKey:SKRightSidePaneWidthKey];
    
    if (leftWidth && rightWidth)
        [self applyLeftSideWidth:[leftWidth floatValue] rightSideWidth:[rightWidth floatValue]];
    
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
    [[[groupedFindTableView tableColumnWithIdentifier:RELEVANCE_COLUMNID] dataCell] setEnabled:NO];
        
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
    NSUInteger pageIndex = NSNotFound;
    if (hasWindowSetup)
        pageIndex = [[savedNormalSetup objectForKey:PAGEINDEX_KEY] unsignedIntValue];
    else if ([sud boolForKey:SKRememberLastPageViewedKey])
        pageIndex = [[SKBookmarkController sharedBookmarkController] pageIndexForRecentDocumentAtPath:[[[self document] fileURL] path]];
    if (pageIndex != NSNotFound && [[pdfView document] pageCount] > pageIndex)
        [pdfView goToPage:[[pdfView document] pageAtIndex:pageIndex]];
    
    // We can fit only after the PDF has been loaded
    if (windowSizeOption == SKFitWindowOption && hasWindowSetup == NO)
        [self performFit:self];
    
    // Open snapshots?
    NSArray *snapshotSetups = nil;
    if (hasWindowSetup)
        snapshotSetups = [savedNormalSetup objectForKey:SNAPSHOTS_KEY];
    else if ([sud boolForKey:SKRememberSnapshotsKey])
        snapshotSetups = [[SKBookmarkController sharedBookmarkController] snapshotsAtPath:[[[self document] fileURL] path]];
    if ([snapshotSetups count])
        [self showSnapshotsWithSetups:snapshotSetups];
    
    // typeSelectHelpers
    SKTypeSelectHelper *typeSelectHelper = [SKTypeSelectHelper typeSelectHelperWithMatchOption:SKFullStringMatch];
    [typeSelectHelper setMatchesImmediately:NO];
    [typeSelectHelper setCyclesSimilarResults:NO];
    [thumbnailTableView setTypeSelectHelper:typeSelectHelper];
    [pdfView setTypeSelectHelper:typeSelectHelper];
    [noteOutlineView setTypeSelectHelper:[SKTypeSelectHelper typeSelectHelperWithMatchOption:SKSubstringMatch]];
    [outlineView setTypeSelectHelper:[SKTypeSelectHelper typeSelectHelperWithMatchOption:SKSubstringMatch]];
    
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
    
    mwcFlags.settingUpWindow = 0;
}

- (void)applyLeftSideWidth:(CGFloat)leftSideWidth rightSideWidth:(CGFloat)rightSideWidth {
    NSRect frame;
    if (leftSideWidth >= 0.0) {
        frame = [leftSideContentView frame];
        frame.size.width = leftSideWidth;
        if (mwcFlags.usesDrawers == 0) {
            [leftSideContentView setFrame:frame];
        } else if (leftSideWidth > 0.0) {
            [leftSideDrawer setContentSize:frame.size];
            [leftSideDrawer openOnEdge:NSMinXEdge];
        } else {
            [leftSideDrawer close];
        }
    }
    if (rightSideWidth >= 0.0) {
        frame = [rightSideContentView frame];
        frame.size.width = rightSideWidth;
        if (mwcFlags.usesDrawers == 0) {
            frame.origin.x = NSMaxX([splitView bounds]) - rightSideWidth;
            [rightSideContentView setFrame:frame];
        } else if (rightSideWidth > 0.0) {
            [rightSideDrawer setContentSize:frame.size];
            [rightSideDrawer openOnEdge:NSMaxXEdge];
        } else {
            [rightSideDrawer close];
        }
    }
    if (mwcFlags.usesDrawers == 0) {
        frame = [pdfContentView frame];
        frame.size.width = NSWidth([splitView frame]) - NSWidth([leftSideContentView frame]) - NSWidth([rightSideContentView frame]) - 2 * [splitView dividerThickness];
        frame.origin.x = NSMaxX([leftSideContentView frame]) + [splitView dividerThickness];
        [pdfContentView setFrame:frame];
    }
}

- (void)applySetup:(NSDictionary *)setup{
    if ([self isWindowLoaded] == NO) {
        [savedNormalSetup setDictionary:setup];
    } else {
        
        NSString *rectString = [setup objectForKey:SKMainWindowFrameKey];
        if (rectString)
            [mainWindow setFrame:NSRectFromString([setup objectForKey:SKMainWindowFrameKey]) display:YES];
        
        NSNumber *leftWidth = [setup objectForKey:LEFTSIDEPANEWIDTH_KEY];
        NSNumber *rightWidth = [setup objectForKey:RIGHTSIDEPANEWIDTH_KEY];
        if (leftWidth && rightWidth)
            [self applyLeftSideWidth:[leftWidth floatValue] rightSideWidth:[rightWidth floatValue]];
        
        NSUInteger pageIndex = [[setup objectForKey:PAGEINDEX_KEY] unsignedIntValue];
        if (pageIndex != NSNotFound)
            [pdfView goToPage:[[pdfView document] pageAtIndex:pageIndex]];
        
        NSArray *snapshotSetups = [setup objectForKey:SNAPSHOTS_KEY];
        if ([snapshotSetups count])
            [self showSnapshotsWithSetups:snapshotSetups];
        
        if ([self isFullScreen] || [self isPresentation])
            [savedNormalSetup addEntriesFromDictionary:setup];
        else
            [self applyPDFSettings:setup];
    }
}

- (NSDictionary *)currentSetup {
    NSMutableDictionary *setup = [NSMutableDictionary dictionary];
    
    [setup setObject:NSStringFromRect([mainWindow frame]) forKey:SKMainWindowFrameKey];
    [setup setObject:[NSNumber numberWithFloat:[self leftSidePaneIsOpen] ? NSWidth([leftSideContentView frame]) : 0.0] forKey:LEFTSIDEPANEWIDTH_KEY];
    [setup setObject:[NSNumber numberWithFloat:[self rightSidePaneIsOpen] ? NSWidth([rightSideContentView frame]) : 0.0] forKey:RIGHTSIDEPANEWIDTH_KEY];
    [setup setObject:[NSNumber numberWithUnsignedInt:[[pdfView currentPage] pageIndex]] forKey:PAGEINDEX_KEY];
    if ([snapshots count])
        [setup setObject:[snapshots valueForKey:SKSnapshotCurrentSetupKey] forKey:SNAPSHOTS_KEY];
    if ([self isFullScreen] || [self isPresentation]) {
        [setup addEntriesFromDictionary:savedNormalSetup];
        [setup removeObjectsForKeys:[NSArray arrayWithObjects:HASHORIZONTALSCROLLER_KEY, HASVERTICALSCROLLER_KEY, AUTOHIDESSCROLLERS_KEY, nil]];
    } else {
        [setup addEntriesFromDictionary:[self currentPDFSettings]];
    }
    
    return setup;
}

- (void)applyPDFSettings:(NSDictionary *)setup {
    NSNumber *number;
    if (number = [setup objectForKey:SCALEFACTOR_KEY])
        [pdfView setScaleFactor:[number floatValue]];
    if (number = [setup objectForKey:AUTOSCALES_KEY])
        [pdfView setAutoScales:[number boolValue]];
    if (number = [setup objectForKey:DISPLAYPAGEBREAKS_KEY])
        [pdfView setDisplaysPageBreaks:[number boolValue]];
    if (number = [setup objectForKey:DISPLAYASBOOK_KEY])
        [pdfView setDisplaysAsBook:[number boolValue]];
    if (number = [setup objectForKey:DISPLAYMODE_KEY])
        [pdfView setDisplayMode:[number intValue]];
    if (number = [setup objectForKey:DISPLAYBOX_KEY])
        [pdfView setDisplayBox:[number intValue]];
}

- (NSDictionary *)currentPDFSettings {
    NSMutableDictionary *setup = [NSMutableDictionary dictionary];
    
    if ([self isPresentation]) {
        [setup setDictionary:savedNormalSetup];
        [setup removeObjectsForKeys:[NSArray arrayWithObjects:HASHORIZONTALSCROLLER_KEY, HASVERTICALSCROLLER_KEY, AUTOHIDESSCROLLERS_KEY, nil]];
    } else {
        [setup setObject:[NSNumber numberWithBool:[pdfView displaysPageBreaks]] forKey:DISPLAYPAGEBREAKS_KEY];
        [setup setObject:[NSNumber numberWithBool:[pdfView displaysAsBook]] forKey:DISPLAYASBOOK_KEY];
        [setup setObject:[NSNumber numberWithInt:[pdfView displayBox]] forKey:DISPLAYBOX_KEY];
        [setup setObject:[NSNumber numberWithFloat:[pdfView scaleFactor]] forKey:SCALEFACTOR_KEY];
        [setup setObject:[NSNumber numberWithBool:[pdfView autoScales]] forKey:AUTOSCALES_KEY];
        [setup setObject:[NSNumber numberWithInt:[pdfView displayMode]] forKey:DISPLAYMODE_KEY];
    }
    
    return setup;
}

#pragma mark UI updating

- (void)updateLeftStatus {
    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Page %ld of %ld", @"Status message"), (long)[self pageNumber], (long)[[pdfView document] pageCount]];
    [statusBar setLeftStringValue:message];
}

- (void)updateRightStatus {
    NSRect rect = [pdfView currentSelectionRect];
    CGFloat magnification = [pdfView currentMagnification];
    NSString *message;
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKDisplayNoteBoundsKey] && NSEqualRects(rect, NSZeroRect) && [pdfView activeAnnotation])
        rect = [[pdfView activeAnnotation] bounds];
    
    if (NSEqualRects(rect, NSZeroRect) == NO) {
        if ([statusBar rightState] == NSOnState) {
            BOOL useMetric = [[[NSLocale currentLocale] objectForKey:NSLocaleUsesMetricSystem] boolValue];
            NSString *units = useMetric ? @"cm" : @"in";
            CGFloat factor = useMetric ? 0.035277778 : 0.013888889;
            message = [NSString stringWithFormat:@"%.2f %C %.2f @ (%.2f, %.2f) %@", NSWidth(rect) * factor, MULTIPLICATION_SIGN_CHARACTER, NSHeight(rect) * factor, NSMinX(rect) * factor, NSMinY(rect) * factor, units];
        } else {
            message = [NSString stringWithFormat:@"%ld %C %ld @ (%ld, %ld) pt", (long)NSWidth(rect), MULTIPLICATION_SIGN_CHARACTER, (long)NSHeight(rect), (long)NSMinX(rect), (long)NSMinY(rect)];
        }
    } else if (magnification > 0.0001) {
        message = [NSString stringWithFormat:@"%.2f %C", magnification, MULTIPLICATION_SIGN_CHARACTER];
    } else {
        message = @"";
    }
    [statusBar setRightStringValue:message];
}

- (void)updatePageColumnWidthForTableView:(NSTableView *)tv {
    NSTableColumn *tableColumn = [tv tableColumnWithIdentifier:PAGE_COLUMNID];
    id cell = [tableColumn dataCell];
    CGFloat labelWidth = [tv headerView] ? [[tableColumn headerCell] cellSize].width : 0.0;
    NSEnumerator *labelEnum = [pageLabels objectEnumerator];
    NSString *label;
    
    while (label = [labelEnum nextObject]) {
        [cell setStringValue:label];
        labelWidth = SKMax(labelWidth, [cell cellSize].width);
    }
    
    [tableColumn setMinWidth:labelWidth];
    [tableColumn setMaxWidth:labelWidth];
    [tableColumn setWidth:labelWidth];
    [tv sizeToFit];
}

- (void)updatePageLabelsAndOutline {
    PDFDocument *pdfDoc = [pdfView document];
    NSUInteger i, count = [pdfDoc pageCount];
    
    // update page labels, also update the size of the table columns displaying the labels
    [self willChangeValueForKey:PAGELABELS_KEY];
    [pageLabels removeAllObjects];
    for (i = 0; i < count; i++)
        [pageLabels addObject:[[pdfDoc pageAtIndex:i] displayLabel]];
    [self didChangeValueForKey:PAGELABELS_KEY];
    
    [self updatePageLabel];
    
    [self updatePageColumnWidthForTableView:thumbnailTableView];
    [self updatePageColumnWidthForTableView:snapshotTableView];
    [self updatePageColumnWidthForTableView:outlineView];
    [self updatePageColumnWidthForTableView:noteOutlineView];
    [self updatePageColumnWidthForTableView:findTableView];
    [self updatePageColumnWidthForTableView:groupedFindTableView];
    
    // this uses the pageLabels
    [[thumbnailTableView typeSelectHelper] rebuildTypeSelectSearchCache];
    
    // these carry a label, moreover when this is called the thumbnails will also be invalid
    [self resetThumbnails];
    [self allSnapshotsNeedUpdate];
    [noteOutlineView reloadData];
    
    // update the outline
    [pdfOutline release];
    pdfOutline = [[SKPDFOutline alloc] initWithOutline:[pdfDoc outlineRoot] parent:nil];
    
    mwcFlags.updatingOutlineSelection = 1;
    // If this is a reload following a TeX run and the user just killed the outline for some reason, we get a crash if the outlineView isn't reloaded, so no longer make it conditional on pdfOutline != nil
    [outlineView reloadData];
	for (i = 0; i < (NSUInteger)[outlineView numberOfRows]; i++) {
		SKPDFOutline *item = [outlineView itemAtRow:i];
		if ([item isOpen])
			[outlineView expandItem:item];
	}
    mwcFlags.updatingOutlineSelection = 0;
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
        
        NSUInteger pageIndex = NSNotFound, secondaryPageIndex = NSNotFound;
        NSRect visibleRect = NSZeroRect, secondaryVisibleRect = NSZeroRect;
        NSArray *snapshotDicts = nil;
        
        if ([pdfView document]) {
            pageIndex = [[pdfView currentPage] pageIndex];
            visibleRect = [pdfView convertRect:[pdfView convertRect:[[pdfView documentView] visibleRect] fromView:[pdfView documentView]] toPage:[pdfView currentPage]];
            if (secondaryPdfView) {
                secondaryPageIndex = [[secondaryPdfView currentPage] pageIndex];
                secondaryVisibleRect = [secondaryPdfView convertRect:[secondaryPdfView convertRect:[[secondaryPdfView documentView] visibleRect] fromView:[secondaryPdfView documentView]] toPage:[secondaryPdfView currentPage]];
            }
            
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
        
        [self showSnapshotsWithSetups:snapshotDicts];
        
        if ([document pageCount] && (pageIndex != NSNotFound || secondaryPageIndex != NSNotFound)) {
            PDFPage *page = nil;
            PDFPage *secondaryPage = nil;
            if (pageIndex != NSNotFound) {
                page = [document pageAtIndex:MIN(pageIndex, [document pageCount] - 1)];
                [pdfView goToPage:page];
            }
            if (secondaryPageIndex != NSNotFound) {
                secondaryPage = [document pageAtIndex:MIN(secondaryPageIndex, [document pageCount] - 1)];
                [secondaryPdfView goToPage:secondaryPage];
            }
            [[pdfView window] disableFlushWindow];
            if (page) {
                [pdfView display];
                [[pdfView documentView] scrollRectToVisible:[pdfView convertRect:[pdfView convertRect:visibleRect fromPage:page] toView:[pdfView documentView]]];
            }
            if (secondaryPage) {
                if ([secondaryPdfView window])
                    [secondaryPdfView display];
                [[secondaryPdfView documentView] scrollRectToVisible:[secondaryPdfView convertRect:[secondaryPdfView convertRect:secondaryVisibleRect fromPage:secondaryPage] toView:[secondaryPdfView documentView]]];
            }
            [[pdfView window] enableFlushWindow];
            [[pdfView window] flushWindowIfNeeded];
        }
        
        // the number of pages may have changed
        [self handleChangedHistoryNotification:nil];
        [self handlePageChangedNotification:nil];
        [self updateLeftStatus];
        [self updateRightStatus];
    }
}
    
- (void)addAnnotationsFromDictionaries:(NSArray *)noteDicts undoable:(BOOL)undoable{
    NSEnumerator *e = [noteDicts objectEnumerator];
    PDFAnnotation *annotation;
    NSDictionary *dict;
    PDFDocument *pdfDoc = [pdfView document];
    NSMutableArray *observableNotes = [self mutableArrayValueForKey:NOTES_KEY];
    
    // create new annotations from the dictionary and add them to their page and to the document
    while (dict = [e nextObject]) {
        NSUInteger pageIndex = [[dict objectForKey:SKNPDFAnnotationPageIndexKey] unsignedIntValue];
        if (annotation = [[PDFAnnotation alloc] initSkimNoteWithProperties:dict]) {
            if (pageIndex == NSNotFound)
                pageIndex = 0;
            else if (pageIndex >= [pdfDoc pageCount])
                pageIndex = [pdfDoc pageCount] - 1;
            PDFPage *page = [pdfDoc pageAtIndex:pageIndex];
            [pdfView addAnnotation:annotation toPage:page undoable:undoable];
            // this is necessary for the initial load of the document, as the notification handler is not yet registered
            if ([observableNotes containsObject:annotation] == NO)
                [observableNotes addObject:annotation];
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
    while (annotation = [e nextObject])
        [pdfView removeAnnotation:annotation undoable:undoable];
    
    [self addAnnotationsFromDictionaries:noteDicts undoable:undoable];
}


- (void)setOpenMetaTags:(NSArray *)newTags {
    if (tags != newTags) {
        [tags release];
        tags = [newTags retain] ?: [[NSArray alloc] init];
    }
}

- (void)setOpenMetaRating:(double)newRating {
    rating = newRating;
}

- (SKPDFView *)pdfView {
    return pdfView;
}

- (void)updatePageNumber {
    NSUInteger number = [[pdfView currentPage] pageIndex] + 1;
    if (pageNumber != number) {
        [self willChangeValueForKey:PAGENUMBER_KEY];
        pageNumber = number;
        [self didChangeValueForKey:PAGENUMBER_KEY];
    }
}

- (NSUInteger)pageNumber {
    return pageNumber;
}

- (void)setPageNumber:(NSUInteger)number {
    // Check that the page number exists
    NSUInteger pageCount = [[pdfView document] pageCount];
    if (number > pageCount)
        number = pageCount;
    if (number > 0 && [[pdfView currentPage] pageIndex] != number - 1)
        [self goToPage:[[pdfView document] pageAtIndex:number - 1]];
}

- (void)updatePageLabel {
    NSString *label = [[pdfView currentPage] displayLabel];
    if (label != pageLabel) {
        [self willChangeValueForKey:PAGELABEL_KEY];
        [pageLabel release];
        pageLabel = [label retain];
        [self didChangeValueForKey:PAGELABEL_KEY];
    }
}

- (NSString *)pageLabel {
    return pageLabel;
}

- (void)setPageLabel:(NSString *)label {
    NSUInteger idx = [pageLabels indexOfObject:label];
    if (idx != NSNotFound && [[[pdfView currentPage] displayLabel] isEqual:label] == NO)
        [self goToPage:[[pdfView document] pageAtIndex:idx]];
}

- (BOOL)validatePageLabel:(id *)value error:(NSError **)error {
    if ([pageLabels indexOfObject:*value] == NSNotFound)
        *value = [self pageLabel];
    return YES;
}

- (BOOL)isFullScreen {
    return [self window] == fullScreenWindow && mwcFlags.isPresentation == 0;
}

- (BOOL)isPresentation {
    return mwcFlags.isPresentation;
}

- (BOOL)autoScales {
    return [pdfView autoScales];
}

- (SKLeftSidePaneState)leftSidePaneState {
    return mwcFlags.leftSidePaneState;
}

- (void)setLeftSidePaneState:(SKLeftSidePaneState)newLeftSidePaneState {
    if (mwcFlags.leftSidePaneState != newLeftSidePaneState) {
        mwcFlags.leftSidePaneState = newLeftSidePaneState;
        
        if ([searchField stringValue] && [[searchField stringValue] isEqualToString:@""] == NO) {
            [searchField setStringValue:@""];
            [self removeTemporaryAnnotations];
        }
        
        if (mwcFlags.leftSidePaneState == SKThumbnailSidePaneState)
            [self displayThumbnailView];
        else if (mwcFlags.leftSidePaneState == SKOutlineSidePaneState)
            [self displayOutlineView];
    }
}

- (SKRightSidePaneState)rightSidePaneState {
    return mwcFlags.rightSidePaneState;
}

- (void)setRightSidePaneState:(SKRightSidePaneState)newRightSidePaneState {
    if (mwcFlags.rightSidePaneState != newRightSidePaneState) {
        mwcFlags.rightSidePaneState = newRightSidePaneState;
        
        if (mwcFlags.rightSidePaneState == SKNoteSidePaneState)
            [self displayNoteView];
        else if (mwcFlags.rightSidePaneState == SKSnapshotSidePaneState)
            [self displaySnapshotView];
    }
}

- (SKFindPaneState)findPaneState {
    return mwcFlags.findPaneState;
}

- (void)setFindPaneState:(SKFindPaneState)newFindPaneState {
    if (mwcFlags.findPaneState != newFindPaneState) {
        mwcFlags.findPaneState = newFindPaneState;
        
        if (mwcFlags.findPaneState == SKSingularFindPaneState) {
            if ([groupedFindView window])
                [self displaySearchView];
        } else if (mwcFlags.findPaneState == SKGroupedFindPaneState) {
            if ([findView window])
                [self displayGroupedSearchView];
        }
        [self updateFindResultHighlights:YES];
    }
}

- (BOOL)leftSidePaneIsOpen {
    NSInteger state;
    if ([self isFullScreen])
        state = [leftSideWindow state];
    else if (mwcFlags.usesDrawers)
        state = [leftSideDrawer state];
    else
        state = NSWidth([leftSideContentView frame]) > 0.0 ? NSDrawerOpenState : NSDrawerClosedState;
    return state == NSDrawerOpenState || state == NSDrawerOpeningState;
}

- (BOOL)rightSidePaneIsOpen {
    NSInteger state;
    if ([self isFullScreen])
        state = [rightSideWindow state];
    else if (mwcFlags.usesDrawers)
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
	 
- (NSUInteger)countOfNotes {
    return [notes count];
}

- (PDFAnnotation *)objectInNotesAtIndex:(NSUInteger)theIndex {
    return [notes objectAtIndex:theIndex];
}

- (void)insertObject:(PDFAnnotation *)note inNotesAtIndex:(NSUInteger)theIndex {
    [notes insertObject:note atIndex:theIndex];

    // Start observing the just-inserted notes so that, when they're changed, we can record undo operations.
    [self startObservingNotes:[NSArray arrayWithObject:note]];
}

- (void)removeObjectFromNotesAtIndex:(NSUInteger)theIndex {
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
        [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:NOTES_KEY];
        
        NSEnumerator *wcEnum = [[[self document] windowControllers] objectEnumerator];
        NSWindowController *wc = [wcEnum nextObject];
        while (wc = [wcEnum nextObject]) {
            if ([wc isNoteWindowController])
                [[wc window] orderOut:self];
        }
        
        CFDictionaryRemoveAllValues(rowHeights);
        
        [self stopObservingNotes:notes];

        [notes removeAllObjects];
        
        [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:NOTES_KEY];
        [noteOutlineView reloadData];
    }
}

- (NSArray *)thumbnails {
    return [[thumbnails copy] autorelease];
}

- (NSUInteger)countOfThumbnails {
    return [thumbnails count];
}

- (SKThumbnail *)objectInThumbnailsAtIndex:(NSUInteger)theIndex {
    return [thumbnails objectAtIndex:theIndex];
}

- (void)insertObject:(SKThumbnail *)thumbnail inThumbnailsAtIndex:(NSUInteger)theIndex {
    [thumbnails insertObject:thumbnail atIndex:theIndex];
}

- (void)removeObjectFromThumbnailsAtIndex:(NSUInteger)theIndex {
    [thumbnails removeObjectAtIndex:theIndex];
}

- (void)removeAllObjectsFromThumbnails {
    if ([thumbnails count]) {
        // cancel all delayed perform requests for makeImageForThumbnail:
        [[self class] cancelPreviousPerformRequestsWithTarget:self];
        NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [thumbnails count])];
        [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:THUMBNAILS_KEY];
        [thumbnails removeAllObjects];
        [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:THUMBNAILS_KEY];
    }
}

- (NSArray *)snapshots {
    return [[snapshots copy] autorelease];
}

- (NSUInteger)countOfSnapshots {
    return [snapshots count];
}

- (SKSnapshotWindowController *)objectInSnapshotsAtIndex:(NSUInteger)theIndex {
    return [snapshots objectAtIndex:theIndex];
}

- (void)insertObject:(SKSnapshotWindowController *)snapshot inSnapshotsAtIndex:(NSUInteger)theIndex {
    [snapshots insertObject:snapshot atIndex:theIndex];
}

- (void)removeObjectFromSnapshotsAtIndex:(NSUInteger)theIndex {
    [dirtySnapshots removeObject:[snapshots objectAtIndex:theIndex]];
    [snapshots removeObjectAtIndex:theIndex];
}

- (void)removeAllObjectsFromSnapshots {
    if ([snapshots count]) {
        NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [snapshots count])];
        [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:SNAPSHOTS_KEY];
        
        [dirtySnapshots removeAllObjects];
        
        [snapshots removeAllObjects];
        
        [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:SNAPSHOTS_KEY];
    }
}

- (NSArray *)selectedNotes {
    NSMutableArray *selectedNotes = [NSMutableArray array];
    NSIndexSet *rowIndexes = [noteOutlineView selectedRowIndexes];
    NSUInteger row = [rowIndexes firstIndex];
    id item = nil;
    while (row != NSNotFound) {
        item = [noteOutlineView itemAtRow:row];
        if ([item type] == nil)
            item = [(SKNoteText *)item note];
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

- (NSUInteger)countOfSearchResults {
    return [searchResults count];
}

- (PDFSelection *)objectInSearchResultsAtIndex:(NSUInteger)theIndex {
    return [searchResults objectAtIndex:theIndex];
}

- (void)insertObject:(PDFSelection *)searchResult inSearchResultsAtIndex:(NSUInteger)theIndex {
    [searchResults insertObject:searchResult atIndex:theIndex];
}

- (void)removeObjectFromSearchResultsAtIndex:(NSUInteger)theIndex {
    [searchResults removeObjectAtIndex:theIndex];
}

- (NSArray *)groupedSearchResults {
    return [[groupedSearchResults copy] autorelease];
}

- (void)setGroupedSearchResults:(NSArray *)newGroupedSearchResults {
    [groupedSearchResults setArray:newGroupedSearchResults];
}

- (NSUInteger)countOfGroupedSearchResults {
    return [groupedSearchResults count];
}

- (SKGroupedSearchResult *)objectInGroupedSearchResultsAtIndex:(NSUInteger)theIndex {
    return [groupedSearchResults objectAtIndex:theIndex];
}

- (void)insertObject:(SKGroupedSearchResult *)groupedSearchResult inGroupedSearchResultsAtIndex:(NSUInteger)theIndex {
    [groupedSearchResults insertObject:groupedSearchResult atIndex:theIndex];
}

- (void)removeObjectFromGroupedSearchResultsAtIndex:(NSUInteger)theIndex {
    [groupedSearchResults removeObjectAtIndex:theIndex];
}

- (NSDictionary *)presentationOptions {
    SKTransitionController *transitions = [pdfView transitionController];
    SKAnimationTransitionStyle style = [transitions transitionStyle];
    NSString *styleName = [SKTransitionController nameForStyle:style];
    NSArray *pageTransitions = [transitions pageTransitions];
    NSMutableDictionary *options = nil;
    if ([styleName length] || [pageTransitions count]) {
        options = [NSMutableDictionary dictionary];
        [options setValue:(styleName ?: @"") forKey:@"styleName"];
        [options setValue:[NSNumber numberWithFloat:[transitions duration]] forKey:@"duration"];
        [options setValue:[NSNumber numberWithBool:[transitions shouldRestrict]] forKey:@"shouldRestrict"];
        [options setValue:pageTransitions forKey:@"pageTransitions"];
    }
    return options;
}

- (void)setPresentationOptions:(NSDictionary *)dictionary {
    SKTransitionController *transitions = [pdfView transitionController];
    NSString *styleName = [dictionary objectForKey:@"styleName"];
    NSNumber *duration = [dictionary objectForKey:@"duration"];
    NSNumber *shouldRestrict = [dictionary objectForKey:@"shouldRestrict"];
    NSArray *pageTransitions = [dictionary objectForKey:@"pageTransitions"];
    if (styleName)
        [transitions setTransitionStyle:[SKTransitionController styleForName:styleName]];
    if (duration)
        [transitions setDuration:[duration floatValue]];
    if (shouldRestrict)
        [transitions setShouldRestrict:[shouldRestrict boolValue]];
    [transitions setPageTransitions:pageTransitions];
}

- (SKPDFDocument *)presentationNotesDocument {
    return presentationNotesDocument;
}

- (void)setPresentationNotesDocument:(SKPDFDocument *)aDocument {
    if (presentationNotesDocument != aDocument) {
        [presentationNotesDocument release];
        presentationNotesDocument = [aDocument retain];
    }
}

- (NSArray *)tags {
    return tags;
}

- (double)rating {
    return rating;
}

#pragma mark Full Screen support

- (void)showLeftSideWindowOnScreen:(NSScreen *)screen {
    if (leftSideWindow == nil)
        leftSideWindow = [[SKSideWindow alloc] initWithMainController:self edge:NSMinXEdge];
    
    [leftSideWindow moveToScreen:screen];
    
    if ([[[leftSideView window] firstResponder] isDescendantOf:leftSideView])
        [[leftSideView window] makeFirstResponder:nil];
    [leftSideWindow setMainView:leftSideView];
    
    if (mwcFlags.usesDrawers == 0) {
        [leftSideEdgeView setEdges:BDSKNoEdgeMask];
    }
    
    if ([self isPresentation]) {
        mwcFlags.savedLeftSidePaneState = [self leftSidePaneState];
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
    
    if (mwcFlags.usesDrawers == 0) {
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
        
        if (mwcFlags.usesDrawers == 0) {
            [leftSideEdgeView setEdges:BDSKMinXEdgeMask | BDSKMaxXEdgeMask];
        }
        
        if ([self isPresentation]) {
            [self setLeftSidePaneState:mwcFlags.savedLeftSidePaneState];
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
        
        if (mwcFlags.usesDrawers == 0) {
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
    
    if ([SKSideWindow isAutoHideEnabled])
        [pdfSplitView setFrame:NSInsetRect([[pdfSplitView superview] bounds], 9.0, 0.0)];
    [[pdfSplitView superview] setNeedsDisplay:YES];
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
        [fullScreenWindow setExcludedFromWindowsMenu:NO];
    }
        
    // explicitly set window frame; screen may have moved, or may be nil (in which case [fullScreenWindow frame] is wrong, which is weird); the first time through this method, [fullScreenWindow screen] is nil
    [fullScreenWindow setFrame:[screen frame] display:NO];
    
    if ([[mainWindow firstResponder] isDescendantOf:pdfView])
        [mainWindow makeFirstResponder:nil];
    if ([self isPresentation]) {
        [fullScreenWindow setMainView:pdfView];
    } else {
        [fullScreenWindow setMainView:pdfSplitView];
        [pdfEdgeView setEdges:[secondaryPdfView window] ? BDSKMinYEdgeMask : BDSKNoEdgeMask];
        [secondaryPdfEdgeView setEdges:BDSKMaxYEdgeMask];
    }
    [fullScreenWindow setBackgroundColor:backgroundColor];
    [fullScreenWindow setLevel:[self isPresentation] ? NSPopUpMenuWindowLevel : NSNormalWindowLevel];
    [pdfView setBackgroundColor:backgroundColor];
    [secondaryPdfView setBackgroundColor:backgroundColor];
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
    [NSApp addWindowsItem:fullScreenWindow title:[self windowTitleForDocumentDisplayName:[[self document] displayName]] filename:NO];
}

- (void)saveNormalSetup {
    NSScrollView *scrollView = [[pdfView documentView] enclosingScrollView];
    [savedNormalSetup setDictionary:[self currentPDFSettings]];
    [savedNormalSetup setObject:[NSNumber numberWithBool:[scrollView hasHorizontalScroller]] forKey:HASHORIZONTALSCROLLER_KEY];
    [savedNormalSetup setObject:[NSNumber numberWithBool:[scrollView hasVerticalScroller]] forKey:HASVERTICALSCROLLER_KEY];
    [savedNormalSetup setObject:[NSNumber numberWithBool:[scrollView autohidesScrollers]] forKey:AUTOHIDESSCROLLERS_KEY];
}

- (void)activityTimerFired:(NSTimer *)timer {
    UpdateSystemActivity(UsrActivity);
}

- (void)enterPresentationMode {
    NSScrollView *scrollView = [[pdfView documentView] enclosingScrollView];
    if ([self isFullScreen] == NO)
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
    [secondaryPdfView setBackgroundColor:backgroundColor];
    [fullScreenWindow setBackgroundColor:backgroundColor];
    [fullScreenWindow setLevel:NSPopUpMenuWindowLevel];
    
    SKPDFView *notesPdfView = [[self presentationNotesDocument] pdfView];
    if (notesPdfView)
        [notesPdfView goToPage:[[notesPdfView document] pageAtIndex:[[pdfView currentPage] pageIndex]]];
    
    // periodically send a 'user activity' to prevent sleep mode and screensaver from being activated
    activityTimer = [[NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(activityTimerFired:) userInfo:NULL repeats:YES] retain];
    
    mwcFlags.isPresentation = 1;
}

- (void)exitPresentationMode {
    [activityTimer invalidate];
    [activityTimer release];
    activityTimer = nil;
    
    NSScrollView *scrollView = [[pdfView documentView] enclosingScrollView];
    [self applyPDFSettings:savedNormalSetup];
    [scrollView setHasHorizontalScroller:[[savedNormalSetup objectForKey:HASHORIZONTALSCROLLER_KEY] boolValue]];
    [scrollView setHasVerticalScroller:[[savedNormalSetup objectForKey:HASVERTICALSCROLLER_KEY] boolValue]];
    [scrollView setAutohidesScrollers:[[savedNormalSetup objectForKey:AUTOHIDESSCROLLERS_KEY] boolValue]];
    
    [self hideLeftSideWindow];
    
    mwcFlags.isPresentation = 0;
}

- (IBAction)enterFullScreen:(id)sender {
    if ([self isFullScreen])
        return;
    
    NSScreen *screen = [[self window] screen] ?: [NSScreen mainScreen]; // @@ screen: or should we use the main screen?
    if ([screen isEqual:[[NSScreen screens] objectAtIndex:0]])
        SetSystemUIMode(kUIModeAllHidden, kUIOptionAutoShowMenuBar);
    
    if ([self isPresentation]) {
        [self exitPresentationMode];
        [pdfView setFrame:[[pdfEdgeView contentView] bounds]];
        [pdfEdgeView addSubview:pdfView];
        [fullScreenWindow setMainView:pdfSplitView];
        [pdfEdgeView setEdges:[secondaryPdfView window] ? BDSKMinYEdgeMask : BDSKNoEdgeMask];
        [secondaryPdfEdgeView setEdges:BDSKMaxYEdgeMask];
    } else {
        [self saveNormalSetup];
        [self goFullScreen];
    }
    
    NSColor *backgroundColor = [[NSUserDefaults standardUserDefaults] colorForKey:SKFullScreenBackgroundColorKey];
    [pdfView setBackgroundColor:backgroundColor];
    [secondaryPdfView setBackgroundColor:backgroundColor];
    [fullScreenWindow setBackgroundColor:backgroundColor];
    [fullScreenWindow setLevel:NSNormalWindowLevel];
    
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
        SetSystemUIMode(kUIModeAllHidden, kUIOptionDisableProcessSwitch);
    else
        SetSystemUIMode(kUIModeNormal, kUIOptionDisableProcessSwitch);
    
    if (wasFullScreen) {
        [pdfSplitView setFrame:[pdfContentView bounds]];
        [pdfContentView addSubview:pdfSplitView];
        [pdfEdgeView setEdges:BDSKMinXEdgeMask | BDSKMaxXEdgeMask | BDSKMinYEdgeMask];
        [secondaryPdfEdgeView setEdges:BDSKEveryEdgeMask];
        [fullScreenWindow setMainView:pdfView];
        [self hideSideWindows];
    } else {
        [self goFullScreen];
    }
    
    [pdfView setInteractionMode:SKPresentationMode screen:screen];
}

- (IBAction)exitFullScreen:(id)sender {
    if ([self isFullScreen] == NO && [self isPresentation] == NO)
        return;

    if ([self isFullScreen])
        [self hideSideWindows];
    
    if ([[fullScreenWindow firstResponder] isDescendantOf:pdfView])
        [fullScreenWindow makeFirstResponder:nil];
    
    SKFullScreenWindow *bgWindow = [[SKFullScreenWindow alloc] initWithScreen:[fullScreenWindow screen]];
    [bgWindow setBackgroundColor:[fullScreenWindow backgroundColor]];
    [bgWindow setLevel:[fullScreenWindow level]];
    [bgWindow orderWindow:NSWindowBelow relativeTo:[fullScreenWindow windowNumber]];
    [fullScreenWindow setDelegate:nil];
    [fullScreenWindow fadeOutBlocking:YES];
    
    [pdfView setInteractionMode:SKNormalMode screen:[[self window] screen]];
    // this should be done before exitPresentationMode to get a smooth transition
    if ([self isFullScreen]) {
        [pdfSplitView setFrame:[pdfContentView bounds]];
        [pdfContentView addSubview:pdfSplitView];
        [pdfEdgeView setEdges:BDSKMinXEdgeMask | BDSKMaxXEdgeMask | BDSKMinYEdgeMask];
        [secondaryPdfEdgeView setEdges:BDSKEveryEdgeMask];
    } else {
        [pdfView setFrame:[[pdfEdgeView contentView] bounds]];
        [pdfEdgeView addSubview:pdfView]; 
    }
    [pdfView setBackgroundColor:[[NSUserDefaults standardUserDefaults] colorForKey:SKBackgroundColorKey]];
    [secondaryPdfView setBackgroundColor:[[NSUserDefaults standardUserDefaults] colorForKey:SKBackgroundColorKey]];
    [pdfView layoutDocumentView];
    
    if ([self isPresentation])
        [self exitPresentationMode];
    else
        [self applyPDFSettings:savedNormalSetup];
    
    [fullScreenWindow orderWindow:NSWindowBelow relativeTo:[bgWindow windowNumber]];
    [fullScreenWindow displayIfNeeded];
    [bgWindow orderOut:nil];
    [bgWindow release];
    [fullScreenWindow setLevel:NSPopUpMenuWindowLevel];
    
    SetSystemUIMode(kUIModeNormal, 0);
    
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
    [fullScreenWindow fadeOutBlocking:NO];
    [mainWindow makeFirstResponder:pdfView];
    [mainWindow recalculateKeyViewLoop];
    [mainWindow setDelegate:self];
    
    [blankingWindows makeObjectsPerformSelector:@selector(fadeOut)];
}

#pragma mark Swapping tables

- (void)replaceSideView:(NSView *)newView animate:(BOOL)animate {
    if ([newView window] == nil) {
        NSView *oldView = nil;
        if (newView == noteView || newView == snapshotView) {
            oldView = currentRightSideView;
            currentRightSideView = newView;
        } else {
            oldView = currentLeftSideView;
            currentLeftSideView = newView;
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
            mwcFlags.isAnimating = 1;
            [animation startAnimation];
            mwcFlags.isAnimating = 0;
            
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
    [self replaceSideView:tocView animate:NO];
    [self updateOutlineSelection];
}

- (void)fadeInOutlineView {
    [self replaceSideView:tocView animate:YES];
    [self updateOutlineSelection];
}

- (void)displayThumbnailView {
    [self replaceSideView:thumbnailView animate:NO];
    [self updateThumbnailSelection];
}

- (void)fadeInThumbnailView {
    [self replaceSideView:thumbnailView animate:YES];
    [self updateThumbnailSelection];
}

- (void)displaySearchView {
    [self replaceSideView:findView animate:NO];
}

- (void)fadeInSearchView {
    [self replaceSideView:findView animate:YES];
}

- (void)displayGroupedSearchView {
    [self replaceSideView:groupedFindView animate:NO];
}

- (void)fadeInGroupedSearchView {
    [self replaceSideView:groupedFindView animate:YES];
}

- (void)displayNoteView {
    [self replaceSideView:noteView animate:NO];
}

- (void)displaySnapshotView {
    [self replaceSideView:snapshotView animate:NO];
    [self updateSnapshotsIfNeeded];
}

#pragma mark Searching

- (void)temporaryAnnotationTimerFired:(NSTimer *)timer {
    [self removeTemporaryAnnotations];
}

- (void)addAnnotationsForSelection:(PDFSelection *)sel {
    NSArray *pages = [sel pages];
    NSInteger i, iMax = [pages count];
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
        if (mwcFlags.leftSidePaneState == SKThumbnailSidePaneState)
            [self fadeInThumbnailView];
        else 
            [self fadeInOutlineView];
    } else {
        NSInteger options = mwcFlags.caseInsensitiveSearch ? NSCaseInsensitiveSearch : 0;
        if (mwcFlags.wholeWordSearch && [[pdfView document] respondsToSelector:@selector(beginFindStrings:withOptions:)]) {
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
        if (mwcFlags.findPaneState == SKSingularFindPaneState)
            [self fadeInSearchView];
        else
            [self fadeInGroupedSearchView];
        
        NSPasteboard *findPboard = [NSPasteboard pasteboardWithName:NSFindPboard];
        [findPboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
        [findPboard setString:[sender stringValue] forType:NSStringPboardType];
    }
}

- (PDFSelection *)findString:(NSString *)string fromSelection:(PDFSelection *)selection withOptions:(NSInteger)options {
	mwcFlags.findPanelFind = 1;
    selection = [[pdfView document] findString:string fromSelection:selection withOptions:options];
	mwcFlags.findPanelFind = 0;
    return selection;
}

- (void)findString:(NSString *)string options:(NSInteger)options{
    PDFSelection *sel = [pdfView currentSelection];
    NSUInteger pageIndex = [[pdfView currentPage] pageIndex];
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

- (NSString *)findString {
    return [[[self pdfView] currentSelection] string];
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
    
    // arm:  PDFSelection is mutable, and using -addSelection on an object from selectedObjects will actually mutate the object in searchResults, which does bad things.
    PDFSelection *firstSel = [selE nextObject];
    PDFSelection *currentSel = [[firstSel copy] autorelease];
    
    while (sel = [selE nextObject])
        [currentSel addSelection:sel];
    
    if (scroll && firstSel) {
        PDFPage *page = [[currentSel pages] objectAtIndex:0];
        NSRect rect = NSIntersectionRect(NSInsetRect([currentSel boundsForPage:page], -50.0, -50.0), [page boundsForBox:kPDFDisplayBoxCropBox]);
        [pdfView scrollRect:rect inPageToVisible:page];
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

- (void)goToSelectedFindResults:(id)sender {
    [self updateFindResultHighlights:YES];
}

- (void)updateFindResultHighlights:(BOOL)scroll {
    NSArray *findResults = nil;
    
    if (mwcFlags.findPaneState == SKSingularFindPaneState && [findView window])
        findResults = [findArrayController selectedObjects];
    else if (mwcFlags.findPaneState == SKGroupedFindPaneState && [groupedFindView window])
        findResults = [[groupedFindArrayController selectedObjects] valueForKeyPath:@"@unionOfArrays.matches"];
    [self goToFindResults:findResults scrollToVisible:scroll];
}

- (IBAction)searchNotes:(id)sender {
    if ([[sender stringValue] length] && mwcFlags.rightSidePaneState != SKNoteSidePaneState)
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
    if (mwcFlags.findPanelFind == 0) {
        if (mwcFlags.wholeWordSearch) {
            PDFSelection *copy = [[instance copy] autorelease];
            NSString *string = [instance string];
            NSUInteger l = [string length];
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
        NSUInteger maxCount = [result maxCount];
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
    if (mwcFlags.findPanelFind == 0) {
        NSString *message = [NSLocalizedString(@"Searching", @"Message in search table header") stringByAppendingEllipsis];
        [findArrayController removeObjects:searchResults];
        [[[findTableView tableColumnWithIdentifier:RESULTS_COLUMNID] headerCell] setStringValue:message];
        [[findTableView headerView] setNeedsDisplay:YES];
        [[[groupedFindTableView tableColumnWithIdentifier:RELEVANCE_COLUMNID] headerCell] setStringValue:message];
        [[groupedFindTableView headerView] setNeedsDisplay:YES];
        [groupedFindArrayController removeObjects:groupedSearchResults];
        [statusBar setProgressIndicatorStyle:SKProgressIndicatorBarStyle];
        [[statusBar progressIndicator] setMaxValue:[[note object] pageCount]];
        [[statusBar progressIndicator] setDoubleValue:0.0];
        [statusBar startAnimation:self];
        [self willChangeValueForKey:SEARCHRESULTS_KEY];
        [self willChangeValueForKey:GROUPEDSEARCHRESULTS_KEY];
    }
}

- (void)documentDidEndDocumentFind:(NSNotification *)note {
    if (mwcFlags.findPanelFind == 0) {
        NSString *message = [NSString stringWithFormat:NSLocalizedString(@"%ld Results", @"Message in search table header"), (long)[searchResults count]];
        [self didChangeValueForKey:GROUPEDSEARCHRESULTS_KEY];
        [self didChangeValueForKey:SEARCHRESULTS_KEY];
        [[[findTableView tableColumnWithIdentifier:RESULTS_COLUMNID] headerCell] setStringValue:message];
        [[findTableView headerView] setNeedsDisplay:YES];
        [[[groupedFindTableView tableColumnWithIdentifier:RELEVANCE_COLUMNID] headerCell] setStringValue:message];
        [[groupedFindTableView headerView] setNeedsDisplay:YES];
        [statusBar stopAnimation:self];
        [statusBar setProgressIndicatorStyle:SKProgressIndicatorNone];
    }
}

- (void)documentDidEndPageFind:(NSNotification *)note {
    NSNumber *pageIndex = [[note userInfo] objectForKey:@"PDFDocumentPageIndex"];
    [[statusBar progressIndicator] setDoubleValue:[pageIndex doubleValue]];
    if ([pageIndex unsignedIntValue] % 50 == 0) {
        [self didChangeValueForKey:GROUPEDSEARCHRESULTS_KEY];
        [self didChangeValueForKey:SEARCHRESULTS_KEY];
        [self willChangeValueForKey:SEARCHRESULTS_KEY];
        [self willChangeValueForKey:GROUPEDSEARCHRESULTS_KEY];
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
        NSUInteger idx = [page pageIndex];
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
            NSInteger historyIndex = [[pdfView valueForKeyPath:@"pdfPriv.historyIndex"] intValue];
            if (historyIndex < (NSInteger)[destinationHistory count])
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

- (void)showSnapshotAtPageNumber:(NSInteger)pageNum forRect:(NSRect)rect scaleFactor:(CGFloat)scaleFactor autoFits:(BOOL)autoFits {
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

- (void)showSnapshotsWithSetups:(NSArray *)setups {
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

- (void)toggleSelectedSnapshots:(id)sender {
    // there should only be a single snapshot
    SKSnapshotWindowController *controller = [[snapshotArrayController selectedObjects] lastObject];
    
    if ([[controller window] isVisible])
        [controller miniaturize];
    else
        [controller deminiaturize];
}

- (void)snapshotControllerDidFinishSetup:(SKSnapshotWindowController *)controller {
    NSImage *image = [controller thumbnailWithSize:snapshotCacheSize];
    
    [controller setThumbnail:image];
    [[self mutableArrayValueForKey:SNAPSHOTS_KEY] addObject:controller];
}

- (void)snapshotControllerWindowWillClose:(SKSnapshotWindowController *)controller {
    [[self mutableArrayValueForKey:SNAPSHOTS_KEY] removeObject:controller];
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
    
    NSInteger row = [[snapshotArrayController arrangedObjects] indexOfObject:controller];
    
    [snapshotTableView scrollRowToVisible:row];
    
    NSRect rect = [snapshotTableView frameOfCellAtColumn:0 row:row];
    
    rect = [snapshotTableView convertRect:rect toView:nil];
    rect.origin = [[snapshotTableView window] convertBaseToScreen:rect.origin];
    
    return rect;
}

- (NSRect)snapshotControllerSourceRectForDeminiaturize:(SKSnapshotWindowController *)controller {
    [[self document] addWindowController:controller];
    
    NSInteger row = [[snapshotArrayController arrangedObjects] indexOfObject:controller];
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
        context:&SKMainWindowDefaultsObservationContext];
}

- (void)unregisterAsObserver {
    @try {
        [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeys:
            [NSArray arrayWithObjects:SKBackgroundColorKey, SKFullScreenBackgroundColorKey, 
                                      SKSearchHighlightColorKey, SKShouldHighlightSearchResultsKey, 
                                      SKThumbnailSizeKey, SKSnapshotThumbnailSizeKey, 
                                      SKShouldAntiAliasKey, SKGreekingThresholdKey, 
                                      SKTableFontSizeKey, nil]];
    }
    @catch (id e) {}
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
            [note addObserver:self forKeyPath:key options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:&SKNPDFAnnotationPropertiesObservationContext];
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
    if (context == &SKMainWindowDefaultsObservationContext) {
        
        // A default value that we are observing has changed
        NSString *key = [keyPath substringFromIndex:7];
        if ([key isEqualToString:SKBackgroundColorKey]) {
            if ([self isFullScreen] == NO && [self isPresentation] == NO) {
                [pdfView setBackgroundColor:[[NSUserDefaults standardUserDefaults] colorForKey:SKBackgroundColorKey]];
                [secondaryPdfView setBackgroundColor:[[NSUserDefaults standardUserDefaults] colorForKey:SKBackgroundColorKey]];
            }
        } else if ([key isEqualToString:SKFullScreenBackgroundColorKey]) {
            if ([self isFullScreen]) {
                NSColor *color = [[NSUserDefaults standardUserDefaults] colorForKey:SKFullScreenBackgroundColorKey];
                if (color) {
                    [pdfView setBackgroundColor:color];
                    [secondaryPdfView setBackgroundColor:color];
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
            [self updatePageColumnWidthForTableView:outlineView];
        }
        
    } else if (context == &SKNPDFAnnotationPropertiesObservationContext) {
        
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
            
            if ([keyPath isEqualToString:SKNPDFAnnotationBoundsKey] && [[NSUserDefaults standardUserDefaults] boolForKey:SKDisplayNoteBoundsKey]) {
                [self updateRightStatus];
            }
            
            // update the various panels if necessary
            if ([[self window] isMainWindow] && [note isEqual:[pdfView activeAnnotation]]) {
                if (mwcFlags.updatingColor == 0 && ([keyPath isEqualToString:SKNPDFAnnotationColorKey] || [keyPath isEqualToString:SKNPDFAnnotationInteriorColorKey])) {
                    mwcFlags.updatingColor = 1;
                    [[NSColorPanel sharedColorPanel] setColor:[note color]];
                    mwcFlags.updatingColor = 0;
                }
                if (mwcFlags.updatingFont == 0 && ([keyPath isEqualToString:SKNPDFAnnotationFontKey])) {
                    mwcFlags.updatingFont = 1;
                    [[NSFontManager sharedFontManager] setSelectedFont:[(PDFAnnotationFreeText *)note font] isMultiple:NO];
                    mwcFlags.updatingFont = 0;
                }
                if (mwcFlags.updatingFontAttributes == 0 && ([keyPath isEqualToString:SKNPDFAnnotationFontColorKey])) {
                    mwcFlags.updatingFontAttributes = 1;
                    [[NSFontManager sharedFontManager] setSelectedAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[(PDFAnnotationFreeText *)note fontColor], NSForegroundColorAttributeName, nil] isMultiple:NO];
                    mwcFlags.updatingFontAttributes = 0;
                }
                if (mwcFlags.updatingLine == 0 && ([keyPath isEqualToString:SKNPDFAnnotationBorderKey] || [keyPath isEqualToString:SKNPDFAnnotationStartLineStyleKey] || [keyPath isEqualToString:SKNPDFAnnotationEndLineStyleKey])) {
                    mwcFlags.updatingLine = 1;
                    [[SKLineInspector sharedLineInspector] setAnnotationStyle:note];
                    mwcFlags.updatingLine = 0;
                }
            }
        }

    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark Outline

- (NSInteger)outlineRowForPageIndex:(NSUInteger)pageIndex {
    if (pdfOutline == nil)
        return -1;
    
	NSInteger i, numRows = [outlineView numberOfRows];
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
	if (pdfOutline == nil || mwcFlags.updatingOutlineSelection)
		return;
	
	// Get index of current page.
	NSUInteger pageIndex = [[pdfView currentPage] pageIndex];
    
	// Test that the current selection is still valid.
	NSInteger row = [outlineView selectedRow];
    if (row == -1 || [[[[outlineView itemAtRow:row] destination] page] pageIndex] != pageIndex) {
        row = [self outlineRowForPageIndex:pageIndex];
        if (row != -1) {
            mwcFlags.updatingOutlineSelection = 1;
            [outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
            mwcFlags.updatingOutlineSelection = 0;
        }
    }
}

#pragma mark Thumbnails

- (void)makeImageForThumbnail:(SKThumbnail *)thumbnail {
    NSSize newSize, oldSize = [thumbnail size];
    PDFDocument *pdfDoc = [pdfView document];
    PDFPage *page = [pdfDoc pageAtIndex:[thumbnail pageIndex]];
    NSRect readingBarRect = [[[pdfView readingBar] page] isEqual:page] ? [[pdfView readingBar] currentBoundsForBox:[pdfView displayBox]] : NSZeroRect;
    NSImage *image = [page thumbnailWithSize:thumbnailCacheSize forBox:[pdfView displayBox] readingBarRect:readingBarRect];
    
    [thumbnail setImage:image];
    
    newSize = [image size];
    if (SKAbs(newSize.width - oldSize.width) > 1.0 || SKAbs(newSize.height - oldSize.height) > 1.0)
        [thumbnailTableView noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:[thumbnail pageIndex]]];
}

- (BOOL)generateImageForThumbnail:(SKThumbnail *)thumbnail {
    if (mwcFlags.isAnimating || [thumbnailTableView isScrolling] || [[pdfView document] isLocked] || [presentationSheetController isScrolling])
        return NO;
    [self performSelector:@selector(makeImageForThumbnail:) withObject:thumbnail afterDelay:0.0];
    return YES;
}

- (void)updateThumbnailSelection {
	// Get index of current page.
	NSUInteger pageIndex = [[pdfView currentPage] pageIndex];
    mwcFlags.updatingThumbnailSelection = 1;
    [thumbnailTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:pageIndex] byExtendingSelection:NO];
    [thumbnailTableView scrollRowToVisible:pageIndex];
    mwcFlags.updatingThumbnailSelection = 0;
}

- (void)resetThumbnails {
    NSUInteger i, count = [pageLabels count];
    // cancel all delayed perform requests for makeImageForThumbnail:
    [[self class] cancelPreviousPerformRequestsWithTarget:self];
    [self willChangeValueForKey:THUMBNAILS_KEY];
    [thumbnails removeAllObjects];
    if (count) {
        PDFPage *firstPage = [[pdfView document] pageAtIndex:0];
        PDFPage *emptyPage = [[[PDFPage alloc] init] autorelease];
        [emptyPage setBounds:[firstPage boundsForBox:kPDFDisplayBoxCropBox] forBox:kPDFDisplayBoxCropBox];
        [emptyPage setBounds:[firstPage boundsForBox:kPDFDisplayBoxMediaBox] forBox:kPDFDisplayBoxMediaBox];
        [emptyPage setRotation:[firstPage rotation]];
        NSImage *image = [emptyPage thumbnailWithSize:thumbnailCacheSize forBox:[pdfView displayBox]];
        [image lockFocus];
        NSRect imgRect = NSZeroRect;
        imgRect.size = [image size];
        CGFloat width = 0.8 * SKMin(NSWidth(imgRect), NSHeight(imgRect));
        imgRect = NSInsetRect(imgRect, 0.5 * (NSWidth(imgRect) - width), 0.5 * (NSHeight(imgRect) - width));
        [[NSImage imageNamed:@"NSApplicationIcon"] drawInRect:imgRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:0.5];
        [image unlockFocus];
        
        for (i = 0; i < count; i++) {
            SKThumbnail *thumbnail = [[SKThumbnail alloc] initWithImage:image label:[pageLabels objectAtIndex:i] pageIndex:i];
            [thumbnail setDelegate:self];
            [thumbnail setDirty:YES];
            [thumbnails addObject:thumbnail];
            [thumbnail release];
        }
    }
    [self didChangeValueForKey:THUMBNAILS_KEY];
    [self allThumbnailsNeedUpdate];
}

- (void)resetThumbnailSizeIfNeeded {
    roundedThumbnailSize = SKRound([[NSUserDefaults standardUserDefaults] floatForKey:SKThumbnailSizeKey]);

    CGFloat defaultSize = roundedThumbnailSize;
    CGFloat thumbnailSize = (defaultSize < 32.1) ? 32.0 : (defaultSize < 64.1) ? 64.0 : (defaultSize < 128.1) ? 128.0 : 256.0;
    
    if (SKAbs(thumbnailSize - thumbnailCacheSize) > 0.1) {
        thumbnailCacheSize = thumbnailSize;
        
        if ([self countOfThumbnails])
            [self allThumbnailsNeedUpdate];
    }
}

- (void)updateThumbnailAtPageIndex:(NSUInteger)anIndex {
    SKThumbnail *tn = [self objectInThumbnailsAtIndex:anIndex];
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(makeImageForThumbnail:) object:tn];
    [tn setDirty:YES];
    [thumbnailTableView reloadData];
}

- (void)allThumbnailsNeedUpdate {
    NSEnumerator *te = [thumbnails objectEnumerator];
    SKThumbnail *tn;
    while (tn = [te nextObject]) {
        [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(makeImageForThumbnail:) object:tn];
        [tn setDirty:YES];
    }
    [thumbnailTableView reloadData];
}

#pragma mark Notes

- (void)updateNoteSelection {

    NSArray *orderedNotes = [noteArrayController arrangedObjects];
    PDFAnnotation *annotation, *selAnnotation = nil;
    NSUInteger pageIndex = [[pdfView currentPage] pageIndex];
	NSInteger i, count = [orderedNotes count];
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
        mwcFlags.updatingNoteSelection = 1;
        [noteOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:[noteOutlineView rowForItem:selAnnotation]] byExtendingSelection:NO];
        mwcFlags.updatingNoteSelection = 0;
    }
}

- (void)updateNoteFilterPredicate {
    [noteArrayController setFilterPredicate:[noteOutlineView filterPredicateForSearchString:[noteSearchField stringValue] caseInsensitive:mwcFlags.caseInsensitiveNoteSearch]];
    [noteOutlineView reloadData];
}

#pragma mark Snapshots

- (void)resetSnapshotSizeIfNeeded {
    roundedSnapshotThumbnailSize = SKRound([[NSUserDefaults standardUserDefaults] floatForKey:SKSnapshotThumbnailSizeKey]);
    CGFloat defaultSize = roundedSnapshotThumbnailSize;
    CGFloat snapshotSize = (defaultSize < 32.1) ? 32.0 : (defaultSize < 64.1) ? 64.0 : (defaultSize < 128.1) ? 128.0 : 256.0;
    
    if (SKAbs(snapshotSize - snapshotCacheSize) > 0.1) {
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
        if (SKAbs(newSize.width - oldSize.width) > 1.0 || SKAbs(newSize.height - oldSize.height) > 1.0) {
            NSUInteger idx = [[snapshotArrayController arrangedObjects] indexOfObject:controller];
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
