//
//  SKMainWindowController.m


//  This code is licensed under a BSD license. Please see the file LICENSE for details.
//
//  Created by Michael McCracken on 12/6/06.
//  Copyright 2006 Michael O. McCracken. All rights reserved.
//

#import "SKMainWindowController.h"
#import "SKStringConstants.h"
#import "SKSubWindowController.h"
#import "SKNoteWindowController.h"
#import "SKInfoWindowController.h"
#import "SKNavigationWindow.h"
#import "SKSideWindow.h"
#import <Quartz/Quartz.h>
#import "SKDocument.h"
#import "SKNote.h"
#import "SKPDFView.h"
#import "SKCollapsibleView.h"
#import "SKPDFAnnotationNote.h"
#import "SKSplitView.h"
#import <Carbon/Carbon.h>

#define SEGMENTED_CONTROL_HEIGHT    25.0
#define WINDOW_X_DELTA              0.0
#define WINDOW_Y_DELTA              70.0

static NSString *SKDocumentToolbarIdentifier = @"SKDocumentToolbarIdentifier";

static NSString *SKDocumentToolbarPreviousItemIdentifier = @"SKDocumentPreviousToolbarItemIdentifier";
static NSString *SKDocumentToolbarNextItemIdentifier = @"SKDocumentNextToolbarItemIdentifier";
static NSString *SKDocumentToolbarBackForwardItemIdentifier = @"SKDocumentToolbarBackForwardItemIdentifier";
static NSString *SKDocumentToolbarPageNumberItemIdentifier = @"SKDocumentToolbarPageNumberItemIdentifier";
static NSString *SKDocumentToolbarScaleItemIdentifier = @"SKDocumentToolbarScaleItemIdentifier";
static NSString *SKDocumentToolbarZoomInItemIdentifier = @"SKDocumentZoomInToolbarItemIdentifier";
static NSString *SKDocumentToolbarZoomOutItemIdentifier = @"SKDocumentZoomOutToolbarItemIdentifier";
static NSString *SKDocumentToolbarZoomActualItemIdentifier = @"SKDocumentZoomActualToolbarItemIdentifier";
static NSString *SKDocumentToolbarZoomAutoItemIdentifier = @"SKDocumentZoomAutoToolbarItemIdentifier";
static NSString *SKDocumentToolbarRotateRightItemIdentifier = @"SKDocumentRotateRightToolbarItemIdentifier";
static NSString *SKDocumentToolbarRotateLeftItemIdentifier = @"SKDocumentRotateLeftToolbarItemIdentifier";
static NSString *SKDocumentToolbarFullScreenItemIdentifier = @"SKDocumentFullScreenToolbarItemIdentifier";
static NSString *SKDocumentToolbarPresentationItemIdentifier = @"SKDocumentToolbarPresentationItemIdentifier";
static NSString *SKDocumentToolbarNewNoteItemIdentifier = @"SKDocumentToolbarNewNoteItemIdentifier";
static NSString *SKDocumentToolbarToggleDrawerItemIdentifier = @"SKDocumentToolbarToggleDrawerItemIdentifier";
static NSString *SKDocumentToolbarInfoItemIdentifier = @"SKDocumentToolbarInfoItemIdentifier";
static NSString *SKDocumentToolbarToolModeItemIdentifier = @"SKDocumentToolbarToolModeItemIdentifier";
static NSString *SKDocumentToolbarAnnotationModeItemIdentifier = @"SKDocumentToolbarAnnotationModeItemIdentifier";
static NSString *SKDocumentToolbarDisplayBoxItemIdentifier = @"SKDocumentToolbarDisplayBoxItemIdentifier";
static NSString *SKDocumentToolbarSearchItemIdentifier = @"SKDocumentToolbarSearchItemIdentifier";

#define TOOLBAR_SEARCHFIELD_MIN_SIZE NSMakeSize(110.0, 22.0)
#define TOOLBAR_SEARCHFIELD_MAX_SIZE NSMakeSize(1000.0, 22.0)


@interface SKFullScreenWindow : NSWindow
- (id)initWithScreen:(NSScreen *)screen;
@end

@interface SKMiniaturizeWindow : NSWindow
- (id)initWithContentRect:(NSRect)contentRect image:(NSImage *)image;
@end

@implementation SKMainWindowController

+ (void)initialize {
    [NSValueTransformer setValueTransformer:[[[SKAnnotationTypeIconTransformer alloc] init] autorelease] forName:@"SKAnnotationTypeIconTransformer"];
}

- (id)initWithWindowNibName:(NSString *)windowNibName owner:(id)owner{
    self = [super initWithWindowNibName:windowNibName owner:owner];
    
    if(self){
        [self setShouldCloseDocument:YES];
        isPresentation = NO;
        searchResults = [[NSMutableArray alloc] init];
        thumbnails = [[NSMutableArray alloc] init];
        dirtyThumbnailIndexes = [[NSMutableIndexSet alloc] init];
        subwindows = [[NSMutableArray alloc] init];
        sidePaneState = SKOutlineSidePaneState;
    }
    
    return self;
}

- (void)dealloc {

	[[NSNotificationCenter defaultCenter] removeObserver: self];
	
    if (thumbnailTimer) {
        [thumbnailTimer invalidate];
        [thumbnailTimer release];
        thumbnailTimer = nil;
    }
    [dirtyThumbnailIndexes release];
	[searchResults release];
    [pdfOutline release];
	[thumbnails release];
	[subwindows release];
    [[outlineView enclosingScrollView] release];
    [[findTableView enclosingScrollView] release];
    [[thumbnailTableView enclosingScrollView] release];
    [[notesTableView enclosingScrollView] release];
    [[subwindowsTableView enclosingScrollView] release];
	[leftSideWindow release];
	[rightSideWindow release];
	[fullScreenWindow release];
    [mainWindow release];
    
    [super dealloc];
}

- (void)windowDidLoad{
    // this is not called automatically, because the document overrides makeWindowControllers
    [[self document] windowControllerDidLoadNib:self];
    
    // we retain as we might replace it with the full screen window
    mainWindow = [[self window] retain];
    [mainWindow setFrameAutosaveName:SKMainWindowFrameAutosaveName];
    
    [[self window] setBackgroundColor:[NSColor colorWithDeviceWhite:0.9 alpha:1.0]];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKOpenFilesMaximizedKey])
        [[self window] setFrame:[[NSScreen mainScreen] visibleFrame] display:NO];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKDefaultDocumentAutoScaleKey])
        [pdfView setAutoScales:YES];
    else
        [pdfView setScaleFactor:0.01 * [[NSUserDefaults standardUserDefaults] floatForKey:SKDefaultDocumentScaleKey]];
    
    [[self window] makeFirstResponder:[pdfView documentView]];
    [[pdfView documentView] setNextKeyView:sidePaneViewButton];
    
    [[outlineView enclosingScrollView] retain];
    [[findTableView enclosingScrollView] retain];
    [[thumbnailTableView enclosingScrollView] retain];
    [[notesTableView enclosingScrollView] retain];
    [[subwindowsTableView enclosingScrollView] retain];
    
    NSRect frame = [sidePaneViewButton frame];
    frame.size.height = SEGMENTED_CONTROL_HEIGHT;
    [sidePaneViewButton setFrame:frame];
    [[sidePaneViewButton cell] setToolTip:NSLocalizedString(@"View Thumbnails", @"Tool tip message") forSegment:SKThumbnailSidePaneState];
    [[sidePaneViewButton cell] setToolTip:NSLocalizedString(@"View Table of Contents", @"Tool tip message") forSegment:SKOutlineSidePaneState];
    
    frame = [drawerViewButton frame];
    frame.size.height = SEGMENTED_CONTROL_HEIGHT;
    [drawerViewButton setFrame:frame];
    [[drawerViewButton cell] setToolTip:NSLocalizedString(@"View Notes", @"Tool tip message") forSegment:0];
    [[drawerViewButton cell] setToolTip:NSLocalizedString(@"View Detail Windows", @"Tool tip message") forSegment:1];
    
    [searchBox setCollapseEdges:SKMaxXEdgeMask | SKMinYEdgeMask];
    [searchBox setMinSize:NSMakeSize(150.0, 42.0)];
    
    [thumbnailTableView setRowHeight:[[NSUserDefaults standardUserDefaults] floatForKey:SKThumbnailSizeKey]];
    
    NSSortDescriptor *indexSortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"pageIndex" ascending:YES] autorelease];
    NSSortDescriptor *contentsSortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"contents" ascending:YES] autorelease];
    [notesArrayController setSortDescriptors:[NSArray arrayWithObjects:indexSortDescriptor, contentsSortDescriptor, nil]];
    [subwindowsArrayController setSortDescriptors:[NSArray arrayWithObjects:indexSortDescriptor, nil]];
    
    [self setupToolbar];
    
    [self handleChangedHistoryNotification:nil];
    [self handleToolModeChangedNotification:nil];
    [self handleAnnotationModeChangedNotification:nil];
    [self handlePageChangedNotification:nil];
    [self handleScaleChangedNotification:nil];
    [pageNumberStepper setMaxValue:[[pdfView document] pageCount]];
    [sidePaneViewButton setSelectedSegment:sidePaneState];
    [drawerViewButton setSelectedSegment:0];
    
    [self registerForNotifications];
}

- (void)registerForNotifications {
    // Application
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAppWillTerminateNotification:) 
                                                 name:NSApplicationWillTerminateNotification object:NSApp];
	// PDFView
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePageChangedNotification:) 
                                                 name:PDFViewPageChangedNotification object:pdfView];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleScaleChangedNotification:) 
                                                 name:PDFViewScaleChangedNotification object:pdfView];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleChangedHistoryNotification:) 
                                                 name:PDFViewChangedHistoryNotification object:pdfView];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleToolModeChangedNotification:) 
                                                 name:SKPDFViewAnnotationModeChangedNotification object:pdfView];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAnnotationModeChangedNotification:) 
                                                 name:SKPDFViewToolModeChangedNotification object:pdfView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDidChangeActiveAnnotationNotification:) 
                                                 name:SKPDFViewActiveAnnotationDidChangeNotification object:pdfView];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDidAddAnnotationNotification:) 
                                                 name:SKPDFViewDidAddAnnotationNotification object:pdfView];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDidRemoveAnnotationNotification:) 
                                                 name:SKPDFViewDidRemoveAnnotationNotification object:pdfView];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDidChangeAnnotationNotification:) 
                                                 name:SKPDFViewDidChangeAnnotationNotification object:pdfView];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDoubleClickedAnnotationNotification:) 
                                                 name:SKPDFViewAnnotationDoubleClickedNotification object:pdfView];
}

