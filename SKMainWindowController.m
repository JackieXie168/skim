//
//  SKMainWindowController.m
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

#import "SKMainWindowController.h"
#import "SKMainToolbarController.h"
#import "SKMainWindowController_UI.h"
#import "SKMainWindowController_Actions.h"
#import "SKLeftSideViewController.h"
#import "SKRightSideViewController.h"
#import <Quartz/Quartz.h>
#import "SKStringConstants.h"
#import "SKNoteWindowController.h"
#import "SKInfoWindowController.h"
#import "SKBookmarkController.h"
#import "SKFullScreenWindow.h"
#import "SKNavigationWindow.h"
#import "SKSideWindow.h"
#import "PDFPage_SKExtensions.h"
#import "SKMainDocument.h"
#import "SKThumbnail.h"
#import "SKPDFView.h"
#import <SkimNotes/SkimNotes.h>
#import "PDFAnnotation_SKExtensions.h"
#import "SKNPDFAnnotationNote_SKExtensions.h"
#import "SKNoteText.h"
#import "SKSplitView.h"
#import "NSScrollView_SKExtensions.h"
#import "NSBezierPath_SKExtensions.h"
#import "NSUserDefaultsController_SKExtensions.h"
#import "NSUserDefaults_SKExtensions.h"
#import "SKOutlineView.h"
#import "SKTocOutlineView.h"
#import "SKNoteOutlineView.h"
#import "SKTableView.h"
#import "SKThumbnailTableView.h"
#import "SKFindTableView.h"
#import "SKNoteTypeSheetController.h"
#import "SKAnnotationTypeImageCell.h"
#import "NSWindowController_SKExtensions.h"
#import "SKImageToolTipWindow.h"
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
#import "SKColorSwatch.h"
#import "SKApplicationController.h"
#import "NSSegmentedControl_SKExtensions.h"
#import "NSImage_SKExtensions.h"
#import "NSMenu_SKExtensions.h"
#import "SKGroupedSearchResult.h"
#import "HIDRemote.h"
#import "NSView_SKExtensions.h"
#import "NSResponder_SKExtensions.h"
#import "PDFOutline_SKExtensions.h"
#import "NSPointerArray_SKExtensions.h"
#import "SKFloatMapTable.h"
#import "SKColorCell.h"
#import "PDFDocument_SKExtensions.h"
#import "SKPDFPage.h"
#import "NSScreen_SKExtensions.h"
#import "PDFView_SKExtensions.h"
#import "NSScanner_SKExtensions.h"
#import "SKCenteredTextFieldCell.h"
#import "SKAccessibilityFauxUIElement.h"

#define MULTIPLICATION_SIGN_CHARACTER (unichar)0x00d7

#define PRESENTATION_SIDE_WINDOW_ALPHA 0.95

#define TINY_SIZE  32.0
#define SMALL_SIZE 64.0
#define LARGE_SIZE 128.0
#define HUGE_SIZE  256.0
#define FUDGE_SIZE 0.1

#define PAGELABELS_KEY              @"pageLabels"
#define SEARCHRESULTS_KEY           @"searchResults"
#define GROUPEDSEARCHRESULTS_KEY    @"groupedSearchResults"
#define NOTES_KEY                   @"notes"
#define THUMBNAILS_KEY              @"thumbnails"
#define SNAPSHOTS_KEY               @"snapshots"

#define PAGE_COLUMNID   @"page"
#define COLOR_COLUMNID  @"color"
#define AUTHOR_COLUMNID @"author"
#define DATE_COLUMNID   @"date"

#define RELEVANCE_COLUMNID  @"relevance"
#define RESULTS_COLUMNID    @"results"

#define PAGENUMBER_KEY  @"pageNumber"
#define PAGELABEL_KEY   @"pageLabel"

#define CONTENTVIEW_KEY @"contentView"
#define BUTTONVIEW_KEY @"buttonView"
#define FIRSTRESPONDER_KEY @"firstResponder"

#define SKMainWindowFrameKey        @"windowFrame"
#define LEFTSIDEPANEWIDTH_KEY       @"leftSidePaneWidth"
#define RIGHTSIDEPANEWIDTH_KEY      @"rightSidePaneWidth"
#define SCALEFACTOR_KEY             @"scaleFactor"
#define AUTOSCALES_KEY              @"autoScales"
#define DISPLAYSPAGEBREAKS_KEY      @"displaysPageBreaks"
#define DISPLAYSASBOOK_KEY          @"displaysAsBook" 
#define DISPLAYMODE_KEY             @"displayMode"
#define DISPLAYBOX_KEY              @"displayBox"
#define HASHORIZONTALSCROLLER_KEY   @"hasHorizontalScroller"
#define HASVERTICALSCROLLER_KEY     @"hasVerticalScroller"
#define AUTOHIDESSCROLLERS_KEY      @"autoHidesScrollers"
#define PAGEINDEX_KEY               @"pageIndex"

#define PAGETRANSITIONS_KEY @"pageTransitions"

#define SKMainWindowFrameAutosaveName @"SKMainWindow"

static char SKPDFAnnotationPropertiesObservationContext;

static char SKMainWindowDefaultsObservationContext;

#define SKLeftSidePaneWidthKey @"SKLeftSidePaneWidth"
#define SKRightSidePaneWidthKey @"SKRightSidePaneWidth"

#define SKUsesDrawersKey @"SKUsesDrawers"

#define SKDisplayNoteBoundsKey @"SKDisplayNoteBounds"

#define SKDisableTableToolTipsKey @"SKDisableTableToolTips"

#define SKUseSettingsFromPDFKey @"SKUseSettingsFromPDF"

static void addSideSubview(NSView *view, NSView *contentView, BOOL usesDrawers) {
    NSRect rect = [contentView bounds];
    if (usesDrawers == 0) {
        rect = NSInsetRect(rect, -1, -1);
        rect.size.height -= 1;
    }
    [view setFrame:rect];
    [contentView addSubview:view];
}

@interface SKMainWindowController (SKPrivate)

- (void)applyLeftSideWidth:(CGFloat)leftSideWidth rightSideWidth:(CGFloat)rightSideWidth;

- (void)setupToolbar;

- (void)updateTableFont;

- (void)updatePageLabel;

- (SKProgressController *)progressController;

- (void)goToSelectedFindResults:(id)sender;
- (void)updateFindResultHighlightsForDirection:(NSSelectionDirection)direction;

- (void)selectSelectedNote:(id)sender;
- (void)goToSelectedOutlineItem:(id)sender;
- (void)toggleSelectedSnapshots:(id)sender;

- (void)updateNoteFilterPredicate;
- (void)updateSnapshotFilterPredicate;

- (void)registerForDocumentNotifications;
- (void)unregisterForDocumentNotifications;

- (void)registerAsObserver;
- (void)unregisterAsObserver;

- (void)startObservingNotes:(NSArray *)newNotes;
- (void)stopObservingNotes:(NSArray *)oldNotes;

- (void)observeUndoManagerCheckpoint:(NSNotification *)notification;

@end


@implementation SKMainWindowController

@synthesize mainWindow, splitView, centerContentView, pdfSplitView, pdfContentView, pdfView, leftSideController, rightSideController, toolbarController, leftSideContentView, rightSideContentView, presentationNotesDocument, tags, rating, pageNumber, pageLabel, interactionMode;
@dynamic pdfDocument, presentationOptions, selectedNotes, autoScales, leftSidePaneState, rightSidePaneState, findPaneState, leftSidePaneIsOpen, rightSidePaneIsOpen;

+ (void)initialize {
    SKINITIALIZE;
    
    [PDFPage setUsesSequentialPageNumbering:[[NSUserDefaults standardUserDefaults] boolForKey:SKSequentialPageNumberingKey]];
}

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
    if ([key isEqualToString:PAGENUMBER_KEY] || [key isEqualToString:PAGELABEL_KEY])
        return NO;
    else
        return [super automaticallyNotifiesObserversForKey:key];
}

- (id)init {
    self = [super initWithWindowNibName:@"MainWindow"];
    if (self) {
        interactionMode = SKNormalMode;
        searchResults = [[NSMutableArray alloc] init];
        searchResultIndex = 0;
        mwcFlags.caseInsensitiveSearch = [[NSUserDefaults standardUserDefaults] boolForKey:SKCaseInsensitiveSearchKey];
        mwcFlags.wholeWordSearch = [[NSUserDefaults standardUserDefaults] boolForKey:SKWholeWordSearchKey];
        mwcFlags.caseInsensitiveNoteSearch = [[NSUserDefaults standardUserDefaults] boolForKey:SKCaseInsensitiveNoteSearchKey];
        groupedSearchResults = [[NSMutableArray alloc] init];
        thumbnails = [[NSMutableArray alloc] init];
        notes = [[NSMutableArray alloc] init];
        tags = [[NSArray alloc] init];
        rating = 0.0;
        snapshots = [[NSMutableArray alloc] init];
        dirtySnapshots = [[NSMutableArray alloc] init];
        pageLabels = [[NSMutableArray alloc] init];
        lastViewedPages = [[NSPointerArray alloc] initWithOptions:NSPointerFunctionsOpaqueMemory | NSPointerFunctionsIntegerPersonality];
        rowHeights = [[SKFloatMapTable alloc] init];
        savedNormalSetup = [[NSMutableDictionary alloc] init];
        mwcFlags.leftSidePaneState = SKThumbnailSidePaneState;
        mwcFlags.rightSidePaneState = SKNoteSidePaneState;
        mwcFlags.findPaneState = SKSingularFindPaneState;
        pageLabel = nil;
        pageNumber = NSNotFound;
        markedPageIndex = NSNotFound;
        beforeMarkedPageIndex = NSNotFound;
        mwcFlags.updatingColor = 0;
        mwcFlags.updatingFont = 0;
        mwcFlags.updatingLine = 0;
        mwcFlags.usesDrawers = [[NSUserDefaults standardUserDefaults] boolForKey:SKUsesDrawersKey];
        activityAssertionID = kIOPMNullAssertionID;
    }
    
    return self;
}

- (void)dealloc {
    [self stopObservingNotes:[self notes]];
    SKDESTROY(undoGroupOldPropertiesPerNote);
	[[NSNotificationCenter defaultCenter] removeObserver: self];
    [self unregisterAsObserver];
    [mainWindow setDelegate:nil];
    [splitView setDelegate:nil];
    [pdfSplitView setDelegate:nil];
    [pdfView setDelegate:nil];
    [[pdfView document] setDelegate:nil];
    [leftSideDrawer setDelegate:nil];
    [rightSideDrawer setDelegate:nil];
    [noteTypeSheetController setDelegate:nil];
    SKDESTROY(dirtySnapshots);
	SKDESTROY(searchResults);
	SKDESTROY(groupedSearchResults);
	SKDESTROY(thumbnails);
	SKDESTROY(notes);
	SKDESTROY(snapshots);
	SKDESTROY(tags);
    SKDESTROY(pageLabels);
    SKDESTROY(pageLabel);
	SKDESTROY(rowHeights);
    SKDESTROY(lastViewedPages);
	SKDESTROY(leftSideWindow);
	SKDESTROY(rightSideWindow);
    SKDESTROY(mainWindow);
    SKDESTROY(statusBar);
    SKDESTROY(findController);
    SKDESTROY(savedNormalSetup);
    SKDESTROY(progressController);
    SKDESTROY(colorAccessoryView);
    SKDESTROY(textColorAccessoryView);
    SKDESTROY(leftSideDrawer);
    SKDESTROY(rightSideDrawer);
    SKDESTROY(secondaryPdfContentView);
    SKDESTROY(presentationNotesDocument);
    SKDESTROY(noteTypeSheetController);
    SKDESTROY(splitView);
    SKDESTROY(centerContentView);
    SKDESTROY(pdfSplitView);
    SKDESTROY(pdfContentView);
    SKDESTROY(pdfView);
    SKDESTROY(leftSideController);
    SKDESTROY(rightSideController);
    SKDESTROY(toolbarController);
    SKDESTROY(leftSideContentView);
    SKDESTROY(rightSideContentView);
    SKDESTROY(fieldEditor);
    [super dealloc];
}

