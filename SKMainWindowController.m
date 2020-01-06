//
//  SKMainWindowController.m
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

#import "SKMainWindowController.h"
#import "SKMainToolbarController.h"
#import "SKMainWindowController_UI.h"
#import "SKMainWindowController_FullScreen.h"
#import "SKMainWindowController_Actions.h"
#import "SKLeftSideViewController.h"
#import "SKRightSideViewController.h"
#import <Quartz/Quartz.h>
#import "SKStringConstants.h"
#import "SKNoteWindowController.h"
#import "SKInfoWindowController.h"
#import "SKBookmarkController.h"
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
#import "NSBezierPath_SKExtensions.h"
#import "NSUserDefaultsController_SKExtensions.h"
#import "NSUserDefaults_SKExtensions.h"
#import "SKOutlineView.h"
#import "SKNoteOutlineView.h"
#import "SKTableView.h"
#import "SKNoteTypeSheetController.h"
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
#import "SKScroller.h"
#import "SKMainWindow.h"
#import "PDFOutline_SKExtensions.h"
#import "NSGraphics_SKExtensions.h"
#import "NSWindow_SKExtensions.h"
#import "SKMainTouchBarController.h"

#define MULTIPLICATION_SIGN_CHARACTER (unichar)0x00d7

#define TINY_SIZE  32.0
#define SMALL_SIZE 64.0
#define LARGE_SIZE 128.0
#define HUGE_SIZE  256.0
#define FUDGE_SIZE 0.1

#define MAX_PAGE_COLUMN_WIDTH 100.0

#define PAGELABELS_KEY              @"pageLabels"
#define SEARCHRESULTS_KEY           @"searchResults"
#define GROUPEDSEARCHRESULTS_KEY    @"groupedSearchResults"
#define NOTES_KEY                   @"notes"
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

#define MAINWINDOWFRAME_KEY         @"windowFrame"
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
#define SCROLLPOINT_KEY             @"scrollPoint"
#define LOCKED_KEY                  @"locked"

#define PAGETRANSITIONS_KEY @"pageTransitions"

#define WINDOW_KEY @"window"

#define CONTENTLAYOUTRECT_KEY @"contentLayoutRect"

#define SKMainWindowFrameAutosaveName @"SKMainWindow"

static char SKPDFAnnotationPropertiesObservationContext;

static char SKMainWindowDefaultsObservationContext;

static char SKMainWindowContentLayoutRectObservationContext;

#define SKLeftSidePaneWidthKey @"SKLeftSidePaneWidth"
#define SKRightSidePaneWidthKey @"SKRightSidePaneWidth"

#define SKUseSettingsFromPDFKey @"SKUseSettingsFromPDF"

@interface SKMainWindowController (SKPrivate)

- (void)cleanup;

- (void)applyLeftSideWidth:(CGFloat)leftSideWidth rightSideWidth:(CGFloat)rightSideWidth;

- (void)setupToolbar;

- (void)updateTableFont;

- (void)updatePageLabel;

- (SKProgressController *)progressController;

- (void)updateFindResultHighlightsForDirection:(NSSelectionDirection)direction;

- (void)registerForDocumentNotifications;
- (void)unregisterForDocumentNotifications;

- (void)registerAsObserver;
- (void)unregisterAsObserver;

- (void)startObservingNotes:(NSArray *)newNotes;
- (void)stopObservingNotes:(NSArray *)oldNotes;

- (void)observeUndoManagerCheckpoint:(NSNotification *)notification;

+ (void)defineFullScreenGlobalVariables;

- (BOOL)useNativeFullScreen;

@end


@implementation SKMainWindowController

@synthesize mainWindow, splitView, centerContentView, pdfSplitView, pdfContentView, statusBar, pdfView, secondaryPdfView, leftSideController, rightSideController, toolbarController, leftSideContentView, rightSideContentView, presentationNotesDocument, presentationNotesOffset, tags, rating, pageNumber, pageLabel, interactionMode, placeholderPdfDocument;
@dynamic pdfDocument, presentationOptions, selectedNotes, autoScales, leftSidePaneState, rightSidePaneState, findPaneState, leftSidePaneIsOpen, rightSidePaneIsOpen, recentInfoNeedsUpdate, searchString;

+ (void)initialize {
    SKINITIALIZE;
    
    [PDFPage setUsesSequentialPageNumbering:[[NSUserDefaults standardUserDefaults] boolForKey:SKSequentialPageNumberingKey]];
    
    [self defineFullScreenGlobalVariables];
}

+ (BOOL)automaticallyNotifiesObserversOfPageNumber { return NO; }

+ (BOOL)automaticallyNotifiesObserversOfPageLabel { return NO; }

- (id)init {
    self = [super initWithWindowNibName:@"MainWindow"];
    if (self) {
        interactionMode = SKNormalMode;
        searchResults = [[NSMutableArray alloc] init];
        searchResultIndex = 0;
        memset(&mwcFlags, 0, sizeof(mwcFlags));
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
        mwcFlags.leftSidePaneState = SKSidePaneStateThumbnail;
        mwcFlags.rightSidePaneState = SKSidePaneStateNote;
        mwcFlags.findPaneState = SKFindPaneStateSingular;
        pageLabel = nil;
        pageNumber = NSNotFound;
        markedPageIndex = NSNotFound;
        markedPagePoint = NSZeroPoint;
        beforeMarkedPageIndex = NSNotFound;
        beforeMarkedPagePoint = NSZeroPoint;
        activityAssertionID = kIOPMNullAssertionID;
        presentationNotesDocument = nil;
        presentationNotesOffset = 0;
    }
    return self;
}

- (void)dealloc {
    if ([self isWindowLoaded] && [[self window] delegate])
        SKENSURE_MAIN_THREAD( [self cleanup]; );
    SKDESTROY(placeholderPdfDocument);
    SKDESTROY(undoGroupOldPropertiesPerNote);
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
    SKDESTROY(secondaryPdfView);
    SKDESTROY(presentationPreview);
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
    SKDESTROY(presentationNotesDocument);
    [super dealloc];
}

// this is called from windowWillClose:
- (void)cleanup {
    if (RUNNING_AFTER(10_9))
        [mainWindow removeObserver:self forKeyPath:CONTENTLAYOUTRECT_KEY];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self stopObservingNotes:[self notes]];
    [self unregisterAsObserver];
    [[self window] setDelegate:nil];
    [splitView setDelegate:nil];
    [pdfSplitView setDelegate:nil];
    [leftSideController setMainController:nil];
    [rightSideController setMainController:nil];
    [toolbarController setMainController:nil];
    [touchBarController setMainController:nil];
    [findController setDelegate:nil]; // this breaks the retain loop from binding
    [pdfView setDelegate:nil]; // this cleans up the pdfview
    [[pdfView document] setDelegate:nil];
    [noteTypeSheetController setDelegate:nil];
    // Sierra seems to have a retain cycle when the document has an outlineRoot
    [[[pdfView document] outlineRoot] clearDocument];
    [[pdfView document] setContainingDocument:nil];
    // Yosemite and El Capitan have a retain cycle when we leave the PDFView with a document
    if (RUNNING_AFTER(10_9) && RUNNING_BEFORE(10_12)) {
        [pdfView setDocument:nil];
        [secondaryPdfView setDocument:nil];
    }
    // we may retain our own document here
    [self setPresentationNotesDocument:nil];
}