#pragma mark Accessors

- (PDFDocument *)pdfDocument{
    return [pdfView document];
}

- (void)setPdfDocument:(PDFDocument *)document{
    if ([pdfView document] != document) {
    
        [[pdfView document] setDelegate:nil];
        [pdfView setDocument:document];
        [[pdfView document] setDelegate:self];
        
        [pdfOutline release];
        pdfOutline = [[[pdfView document] outlineRoot] retain];
        if (outline && [[pdfView document] isLocked] == NO) {
            [outlineView reloadData];
            [outlineView setAutoresizesOutlineColumn: NO];
            
            if ([outlineView numberOfRows] == 1)
                [outlineView expandItem: [outlineView itemAtRow: 0] expandChildren: NO];
            [self updateOutlineSelection];
        }
        
        [self updateNoteSelection];
        
        [self resetThumbnails];
        [self updateThumbnailSelection];
    }
}

- (void)setAnnotationsFromDictionaries:(NSArray *)noteDicts{
    NSMutableArray *notes = [[self document] mutableArrayValueForKey:@"notes"];
    NSEnumerator *e = [notes objectEnumerator];
    PDFAnnotation *annotation;
    NSDictionary *dict;
    PDFDocument *pdfDoc = [pdfView document];
    
    // remove the current anotations
    [pdfView endAnnotationEdit];
    while (annotation = [e nextObject]) {
        [pdfView setNeedsDisplayForAnnotation:annotation];
        [[annotation page] removeAnnotation:annotation];
    }
    [notes removeAllObjects];
    
    // create new annotations from the dictionary and add them to their page and to the document
    e = [noteDicts objectEnumerator];
    while (dict = [e nextObject]) {
        unsigned pageIndex = [[dict objectForKey:@"pageIndex"] unsignedIntValue];
        if (annotation = [[PDFAnnotation alloc] initWithDictionary:dict]) {
            if (pageIndex == NSNotFound)
                pageIndex = 0;
            else if ([pdfDoc pageCount] > pageIndex)
                pageIndex = [pdfDoc pageCount] - 1;
            PDFPage *page = [pdfDoc pageAtIndex:pageIndex];
            [page addAnnotation:annotation];
            [notes addObject:annotation];
            [annotation release];
        }
    }
    [self thumbnailsAtIndexesNeedUpdate:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [pdfDoc pageCount])]];
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

- (NSArray *)thumbnails {
    return thumbnails;
}

- (void)setThumbnails:(NSArray *)newThumbnails {
    [thumbnails setArray:thumbnails];
}

- (unsigned)countOfThumbnails {
    return [thumbnails count];
}

- (id)objectInThumbnailsAtIndex:(unsigned)theIndex {
    return [thumbnails objectAtIndex:theIndex];
}

- (void)insertObject:(id)obj inThumbnailsAtIndex:(unsigned)theIndex {
    [thumbnails insertObject:obj atIndex:theIndex];
}

- (void)removeObjectFromThumbnailsAtIndex:(unsigned)theIndex {
    [thumbnails removeObjectAtIndex:theIndex];
}

- (NSArray *)subwindows {
    return subwindows;
}

- (void)setSubwindows:(NSArray *)newSubwindows {
    [subwindows setArray:subwindows];
}

- (unsigned)countOfSubwindows {
    return [subwindows count];
}

- (id)objectInSubwindowsAtIndex:(unsigned)theIndex {
    return [subwindows objectAtIndex:theIndex];
}

- (void)insertObject:(id)obj inSubwindowsAtIndex:(unsigned)theIndex {
    [subwindows insertObject:obj atIndex:theIndex];
}

- (void)removeObjectFromSubwindowsAtIndex:(unsigned)theIndex {
    [subwindows removeObjectAtIndex:theIndex];
}

#pragma mark Actions

- (IBAction)pickColor:(id)sender{
    PDFAnnotation *annotation = [pdfView activeAnnotation];
    if (annotation)
        [[NSColorPanel sharedColorPanel] setColor:[annotation color]];
    [[NSColorPanel sharedColorPanel] makeKeyAndOrderFront:self];
}

- (IBAction)changeColor:(id)sender{
    PDFAnnotation *annotation = [pdfView activeAnnotation];
    if (annotation) {
        [annotation setColor:[sender color]];
        [pdfView setNeedsDisplayForAnnotation:annotation];
    }
}

- (IBAction)createNewNote:(id)sender{
    [pdfView addAnnotationFromSelection:[pdfView currentSelection]];
}

- (void)selectNotes:(NSArray *)notesToShow{
    // there should only be a single note
	[pdfView setActiveAnnotation:[notesToShow lastObject]];
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

- (IBAction)displayMediaBox:(id)sender {
    if ([pdfView displayBox] == kPDFDisplayBoxCropBox)
        [pdfView setDisplayBox:kPDFDisplayBoxMediaBox];
}

- (IBAction)displayCropBox:(id)sender {
    if ([pdfView displayBox] == kPDFDisplayBoxMediaBox)
        [pdfView setDisplayBox:kPDFDisplayBoxCropBox];
}

- (IBAction)changeDisplayBox:(id)sender {
    PDFDisplayBox displayBox = [sender indexOfSelectedItem] == 0 ? kPDFDisplayBoxMediaBox : kPDFDisplayBoxCropBox;
    [pdfView setDisplayBox:displayBox];
}

- (IBAction)doGoToNextPage:(id)sender {
    [pdfView goToNextPage:sender];
}

- (IBAction)doGoToPreviousPage:(id)sender {
    [pdfView goToPreviousPage:sender];
}

- (void)choosePageSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSOKButton) {
        int page = [choosePageField intValue];

        // Check that the page number exists
        int pageCount = [[pdfView document] pageCount];
        if (page > pageCount) {
            [pdfView goToPage:[[pdfView document] pageAtIndex:pageCount - 1]];
        } else if (page > 0) {
            [pdfView goToPage:[[pdfView document] pageAtIndex:page - 1]];
        }
    }
}

- (IBAction)doGoToPage:(id)sender {
    [choosePageField setStringValue:@""];
    
    [NSApp beginSheet: choosePageSheet
       modalForWindow: [self window]
        modalDelegate: self
       didEndSelector: @selector(choosePageSheetDidEnd:returnCode:contextInfo:)
          contextInfo: nil];
}