- (void)windowDidLoad{
    NSUserDefaults *sud = [NSUserDefaults standardUserDefaults];
    BOOL hasWindowSetup = [savedNormalSetup count] > 0;
    
    mwcFlags.settingUpWindow = 1;
    
    // Set up the panes and subviews, needs to be done before we resize them
    [pdfSplitView setFrame:[centerContentView bounds]];
    [centerContentView addSubview:pdfSplitView];
    
    // This gets sometimes messed up in the nib, AppKit bug rdar://5346690
    [leftSideContentView setAutoresizesSubviews:YES];
    [rightSideContentView setAutoresizesSubviews:YES];
    [centerContentView setAutoresizesSubviews:YES];
    [pdfContentView setAutoresizesSubviews:YES];
    
    // make sure the first thing we call on the side view controllers is its view so their nib is loaded
    addSideSubview(leftSideController.view, leftSideContentView, mwcFlags.usesDrawers);
    addSideSubview(rightSideController.view, rightSideContentView, mwcFlags.usesDrawers);
    
    [leftSideController.searchField setAction:@selector(search:)];
    [leftSideController.searchField setTarget:self];
    [rightSideController.searchField setAction:@selector(searchNotes:)];
    [rightSideController.searchField setTarget:self];
    
    [rightSideController.noteOutlineView setDoubleAction:@selector(selectSelectedNote:)];
    [rightSideController.noteOutlineView setTarget:self];
    [leftSideController.tocOutlineView setDoubleAction:@selector(goToSelectedOutlineItem:)];
    [leftSideController.tocOutlineView setTarget:self];
    [rightSideController.snapshotTableView setDoubleAction:@selector(toggleSelectedSnapshots:)];
    [rightSideController.snapshotTableView setTarget:self];
    [leftSideController.findTableView setDoubleAction:@selector(goToSelectedFindResults:)];
    [leftSideController.findTableView setTarget:self];
    [leftSideController.groupedFindTableView setDoubleAction:@selector(goToSelectedFindResults:)];
    [leftSideController.groupedFindTableView setTarget:self];
    
    [self updateTableFont];
    
    if (mwcFlags.usesDrawers) {
        leftSideDrawer = [[NSDrawer alloc] initWithContentSize:[leftSideContentView frame].size preferredEdge:NSMinXEdge];
        [leftSideDrawer setParentWindow:[self window]];
        [leftSideDrawer setContentView:leftSideContentView];
        [leftSideDrawer openOnEdge:NSMinXEdge];
        [leftSideDrawer setDelegate:self];
        rightSideDrawer = [[NSDrawer alloc] initWithContentSize:[rightSideContentView frame].size preferredEdge:NSMaxXEdge];
        [rightSideDrawer setParentWindow:[self window]];
        [rightSideDrawer setContentView:rightSideContentView];
        [rightSideDrawer openOnEdge:NSMaxXEdge];
        [rightSideDrawer setDelegate:self];
        [centerContentView setFrame:[splitView bounds]];
    }
    
    [self displayThumbnailViewAnimating:NO];
    [self displayNoteViewAnimating:NO];
    
    // we need to create the PDFView before setting the toolbar
    pdfView = [[SKPDFView alloc] initWithFrame:[pdfContentView bounds]];
    [pdfView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    
    // Set up the tool bar
    [toolbarController setupToolbar];
    
    // Set up the window
    [self setWindowFrameAutosaveNameOrCascade:SKMainWindowFrameAutosaveName];
    
    [[self window] setAutorecalculatesContentBorderThickness:NO forEdge:NSMinYEdge];
    
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
    [pdfView setShouldAntiAlias:[sud boolForKey:SKShouldAntiAliasKey]];
    [pdfView setGreekingThreshold:[sud floatForKey:SKGreekingThresholdKey]];
    [pdfView setBackgroundColor:[sud colorForKey:SKBackgroundColorKey]];
    
    [self applyPDFSettings:hasWindowSetup ? savedNormalSetup : [sud dictionaryForKey:SKDefaultPDFDisplaySettingsKey]];
    
    [pdfView setDelegate:self];
    
    NSNumber *leftWidth = [savedNormalSetup objectForKey:LEFTSIDEPANEWIDTH_KEY] ?: [sud objectForKey:SKLeftSidePaneWidthKey];
    NSNumber *rightWidth = [savedNormalSetup objectForKey:RIGHTSIDEPANEWIDTH_KEY] ?: [sud objectForKey:SKRightSidePaneWidthKey];
    
    if (leftWidth && rightWidth)
        [self applyLeftSideWidth:[leftWidth doubleValue] rightSideWidth:[rightWidth doubleValue]];
    
    // this needs to be done before loading the PDFDocument
    [self resetThumbnailSizeIfNeeded];
    [self resetSnapshotSizeIfNeeded];
    
    // this needs to be done before loading the PDFDocument
    NSSortDescriptor *pageIndexSortDescriptor = [[[NSSortDescriptor alloc] initWithKey:SKNPDFAnnotationPageIndexKey ascending:YES] autorelease];
    NSSortDescriptor *boundsSortDescriptor = [[[NSSortDescriptor alloc] initWithKey:SKNPDFAnnotationBoundsKey ascending:YES selector:@selector(boundsCompare:)] autorelease];
    [rightSideController.noteArrayController setSortDescriptors:[NSArray arrayWithObjects:pageIndexSortDescriptor, boundsSortDescriptor, nil]];
    [rightSideController.snapshotArrayController setSortDescriptors:[NSArray arrayWithObjects:pageIndexSortDescriptor, nil]];
    
    NSSortDescriptor *countDescriptor = [[[NSSortDescriptor alloc] initWithKey:SKGroupedSearchResultCountKey ascending:NO] autorelease];
    [leftSideController.groupedFindArrayController setSortDescriptors:[NSArray arrayWithObjects:countDescriptor, nil]];
    [[[leftSideController.groupedFindTableView tableColumnWithIdentifier:RELEVANCE_COLUMNID] dataCell] setEnabled:NO];
        
    // NB: the next line will load the PDF document and annotations, so necessary setup must be finished first!
    // windowControllerDidLoadNib: is not called automatically because the document overrides makeWindowControllers
    [[self document] windowControllerDidLoadNib:self];
    
    if ([[self pdfDocument] hasRightToLeftLanguage]) {
        boundsSortDescriptor = [[[NSSortDescriptor alloc] initWithKey:SKNPDFAnnotationBoundsKey ascending:YES selector:@selector(mirorredBoundsCompare:)] autorelease];
        [rightSideController.noteArrayController setSortDescriptors:[NSArray arrayWithObjects:pageIndexSortDescriptor, boundsSortDescriptor, nil]];
        [rightSideController.noteOutlineView reloadData];
    }
    
    // Show/hide left side pane if necessary
    BOOL hasOutline = ([[pdfView document] outlineRoot] != nil);
    if ([sud boolForKey:SKOpenContentsPaneOnlyForTOCKey] && [self leftSidePaneIsOpen] != hasOutline)
        [self toggleLeftSidePane:nil];
    if (hasOutline)
        [self setLeftSidePaneState:SKOutlineSidePaneState];
    else
        [leftSideController.button setEnabled:NO forSegment:SKOutlineSidePaneState];
    
    // Due to a bug in Leopard we should only resize and swap in the PDFView after loading the PDFDocument
    [pdfView setFrame:[pdfContentView bounds]];
    [pdfContentView addSubview:pdfView];
    
    // get the initial display mode from the PDF if present and not overridden by an explicit setup
    if (hasWindowSetup == NO && [[NSUserDefaults standardUserDefaults] boolForKey:SKUseSettingsFromPDFKey]) {
        NSDictionary *initialSettings = [[self pdfDocument] initialSettings];
        if (initialSettings) {
            [self applyPDFSettings:initialSettings];
            if ([initialSettings objectForKey:@"fitWindow"])
                windowSizeOption = [[initialSettings objectForKey:@"fitWindow"] boolValue] ? SKFitWindowOption : SKDefaultWindowOption;
        }
    }
    
    // Go to page?
    NSUInteger pageIndex = NSNotFound;
    if (hasWindowSetup)
        pageIndex = [[savedNormalSetup objectForKey:PAGEINDEX_KEY] unsignedIntegerValue];
    else if ([sud boolForKey:SKRememberLastPageViewedKey])
        pageIndex = [[SKBookmarkController sharedBookmarkController] pageIndexForRecentDocumentAtURL:[[self document] fileURL]];
    if (pageIndex != NSNotFound && [[pdfView document] pageCount] > pageIndex) {
        if ([[pdfView document] isLocked]) {
            [savedNormalSetup setObject:[NSNumber numberWithUnsignedInteger:pageIndex] forKey:PAGEINDEX_KEY];
        } else if ([[pdfView currentPage] pageIndex] != pageIndex) {
            [lastViewedPages setCount:0];
            [pdfView goToPage:[[pdfView document] pageAtIndex:pageIndex]];
            [pdfView resetHistory];
        }
    }
    
    // We can fit only after the PDF has been loaded
    if (windowSizeOption == SKFitWindowOption && hasWindowSetup == NO)
        [self performFit:self];
    
    // Open snapshots?
    NSArray *snapshotSetups = nil;
    if (hasWindowSetup)
        snapshotSetups = [savedNormalSetup objectForKey:SNAPSHOTS_KEY];
    else if ([sud boolForKey:SKRememberSnapshotsKey])
        snapshotSetups = [[SKBookmarkController sharedBookmarkController] snapshotsForRecentDocumentAtURL:[[self document] fileURL]];
    if ([snapshotSetups count]) {
        if ([[pdfView document] isLocked])
            [savedNormalSetup setObject:snapshotSetups forKey:SNAPSHOTS_KEY];
        else
            [self showSnapshotsWithSetups:snapshotSetups];
    }
    
    noteTypeSheetController = [[SKNoteTypeSheetController alloc] init];
    [noteTypeSheetController setDelegate:self];
    
    NSMenu *menu = [[rightSideController.noteOutlineView headerView] menu];
    [menu addItem:[NSMenuItem separatorItem]];
    [[menu addItemWithTitle:NSLocalizedString(@"Note Type", @"Menu item title") action:NULL keyEquivalent:@""] setSubmenu:[noteTypeSheetController noteTypeMenu]];
    
    [rightSideController.noteOutlineView setIndentationPerLevel:1.0];
    
    [rightSideController.noteOutlineView registerForDraggedTypes:[NSColor readableTypesForPasteboard:[NSPasteboard pasteboardWithName:NSDragPboard]]];
    
    [leftSideController.thumbnailTableView setDraggingSourceOperationMask:NSDragOperationEvery forLocal:NO];
    [rightSideController.snapshotTableView setDraggingSourceOperationMask:NSDragOperationEvery forLocal:NO];
    
    if (NO == [[NSUserDefaults standardUserDefaults] boolForKey:SKDisableTableToolTipsKey]) {
        [leftSideController.tocOutlineView setHasImageToolTips:YES];
        [leftSideController.findTableView setHasImageToolTips:YES];
        [leftSideController.groupedFindTableView setHasImageToolTips:YES];
    }
    
    [pdfView setTypeSelectHelper:[leftSideController.thumbnailTableView typeSelectHelper]];
    
    [[self window] recalculateKeyViewLoop];
    [[self window] makeFirstResponder:pdfView];
    
    // Update page states
    [self handlePageChangedNotification:nil];
    [toolbarController handlePageChangedNotification:nil];
    
    // Observe notifications and KVO
    [self registerForNotifications];
    [self registerAsObserver];
    
    if ([[pdfView document] isLocked])
        [[self window] makeFirstResponder:[pdfView subviewOfClass:[NSSecureTextField class]]];
    else
        [savedNormalSetup removeAllObjects];
    
    mwcFlags.settingUpWindow = 0;
}

- (void)synchronizeWindowTitleWithDocumentName {
    // as the fullscreen window has no title we have to do this manually
    if ([self interactionMode] == SKFullScreenMode)
        [NSApp changeWindowsItem:[self window] title:[self windowTitleForDocumentDisplayName:[[self document] displayName]] filename:NO];
    [super synchronizeWindowTitleWithDocumentName];
}

- (void)applyLeftSideWidth:(CGFloat)leftSideWidth rightSideWidth:(CGFloat)rightSideWidth {
    if (mwcFlags.usesDrawers == 0) {
        [splitView setPosition:leftSideWidth ofDividerAtIndex:0];
        [splitView setPosition:[splitView maxPossiblePositionOfDividerAtIndex:1] - [splitView dividerThickness] - rightSideWidth ofDividerAtIndex:1];
    } else {
        if (leftSideWidth > 0.0) {
            [leftSideDrawer setContentSize:NSMakeSize(leftSideWidth, NSHeight([leftSideContentView frame]))];
            [leftSideDrawer openOnEdge:NSMinXEdge];
        } else {
            [leftSideDrawer close];
        }
        if (rightSideWidth > 0.0) {
            [rightSideDrawer setContentSize:NSMakeSize(leftSideWidth, NSHeight([rightSideContentView frame]))];
            [rightSideDrawer openOnEdge:NSMaxXEdge];
        } else {
            [rightSideDrawer close];
        }
    }
}

- (void)applySetup:(NSDictionary *)setup{
    if ([self isWindowLoaded] == NO) {
        [savedNormalSetup setDictionary:setup];
    } else {
        
        NSString *rectString = [setup objectForKey:SKMainWindowFrameKey];
        if (rectString)
            [mainWindow setFrame:NSRectFromString([setup objectForKey:SKMainWindowFrameKey]) display:[mainWindow isVisible]];
        
        NSNumber *leftWidth = [setup objectForKey:LEFTSIDEPANEWIDTH_KEY];
        NSNumber *rightWidth = [setup objectForKey:RIGHTSIDEPANEWIDTH_KEY];
        if (leftWidth && rightWidth)
            [self applyLeftSideWidth:[leftWidth doubleValue] rightSideWidth:[rightWidth doubleValue]];
        
        NSNumber *pageIndexNumber = [setup objectForKey:PAGEINDEX_KEY];
        NSUInteger pageIndex = [pageIndexNumber unsignedIntegerValue];
        if (pageIndexNumber && pageIndex != NSNotFound && pageIndex != [[pdfView currentPage] pageIndex])
            [pdfView goToPage:[[pdfView document] pageAtIndex:pageIndex]];
        
        NSArray *snapshotSetups = [setup objectForKey:SNAPSHOTS_KEY];
        if ([snapshotSetups count])
            [self showSnapshotsWithSetups:snapshotSetups];
        
        if ([self interactionMode] == SKNormalMode)
            [self applyPDFSettings:setup];
        else
            [savedNormalSetup addEntriesFromDictionary:setup];
    }
}

- (NSDictionary *)currentSetup {
    NSMutableDictionary *setup = [NSMutableDictionary dictionary];
    
    [setup setObject:NSStringFromRect([mainWindow frame]) forKey:SKMainWindowFrameKey];
    [setup setObject:[NSNumber numberWithDouble:[self leftSidePaneIsOpen] ? NSWidth([leftSideContentView frame]) : 0.0] forKey:LEFTSIDEPANEWIDTH_KEY];
    [setup setObject:[NSNumber numberWithDouble:[self rightSidePaneIsOpen] ? NSWidth([rightSideContentView frame]) : 0.0] forKey:RIGHTSIDEPANEWIDTH_KEY];
    [setup setObject:[NSNumber numberWithUnsignedInteger:[[pdfView currentPage] pageIndex]] forKey:PAGEINDEX_KEY];
    if ([snapshots count])
        [setup setObject:[snapshots valueForKey:SKSnapshotCurrentSetupKey] forKey:SNAPSHOTS_KEY];
    if ([self interactionMode] == SKNormalMode) {
        [setup addEntriesFromDictionary:[self currentPDFSettings]];
    } else {
        [setup addEntriesFromDictionary:savedNormalSetup];
        [setup removeObjectsForKeys:[NSArray arrayWithObjects:HASHORIZONTALSCROLLER_KEY, HASVERTICALSCROLLER_KEY, AUTOHIDESSCROLLERS_KEY, nil]];
    }
    
    return setup;
}

- (void)applyPDFSettings:(NSDictionary *)setup {
    NSNumber *number;
    if ((number = [setup objectForKey:AUTOSCALES_KEY]))
        [pdfView setAutoScales:[number boolValue]];
    if ([pdfView autoScales] == NO && (number = [setup objectForKey:SCALEFACTOR_KEY]))
        [pdfView setScaleFactor:[number doubleValue]];
    if ((number = [setup objectForKey:DISPLAYSPAGEBREAKS_KEY]))
        [pdfView setDisplaysPageBreaks:[number boolValue]];
    if ((number = [setup objectForKey:DISPLAYSASBOOK_KEY]))
        [pdfView setDisplaysAsBook:[number boolValue]];
    if ((number = [setup objectForKey:DISPLAYMODE_KEY]))
        [pdfView setDisplayMode:[number integerValue]];
    if ((number = [setup objectForKey:DISPLAYBOX_KEY]))
        [pdfView setDisplayBox:[number integerValue]];
}

- (NSDictionary *)currentPDFSettings {
    NSMutableDictionary *setup = [NSMutableDictionary dictionary];
    
    [setup setObject:[NSNumber numberWithBool:[pdfView displaysPageBreaks]] forKey:DISPLAYSPAGEBREAKS_KEY];
    [setup setObject:[NSNumber numberWithBool:[pdfView displaysAsBook]] forKey:DISPLAYSASBOOK_KEY];
    [setup setObject:[NSNumber numberWithInteger:[pdfView displayBox]] forKey:DISPLAYBOX_KEY];
    [setup setObject:[NSNumber numberWithDouble:[pdfView scaleFactor]] forKey:SCALEFACTOR_KEY];
    [setup setObject:[NSNumber numberWithBool:[pdfView autoScales]] forKey:AUTOSCALES_KEY];
    [setup setObject:[NSNumber numberWithInteger:[pdfView displayMode]] forKey:DISPLAYMODE_KEY];
    
    return setup;
}

#pragma mark UI updating

- (void)updateLeftStatus {
    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Page %ld of %ld", @"Status message"), (long)[self pageNumber], (long)[[pdfView document] pageCount]];
    [statusBar setLeftStringValue:message];
}

#define CM_PER_POINT 0.035277778
#define INCH_PER_POINT 0.013888889

- (void)updateRightStatus {
    NSRect rect = [pdfView currentSelectionRect];
    CGFloat magnification = [pdfView currentMagnification];
    NSString *message;
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKDisplayNoteBoundsKey] && NSEqualRects(rect, NSZeroRect) && [pdfView activeAnnotation])
        rect = [[pdfView activeAnnotation] bounds];
    
    if (NSEqualRects(rect, NSZeroRect) == NO) {
        if ([statusBar rightState] == NSOnState) {
            BOOL useMetric = [[[NSLocale currentLocale] objectForKey:NSLocaleUsesMetricSystem] boolValue];
            NSString *units = useMetric ? NSLocalizedString(@"cm", @"size unit") : NSLocalizedString(@"in", @"size unit");
            CGFloat factor = useMetric ? CM_PER_POINT : INCH_PER_POINT;
            message = [NSString stringWithFormat:@"%.2f %C %.2f @ (%.2f, %.2f) %@", NSWidth(rect) * factor, MULTIPLICATION_SIGN_CHARACTER, NSHeight(rect) * factor, NSMinX(rect) * factor, NSMinY(rect) * factor, units];
        } else {
            message = [NSString stringWithFormat:@"%ld %C %ld @ (%ld, %ld) %@", (long)NSWidth(rect), MULTIPLICATION_SIGN_CHARACTER, (long)NSHeight(rect), (long)NSMinX(rect), (long)NSMinY(rect), NSLocalizedString(@"pt", @"size unit")];
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
    
    for (NSString *label in pageLabels) {
        [cell setStringValue:label];
        labelWidth = fmax(labelWidth, [cell cellSize].width);
    }
    
    [tableColumn setMinWidth:labelWidth];
    [tableColumn setMaxWidth:labelWidth];
    [tableColumn setWidth:labelWidth];
    [tv sizeToFit];
}

#define LABEL_KEY @"label"
#define EXPANDED_KEY @"expanded"
#define CHILDREN_KEY @"children"

- (NSDictionary *)expansionStateForOutline:(PDFOutline *)anOutline {
    if (anOutline == nil)
        return nil;
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setValue:[anOutline label] forKey:LABEL_KEY];
    BOOL isExpanded = ([anOutline parent] == nil || [leftSideController.tocOutlineView isItemExpanded:anOutline]);
    [dict setValue:[NSNumber numberWithBool:isExpanded] forKey:EXPANDED_KEY];
    if (isExpanded) {
        NSUInteger i, iMax = [anOutline numberOfChildren];
        if (iMax > 0) {
            NSMutableArray *array = [[NSMutableArray alloc] init];
            for (i = 0; i < iMax; i++)
                [array addObject:[self expansionStateForOutline:[anOutline childAtIndex:i]]];
            [dict setValue:array forKey:CHILDREN_KEY];
            [array release];
        }
    }
    return dict;
}