- (void)windowDidLoad{
    NSUserDefaults *sud = [NSUserDefaults standardUserDefaults];
    BOOL hasWindowSetup = [savedNormalSetup count] > 0;
    NSWindow *window = [self window];
    
    mwcFlags.settingUpWindow = 1;
    
    // Set up the panes and subviews, needs to be done before we resize them
    
    // This gets sometimes messed up in the nib, AppKit bug rdar://5346690
    [leftSideContentView setAutoresizesSubviews:YES];
    [rightSideContentView setAutoresizesSubviews:YES];
    [centerContentView setAutoresizesSubviews:YES];
    [pdfContentView setAutoresizesSubviews:YES];
    
    // make sure the first thing we call on the side view controllers is its view so their nib is loaded
    [leftSideController.view setFrame:SKShrinkRect(NSInsetRect([leftSideContentView bounds], -1.0, -1.0), 1.0, NSMaxYEdge)];
    [leftSideContentView addSubview:leftSideController.view];
    [rightSideController.view setFrame:SKShrinkRect(NSInsetRect([rightSideContentView bounds], -1.0, -1.0), 1.0, NSMaxYEdge)];
    [rightSideContentView addSubview:rightSideController.view];
    
    [self updateTableFont];
    
    [self displayThumbnailViewAnimating:NO];
    [self displayNoteViewAnimating:NO];
    
    // we need to create the PDFView before setting the toolbar
    pdfView = [[SKPDFView alloc] initWithFrame:[pdfContentView bounds]];
    [pdfView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    
    if ([pdfView maximumScaleFactor] < 20.0 && [pdfView respondsToSelector:NSSelectorFromString(@"setMaxScaleFactor:")])
        [pdfView setValue:[NSNumber numberWithDouble:20.0] forKey:@"maxScaleFactor"];
    
    // Set up the tool bar
    [toolbarController setupToolbar];
    
    // Set up the window
    if ([self useNativeFullScreen])
        [window setCollectionBehavior:[window collectionBehavior] | NSWindowCollectionBehaviorFullScreenPrimary];
    
    if (RUNNING_AFTER(10_9)) {
        [window setStyleMask:[window styleMask] | NSFullSizeContentViewWindowMask];
        [[splitView superview] setFrame:[window contentLayoutRect]];
        [window addObserver:self forKeyPath:CONTENTLAYOUTRECT_KEY options:0 context:&SKMainWindowContentLayoutRectObservationContext];
    }
    
    [self setWindowFrameAutosaveNameOrCascade:SKMainWindowFrameAutosaveName];
    
    [window setAutorecalculatesContentBorderThickness:NO forEdge:NSMinYEdge];
    
    [statusBar setRightAction:@selector(statusBarClicked:)];
    [statusBar setRightTarget:self];

    if ([sud boolForKey:SKShowStatusBarKey] == NO)
        [self toggleStatusBar:nil];
    else
        [window setContentBorderThickness:22.0 forEdge:NSMinYEdge];
    
    NSInteger windowSizeOption = [sud integerForKey:SKInitialWindowSizeOptionKey];
    if (hasWindowSetup) {
        NSString *rectString = [savedNormalSetup objectForKey:MAINWINDOWFRAME_KEY];
        if (rectString)
            [window setFrame:NSRectFromString(rectString) display:NO];
    } else if (windowSizeOption == SKWindowOptionMaximize) {
        [window setFrame:[[NSScreen mainScreen] visibleFrame] display:NO];
    }
    
    // Set up the PDF
    [pdfView setShouldAntiAlias:[sud boolForKey:SKShouldAntiAliasKey]];
    [pdfView setGreekingThreshold:[sud floatForKey:SKGreekingThresholdKey]];
    [pdfView setBackgroundColor:[PDFView defaultBackgroundColor]];
    [pdfView applyDefaultPageBackgroundColor];
    [pdfView applyDefaultInterpolationQuality];
    
    [self applyPDFSettings:hasWindowSetup ? savedNormalSetup : [sud dictionaryForKey:SKDefaultPDFDisplaySettingsKey] rewind:NO];
    
    [pdfView setDelegate:self];
    
    NSNumber *leftWidthNumber = [savedNormalSetup objectForKey:LEFTSIDEPANEWIDTH_KEY] ?: [sud objectForKey:SKLeftSidePaneWidthKey];
    NSNumber *rightWidthNumber = [savedNormalSetup objectForKey:RIGHTSIDEPANEWIDTH_KEY] ?: [sud objectForKey:SKRightSidePaneWidthKey];
    
    if (leftWidthNumber && rightWidthNumber)
        [self applyLeftSideWidth:[leftWidthNumber doubleValue] rightSideWidth:[rightWidthNumber doubleValue]];
    
    // this needs to be done before loading the PDFDocument
    [self resetThumbnailSizeIfNeeded];
    [self resetSnapshotSizeIfNeeded];
    
    
    // NB: the next line will load the PDF document and annotations, so necessary setup must be finished first!
    // windowControllerDidLoadNib: is not called automatically because the document overrides makeWindowControllers
    [[self document] windowControllerDidLoadNib:self];
    
    // Show/hide left side pane if necessary
    BOOL hasOutline = ([[pdfView document] outlineRoot] != nil);
    if ([sud boolForKey:SKOpenContentsPaneOnlyForTOCKey] && [self leftSidePaneIsOpen] != hasOutline)
        [self toggleLeftSidePane:nil];
    if (hasOutline)
        [self setLeftSidePaneState:SKSidePaneStateOutline];
    else
        [leftSideController.button setEnabled:NO forSegment:SKSidePaneStateOutline];
    
    // Due to a bug in Leopard we should only resize and swap in the PDFView after loading the PDFDocument
    [pdfView setFrame:[pdfContentView bounds]];
    if ([[pdfView document] isLocked]) {
        // PDFView has the annoying habit for the password view to force a full window display
        CGFloat leftWidth = [self leftSideWidth];
        CGFloat rightWidth = [self rightSideWidth];
        [pdfContentView addSubview:pdfView];
        [self applyLeftSideWidth:leftWidth rightSideWidth:rightWidth];
    } else {
        [pdfContentView addSubview:pdfView];
    }
    
    // get the initial display mode from the PDF if present and not overridden by an explicit setup
    if (hasWindowSetup == NO && [[NSUserDefaults standardUserDefaults] boolForKey:SKUseSettingsFromPDFKey]) {
        NSDictionary *initialSettings = [[self pdfDocument] initialSettings];
        if (initialSettings) {
            [self applyPDFSettings:initialSettings rewind:NO];
            if ([initialSettings objectForKey:@"fitWindow"])
                windowSizeOption = [[initialSettings objectForKey:@"fitWindow"] boolValue] ? SKWindowOptionFit : SKWindowOptionDefault;
        }
    }
    
    // Go to page?
    NSUInteger pageIndex = NSNotFound;
    NSString *pointString = nil;
    if (hasWindowSetup) {
        pageIndex = [[savedNormalSetup objectForKey:PAGEINDEX_KEY] unsignedIntegerValue];
        pointString = [savedNormalSetup objectForKey:SCROLLPOINT_KEY];
    } else if ([sud boolForKey:SKRememberLastPageViewedKey]) {
        pageIndex = [[SKBookmarkController sharedBookmarkController] pageIndexForRecentDocumentAtURL:[(NSDocument *)[self document] fileURL]];
    }
    if (pageIndex != NSNotFound && [[pdfView document] pageCount] > pageIndex) {
        if ([[pdfView document] isLocked]) {
            [savedNormalSetup setObject:[NSNumber numberWithUnsignedInteger:pageIndex] forKey:PAGEINDEX_KEY];
        } else if ([[pdfView currentPage] pageIndex] != pageIndex || pointString) {
            if (pointString)
                [pdfView goToPageAtIndex:pageIndex point:NSPointFromString(pointString)];
            else
                [pdfView goToPage:[[pdfView document] pageAtIndex:pageIndex]];
            [lastViewedPages setCount:0];
            [lastViewedPages addPointer:(void *)pageIndex];
            [pdfView resetHistory];
        }
    }
    
    // We can fit only after the PDF has been loaded
    if (windowSizeOption == SKWindowOptionFit && hasWindowSetup == NO)
        [self performFit:self];
    
    // Open snapshots?
    NSArray *snapshotSetups = nil;
    if (hasWindowSetup)
        snapshotSetups = [savedNormalSetup objectForKey:SNAPSHOTS_KEY];
    else if ([sud boolForKey:SKRememberSnapshotsKey])
        snapshotSetups = [[SKBookmarkController sharedBookmarkController] snapshotsForRecentDocumentAtURL:[(NSDocument *)[self document] fileURL]];
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
    
    [pdfView setTypeSelectHelper:[leftSideController.thumbnailTableView typeSelectHelper]];
    
    [window recalculateKeyViewLoop];
    [window makeFirstResponder:pdfView];
    
    // Update page states
    [self handlePageChangedNotification:nil];
    [toolbarController handlePageChangedNotification:nil];
    
    // Observe notifications and KVO
    [self registerForNotifications];
    [self registerAsObserver];
    
    if ([[pdfView document] isLocked]) {
        [window makeFirstResponder:[pdfView subviewOfClass:[NSSecureTextField class]]];
        [savedNormalSetup setObject:[NSNumber numberWithBool:YES] forKey:LOCKED_KEY];
    } else {
        [savedNormalSetup removeAllObjects];
    }
    
    [self setRecentInfoNeedsUpdate:YES];
    
    mwcFlags.settingUpWindow = 0;
}

- (void)synchronizeWindowTitleWithDocumentName {
    // as the fullscreen window has no title we have to do this manually
    if ([self interactionMode] == SKLegacyFullScreenMode)
        [NSApp changeWindowsItem:[self window] title:[self windowTitleForDocumentDisplayName:[[self document] displayName]] filename:NO];
    [super synchronizeWindowTitleWithDocumentName];
}

- (void)applyLeftSideWidth:(CGFloat)leftSideWidth rightSideWidth:(CGFloat)rightSideWidth {
    [splitView setPosition:leftSideWidth ofDividerAtIndex:0];
    [splitView setPosition:[splitView maxPossiblePositionOfDividerAtIndex:1] - [splitView dividerThickness] - rightSideWidth ofDividerAtIndex:1];
}

- (void)applySetup:(NSDictionary *)setup{
    if ([self isWindowLoaded] == NO) {
        [savedNormalSetup setDictionary:setup];
    } else {
        
        NSString *rectString = [setup objectForKey:MAINWINDOWFRAME_KEY];
        if (rectString)
            [mainWindow setFrame:NSRectFromString(rectString) display:[mainWindow isVisible]];
        
        NSNumber *leftWidth = [setup objectForKey:LEFTSIDEPANEWIDTH_KEY];
        NSNumber *rightWidth = [setup objectForKey:RIGHTSIDEPANEWIDTH_KEY];
        if (leftWidth && rightWidth)
            [self applyLeftSideWidth:[leftWidth doubleValue] rightSideWidth:[rightWidth doubleValue]];
        
        NSArray *snapshotSetups = [setup objectForKey:SNAPSHOTS_KEY];
        if ([snapshotSetups count])
            [self showSnapshotsWithSetups:snapshotSetups];
        
        if ([self interactionMode] == SKNormalMode)
            [self applyPDFSettings:setup rewind:NO];
        else
            [savedNormalSetup addEntriesFromDictionary:setup];
        
        NSNumber *pageIndexNumber = [setup objectForKey:PAGEINDEX_KEY];
        NSUInteger pageIndex = [pageIndexNumber unsignedIntegerValue];
        if (pageIndexNumber && pageIndex != NSNotFound && pageIndex != [[pdfView currentPage] pageIndex]) {
            NSString *pointString = [setup objectForKey:SCROLLPOINT_KEY];
            if (pointString)
                [pdfView goToPageAtIndex:pageIndex point:NSPointFromString(pointString)];
            else
                [pdfView goToPage:[[pdfView document] pageAtIndex:pageIndex]];
        }
    }
}

- (NSDictionary *)currentSetup {
    NSMutableDictionary *setup = [NSMutableDictionary dictionary];
    NSPoint point = NSZeroPoint;
    BOOL rotated = NO;
    NSUInteger pageIndex = [pdfView currentPageIndexAndPoint:&point rotated:&rotated];
    
    [setup setObject:NSStringFromRect([mainWindow frame]) forKey:MAINWINDOWFRAME_KEY];
    [setup setObject:[NSNumber numberWithDouble:[self leftSideWidth]] forKey:LEFTSIDEPANEWIDTH_KEY];
    [setup setObject:[NSNumber numberWithDouble:[self rightSideWidth]] forKey:RIGHTSIDEPANEWIDTH_KEY];
    [setup setObject:[NSNumber numberWithUnsignedInteger:pageIndex] forKey:PAGEINDEX_KEY];
    if (rotated == NO)
        [setup setObject:NSStringFromPoint(point) forKey:SCROLLPOINT_KEY];
    if ([snapshots count])
        [setup setObject:[snapshots valueForKey:SKSnapshotCurrentSetupKey] forKey:SNAPSHOTS_KEY];
    if ([self interactionMode] == SKNormalMode) {
        [setup addEntriesFromDictionary:[self currentPDFSettings]];
    } else {
        [setup addEntriesFromDictionary:savedNormalSetup];
        [setup removeObjectsForKeys:[NSArray arrayWithObjects:HASHORIZONTALSCROLLER_KEY, HASVERTICALSCROLLER_KEY, AUTOHIDESSCROLLERS_KEY, LOCKED_KEY, nil]];
    }
    
    return setup;
}

- (void)applyPDFSettings:(NSDictionary *)setup rewind:(BOOL)rewind {
    if ([setup count] && rewind)
        [pdfView setNeedsRewind:YES];
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
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKDisplayPageBoundsKey] && NSEqualRects(rect, NSZeroRect))
        rect = [[pdfView currentPage] boundsForBox:[pdfView displayBox]];

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
        labelWidth = fmax(labelWidth, [cell cellSize].width + 0.0);
    }
    
    labelWidth = fmin(ceil(labelWidth), MAX_PAGE_COLUMN_WIDTH);
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
    
    // these carry a label, moreover when this is called the thumbnails will also be invalid
    [self resetThumbnails];
    [self allSnapshotsNeedUpdate];
    [rightSideController.noteOutlineView reloadData];
    
    [self updatePageColumnWidthForTableView:leftSideController.thumbnailTableView];
    [self updatePageColumnWidthForTableView:rightSideController.snapshotTableView];
    [self updatePageColumnWidthForTableView:leftSideController.tocOutlineView];
    [self updatePageColumnWidthForTableView:rightSideController.noteOutlineView];
    [self updatePageColumnWidthForTableView:leftSideController.findTableView];
    [self updatePageColumnWidthForTableView:leftSideController.groupedFindTableView];
    
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
        [self setLeftSidePaneState:SKSidePaneStateThumbnail];

    [leftSideController.button setEnabled:outlineRoot != nil forSegment:SKSidePaneStateOutline];
}

