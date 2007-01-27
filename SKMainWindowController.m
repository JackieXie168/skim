//
//  SKMainWindowController.m


//  This code is licensed under a BSD license. Please see the file LICENSE for details.
//
//  Created by Michael McCracken on 12/6/06.
//  Copyright 2006 Michael O. McCracken. All rights reserved.
//

#import "SKMainWindowController.h"
#import "SKSubWindowController.h"
#import "SKNoteWindowController.h"
#import "SKInfoWindowController.h"
#import "SKNavigationWindow.h"
#import <Quartz/Quartz.h>
#import "SKDocument.h"
#import "SKNote.h"
#import "SKPDFView.h"
#import "SKCollapsibleView.h"
#import <Carbon/Carbon.h>


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
static NSString *SKDocumentToolbarToggleDrawerItemIdentifier = @"SKDocumentToolbarToggleDrawerItemIdentifier";
static NSString *SKDocumentToolbarInfoItemIdentifier = @"SKDocumentToolbarInfoItemIdentifier";
static NSString *SKDocumentToolbarToolModeItemIdentifier = @"SKDocumentToolbarToolModeItemIdentifier";
static NSString *SKDocumentToolbarDisplayBoxItemIdentifier = @"SKDocumentToolbarDisplayBoxItemIdentifier";
static NSString *SKDocumentToolbarSearchItemIdentifier = @"SKDocumentToolbarSearchItemIdentifier";

#define TOOLBAR_SEARCHFIELD_MIN_SIZE NSMakeSize(110.0, 22.0)
#define TOOLBAR_SEARCHFIELD_MAX_SIZE NSMakeSize(1000.0, 22.0)


@interface SKFullScreenWindow : NSWindow
- (id)initWithScreen:(NSScreen *)screen;
@end

@interface PDFAnnotation (SKExtensions)
@end
@implementation PDFAnnotation (SKExtensions)
- (BOOL)isTemporaryAnnotation { return NO; }
@end

@interface SKPDFAnnotationTemporary : PDFAnnotationCircle
@end

// useful for highlighting things; isTemporaryAnnotation is so we know to remove it
@implementation SKPDFAnnotationTemporary
- (BOOL)isTemporaryAnnotation { return YES; }
- (BOOL)shouldPrint { return NO; }
- (NSColor *)color { return [NSColor redColor]; }
- (NSRect)bounds {
    NSRect r = [super bounds];
    return NSInsetRect(r, -5.0f, -5.0f);
}
@end

@implementation SKMainWindowController

- (id)initWithWindowNibName:(NSString *)windowNibName owner:(id)owner{
    self = [super initWithWindowNibName:windowNibName owner:owner];
    
    if(self){
        [self setShouldCloseDocument:YES];
        isPresentation = NO;
        searchResults = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)setupDocumentNotifications{
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(handlePageChangedNotification:) 
                                                 name: PDFViewPageChangedNotification object: pdfView];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(handleScaleChangedNotification:) 
                                                 name: PDFViewScaleChangedNotification object: pdfView];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(handleChangedHistoryNotification:) 
                                                 name: PDFViewChangedHistoryNotification object: pdfView];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(handleToolModeChangedNotification:) 
                                                 name: SKPDFViewToolModeChangedNotification object: pdfView];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(handleDocumentWillSaveNotification:) 
                                                 name: SKDocumentWillSaveNotification object: [self document]];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(handleDocumentDidSaveNotification:) 
                                                 name: SKDocumentDidSaveNotification object: [self document]];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(handleAppWillTerminateNotification:) 
                                                 name: NSApplicationWillTerminateNotification object: NSApp];

	// Delegate.
	[[pdfView document] setDelegate: self];
}

- (void)dealloc {

	[[NSNotificationCenter defaultCenter] removeObserver: self];
	
	// Search clean-up.
	[searchResults release];

	if (pdfOutline)	[pdfOutline release];
	if (fullScreenWindow)	[fullScreenWindow release];
    if (mainWindow) [mainWindow release];
    
    [super dealloc];
}