- (IBAction)dismissChoosePageSheet:(id)sender {
    [NSApp endSheet:choosePageSheet returnCode:[sender tag]];
    [choosePageSheet orderOut:self];
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

- (IBAction)doZoomToActualSize:(id)sender {
    [pdfView setScaleFactor:1.0];
}

- (IBAction)doZoomToFit:(id)sender {
    [pdfView setAutoScales:YES];
}

- (IBAction)toggleZoomToFit:(id)sender {
    if ([pdfView autoScales])
        [self doZoomToActualSize:sender];
    else
        [self doZoomToFit:sender];
}

- (IBAction)rotateRight:(id)sender {
    [[pdfView currentPage] setRotation:[[pdfView currentPage] rotation] + 90];
    [pdfView layoutDocumentView];
}

- (IBAction)rotateLeft:(id)sender {
    [[pdfView currentPage] setRotation:[[pdfView currentPage] rotation] - 90];
    [pdfView layoutDocumentView];
}

- (IBAction)rotateAllRight:(id)sender {
    int i, count = [[pdfView document] pageCount];
    for (i = 0 ; i < count; ++ i ) {
        [[[pdfView document] pageAtIndex:i] setRotation:[[[pdfView document] pageAtIndex:i] rotation] + 90];
    }
    [pdfView layoutDocumentView];
}

- (IBAction)rotateAllLeft:(id)sender {
    int i, count = [[pdfView document] pageCount];
    for (i = 0 ; i < count; ++ i ) {
        [[[pdfView document] pageAtIndex:i] setRotation:[[[pdfView document] pageAtIndex:i] rotation] - 90];
    }
    [pdfView layoutDocumentView];
}

- (IBAction)toggleNotesDrawer:(id)sender {
    [notesDrawer toggle:sender];
}

- (IBAction)getInfo:(id)sender {
    SKInfoWindowController *infoController = [SKInfoWindowController sharedInstance];
    [infoController fillInfoForDocument:[self document]];
    [infoController showWindow:self];
}

- (IBAction)changePageNumber:(id)sender {
    int page = [sender intValue];

    // Check that the page number exists
    int pageCount = [[pdfView document] pageCount];
    if (page > pageCount) {
        [pdfView goToPage:[[pdfView document] pageAtIndex:pageCount - 1]];
        [pageNumberField setIntValue: page];
    } else if (page > 0) {
        [pdfView goToPage:[[pdfView document] pageAtIndex:page - 1]];
    }
}

- (IBAction)changeScaleFactor:(id)sender {
    int scale = [sender intValue];

	if (scale >= 10.0 && scale <= 500.0 ) {
		[pdfView setScaleFactor:scale / 100.0f];
		[pdfView setAutoScales:NO];
	}
}

- (IBAction)changeToolMode:(id)sender {
    SKToolMode toolMode = [sender isKindOfClass:[NSSegmentedControl class]] ? [sender selectedSegment] : [sender tag];
    [pdfView setToolMode:toolMode];
}

- (IBAction)changeAnnotationMode:(id)sender {
    SKAnnotationMode newAnnotationMode = [sender isKindOfClass:[NSSegmentedControl class]] ? [sender selectedSegment] : [sender tag];
    [pdfView setAnnotationMode:newAnnotationMode];
}

- (IBAction)changeSidePaneView:(id)sender {
    sidePaneState = [sender selectedSegment];
    
    if ([findField stringValue] && [[findField stringValue] isEqualToString:@""] == NO) {
        [findField setStringValue:@""];
        [self removeTemporaryAnnotations];
    }
    
    if (sidePaneState == SKThumbnailSidePaneState)
        [self displayThumbnailView];
    else if (sidePaneState == SKOutlineSidePaneState)
        [self displayOutlineView];
}

- (IBAction)changeDrawerView:(id)sender {
    int drawerState = [sender selectedSegment];
    
    if (drawerState == 0)
        [self displayNotesView];
    else if (drawerState == 1)
        [self displaySubwindowsView];
}

- (void)goFullScreen {
    NSScreen *screen = [NSScreen mainScreen]; // @@ or should we use the window's screen?

    // Create the full-screen window if it does not already  exist.
    if (fullScreenWindow == nil) {
        fullScreenWindow = [[SKFullScreenWindow alloc] initWithScreen:screen];
        [fullScreenWindow setDelegate:self];
    } else if (screen != [fullScreenWindow screen]) {
        [fullScreenWindow setFrame:[screen frame] display:NO];
    }
    
    [fullScreenWindow setContentView:pdfView];
    [pdfView setBackgroundColor:[NSColor blackColor]];
    [pdfView layoutDocumentView];
    [pdfView setNeedsDisplay:YES];
    
    [self setWindow:fullScreenWindow];
    [fullScreenWindow makeKeyAndOrderFront:self];
}

- (void)removeFullScreen {
    [pdfView setBackgroundColor:[NSColor colorWithCalibratedWhite:0.5 alpha:1.0]];
    [pdfView layoutDocumentView];
    
    [self setWindow:mainWindow];
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
}

- (void)showSideWindow {
    if (leftSideWindow == nil) {
        leftSideWindow = [[SKSideWindow alloc] initWithMainController:self edge:NSMinXEdge];
    } else if ([[self window] screen] != [leftSideWindow screen]) {
        [leftSideWindow moveToScreen:[[self window] screen]];
    }
    if (rightSideWindow == nil) {
        rightSideWindow = [[SKSideWindow alloc] initWithMainController:self edge:NSMaxXEdge];
    } else if ([[self window] screen] != [rightSideWindow screen]) {
        [rightSideWindow moveToScreen:[[self window] screen]];
    }
    
    [sideBox retain]; // sideBox is removed from its old superview in the process
    [leftSideWindow setMainView:sideBox];
    [sideBox release];
    [leftSideWindow setLevel:[[self window] level]];
    [[self window] addChildWindow:leftSideWindow ordered:NSWindowAbove];
    
    NSView *rightView = [notesDrawer contentView];
    [rightView retain];
    [rightSideWindow setMainView:rightView];
    [rightView release];
    [rightSideWindow setLevel:[[self window] level]];
    [[self window] addChildWindow:rightSideWindow ordered:NSWindowAbove];
    
    [leftSideWindow orderFront:self];
    [rightSideWindow orderFront:self];
}

- (void)hideSideWindow {
    [leftSideWindow orderOut:self];
    [rightSideWindow orderOut:self];
    
    [sideBox retain]; // sideBox is removed from its old superview in the process
    [sideBox setFrame:[sideContentBox bounds]];
    [sideContentBox addSubview:sideBox];
    [sideBox release];
    
    NSView *rightView = [rightSideWindow mainView];
    [rightView retain];
    [notesDrawer setContentView:rightView];
    [rightView release];
}

- (void)enterPresentationMode {
    NSScrollView *scrollView = [[pdfView documentView] enclosingScrollView];
	// Set up presentation mode
	savedState.displayMode = [pdfView displayMode];
	[pdfView setDisplayMode:kPDFDisplaySinglePage];
	savedState.autoScales = [pdfView autoScales];
	savedState.scaleFactor = [pdfView scaleFactor];
	[pdfView setAutoScales:YES];
	savedState.hasHorizontalScroller = [scrollView hasHorizontalScroller];
	[scrollView setHasHorizontalScroller:NO];
	savedState.hasVerticalScroller = [scrollView hasVerticalScroller];
	[scrollView setHasVerticalScroller:NO];
	savedState.autoHidesScrollers = [scrollView autohidesScrollers];
	[scrollView setAutohidesScrollers:YES];
    
    // Get the screen information.
    NSScreen *screen = [NSScreen mainScreen]; // @@ or should we use the window's screen?
    NSNumber *screenID = [[screen deviceDescription] objectForKey:@"NSScreenNumber"];
    
    // Capture the screen.
    CGDisplayCapture((CGDirectDisplayID)[screenID longValue]);
    
    isPresentation = YES;
}

- (void)exitPresentationMode {
    NSScrollView *scrollView = [[pdfView documentView] enclosingScrollView];
    [pdfView setDisplayMode:savedState.displayMode];
    if (savedState.autoScales) {
        [pdfView setAutoScales:YES];
    } else {
        [pdfView setAutoScales:NO];
        [pdfView setScaleFactor:savedState.scaleFactor];
    }		
    [scrollView setHasHorizontalScroller:savedState.hasHorizontalScroller];		
    [scrollView setHasVerticalScroller:savedState.hasVerticalScroller];
    [scrollView setAutohidesScrollers:savedState.autoHidesScrollers];		
    
    // Get the screen information.
    NSScreen *screen = [fullScreenWindow screen];
    NSNumber *screenID = [[screen deviceDescription] objectForKey:@"NSScreenNumber"];
    CGDisplayRelease((CGDirectDisplayID)[screenID longValue]);
    
    isPresentation = NO;
}

- (IBAction)enterFullScreen:(id)sender {
    if ([self isFullScreen])
        return;
    
    SetSystemUIMode(kUIModeAllHidden, kUIOptionAutoShowMenuBar);
    
    if ([self isPresentation])
        [self exitPresentationMode];
    else
        [self goFullScreen];
    
    [fullScreenWindow setLevel:NSNormalWindowLevel];
    [pdfView setHasNavigation:YES autohidesCursor:NO];
    [self showSideWindow];
}

- (IBAction)enterPresentation:(id)sender {
    if ([self isPresentation])
        return;
    
    BOOL isFullScreen = [self isFullScreen];
    
    [self enterPresentationMode];
    
    if (isFullScreen) {
        [self hideSideWindow];
        SetSystemUIMode(kUIModeNormal, 0);
    } else
        [self goFullScreen];
    
    [fullScreenWindow setLevel:CGShieldingWindowLevel()];
    [pdfView setHasNavigation:YES autohidesCursor:YES];
}

- (IBAction)exitFullScreen:(id)sender {
    if ([self isFullScreen] == NO && [self isPresentation] == NO)
        return;

    [self hideSideWindow];
    
    [pdfView setHasNavigation:NO autohidesCursor:NO];
    [pdfContentBox setContentView:pdfView]; // this should be done before exitPresentationMode to get a smooth transition
    
    if ([self isPresentation])
        [self exitPresentationMode];
    else
        SetSystemUIMode(kUIModeNormal, 0);
    
    [self removeFullScreen];
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

- (IBAction)printDocument:(id)sender{
    [pdfView printWithInfo:[[self document] printInfo] autoRotate:NO];
}

#pragma mark Searching

- (void)documentDidBeginDocumentFind:(NSNotification *)note {
    [findArrayController removeObjects:searchResults];
    [spinner startAnimation:nil];
}

- (void)documentDidEndDocumentFind:(NSNotification *)note {
    [spinner stopAnimation:nil];
}

- (void)documentDidEndPageFind:(NSNotification *)note {
	double pageIndex = [[[note userInfo] objectForKey:@"PDFDocumentPageIndex"] doubleValue];
	[spinner setDoubleValue: pageIndex / [[pdfView document] pageCount]];
}

- (void)didMatchString:(PDFSelection *)instance {
    [findArrayController addObject:instance];
}

- (void)replaceTable:(NSTableView *)oldTableView withTable:(NSTableView *)newTableView animate:(BOOL)animate {
    if ([newTableView window] == nil) {
        NSView *newTable = [newTableView enclosingScrollView];
        NSView *oldTable = [oldTableView enclosingScrollView];
        NSRect frame = [oldTable frame];
        
        [newTable setFrame:frame];
        [newTable setHidden:animate];
        [[oldTable superview] addSubview:newTable];
        
        if (animate) {
            NSViewAnimation *animation;
            NSDictionary *fadeOutDict = [[NSDictionary alloc] initWithObjectsAndKeys:oldTable, NSViewAnimationTargetKey, NSViewAnimationFadeOutEffect, NSViewAnimationEffectKey, nil];
            NSDictionary *fadeInDict = [[NSDictionary alloc] initWithObjectsAndKeys:newTable, NSViewAnimationTargetKey, NSViewAnimationFadeInEffect, NSViewAnimationEffectKey, nil];
            
            animation = [[[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObjects:fadeOutDict, fadeInDict, nil]] autorelease];
            [fadeOutDict release];
            [fadeInDict release];
            
            [animation setAnimationBlockingMode:NSAnimationBlocking];
            [animation setDuration:0.75];
            [animation setAnimationCurve:NSAnimationEaseIn];
            [animation startAnimation];
        }
        
        [oldTable removeFromSuperview];
        [oldTable setHidden:NO];
        
        currentTableView = newTableView;
    }
}

- (void)displayOutlineView {
    [self replaceTable:currentTableView withTable:outlineView animate:NO];
    [self updateOutlineSelection];
}

- (void)fadeInOutlineView {
    [self replaceTable:currentTableView withTable:outlineView animate:YES];
    [self updateOutlineSelection];
}

- (void)displayThumbnailView {
    [self replaceTable:currentTableView withTable:thumbnailTableView animate:NO];
    [self updateThumbnailSelection];
    [self updateThumbnailsIfNeeded];
}

- (void)fadeInThumbnailView {
    [self replaceTable:currentTableView withTable:thumbnailTableView animate:YES];
    [self updateThumbnailSelection];
    [self updateThumbnailsIfNeeded];
}

- (void)displaySearchView {
    [self replaceTable:currentTableView withTable:findTableView animate:NO];
}

- (void)fadeInSearchView {
    [self replaceTable:currentTableView withTable:findTableView animate:YES];
}

- (void)displayNotesView {
    [self replaceTable:subwindowsTableView withTable:notesTableView animate:NO];
}

- (void)fadeInNotesView {
    [self replaceTable:subwindowsTableView withTable:notesTableView animate:YES];
}

- (void)displaySubwindowsView {
    [self replaceTable:notesTableView withTable:subwindowsTableView animate:NO];
}

- (void)fadeInSubwindowsView {
    [self replaceTable:notesTableView withTable:subwindowsTableView animate:YES];
}

- (void)addAnnotationsForSelection:(PDFSelection *)sel {
    PDFDocument *doc = [pdfView document];
    NSArray *pages = [sel pages];
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    int i, iMax = [pages count];
    NSColor *color = nil;
    NSData *colorData = [[NSUserDefaults standardUserDefaults] dataForKey:SKSearchHighlightColorKey];
    
    if (colorData != nil)
        color = [NSUnarchiver unarchiveObjectWithData:colorData];
    if (color == nil)
        color = [NSColor redColor];
    
    for (i = 0; i < iMax; i++) {
        PDFPage *page = [pages objectAtIndex:i];
        NSRect bounds = NSInsetRect([sel boundsForPage:page], -3.0, -3.0);
        SKPDFAnnotationTemporary *circle = [[SKPDFAnnotationTemporary alloc] initWithBounds:bounds];
        [circle setColor:color];
        [page addAnnotation:circle];
        [pdfView setNeedsDisplayForAnnotation:circle];
        [indexes addIndex:[doc indexForPage:page]];
        [circle release];
    }
    
    [self thumbnailsAtIndexesNeedUpdate:indexes];
}

- (void)removeTemporaryAnnotations {
    PDFDocument *doc = [pdfView document];
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    unsigned i, iMax = [doc pageCount];
    for (i = 0; i < iMax; i++) {
        PDFPage *page = [doc pageAtIndex:i];
        NSArray *annotations = [[page annotations] copy];
        unsigned j, jMax = [annotations count];
        PDFAnnotation *annote;
        for (j = 0; j < jMax; j++) {
            annote = [annotations objectAtIndex:j];
            if ([annote isTemporaryAnnotation]) {
                [page removeAnnotation:annote];
                [pdfView setNeedsDisplayForAnnotation:annote];
                [indexes addIndex:[doc indexForPage:page]];
            }
        }
        [annotations release];
    }
    [self thumbnailsAtIndexesNeedUpdate:indexes];
}

- (IBAction)search:(id)sender {
    if ([[sender stringValue] isEqualToString:@""]) {
        // get rid of temporary annotations
        [self removeTemporaryAnnotations];
        if (sidePaneState == SKThumbnailSidePaneState)
            [self fadeInThumbnailView];
        else 
            [self fadeInOutlineView];
        [sidePaneViewButton setSelectedSegment:sidePaneState];
    } else {
        [self fadeInSearchView];
        [sidePaneViewButton setSelected:NO forSegment:0];
        [sidePaneViewButton setSelected:NO forSegment:1];
    }
    [[pdfView document] findString:[sender stringValue] withOptions:NSCaseInsensitiveSearch];
}

#pragma mark NSTableView delegate protocol

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
    if ([[aNotification object] isEqual:findTableView]) {
        
        BOOL highlight = [[NSUserDefaults standardUserDefaults] boolForKey:SKShouldHighlightSearchResultsKey];
        
        // clear the selection
        [pdfView setCurrentSelection:nil];
        [self removeTemporaryAnnotations];
        
        // union all selected objects
        NSEnumerator *selE = [[findArrayController selectedObjects] objectEnumerator];
        PDFSelection *sel;
        
        // arm:  PDFSelection is mutable, and using -addSelection on an object from selectedObjects will actually mutate the object in searchResults, which does bad things.  MagicHat indicates that PDFSelection implements copyWithZone: even though it doesn't conform to <NSCopying>, so we'll use that since -init doesn't work (-initWithDocument: does, but it's not listed in the header either).  I filed rdar://problem/4888251 and also noticed that PDFKitViewer sample code uses -[PDFSelection copy].
        PDFSelection *currentSel = [[[selE nextObject] copy] autorelease];
        
        // add an annotation so it's easier to see the search result
        if (highlight)
            [self addAnnotationsForSelection:currentSel];
        
        while (sel = [selE nextObject]) {
            [currentSel addSelection:sel];
            if (highlight)
                [self addAnnotationsForSelection:sel];
        }
        
        [pdfView setCurrentSelection:currentSel];
        [pdfView scrollSelectionToVisible:self];
    } else if ([[aNotification object] isEqual:thumbnailTableView]) {
        if (updatingThumbnailSelection == NO) {
            int row = [thumbnailTableView selectedRow];
            if (row != -1)
                [pdfView goToPage:[[pdfView document] pageAtIndex:row]];
        }
    } else if ([[aNotification object] isEqual:notesTableView]) {
        if (updatingNoteSelection == NO) {
            NSArray *selectedNotes = [notesArrayController selectedObjects];
            if ([selectedNotes count])
                [pdfView goToDestination:[[selectedNotes objectAtIndex:0] destination]];
        }
    }
}

// AppKit bug: need a dummy NSTableDataSource implementation, otherwise some NSTableView delegate methods are ignored
- (int)numberOfRowsInTableView:(NSTableView *)tv { return 0; }

- (id)tableView:(NSTableView *)tv objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row { return nil; }

- (NSString *)tableView:(NSTableView *)tv toolTipForCell:(NSCell *)aCell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)tableColumn row:(int)row mouseLocation:(NSPoint)mouseLocation{
    if ([tv isEqual:notesTableView])
        return [[[notesArrayController arrangedObjects] objectAtIndex:row] contents];
    return nil;
}