#pragma mark Accessors

- (PDFDocument *)pdfDocument{
    return [pdfView document];
}

- (void)setPdfDocument:(PDFDocument *)document{

    if ([pdfView document] != document) {
        
        NSUInteger pageIndex = NSNotFound, secondaryPageIndex = NSNotFound;
        NSPoint point = NSZeroPoint, secondaryPoint = NSZeroPoint;
        BOOL rotated = NO, secondaryRotated = NO;
        NSArray *snapshotDicts = nil;
        NSDictionary *openState = nil;
        
        if ([pdfView document]) {
            pageIndex = [pdfView currentPageIndexAndPoint:&point rotated:&rotated];
            if (secondaryPdfView)
                secondaryPageIndex = [secondaryPdfView currentPageIndexAndPoint:&secondaryPoint rotated:&secondaryRotated];
            openState = [self expansionStateForOutline:[[pdfView document] outlineRoot]];
            
            [[pdfView document] cancelFindString];
            
            // make sure these will not be activated, or they can lead to a crash
            [pdfView removePDFToolTipRects];
            [pdfView setActiveAnnotation:nil];
            
            // these will be invalid. If needed, the document will restore them
            [self setSearchResults:nil];
            [self setGroupedSearchResults:nil];
            [self removeAllObjectsFromNotes];
            [self setThumbnails:nil];
            SKDESTROY(placeholderPdfDocument);
            
            // remmeber snapshots and close them, without animation
            snapshotDicts = [snapshots valueForKey:SKSnapshotCurrentSetupKey];
            [snapshots setValue:nil forKey:@"delegate"];
            [snapshots makeObjectsPerformSelector:@selector(close)];
            [self removeAllObjectsFromSnapshots];
            [rightSideController.snapshotTableView reloadData];
            
            [lastViewedPages setCount:0];
            
            [self unregisterForDocumentNotifications];
            
            [[pdfView document] setDelegate:nil];
            
            [[[pdfView document] outlineRoot] clearDocument];
            
            [[pdfView document] setContainingDocument:nil];
        }
        
        if ([document isLocked] && [pdfView window]) {
            // PDFView has the annoying habit for the password view to force a full window display
            CGFloat leftWidth = [self leftSideWidth];
            CGFloat rightWidth = [self rightSideWidth];
            [pdfView setDocument:document];
            [self applyLeftSideWidth:leftWidth rightSideWidth:rightWidth];
        } else {
            [pdfView setDocument:document];
        }
        [[pdfView document] setDelegate:self];
        
        [secondaryPdfView setDocument:document];
        
        [[pdfView document] setContainingDocument:[self document]];

        [self registerForDocumentNotifications];
        
        [self updatePageLabelsAndOutlineForExpansionState:openState];
        [self updateNoteSelection];
        
        if ([snapshotDicts count]) {
            if ([document isLocked] && ([self interactionMode] == SKNormalMode || [self interactionMode] == SKFullScreenMode))
                [savedNormalSetup setObject:snapshotDicts forKey:SNAPSHOTS_KEY];
            else
                [self showSnapshotsWithSetups:snapshotDicts];
        }
        
        if ([document pageCount] && (pageIndex != NSNotFound || secondaryPageIndex != NSNotFound)) {
            if (pageIndex != NSNotFound) {
                if (pageIndex >= [document pageCount])
                    pageIndex = [document pageCount] - 1;
                if ([document isLocked] && ([self interactionMode] == SKNormalMode || [self interactionMode] == SKFullScreenMode)) {
                    [savedNormalSetup setObject:[NSNumber numberWithUnsignedInteger:pageIndex] forKey:PAGEINDEX_KEY];
                } else {
                    if (rotated)
                        [pdfView goToPage:[document pageAtIndex:pageIndex]];
                    else
                        [pdfView goToPageAtIndex:pageIndex point:point];
                }
            }
            if (secondaryPageIndex != NSNotFound) {
                if (secondaryPageIndex >= [document pageCount])
                    secondaryPageIndex = [document pageCount] - 1;
                if (secondaryRotated)
                    [secondaryPdfView goToPage:[document pageAtIndex:secondaryPageIndex]];
                else
                    [secondaryPdfView goToPageAtIndex:secondaryPageIndex point:secondaryPoint];
            }
            [pdfView resetHistory];
        }
        
        // the number of pages may have changed
        [toolbarController handleChangedHistoryNotification:nil];
        [toolbarController handlePageChangedNotification:nil];
        [self handlePageChangedNotification:nil];
        [self updateLeftStatus];
        [self updateRightStatus];
    }
}