- (void)expandOutline:(PDFOutline *)anOutline forExpansionState:(NSDictionary *)info {
    BOOL isExpanded = info ? [[info valueForKey:EXPANDED_KEY] boolValue] : [anOutline isOpen];
    if (isExpanded && anOutline) {
        NSUInteger i, iMax = [anOutline numberOfChildren];
        NSMutableArray *children = [[NSMutableArray alloc] init];
        for (i = 0; i < iMax; i++)
            [children addObject:[anOutline childAtIndex:i]];
        if ([anOutline parent])
            [leftSideController.tocOutlineView expandItem:anOutline];
        NSArray *childrenStates = [info valueForKey:CHILDREN_KEY];
        NSEnumerator *infoEnum = nil;
        if (childrenStates && [[children valueForKey:LABEL_KEY] isEqualToArray:[childrenStates valueForKey:LABEL_KEY]])
            infoEnum = [childrenStates objectEnumerator];
        for (PDFOutline *child in children)
            [self expandOutline:child forExpansionState:[infoEnum nextObject]];
        [children release];
    }
}

- (void)updateTableFont {
    NSFont *font = [NSFont systemFontOfSize:[[NSUserDefaults standardUserDefaults] floatForKey:SKTableFontSizeKey]];
    [leftSideController.tocOutlineView setFont:font];
    [rightSideController.noteOutlineView setFont:font];
    [leftSideController.findTableView setFont:font];
    [leftSideController.groupedFindTableView setFont:font];
}

- (void)updatePageLabelsAndOutlineForExpansionState:(NSDictionary *)info {
    // update page labels, also update the size of the table columns displaying the labels
    [self willChangeValueForKey:PAGELABELS_KEY];
    [pageLabels setArray:[[pdfView document] pageLabels]];
    [self didChangeValueForKey:PAGELABELS_KEY];
    
    [self updatePageLabel];
    
    [self updatePageColumnWidthForTableView:leftSideController.thumbnailTableView];
    [self updatePageColumnWidthForTableView:rightSideController.snapshotTableView];
    [self updatePageColumnWidthForTableView:leftSideController.tocOutlineView];
    [self updatePageColumnWidthForTableView:rightSideController.noteOutlineView];
    [self updatePageColumnWidthForTableView:leftSideController.findTableView];
    [self updatePageColumnWidthForTableView:leftSideController.groupedFindTableView];
    
    // this uses the pageLabels
    [[leftSideController.thumbnailTableView typeSelectHelper] rebuildTypeSelectSearchCache];
    
    // these carry a label, moreover when this is called the thumbnails will also be invalid
    [self resetThumbnails];
    [self allSnapshotsNeedUpdate];
    [rightSideController.noteOutlineView reloadData];
    
    PDFOutline *outlineRoot = [[pdfView document] outlineRoot];
    
    mwcFlags.updatingOutlineSelection = 1;
    // If this is a reload following a TeX run and the user just killed the outline for some reason, we get a crash if the outlineView isn't reloaded, so no longer make it conditional on pdfOutline != nil
    [leftSideController.tocOutlineView reloadData];
    if (outlineRoot)
        [self expandOutline:outlineRoot forExpansionState:info];
    mwcFlags.updatingOutlineSelection = 0;
    [self updateOutlineSelection];
    
    // handle the case as above where the outline has disappeared in a reload situation
    if (nil == outlineRoot)
        [self setLeftSidePaneState:SKThumbnailSidePaneState];

    [leftSideController.button setEnabled:outlineRoot != nil forSegment:SKOutlineSidePaneState];
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
        NSDictionary *openState = nil;
        
        if ([pdfView document]) {
            pageIndex = [[pdfView currentPage] pageIndex];
            visibleRect = [pdfView convertRect:[pdfView convertRect:[[pdfView documentView] visibleRect] fromView:[pdfView documentView]] toPage:[pdfView currentPage]];
            if (secondaryPdfView) {
                secondaryPageIndex = [[secondaryPdfView currentPage] pageIndex];
                secondaryVisibleRect = [secondaryPdfView convertRect:[secondaryPdfView convertRect:[[secondaryPdfView documentView] visibleRect] fromView:[secondaryPdfView documentView]] toPage:[secondaryPdfView currentPage]];
            }
            openState = [self expansionStateForOutline:[[pdfView document] outlineRoot]];
            
            [[pdfView document] cancelFindString];
            
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
            
            [lastViewedPages setCount:0];
            
            [self unregisterForDocumentNotifications];
            
            [[pdfView document] setDelegate:nil];
        }
        
        [pdfView setDocument:document];
        [[pdfView document] setDelegate:self];
        
        [secondaryPdfView setDocument:document];
        
        [self registerForDocumentNotifications];
        
        [self updatePageLabelsAndOutlineForExpansionState:openState];
        [self updateNoteSelection];
        
        if ([snapshotDicts count]) {
            if ([document isLocked] && [self presentationOptions] == SKNormalMode)
                [savedNormalSetup setObject:snapshotDicts forKey:SNAPSHOTS_KEY];
            else
                [self showSnapshotsWithSetups:snapshotDicts];
        }
        
        if ([document pageCount] && (pageIndex != NSNotFound || secondaryPageIndex != NSNotFound)) {
            PDFPage *page = nil;
            PDFPage *secondaryPage = nil;
            if (pageIndex != NSNotFound) {
                if (pageIndex >= [document pageCount])
                    pageIndex = [document pageCount] - 1;
                if ([document isLocked] && [self presentationOptions] == SKNormalMode) {
                    [savedNormalSetup setObject:[NSNumber numberWithUnsignedInteger:pageIndex] forKey:PAGEINDEX_KEY];
                } else {
                    page = [document pageAtIndex:pageIndex];
                    [pdfView goToPage:page];
                }
            }
            if (secondaryPageIndex != NSNotFound) {
                secondaryPage = [document pageAtIndex:MIN(secondaryPageIndex, [document pageCount] - 1)];
                [secondaryPdfView goToPage:secondaryPage];
            }
            [pdfView resetHistory];
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
        [toolbarController handleChangedHistoryNotification:nil];
        [toolbarController handlePageChangedNotification:nil];
        [self handlePageChangedNotification:nil];
        [self updateLeftStatus];
        [self updateRightStatus];
    }
}
    
- (void)addAnnotationsFromDictionaries:(NSArray *)noteDicts replace:(BOOL)replace {
    PDFAnnotation *annotation;
    PDFDocument *pdfDoc = [pdfView document];
    NSMutableArray *observableNotes = [self mutableArrayValueForKey:NOTES_KEY];
    
    if (replace) {
        [pdfView removePDFToolTipRects];
        // remove the current annotations
        [pdfView setActiveAnnotation:nil];
        for (annotation in [[notes copy] autorelease])
            [pdfView removeAnnotation:annotation];
    }
    
    // create new annotations from the dictionary and add them to their page and to the document
    for (NSDictionary *dict in noteDicts) {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        NSUInteger pageIndex = [[dict objectForKey:SKNPDFAnnotationPageIndexKey] unsignedIntegerValue];
        if ((annotation = [[PDFAnnotation alloc] initSkimNoteWithProperties:dict])) {
            if (pageIndex == NSNotFound)
                pageIndex = 0;
            else if (pageIndex >= [pdfDoc pageCount])
                pageIndex = [pdfDoc pageCount] - 1;
            PDFPage *page = [pdfDoc pageAtIndex:pageIndex];
            [pdfView addAnnotation:annotation toPage:page];
            // this is necessary for the initial load of the document, as the notification handler is not yet registered
            if ([observableNotes containsObject:annotation] == NO)
                [observableNotes addObject:annotation];
            [annotation release];
        }
        [pool release];
    }
    // make sure we clear the undo handling
    [self observeUndoManagerCheckpoint:nil];
    [rightSideController.noteOutlineView reloadData];
    [self allThumbnailsNeedUpdate];
    [pdfView resetPDFToolTipRects];
}