- (void)tableView:(NSTableView *)tv deleteRowsWithIndexes:(NSIndexSet *)rowIndexes {
    if ([tv isEqual:notesTableView]) {
        NSArray *notesToRemove = [[notesArrayController arrangedObjects] objectsAtIndexes:rowIndexes];
        NSEnumerator *noteEnum = [notesToRemove objectEnumerator];
        PDFAnnotation *annotation;
        
        while (annotation = [noteEnum nextObject])
            [pdfView removeAnnotation:annotation];
    } else if ([tv isEqual:subwindowsTableView]) {
        [subwindowsArrayController removeObjectsAtArrangedObjectIndexes:rowIndexes];
    }
}

#pragma mark Sub- and note- windows

- (void)showSubWindowAtPageNumber:(int)pageNum location:(NSPoint)locationInPageSpace{
    
    SKSubWindowController *swc = [[SKSubWindowController alloc] init];
    
    PDFDocument *doc = [pdfView document];
    [swc setPdfDocument:doc
            scaleFactor:[pdfView scaleFactor]
             autoScales:[pdfView autoScales]
         goToPageNumber:pageNum
                  point:locationInPageSpace];
    
    [[self document] addWindowController:swc];
    [swc release];
    [swc showWindow:self];
}

- (void)miniaturizeSubWindowController:(SKSubWindowController *)controller {
    if ([self isPresentation] == NO && [subwindowsTableView window] == nil) {
        [notesDrawer open];
        [self displaySubwindowsView];
        [drawerViewButton setSelectedSegment:1];
    }
    
    NSImage *image = [controller thumbnailWithSize:256.0 shadowBlurRadius:8.0 shadowOffset:NSMakeSize(0.0, -6.0)];
    PDFPage *page = [[controller pdfView] currentPage];
    SKThumbnail *thumbnail = [[SKThumbnail alloc] initWithImage:image label:[page label]];
    
    [thumbnail setController:controller];
    [thumbnail setPageIndex:[[page document] indexForPage:page]];
    [subwindowsArrayController addObject:thumbnail];
    [thumbnail release];
    
    if ([self isPresentation] == NO) {
        NSRect startRect = [controller rectForThumbnail];
        float ratio = NSHeight(startRect) / NSWidth(startRect);
        NSRect endRect = [subwindowsTableView frameOfCellAtColumn:0 row:[[subwindowsArrayController arrangedObjects] indexOfObject:thumbnail]];
        
        startRect.origin = [[controller window] convertBaseToScreen:startRect.origin];
        endRect = [subwindowsTableView convertRect:endRect toView:nil];
        endRect.origin = [[subwindowsTableView window] convertBaseToScreen:endRect.origin];
        if (ratio > 1.0)
            endRect = NSInsetRect(endRect, 0.5 * NSWidth(endRect) * (1.0 - 1.0 / ratio), 0.0);
        else
            endRect = NSInsetRect(endRect, 0.0, 0.5 * NSHeight(endRect) * (1.0 - ratio));
        
        image = [controller thumbnailWithSize:0.0 shadowBlurRadius:0.0 shadowOffset:NSZeroSize];
        
        SKMiniaturizeWindow *miniaturizeWindow = [[SKMiniaturizeWindow alloc] initWithContentRect:startRect image:image];
        [miniaturizeWindow orderFront:self];
        [[controller window] orderOut:self];
        [miniaturizeWindow setFrame:endRect display:YES animate:YES];
        [miniaturizeWindow orderOut:self];
        [miniaturizeWindow release];
        
    } else {
        [[controller window] orderOut:self];
    }
}