- (void)addAnnotationsFromDictionaries:(NSArray *)noteDicts removeAnnotations:(NSArray *)notesToRemove autoUpdate:(BOOL)autoUpdate {
    PDFAnnotation *annotation;
    PDFDocument *pdfDoc = [pdfView document];
    NSMutableArray *notesToAdd = [NSMutableArray array];
    NSMutableIndexSet *pageIndexes = [NSMutableIndexSet indexSet];
    
    if ([pdfDoc allowsNotes] == NO && [noteDicts count] > 0) {
        // there should not be any notesToRemove at this point
        if ([noteDicts count])
            tmpNoteProperties = [noteDicts retain];
        NSUInteger i, pageCount = MIN([pdfDoc pageCount], [[noteDicts valueForKeyPath:@"@max.pageIndex"] unsignedIntegerValue]);
        SKDESTROY(placeholderPdfDocument);
        pdfDoc = placeholderPdfDocument = [[SKPDFDocument alloc] init];
        [placeholderPdfDocument setContainingDocument:[self document]];
        for (i = 0; i < pageCount; i++) {
            PDFPage *page = [[SKPDFPage alloc] init];
            [placeholderPdfDocument insertPage:page atIndex:i];
            [page release];
        }
    }
    
    // disable automatic add/remove from the notification handlers
    // we want to do this in bulk as binding can be very slow and there are potentially many notes
    mwcFlags.addOrRemoveNotesInBulk = 1;
    
    if ([notesToRemove count]) {
        // notesToRemove is either all notes, no notes, or non Skim notes
        BOOL removeAllNotes = [[notesToRemove firstObject] isSkimNote];
        if (removeAllNotes) {
            [pdfView removePDFToolTipRects];
            // remove the current annotations
            [pdfView setActiveAnnotation:nil];
        }
        for (annotation in [[notesToRemove copy] autorelease]) {
            [pageIndexes addIndex:[annotation pageIndex]];
            PDFAnnotation *popup = [annotation popup];
            if (popup)
                [pdfView removeAnnotation:popup];
            [pdfView removeAnnotation:annotation];
        }
        if (removeAllNotes)
            [self removeAllObjectsFromNotes];
    }
    
    // create new annotations from the dictionary and add them to their page and to the document
    for (NSDictionary *dict in noteDicts) {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        NSUInteger pageIndex = [[dict objectForKey:SKNPDFAnnotationPageIndexKey] unsignedIntegerValue];
        if ((annotation = [[PDFAnnotation alloc] initSkimNoteWithProperties:dict])) {
            // this is only to make sure markup annotations generate the lineRects, for thread safety
            [annotation boundsOrder];
            if (pageIndex == NSNotFound)
                pageIndex = 0;
            else if (pageIndex >= [pdfDoc pageCount])
                pageIndex = [pdfDoc pageCount] - 1;
            [pageIndexes addIndex:pageIndex];
            PDFPage *page = [pdfDoc pageAtIndex:pageIndex];
            [pdfView addAnnotation:annotation toPage:page];
            if (autoUpdate && [[annotation contents] length] == 0)
                [annotation autoUpdateString];
            [notesToAdd addObject:annotation];
            [annotation release];
        }
        [pool release];
    }
    if ([notesToAdd count] > 0)
        [self insertNotes:notesToAdd atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange([notes count], [notesToAdd count])]];
    // make sure we clear the undo handling
    [self observeUndoManagerCheckpoint:nil];
    [rightSideController.noteOutlineView reloadData];
    [self updateThumbnailsAtPageIndexes:pageIndexes];
    [pdfView resetPDFToolTipRects];
    
    mwcFlags.addOrRemoveNotesInBulk = 0;
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
    if (pageNumber != number) {
        pageNumber = number;
    }
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
    if (label != pageLabel) {
        [pageLabel release];
        pageLabel = [label retain];
    }
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
        
        if (mwcFlags.leftSidePaneState == SKSidePaneStateThumbnail)
            [self displayThumbnailViewAnimating:NO];
        else if (mwcFlags.leftSidePaneState == SKSidePaneStateOutline)
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
        
        if (mwcFlags.rightSidePaneState == SKSidePaneStateNote)
            [self displayNoteViewAnimating:NO];
        else if (mwcFlags.rightSidePaneState == SKSidePaneStateSnapshot)
            [self displaySnapshotViewAnimating:NO];
    }
}

- (SKFindPaneState)findPaneState {
    return mwcFlags.findPaneState;
}

- (void)setFindPaneState:(SKFindPaneState)newFindPaneState {
    if (mwcFlags.findPaneState != newFindPaneState) {
        mwcFlags.findPaneState = newFindPaneState;
        
        if (mwcFlags.findPaneState == SKFindPaneStateSingular) {
            if ([leftSideController.groupedFindTableView window])
                [self displayFindViewAnimating:NO];
        } else if (mwcFlags.findPaneState == SKFindPaneStateGrouped) {
            if ([leftSideController.findTableView window])
                [self displayGroupedFindViewAnimating:NO];
        }
        [self updateFindResultHighlightsForDirection:NSDirectSelection];
    }
}

- (BOOL)leftSidePaneIsOpen {
    NSInteger state;
    if ([self interactionMode] == SKLegacyFullScreenMode)
        state = [leftSideWindow state];
    else if ([self interactionMode] == SKPresentationMode)
        state = [leftSideWindow isVisible] ? NSDrawerOpenState : NSDrawerClosedState;
    else
        state = [splitView isSubviewCollapsed:leftSideContentView] ? NSDrawerClosedState : NSDrawerOpenState;
    return state == NSDrawerOpenState || state == NSDrawerOpeningState;
}

- (BOOL)rightSidePaneIsOpen {
    NSInteger state;
    if ([self interactionMode] == SKLegacyFullScreenMode)
        state = [rightSideWindow state];
    else if ([self interactionMode] == SKPresentationMode)
        state = [rightSideWindow isVisible] ? NSDrawerOpenState : NSDrawerClosedState;
    else
        state = [splitView isSubviewCollapsed:rightSideContentView] ? NSDrawerClosedState : NSDrawerOpenState;;
    return state == NSDrawerOpenState || state == NSDrawerOpeningState;
}

- (CGFloat)leftSideWidth {
    return [self leftSidePaneIsOpen] ? NSWidth([leftSideContentView frame]) : 0.0;
}

- (CGFloat)rightSideWidth {
    return [self rightSidePaneIsOpen] ? NSWidth([rightSideContentView frame]) : 0.0;
}