- (void)updatePageNumber {
    NSUInteger number = [[pdfView currentPage] pageIndex] + 1;
    if (pageNumber != number) {
        [self willChangeValueForKey:PAGENUMBER_KEY];
        pageNumber = number;
        [self didChangeValueForKey:PAGENUMBER_KEY];
    }
}

- (void)setPageNumber:(NSUInteger)number {
    // Check that the page number exists
    NSUInteger pageCount = [[pdfView document] pageCount];
    if (number > pageCount)
        number = pageCount;
    if (number > 0 && [[pdfView currentPage] pageIndex] != number - 1)
        [pdfView goToPage:[[pdfView document] pageAtIndex:number - 1]];
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

- (void)setPageLabel:(NSString *)label {
    NSUInteger idx = [pageLabels indexOfObject:label];
    if (idx != NSNotFound && [[pdfView currentPage] pageIndex] != idx)
        [pdfView goToPage:[[pdfView document] pageAtIndex:idx]];
}

- (BOOL)validatePageLabel:(id *)value error:(NSError **)error {
    if ([pageLabels indexOfObject:*value] == NSNotFound)
        *value = [self pageLabel];
    return YES;
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
        
        if ([leftSideController.searchField stringValue] && [[leftSideController.searchField stringValue] isEqualToString:@""] == NO) {
            [leftSideController.searchField setStringValue:@""];
        }
        
        if (mwcFlags.leftSidePaneState == SKThumbnailSidePaneState)
            [self displayThumbnailViewAnimating:NO];
        else if (mwcFlags.leftSidePaneState == SKOutlineSidePaneState)
            [self displayTocViewAnimating:NO];
    }
}

- (SKRightSidePaneState)rightSidePaneState {
    return mwcFlags.rightSidePaneState;
}

- (void)setRightSidePaneState:(SKRightSidePaneState)newRightSidePaneState {
    if (mwcFlags.rightSidePaneState != newRightSidePaneState) {
        
        if ([[rightSideController.searchField stringValue] length] > 0) {
            [rightSideController.searchField setStringValue:@""];
            [self searchNotes:rightSideController.searchField];
        }
        
        mwcFlags.rightSidePaneState = newRightSidePaneState;
        
        if (mwcFlags.rightSidePaneState == SKNoteSidePaneState)
            [self displayNoteViewAnimating:NO];
        else if (mwcFlags.rightSidePaneState == SKSnapshotSidePaneState)
            [self displaySnapshotViewAnimating:NO];
    }
}

- (SKFindPaneState)findPaneState {
    return mwcFlags.findPaneState;
}

- (void)setFindPaneState:(SKFindPaneState)newFindPaneState {
    if (mwcFlags.findPaneState != newFindPaneState) {
        mwcFlags.findPaneState = newFindPaneState;
        
        if (mwcFlags.findPaneState == SKSingularFindPaneState) {
            if ([leftSideController.groupedFindTableView window])
                [self displayFindViewAnimating:NO];
        } else if (mwcFlags.findPaneState == SKGroupedFindPaneState) {
            if ([leftSideController.findTableView window])
                [self displayGroupedFindViewAnimating:NO];
        }
        [self updateFindResultHighlightsForDirection:NSDirectSelection];
    }
}

- (BOOL)leftSidePaneIsOpen {
    NSInteger state;
    if ([self interactionMode] == SKFullScreenMode)
        state = [leftSideWindow state];
    else if ([self interactionMode] == SKPresentationMode)
        state = [leftSideWindow isVisible] ? NSDrawerOpenState : NSDrawerClosedState;
    else if (mwcFlags.usesDrawers)
        state = [leftSideDrawer state];
    else
        state = [splitView isSubviewCollapsed:leftSideContentView] ? NSDrawerClosedState : NSDrawerOpenState;
    return state == NSDrawerOpenState || state == NSDrawerOpeningState;
}

- (BOOL)rightSidePaneIsOpen {
    NSInteger state;
    if ([self interactionMode] == SKFullScreenMode)
        state = [rightSideWindow state];
    else if ([self interactionMode] == SKPresentationMode)
        state = [rightSideWindow isVisible] ? NSDrawerOpenState : NSDrawerClosedState;
    else if (mwcFlags.usesDrawers)
        state = [rightSideDrawer state];
    else
        state = [splitView isSubviewCollapsed:rightSideContentView] ? NSDrawerClosedState : NSDrawerOpenState;;
    return state == NSDrawerOpenState || state == NSDrawerOpeningState;
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
    
    [[self windowControllerForNote:note] close];
    
    if ([[note texts] count])
        [rowHeights removeFloatForKey:[[note texts] lastObject]];
    [rowHeights removeFloatForKey:note];
    
    // Stop observing the removed notes
    [self stopObservingNotes:[NSArray arrayWithObject:note]];
    
    [notes removeObjectAtIndex:theIndex];
}

- (void)removeAllObjectsFromNotes {
    if ([notes count]) {
        NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [notes count])];
        [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:NOTES_KEY];
        
        for (NSWindowController *wc in [[self document] windowControllers]) {
            if ([wc isNoteWindowController])
                [wc close];
        }
        
        [rowHeights removeAllFloats];
        
        [self stopObservingNotes:notes];

        [notes removeAllObjects];
        
        [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:NOTES_KEY];
        [rightSideController.noteOutlineView reloadData];
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
    NSIndexSet *rowIndexes = [rightSideController.noteOutlineView selectedRowIndexes];
    [rowIndexes enumerateIndexesUsingBlock:^(NSUInteger row, BOOL *stop) {
        id item = [rightSideController.noteOutlineView itemAtRow:row];
        if ([(PDFAnnotation *)item type] == nil)
            item = [(SKNoteText *)item note];
        if ([selectedNotes containsObject:item] == NO)
            [selectedNotes addObject:item];
    }];
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
        [options setValue:(styleName ?: @"") forKey:SKStyleNameKey];
        [options setValue:[NSNumber numberWithDouble:[transitions duration]] forKey:SKDurationKey];
        [options setValue:[NSNumber numberWithBool:[transitions shouldRestrict]] forKey:SKShouldRestrictKey];
        [options setValue:pageTransitions forKey:PAGETRANSITIONS_KEY];
    }
    return options;
}

- (void)setPresentationOptions:(NSDictionary *)dictionary {
    SKTransitionController *transitions = [pdfView transitionController];
    NSString *styleName = [dictionary objectForKey:SKStyleNameKey];
    NSNumber *duration = [dictionary objectForKey:SKDurationKey];
    NSNumber *shouldRestrict = [dictionary objectForKey:SKShouldRestrictKey];
    NSArray *pageTransitions = [dictionary objectForKey:PAGETRANSITIONS_KEY];
    if (styleName)
        [transitions setTransitionStyle:[SKTransitionController styleForName:styleName]];
    if (duration)
        [transitions setDuration:[duration doubleValue]];
    if (shouldRestrict)
        [transitions setShouldRestrict:[shouldRestrict boolValue]];
    [transitions setPageTransitions:pageTransitions];
}

#pragma mark Full Screen support

- (void)showLeftSideWindow {
    if (leftSideWindow == nil)
        leftSideWindow = [[SKSideWindow alloc] initWithMainController:self edge:NSMinXEdge];
    
    if ([[[leftSideController.view window] firstResponder] isDescendantOf:leftSideController.view])
        [[leftSideController.view window] makeFirstResponder:nil];
    [leftSideWindow setMainView:leftSideController.view];
    
    if ([self interactionMode] == SKPresentationMode) {
        mwcFlags.savedLeftSidePaneState = [self leftSidePaneState];
        [self setLeftSidePaneState:SKThumbnailSidePaneState];
        [leftSideWindow setAlphaValue:PRESENTATION_SIDE_WINDOW_ALPHA];
        [leftSideWindow setEnabled:NO];
        [leftSideWindow makeFirstResponder:leftSideController.thumbnailTableView];
        [leftSideWindow attachToWindow:[self window]];
        [leftSideWindow expand];
    } else {
        [leftSideWindow makeFirstResponder:leftSideController.searchField];
        [leftSideWindow attachToWindow:[self window]];
    }
}

- (void)showRightSideWindow {
    if (rightSideWindow == nil) 
        rightSideWindow = [[SKSideWindow alloc] initWithMainController:self edge:NSMaxXEdge];
    
    if ([[[rightSideController.view window] firstResponder] isDescendantOf:rightSideController.view])
        [[rightSideController.view window] makeFirstResponder:nil];
    [rightSideWindow setMainView:rightSideController.view];
    
    if ([self interactionMode] == SKPresentationMode) {
        [rightSideWindow setAlphaValue:PRESENTATION_SIDE_WINDOW_ALPHA];
        [rightSideWindow setEnabled:NO];
        [rightSideWindow attachToWindow:[self window]];
        [rightSideWindow expand];
    } else {
        [rightSideWindow attachToWindow:[self window]];
    }
}

- (void)hideLeftSideWindow {
    if ([[leftSideController.view window] isEqual:leftSideWindow]) {
        [leftSideWindow remove];
        
        if ([[leftSideWindow firstResponder] isDescendantOf:leftSideController.view])
            [leftSideWindow makeFirstResponder:nil];
        addSideSubview(leftSideController.view, leftSideContentView, mwcFlags.usesDrawers);
        
        SKDESTROY(leftSideWindow);
    }
}

- (void)hideRightSideWindow {
    if ([[rightSideController.view window] isEqual:rightSideWindow]) {
        [rightSideWindow remove];
        
        if ([[rightSideWindow firstResponder] isDescendantOf:rightSideController.view])
            [rightSideWindow makeFirstResponder:nil];
        addSideSubview(rightSideController.view, rightSideContentView, mwcFlags.usesDrawers);
        
        SKDESTROY(rightSideWindow);
    }
}

- (void)forceSubwindowsOnTop:(BOOL)flag {
    for (NSWindowController *wc in [[self document] windowControllers]) {
        if ([wc respondsToSelector:@selector(setForceOnTop:)])
            [(id)wc setForceOnTop:flag];
    }
}

- (void)enterPresentationMode {
    NSScrollView *scrollView = [[pdfView documentView] enclosingScrollView];
    [savedNormalSetup setObject:[NSNumber numberWithBool:[scrollView hasHorizontalScroller]] forKey:HASHORIZONTALSCROLLER_KEY];
    [savedNormalSetup setObject:[NSNumber numberWithBool:[scrollView hasVerticalScroller]] forKey:HASVERTICALSCROLLER_KEY];
    [savedNormalSetup setObject:[NSNumber numberWithBool:[scrollView autohidesScrollers]] forKey:AUTOHIDESSCROLLERS_KEY];
    // Set up presentation mode
    [pdfView setBackgroundColor:[NSColor clearColor]];
    [pdfView setAutoScales:YES];
    [pdfView setDisplayMode:kPDFDisplaySinglePage];
    [pdfView setDisplayBox:kPDFDisplayBoxCropBox];
    [pdfView setDisplaysPageBreaks:NO];
    [scrollView setAutohidesScrollers:YES];
    [scrollView setHasHorizontalScroller:NO];
    [scrollView setHasVerticalScroller:NO];
    
    [pdfView setCurrentSelection:nil];
    if ([pdfView hasReadingBar])
        [pdfView toggleReadingBar];
    
    [[self presentationNotesDocument] setCurrentPage:[[[self presentationNotesDocument] pdfDocument] pageAtIndex:[[pdfView currentPage] pageIndex]]];
    
    // prevent sleep
    if (activityAssertionID == kIOPMNullAssertionID && kIOReturnSuccess != IOPMAssertionCreateWithName(kIOPMAssertionTypeNoDisplaySleep, kIOPMAssertionLevelOn, CFSTR("Skim"), &activityAssertionID))
        activityAssertionID = kIOPMNullAssertionID;
}

- (void)exitPresentationMode {
    if (activityAssertionID != kIOPMNullAssertionID && kIOReturnSuccess == IOPMAssertionRelease(activityAssertionID))
        activityAssertionID = kIOPMNullAssertionID;
    
    NSScrollView *scrollView = [[pdfView documentView] enclosingScrollView];
    [scrollView setHasHorizontalScroller:[[savedNormalSetup objectForKey:HASHORIZONTALSCROLLER_KEY] boolValue]];
    [scrollView setHasVerticalScroller:[[savedNormalSetup objectForKey:HASVERTICALSCROLLER_KEY] boolValue]];
    [scrollView setAutohidesScrollers:[[savedNormalSetup objectForKey:AUTOHIDESSCROLLERS_KEY] boolValue]];
}

- (void)fadeInFullScreenWindowWithBackgroundColor:(NSColor *)backgroundColor level:(NSInteger)level {
    if ([[mainWindow firstResponder] isDescendantOf:pdfSplitView])
        [mainWindow makeFirstResponder:nil];
    
    SKMainFullScreenWindow *fullScreenWindow = [[SKMainFullScreenWindow alloc] initWithScreen:[mainWindow screen] backgroundColor:backgroundColor level:NSPopUpMenuWindowLevel];
    
    [mainWindow setDelegate:nil];
    [fullScreenWindow fadeInBlocking];
    [self setWindow:fullScreenWindow];  
    [fullScreenWindow makeKeyWindow];
    [mainWindow orderOut:nil];  
    [fullScreenWindow setLevel:level];
    [fullScreenWindow orderFront:nil];
    [NSApp addWindowsItem:fullScreenWindow title:[self windowTitleForDocumentDisplayName:[[self document] displayName]] filename:NO];
    [fullScreenWindow release];
}

