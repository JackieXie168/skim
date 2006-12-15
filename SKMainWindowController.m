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
#import <Quartz/Quartz.h>
#import "SKDocument.h"
#import "SKNote.h"
#import "SKPDFView.h"


static NSString *SKDocumentToolbarIdentifier = @"SKDocumentToolbarIdentifier";

static NSString *SKDocumentToolbarPreviousItemIdentifier = @"SKDocumentPreviousToolbarItemIdentifier";
static NSString *SKDocumentToolbarNextItemIdentifier = @"SKDocumentNextToolbarItemIdentifier";
static NSString *SKDocumentToolbarBackForwardItemIdentifier = @"SKDocumentToolbarBackForwardItemIdentifier";
static NSString *SKDocumentToolbarPageNumberItemIdentifier = @"SKDocumentToolbarPageNumberItemIdentifier";
static NSString *SKDocumentToolbarZoomInItemIdentifier = @"SKDocumentZoomInToolbarItemIdentifier";
static NSString *SKDocumentToolbarZoomOutItemIdentifier = @"SKDocumentZoomOutToolbarItemIdentifier";
static NSString *SKDocumentToolbarZoomActualItemIdentifier = @"SKDocumentZoomActualToolbarItemIdentifier";
static NSString *SKDocumentToolbarZoomAutoItemIdentifier = @"SKDocumentZoomAutoToolbarItemIdentifier";
static NSString *SKDocumentToolbarRotateRightItemIdentifier = @"SKDocumentRotateRightToolbarItemIdentifier";
static NSString *SKDocumentToolbarRotateLeftItemIdentifier = @"SKDocumentRotateLeftToolbarItemIdentifier";
static NSString *SKDocumentToolbarFullScreenItemIdentifier = @"SKDocumentFullScreenToolbarItemIdentifier";
static NSString *SKDocumentToolbarToggleDrawerItemIdentifier = @"SKDocumentToolbarToggleDrawerItemIdentifier";
static NSString *SKDocumentToolbarInfoItemIdentifier = @"SKDocumentToolbarInfoItemIdentifier";
static NSString *SKDocumentToolbarToolModeItemIdentifier = @"SKDocumentToolbarToolModeItemIdentifier";
static NSString *SKDocumentToolbarSearchItemIdentifier = @"SKDocumentToolbarSearchItemIdentifier";


#define TOOLBAR_SEARCHFIELD_MIN_SIZE NSMakeSize(110.0, 22.0)
#define TOOLBAR_SEARCHFIELD_MAX_SIZE NSMakeSize(1000.0, 22.0)

@implementation SKMainWindowController

- (id)initWithWindowNibName:(NSString *)windowNibName owner:(id)owner{
    self = [super initWithWindowNibName:windowNibName owner:owner];
    
    if(self){
        [self setShouldCloseDocument:YES];
    }
    
    return self;
}

- (void)setupDocumentNotifications{
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(handlePageChangedNotification:) 
                                                 name: PDFViewPageChangedNotification object: pdfView];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(handleChangedHistoryNotification:) 
                                                 name: PDFViewChangedHistoryNotification object: pdfView];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(handleToolModeChangedNotification:) 
                                                 name: @"SKPDFViewToolModeChangedNotification" object: pdfView];
    
/*	// Find notifications.
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(startFind:) 
                                                 name: PDFDocumentDidBeginFindNotification object: [pdfView document]];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(endFind:) 
                                                 name: PDFDocumentDidEndFindNotification object: [pdfView document]];
*/	

	// Delegate.
	[[pdfView document] setDelegate: self];
}