- (void)deminiaturizeSubWindows:(NSArray *)subwindowsToShow {
    // there should only be a single note
	SKThumbnail *thumbnail = [subwindowsToShow lastObject];
    SKSubWindowController *controller = [thumbnail controller];
    
    [[self document] addWindowController:controller];
    
    if ([self isPresentation] == NO) {
        NSRect endRect = [controller rectForThumbnail];
        float ratio = NSHeight(endRect) / NSWidth(endRect);
        NSRect cellRect = [subwindowsTableView frameOfCellAtColumn:0 row:[[subwindowsArrayController arrangedObjects] indexOfObject:thumbnail]];
        NSRect startRect = [subwindowsTableView convertRect:cellRect toView:nil];
        
        endRect.origin = [[controller window] convertBaseToScreen:endRect.origin];
        startRect.origin = [[subwindowsTableView window] convertBaseToScreen:startRect.origin];
        if (ratio > 1.0)
            startRect = NSInsetRect(startRect, 0.5 * NSWidth(startRect) * (1.0 - 1.0 / ratio), 0.0);
        else
            startRect = NSInsetRect(startRect, 0.0, 0.5 * NSHeight(startRect) * (1.0 - ratio));
        
        NSImage *image = [controller thumbnailWithSize:0.0 shadowBlurRadius:0.0 shadowOffset:NSZeroSize];
        SKMiniaturizeWindow *miniaturizeWindow = [[SKMiniaturizeWindow alloc] initWithContentRect:startRect image:image];
        [miniaturizeWindow orderFront:self];
        [thumbnail setImage:nil];
        [subwindowsTableView displayRect:cellRect];
        [miniaturizeWindow setFrame:endRect display:YES animate:YES];
        [[controller window] orderFront:self];
        [miniaturizeWindow orderOut:self];
        [miniaturizeWindow release];
    } else {
        [controller showWindow:self];
    }
    [subwindowsArrayController removeObject:thumbnail];
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
        [[self document] addWindowController:wc];
        [wc release];
    }
    [wc showWindow:self];
}

#pragma mark Notification handlers

- (void)handleChangedHistoryNotification:(NSNotification *)notification {
    [backForwardButton setEnabled:[pdfView canGoBack] forSegment:0];
    [backForwardButton setEnabled:[pdfView canGoForward] forSegment:1];
}

- (void)handlePageChangedNotification:(NSNotification *)notification {
	PDFDocument *pdfDoc = [pdfView document];
    unsigned pageIndex = [pdfDoc indexForPage:[pdfView currentPage]];
    
    [pageNumberStepper setIntValue:pageIndex + 1];
    [pageNumberField setIntValue:pageIndex + 1];
    
    [self updateOutlineSelection];
    [self updateNoteSelection];
    [self updateThumbnailSelection];
}

- (void)handleScaleChangedNotification:(NSNotification *)notification {
    [scaleField setFloatValue:[pdfView scaleFactor] * 100.0];
}

- (void)handleToolModeChangedNotification:(NSNotification *)notification {
	unsigned toolMode = [pdfView toolMode];
    [toolModeButton setSelectedSegment:toolMode];
}

- (void)handleAnnotationModeChangedNotification:(NSNotification *)notification {
	unsigned annotationMode = [pdfView annotationMode];
    [annotationModeButton setSelectedSegment:annotationMode];
}

- (void)handleAppWillTerminateNotification:(NSNotification *)notification {
    if ([self isFullScreen] || [self isPresentation])
        [self exitFullScreen:self];
}

- (void)handleDidChangeActiveAnnotationNotification:(NSNotification *)notification {
    PDFAnnotation *annotation = [pdfView activeAnnotation];
    updatingNoteSelection = YES;
    [notesArrayController setSelectedObjects:[NSArray arrayWithObjects:annotation, nil]];
    updatingNoteSelection = NO;
    if (annotation)
        [[NSColorPanel sharedColorPanel] setColor:[annotation color]];
}

- (void)handleDidAddAnnotationNotification:(NSNotification *)notification {
    PDFAnnotation *annotation = [[notification userInfo] objectForKey:@"annotation"];
    PDFPage *page = [[notification userInfo] objectForKey:@"page"];;
    if (annotation) {
        updatingNoteSelection = YES;
        [[(SKDocument *)[self document] mutableArrayValueForKey:@"notes"] addObject:annotation];
        updatingNoteSelection = NO;
        if (page)
            [self thumbnailAtIndexNeedsUpdate:[[pdfView document] indexForPage:page]];
    }
    [[self window] setDocumentEdited:YES];
}

- (void)handleDidRemoveAnnotationNotification:(NSNotification *)notification {
    PDFAnnotation *annotation = [[notification userInfo] objectForKey:@"annotation"];
    PDFPage *page = [[notification userInfo] objectForKey:@"page"];;
    if (annotation) {
        NSWindowController *wc = nil;
        NSEnumerator *wcEnum = [[[self document] windowControllers] objectEnumerator];
        
        while (wc = [wcEnum nextObject]) {
            if ([wc isKindOfClass:[SKNoteWindowController class]] && [(SKNoteWindowController *)wc note] == annotation) {
                [wc close];
                break;
            }
        }
        [[[self document] mutableArrayValueForKey:@"notes"] removeObject:annotation];
        if (page)
            [self thumbnailAtIndexNeedsUpdate:[[pdfView document] indexForPage:page]];
    }
    [[self window] setDocumentEdited:YES];
}

- (void)handleDidChangeAnnotationNotification:(NSNotification *)notification {
    PDFAnnotation *annotation = [[notification userInfo] objectForKey:@"annotation"];
    [[self window] setDocumentEdited:YES];
    [self thumbnailAtIndexNeedsUpdate:[annotation pageIndex]];
}

- (void)handleDoubleClickedAnnotationNotification:(NSNotification *)notification {
    PDFAnnotation *annotation = [[notification userInfo] objectForKey:@"annotation"];
    
    [self showNote:annotation];
}

#pragma mark NSOutlineView methods

- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item{
	if (item == nil){
		if ((pdfOutline) && ([[pdfView document] isLocked] == NO)){
			return [pdfOutline numberOfChildren];
		}else{
			return 0;
        }
	}else{
		return [(PDFOutline *)item numberOfChildren];
    }
}

- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item{
	if (item == nil){
		if ((pdfOutline) && ([[pdfView document] isLocked] == NO)){
            
			return [[pdfOutline childAtIndex: index] retain];
            
        }else{
			return nil;
        }
	}else{
		return [[(PDFOutline *)item childAtIndex: index] retain];
    }
}


- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item{
	if (item == nil){
		if ((pdfOutline) && ([[pdfView document] isLocked] == NO)){
			return ([pdfOutline numberOfChildren] > 0);
		}else{
			return NO;
        }
	}else{
		return ([(PDFOutline *)item numberOfChildren] > 0);
    }
}


- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item{
    NSString *tcID = [tableColumn identifier];
    if([tcID isEqualToString:@"label"]){
        return [(PDFOutline *)item label];
    }else if([tcID isEqualToString:@"icon"]){
        return [[[(PDFOutline *)item destination] page] label];
    }else{
        [NSException raise:@"Unexpected tablecolumn identifier" format:@" - %@ ", tcID];
        return nil;
    }
}


- (void)outlineViewSelectionDidChange:(NSNotification *)notification{
	// Get the destination associated with the search result list. Tell the PDFView to go there.
	if (([notification object] == outlineView) && (updatingOutlineSelection == NO)){
		[pdfView goToDestination: [[outlineView itemAtRow: [outlineView selectedRow]] destination]];
    }
}


- (void)outlineViewItemDidExpand:(NSNotification *)notification{
	[self updateOutlineSelection];
}


- (void)outlineViewItemDidCollapse:(NSNotification *)notification{
	[self updateOutlineSelection];
}


- (void)updateOutlineSelection{

	PDFOutline	*outlineItem;
	unsigned int pageIndex;
	int			 numRows;
	int			 i;
	
	// Skip out if this PDF has no outline.
	if (pdfOutline == nil)
		return;
	
	// Get index of current page.
	pageIndex = [[pdfView document] indexForPage: [pdfView currentPage]];
	
	// Test that the current selection is still valid.
	outlineItem = (PDFOutline *)[outlineView itemAtRow: [outlineView selectedRow]];
	if ([[pdfView document] indexForPage: [[outlineItem destination] page]] == pageIndex)
		return;
	
	// Walk outline view looking for best firstpage number match.
	numRows = [outlineView numberOfRows];
	for (i = 0; i < numRows; i++)
	{
		// Get the destination of the given row....
		outlineItem = (PDFOutline *)[outlineView itemAtRow: i];
		
		if ([[pdfView document] indexForPage: [[outlineItem destination] page]] == pageIndex)
		{
			updatingOutlineSelection = YES;
			[outlineView selectRow: i byExtendingSelection: NO];
			updatingOutlineSelection = NO;
			break;
		}
		else if ([[pdfView document] indexForPage: [[outlineItem destination] page]] > pageIndex)
		{
			updatingOutlineSelection = YES;
			if (i < 1)				
				[outlineView selectRow: 0 byExtendingSelection: NO];
			else
				[outlineView selectRow: i - 1 byExtendingSelection: NO];
			updatingOutlineSelection = NO;
			break;
		}
	}
}

#pragma mark Thumbnails

- (void)updateThumbnailSelection {
	// Get index of current page.
	unsigned pageIndex = [[pdfView document] indexForPage: [pdfView currentPage]];
    updatingThumbnailSelection = YES;
    [thumbnailTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:pageIndex] byExtendingSelection:NO];
    updatingThumbnailSelection = NO;
}

- (void)resetThumbnails {
    PDFDocument *pdfDoc = [pdfView document];
    unsigned i, count = [pdfDoc pageCount];
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:count];
    if (count) {
        PDFPage *emptyPage = [[[PDFPage alloc] init] autorelease];
        [emptyPage setBounds:[[[pdfView document] pageAtIndex:0] boundsForBox:kPDFDisplayBoxCropBox] forBox:kPDFDisplayBoxCropBox];
        NSImage *image = [emptyPage thumbnailWithSize:256.0 shadowBlurRadius:8.0 shadowOffset:NSMakeSize(0.0, -6.0)];
        for (i = 0; i < count; i++) {
            SKThumbnail *thumbnail = [[SKThumbnail alloc] initWithImage:image label:[[pdfDoc pageAtIndex:i] label]];
            [array insertObject:thumbnail atIndex:i];
            [thumbnail release];
        }
    }
    [[self mutableArrayValueForKey:@"thumbnails"] setArray:array];
    [dirtyThumbnailIndexes removeAllIndexes];
    [dirtyThumbnailIndexes addIndexesInRange:NSMakeRange(0, count)];
    [self updateThumbnailsIfNeeded];
}