- (void)fadeInFullScreenView:(NSView *)view inset:(CGFloat)inset {
    SKMainFullScreenWindow *fullScreenWindow = (SKMainFullScreenWindow *)[self window];
    SKFullScreenWindow *fadeWindow = [[SKFullScreenWindow alloc] initWithScreen:[fullScreenWindow screen] backgroundColor:[fullScreenWindow backgroundColor] level:[fullScreenWindow level]];
    
    [view setFrame:NSInsetRect([[fadeWindow contentView] bounds], inset, 0.0)];
    [[fadeWindow contentView] addSubview:view];
    [fadeWindow setAlphaValue:0.0];
    [pdfView layoutDocumentView];
    [pdfView setNeedsDisplay:YES];
    [fadeWindow orderWindow:NSWindowAbove relativeTo:[fullScreenWindow windowNumber]];
    [fadeWindow fadeInBlocking];
    [[fullScreenWindow contentView] addSubview:view];
    [fullScreenWindow makeFirstResponder:pdfView];
    [fullScreenWindow recalculateKeyViewLoop];
    [fullScreenWindow setDelegate:self];
    [fullScreenWindow display];
    [fadeWindow orderOut:nil];
    [fadeWindow release];
}

- (void)fadeOutFullScreenView:(NSView *)view {
    SKMainFullScreenWindow *fullScreenWindow = (SKMainFullScreenWindow *)[self window];
    SKFullScreenWindow *fadeWindow = [[SKFullScreenWindow alloc] initWithScreen:[fullScreenWindow screen] backgroundColor:[fullScreenWindow backgroundColor] level:[fullScreenWindow level]];
    
    [[fadeWindow contentView] addSubview:view];
    [fadeWindow orderWindow:NSWindowAbove relativeTo:[fullScreenWindow windowNumber]];
    [fadeWindow display];
    [fullScreenWindow display];
    [fullScreenWindow setDelegate:nil];
    [fullScreenWindow makeFirstResponder:nil];
    [fadeWindow fadeOutBlocking];
    [fadeWindow release];
}

- (void)fadeOutFullScreenWindow {
    SKMainFullScreenWindow *fullScreenWindow = (SKMainFullScreenWindow *)[[[self window] retain] autorelease];
    
    [self setWindow:mainWindow];
    // trick to make sure the main window shows up in the same space as the fullscreen window
    [fullScreenWindow addChildWindow:mainWindow ordered:NSWindowBelow];
    [fullScreenWindow removeChildWindow:mainWindow];
    [fullScreenWindow setLevel:NSPopUpMenuWindowLevel];
    // these can change due to the child window trick
    [mainWindow setLevel:NSNormalWindowLevel];
    [mainWindow setCollectionBehavior:NSWindowCollectionBehaviorDefault];
    [mainWindow display];
    [mainWindow makeFirstResponder:pdfView];
    [mainWindow recalculateKeyViewLoop];
    [mainWindow setDelegate:self];
    [mainWindow makeKeyWindow];
    [NSApp removeWindowsItem:fullScreenWindow];
    [fullScreenWindow fadeOut];
}

- (void)showBlankingWindows {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKBlankAllScreensInFullScreenKey] && [[NSScreen screens] count] > 1) {
        if (nil == blankingWindows)
            blankingWindows = [[NSMutableArray alloc] init];
        NSScreen *screen = [[self window] screen];
        NSColor *backgroundColor = [[self window] backgroundColor];
        for (NSScreen *screenToBlank in [NSScreen screens]) {
            if ([screenToBlank isEqual:screen] == NO) {
                SKFullScreenWindow *aWindow = [[SKFullScreenWindow alloc] initWithScreen:screenToBlank backgroundColor:backgroundColor level:NSFloatingWindowLevel];
                [aWindow setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
                [aWindow setHidesOnDeactivate:YES];
                [aWindow fadeIn];
                [blankingWindows addObject:aWindow];
                [aWindow release];
            }
        }
    }
}

- (void)removeBlankingWindows {
    [blankingWindows makeObjectsPerformSelector:@selector(fadeOut)];
    [blankingWindows autorelease];
    blankingWindows = nil;
}

- (IBAction)enterFullscreen:(id)sender {
    SKInteractionMode wasInteractionMode = [self interactionMode];
    if (wasInteractionMode == SKFullScreenMode)
        return;
    
    NSColor *backgroundColor = [[NSUserDefaults standardUserDefaults] colorForKey:SKFullScreenBackgroundColorKey];
    NSDictionary *fullScreenSetup = [[NSUserDefaults standardUserDefaults] dictionaryForKey:SKDefaultFullScreenPDFDisplaySettingsKey];
    PDFPage *page = [[self pdfView] currentPage];
    
    mwcFlags.isSwitchingFullScreen = 1;
    
    if ([[findController view] window])
        [findController toggleAboveView:nil animate:NO];
    
    // remember normal setup to return to, we must do this before changing the interactionMode
    if (wasInteractionMode == SKNormalMode)
        [savedNormalSetup setDictionary:[self currentPDFSettings]];
    
    interactionMode = SKFullScreenMode;
    
    if (wasInteractionMode == SKPresentationMode) {
        [self exitPresentationMode];
        [self hideLeftSideWindow];
        
        [NSApp updatePresentationOptionsForWindow:[self window]];
        
        [pdfView setFrame:[pdfContentView bounds]];
        [pdfContentView addSubview:pdfView];
        [pdfSplitView setFrame:NSInsetRect([[[self window] contentView] bounds], [SKSideWindow requiredMargin], 0.0)];
        [[[self window] contentView] addSubview:pdfSplitView];
        
        [[self window] setBackgroundColor:backgroundColor];
        [[self window] setLevel:NSNormalWindowLevel];
        [pdfView setBackgroundColor:backgroundColor];
        [secondaryPdfView setBackgroundColor:backgroundColor];
        [self applyPDFSettings:[fullScreenSetup count] ? fullScreenSetup : savedNormalSetup];
        [pdfView layoutDocumentView];
        [pdfView setNeedsDisplay:YES];
    } else {
        [self fadeInFullScreenWindowWithBackgroundColor:backgroundColor level:NSNormalWindowLevel];
        
        [pdfView setBackgroundColor:backgroundColor];
        [secondaryPdfView setBackgroundColor:backgroundColor];
        [self applyPDFSettings:fullScreenSetup];
        
        [self fadeInFullScreenView:pdfSplitView inset:[SKSideWindow requiredMargin]];
    }
    
    if ([[[self pdfView] currentPage] isEqual:page] == NO)
        [[self pdfView] goToPage:page];
    
    mwcFlags.isSwitchingFullScreen = 0;
    
    [self forceSubwindowsOnTop:YES];
    
    [pdfView setInteractionMode:SKFullScreenMode];
    
    [self showBlankingWindows];
    [self showLeftSideWindow];
    [self showRightSideWindow];
}

- (IBAction)enterPresentation:(id)sender {
    SKInteractionMode wasInteractionMode = [self interactionMode];
    if (wasInteractionMode == SKPresentationMode)
        return;
    
    NSColor *backgroundColor = [NSColor blackColor];
    NSInteger level = [[NSUserDefaults standardUserDefaults] boolForKey:SKUseNormalLevelForPresentationKey] ? NSNormalWindowLevel : NSPopUpMenuWindowLevel;
    PDFPage *page = [[self pdfView] currentPage];
    
    // remember normal setup to return to, we must do this before changing the interactionMode
    if (wasInteractionMode == SKNormalMode)
        [savedNormalSetup setDictionary:[self currentPDFSettings]];
    
    mwcFlags.isSwitchingFullScreen = 1;
    
    if ([[findController view] window])
        [findController toggleAboveView:nil animate:NO];
    
    interactionMode = SKPresentationMode;
    
    if (wasInteractionMode == SKFullScreenMode) {
        [self enterPresentationMode];
        
        [NSApp updatePresentationOptionsForWindow:[self window]];
        
        [pdfSplitView setFrame:[centerContentView bounds]];
        [centerContentView addSubview:pdfSplitView];
        [pdfView setFrame:[[[self window] contentView] bounds]];
        [[[self window] contentView] addSubview:pdfView];
        
        [[self window] setBackgroundColor:backgroundColor];
        [[self window] setLevel:level];
        [pdfView layoutDocumentView];
        [pdfView setNeedsDisplay:YES];
        
        [self forceSubwindowsOnTop:NO];
        
        [self hideLeftSideWindow];
        [self hideRightSideWindow];
        [self removeBlankingWindows];
    } else {
        [self fadeInFullScreenWindowWithBackgroundColor:backgroundColor level:level];
        
        [self enterPresentationMode];
        
        [self fadeInFullScreenView:pdfView inset:0.0];
    }
    
    if ([[[self pdfView] currentPage] isEqual:page] == NO)
        [[self pdfView] goToPage:page];
    
    mwcFlags.isSwitchingFullScreen = 0;
    
    [pdfView setInteractionMode:SKPresentationMode];
}

- (IBAction)exitFullscreen:(id)sender {
    SKInteractionMode wasInteractionMode = [self interactionMode];
    if (wasInteractionMode == SKNormalMode)
        return;
    
    NSColor *backgroundColor = [[NSUserDefaults standardUserDefaults] colorForKey:SKBackgroundColorKey];
    NSView *view;
    NSView *contentView;
    PDFPage *page = [[self pdfView] currentPage];
    
    mwcFlags.isSwitchingFullScreen = 1;
    
    if ([[findController view] window])
        [findController toggleAboveView:nil animate:NO];
    
    if (wasInteractionMode == SKFullScreenMode) {
        view = pdfSplitView;
        contentView = centerContentView;
    } else {
        view = pdfView;
        contentView = pdfContentView;
    }
    
    [self hideLeftSideWindow];
    [self hideRightSideWindow];
    
    // do this first, otherwise the navigation window may be covered by fadeWindow and then reveiled again, which looks odd
    [pdfView setInteractionMode:SKNormalMode];
    
    [self fadeOutFullScreenView:view];
    
    // this should be done before exitPresentationMode to get a smooth transition
    [view setFrame:[contentView bounds]];
    [contentView addSubview:view];
    [pdfView setBackgroundColor:backgroundColor];
    [secondaryPdfView setBackgroundColor:backgroundColor];
    
    if (wasInteractionMode == SKPresentationMode)
        [self exitPresentationMode];
    [self applyPDFSettings:savedNormalSetup];
    [savedNormalSetup removeAllObjects];
    
    [pdfView layoutDocumentView];
    [pdfView setNeedsDisplay:YES];
    
    if ([[[self pdfView] currentPage] isEqual:page] == NO)
        [[self pdfView] goToPage:page];
    
    mwcFlags.isSwitchingFullScreen = 0;
    
    [self forceSubwindowsOnTop:NO];
    
    interactionMode = SKNormalMode;
    
    [self fadeOutFullScreenWindow];
    
    // the page number may have changed
    [self synchronizeWindowTitleWithDocumentName];
    
    [self removeBlankingWindows];
}

- (BOOL)handleRightMouseDown:(NSEvent *)theEvent {
    if ([self interactionMode] == SKPresentationMode) {
        [self doGoToPreviousPage:nil];
        return YES;
    }
    return NO;
}

#pragma mark Swapping tables

- (void)displayTocViewAnimating:(BOOL)animate {
    [leftSideController replaceSideView:leftSideController.tocOutlineView.enclosingScrollView animate:animate];
    [self updateOutlineSelection];
}

- (void)displayThumbnailViewAnimating:(BOOL)animate {
    [leftSideController replaceSideView:leftSideController.thumbnailTableView.enclosingScrollView animate:animate];
    [self updateThumbnailSelection];
}

- (void)displayFindViewAnimating:(BOOL)animate {
    [leftSideController replaceSideView:leftSideController.findTableView.enclosingScrollView animate:animate];
}

- (void)displayGroupedFindViewAnimating:(BOOL)animate {
    [leftSideController replaceSideView:leftSideController.groupedFindTableView.enclosingScrollView animate:animate];
}

- (void)displayNoteViewAnimating:(BOOL)animate {
    [rightSideController replaceSideView:rightSideController.noteOutlineView.enclosingScrollView animate:animate];
}

- (void)displaySnapshotViewAnimating:(BOOL)animate {
    [rightSideController replaceSideView:rightSideController.snapshotTableView.enclosingScrollView animate:animate];
    [self updateSnapshotsIfNeeded];
}

#pragma mark Searching

- (void)displaySearchResultsForString:(NSString *)string {
    if ([self leftSidePaneIsOpen] == NO)
        [self toggleLeftSidePane:nil];
    [leftSideController.searchField setStringValue:string];
    [self performSelector:@selector(search:) withObject:leftSideController.searchField afterDelay:0.0];
}

- (IBAction)search:(id)sender {

    // cancel any previous find to remove those results, or else they stay around
    if ([[pdfView document] isFinding])
        [[pdfView document] cancelFindString];
    [pdfView setHighlightedSelections:nil];
    
    if ([[sender stringValue] isEqualToString:@""]) {
        
        if (mwcFlags.leftSidePaneState == SKThumbnailSidePaneState)
            [self displayThumbnailViewAnimating:YES];
        else 
            [self displayTocViewAnimating:YES];
    } else {
        NSInteger options = mwcFlags.caseInsensitiveSearch ? NSCaseInsensitiveSearch : 0;
        if (mwcFlags.wholeWordSearch) {
            NSScanner *scanner = [NSScanner scannerWithString:[sender stringValue]];
            NSMutableArray *words = [NSMutableArray array];
            NSString *word;
            [scanner setCharactersToBeSkipped:nil];
            while ([scanner isAtEnd] == NO) {
                if ('"' == [[scanner string] characterAtIndex:[scanner scanLocation]]) {
                    [scanner setScanLocation:[scanner scanLocation] + 1];
                    if ([scanner scanUpToString:@"\"" intoString:&word])
                        [words addObject:word];
                    if ([scanner isAtEnd] == NO)
                        [scanner setScanLocation:[scanner scanLocation] + 1];
                } else if ([scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:&word]) {
                    [words addObject:word];
                }
                [scanner scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:NULL];
            }
            [[pdfView document] beginFindStrings:words withOptions:options];
        } else {
            [[pdfView document] beginFindString:[sender stringValue] withOptions:options];
        }
        if (mwcFlags.findPaneState == SKSingularFindPaneState)
            [self displayFindViewAnimating:YES];
        else
            [self displayGroupedFindViewAnimating:YES];
        
        NSPasteboard *findPboard = [NSPasteboard pasteboardWithName:NSFindPboard];
        [findPboard clearContents];
        [findPboard writeObjects:[NSArray arrayWithObjects:[sender stringValue], nil]];
    }
}