- (NSArray *)notes {
    return notes;
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

- (void)insertNotes:(NSArray *)newNotes atIndexes:(NSIndexSet *)theIndexes {
    [notes insertObjects:newNotes atIndexes:theIndexes];

    // Start observing the just-inserted notes so that, when they're changed, we can record undo operations.
    [self startObservingNotes:newNotes];
}

- (void)removeObjectFromNotesAtIndex:(NSUInteger)theIndex {
    PDFAnnotation *note = [notes objectAtIndex:theIndex];
    
    [[self windowControllerForNote:note] close];
    
    if ([note hasNoteText])
        [rowHeights removeFloatForKey:[note noteText]];
    [rowHeights removeFloatForKey:note];
    
    // Stop observing the removed notes
    [self stopObservingNotes:[NSArray arrayWithObject:note]];
    
    [notes removeObjectAtIndex:theIndex];
}

- (void)removeAllObjectsFromNotes {
    if ([notes count]) {
        NSArray *wcs = [[[self document] windowControllers] copy];
        for (NSWindowController *wc in wcs) {
            if ([wc isNoteWindowController])
                [wc close];
        }
        [wcs release];
        
        [rowHeights removeAllFloats];
        
        [self stopObservingNotes:notes];

        NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [notes count])];
        [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:NOTES_KEY];
        [notes removeAllObjects];
        [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:NOTES_KEY];
        
        [rightSideController.noteOutlineView reloadData];
    }
}

- (NSArray *)thumbnails {
    return thumbnails;
}

- (void)setThumbnails:(NSArray *)newThumbnails {
    [thumbnails setArray:newThumbnails];
}

- (NSArray *)snapshots {
    return snapshots;
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

- (void)setSelectedNotes:(NSArray *)newSelectedNotes {
    NSMutableIndexSet *rowIndexes = [NSMutableIndexSet indexSet];
    for (PDFAnnotation *note in newSelectedNotes) {
        NSInteger row = [rightSideController.noteOutlineView rowForItem:note];
        if (row != -1)
            [rowIndexes addIndex:row];
    }
    [rightSideController.noteOutlineView selectRowIndexes:rowIndexes byExtendingSelection:NO];
}

- (NSArray *)searchResults {
    return searchResults;
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
    return groupedSearchResults;
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

- (void)setPresentationNotesDocument:(NSDocument *)newDocument {
    [self removePresentationNotesNavigation];
    if (presentationNotesDocument != newDocument) {
        [presentationNotesDocument release];
        presentationNotesDocument = [newDocument retain];
    }
}

- (BOOL)recentInfoNeedsUpdate {
    return mwcFlags.recentInfoNeedsUpdate && [self isWindowLoaded] && [[self window] delegate];
}

- (void)setRecentInfoNeedsUpdate:(BOOL)flag {
    mwcFlags.recentInfoNeedsUpdate = flag;
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

- (NSString *)searchString {
    return [leftSideController.searchField stringValue];
}

- (BOOL)findString:(NSString *)string forward:(BOOL)forward {
    PDFDocument *pdfDoc = [pdfView document];
    if ([pdfDoc isFinding]) {
        NSBeep();
        return NO;
    }
    PDFSelection *sel = [pdfView currentSelection];
    NSUInteger pageIndex = [[pdfView currentPage] pageIndex];
    NSInteger options = 0;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKCaseInsensitiveFindKey])
        options |= NSCaseInsensitiveSearch;
    if (forward == NO)
        options |= NSBackwardsSearch;
    while ([sel hasCharacters] == NO && (forward ? pageIndex-- > 0 : ++pageIndex < [pdfDoc pageCount])) {
        PDFPage *page = [pdfDoc pageAtIndex:pageIndex];
        NSUInteger length = [[page string] length];
        if (length > 0)
            sel = [page selectionForRange:NSMakeRange(0, length)];
    }
    PDFSelection *selection = [pdfDoc findString:string fromSelection:sel withOptions:options];
    if ([selection hasCharacters] == NO && [sel hasCharacters])
        selection = [pdfDoc findString:string fromSelection:nil withOptions:options];
    if (selection) {
        PDFPage *page = [selection safeFirstPage];
        [pdfView goToRect:[selection boundsForPage:page] onPage:page];
        [leftSideController.findTableView deselectAll:self];
        [leftSideController.groupedFindTableView deselectAll:self];
        [pdfView setCurrentSelection:selection animate:YES];
        return YES;
	} else {
		NSBeep();
        return NO;
	}
}

- (void)findControllerWillBeRemoved:(SKFindController *)aFindController {
    if ([[[self window] firstResponder] isDescendantOf:[aFindController view]])
        [[self window] makeFirstResponder:[self pdfView]];
}

- (void)showFindBar {
    if (findController == nil) {
        findController = [[SKFindController alloc] init];
        [findController setDelegate:self];
    }
    if ([[findController view] window] == nil)
        [findController toggleAboveView:([self interactionMode] == SKLegacyFullScreenMode ? pdfSplitView : splitView) animate:YES];
    [[findController findField] selectText:nil];
}

#define FIND_RESULT_MARGIN 50.0

- (void)selectFindResultHighlight:(NSSelectionDirection)direction {
    [self updateFindResultHighlightsForDirection:direction];
    if (direction == NSDirectSelection && [self interactionMode] == SKPresentationMode && [[NSUserDefaults standardUserDefaults] boolForKey:SKAutoHidePresentationContentsKey])
        [self hideLeftSideWindow];
}

- (void)updateFindResultHighlightsForDirection:(NSSelectionDirection)direction {
    NSArray *findResults = nil;
    
    if (mwcFlags.findPaneState == SKFindPaneStateSingular && [leftSideController.findTableView window])
        findResults = [leftSideController.findArrayController selectedObjects];
    else if (mwcFlags.findPaneState == SKFindPaneStateGrouped && [leftSideController.groupedFindTableView window])
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
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"
        [highlights setValue:[NSColor respondsToSelector:@selector(findHighlightColor)] ? [NSColor findHighlightColor] : [NSColor yellowColor] forKey:@"color"];
#pragma clang diagnostic pop
        [pdfView setHighlightedSelections:highlights];
        [highlights release];
        
        if ([currentSel hasCharacters])
            [pdfView setCurrentSelection:currentSel animate:YES];
        if ([pdfView toolMode] == SKMoveToolMode || [pdfView toolMode] == SKMagnifyToolMode || [pdfView toolMode] == SKSelectToolMode)
            [pdfView setCurrentSelection:nil];
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
    // this should never happen, but apparently PDFKit sometimes does return empty matches
    if (page == nil)
        return;
    
    NSUInteger pageIndex = [page pageIndex];
    CGFloat order = [instance boundsOrderForPage:page];
    NSInteger i = [searchResults count];
    while (i-- > 0) {
        PDFSelection *prevResult = [searchResults objectAtIndex:i];
        PDFPage *prevPage = [prevResult safeFirstPage];
        NSUInteger prevIndex = [prevPage pageIndex];
        if (pageIndex > prevIndex || (pageIndex == prevIndex && order >= [prevResult boundsOrderForPage:prevPage]))
            break;
    }
    [searchResults insertObject:instance atIndex:i + 1];
    
    SKGroupedSearchResult *result = nil;
    NSUInteger maxCount = [[groupedSearchResults lastObject] maxCount];
    i = [groupedSearchResults count];
    while (i-- > 0) {
        SKGroupedSearchResult *prevResult = [groupedSearchResults objectAtIndex:i];
        NSUInteger prevIndex = [prevResult pageIndex];
        if (pageIndex >= prevIndex) {
            if (pageIndex == prevIndex)
                result = prevResult;
            break;
        }
    }
    if (result == nil) {
        result = [SKGroupedSearchResult groupedSearchResultWithPage:page maxCount:maxCount];
        [groupedSearchResults insertObject:result atIndex:i + 1];
    }
    [result addMatch:instance];
    
    if ([result count] > maxCount) {
        maxCount = [result count];
        for (result in groupedSearchResults)
            [result setMaxCount:maxCount];
    }
}

- (void)documentDidBeginDocumentFind:(NSNotification *)note {
    [leftSideController applySearchTableHeader:[NSLocalizedString(@"Searching", @"Message in search table header") stringByAppendingEllipsis]];
    [self setSearchResults:nil];
    [self setGroupedSearchResults:nil];
    [statusBar setProgressIndicatorStyle:SKProgressIndicatorStyleDeterminate];
    [statusBar setProgressIndicatorMaxValue:[[note object] pageCount]];
    [statusBar setProgressIndicatorValue:0.0];
    [statusBar startAnimation:self];
    [self willChangeValueForKey:SEARCHRESULTS_KEY];
    [self willChangeValueForKey:GROUPEDSEARCHRESULTS_KEY];
}

- (void)documentDidEndDocumentFind:(NSNotification *)note {
    [leftSideController applySearchTableHeader:[NSString stringWithFormat:NSLocalizedString(@"%ld Results", @"Message in search table header"), (long)[searchResults count]]];
    [self didChangeValueForKey:GROUPEDSEARCHRESULTS_KEY];
    [self didChangeValueForKey:SEARCHRESULTS_KEY];
    [statusBar stopAnimation:self];
    [statusBar setProgressIndicatorStyle:SKProgressIndicatorStyleNone];
}

- (void)documentDidEndPageFind:(NSNotification *)note {
    NSNumber *pageIndex = [[note userInfo] objectForKey:@"PDFDocumentPageIndex"];
    [statusBar setProgressIndicatorValue:[pageIndex doubleValue] + 1.0];
    if ([pageIndex unsignedIntegerValue] % 50 == 0) {
        [self didChangeValueForKey:GROUPEDSEARCHRESULTS_KEY];
        [self didChangeValueForKey:SEARCHRESULTS_KEY];
        [self willChangeValueForKey:SEARCHRESULTS_KEY];
        [self willChangeValueForKey:GROUPEDSEARCHRESULTS_KEY];
    }
}

- (void)documentDidUnlockDelayed {
    NSDictionary *settings = [self interactionMode] == SKFullScreenMode ? [[NSUserDefaults standardUserDefaults] dictionaryForKey:SKDefaultFullScreenPDFDisplaySettingsKey] : nil;
    if ([settings count] == 0)
        settings = [savedNormalSetup objectForKey:AUTOSCALES_KEY] ? savedNormalSetup : [[NSUserDefaults standardUserDefaults] dictionaryForKey:SKDefaultPDFDisplaySettingsKey];
    [self applyPDFSettings:settings rewind:NO];
    
    NSNumber *pageIndexNumber = [savedNormalSetup objectForKey:PAGEINDEX_KEY];
    NSUInteger pageIndex = pageIndexNumber ? [pageIndexNumber unsignedIntegerValue] : NSNotFound;
    if (pageIndex != NSNotFound) {
        NSString *pointString = [savedNormalSetup objectForKey:SCROLLPOINT_KEY];
        if (pointString)
            [pdfView goToPageAtIndex:pageIndex point:NSPointFromString(pointString)];
        else
            [pdfView goToPage:[[pdfView document] pageAtIndex:pageIndex]];
        [lastViewedPages setCount:0];
        [lastViewedPages addPointer:(void *)pageIndex];
        [pdfView resetHistory];
    }
    
    NSArray *snapshotSetups = [savedNormalSetup objectForKey:SNAPSHOTS_KEY];
    if ([snapshotSetups count])
        [self showSnapshotsWithSetups:snapshotSetups];
    
    if ([self interactionMode] == SKNormalMode)
        [savedNormalSetup removeAllObjects];
}

- (void)documentDidUnlock:(NSNotification *)notification {
    if (placeholderPdfDocument && [[self pdfDocument] allowsNotes]) {
        PDFDocument *pdfDoc = [self pdfDocument];
        NSMutableIndexSet *pageIndexes = [NSMutableIndexSet indexSet];
        for (PDFAnnotation *note in [self notes]) {
            PDFPage *page = [note page];
            NSUInteger pageIndex = [page pageIndex];
            if ([page document] != pdfDoc) {
                [page removeAnnotation:note];
                [[pdfDoc pageAtIndex:[page pageIndex]] addAnnotation:note];
                [pageIndexes addIndex:pageIndex];
            }
        }
        SKDESTROY(placeholderPdfDocument);
        [pdfView requiresDisplay];
        [rightSideController.noteArrayController rearrangeObjects];
        if ([[savedNormalSetup objectForKey:LOCKED_KEY] boolValue] == NO) {
            [rightSideController.noteOutlineView reloadData];
            [self updateThumbnailsAtPageIndexes:pageIndexes];
        }
    }
    
    if ([[savedNormalSetup objectForKey:LOCKED_KEY] boolValue]) {
        [self updatePageLabelsAndOutlineForExpansionState:nil];
        
        // when the PDF was locked, PDFView resets the display settings, so we need to reapply them, however if we don't delay it's reset again immediately
        if ([self interactionMode] == SKNormalMode || [self interactionMode] == SKFullScreenMode)
            [self performSelector:@selector(documentDidUnlockDelayed) withObject:nil afterDelay:0.0];
    }
}

enum { SKOptionAsk = -1, SKOptionNever = 0, SKOptionAlways = 1 };

- (void)document:(PDFDocument *)aDocument didUnlockWithPassword:(NSString *)password {
    if ([aDocument isLocked])
        return;
    
    NSInteger saveOption = [[NSUserDefaults standardUserDefaults] integerForKey:SKSavePasswordOptionKey];
    if (saveOption == SKOptionAlways) {
        [[self document] savePasswordInKeychain:password];
    } else if (saveOption == SKOptionAsk) {
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert setMessageText:[NSString stringWithFormat:NSLocalizedString(@"Remember Password?", @"Message in alert dialog"), nil]];
        [alert setInformativeText:NSLocalizedString(@"Do you want to save this password in your Keychain?", @"Informative text in alert dialog")];
        [alert addButtonWithTitle:NSLocalizedString(@"Yes", @"Button title")];
        [alert addButtonWithTitle:NSLocalizedString(@"No", @"Button title")];
        NSWindow *window = [self window];
        if ([window attachedSheet] == nil)
            [alert beginSheetModalForWindow:window completionHandler:^(NSInteger returnCode){
                if (returnCode == NSAlertFirstButtonReturn)
                    [[self document] savePasswordInKeychain:password];
            }];
        else if (NSAlertFirstButtonReturn == [alert runModal])
            [[self document] savePasswordInKeychain:password];
    }
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
    
    [secondaryPdfView requiresDisplay];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKDisplayPageBoundsKey])
        [self updateRightStatus];
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
    NSUInteger i, iMax = [setups count];
    
    for (i = 0; i < iMax; i++) {
        NSDictionary *setup  = [setups objectAtIndex:i];
        
        SKSnapshotWindowController *swc = [[SKSnapshotWindowController alloc] init];
        
        [swc setDelegate:self];
        
        [swc setPdfDocument:[pdfView document] setup:setup];
        
        [swc setForceOnTop:[self interactionMode] != SKNormalMode];
        
        [[self document] addWindowController:swc];
        
        [swc release];
    }
}