- (void) dealloc{

	[[NSNotificationCenter defaultCenter] removeObserver: self];
	
/*	// Remove back-forward toolbar item.
	if (_toolbarBackForwardItem)
	{
		[_toolbarBackForwardItem release];
		[_backForwardView release];
	}
	
	// Remove page number toolbar item.
	if (_toolbarPageNumberItem)
	{
		[_toolbarPageNumberItem release];
		[_pageNumberView release];
	}
    
	// Remove page number toolbar item.
	if (_toolbarViewModeItem)
	{
		[_toolbarViewModeItem release];
		[_viewModeView release];
	}
    
	// Remove search toolbar item.
	if (_toolbarSearchFieldItem)
	{
		[_toolbarSearchFieldItem release];
		[_searchFieldView release];
	}
    
	// Remove back-forward toolbar item.
	if (_toolbarEditTestItem)
	{
		[_toolbarEditTestItem release];
		[_editTestView release];
	}
	
	// Search clean-up.
	[_searchResults release];
	[_sampleStrings release];
*/	
	if (pdfOutline)	[pdfOutline release];
	
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
    
    [self setupToolbar];
    [pdfView setDocument:pdfDoc];
    
    [self handleChangedHistoryNotification:nil];
    [self handleToolModeChangedNotification:nil];
    [self handlePageChangedNotification:nil];
    [pageNumberStepper setMaxValue:[[pdfView document] pageCount]];
    
    [self setupDocumentNotifications];
}

#pragma mark key handling