- (BOOL)findString:(NSString *)string forward:(BOOL)forward {
    PDFSelection *sel = [pdfView currentSelection];
    NSUInteger pageIndex = [[pdfView currentPage] pageIndex];
    PDFDocument *pdfDoc = [pdfView document];
    NSInteger options = 0;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKCaseInsensitiveFindKey])
        options |= NSCaseInsensitiveSearch;
    if (forward == NO)
        options |= NSBackwardsSearch;
    while ([sel hasCharacters] == NO && (forward ? pageIndex-- > 0 : ++pageIndex < [pdfDoc pageCount])) {
        PDFPage *page = [[pdfView document] pageAtIndex:pageIndex];
        NSUInteger length = [[page string] length];
        if (length > 0)
            sel = [page selectionForRange:NSMakeRange(0, length)];
    }
    PDFSelection *selection = [pdfDoc findString:string fromSelection:sel withOptions:options];
    if ([selection hasCharacters] == NO && [sel hasCharacters])
        selection = [pdfDoc findString:string fromSelection:nil withOptions:options];
    if (selection) {
        [pdfView setCurrentSelection:selection];
		[pdfView scrollSelectionToVisible:self];
        [leftSideController.findTableView deselectAll:self];
        [leftSideController.groupedFindTableView deselectAll:self];
        [pdfView setCurrentSelection:selection animate:YES];
        return YES;
	} else {
		NSBeep();
        return NO;
	}
}

- (void)showFindBar {
    if (findController == nil) {
        findController = [[SKFindController alloc] init];
        [findController setDelegate:self];
    }
    if ([[findController view] window] == nil)
        [findController toggleAboveView:(interactionMode == SKFullScreenMode ? pdfSplitView : splitView) animate:YES];
    [[findController findField] selectText:nil];
}

#define FIND_RESULT_MARGIN 50.0

- (void)updateFindResultHighlightsForDirection:(NSSelectionDirection)direction {
    NSArray *findResults = nil;
    
    if (mwcFlags.findPaneState == SKSingularFindPaneState && [leftSideController.findTableView window])
        findResults = [leftSideController.findArrayController selectedObjects];
    else if (mwcFlags.findPaneState == SKGroupedFindPaneState && [leftSideController.groupedFindTableView window])
        findResults = [[leftSideController.groupedFindArrayController selectedObjects] valueForKeyPath:@"@unionOfArrays.matches"];
    
    if ([findResults count] == 0) {
        
        [pdfView setHighlightedSelections:nil];
        
    } else {
        
        if (direction == NSDirectSelection) {
            searchResultIndex = 0;
        } else if (direction == NSSelectingNext) {
            if (++searchResultIndex >= (NSInteger)[findResults count])
                searchResultIndex = 0;
        } else if (direction == NSSelectingPrevious) {
            if (--searchResultIndex < 0)
                searchResultIndex = [findResults count] - 1;
        }
    
        PDFSelection *currentSel = [findResults objectAtIndex:searchResultIndex];
        
        if ([currentSel hasCharacters]) {
            PDFPage *page = [currentSel safeFirstPage];
            NSRect rect = NSZeroRect;
            
            for (PDFSelection *sel in findResults) {
                if ([[sel pages] containsObject:page])
                    rect = NSUnionRect(rect, [sel boundsForPage:page]);
            }
            rect = NSIntersectionRect(NSInsetRect(rect, -FIND_RESULT_MARGIN, -FIND_RESULT_MARGIN), [page boundsForBox:kPDFDisplayBoxCropBox]);
            [pdfView goToPage:page];
            [pdfView goToRect:rect onPage:page];
        }
        
        NSArray *highlights = [[NSArray alloc] initWithArray:findResults copyItems:YES];
        [highlights setValue:[NSColor yellowColor] forKey:@"color"];
        [pdfView setHighlightedSelections:highlights];
        [highlights release];
        
        if ([currentSel hasCharacters])
            [pdfView setCurrentSelection:currentSel animate:YES];
        if ([pdfView toolMode] == SKMoveToolMode || [pdfView toolMode] == SKMagnifyToolMode || [pdfView toolMode] == SKSelectToolMode)
            [pdfView setCurrentSelection:nil];
    }
}

- (void)goToSelectedFindResults:(id)sender {
    [self updateFindResultHighlightsForDirection:NSDirectSelection];
}

- (IBAction)searchNotes:(id)sender {
    if (mwcFlags.rightSidePaneState == SKNoteSidePaneState)
        [self updateNoteFilterPredicate];
    else
        [self updateSnapshotFilterPredicate];
    if ([[sender stringValue] length]) {
        NSPasteboard *findPboard = [NSPasteboard pasteboardWithName:NSFindPboard];
        [findPboard clearContents];
        [findPboard writeObjects:[NSArray arrayWithObjects:[sender stringValue], nil]];
    }
}

#pragma mark PDFDocument delegate

- (void)didMatchString:(PDFSelection *)instance {
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
    
    PDFPage *page = [instance safeFirstPage];
    NSRect bounds = [instance boundsForPage:page];
    NSInteger i = [searchResults count];
    while (i-- > 0) {
        PDFSelection *prevResult = [searchResults objectAtIndex:i];
        PDFPage *prevPage = [prevResult safeFirstPage];
        if ([page isEqual:prevPage] == NO || SKCompareRects(bounds, [prevResult boundsForPage:prevPage]) != NSOrderedAscending)
            break;
    }
    [searchResults insertObject:instance atIndex:i + 1];
    
    SKGroupedSearchResult *result = [groupedSearchResults lastObject];
    NSUInteger maxCount = [result maxCount];
    if ([[result page] isEqual:page] == NO) {
        result = [SKGroupedSearchResult groupedSearchResultWithPage:page maxCount:maxCount];
        [groupedSearchResults addObject:result];
    }
    [result addMatch:instance];
    
    if ([result count] > maxCount) {
        maxCount = [result count];
        for (result in groupedSearchResults)
            [result setMaxCount:maxCount];
    }
}

- (void)documentDidBeginDocumentFind:(NSNotification *)note {
    NSString *message = [NSLocalizedString(@"Searching", @"Message in search table header") stringByAppendingEllipsis];
    [self setSearchResults:nil];
    [[[leftSideController.findTableView tableColumnWithIdentifier:RESULTS_COLUMNID] headerCell] setStringValue:message];
    [[leftSideController.findTableView headerView] setNeedsDisplay:YES];
    [[[leftSideController.groupedFindTableView tableColumnWithIdentifier:RELEVANCE_COLUMNID] headerCell] setStringValue:message];
    [[leftSideController.groupedFindTableView headerView] setNeedsDisplay:YES];
    [self setGroupedSearchResults:nil];
    [statusBar setProgressIndicatorStyle:SKProgressIndicatorBarStyle];
    [[statusBar progressIndicator] setMaxValue:[[note object] pageCount]];
    [[statusBar progressIndicator] setDoubleValue:0.0];
    [statusBar startAnimation:self];
    [self willChangeValueForKey:SEARCHRESULTS_KEY];
    [self willChangeValueForKey:GROUPEDSEARCHRESULTS_KEY];
}

- (void)documentDidEndDocumentFind:(NSNotification *)note {
    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"%ld Results", @"Message in search table header"), (long)[searchResults count]];
    [self didChangeValueForKey:GROUPEDSEARCHRESULTS_KEY];
    [self didChangeValueForKey:SEARCHRESULTS_KEY];
    [[[leftSideController.findTableView tableColumnWithIdentifier:RESULTS_COLUMNID] headerCell] setStringValue:message];
    [[leftSideController.findTableView headerView] setNeedsDisplay:YES];
    [[[leftSideController.groupedFindTableView tableColumnWithIdentifier:RELEVANCE_COLUMNID] headerCell] setStringValue:message];
    [[leftSideController.groupedFindTableView headerView] setNeedsDisplay:YES];
    [statusBar stopAnimation:self];
    [statusBar setProgressIndicatorStyle:SKProgressIndicatorNone];
}

- (void)documentDidEndPageFind:(NSNotification *)note {
    NSNumber *pageIndex = [[note userInfo] objectForKey:@"PDFDocumentPageIndex"];
    [[statusBar progressIndicator] setDoubleValue:[pageIndex doubleValue]];
    if ([pageIndex unsignedIntegerValue] % 50 == 0) {
        [self didChangeValueForKey:GROUPEDSEARCHRESULTS_KEY];
        [self didChangeValueForKey:SEARCHRESULTS_KEY];
        [self willChangeValueForKey:SEARCHRESULTS_KEY];
        [self willChangeValueForKey:GROUPEDSEARCHRESULTS_KEY];
    }
}

- (void)documentDidUnlockDelayed {
    NSUInteger pageIndex = [[savedNormalSetup objectForKey:PAGEINDEX_KEY] unsignedIntegerValue];
    NSArray *snapshotSetups = [savedNormalSetup objectForKey:SNAPSHOTS_KEY];
    [self applyPDFSettings:[savedNormalSetup objectForKey:AUTOSCALES_KEY] ? savedNormalSetup : [[NSUserDefaults standardUserDefaults] dictionaryForKey:SKDefaultPDFDisplaySettingsKey]];
    if (pageIndex != NSNotFound) {
        [lastViewedPages setCount:0];
        [pdfView goToPage:[[pdfView document] pageAtIndex:pageIndex]];
        [pdfView resetHistory];
    }
    if ([snapshotSetups count]) {
        [self showSnapshotsWithSetups:snapshotSetups];
    }
    [savedNormalSetup removeAllObjects];
}

- (void)documentDidUnlock:(NSNotification *)notification {
    [self updatePageLabelsAndOutlineForExpansionState:nil];
    // when the PDF was locked, PDFView resets the display settings, so we need to reapply them, however if don't delay it's reset again immediately
    if ([self presentationOptions] == SKNormalMode)
        [self performSelector:@selector(documentDidUnlockDelayed) withObject:nil afterDelay:0.0];
}

- (void)document:(PDFDocument *)aDocument didUnlockWithPassword:(NSString *)password {
    [[self document] savePasswordInKeychain:password];
}

#pragma mark PDFDocument notifications