- (void)windowDidLoad{
    PDFDocument *pdfDoc = [(SKDocument *)[self document] pdfDocument];
    
    pdfOutline = [[pdfDoc outlineRoot] retain];
    if (pdfOutline){

		if ([[pdfView document] isLocked] == NO){

			[outlineView reloadData];
			[outlineView setAutoresizesOutlineColumn: NO];
			
			if ([outlineView numberOfRows] == 1){
				[outlineView expandItem: [outlineView itemAtRow: 0] expandChildren: NO];
            }

			[self updateOutlineSelection];
		}
	}
    
    // we retain as we might replace it with the full screen window
    mainWindow = [[self window] retain];
    [mainWindow setFrameAutosaveName:SKMainWindowFrameAutosaveName];
    
    [searchBox setCollapseEdges:SKMaxXEdgeMask | SKMinYEdgeMask];
    [searchBox setMinSize:NSMakeSize(100.0, 46.0)];
    
    [self setupToolbar];
    [pdfView setDocument:pdfDoc];
    
    [self handleChangedHistoryNotification:nil];
    [self handleToolModeChangedNotification:nil];
    [self handlePageChangedNotification:nil];
    [self handleScaleChangedNotification:nil];
    [pageNumberStepper setMaxValue:[[pdfView document] pageCount]];
    
    [self setupDocumentNotifications];
}

- (BOOL)isFullScreen {
    return [self window] == fullScreenWindow;
}

- (BOOL)isPresentation {
    return isPresentation;
}

- (BOOL)autoScales {
    return [pdfView autoScales];
}

#pragma mark key handling