- (void)thumbnailAtIndexNeedsUpdate:(unsigned)index {
    [self thumbnailsAtIndexesNeedUpdate:[NSIndexSet indexSetWithIndex:index]];
}

- (void)thumbnailsAtIndexesNeedUpdate:(NSIndexSet *)indexes {
    [dirtyThumbnailIndexes addIndexes:indexes];
    [self updateThumbnailsIfNeeded];
}

- (void)updateThumbnailsIfNeeded {
    if ([thumbnailTableView window] != nil && [dirtyThumbnailIndexes count] > 0 && thumbnailTimer == nil)
        thumbnailTimer = [[NSTimer scheduledTimerWithTimeInterval:0.03 target:self selector:@selector(updateThumbnail:) userInfo:NULL repeats:YES] retain];
}

- (void)updateThumbnail:(NSTimer *)timer {
    unsigned index = [dirtyThumbnailIndexes firstIndex];
    
    if (index != NSNotFound) {
        PDFDocument *pdfDoc = [pdfView document];
        PDFPage *page = [pdfDoc pageAtIndex:index];
        NSImage *image = [page thumbnailWithSize:256.0 shadowBlurRadius:8.0 shadowOffset:NSMakeSize(0.0, -6.0)];
        [[thumbnails objectAtIndex:index] setImage:image];
        [dirtyThumbnailIndexes removeIndex:index];
    }
    if ([dirtyThumbnailIndexes count] == 0) {
        [thumbnailTimer invalidate];
        [thumbnailTimer release];
        thumbnailTimer = nil;
    }
}

- (void)updateNoteSelection {

	NSArray *notes = [notesArrayController arrangedObjects];
    PDFAnnotation *annotation;
    unsigned int pageIndex = [[pdfView document] indexForPage: [pdfView currentPage]];
	int i, numRows = [notes count];
    unsigned int selPageIndex = [notesTableView numberOfSelectedRows] ? [[notes objectAtIndex:[notesTableView selectedRow]] pageIndex] : NSNotFound;
	
    if (numRows == 0 || selPageIndex == pageIndex)
		return;
	
	// Walk outline view looking for best firstpage number match.
	for (i = 0; i < numRows; i++) {
		// Get the destination of the given row....
		annotation = [notes objectAtIndex:i];
		
		if ([annotation pageIndex] == pageIndex) {
			updatingNoteSelection = YES;
			[notesTableView selectRow:i byExtendingSelection:NO];
			updatingNoteSelection = NO;
			break;
		} else if ([annotation pageIndex] > pageIndex) {
			updatingNoteSelection = YES;
			if (i < 1)				
				[notesTableView selectRow:0 byExtendingSelection:NO];
			else if ([[notes objectAtIndex:i - 1] pageIndex] != selPageIndex)
				[notesTableView selectRow:i - 1 byExtendingSelection:NO];
			updatingNoteSelection = NO;
			break;
		}
	}
}

#pragma mark Toolbar