- (void)handlePageBoundsDidChangeNotification:(NSNotification *)notification {
    NSDictionary *info = [notification userInfo];
    PDFPage *page = [info objectForKey:SKPDFPagePageKey];
    NSString *action = [info objectForKey:SKPDFPageActionKey];
    BOOL displayChanged = [action isEqualToString:SKPDFPageActionCrop] == NO || [pdfView displayBox] == kPDFDisplayBoxCropBox;
        
    if (displayChanged)
        [pdfView layoutDocumentView];
    if (page) {
        NSUInteger idx = [page pageIndex];
        for (SKSnapshotWindowController *wc in snapshots) {
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
    [self beginProgressSheetWithMessage:[NSLocalizedString(@"Exporting PDF", @"Message for progress sheet") stringByAppendingEllipsis] maxValue:[[pdfView document] pageCount]];
}

- (void)handleDocumentEndWrite:(NSNotification *)notification {
    [self dismissProgressSheet];
}

- (void)handleDocumentEndPageWrite:(NSNotification *)notification {
    [self incrementProgressSheet];
}

- (void)registerForDocumentNotifications {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    PDFDocument *pdfDoc = [pdfView document];
    [nc addObserver:self selector:@selector(handleDocumentBeginWrite:) 
                             name:PDFDocumentDidBeginWriteNotification object:pdfDoc];
    [nc addObserver:self selector:@selector(handleDocumentEndWrite:) 
                             name:PDFDocumentDidEndWriteNotification object:pdfDoc];
    [nc addObserver:self selector:@selector(handleDocumentEndPageWrite:) 
                             name:PDFDocumentDidEndPageWriteNotification object:pdfDoc];
    [nc addObserver:self selector:@selector(handlePageBoundsDidChangeNotification:) 
                             name:SKPDFPageBoundsDidChangeNotification object:pdfDoc];
}

- (void)unregisterForDocumentNotifications {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    PDFDocument *pdfDoc = [pdfView document];
    [nc removeObserver:self name:PDFDocumentDidBeginWriteNotification object:pdfDoc];
    [nc removeObserver:self name:PDFDocumentDidEndWriteNotification object:pdfDoc];
    [nc removeObserver:self name:PDFDocumentDidEndPageWriteNotification object:pdfDoc];
    [nc removeObserver:self name:SKPDFPageBoundsDidChangeNotification object:pdfDoc];
}

#pragma mark Subwindows

- (void)showSnapshotAtPageNumber:(NSInteger)pageNum forRect:(NSRect)rect scaleFactor:(CGFloat)scaleFactor autoFits:(BOOL)autoFits {
    SKSnapshotWindowController *swc = [[SKSnapshotWindowController alloc] init];
    
    [swc setDelegate:self];
    
    [swc setPdfDocument:[pdfView document]
         goToPageNumber:pageNum
                   rect:rect
            scaleFactor:scaleFactor
               autoFits:autoFits];
    
    [swc setForceOnTop:[self interactionMode] != SKNormalMode];
    
    [[self document] addWindowController:swc];
    [swc release];
}

- (void)showSnapshotsWithSetups:(NSArray *)setups {
    for (NSDictionary *setup in setups) {
        SKSnapshotWindowController *swc = [[SKSnapshotWindowController alloc] init];
        
        [swc setDelegate:self];
        
        [swc setPdfDocument:[pdfView document] setup:setup];
        
        [swc setForceOnTop:[self interactionMode] != SKNormalMode];
        
        [[self document] addWindowController:swc];
        [swc release];
    }
}

- (void)toggleSelectedSnapshots:(id)sender {
    // there should only be a single snapshot
    SKSnapshotWindowController *controller = [[rightSideController.snapshotArrayController selectedObjects] lastObject];
    
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

- (void)snapshotControllerWillClose:(SKSnapshotWindowController *)controller {
    [[self mutableArrayValueForKey:SNAPSHOTS_KEY] removeObject:controller];
}

- (void)snapshotControllerDidChange:(SKSnapshotWindowController *)controller {
    [self snapshotNeedsUpdate:controller];
    if (mwcFlags.rightSidePaneState == SKSnapshotSidePaneState && [[rightSideController.searchField stringValue] length] > 0)
        [rightSideController.snapshotArrayController rearrangeObjects];
}

- (void)hideRightSideWindow:(NSTimer *)timer {
    [rightSideWindow collapse];
}

- (NSRect)snapshotController:(SKSnapshotWindowController *)controller miniaturizedRect:(BOOL)isMiniaturize {
    NSUInteger row = [[rightSideController.snapshotArrayController arrangedObjects] indexOfObject:controller];
    if (isMiniaturize && [self interactionMode] != SKPresentationMode) {
        if ([self interactionMode] == SKNormalMode && [self rightSidePaneIsOpen] == NO) {
            [self toggleRightSidePane:self];
        } else if ([self interactionMode] == SKFullScreenMode && ([rightSideWindow state] == NSDrawerClosedState || [rightSideWindow state] == NSDrawerClosingState)) {
            [rightSideWindow expand];
            [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(hideRightSideWindow:) userInfo:NULL repeats:NO];
        }
        [self setRightSidePaneState:SKSnapshotSidePaneState];
        if (row != NSNotFound)
            [rightSideController.snapshotTableView scrollRowToVisible:row];
    }
    NSRect rect = NSZeroRect;
    if (row != NSNotFound) {
        rect = [rightSideController.snapshotTableView frameOfCellAtColumn:0 row:row];
    } else {
        rect.origin = SKBottomLeftPoint([rightSideController.snapshotTableView visibleRect]);
        rect.size.width = rect.size.height = 1.0;
    }
    rect = [rightSideController.snapshotTableView convertRect:rect toView:nil];
    rect.origin = [[rightSideController.snapshotTableView window] convertBaseToScreen:rect.origin];
    return rect;
}

- (void)showNote:(PDFAnnotation *)annotation {
    NSWindowController *wc = [self windowControllerForNote:annotation];
    if (wc == nil) {
        wc = [[SKNoteWindowController alloc] initWithNote:annotation];
        [(SKNoteWindowController *)wc setForceOnTop:[self interactionMode] != SKNormalMode];
        [[self document] addWindowController:wc];
        [wc release];
    }
    [wc showWindow:self];
}

- (NSWindowController *)windowControllerForNote:(PDFAnnotation *)annotation {
    for (id wc in [[self document] windowControllers]) {
        if ([wc isNoteWindowController] && [[wc note] isEqual:annotation])
            return wc;
    }
    return nil;
}

#pragma mark Observer registration

- (void)registerAsObserver {
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeys:
        [NSArray arrayWithObjects:SKBackgroundColorKey, SKFullScreenBackgroundColorKey, SKPageBackgroundColorKey, 
                                  SKThumbnailSizeKey, SKSnapshotThumbnailSizeKey, 
                                  SKShouldAntiAliasKey, SKGreekingThresholdKey, 
                                  SKTableFontSizeKey, nil]
        context:&SKMainWindowDefaultsObservationContext];
}

- (void)unregisterAsObserver {
    @try {
        [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeys:
            [NSArray arrayWithObjects:SKBackgroundColorKey, SKFullScreenBackgroundColorKey, SKPageBackgroundColorKey, 
                                      SKThumbnailSizeKey, SKSnapshotThumbnailSizeKey, 
                                      SKShouldAntiAliasKey, SKGreekingThresholdKey, 
                                      SKTableFontSizeKey, nil]];
    }
    @catch (id e) {}
}

#pragma mark Undo

- (void)startObservingNotes:(NSArray *)newNotes {
    // Each note can have a different set of properties that need to be observed.
    for (PDFAnnotation *note in newNotes) {
        for (NSString *key in [note keysForValuesToObserveForUndo]) {
            // We use NSKeyValueObservingOptionOld because when something changes we want to record the old value, which is what has to be set in the undo operation. We use NSKeyValueObservingOptionNew because we compare the new value against the old value in an attempt to ignore changes that aren't really changes.
            [note addObserver:self forKeyPath:key options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:&SKPDFAnnotationPropertiesObservationContext];
        }
    }
}

- (void)stopObservingNotes:(NSArray *)oldNotes {
    // Do the opposite of what's done in -startObservingNotes:.
    for (PDFAnnotation *note in oldNotes) {
        for (NSString *key in [note keysForValuesToObserveForUndo])
            [note removeObserver:self forKeyPath:key];
    }
}

- (void)setNoteProperties:(NSMapTable *)propertiesPerNote {
    // The passed-in dictionary is keyed by note...
    for (PDFAnnotation *note in propertiesPerNote) {
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
            if ([self interactionMode] == SKNormalMode) {
                [pdfView setBackgroundColor:[[NSUserDefaults standardUserDefaults] colorForKey:SKBackgroundColorKey]];
                [secondaryPdfView setBackgroundColor:[[NSUserDefaults standardUserDefaults] colorForKey:SKBackgroundColorKey]];
            }
        } else if ([key isEqualToString:SKFullScreenBackgroundColorKey]) {
            if ([self interactionMode] == SKFullScreenMode) {
                NSColor *color = [[NSUserDefaults standardUserDefaults] colorForKey:SKFullScreenBackgroundColorKey];
                if (color) {
                    [pdfView setBackgroundColor:color];
                    [secondaryPdfView setBackgroundColor:color];
                    [[self window] setBackgroundColor:color];
                    [[[self window] contentView] setNeedsDisplay:YES];
                    
                    for (NSWindow *window in blankingWindows) {
                        [window setBackgroundColor:color];
                        [[window contentView] setNeedsDisplay:YES];
                    }
                }
            }
        } else if ([key isEqualToString:SKPageBackgroundColorKey]) {
            [pdfView setNeedsDisplay:YES];
            [secondaryPdfView setNeedsDisplay:YES];
            [self allThumbnailsNeedUpdate];
            [self allSnapshotsNeedUpdate];
        } else if ([key isEqualToString:SKThumbnailSizeKey]) {
            [self resetThumbnailSizeIfNeeded];
            [leftSideController.thumbnailTableView noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self countOfThumbnails])]];
        } else if ([key isEqualToString:SKSnapshotThumbnailSizeKey]) {
            [self resetSnapshotSizeIfNeeded];
            [rightSideController.snapshotTableView noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self countOfSnapshots])]];
        } else if ([key isEqualToString:SKShouldAntiAliasKey]) {
            [pdfView setShouldAntiAlias:[[NSUserDefaults standardUserDefaults] boolForKey:SKShouldAntiAliasKey]];
            [secondaryPdfView setShouldAntiAlias:[[NSUserDefaults standardUserDefaults] boolForKey:SKShouldAntiAliasKey]];
        } else if ([key isEqualToString:SKGreekingThresholdKey]) {
            [pdfView setGreekingThreshold:[[NSUserDefaults standardUserDefaults] floatForKey:SKGreekingThresholdKey]];
            [secondaryPdfView setGreekingThreshold:[[NSUserDefaults standardUserDefaults] floatForKey:SKGreekingThresholdKey]];
        } else if ([key isEqualToString:SKTableFontSizeKey]) {
            [self updateTableFont];
            [self updatePageColumnWidthForTableView:leftSideController.tocOutlineView];
            [self updatePageColumnWidthForTableView:rightSideController.noteOutlineView];
            [self updatePageColumnWidthForTableView:leftSideController.findTableView];
            [self updatePageColumnWidthForTableView:leftSideController.groupedFindTableView];
        }
        
    } else if (context == &SKPDFAnnotationPropertiesObservationContext) {
        
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
            BOOL isUndoOrRedo = ([undoManager isUndoing] || [undoManager isRedoing]);
            if (undoGroupOldPropertiesPerNote == nil) {
                // We haven't recorded changes for any notes at all since the last undo manager checkpoint. Get ready to start collecting them. We don't want to copy the PDFAnnotations though.
                undoGroupOldPropertiesPerNote = [[NSMapTable alloc] initWithKeyOptions:NSMapTableZeroingWeakMemory | NSMapTableObjectPointerPersonality valueOptions:NSMapTableStrongMemory | NSMapTableObjectPointerPersonality capacity:0];
                // Register an undo operation for any note property changes that are going to be coalesced between now and the next invocation of -observeUndoManagerCheckpoint:.
                [undoManager registerUndoWithTarget:self selector:@selector(setNoteProperties:) object:undoGroupOldPropertiesPerNote];
                // Don't set the undo action name during undoing and redoing
                if (isUndoOrRedo == NO)
                    [undoManager setActionName:NSLocalizedString(@"Edit Note", @"Undo action name")];
            }

            // Find the dictionary in which we're recording the old values of properties for the changed note
            NSMutableDictionary *oldNoteProperties = [undoGroupOldPropertiesPerNote objectForKey:note];
            if (oldNoteProperties == nil) {
                // We have to create a dictionary to hold old values for the changed note
                oldNoteProperties = [[NSMutableDictionary alloc] init];
                // -setValue:forKey: copies, even if the callback doesn't, so we need to use CF functions
                [undoGroupOldPropertiesPerNote setObject:oldNoteProperties forKey:note];
                [oldNoteProperties release];
                // set the mod date here, need to do that only once for each note for a real user action
                if ([[NSUserDefaults standardUserDefaults] boolForKey:SKDisableModificationDateKey] == NO && isUndoOrRedo == NO && [keyPath isEqualToString:SKNPDFAnnotationModificationDateKey] == NO)
                    [note setModificationDate:[NSDate date]];
            }
            
            // Record the old value for the changed property, unless an older value has already been recorded for the current undo group. Here we're "casting" a KVC key path to a dictionary key, but that should be OK. -[NSMutableDictionary setObject:forKey:] doesn't know the difference.
            if ([oldNoteProperties objectForKey:keyPath] == nil)
                [oldNoteProperties setObject:oldValue forKey:keyPath];
            
            // Update the UI, we should always do that unless the value did not really change or we're just changing the mod date or user name
            if ([keyPath isEqualToString:SKNPDFAnnotationModificationDateKey] == NO && [keyPath isEqualToString:SKNPDFAnnotationUserNameKey] == NO) {
                PDFPage *page = [note page];
                NSRect oldRect = NSZeroRect;
                if ([keyPath isEqualToString:SKNPDFAnnotationBoundsKey] && [oldValue isEqual:[NSNull null]] == NO) {
                    oldRect = [note displayRectForBounds:[oldValue rectValue] lineWidth:[note lineWidth]];
                } else if ([keyPath isEqualToString:SKNPDFAnnotationBorderKey] && [oldValue isEqual:[NSNull null]] == NO) {
                    if ([oldValue lineWidth] > [note lineWidth])
                        oldRect = [note displayRectForBounds:[note bounds] lineWidth:[oldValue lineWidth]];
                }
                
                [self updateThumbnailAtPageIndex:[note pageIndex]];
                
                for (SKSnapshotWindowController *wc in snapshots) {
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
                    if ([note isResizable]) {
                        CGFloat margin = 4.0 / [pdfView scaleFactor];
                        oldRect = NSInsetRect(oldRect, -margin, -margin);
                    }
                    [pdfView setNeedsDisplayInRect:oldRect ofPage:page];
                    [secondaryPdfView setNeedsDisplayInRect:oldRect ofPage:page];
                }
                
                if ([keyPath isEqualToString:SKNPDFAnnotationBoundsKey]) {
                    NSRect oldBounds = NSZeroRect, newBounds = NSZeroRect;
                    if ([oldValue isEqual:[NSNull null]] == NO)
                        oldBounds = [oldValue rectValue];
                    if ([newValue isEqual:[NSNull null]] == NO)
                        newBounds = [newValue rectValue];
                    if (NSEqualSizes(oldBounds.size, newBounds.size) == NO)
                        NSAccessibilityPostNotification([SKAccessibilityProxyFauxUIElement elementWithObject:note parent:[pdfView documentView]], NSAccessibilityResizedNotification);
                    if (NSEqualPoints(oldBounds.origin, newBounds.origin) == NO)
                        NSAccessibilityPostNotification([SKAccessibilityProxyFauxUIElement elementWithObject:note parent:[pdfView documentView]], NSAccessibilityMovedNotification);
                    
                    if ([note isNote]) {
                        [pdfView annotationsChangedOnPage:[note page]];
                        [pdfView resetPDFToolTipRects];
                    }
                    
                    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKDisplayNoteBoundsKey]) {
                        [self updateRightStatus];
                    }
                } else if (([keyPath isEqualToString:SKNPDFAnnotationStringKey] || [keyPath isEqualToString:SKNPDFAnnotationTextKey]) &&
                           [[note accessibilityAttributeNames] containsObject:NSAccessibilityValueAttribute]) {
                    NSAccessibilityPostNotification([SKAccessibilityProxyFauxUIElement elementWithObject:note parent:[pdfView documentView]], NSAccessibilityValueChangedNotification);
                }
            }
            
            if ([keyPath isEqualToString:SKNPDFAnnotationBoundsKey] || [keyPath isEqualToString:SKNPDFAnnotationStringKey] || [keyPath isEqualToString:SKNPDFAnnotationTextKey] || [keyPath isEqualToString:SKNPDFAnnotationColorKey] || [keyPath isEqualToString:SKNPDFAnnotationUserNameKey] || [keyPath isEqualToString:SKNPDFAnnotationModificationDateKey]) {
                [rightSideController.noteArrayController rearrangeObjects];
                [rightSideController.noteOutlineView reloadData];
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
    if ([[pdfView document] outlineRoot] == nil)
        return -1;
    
	NSInteger i, numRows = [leftSideController.tocOutlineView numberOfRows];
	for (i = 0; i < numRows; i++) {
		// Get the destination of the given row....
		PDFOutline *outlineItem = [leftSideController.tocOutlineView itemAtRow:i];
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
	if ([[pdfView document] outlineRoot] == nil || mwcFlags.updatingOutlineSelection)
		return;
	
	// Get index of current page.
	NSUInteger pageIndex = [[pdfView currentPage] pageIndex];
    
	// Test that the current selection is still valid.
	NSInteger row = [leftSideController.tocOutlineView selectedRow];
    if (row == -1 || [[[[leftSideController.tocOutlineView itemAtRow:row] destination] page] pageIndex] != pageIndex) {
        row = [self outlineRowForPageIndex:pageIndex];
        if (row != -1) {
            mwcFlags.updatingOutlineSelection = 1;
            [leftSideController.tocOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
            mwcFlags.updatingOutlineSelection = 0;
        }
    }
}

#pragma mark Thumbnails

- (void)makeImageForThumbnail:(SKThumbnail *)thumbnail {
    NSSize newSize, oldSize = [thumbnail size];
    PDFDocument *pdfDoc = [pdfView document];
    PDFPage *page = [pdfDoc pageAtIndex:[thumbnail pageIndex]];
    SKReadingBar *readingBar = [[[pdfView readingBar] page] isEqual:page] ? [pdfView readingBar] : nil;
    NSImage *image = [page thumbnailWithSize:thumbnailCacheSize forBox:[pdfView displayBox] readingBar:readingBar];
    
    [thumbnail setImage:image];
    
    newSize = [image size];
    if (fabs(newSize.width - oldSize.width) > 1.0 || fabs(newSize.height - oldSize.height) > 1.0)
        [leftSideController.thumbnailTableView noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:[thumbnail pageIndex]]];
}

- (BOOL)generateImageForThumbnail:(SKThumbnail *)thumbnail {
    if ([leftSideController.thumbnailTableView isScrolling] || [[pdfView document] isLocked] || [presentationSheetController isScrolling])
        return NO;
    [self performSelector:@selector(makeImageForThumbnail:) withObject:thumbnail afterDelay:0.0];
    return YES;
}

- (void)updateThumbnailSelection {
	// Get index of current page.
	NSUInteger pageIndex = [[pdfView currentPage] pageIndex];
    mwcFlags.updatingThumbnailSelection = 1;
    [leftSideController.thumbnailTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:pageIndex] byExtendingSelection:NO];
    [leftSideController.thumbnailTableView scrollRowToVisible:pageIndex];
    mwcFlags.updatingThumbnailSelection = 0;
}