- (void)snapshotController:(SKSnapshotWindowController *)controller didFinishSetup:(SKSnapshotOpenType)openType {
    NSImage *image = [controller thumbnailWithSize:snapshotCacheSize];
    [controller setThumbnail:image];
    
    if (openType == SKSnapshotOpenFromSetup) {
        [[self mutableArrayValueForKey:SNAPSHOTS_KEY] addObject:controller];
        [rightSideController.snapshotTableView reloadData];
    } else {
        if (openType == SKSnapshotOpenNormal) {
            [rightSideController.snapshotTableView beginUpdates];
            [[self mutableArrayValueForKey:SNAPSHOTS_KEY] addObject:controller];
            NSUInteger row = [[rightSideController.snapshotArrayController arrangedObjects] indexOfObject:controller];
            if (row != NSNotFound) {
                NSTableViewAnimationOptions options = NSTableViewAnimationEffectGap | NSTableViewAnimationSlideDown;
                if ([self rightSidePaneIsOpen] == NO || [self rightSidePaneState] != SKSidePaneStateSnapshot || [[NSUserDefaults standardUserDefaults] boolForKey:SKDisableAnimationsKey])
                    options = NSTableViewAnimationEffectNone;
                [rightSideController.snapshotTableView insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:row] withAnimation:options];
            }
            [rightSideController.snapshotTableView endUpdates];
        }
        [self setRecentInfoNeedsUpdate:YES];
    }
}

- (void)snapshotControllerWillClose:(SKSnapshotWindowController *)controller {
    if (controller == presentationPreview) {
        [presentationPreview autorelease];
        presentationPreview = nil;
    } else {
        [rightSideController.snapshotTableView beginUpdates];
        NSUInteger row = [[rightSideController.snapshotArrayController arrangedObjects] indexOfObject:controller];
        if (row != NSNotFound) {
            NSTableViewAnimationOptions options = NSTableViewAnimationEffectGap | NSTableViewAnimationSlideUp;
            if ([self rightSidePaneIsOpen] == NO || [self rightSidePaneState] != SKSidePaneStateSnapshot || [[NSUserDefaults standardUserDefaults] boolForKey:SKDisableAnimationsKey])
                options = NSTableViewAnimationEffectNone;
            [rightSideController.snapshotTableView removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:row] withAnimation:options];
        }
        [[self mutableArrayValueForKey:SNAPSHOTS_KEY] removeObject:controller];
        [rightSideController.snapshotTableView endUpdates];
        [self setRecentInfoNeedsUpdate:YES];
    }
}