- (void)keyDown:(NSEvent *)theEvent{
    NSString *characters;
    unichar eventChar;
	unsigned int modifierFlags;
	BOOL noModifier;
	
    characters = [theEvent charactersIgnoringModifiers];
	eventChar = [characters length] > 0 ? [characters characterAtIndex:0] : 0;
	modifierFlags = [theEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask;
	noModifier = ((modifierFlags & (NSShiftKeyMask | NSControlKeyMask | NSAlternateKeyMask)) == 0);
    
    if (eventChar == NSEnterCharacter ||
        eventChar == NSFormFeedCharacter ||
        eventChar == NSNewlineCharacter ||
        eventChar == NSCarriageReturnCharacter){
        [self createNewNote:nil];
    }
    
}

#pragma mark Actions

- (IBAction)createNewNote:(id)sender{
    PDFDocument *doc = [(SKDocument *)[self document] pdfDocument];
    PDFSelection *sel = [pdfView currentSelection];

    NSLog(@"current sele:%@\nquotation:%@\ncurrent page:%@\ncurrent dest:%@", sel, [sel string], [pdfView currentPage], [pdfView currentDestination]);
    // open new note popup
    SKNote *newNote = [[SKNote alloc] initWithPageIndex:[doc indexForPage:[pdfView currentPage]]
                                              pageLabel:[[pdfView currentPage] label]
                                    locationInPageSpace:sel ? [sel boundsForPage:[pdfView currentPage]].origin : [[pdfView currentDestination] point]
                                              quotation:sel ? [sel string] : @""];
    SKNoteWindowController *noteController = [[[SKNoteWindowController alloc] initWithNote:newNote] autorelease];
    
    [noteController beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:@selector(newNoteSheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (void)newNoteSheetDidEnd:(SKNoteWindowController *)sender returnCode:(int)returnCode contextInfo:(void *)contextInfo{
    if (returnCode == NSOKButton) {
        [[(SKDocument *)[self document] mutableArrayValueForKey:@"notes"] addObject:[sender note]];
        NSRect bounds = NSMakeRect(0.0, 0.0, 50.0, 20.0);
        bounds.origin = [[sender note] locationInPageSpace];
        PDFPage *page = [[pdfView document] pageAtIndex:[[sender note] pageIndex]];
        SKPDFAnnotationTemporary *circle = [[SKPDFAnnotationTemporary alloc] initWithBounds:bounds];
        [page addAnnotation:circle];
        [circle release];
    }
}

- (void)showNotes:(NSArray *)notesToShow{
    // there should only be a single note
    SKNote *note = [notesToShow lastObject];
    
    PDFPage *page = [[pdfView document] pageAtIndex:[note pageIndex]];
    PDFDestination *dest = [[[PDFDestination alloc] initWithPage:page atPoint:[note locationInPageSpace]] autorelease];
    
    [pdfView goToDestination:dest];
    
    SKNoteWindowController *noteController = [[[SKNoteWindowController alloc] initWithNote:note] autorelease];
    
    [noteController beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:@selector(showNoteSheetDidEnd:returnCode:note:) contextInfo:[note retain]];
}

- (void)showNoteSheetDidEnd:(SKNoteWindowController *)sender returnCode:(int)returnCode note:(SKNote *)note{
    if (returnCode == NSOKButton) {
        SKNote *changedNote = [sender note];
        [note setAttributedQuotation:[changedNote attributedQuotation]];
        [note setAttributedString:[changedNote attributedString]];
    }
    [note release];
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

- (IBAction)enterFullScreen:(id)sender {
    if ([self isFullScreen])
        return;
    
    SetSystemUIMode(kUIModeAllHidden, kUIOptionAutoShowMenuBar);
    
    NSScreen *screen = [NSScreen mainScreen]; // @@ or should we use the window's screen?

    // Create the full-screen window if it doesn‚Äôt already  exist.
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
    
    [pdfView setHasNavigation:YES autohidesCursor:NO];
    isPresentation = NO;
}

- (IBAction)exitFullScreen:(id)sender {
    if ([self isFullScreen] == NO)
        return;
    
    SetSystemUIMode(kUIModeNormal, 0);

    [pdfView setHasNavigation:NO autohidesCursor:NO];
    [pdfContentBox setContentView:pdfView];
    [pdfView setBackgroundColor:[NSColor colorWithCalibratedWhite:0.5 alpha:1.0]];
    
    // Exit from presentation mode
    if (isPresentation) {
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
        
        [fullScreenWindow setLevel:NSNormalWindowLevel];
        
        isPresentation = NO;
    }
    
    [pdfView layoutDocumentView];
    
    [self setWindow:mainWindow];
    [mainWindow makeKeyAndOrderFront:self];
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
}

- (IBAction)toggleFullScreen:(id)sender {
    if ([self isFullScreen])
        [self exitFullScreen:sender];
    else
        [self enterFullScreen:sender];
}

- (IBAction)enterPresentation:(id)sender {
    if (isPresentation)
        return;
    
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
    
    [self enterFullScreen:sender];
    [fullScreenWindow setLevel:CGShieldingWindowLevel()];
    
    [pdfView setHasNavigation:YES autohidesCursor:YES];
    isPresentation = YES;
}

- (IBAction)togglePresentation:(id)sender {
    if ([self isFullScreen])
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

- (void)replaceTable:(NSTableView *)oldTableView withTable:(NSTableView *)newTableView {
    if ([newTableView window] != [self window]) {
        NSView *newTable = [newTableView enclosingScrollView];
        NSView *oldTable = [oldTableView enclosingScrollView];
        NSRect frame = [oldTable frame];
        [oldTable retain];
        
        [[oldTable superview] replaceSubview:oldTable with:newTable];
        [newTable setFrame:frame];
        
        [findCustomView addSubview:oldTable];
        [oldTable release];
        
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
}

- (void)displayOutlineView {
    [self replaceTable:tableView withTable:outlineView];
}

- (void)displaySearchView {
    [self replaceTable:outlineView withTable:tableView];
}

- (void)addAnnotationsForSelection:(PDFSelection *)sel {
    NSArray *pages = [sel pages];
    int i, iMax = [pages count];
    for (i = 0; i < iMax; i++) {
        PDFPage *page = [pages objectAtIndex:i];
        NSRect bounds = [sel boundsForPage:page];
        SKPDFAnnotationTemporary *circle = [[SKPDFAnnotationTemporary alloc] initWithBounds:bounds];
        [page addAnnotation:circle];
        [circle release];
    }
}

- (void)removeTemporaryAnnotations {
    PDFDocument *doc = [pdfView document];
    unsigned i, iMax = [doc pageCount];
    for (i = 0; i < iMax; i++) {
        PDFPage *page = [doc pageAtIndex:i];
        NSArray *annotations = [[page annotations] copy];
        unsigned j, jMax = [annotations count];
        PDFAnnotation *annote;
        for (j = 0; j < jMax; j++) {
            annote = [annotations objectAtIndex:j];
            if ([annote isTemporaryAnnotation])
                [page removeAnnotation:annote];
        }
        [annotations release];
    }
    
    // removing an annotation doesn't mark the page for redisplay; seems like a PDFPage bug
    [pdfView setNeedsDisplay:YES];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
    if ([[aNotification object] isEqual:tableView] || aNotification == nil) {
        
        // clear the selection
        [pdfView setCurrentSelection:nil];
        [self removeTemporaryAnnotations];
        
        // union all selected objects
        NSEnumerator *selE = [[findArrayController selectedObjects] objectEnumerator];
        PDFSelection *sel;
        
        // arm:  PDFSelection is mutable, and using -addSelection on an object from selectedObjects will actually mutate the object in searchResults, which does bad things.  MagicHat indicates that PDFSelection implements copyWithZone: even though it doesn't conform to <NSCopying>, so we'll use that since -init doesn't work (-initWithDocument: does, but it's not listed in the header either).  I filed rdar://problem/4888251 and also noticed that PDFKitViewer sample code uses -[PDFSelection copy].
        PDFSelection *currentSel = [[[selE nextObject] copy] autorelease];
        
        // add an annotation so it's easier to see the search result
        [self addAnnotationsForSelection:currentSel];
        
        while (sel = [selE nextObject]) {
            [self addAnnotationsForSelection:sel];
            [currentSel addSelection:sel];
        }
        
        [pdfView setCurrentSelection:currentSel];
        [pdfView scrollSelectionToVisible:self];
    }
}

- (IBAction)search:(id)sender {
    if ([[sender stringValue] isEqualToString:@""]) {
        // get rid of temporary annotations
        [self removeTemporaryAnnotations];
        [self displayOutlineView];
    } else {
        [self displaySearchView];
    }
    [[pdfView document] findString:[sender stringValue] withOptions:NSCaseInsensitiveSearch];
}

#pragma mark Sub- and note- windows

- (void)showSubWindowAtPageNumber:(int)pageNum location:(NSPoint)locationInPageSpace{
    
    SKSubWindowController *swc = [[SKSubWindowController alloc] init];
    
    PDFDocument *doc = [(SKDocument *)[self document] pdfDocument];
    [swc setPdfDocument:doc
            scaleFactor:[pdfView scaleFactor]
             autoScales:[pdfView autoScales]
         goToPageNumber:pageNum
                  point:locationInPageSpace];
    
    [[self document] addWindowController:swc];
    [swc release];
    [swc showWindow:self];
}

- (void)createNewNoteAtPageNumber:(int)pageNum location:(NSPoint)locationInPageSpace{
    NSString *selString = [[pdfView currentSelection] string];

    // open new note popup
    SKNote *newNote = [[SKNote alloc] initWithPageIndex:pageNum
                                              pageLabel:[[[pdfView document] pageAtIndex:pageNum] label]
                                    locationInPageSpace:locationInPageSpace
                                              quotation:selString ? selString : @""];
    SKNoteWindowController *noteController = [[[SKNoteWindowController alloc] initWithNote:newNote] autorelease];
    
    [noteController beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:@selector(newNoteSheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
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
    
	// Skip out if there is no outline or if the selected outline item is already on the current page
	if ([pdfDoc outlineRoot] == nil ||
        [[pdfView currentPage] isEqual:[[[outlineView itemAtRow:[outlineView selectedRow]] destination] page]])
		return;
	
	// Walk outline view looking for best firstpage number match.
	int newlySelectedRow = -1;
	int i, numRows = [outlineView numberOfRows];
    
	for (i = 0; i < numRows; i++) {
        PDFOutline *outlineItem = (PDFOutline *)[outlineView itemAtRow:i];
		unsigned int itemPageIndex = [pdfDoc indexForPage:[[outlineItem destination] page]];
		
		if (itemPageIndex == pageIndex) {
			newlySelectedRow = i;
			break;
		} else if (itemPageIndex > pageIndex) {
			newlySelectedRow = i - 1;
			break;
		}
	}
	
	if (newlySelectedRow != -1) {
        [outlineView selectRow:newlySelectedRow byExtendingSelection:NO];
		[outlineView scrollRowToVisible:newlySelectedRow];
    }
}

- (void)handleScaleChangedNotification:(NSNotification *)notification {
    [scaleField setFloatValue:[pdfView scaleFactor] * 100.0];
}

- (void)handleToolModeChangedNotification:(NSNotification *)notification {
	unsigned toolMode = [pdfView toolMode];
    
    [toolModeButton setSelectedSegment:toolMode];
}

- (void)handleDocumentWillSaveNotification:(NSNotification *)notification {
    [self removeTemporaryAnnotations];
}

- (void)handleDocumentDidSaveNotification:(NSNotification *)notification {
    if ([tableView window] == [self window]) {
        [self tableViewSelectionDidChange:nil];
    }
}

- (void)handleAppWillTerminateNotification:(NSNotification *)notification {
    if ([self isFullScreen])
        [self exitFullScreen:self];
}

#pragma mark NSOutlineView methods

- (int) outlineView: (NSOutlineView *) outlineView numberOfChildrenOfItem: (id) item{
	if (item == NULL){
		if ((pdfOutline) && ([[pdfView document] isLocked] == NO)){
			return [pdfOutline numberOfChildren];
		}else{
			return 0;
        }
	}else{
		return [(PDFOutline *)item numberOfChildren];
    }
}

- (id) outlineView: (NSOutlineView *) outlineView child: (int) index ofItem: (id) item{
	if (item == NULL){
		if ((pdfOutline) && ([[pdfView document] isLocked] == NO)){
            
			return [[pdfOutline childAtIndex: index] retain];
            
        }else{
			return NULL;
        }
	}else{
		return [[(PDFOutline *)item childAtIndex: index] retain];
    }
}


- (BOOL) outlineView: (NSOutlineView *) outlineView isItemExpandable: (id) item{
	if (item == NULL){
		if ((pdfOutline) && ([[pdfView document] isLocked] == NO)){
			return ([pdfOutline numberOfChildren] > 0);
		}else{
			return NO;
        }
	}else{
		return ([(PDFOutline *)item numberOfChildren] > 0);
    }
}


- (id) outlineView: (NSOutlineView *) outlineView objectValueForTableColumn: (NSTableColumn *) tableColumn 
            byItem: (id) item{
    
    NSString *tcID = [tableColumn identifier];
    if([tcID isEqualToString:@"label"]){
        
        return [(PDFOutline *)item label];
    }else if([tcID isEqualToString:@"icon"]){
        // check if item is in history list and return its position.
        return @"1";
    }else{
        [NSException raise:@"Unexpected tablecolumn identifier"
                    format:@" - %@ ", tcID];
    }
    return @"Shouldn't get here.";
}


- (void) outlineViewSelectionDidChange: (NSNotification *) notification{
	// Get the destination associated with the search result list. Tell the PDFView to go there.
	if (([notification object] == outlineView) && (updatingOutlineSelection == NO)){
		[pdfView goToDestination: [[outlineView itemAtRow: [outlineView selectedRow]] destination]];
    }
}


- (void) outlineViewItemDidExpand: (NSNotification *) notification{
	[self updateOutlineSelection];
}


- (void) outlineViewItemDidCollapse: (NSNotification *) notification{
	[self updateOutlineSelection];
}


- (void)updateOutlineSelection{

	PDFOutline	*outlineItem;
	unsigned int pageIndex;
	int			 numRows;
	int			 i;
	
	// Skip out if this PDF has no outline.
	if (pdfOutline == NULL)
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

#pragma mark Toolbar

- (void)setupToolbar {
    // Create a new toolbar instance, and attach it to our document window
    NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier:SKDocumentToolbarIdentifier] autorelease];
    NSToolbarItem *item;
    
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
    [item setToolTip:NSLocalizedString(@"Previous page", @"Tool tip message")];
    [item setImage:[NSImage imageNamed:@"previous"]];
    [item setTarget:self];
    [item setAction:@selector(doGoToPreviousPage:)];
    [toolbarItems setObject:item forKey:SKDocumentToolbarPreviousItemIdentifier];
    [item release];
    
    item = [[NSToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarNextItemIdentifier];
    [item setLabel:NSLocalizedString(@"Next", @"Toolbar item label")];
    [item setPaletteLabel:NSLocalizedString(@"Next", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Next page", @"Tool tip message")];
    [item setImage:[NSImage imageNamed:@"next"]];
    [item setTarget:self];
    [item setAction:@selector(doGoToNextPage:)];
    [toolbarItems setObject:item forKey:SKDocumentToolbarNextItemIdentifier];
    [item release];
    
    item = [[NSToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarBackForwardItemIdentifier];
    [item setLabel:NSLocalizedString(@"Back/Forward", @"Toolbar item label")];
    [item setPaletteLabel:NSLocalizedString(@"Back/Forward", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Back/Forward", @"Tool tip message")];
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
    [item setImage:[NSImage imageNamed:@"zoomIn"]];
    [item setTarget:self];
    [item setAction:@selector(doZoomIn:)];
    [toolbarItems setObject:item forKey:SKDocumentToolbarZoomInItemIdentifier];
    [item release];
    
    item = [[NSToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarZoomOutItemIdentifier];
    [item setLabel:NSLocalizedString(@"Zoom Out", @"Toolbar item label")];
    [item setPaletteLabel:NSLocalizedString(@"Zoom Out", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Zoom Out", @"Tool tip message")];
    [item setImage:[NSImage imageNamed:@"zoomOut"]];
    [item setTarget:self];
    [item setAction:@selector(doZoomOut:)];
    [toolbarItems setObject:item forKey:SKDocumentToolbarZoomOutItemIdentifier];
    [item release];
    
    item = [[NSToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarZoomActualItemIdentifier];
    [item setLabel:NSLocalizedString(@"Actual Size", @"Toolbar item label")];
    [item setPaletteLabel:NSLocalizedString(@"Actual Size", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Zoom To Actual Size", @"Tool tip message")];
    [item setImage:[NSImage imageNamed:@"zoomActual"]];
    [item setTarget:self];
    [item setAction:@selector(doZoomToActualSize:)];
    [toolbarItems setObject:item forKey:SKDocumentToolbarZoomActualItemIdentifier];
    [item release];
    
    item = [[NSToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarZoomAutoItemIdentifier];
    [item setLabel:NSLocalizedString(@"Auto Zoom", @"Toolbar item label")];
    [item setPaletteLabel:NSLocalizedString(@"Zoom To Fit", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Zoom To Fit", @"Tool tip message")];
    [item setImage:[NSImage imageNamed:@"zoomToFit"]];
    [item setTarget:self];
    [item setAction:@selector(doZoomToFit:)];
    [toolbarItems setObject:item forKey:SKDocumentToolbarZoomAutoItemIdentifier];
    [item release];
    
    item = [[NSToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarRotateRightItemIdentifier];
    [item setLabel:NSLocalizedString(@"Rotate Right", @"Toolbar item label")];
    [item setPaletteLabel:NSLocalizedString(@"Rotate Right", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Rotate Right", @"Tool tip message")];
    [item setImage:[NSImage imageNamed:@"rotateRight"]];
    [item setTarget:self];
    [item setAction:@selector(rotateAllRight:)];
    [toolbarItems setObject:item forKey:SKDocumentToolbarRotateRightItemIdentifier];
    [item release];
    
    item = [[NSToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarRotateLeftItemIdentifier];
    [item setLabel:NSLocalizedString(@"Rotate Left", @"Toolbar item label")];
    [item setPaletteLabel:NSLocalizedString(@"Rotate Left", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Rotate Left", @"Tool tip message")];
    [item setImage:[NSImage imageNamed:@"rotateLeft"]];
    [item setTarget:self];
    [item setAction:@selector(rotateAllLeft:)];
    [toolbarItems setObject:item forKey:SKDocumentToolbarRotateLeftItemIdentifier];
    [item release];
    
    item = [[NSToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarFullScreenItemIdentifier];
    [item setLabel:NSLocalizedString(@"Full Screen", @"Toolbar item label")];
    [item setPaletteLabel:NSLocalizedString(@"Full Screen", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Full Screen", @"Tool tip message")];
    [item setImage:[NSImage imageNamed:@"fullScreen"]];
    [item setTarget:self];
    [item setAction:@selector(enterFullScreen:)];
    [toolbarItems setObject:item forKey:SKDocumentToolbarFullScreenItemIdentifier];
    [item release];
    
    item = [[NSToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarPresentationItemIdentifier];
    [item setLabel:NSLocalizedString(@"Presentation", @"Toolbar item label")];
    [item setPaletteLabel:NSLocalizedString(@"Presentation", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Presentation", @"Tool tip message")];
    [item setImage:[NSImage imageNamed:@"fullScreen"]];
    [item setTarget:self];
    [item setAction:@selector(enterPresentation:)];
    [toolbarItems setObject:item forKey:SKDocumentToolbarPresentationItemIdentifier];
    [item release];
    
    item = [[NSToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarToggleDrawerItemIdentifier];
    [item setLabel:NSLocalizedString(@"Drawer", @"Toolbar item label")];
    [item setPaletteLabel:NSLocalizedString(@"Drawer", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Toggle Drawer", @"Tool tip message")];
    [item setImage:[NSImage imageNamed:@"notesDrawer"]];
    [item setTarget:self];
    [item setAction:@selector(toggleNotesDrawer:)];
    [toolbarItems setObject:item forKey:SKDocumentToolbarToggleDrawerItemIdentifier];
    [item release];
    
    item = [[NSToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarToolModeItemIdentifier];
    [item setLabel:NSLocalizedString(@"Tool Mode", @"Toolbar item label")];
    [item setPaletteLabel:NSLocalizedString(@"Tool Mode", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Tool Mode", @"Tool tip message")];
    [item setView:toolModeButton];
    [item setMinSize:[toolModeButton bounds].size];
    [item setMaxSize:[toolModeButton bounds].size];
    [toolbarItems setObject:item forKey:SKDocumentToolbarToolModeItemIdentifier];
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
    [item setToolTip:NSLocalizedString(@"Info", @"Tool tip message")];
    [item setImage:[NSImage imageNamed:@"info"]];
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
        SKDocumentToolbarToggleDrawerItemIdentifier, 
        SKDocumentToolbarInfoItemIdentifier, 
        SKDocumentToolbarToolModeItemIdentifier, 
        SKDocumentToolbarDisplayBoxItemIdentifier, 
        SKDocumentToolbarSearchItemIdentifier, 
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

@end


@implementation SKFullScreenWindow

- (id)initWithScreen:(NSScreen *)screen {
    if (self = [[SKFullScreenWindow alloc] initWithContentRect:[screen frame] styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO screen:screen]) {
        [self setReleasedWhenClosed:NO];
        [self setDisplaysWhenScreenProfileChanges:YES];
        [self setLevel:CGShieldingWindowLevel()];
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