- (void)resetThumbnails {
    // cancel all delayed perform requests for makeImageForThumbnail:
    for (SKThumbnail *tn in thumbnails)
        [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(makeImageForThumbnail:) object:tn];
    [self willChangeValueForKey:THUMBNAILS_KEY];
    [thumbnails removeAllObjects];
    if ([pageLabels count] > 0) {
        PDFPage *firstPage = [[pdfView document] pageAtIndex:0];
        PDFPage *emptyPage = [[[SKPDFPage alloc] init] autorelease];
        [emptyPage setBounds:[firstPage boundsForBox:kPDFDisplayBoxCropBox] forBox:kPDFDisplayBoxCropBox];
        [emptyPage setBounds:[firstPage boundsForBox:kPDFDisplayBoxMediaBox] forBox:kPDFDisplayBoxMediaBox];
        [emptyPage setRotation:[firstPage rotation]];
        NSImage *image = [emptyPage thumbnailWithSize:thumbnailCacheSize forBox:[pdfView displayBox]];
        [image lockFocus];
        NSRect imgRect = NSZeroRect;
        imgRect.size = [image size];
        CGFloat width = 0.8 * fmin(NSWidth(imgRect), NSHeight(imgRect));
        imgRect = NSInsetRect(imgRect, 0.5 * (NSWidth(imgRect) - width), 0.5 * (NSHeight(imgRect) - width));
        [[NSImage imageNamed:@"NSApplicationIcon"] drawInRect:imgRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:0.5];
        if ([[pdfView document] isLocked])
            [[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kLockedBadgeIcon)] drawInRect:imgRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:0.5];
        [image unlockFocus];
        
        [pageLabels enumerateObjectsUsingBlock:^(id label, NSUInteger i, BOOL *stop) {
            SKThumbnail *thumbnail = [[SKThumbnail alloc] initWithImage:image label:label pageIndex:i];
            [thumbnail setDelegate:self];
            [thumbnail setDirty:YES];
            [thumbnails addObject:thumbnail];
            [thumbnail release];
        }];
    }
    [self didChangeValueForKey:THUMBNAILS_KEY];
    [self allThumbnailsNeedUpdate];
}

- (void)resetThumbnailSizeIfNeeded {
    roundedThumbnailSize = round([[NSUserDefaults standardUserDefaults] floatForKey:SKThumbnailSizeKey]);

    CGFloat defaultSize = roundedThumbnailSize;
    CGFloat thumbnailSize = (defaultSize < TINY_SIZE + FUDGE_SIZE) ? TINY_SIZE : (defaultSize < SMALL_SIZE + FUDGE_SIZE) ? SMALL_SIZE : (defaultSize < LARGE_SIZE + FUDGE_SIZE) ? LARGE_SIZE : HUGE_SIZE;
    
    if (fabs(thumbnailSize - thumbnailCacheSize) > FUDGE_SIZE) {
        thumbnailCacheSize = thumbnailSize;
        
        if ([self countOfThumbnails])
            [self allThumbnailsNeedUpdate];
    }
}

- (void)updateThumbnailAtPageIndex:(NSUInteger)anIndex {
    SKThumbnail *tn = [self objectInThumbnailsAtIndex:anIndex];
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(makeImageForThumbnail:) object:tn];
    [tn setDirty:YES];
    [leftSideController.thumbnailTableView reloadData];
}

- (void)allThumbnailsNeedUpdate {
    for (SKThumbnail *tn in thumbnails) {
        [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(makeImageForThumbnail:) object:tn];
        [tn setDirty:YES];
    }
    [leftSideController.thumbnailTableView reloadData];
}

#pragma mark Notes

- (void)updateNoteSelection {

    NSArray *orderedNotes = [rightSideController.noteArrayController arrangedObjects];
    __block PDFAnnotation *selAnnotation = nil;
    NSUInteger pageIndex = [[pdfView currentPage] pageIndex];
    NSMutableIndexSet *selPageIndexes = [NSMutableIndexSet indexSet];
    
    for (selAnnotation in [self selectedNotes])
        [selPageIndexes addIndex:[selAnnotation pageIndex]];
    
    if ([orderedNotes count] == 0 || [selPageIndexes containsIndex:pageIndex])
		return;
	
	// Walk outline view looking for best firstpage number match.
    [orderedNotes enumerateObjectsUsingBlock:^(id annotation, NSUInteger i, BOOL *stop) {
		if ([annotation pageIndex] == pageIndex) {
            selAnnotation = annotation;
			*stop = YES;
		} else if ([annotation pageIndex] > pageIndex) {
			if (i == 0)
				selAnnotation = [orderedNotes objectAtIndex:0];
			else if ([selPageIndexes containsIndex:[[orderedNotes objectAtIndex:i - 1] pageIndex]])
                selAnnotation = [orderedNotes objectAtIndex:i - 1];
			*stop = YES;
		}
    }];
    if (selAnnotation) {
        mwcFlags.updatingNoteSelection = 1;
        [rightSideController.noteOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:[rightSideController.noteOutlineView rowForItem:selAnnotation]] byExtendingSelection:NO];
        mwcFlags.updatingNoteSelection = 0;
    }
}

- (void)updateNoteFilterPredicate {
    [rightSideController.noteArrayController setFilterPredicate:[noteTypeSheetController filterPredicateForSearchString:[rightSideController.searchField stringValue] caseInsensitive:mwcFlags.caseInsensitiveNoteSearch]];
    [rightSideController.noteOutlineView reloadData];
}

#pragma mark Snapshots

- (void)resetSnapshotSizeIfNeeded {
    roundedSnapshotThumbnailSize = round([[NSUserDefaults standardUserDefaults] floatForKey:SKSnapshotThumbnailSizeKey]);
    CGFloat defaultSize = roundedSnapshotThumbnailSize;
    CGFloat snapshotSize = (defaultSize < TINY_SIZE + FUDGE_SIZE) ? TINY_SIZE : (defaultSize < SMALL_SIZE + FUDGE_SIZE) ? SMALL_SIZE : (defaultSize < LARGE_SIZE + FUDGE_SIZE) ? LARGE_SIZE : HUGE_SIZE;
    
    if (fabs(snapshotSize - snapshotCacheSize) > FUDGE_SIZE) {
        snapshotCacheSize = snapshotSize;
        
        if (snapshotTimer) {
            [snapshotTimer invalidate];
            SKDESTROY(snapshotTimer);
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
    if ([rightSideController.snapshotTableView window] != nil && [dirtySnapshots count] > 0 && snapshotTimer == nil)
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
        if (fabs(newSize.width - oldSize.width) > 1.0 || fabs(newSize.height - oldSize.height) > 1.0) {
            NSUInteger idx = [[rightSideController.snapshotArrayController arrangedObjects] indexOfObject:controller];
            if (idx != NSNotFound)
                [rightSideController.snapshotTableView noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:idx]];
        }
    }
    if ([dirtySnapshots count] == 0) {
        [snapshotTimer invalidate];
        SKDESTROY(snapshotTimer);
    }
}

- (void)updateSnapshotFilterPredicate {
    NSString *searchString = [rightSideController.searchField stringValue];
    NSPredicate *filterPredicate = nil;
    if (mwcFlags.rightSidePaneState == SKSnapshotSidePaneState && [searchString length] > 0) {
        NSExpression *lhs = [NSExpression expressionForConstantValue:searchString];
        NSExpression *rhs = [NSExpression expressionForKeyPath:@"string"];
        NSUInteger options = NSDiacriticInsensitivePredicateOption;
        if (mwcFlags.caseInsensitiveNoteSearch)
            options |= NSCaseInsensitivePredicateOption;
        filterPredicate = [NSComparisonPredicate predicateWithLeftExpression:lhs rightExpression:rhs modifier:NSDirectPredicateModifier type:NSInPredicateOperatorType options:options];
    }
    [rightSideController.snapshotArrayController setFilterPredicate:filterPredicate];
}

#pragma mark Progress sheet

- (void)beginProgressSheetWithMessage:(NSString *)message maxValue:(NSUInteger)maxValue {
    if (progressController == nil)
        progressController = [[SKProgressController alloc] init];
    
    [progressController setMessage:message];
    if (maxValue > 0) {
        [progressController setIndeterminate:NO];
        [progressController setMaxValue:(double)maxValue];
    } else {
        [progressController setIndeterminate:YES];
    }
    [progressController beginSheetModalForWindow:[self window] completionHandler:NULL];
}

- (void)incrementProgressSheet {
    [progressController incrementBy:1.0];
}

- (void)dismissProgressSheet {
    [progressController dismissSheet:nil];
    SKDESTROY(progressController);
}

#pragma mark Remote Control

- (void)remoteButtonPressed:(NSEvent *)theEvent {
    HIDRemoteButtonCode remoteButton = (HIDRemoteButtonCode)[theEvent data1];
    BOOL remoteScrolling = (BOOL)[theEvent data2];
    
    switch (remoteButton) {
        case kHIDRemoteButtonCodeUp:
            if (remoteScrolling)
                [[[self pdfView] documentView] scrollLineUp];
            else if ([self interactionMode] == SKPresentationMode)
                [self doAutoScale:nil];
            else
                [self doZoomIn:nil];
            break;
        case kHIDRemoteButtonCodeDown:
            if (remoteScrolling)
                [[[self pdfView] documentView] scrollLineDown];
            else if ([self interactionMode] == SKPresentationMode)
                [self doZoomToActualSize:nil];
            else
                [self doZoomOut:nil];
            break;
        case kHIDRemoteButtonCodeRightHold:
        case kHIDRemoteButtonCodeRight:
            if (remoteScrolling)
                [[[self pdfView] documentView] scrollLineRight];
            else 
                [self doGoToNextPage:nil];
            break;
        case kHIDRemoteButtonCodeLeftHold:
        case kHIDRemoteButtonCodeLeft:
            if (remoteScrolling)
                [[[self pdfView] documentView] scrollLineLeft];
            else 
                [self doGoToPreviousPage:nil];
            break;
        case kHIDRemoteButtonCodeCenter:        
            [self togglePresentation:nil];
            break;
        default:
            break;
    }
}

@end