- (void)snapshotControllerDidChange:(SKSnapshotWindowController *)controller {
    if (controller != presentationPreview) {
        [self snapshotNeedsUpdate:controller];
        [rightSideController.snapshotArrayController rearrangeObjects];
        [rightSideController.snapshotTableView reloadData];
        [self setRecentInfoNeedsUpdate:YES];
    }
}

- (void)snapshotControllerDidMove:(SKSnapshotWindowController *)controller {
    if (controller != presentationPreview) {
        [self setRecentInfoNeedsUpdate:YES];
    }
}

- (NSRect)snapshotController:(SKSnapshotWindowController *)controller miniaturizedRect:(BOOL)isMiniaturize {
    if (controller == presentationPreview)
        return NSZeroRect;
    NSUInteger row = [[rightSideController.snapshotArrayController arrangedObjects] indexOfObject:controller];
    BOOL shouldReopenRightSidePane = NO;
    if (isMiniaturize && [self interactionMode] != SKPresentationMode) {
        if ([self interactionMode] != SKLegacyFullScreenMode && [self rightSidePaneIsOpen] == NO) {
            [[self window] disableFlushWindow];
            [self toggleRightSidePane:nil];
            shouldReopenRightSidePane = YES;
        } else if ([self interactionMode] == SKLegacyFullScreenMode && ([rightSideWindow state] == NSDrawerClosedState || [rightSideWindow state] == NSDrawerClosingState)) {
            [rightSideWindow expand];
            [rightSideWindow performSelector:@selector(collapse) withObject:nil afterDelay:1.0];
        }
        [self setRightSidePaneState:SKSidePaneStateSnapshot];
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
    rect = [rightSideController.snapshotTableView convertRectToScreen:rect];
    if (shouldReopenRightSidePane) {
        [self toggleRightSidePane:nil];
        [[self window] enableFlushWindow];
        [self toggleRightSidePane:self];
    }
    [self setRecentInfoNeedsUpdate:YES];
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
        [NSArray arrayWithObjects:SKBackgroundColorKey, SKFullScreenBackgroundColorKey,
                                  SKDarkBackgroundColorKey, SKDarkFullScreenBackgroundColorKey,
                                  SKPageBackgroundColorKey, 
                                  SKThumbnailSizeKey, SKSnapshotThumbnailSizeKey, 
                                  SKShouldAntiAliasKey, SKGreekingThresholdKey, 
                                  SKTableFontSizeKey, nil]
        context:&SKMainWindowDefaultsObservationContext];
}

- (void)unregisterAsObserver {
    @try {
        [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeys:
         [NSArray arrayWithObjects:SKBackgroundColorKey, SKFullScreenBackgroundColorKey,
                                   SKDarkBackgroundColorKey, SKDarkFullScreenBackgroundColorKey,
                                   SKPageBackgroundColorKey,
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

- (BOOL)notesNeedReloadForKey:(NSString *)key {
    if ([key isEqualToString:SKNPDFAnnotationBoundsKey] ||
        [key isEqualToString:[[[rightSideController.noteArrayController sortDescriptors] firstObject] key]])
        return YES;
    if ([[rightSideController.searchField stringValue] length])
        return [key isEqualToString:SKNPDFAnnotationStringKey] || [key isEqualToString:SKNPDFAnnotationTextKey];
    return NO;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == &SKMainWindowDefaultsObservationContext) {
        
        // A default value that we are observing has changed
        NSString *key = [keyPath substringFromIndex:7];
        if ([key isEqualToString:SKBackgroundColorKey] || [key isEqualToString:SKDarkBackgroundColorKey]) {
            if ([self interactionMode] == SKNormalMode) {
                [pdfView setBackgroundColor:[PDFView defaultBackgroundColor]];
                [secondaryPdfView setBackgroundColor:[PDFView defaultBackgroundColor]];
            }
        } else if ([key isEqualToString:SKFullScreenBackgroundColorKey] || [key isEqualToString:SKDarkFullScreenBackgroundColorKey]) {
            if ([self interactionMode] == SKFullScreenMode || [self interactionMode] == SKLegacyFullScreenMode) {
                NSColor *color = [PDFView defaultFullScreenBackgroundColor];
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
            [pdfView applyDefaultPageBackgroundColor];
            [secondaryPdfView applyDefaultPageBackgroundColor];
            [self allThumbnailsNeedUpdate];
            [self allSnapshotsNeedUpdate];
        } else if ([key isEqualToString:SKThumbnailSizeKey]) {
            [self resetThumbnailSizeIfNeeded];
            [leftSideController.thumbnailTableView noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [[self thumbnails] count])]];
        } else if ([key isEqualToString:SKSnapshotThumbnailSizeKey]) {
            [self resetSnapshotSizeIfNeeded];
            [rightSideController.snapshotTableView noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self countOfSnapshots])]];
        } else if ([key isEqualToString:SKShouldAntiAliasKey]) {
            [pdfView setShouldAntiAlias:[[NSUserDefaults standardUserDefaults] boolForKey:SKShouldAntiAliasKey]];
            [pdfView applyDefaultInterpolationQuality];
            [secondaryPdfView setShouldAntiAlias:[[NSUserDefaults standardUserDefaults] boolForKey:SKShouldAntiAliasKey]];
            [secondaryPdfView applyDefaultInterpolationQuality];
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
        
    } else if (context == &SKMainWindowContentLayoutRectObservationContext) {
        
        if ([[splitView window] isEqual:mainWindow] && [mainWindow respondsToSelector:@selector(contentLayoutRect)])
            [[splitView superview] setFrame:[mainWindow contentLayoutRect]];
        
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
                    if ([note isNote]) {
                        [pdfView annotationsChangedOnPage:[note page]];
                        [pdfView resetPDFToolTipRects];
                    }
                    
                    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKDisplayNoteBoundsKey]) {
                        [self updateRightStatus];
                    }
                }
            }
            
            if (mwcFlags.autoResizeNoteRows) {
                if ([keyPath isEqualToString:SKNPDFAnnotationStringKey])
                    [rowHeights removeFloatForKey:note];
                if ([keyPath isEqualToString:SKNPDFAnnotationTextKey])
                    [rowHeights removeFloatForKey:[note noteText]];
            }
            if ([self notesNeedReloadForKey:keyPath]) {
                [rightSideController.noteArrayController rearrangeObjects];
                [rightSideController.noteOutlineView reloadData];
            } else if ([keyPath isEqualToString:SKNPDFAnnotationStringKey] ||
                       [keyPath isEqualToString:SKNPDFAnnotationTextKey]) {
                [rightSideController.noteOutlineView reloadTypeSelectStrings];
                if (mwcFlags.autoResizeNoteRows) {
                    NSInteger row = [rightSideController.noteOutlineView rowForItem:[keyPath isEqualToString:SKNPDFAnnotationStringKey] ? note : [note noteText]];
                    if (row != -1)
                        [rightSideController.noteOutlineView noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:row]];
                }
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