- (void)setupToolbar {
    // Create a new toolbar instance, and attach it to our document window
    NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier:SKDocumentToolbarIdentifier] autorelease];
    NSToolbarItem *item;
    NSRect frame;
    
    toolbarItems = [[NSMutableDictionary alloc] initWithCapacity:9];
    
    // Set up toolbar properties: Allow customization, give a default display mode, and remember state in user defaults
    [toolbar setAllowsUserCustomization: YES];
    [toolbar setAutosavesConfiguration: YES];
    [toolbar setDisplayMode: NSToolbarDisplayModeDefault];
    
    // We are the delegate
    [toolbar setDelegate: self];
    
    // Add template toolbar items
    
    item = [[NSToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarPreviousItemIdentifier];
    [item setLabel:NSLocalizedString(@"Previous", @"Toolbar item label")];
    [item setPaletteLabel:NSLocalizedString(@"Previous", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Go To Previous Page", @"Tool tip message")];
    [item setImage:[NSImage imageNamed:@"ToolbarPrevious"]];
    [item setTarget:self];
    [item setAction:@selector(doGoToPreviousPage:)];
    [toolbarItems setObject:item forKey:SKDocumentToolbarPreviousItemIdentifier];
    [item release];
    
    item = [[NSToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarNextItemIdentifier];
    [item setLabel:NSLocalizedString(@"Next", @"Toolbar item label")];
    [item setPaletteLabel:NSLocalizedString(@"Next", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Go To Next Page", @"Tool tip message")];
    [item setImage:[NSImage imageNamed:@"ToolbarNext"]];
    [item setTarget:self];
    [item setAction:@selector(doGoToNextPage:)];
    [toolbarItems setObject:item forKey:SKDocumentToolbarNextItemIdentifier];
    [item release];
    
    item = [[NSToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarBackForwardItemIdentifier];
    [item setLabel:NSLocalizedString(@"Back/Forward", @"Toolbar item label")];
    [item setPaletteLabel:NSLocalizedString(@"Back/Forward", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Back/Forward", @"Tool tip message")];
    [[backForwardButton cell] setToolTip:NSLocalizedString(@"Go Back", @"Tool tip message") forSegment:0];
    [[backForwardButton cell] setToolTip:NSLocalizedString(@"Go Forward", @"Tool tip message") forSegment:1];
    frame = [backForwardButton frame];
    frame.size.height = SEGMENTED_CONTROL_HEIGHT;
    [backForwardButton setFrame:frame];
    [item setView:backForwardButton];
    [item setMinSize:[backForwardButton bounds].size];
    [item setMaxSize:[backForwardButton bounds].size];
    [toolbarItems setObject:item forKey:SKDocumentToolbarBackForwardItemIdentifier];
    [item release];
    
    item = [[NSToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarPageNumberItemIdentifier];
    [item setLabel:NSLocalizedString(@"Page", @"Toolbar item label")];
    [item setPaletteLabel:NSLocalizedString(@"Page", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Go To Page", @"Tool tip message")];
    [item setView:pageNumberView];
    [item setMinSize:[pageNumberView bounds].size];
    [item setMaxSize:[pageNumberView bounds].size];
    [toolbarItems setObject:item forKey:SKDocumentToolbarPageNumberItemIdentifier];
    [item release];
    
    item = [[NSToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarScaleItemIdentifier];
    [item setLabel:NSLocalizedString(@"Scale", @"Toolbar item label")];
    [item setPaletteLabel:NSLocalizedString(@"Scale", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Scale", @"Tool tip message")];
    [item setView:scaleField];
    [item setMinSize:[scaleField bounds].size];
    [item setMaxSize:[scaleField bounds].size];
    [toolbarItems setObject:item forKey:SKDocumentToolbarScaleItemIdentifier];
    [item release];
    
    item = [[NSToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarZoomInItemIdentifier];
    [item setLabel:NSLocalizedString(@"Zoom In", @"Toolbar item label")];
    [item setPaletteLabel:NSLocalizedString(@"Zoom In", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Zoom In", @"Tool tip message")];
    [item setImage:[NSImage imageNamed:@"ToolbarZoomIn"]];
    [item setTarget:self];
    [item setAction:@selector(doZoomIn:)];
    [toolbarItems setObject:item forKey:SKDocumentToolbarZoomInItemIdentifier];
    [item release];
    
    item = [[NSToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarZoomOutItemIdentifier];
    [item setLabel:NSLocalizedString(@"Zoom Out", @"Toolbar item label")];
    [item setPaletteLabel:NSLocalizedString(@"Zoom Out", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Zoom Out", @"Tool tip message")];
    [item setImage:[NSImage imageNamed:@"ToolbarZoomOut"]];
    [item setTarget:self];
    [item setAction:@selector(doZoomOut:)];
    [toolbarItems setObject:item forKey:SKDocumentToolbarZoomOutItemIdentifier];
    [item release];
    
    item = [[NSToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarZoomActualItemIdentifier];
    [item setLabel:NSLocalizedString(@"Actual Size", @"Toolbar item label")];
    [item setPaletteLabel:NSLocalizedString(@"Actual Size", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Zoom To Actual Size", @"Tool tip message")];
    [item setImage:[NSImage imageNamed:@"ToolbarZoomActual"]];
    [item setTarget:self];
    [item setAction:@selector(doZoomToActualSize:)];
    [toolbarItems setObject:item forKey:SKDocumentToolbarZoomActualItemIdentifier];
    [item release];
    
    item = [[NSToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarZoomAutoItemIdentifier];
    [item setLabel:NSLocalizedString(@"Auto Zoom", @"Toolbar item label")];
    [item setPaletteLabel:NSLocalizedString(@"Zoom To Fit", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Zoom To Fit", @"Tool tip message")];
    [item setImage:[NSImage imageNamed:@"ToolbarZoomToFit"]];
    [item setTarget:self];
    [item setAction:@selector(doZoomToFit:)];
    [toolbarItems setObject:item forKey:SKDocumentToolbarZoomAutoItemIdentifier];
    [item release];
    
    item = [[NSToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarRotateRightItemIdentifier];
    [item setLabel:NSLocalizedString(@"Rotate Right", @"Toolbar item label")];
    [item setPaletteLabel:NSLocalizedString(@"Rotate Right", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Rotate Right", @"Tool tip message")];
    [item setImage:[NSImage imageNamed:@"ToolbarRotateRight"]];
    [item setTarget:self];
    [item setAction:@selector(rotateAllRight:)];
    [toolbarItems setObject:item forKey:SKDocumentToolbarRotateRightItemIdentifier];
    [item release];
    
    item = [[NSToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarRotateLeftItemIdentifier];
    [item setLabel:NSLocalizedString(@"Rotate Left", @"Toolbar item label")];
    [item setPaletteLabel:NSLocalizedString(@"Rotate Left", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Rotate Left", @"Tool tip message")];
    [item setImage:[NSImage imageNamed:@"ToolbarRotateLeft"]];
    [item setTarget:self];
    [item setAction:@selector(rotateAllLeft:)];
    [toolbarItems setObject:item forKey:SKDocumentToolbarRotateLeftItemIdentifier];
    [item release];
    
    item = [[NSToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarFullScreenItemIdentifier];
    [item setLabel:NSLocalizedString(@"Full Screen", @"Toolbar item label")];
    [item setPaletteLabel:NSLocalizedString(@"Full Screen", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Full Screen", @"Tool tip message")];
    [item setImage:[NSImage imageNamed:@"ToolbarFullScreen"]];
    [item setTarget:self];
    [item setAction:@selector(enterFullScreen:)];
    [toolbarItems setObject:item forKey:SKDocumentToolbarFullScreenItemIdentifier];
    [item release];
    
    item = [[NSToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarPresentationItemIdentifier];
    [item setLabel:NSLocalizedString(@"Presentation", @"Toolbar item label")];
    [item setPaletteLabel:NSLocalizedString(@"Presentation", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Presentation", @"Tool tip message")];
    [item setImage:[NSImage imageNamed:@"ToolbarPresentation"]];
    [item setTarget:self];
    [item setAction:@selector(enterPresentation:)];
    [toolbarItems setObject:item forKey:SKDocumentToolbarPresentationItemIdentifier];
    [item release];
    
    item = [[NSToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarNewNoteItemIdentifier];
    [item setLabel:NSLocalizedString(@"New Note", @"Toolbar item label")];
    [item setPaletteLabel:NSLocalizedString(@"New Note", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Add New Note", @"Tool tip message")];
    [item setImage:[NSImage imageNamed:@"ToolbarNote"]];
    [item setTarget:self];
    [item setAction:@selector(createNewNote:)];
    [toolbarItems setObject:item forKey:SKDocumentToolbarNewNoteItemIdentifier];
    [item release];
    
    item = [[NSToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarToggleDrawerItemIdentifier];
    [item setLabel:NSLocalizedString(@"Drawer", @"Toolbar item label")];
    [item setPaletteLabel:NSLocalizedString(@"Drawer", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Toggle Drawer", @"Tool tip message")];
    [item setImage:[NSImage imageNamed:@"ToolbarNotesDrawer"]];
    [item setTarget:self];
    [item setAction:@selector(toggleNotesDrawer:)];
    [toolbarItems setObject:item forKey:SKDocumentToolbarToggleDrawerItemIdentifier];
    [item release];
    
    item = [[NSToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarToolModeItemIdentifier];
    [item setLabel:NSLocalizedString(@"Tool Mode", @"Toolbar item label")];
    [item setPaletteLabel:NSLocalizedString(@"Tool Mode", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Tool Mode", @"Tool tip message")];
    [[toolModeButton cell] setToolTip:NSLocalizedString(@"Text Tool", @"Tool tip message") forSegment:SKTextToolMode];
    [[toolModeButton cell] setToolTip:NSLocalizedString(@"Scroll Tool", @"Tool tip message") forSegment:SKMoveToolMode];
    [[toolModeButton cell] setToolTip:NSLocalizedString(@"Magnify Tool", @"Tool tip message") forSegment:SKMagnifyToolMode];
    frame = [toolModeButton frame];
    frame.size.height = SEGMENTED_CONTROL_HEIGHT;
    [toolModeButton setFrame:frame];
    [item setView:toolModeButton];
    [item setMinSize:[toolModeButton bounds].size];
    [item setMaxSize:[toolModeButton bounds].size];
    [toolbarItems setObject:item forKey:SKDocumentToolbarToolModeItemIdentifier];
    [item release];
    
    item = [[NSToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarAnnotationModeItemIdentifier];
    [item setLabel:NSLocalizedString(@"Annotation", @"Toolbar item label")];
    [item setPaletteLabel:NSLocalizedString(@"Annotation Mode", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Annotation Mode", @"Tool tip message")];
    [[annotationModeButton cell] setToolTip:NSLocalizedString(@"Text Annotation", @"Tool tip message") forSegment:SKFreeTextAnnotationMode];
    [[annotationModeButton cell] setToolTip:NSLocalizedString(@"Note Annotation", @"Tool tip message") forSegment:SKNoteAnnotationMode];
    [[annotationModeButton cell] setToolTip:NSLocalizedString(@"Oval Annotation", @"Tool tip message") forSegment:SKCircleAnnotationMode];
    frame = [annotationModeButton frame];
    frame.size.height = SEGMENTED_CONTROL_HEIGHT;
    [annotationModeButton setFrame:frame];
    [item setView:annotationModeButton];
    [item setMinSize:[annotationModeButton bounds].size];
    [item setMaxSize:[annotationModeButton bounds].size];
    [toolbarItems setObject:item forKey:SKDocumentToolbarAnnotationModeItemIdentifier];
    [item release];
    
    item = [[NSToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarDisplayBoxItemIdentifier];
    [item setLabel:NSLocalizedString(@"Display Box", @"Toolbar item label")];
    [item setPaletteLabel:NSLocalizedString(@"Display Box", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Display Box", @"Tool tip message")];
    [item setView:displayBoxPopUpButton];
    [item setMinSize:[displayBoxPopUpButton bounds].size];
    [item setMaxSize:[displayBoxPopUpButton bounds].size];
    [toolbarItems setObject:item forKey:SKDocumentToolbarDisplayBoxItemIdentifier];
    [item release];
	
    item = [[NSToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarSearchItemIdentifier];
    [item setLabel:NSLocalizedString(@"Search", @"Toolbar item label")];
    [item setPaletteLabel:NSLocalizedString(@"Search", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Search", @"Tool tip message")];
    [item setTarget:self];
    [item setView:searchField];
    [item setMinSize:TOOLBAR_SEARCHFIELD_MIN_SIZE];
    [item setMaxSize:TOOLBAR_SEARCHFIELD_MAX_SIZE];
    [toolbarItems setObject:item forKey:SKDocumentToolbarSearchItemIdentifier];
    [item release];
    
    item = [[NSToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarInfoItemIdentifier];
    [item setLabel:NSLocalizedString(@"Info", @"Toolbar item label")];
    [item setPaletteLabel:NSLocalizedString(@"Info", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Get Document Info", @"Tool tip message")];
    [item setImage:[NSImage imageNamed:@"ToolbarInfo"]];
    [item setTarget:self];
    [item setAction:@selector(getInfo:)];
    [toolbarItems setObject:item forKey:SKDocumentToolbarInfoItemIdentifier];
    [item release];
    
    // Attach the toolbar to the window
    [[self window] setToolbar:toolbar];
}

- (NSToolbarItem *) toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted {

    NSToolbarItem *item = [toolbarItems objectForKey:itemIdent];
    NSToolbarItem *newItem = [[item copy] autorelease];
    // the view should not be copied
    if ([item view] && willBeInserted) [newItem setView:[item view]];
    return newItem;
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
        SKDocumentToolbarToolModeItemIdentifier, nil];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
    return [NSArray arrayWithObjects: 
        SKDocumentToolbarPreviousItemIdentifier, 
        SKDocumentToolbarNextItemIdentifier, 
        SKDocumentToolbarBackForwardItemIdentifier, 
        SKDocumentToolbarPageNumberItemIdentifier, 
        SKDocumentToolbarScaleItemIdentifier, 
        SKDocumentToolbarZoomInItemIdentifier, 
        SKDocumentToolbarZoomOutItemIdentifier, 
        SKDocumentToolbarZoomActualItemIdentifier, 
        SKDocumentToolbarZoomAutoItemIdentifier, 
        SKDocumentToolbarRotateRightItemIdentifier, 
        SKDocumentToolbarRotateLeftItemIdentifier, 
        SKDocumentToolbarFullScreenItemIdentifier, 
        SKDocumentToolbarPresentationItemIdentifier, 
        SKDocumentToolbarNewNoteItemIdentifier, 
        SKDocumentToolbarToggleDrawerItemIdentifier, 
        SKDocumentToolbarInfoItemIdentifier, 
        SKDocumentToolbarToolModeItemIdentifier, 
        SKDocumentToolbarAnnotationModeItemIdentifier, 
        SKDocumentToolbarDisplayBoxItemIdentifier, 
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
    } else if ([identifier isEqualToString:SKDocumentToolbarZoomAutoItemIdentifier]) {
        return [pdfView autoScales] == NO;
    } else if ([identifier isEqualToString:SKDocumentToolbarZoomActualItemIdentifier]) {
        return fabs([pdfView scaleFactor] - 1.0) > 0.01;
    } else if ([identifier isEqualToString:SKDocumentToolbarFullScreenItemIdentifier]) {
        return YES;
    } else if ([identifier isEqualToString:SKDocumentToolbarPresentationItemIdentifier]) {
        return YES;
    } else if ([identifier isEqualToString:SKDocumentToolbarInfoItemIdentifier]) {
        return NO;
    } else {
        return YES;
    }
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    SEL action = [menuItem action];
    if (action == @selector(createNewNote:)) {
        return [pdfView toolMode] == SKTextToolMode;
    } else if (action == @selector(displaySinglePages:)) {
        BOOL displaySinglePages = [pdfView displayMode] == kPDFDisplaySinglePage || [pdfView displayMode] == kPDFDisplaySinglePageContinuous;
        [menuItem setState:displaySinglePages ? NSOnState : NSOffState];
        return YES;
    } else if (action == @selector(displayFacingPages:)) {
        BOOL displayFacingPages = [pdfView displayMode] == kPDFDisplayTwoUp || [pdfView displayMode] == kPDFDisplayTwoUpContinuous;
        [menuItem setState:displayFacingPages ? NSOnState : NSOffState];
        return YES;
    } else if (action == @selector(toggleDisplayContinuous:)) {
        BOOL displayContinuous = [pdfView displayMode] == kPDFDisplaySinglePageContinuous || [pdfView displayMode] == kPDFDisplayTwoUpContinuous;
        [menuItem setState:displayContinuous ? NSOnState : NSOffState];
        return YES;
    } else if (action == @selector(toggleDisplayAsBook:)) {
        [menuItem setState:[pdfView displaysAsBook] ? NSOnState : NSOffState];
        return [pdfView displayMode] == kPDFDisplayTwoUp || [pdfView displayMode] == kPDFDisplayTwoUpContinuous;
    } else if (action == @selector(toggleDisplayPageBreaks:)) {
        [menuItem setState:[pdfView displaysPageBreaks] ? NSOnState : NSOffState];
        return YES;
    } else if (action == @selector(displayMediaBox:)) {
        BOOL displayMediaBox = [pdfView displayBox] == kPDFDisplayBoxMediaBox;
        [menuItem setState:displayMediaBox ? NSOnState : NSOffState];
        return YES;
    } else if (action == @selector(displayCropBox:)) {
        BOOL displayCropBox = [pdfView displayBox] == kPDFDisplayBoxCropBox;
        [menuItem setState:displayCropBox ? NSOnState : NSOffState];
        return YES;
    } else if (action == @selector(changeToolMode:)) {
        [menuItem setState:[pdfView toolMode] == (unsigned)[menuItem tag] ? NSOnState : NSOffState];
        return YES;
    } else if (action == @selector(changeAnnotationMode:)) {
        [menuItem setState:[pdfView annotationMode] == (unsigned)[menuItem tag] ? NSOnState : NSOffState];
        return YES;
    } else if (action == @selector(doGoToNextPage:)) {
        return [pdfView canGoToNextPage];
    } else if (action == @selector(doGoToPreviousPage:)) {
        return [pdfView canGoToPreviousPage];
    } else if (action == @selector(doGoBack:)) {
        return [pdfView canGoBack];
    } else if (action == @selector(doGoForward:)) {
        return [pdfView canGoForward];
    } else if (action == @selector(doZoomIn:)) {
        return [pdfView canZoomIn];
    } else if (action == @selector(doZoomOut:)) {
        return [pdfView canZoomOut];
    } else if (action == @selector(doZoomToActualSize:)) {
        return fabs([pdfView scaleFactor] - 1.0 ) > 0.01;
    } else if (action == @selector(doZoomToFit:)) {
        return [pdfView autoScales] == NO;
    } else if (action == @selector(toggleFullScreen:)) {
        return YES;
    } else if (action == @selector(togglePresentation:)) {
        return YES;
    } else if (action == @selector(toggleNotesDrawer:)) {
        NSDrawerState state = [notesDrawer state];
        if (state == NSDrawerClosedState || state == NSDrawerClosingState)
            [menuItem setTitle:NSLocalizedString(@"Show Notes Drawer", @"")];
        else 
            [menuItem setTitle:NSLocalizedString(@"Hide Notes Drawer", @"")];
        return YES;
    } else if (action == @selector(getInfo:)) {
        return YES;
    }
    return YES;
}

#pragma mark SKSplitView delegate protocol

- (void)splitViewDoubleClick:(SKSplitView *)sender {
    NSView *leftView = [[sender subviews] objectAtIndex:0]; // table
    NSView *rightView = [[sender subviews] objectAtIndex:1]; // pdfView
    NSRect leftFrame = [leftView frame];
    NSRect rightFrame = [rightView frame];
    
    if(NSWidth(leftFrame) > 0.0){ // not sure what the criteria for isSubviewCollapsed, but it doesn't work
        lastSidePaneWidth = NSWidth(leftFrame); // cache this
        rightFrame.size.width += lastSidePaneWidth;
        leftFrame.size.width = 0.0;
    } else {
        if(lastSidePaneWidth <= 0)
            lastSidePaneWidth = 250.0; // a reasonable value to start
		leftFrame.size.width = lastSidePaneWidth;
        rightFrame.size.width = NSWidth([sender frame]) - lastSidePaneWidth - [sender dividerThickness];
    }
    [leftView setFrame:leftFrame];
    [rightView setFrame:rightFrame];
    [sender adjustSubviews];
}

@end


@implementation SKFullScreenWindow

- (id)initWithScreen:(NSScreen *)screen {
    if (self = [self initWithContentRect:[screen frame] styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO screen:screen]) {
        [self setReleasedWhenClosed:NO];
        [self setDisplaysWhenScreenProfileChanges:YES];
        [self setAcceptsMouseMovedEvents:YES];
    }
    return self;
}

- (BOOL)canBecomeKeyWindow {
    return YES;
}

- (void)keyDown:(NSEvent *)theEvent {
    NSString *characters = [theEvent charactersIgnoringModifiers];
    unichar ch = [characters length] > 0 ? [characters characterAtIndex:0] : 0;
	unsigned modifierFlags = [theEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask;
    
    if (modifierFlags == 0) {
        SKMainWindowController *wc = (SKMainWindowController *)[self windowController];
        if (ch == 0x1B) {
            [wc exitFullScreen:self];
        } else if (ch == '1' && [wc isPresentation]) {
            [wc displaySinglePages:self];
        } else if (ch == '2' && [wc isPresentation]) {
            [wc displayFacingPages:self];
        } else {
            [super keyDown:theEvent];
        }
    } else {
        [super keyDown:theEvent];
    }
}

@end

@implementation SKThumbnail

- (id)initWithImage:(NSImage *)anImage label:(NSString *)aLabel {
    if (self = [super init]) {
        image = [anImage retain];
        label = [aLabel retain];
        pageIndex = 0;
        controller = nil;
    }
    return self;
}

- (void)dealloc {
    [image release];
    [label release];
    [controller release];
    [super dealloc];
}

- (NSImage *)image {
    return image;
}

- (void)setImage:(NSImage *)newImage {
    if (image != newImage) {
        [image release];
        image = [newImage retain];
    }
}

- (NSString *)label {
    return label;
}

- (void)setLabel:(NSString *)newLabel {
    if (label != newLabel) {
        [label release];
        label = [newLabel retain];
    }
}

- (unsigned int)pageIndex {
    return pageIndex;
}

- (void)setPageIndex:(unsigned int)newPageIndex {
    if (pageIndex != newPageIndex) {
        pageIndex = newPageIndex;
    }
}

- (id)controller {
    return controller;
}

- (void)setController:(id)newController {
    if (controller != newController) {
        [controller release];
        controller = [newController retain];
    }
}

@end

// the search table columns use these methods for display
@interface PDFSelection (SKExtensions)
@end

@implementation PDFSelection (SKExtensions)

// returns the label of the first page (if the selection spans multiple pages)
- (NSString *)firstPageLabel { 
    NSArray *pages = [self pages];
    return [pages count] ? [[pages objectAtIndex:0] label] : nil;
}

// displays the selection string with some surrounding context as well
- (NSString *)contextString {
    
    NSArray *pages = [self pages];
    int i, iMax = [pages count];
    NSMutableString *string = [NSMutableString string];
    
    for (i = 0; i < iMax; i++) {
        
        PDFPage *page = [pages objectAtIndex:i];
        NSString *pageString = [page string];
        if (pageString) {
            NSRect r = [self boundsForPage:page];
            
            int start, end;
            start = [page characterIndexAtPoint:NSMakePoint(NSMinX(r), NSMinY(r))];
            end = [page characterIndexAtPoint:NSMakePoint(NSMaxX(r), NSMinY(r))];
            
            if (start != -1 && end != -1) {
                start = MAX(start - 10, 0);
                end = MIN(end + 20, (int)[pageString length]);
                [string appendString:[pageString substringWithRange:NSMakeRange(start, end - start)]];
            } else {
                // this shouldn't happen, but just in case...
                [string appendString:[self string]];
            }
        }
    }
    
    // we don't want newlines in the tableview
    static NSCharacterSet *newlineCharacterSet = nil;
    if (nil == newlineCharacterSet) {
        NSMutableCharacterSet *cs = [[NSCharacterSet whitespaceCharacterSet] mutableCopy];
        [cs invert];
        [cs formIntersectionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        newlineCharacterSet = [cs copy];
        [cs release];
    }
    NSRange r = [string rangeOfCharacterFromSet:newlineCharacterSet];
    while (r.location != NSNotFound) {
        [string deleteCharactersInRange:r];
        r = [string rangeOfCharacterFromSet:newlineCharacterSet];
    }
    // trim any leading or trailing whitespace
    CFStringTrimWhitespace((CFMutableStringRef)string);
    
    return string;
}

@end


@implementation SKNotesTableView

- (void)delete:(id)sender {
    if ([[self delegate] respondsToSelector:@selector(tableView:deleteRowsWithIndexes:)]) {
		if ([self selectedRow] == -1)
			NSBeep();
		else
			[[self delegate] tableView:self deleteRowsWithIndexes:[self selectedRowIndexes]];
    }
}

- (void)keyDown:(NSEvent *)theEvent {
    NSString *characters = [theEvent charactersIgnoringModifiers];
    unichar eventChar = [characters length] > 0 ? [characters characterAtIndex:0] : 0;
	unsigned int modifiers = [theEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask;
    
	if ((eventChar == NSDeleteCharacter || eventChar == NSDeleteFunctionKey) && modifiers == 0)
        [self delete:self];
	else
		[super keyDown:theEvent];
}

@end


@implementation SKAnnotationTypeIconTransformer

+ (Class)transformedValueClass {
    return [NSImage class];
}

+ (BOOL)allowsReverseTransformation {
    return NO;
}

- (NSImage *)transformedValue:(NSString *)type {
    if ([type isEqualToString:@"FreeText"])
        return [NSImage imageNamed:@"AnnotateToolAdorn"];
    if ([type isEqualToString:@"Note"])
        return [NSImage imageNamed:@"NoteToolAdorn"];
    if ([type isEqualToString:@"Circle"])
        return [NSImage imageNamed:@"CircleToolAdorn"];
    return nil;
}

@end


@implementation SKMiniaturizeWindow

- (id)initWithContentRect:(NSRect)contentRect image:(NSImage *)image {
    if (self = [self initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO]) {
        [self setReleasedWhenClosed:NO];
        
        NSImageView *imageView = [[NSImageView alloc] init];
        [imageView setImage:image];
        [imageView setImageFrameStyle:NSImageFrameNone];
        [self setContentView:imageView];
        [imageView release];
    }
    return self;
}

- (BOOL)canBecomeMainWindow { return NO; }

- (BOOL)canBecomeKeyWindow { return NO; }

- (NSTimeInterval)animationResizeTime:(NSRect)newWindowFrame {
    return 0.6 * [super animationResizeTime:newWindowFrame];
}

@end