- (void)keyDown:(NSEvent *)theEvent{
    
    unichar			eventChar;
	unsigned int	modifierFlags;
	BOOL			noModifier;
	
	eventChar = [[theEvent charactersIgnoringModifiers] characterAtIndex: 0];
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

- (IBAction)goToNextPage:(id)sender {
    [pdfView goToNextPage:sender];
}

- (IBAction)goToPreviousPage:(id)sender {
    [pdfView goToPreviousPage:sender];
}

- (IBAction)goBackOrForward:(id)sender {
    if ([sender selectedSegment] == 1)
        [pdfView goForward:sender];
    else
        [pdfView goBack:sender];
}

- (IBAction)zoomIn:(id)sender {
    [pdfView zoomIn:sender];
}

- (IBAction)zoomOut:(id)sender {
    [pdfView zoomOut:sender];
}

- (IBAction)zoomToActualSize:(id)sender {
    [pdfView setScaleFactor:1.0];
}

- (IBAction)zoomToFit:(id)sender {
    [pdfView setAutoScales:YES];
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

- (IBAction)fullScreen:(id)sender {
    // this should open a full screen window
}

- (IBAction)toggleNotesDrawer:(id)sender {
    [notesDrawer toggle:sender];
}

- (IBAction)getInfo:(id)sender {
    // this should show a window with pdf document info
}

- (IBAction)search:(id)sender {
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

- (IBAction)changeToolMode:(id)sender {
    SKToolMode toolMode = [sender isKindOfClass:[NSSegmentedControl class]] ? [sender selectedSegment] : [sender tag];
    
    [pdfView setToolMode:toolMode];
}

- (IBAction)printDocument:(id)sender{
    [pdfView printWithInfo:[[self document] printInfo] autoRotate:NO];
}

- (void)showSubWindowAtPageNumber:(int)pageNum location:(NSPoint)locationInPageSpace{
    
    SKSubWindowController *swc = [[SKSubWindowController alloc] init];
    
    PDFDocument *doc = [(SKDocument *)[self document] pdfDocument];
    [swc setPdfDocument:doc
            scaleFactor:[pdfView scaleFactor]
             autoScales:[pdfView autoScales]];
    [swc goToPageNumber:pageNum point:locationInPageSpace];
    
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
	unsigned page = [[pdfView document] indexForPage:[pdfView currentPage]] + 1;
    
    [pageNumberStepper setIntValue:page];
    [pageNumberField setIntValue:page];
}

- (void)handleToolModeChangedNotification:(NSNotification *)notification {
	unsigned toolMode = [pdfView toolMode];
    
    [toolModeButton setSelectedSegment:toolMode];
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
	int			pageIndex;
	int			numRows;
	int			i;
	
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
    [item setAction:@selector(goToPreviousPage:)];
    [toolbarItems setObject:item forKey:SKDocumentToolbarPreviousItemIdentifier];
    [item release];
    
    item = [[NSToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarNextItemIdentifier];
    [item setLabel:NSLocalizedString(@"Next", @"Toolbar item label")];
    [item setPaletteLabel:NSLocalizedString(@"Next", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Next page", @"Tool tip message")];
    [item setImage:[NSImage imageNamed:@"next"]];
    [item setTarget:self];
    [item setAction:@selector(goToNextPage:)];
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
    
    item = [[NSToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarZoomInItemIdentifier];
    [item setLabel:NSLocalizedString(@"Zoom In", @"Toolbar item label")];
    [item setPaletteLabel:NSLocalizedString(@"Zoom In", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Zoom In", @"Tool tip message")];
    [item setImage:[NSImage imageNamed:@"zoomIn"]];
    [item setTarget:self];
    [item setAction:@selector(zoomIn:)];
    [toolbarItems setObject:item forKey:SKDocumentToolbarZoomInItemIdentifier];
    [item release];
    
    item = [[NSToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarZoomOutItemIdentifier];
    [item setLabel:NSLocalizedString(@"Zoom Out", @"Toolbar item label")];
    [item setPaletteLabel:NSLocalizedString(@"Zoom Out", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Zoom Out", @"Tool tip message")];
    [item setImage:[NSImage imageNamed:@"zoomOut"]];
    [item setTarget:self];
    [item setAction:@selector(zoomOut:)];
    [toolbarItems setObject:item forKey:SKDocumentToolbarZoomOutItemIdentifier];
    [item release];
    
    item = [[NSToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarZoomActualItemIdentifier];
    [item setLabel:NSLocalizedString(@"Actual Size", @"Toolbar item label")];
    [item setPaletteLabel:NSLocalizedString(@"Actual Size", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Zoom To Actual Size", @"Tool tip message")];
    [item setImage:[NSImage imageNamed:@"zoomActual"]];
    [item setTarget:self];
    [item setAction:@selector(zoomToActualSize:)];
    [toolbarItems setObject:item forKey:SKDocumentToolbarZoomActualItemIdentifier];
    [item release];
    
    item = [[NSToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarZoomAutoItemIdentifier];
    [item setLabel:NSLocalizedString(@"Auto Zoom", @"Toolbar item label")];
    [item setPaletteLabel:NSLocalizedString(@"Zoom To Fit", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Zoom To Fit", @"Tool tip message")];
    [item setImage:[NSImage imageNamed:@"zoomToFit"]];
    [item setTarget:self];
    [item setAction:@selector(zoomToFit:)];
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
    [item setAction:@selector(fullScreen:)];
    [toolbarItems setObject:item forKey:SKDocumentToolbarFullScreenItemIdentifier];
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
        SKDocumentToolbarZoomInItemIdentifier, 
        SKDocumentToolbarZoomOutItemIdentifier, 
        SKDocumentToolbarZoomActualItemIdentifier, 
        SKDocumentToolbarZoomAutoItemIdentifier, 
        SKDocumentToolbarRotateRightItemIdentifier, 
        SKDocumentToolbarRotateLeftItemIdentifier, 
        SKDocumentToolbarFullScreenItemIdentifier, 
        SKDocumentToolbarToggleDrawerItemIdentifier, 
        SKDocumentToolbarInfoItemIdentifier, 
        SKDocumentToolbarToolModeItemIdentifier, 
        SKDocumentToolbarSearchItemIdentifier, 
		NSToolbarPrintItemIdentifier,
		NSToolbarFlexibleSpaceItemIdentifier, 
		NSToolbarSpaceItemIdentifier, 
		NSToolbarSeparatorItemIdentifier, 
		NSToolbarCustomizeToolbarItemIdentifier, nil];
}

- (BOOL)validateToolbarItem:(NSToolbarItem *) toolbarItem {
    // Optional method   self message is sent to us since we are the target of some toolbar item actions
    // (for example:  of the save items action)
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
        return [pdfView scaleFactor] != 1.0;
    } else if ([identifier isEqualToString:SKDocumentToolbarFullScreenItemIdentifier]) {
        return NO;
    } else if ([identifier isEqualToString:SKDocumentToolbarInfoItemIdentifier]) {
        return NO;
    } else {
        return YES;
    }
}

@end