- (void)updateOutlineSelection{

	// Skip out if this PDF has no outline.
	if ([[pdfView document] outlineRoot] == nil || mwcFlags.updatingOutlineSelection)
		return;
	
	// Get index of current page.
	NSUInteger pageIndex = [[pdfView currentPage] pageIndex];
    
	// Test that the current selection is still valid.
	NSInteger row = [leftSideController.tocOutlineView selectedRow];
    if (row == -1 || [[[leftSideController.tocOutlineView itemAtRow:row] page] pageIndex] != pageIndex) {
        // Get the outline row that contains the current page
        NSInteger numRows = [leftSideController.tocOutlineView numberOfRows];
        for (row = 0; row < numRows; row++) {
            // Get the page for the given row....
            PDFPage *page = [[leftSideController.tocOutlineView itemAtRow:row] page];
            if (page == nil) {
                continue;
            } else if ([page pageIndex] == pageIndex) {
                break;
            } else if ([page pageIndex] > pageIndex) {
                if (row > 0) --row;
                break;	
            }
        }
        if (row == numRows)
            row--;
        if (row != -1) {
            mwcFlags.updatingOutlineSelection = 1;
            [leftSideController.tocOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
            mwcFlags.updatingOutlineSelection = 0;
        }
    }
}

#pragma mark Thumbnails

- (BOOL)generateImageForThumbnail:(SKThumbnail *)thumbnail {
    if ([(SKScroller *)[leftSideController.thumbnailTableView.enclosingScrollView verticalScroller] isScrolling] || [[pdfView document] isLocked] || [[presentationSheetController verticalScroller] isScrolling])
        return NO;
    
    PDFPage *page = [[pdfView document] pageAtIndex:[thumbnail pageIndex]];
    SKReadingBar *readingBar = [[[pdfView readingBar] page] isEqual:page] ? [pdfView readingBar] : nil;
    PDFDisplayBox box = [pdfView displayBox];
    dispatch_queue_t queue = RUNNING_AFTER(10_11) ? dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) : dispatch_get_main_queue();
    
    dispatch_async(queue, ^{
        NSImage *image = [page thumbnailWithSize:thumbnailCacheSize forBox:box readingBar:readingBar];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSUInteger pageIndex = [thumbnail pageIndex];
            BOOL sameSize = NSEqualSizes([image size], [thumbnail size]);
            
            [thumbnail setImage:image];
            
            if (sameSize == NO)
                [leftSideController.thumbnailTableView noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:pageIndex]];
        });
    });
    
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
    NSMutableArray *newThumbnails = [NSMutableArray array];
    if ([pageLabels count] > 0) {
        BOOL isLocked = [[pdfView document] isLocked];
        PDFPage *firstPage = [[pdfView document] pageAtIndex:0];
        PDFPage *emptyPage = [[[SKPDFPage alloc] init] autorelease];
        [emptyPage setBounds:[firstPage boundsForBox:kPDFDisplayBoxCropBox] forBox:kPDFDisplayBoxCropBox];
        [emptyPage setBounds:[firstPage boundsForBox:kPDFDisplayBoxMediaBox] forBox:kPDFDisplayBoxMediaBox];
        [emptyPage setRotation:[firstPage rotation]];
        NSImage *pageImage = [emptyPage thumbnailWithSize:thumbnailCacheSize forBox:[pdfView displayBox]];
        NSRect rect = NSZeroRect;
        rect.size = [pageImage size];
        CGFloat width = 0.8 * fmin(NSWidth(rect), NSHeight(rect));
        rect = NSInsetRect(rect, 0.5 * (NSWidth(rect) - width), 0.5 * (NSHeight(rect) - width));
        
        [pageImage lockFocus];
        [[NSImage imageNamed:NSImageNameApplicationIcon] drawInRect:rect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:0.5];
        if (isLocked)
            [[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kLockedBadgeIcon)] drawInRect:rect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:0.5];
        [pageImage unlockFocus];
        
        [pageLabels enumerateObjectsUsingBlock:^(id label, NSUInteger i, BOOL *stop) {
            SKThumbnail *thumbnail = [[SKThumbnail alloc] initWithImage:pageImage label:label pageIndex:i];
            [thumbnail setDelegate:self];
            [thumbnail setDirty:YES];
            [newThumbnails addObject:thumbnail];
            [thumbnail release];
        }];
    }
    // reloadData resets the selection, so we have to ignore its notification and reset it
    mwcFlags.updatingThumbnailSelection = 1;
    [self setThumbnails:newThumbnails];
    [self updateThumbnailSelection];
    mwcFlags.updatingThumbnailSelection = 0;
}

- (void)resetThumbnailSizeIfNeeded {
    roundedThumbnailSize = round([[NSUserDefaults standardUserDefaults] floatForKey:SKThumbnailSizeKey]);

    CGFloat defaultSize = roundedThumbnailSize;
    CGFloat thumbnailSize = (defaultSize < TINY_SIZE + FUDGE_SIZE) ? TINY_SIZE : (defaultSize < SMALL_SIZE + FUDGE_SIZE) ? SMALL_SIZE : (defaultSize < LARGE_SIZE + FUDGE_SIZE) ? LARGE_SIZE : HUGE_SIZE;
    
    if (fabs(thumbnailSize - thumbnailCacheSize) > FUDGE_SIZE) {
        thumbnailCacheSize = thumbnailSize;
        
        if ([[self thumbnails] count])
            [self allThumbnailsNeedUpdate];
    }
}

- (void)updateThumbnailAtPageIndex:(NSUInteger)anIndex {
    [[thumbnails objectAtIndex:anIndex] setDirty:YES];
}

- (void)updateThumbnailsAtPageIndexes:(NSIndexSet *)indexSet {
    [[thumbnails objectsAtIndexes:indexSet] setValue:[NSNumber numberWithBool:YES] forKey:@"dirty"];
}

- (void)allThumbnailsNeedUpdate {
    [self updateThumbnailsAtPageIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [[self thumbnails] count])]];
}

#pragma mark Notes

- (void)updateNoteSelection {
    NSSortDescriptor *sortDesc = [[rightSideController.noteArrayController sortDescriptors] firstObject];
    
    if ([[sortDesc key] isEqualToString:SKNPDFAnnotationPageIndexKey] == NO)
        return;
    
    NSArray *orderedNotes = [rightSideController.noteArrayController arrangedObjects];
    __block PDFAnnotation *selAnnotation = nil;
    NSUInteger pageIndex = [[pdfView currentPage] pageIndex];
    NSMutableIndexSet *selPageIndexes = [NSMutableIndexSet indexSet];
    NSEnumerationOptions options = [sortDesc ascending] ? 0 : NSEnumerationReverse;
    
    for (selAnnotation in [self selectedNotes]) {
        if ([selAnnotation pageIndex] != NSNotFound)
            [selPageIndexes addIndex:[selAnnotation pageIndex]];
    }
    
    if ([orderedNotes count] == 0 || [selPageIndexes containsIndex:pageIndex])
		return;
	
	// Walk outline view looking for best firstpage number match.
    [orderedNotes enumerateObjectsWithOptions:options usingBlock:^(id annotation, NSUInteger i, BOOL *stop) {
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
        NSInteger row = [rightSideController.noteOutlineView rowForItem:selAnnotation];
        [rightSideController.noteOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
        [rightSideController.noteOutlineView scrollRowToVisible:row];
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
    if (mwcFlags.rightSidePaneState == SKSidePaneStateSnapshot && [searchString length] > 0) {
        NSExpression *lhs = [NSExpression expressionForConstantValue:searchString];
        NSExpression *rhs = [NSExpression expressionForKeyPath:@"string"];
        NSUInteger options = NSDiacriticInsensitivePredicateOption;
        if (mwcFlags.caseInsensitiveNoteSearch)
            options |= NSCaseInsensitivePredicateOption;
        filterPredicate = [NSComparisonPredicate predicateWithLeftExpression:lhs rightExpression:rhs modifier:NSDirectPredicateModifier type:NSInPredicateOperatorType options:options];
    }
    [rightSideController.snapshotArrayController setFilterPredicate:filterPredicate];
    [rightSideController.snapshotArrayController rearrangeObjects];
    [rightSideController.snapshotTableView reloadData];
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
            if ([self interactionMode] == SKPresentationMode)
                [self doAutoScale:nil];
            else if (remoteScrolling)
                [self scrollUp:nil];
            else
                [self doZoomIn:nil];
            break;
        case kHIDRemoteButtonCodeDown:
            if ([self interactionMode] == SKPresentationMode)
                [self doZoomToActualSize:nil];
            else if (remoteScrolling)
                [self scrollDown:nil];
            else
                [self doZoomOut:nil];
            break;
        case kHIDRemoteButtonCodeRightHold:
        case kHIDRemoteButtonCodeRight:
            if (remoteScrolling && [self interactionMode] != SKPresentationMode)
                [self scrollRight:nil];
            else 
                [self doGoToNextPage:nil];
            break;
        case kHIDRemoteButtonCodeLeftHold:
        case kHIDRemoteButtonCodeLeft:
            if (remoteScrolling && [self interactionMode] != SKPresentationMode)
                [self scrollLeft:nil];
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

#pragma mark Touch bar

- (NSTouchBar *)makeTouchBar {
    if (touchBarController == nil) {
        touchBarController = [[SKMainTouchBarController alloc] init];
        [touchBarController setMainController:self];
    }
    return [touchBarController makeTouchBar];
}

@end
