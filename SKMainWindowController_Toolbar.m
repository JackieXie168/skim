//
//  SKMainWindowController_Toolbar.m
//  Skim
//
//  Created by Christiaan Hofman on 4/2/08.
/*
 This software is Copyright (c) 2008
 Christiaan Hofman. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

 - Neither the name of Christiaan Hofman nor the names of any
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

#import "SKMainWindowController_Toolbar.h"
#import "SKToolbarItem.h"
#import "NSSegmentedControl_SKExtensions.h"
#import "SKStringConstants.h"
#import "SKPDFView.h"
#import "SKColorSwatch.h"
#import "SKUnarchiveFromDataArrayTransformer.h"
#import "SKApplicationController.h"
#import "NSImage_SKExtensions.h"
#import "NSMenu_SKExtensions.h"

static NSString *SKDocumentToolbarIdentifier = @"SKDocumentToolbar";

static NSString *SKDocumentToolbarPreviousItemIdentifier = @"SKDocumentToolbarPreviousItemIdentifier";
static NSString *SKDocumentToolbarNextItemIdentifier = @"SKDocumentToolbarNextItemIdentifier";
static NSString *SKDocumentToolbarPreviousNextItemIdentifier = @"SKDocumentToolbarPreviousNextItemIdentifier";
static NSString *SKDocumentToolbarPreviousNextFirstLastItemIdentifier = @"SKDocumentToolbarPreviousNextFirstLastItemIdentifier";
static NSString *SKDocumentToolbarBackForwardItemIdentifier = @"SKDocumentToolbarBackForwardItemIdentifier";
static NSString *SKDocumentToolbarPageNumberItemIdentifier = @"SKDocumentToolbarPageNumberItemIdentifier";
static NSString *SKDocumentToolbarScaleItemIdentifier = @"SKDocumentToolbarScaleItemIdentifier";
static NSString *SKDocumentToolbarZoomActualItemIdentifier = @"SKDocumentToolbarZoomActualItemIdentifier";
static NSString *SKDocumentToolbarZoomToSelectionItemIdentifier = @"SKDocumentToolbarZoomToSelectionItemIdentifier";
static NSString *SKDocumentToolbarZoomToFitItemIdentifier = @"SKDocumentToolbarZoomToFitItemIdentifier";
static NSString *SKDocumentToolbarZoomInOutItemIdentifier = @"SKDocumentToolbarZoomInOutItemIdentifier";
static NSString *SKDocumentToolbarZoomInActualOutItemIdentifier = @"SKDocumentToolbarZoomInActualOutItemIdentifier";
static NSString *SKDocumentToolbarRotateRightItemIdentifier = @"SKDocumentToolbarRotateRightItemIdentifier";
static NSString *SKDocumentToolbarRotateLeftItemIdentifier = @"SKDocumentToolbarRotateLeftItemIdentifier";
static NSString *SKDocumentToolbarRotateLeftRightItemIdentifier = @"SKDocumentToolbarRotateLeftRightItemIdentifier";
static NSString *SKDocumentToolbarCropItemIdentifier = @"SKDocumentToolbarCropItemIdentifier";
static NSString *SKDocumentToolbarFullScreenItemIdentifier = @"SKDocumentToolbarFullScreenItemIdentifier";
static NSString *SKDocumentToolbarPresentationItemIdentifier = @"SKDocumentToolbarPresentationItemIdentifier";
static NSString *SKDocumentToolbarNewTextNoteItemIdentifier = @"SKDocumentToolbarNewTextNoteItemIdentifier";
static NSString *SKDocumentToolbarNewCircleNoteItemIdentifier = @"SKDocumentToolbarNewCircleNoteItemIdentifier";
static NSString *SKDocumentToolbarNewMarkupItemIdentifier = @"SKDocumentToolbarNewMarkupItemIdentifier";
static NSString *SKDocumentToolbarNewLineItemIdentifier = @"SKDocumentToolbarNewLineItemIdentifier";
static NSString *SKDocumentToolbarNewNoteItemIdentifier = @"SKDocumentToolbarNewNoteItemIdentifier";
static NSString *SKDocumentToolbarInfoItemIdentifier = @"SKDocumentToolbarInfoItemIdentifier";
static NSString *SKDocumentToolbarToolModeItemIdentifier = @"SKDocumentToolbarToolModeItemIdentifier";
static NSString *SKDocumentToolbarSingleTwoUpItemIdentifier = @"SKDocumentToolbarSingleTwoUpItemIdentifier";
static NSString *SKDocumentToolbarContinuousItemIdentifier = @"SKDocumentToolbarContinuousItemIdentifier";
static NSString *SKDocumentToolbarDisplayModeItemIdentifier = @"SKDocumentToolbarDisplayModeItemIdentifier";
static NSString *SKDocumentToolbarDisplayBoxItemIdentifier = @"SKDocumentToolbarDisplayBoxItemIdentifier";
static NSString *SKDocumentToolbarColorSwatchItemIdentifier = @"SKDocumentToolbarColorSwatchItemIdentifier";
static NSString *SKDocumentToolbarColorsItemIdentifier = @"SKDocumentToolbarColorsItemIdentifier";
static NSString *SKDocumentToolbarFontsItemIdentifier = @"SKDocumentToolbarFontsItemIdentifier";
static NSString *SKDocumentToolbarLinesItemIdentifier = @"SKDocumentToolbarLinesItemIdentifier";
static NSString *SKDocumentToolbarContentsPaneItemIdentifier = @"SKDocumentToolbarContentsPaneItemIdentifier";
static NSString *SKDocumentToolbarNotesPaneItemIdentifier = @"SKDocumentToolbarNotesPaneItemIdentifier";
static NSString *SKDocumentToolbarPrintItemIdentifier = @"SKDocumentToolbarPrintItemIdentifier";
static NSString *SKDocumentToolbarCustomizeItemIdentifier = @"SKDocumentToolbarCustomizeItemIdentifier";


@interface SKMainWindowController (TSKoolbarPrivate)
- (void)handleColorSwatchColorsChangedNotification:(NSNotification *)notification;
@end


@implementation SKMainWindowController (SKToolbar)

- (void)setupToolbar {
    // Create a new toolbar instance, and attach it to our document window
    NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier:SKDocumentToolbarIdentifier] autorelease];
    
    // Set up toolbar properties: Allow customization, give a default display mode, and remember state in user defaults
    [toolbar setAllowsUserCustomization:YES];
    [toolbar setAutosavesConfiguration:YES];
    [toolbar setDisplayMode:NSToolbarDisplayModeDefault];
    
    // We are the delegate
    [toolbar setDelegate:self];
    
    // Attach the toolbar to the window
    [[self window] setToolbar:toolbar];
}

- (NSToolbarItem *)toolbarItemForItemIdentifier:(NSString *)identifier {
    SKToolbarItem *item = [toolbarItems objectForKey:identifier];
    NSMenu *menu;
    NSMenuItem *menuItem;
    
    if (item == nil) {
        
        if (toolbarItems == nil)
            toolbarItems = [[NSMutableDictionary alloc] init];

        item = [[[SKToolbarItem alloc] initWithItemIdentifier:identifier] autorelease];
        [toolbarItems setObject:item forKey:identifier];
    
        if ([identifier isEqualToString:SKDocumentToolbarPreviousNextItemIdentifier]) {
            
            menu = [NSMenu menu];
            [menu addItemWithTitle:NSLocalizedString(@"Previous", @"Menu item title") action:@selector(doGoToPreviousPage:) target:self];
            [menu addItemWithTitle:NSLocalizedString(@"Next", @"Menu item title") action:@selector(doGoToNextPage:) target:self];
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Previous/Next", @"Toolbar item label") submenu:menu] autorelease];
            
            [item setLabels:NSLocalizedString(@"Previous/Next", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Previous/Next", @"Tool tip message")];
            [previousNextPageButton setToolTip:NSLocalizedString(@"Go To Previous Page", @"Tool tip message") forSegment:0];
            [previousNextPageButton setToolTip:NSLocalizedString(@"Go To Next Page", @"Tool tip message") forSegment:1];
            [item setSegmentedControl:previousNextPageButton];
            [item setMenuFormRepresentation:menuItem];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarPreviousItemIdentifier]) {
            
            menu = [NSMenu menu];
            [menu addItemWithTitle:NSLocalizedString(@"Previous", @"Menu item title") action:@selector(doGoToPreviousPage:) target:self];
            menuItem = [menu addItemWithTitle:NSLocalizedString(@"First", @"Menu item title") action:@selector(doGoToFirstPage:) target:self];
            
            [item setLabels:NSLocalizedString(@"Previous", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Go To Previous Page", @"Tool tip message")];
            [previousPageButton setToolTip:NSLocalizedString(@"Go To First page", @"Tool tip message") forSegment:0];
            [previousPageButton setToolTip:NSLocalizedString(@"Go To Previous Page", @"Tool tip message") forSegment:1];
            [item setSegmentedControl:previousPageButton];
            [item setMenuFormRepresentation:menuItem];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarNextItemIdentifier]) {
            
            menu = [NSMenu menu];
            [menu addItemWithTitle:NSLocalizedString(@"Next", @"Menu item title") action:@selector(doGoToNextPage:) target:self];
            [menu addItemWithTitle:NSLocalizedString(@"Last", @"Menu item title") action:@selector(doGoToLastPage:) target:self];
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Page", @"Toolbar item label") submenu:menu] autorelease];
            
            [item setLabels:NSLocalizedString(@"Next", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Go To Next Page", @"Tool tip message")];
            [nextPageButton setToolTip:NSLocalizedString(@"Go To Next Page", @"Tool tip message") forSegment:0];
            [nextPageButton setToolTip:NSLocalizedString(@"Go To Last page", @"Tool tip message") forSegment:1];
            [item setSegmentedControl:nextPageButton];
            [item setMenuFormRepresentation:menuItem];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarPreviousNextFirstLastItemIdentifier]) {
            
            menu = [NSMenu menu];
            [menu addItemWithTitle:NSLocalizedString(@"Previous", @"Menu item title") action:@selector(doGoToPreviousPage:) target:self];
            [menu addItemWithTitle:NSLocalizedString(@"Next", @"Menu item title") action:@selector(doGoToNextPage:) target:self];
            [menu addItemWithTitle:NSLocalizedString(@"First", @"Menu item title") action:@selector(doGoToFirstPage:) target:self];
            [menu addItemWithTitle:NSLocalizedString(@"Last", @"Menu item title") action:@selector(doGoToLastPage:) target:self];
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Previous/Next", @"Toolbar item label") submenu:menu] autorelease];
            
            [item setLabels:NSLocalizedString(@"Previous/Next", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Go To First, Previous, Next or Last Page", @"Tool tip message")];
            [previousNextFirstLastPageButton setToolTip:NSLocalizedString(@"Go To First page", @"Tool tip message") forSegment:0];
            [previousNextFirstLastPageButton setToolTip:NSLocalizedString(@"Go To Previous Page", @"Tool tip message") forSegment:1];
            [previousNextFirstLastPageButton setToolTip:NSLocalizedString(@"Go To Next Page", @"Tool tip message") forSegment:2];
            [previousNextFirstLastPageButton setToolTip:NSLocalizedString(@"Go To Last page", @"Tool tip message") forSegment:3];
            [item setSegmentedControl:previousNextFirstLastPageButton];
            [item setMenuFormRepresentation:menuItem];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarBackForwardItemIdentifier]) {
            
            menu = [NSMenu menu];
            [menu addItemWithTitle:NSLocalizedString(@"Back", @"Menu item title") action:@selector(doGoBack:) target:self];
            [menu addItemWithTitle:NSLocalizedString(@"Forward", @"Menu item title") action:@selector(doGoForward:) target:self];
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Back/Forward", @"Toolbar item label") submenu:menu] autorelease];
            
            [item setLabels:NSLocalizedString(@"Back/Forward", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Back/Forward", @"Tool tip message")];
            [backForwardButton setToolTip:NSLocalizedString(@"Go Back", @"Tool tip message") forSegment:0];
            [backForwardButton setToolTip:NSLocalizedString(@"Go Forward", @"Tool tip message") forSegment:1];
            [item setSegmentedControl:backForwardButton];
            [item setMenuFormRepresentation:menuItem];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarPageNumberItemIdentifier]) {
            
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Page", @"Menu item title") action:@selector(doGoToPage:) target:self] autorelease];
            
            [item setLabels:NSLocalizedString(@"Page", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Go To Page", @"Tool tip message")];
            [item setViewWithSizes:pageNumberField];
            [item setMenuFormRepresentation:menuItem];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarScaleItemIdentifier]) {
            
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Scale", @"Menu item title") action:@selector(chooseScale:) target:self] autorelease];
            
            [item setLabels:NSLocalizedString(@"Scale", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Scale", @"Tool tip message")];
            [item setViewWithSizes:scaleField];
            [item setMenuFormRepresentation:menuItem];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarZoomActualItemIdentifier]) {
            
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Actual Size", @"Menu item title") action:@selector(doZoomToActualSize:) target:self] autorelease];
            
            [item setLabels:NSLocalizedString(@"Actual Size", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Zoom To Actual Size", @"Tool tip message")];
            [item setSegmentedControl:zoomActualButton];
            [item setMenuFormRepresentation:menuItem];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarZoomToFitItemIdentifier]) {
            
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Zoom To Fit", @"Menu item title") action:@selector(doZoomToFit:) target:self] autorelease];
            
            [item setLabels:NSLocalizedString(@"Zoom To Fit", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Zoom To Fit", @"Tool tip message")];
            [item setSegmentedControl:zoomFitButton];
            [item setMenuFormRepresentation:menuItem];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarZoomToSelectionItemIdentifier]) {
            
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Zoom To Selection", @"Menu item title") action:@selector(doZoomToSelection:) target:self] autorelease];
            
            [item setLabels:NSLocalizedString(@"Zoom To Selection", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Zoom To Selection", @"Tool tip message")];
            [item setSegmentedControl:zoomSelectionButton];
            [item setMenuFormRepresentation:menuItem];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarZoomInOutItemIdentifier]) {
            
            menu = [NSMenu menu];
            [menu addItemWithTitle:NSLocalizedString(@"Zoom In", @"Menu item title") action:@selector(doZoomIn:) target:self];
            [menu addItemWithTitle:NSLocalizedString(@"Zoom Out", @"Menu item title") action:@selector(doZoomOut:) target:self];
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Zoom", @"Toolbar item label") submenu:menu] autorelease];
            
            [item setLabels:NSLocalizedString(@"Zoom", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Zoom", @"Tool tip message")];
            [zoomInOutButton setToolTip:NSLocalizedString(@"Zoom Out", @"Tool tip message") forSegment:0];
            [zoomInOutButton setToolTip:NSLocalizedString(@"Zoom In", @"Tool tip message") forSegment:1];
            [item setSegmentedControl:zoomInOutButton];
            [item setMenuFormRepresentation:menuItem];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarZoomInActualOutItemIdentifier]) {
            
            menu = [NSMenu menu];
            [menu addItemWithTitle:NSLocalizedString(@"Zoom In", @"Menu item title") action:@selector(doZoomIn:) target:self];
            [menu addItemWithTitle:NSLocalizedString(@"Zoom Out", @"Menu item title") action:@selector(doZoomOut:) target:self];
            [menu addItemWithTitle:NSLocalizedString(@"Actual Size", @"Menu item title") action:@selector(doZoomToActualSize:) target:self];
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Zoom", @"Toolbar item label") submenu:menu] autorelease];
            
            [item setLabels:NSLocalizedString(@"Zoom", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Zoom", @"Tool tip message")];
            [zoomInActualOutButton setToolTip:NSLocalizedString(@"Zoom Out", @"Tool tip message") forSegment:0];
            [zoomInActualOutButton setToolTip:NSLocalizedString(@"Zoom To Actual Size", @"Tool tip message") forSegment:1];
            [zoomInActualOutButton setToolTip:NSLocalizedString(@"Zoom In", @"Tool tip message") forSegment:2];
            [item setSegmentedControl:zoomInActualOutButton];
            [item setMenuFormRepresentation:menuItem];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarRotateRightItemIdentifier]) {
            
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Rotate Right", @"Menu item title") action:@selector(rotateAllRight:) target:self] autorelease];
            
            [item setLabels:NSLocalizedString(@"Rotate Right", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Rotate Right", @"Tool tip message")];
            [item setSegmentedControl:rotateRightButton];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarRotateLeftItemIdentifier]) {
            
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Rotate Left", @"Menu item title") action:@selector(rotateAllLeft:) target:self] autorelease];
            
            [item setLabels:NSLocalizedString(@"Rotate Left", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Rotate Left", @"Tool tip message")];
            [item setSegmentedControl:rotateLeftButton];
            [item setMenuFormRepresentation:menuItem];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarRotateLeftRightItemIdentifier]) {
            
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Rotate Left", @"Menu item title") action:@selector(rotateAllLeft:) target:self] autorelease];
            
            [item setLabels:NSLocalizedString(@"Rotate", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Rotate Left or Right", @"Tool tip message")];
            [item setSegmentedControl:rotateLeftRightButton];
            [item setMenuFormRepresentation:menuItem];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarCropItemIdentifier]) {
            
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Crop", @"Menu item title") action:@selector(cropAll:) target:self] autorelease];
            
            [item setLabels:NSLocalizedString(@"Crop", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Crop", @"Tool tip message")];
            [item setSegmentedControl:cropButton];
            [item setMenuFormRepresentation:menuItem];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarFullScreenItemIdentifier]) {
            
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Full Screen", @"Menu item title") action:@selector(enterFullScreen:) target:self] autorelease];
            
            [item setLabels:NSLocalizedString(@"Full Screen", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Full Screen", @"Tool tip message")];
            [item setSegmentedControl:fullScreenButton];
            [item setMenuFormRepresentation:menuItem];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarPresentationItemIdentifier]) {
            
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Presentation", @"Menu item title") action:@selector(enterPresentation:) target:self] autorelease];
            
            [item setLabels:NSLocalizedString(@"Presentation", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Presentation", @"Tool tip message")];
            [item setSegmentedControl:presentationButton];
            [item setMenuFormRepresentation:menuItem];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarNewTextNoteItemIdentifier]) {
            
            menu = [NSMenu menu];
            [menu addItemWithTitle:NSLocalizedString(@"Text Note", @"Menu item title") imageNamed:SKImageNameToolbarAddTextNote action:@selector(createNewTextNote:) target:self tag:SKFreeTextNote];
            [menu addItemWithTitle:NSLocalizedString(@"Anchored Note", @"Menu item title") imageNamed:SKImageNameToolbarAddAnchoredNote action:@selector(createNewTextNote:) target:self tag:SKAnchoredNote];
            [textNoteButton setMenu:menu forSegment:0];
            
            menu = [NSMenu menu];
            [menu addItemWithTitle:NSLocalizedString(@"Text Note", @"Menu item title") imageNamed:SKImageNameToolbarAddTextNote action:@selector(createNewNote:) target:self tag:SKFreeTextNote];
            [menu addItemWithTitle:NSLocalizedString(@"Anchored Note", @"Menu item title") imageNamed:SKImageNameToolbarAddAnchoredNote action:@selector(createNewNote:) target:self tag:SKAnchoredNote];
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Add Note", @"Toolbar item label") submenu:menu] autorelease];
            
            [item setLabels:NSLocalizedString(@"Add Note", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Add New Note", @"Tool tip message")];
            [item setSegmentedControl:textNoteButton];
            [item setMenuFormRepresentation:menuItem];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarNewCircleNoteItemIdentifier]) {
            
            menu = [NSMenu menu];
            [menu addItemWithTitle:NSLocalizedString(@"Circle", @"Menu item title") imageNamed:SKImageNameToolbarAddCircleNote action:@selector(createNewCircleNote:) target:self tag:SKCircleNote];
            [menu addItemWithTitle:NSLocalizedString(@"Box", @"Menu item title") imageNamed:SKImageNameToolbarAddSquareNote action:@selector(createNewCircleNote:) target:self tag:SKSquareNote];
            [circleNoteButton setMenu:menu forSegment:0];
            
            menu = [NSMenu menu];
            [menu addItemWithTitle:NSLocalizedString(@"Circle", @"Menu item title") imageNamed:SKImageNameToolbarAddCircleNote action:@selector(createNewNote:) target:self tag:SKCircleNote];
            [menu addItemWithTitle:NSLocalizedString(@"Box", @"Menu item title") imageNamed:SKImageNameToolbarAddSquareNote action:@selector(createNewNote:) target:self tag:SKSquareNote];
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Add Shape", @"Toolbar item label") submenu:menu] autorelease];
            
            [item setLabels:NSLocalizedString(@"Add Shape", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Add New Circle or Box", @"Tool tip message")];
            [item setSegmentedControl:circleNoteButton];
            [item setMenuFormRepresentation:menuItem];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarNewMarkupItemIdentifier]) {
            
            menu = [NSMenu menu];
            [menu addItemWithTitle:NSLocalizedString(@"Highlight", @"Menu item title") imageNamed:SKImageNameToolbarAddHighlightNote action:@selector(createNewMarkupNote:) target:self tag:SKHighlightNote];
            [menu addItemWithTitle:NSLocalizedString(@"Underline", @"Menu item title") imageNamed:SKImageNameToolbarAddUnderlineNote action:@selector(createNewMarkupNote:) target:self tag:SKUnderlineNote];
            [menu addItemWithTitle:NSLocalizedString(@"Strike Out", @"Menu item title") imageNamed:SKImageNameToolbarAddStrikeOutNote action:@selector(createNewMarkupNote:) target:self tag:SKStrikeOutNote];
            [markupNoteButton setMenu:menu forSegment:0];
            
            menu = [NSMenu menu];
            [menu addItemWithTitle:NSLocalizedString(@"Highlight", @"Menu item title") imageNamed:SKImageNameToolbarAddHighlightNote action:@selector(createNewNote:) target:self tag:SKHighlightNote];
            [menu addItemWithTitle:NSLocalizedString(@"Underline", @"Menu item title") imageNamed:SKImageNameToolbarAddUnderlineNote action:@selector(createNewNote:) target:self tag:SKUnderlineNote];
            [menu addItemWithTitle:NSLocalizedString(@"Strike Out", @"Menu item title") imageNamed:SKImageNameToolbarAddStrikeOutNote action:@selector(createNewNote:) target:self tag:SKStrikeOutNote];
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Add Markup", @"Toolbar item label") submenu:menu] autorelease];
            
            [item setLabels:NSLocalizedString(@"Add Markup", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Add New Markup", @"Tool tip message")];
            [item setSegmentedControl:markupNoteButton];
            [item setMenuFormRepresentation:menuItem];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarNewLineItemIdentifier]) {
            
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Add Line", @"Toolbar item label") action:@selector(createNewNote:) target:self tag:SKLineNote] autorelease];
            
            [item setLabels:NSLocalizedString(@"Add Line", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Add New Line", @"Tool tip message")];
            [item setTag:SKLineNote];
            [item setSegmentedControl:lineNoteButton];
            [item setMenuFormRepresentation:menuItem];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarNewNoteItemIdentifier]) {
            
            menu = [NSMenu menu];
            [menu addItemWithTitle:NSLocalizedString(@"Text Note", @"Menu item title") imageNamed:SKImageNameToolbarAddTextNote action:@selector(createNewNote:) target:self tag:SKFreeTextNote];
            [menu addItemWithTitle:NSLocalizedString(@"Anchored Note", @"Menu item title") imageNamed:SKImageNameToolbarAddAnchoredNote action:@selector(createNewNote:) target:self tag:SKAnchoredNote];
            [menu addItemWithTitle:NSLocalizedString(@"Circle", @"Menu item title") imageNamed:SKImageNameToolbarAddCircleNote action:@selector(createNewNote:) target:self tag:SKCircleNote];
            [menu addItemWithTitle:NSLocalizedString(@"Box", @"Menu item title") imageNamed:SKImageNameToolbarAddSquareNote action:@selector(createNewNote:) target:self tag:SKSquareNote];
            [menu addItemWithTitle:NSLocalizedString(@"Highlight", @"Menu item title") imageNamed:SKImageNameToolbarAddHighlightNote action:@selector(createNewNote:) target:self tag:SKHighlightNote];
            [menu addItemWithTitle:NSLocalizedString(@"Underline", @"Menu item title") imageNamed:SKImageNameToolbarAddUnderlineNote action:@selector(createNewNote:) target:self tag:SKUnderlineNote];
            [menu addItemWithTitle:NSLocalizedString(@"Strike Out", @"Menu item title") imageNamed:SKImageNameToolbarAddStrikeOutNote action:@selector(createNewNote:) target:self tag:SKStrikeOutNote];
            [menu addItemWithTitle:NSLocalizedString(@"Line", @"Menu item title") imageNamed:SKImageNameToolbarAddLineNote action:@selector(createNewNote:) target:self tag:SKLineNote];
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Add Note", @"Toolbar item label") submenu:menu] autorelease];
            
            [item setLabels:NSLocalizedString(@"Add Note", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Add New Note", @"Tool tip message")];
            [noteButton setToolTip:NSLocalizedString(@"Add New Text Note", @"Tool tip message") forSegment:SKFreeTextNote];
            [noteButton setToolTip:NSLocalizedString(@"Add New Anchored Note", @"Tool tip message") forSegment:SKAnchoredNote];
            [noteButton setToolTip:NSLocalizedString(@"Add New Circle", @"Tool tip message") forSegment:SKCircleNote];
            [noteButton setToolTip:NSLocalizedString(@"Add New Box", @"Tool tip message") forSegment:SKSquareNote];
            [noteButton setToolTip:NSLocalizedString(@"Add New Highlight", @"Tool tip message") forSegment:SKHighlightNote];
            [noteButton setToolTip:NSLocalizedString(@"Add New Underline", @"Tool tip message") forSegment:SKUnderlineNote];
            [noteButton setToolTip:NSLocalizedString(@"Add New Strike Out", @"Tool tip message") forSegment:SKStrikeOutNote];
            [noteButton setToolTip:NSLocalizedString(@"Add New Line", @"Tool tip message") forSegment:SKLineNote];
            [item setSegmentedControl:noteButton];
            [item setMenuFormRepresentation:menuItem];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarToolModeItemIdentifier]) {
            
            menu = [NSMenu menu];
            [menu addItemWithTitle:NSLocalizedString(@"Text Note", @"Menu item title") imageNamed:SKImageNameToolbarTextNote action:@selector(changeAnnotationMode:) target:self tag:SKFreeTextNote];
            [menu addItemWithTitle:NSLocalizedString(@"Anchored Note", @"Menu item title") imageNamed:SKImageNameToolbarAnchoredNote action:@selector(changeAnnotationMode:) target:self tag:SKAnchoredNote];
            [menu addItemWithTitle:NSLocalizedString(@"Circle", @"Menu item title") imageNamed:SKImageNameToolbarCircleNote action:@selector(changeAnnotationMode:) target:self tag:SKCircleNote];
            [menu addItemWithTitle:NSLocalizedString(@"Box", @"Menu item title") imageNamed:SKImageNameToolbarSquareNote action:@selector(changeAnnotationMode:) target:self tag:SKSquareNote];
            [menu addItemWithTitle:NSLocalizedString(@"Highlight", @"Menu item title") imageNamed:SKImageNameToolbarHighlightNote action:@selector(changeAnnotationMode:) target:self tag:SKHighlightNote];
            [menu addItemWithTitle:NSLocalizedString(@"Underline", @"Menu item title") imageNamed:SKImageNameToolbarUnderlineNote action:@selector(changeAnnotationMode:) target:self tag:SKUnderlineNote];
            [menu addItemWithTitle:NSLocalizedString(@"Strike Out", @"Menu item title") imageNamed:SKImageNameToolbarStrikeOutNote action:@selector(changeAnnotationMode:) target:self tag:SKStrikeOutNote];
            [menu addItemWithTitle:NSLocalizedString(@"Line", @"Menu item title") imageNamed:SKImageNameToolbarLineNote action:@selector(changeAnnotationMode:) target:self tag:SKLineNote];
            //[menu addItemWithTitle:NSLocalizedString(@"Freehand", @"Menu item title") imageNamed:SKImageNameToolbarInkNote action:@selector(changeAnnotationMode:) target:self tag:SKInkNote];
            [toolModeButton setMenu:menu forSegment:SKNoteToolMode];
            
            menu = [NSMenu menu];
            [menu addItemWithTitle:NSLocalizedString(@"Text Tool", @"Menu item title") action:@selector(changeToolMode:) target:self tag:SKTextToolMode];
            [menu addItemWithTitle:NSLocalizedString(@"Scroll Tool", @"Menu item title") action:@selector(changeToolMode:) target:self tag:SKMoveToolMode];
            [menu addItemWithTitle:NSLocalizedString(@"Magnify Tool", @"Menu item title") action:@selector(changeToolMode:) target:self tag:SKMagnifyToolMode];
            [menu addItemWithTitle:NSLocalizedString(@"Select Tool", @"Menu item title") action:@selector(changeToolMode:) target:self tag:SKSelectToolMode];
            [menu addItem:[NSMenuItem separatorItem]];
            [menu addItemWithTitle:NSLocalizedString(@"Text Note Tool", @"Menu item title") action:@selector(changeAnnotationMode:) target:self tag:SKFreeTextNote];
            [menu addItemWithTitle:NSLocalizedString(@"Anchored Note Tool", @"Menu item title") action:@selector(changeAnnotationMode:) target:self tag:SKAnchoredNote];
            [menu addItemWithTitle:NSLocalizedString(@"Circle Tool", @"Menu item title") action:@selector(changeAnnotationMode:) target:self tag:SKCircleNote];
            [menu addItemWithTitle:NSLocalizedString(@"Box Tool", @"Menu item title") action:@selector(changeAnnotationMode:) target:self tag:SKSquareNote];
            [menu addItemWithTitle:NSLocalizedString(@"Highlight Tool", @"Menu item title") action:@selector(changeAnnotationMode:) target:self tag:SKHighlightNote];
            [menu addItemWithTitle:NSLocalizedString(@"Underline Tool", @"Menu item title") action:@selector(changeAnnotationMode:) target:self tag:SKUnderlineNote];
            [menu addItemWithTitle:NSLocalizedString(@"Strike Out Tool", @"Menu item title") action:@selector(changeAnnotationMode:) target:self tag:SKStrikeOutNote];
            [menu addItemWithTitle:NSLocalizedString(@"Line Tool", @"Menu item title") action:@selector(changeAnnotationMode:) target:self tag:SKLineNote];
            //[menu addItemWithTitle:NSLocalizedString(@"Freehand Tool", @"Menu item title") action:@selector(changeAnnotationMode:) target:self tag:SKInkNote];
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Tool Mode", @"Toolbar item label") submenu:menu] autorelease];
            
            [item setLabels:NSLocalizedString(@"Tool Mode", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Tool Mode", @"Tool tip message")];
            [toolModeButton setToolTip:NSLocalizedString(@"Text Tool", @"Tool tip message") forSegment:SKTextToolMode];
            [toolModeButton setToolTip:NSLocalizedString(@"Scroll Tool", @"Tool tip message") forSegment:SKMoveToolMode];
            [toolModeButton setToolTip:NSLocalizedString(@"Magnify Tool", @"Tool tip message") forSegment:SKMagnifyToolMode];
            [toolModeButton setToolTip:NSLocalizedString(@"Select Tool", @"Tool tip message") forSegment:SKSelectToolMode];
            [toolModeButton setToolTip:NSLocalizedString(@"Note Tool", @"Tool tip message") forSegment:SKNoteToolMode];
            [item setSegmentedControl:toolModeButton];
            [item setMenuFormRepresentation:menuItem];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarSingleTwoUpItemIdentifier]) {
            
            menu = [NSMenu menu];
            [menu addItemWithTitle:NSLocalizedString(@"Single Page", @"Menu item title") action:@selector(changeDisplaySinglePages:) target:self tag:kPDFDisplaySinglePage];
            [menu addItemWithTitle:NSLocalizedString(@"Two Pages", @"Menu item title") action:@selector(changeDisplaySinglePages:) target:self tag:kPDFDisplayTwoUp];
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Single/Two Pages", @"Toolbar item label") submenu:menu] autorelease];
            
            [item setLabels:NSLocalizedString(@"Single/Two Pages", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Single/Two Pages", @"Tool tip message")];
            [singleTwoUpButton setToolTip:NSLocalizedString(@"Single Page", @"Tool tip message") forSegment:0];
            [singleTwoUpButton setToolTip:NSLocalizedString(@"Two Pages", @"Tool tip message") forSegment:1];
            [item setSegmentedControl:singleTwoUpButton];
            [item setMenuFormRepresentation:menuItem];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarContinuousItemIdentifier]) {
            
            menu = [NSMenu menu];
            [menu addItemWithTitle:NSLocalizedString(@"Non Continuous", @"Menu item title") action:@selector(changeDisplayContinuous:) target:self tag:kPDFDisplaySinglePage];
            [menu addItemWithTitle:NSLocalizedString(@"Continuous", @"Menu item title") action:@selector(changeDisplayContinuous:) target:self tag:kPDFDisplaySinglePageContinuous];
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Continuous", @"Toolbar item label") submenu:menu] autorelease];
            
            [item setLabels:NSLocalizedString(@"Continuous", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Continuous", @"Tool tip message")];
            [continuousButton setToolTip:NSLocalizedString(@"Non Continuous", @"Tool tip message") forSegment:0];
            [continuousButton setToolTip:NSLocalizedString(@"Continuous", @"Tool tip message") forSegment:1];
            [item setSegmentedControl:continuousButton];
            [item setMenuFormRepresentation:menuItem];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarDisplayModeItemIdentifier]) {
            
            menu = [NSMenu menu];
            [menu addItemWithTitle:NSLocalizedString(@"Single Page", @"Menu item title") action:@selector(changeDisplayMode:) target:self tag:kPDFDisplaySinglePage];
            [menu addItemWithTitle:NSLocalizedString(@"Single Page Continuous", @"Menu item title") action:@selector(changeDisplayMode:) target:self tag:kPDFDisplaySinglePageContinuous];
            [menu addItemWithTitle:NSLocalizedString(@"Two Pages", @"Menu item title") action:@selector(changeDisplayMode:) target:self tag:kPDFDisplayTwoUp];
            [menu addItemWithTitle:NSLocalizedString(@"Two Pages Continuous", @"Menu item title") action:@selector(changeDisplayMode:) target:self tag:kPDFDisplayTwoUpContinuous];
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Display Mode", @"Toolbar item label") submenu:menu] autorelease];
            
            [item setLabels:NSLocalizedString(@"Display Mode", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Display Mode", @"Tool tip message")];
            [displayModeButton setToolTip:NSLocalizedString(@"Single Page", @"Tool tip message") forSegment:kPDFDisplaySinglePage];
            [displayModeButton setToolTip:NSLocalizedString(@"Single Page Continuous", @"Tool tip message") forSegment:kPDFDisplaySinglePageContinuous];
            [displayModeButton setToolTip:NSLocalizedString(@"Two Pages", @"Tool tip message") forSegment:kPDFDisplayTwoUp];
            [displayModeButton setToolTip:NSLocalizedString(@"Two Pages Continuous", @"Tool tip message") forSegment:kPDFDisplayTwoUpContinuous];
            [item setSegmentedControl:displayModeButton];
            [item setMenuFormRepresentation:menuItem];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarDisplayBoxItemIdentifier]) {
            
            menu = [NSMenu menu];
            [menu addItemWithTitle:NSLocalizedString(@"Media Box", @"Menu item title") action:@selector(changeDisplayBox:) target:self tag:kPDFDisplayBoxMediaBox];
            [menu addItemWithTitle:NSLocalizedString(@"Crop Box", @"Menu item title") action:@selector(changeDisplayBox:) target:self tag:kPDFDisplayBoxCropBox];
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Display Box", @"Toolbar item label") submenu:menu] autorelease];
            
            [item setLabels:NSLocalizedString(@"Display Box", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Display Box", @"Tool tip message")];
            [item setSegmentedControl:displayBoxButton];
            [item setMenuFormRepresentation:menuItem];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarColorSwatchItemIdentifier]) {
            
            NSDictionary *options = [NSDictionary dictionaryWithObject:SKUnarchiveFromDataArrayTransformerName forKey:NSValueTransformerNameBindingOption];
            [colorSwatch bind:SKColorSwatchColorsKey toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:[NSString stringWithFormat:@"values.%@", SKSwatchColorsKey] options:options];
            [colorSwatch sizeToFit];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleColorSwatchColorsChangedNotification:) 
                                                         name:SKColorSwatchColorsChangedNotification object:colorSwatch];
            
            menu = [NSMenu menu];
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Colors", @"Toolbar item label") submenu:menu] autorelease];
            
            [item setLabels:NSLocalizedString(@"Favorite Colors", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Favorite Colors", @"Tool tip message")];
            [item setViewWithSizes:colorSwatch];
            [item setMenuFormRepresentation:menuItem];
            [self handleColorSwatchColorsChangedNotification:nil];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarColorsItemIdentifier]) {
            
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Colors", @"Menu item title") action:@selector(orderFrontColorPanel:) keyEquivalent:@""] autorelease];
            
            [item setLabels:NSLocalizedString(@"Colors", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Colors", @"Tool tip message")];
            [item setSegmentedControl:colorsButton];
            [item setMenuFormRepresentation:menuItem];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarFontsItemIdentifier]) {
            
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Fonts", @"Menu item title") action:@selector(orderFrontFontPanel:) keyEquivalent:@""] autorelease];
            
            [item setLabels:NSLocalizedString(@"Fonts", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Fonts", @"Tool tip message")];
            [item setImageNamed:@"ToolbarFonts"];
            [item setSegmentedControl:fontsButton];
            if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_4)
                [fontsButton setImage:[NSImage imageNamed:@"ToolbarFontsBlack"] forSegment:0];
            [item setMenuFormRepresentation:menuItem];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarLinesItemIdentifier]) {
            
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Lines", @"Menu item title") action:@selector(orderFrontLineInspector:) keyEquivalent:@""] autorelease];
            
            [item setLabels:NSLocalizedString(@"Lines", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Lines", @"Tool tip message")];
            [item setSegmentedControl:linesButton];
            [item setMenuFormRepresentation:menuItem];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarInfoItemIdentifier]) {
            
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Info", @"Menu item title") action:@selector(getInfo:) target:self] autorelease];
            
            [item setLabels:NSLocalizedString(@"Info", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Get Document Info", @"Tool tip message")];
            [item setSegmentedControl:infoButton];
            [item setMenuFormRepresentation:menuItem];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarContentsPaneItemIdentifier]) {
            
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Contents Pane", @"Menu item title") action:@selector(toggleLeftSidePane:) target:self] autorelease];
            
            [item setLabels:NSLocalizedString(@"Contents Pane", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Toggle Contents Pane", @"Tool tip message")];
            [item setSegmentedControl:leftPaneButton];
            [item setMenuFormRepresentation:menuItem];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarNotesPaneItemIdentifier]) {
            
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Notes Pane", @"Menu item title") action:@selector(toggleRightSidePane:) target:self] autorelease];
            
            [item setLabels:NSLocalizedString(@"Notes Pane", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Toggle Notes Pane", @"Tool tip message")];
            [item setSegmentedControl:rightPaneButton];
            [item setMenuFormRepresentation:menuItem];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarPrintItemIdentifier]) {
            
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Print", @"Menu item title") action:@selector(printDocument:) keyEquivalent:@""] autorelease];
            
            [item setLabels:NSLocalizedString(@"Print", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Print Document", @"Tool tip message")];
            [item setSegmentedControl:printButton];
            [item setMenuFormRepresentation:menuItem];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarCustomizeItemIdentifier]) {
            
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Customize", @"Menu item title") action:@selector(runToolbarCustomizationPalette:) keyEquivalent:@""] autorelease];
            
            [item setLabels:NSLocalizedString(@"Customize", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Customize Toolbar", @"Tool tip message")];
            [item setSegmentedControl:customizeButton];
            [item setMenuFormRepresentation:menuItem];
            
        }
    }
    
    return item;
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdent willBeInsertedIntoToolbar:(BOOL)willBeInserted {

    NSToolbarItem *item = [self toolbarItemForItemIdentifier:itemIdent];
    
    if (willBeInserted == NO) {
        item = [[item copy] autorelease];
        [item setEnabled:YES];
        if ([[item view] respondsToSelector:@selector(setEnabled:)])
            [(NSControl *)[item view] setEnabled:YES];
        if ([[item view] respondsToSelector:@selector(setEnabledForAllSegments:)])
            [(NSSegmentedControl *)[item view] setEnabledForAllSegments:YES];
    }
    
    return item;
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
    return [NSArray arrayWithObjects:
        SKDocumentToolbarPreviousNextItemIdentifier, 
        SKDocumentToolbarPageNumberItemIdentifier, 
        SKDocumentToolbarBackForwardItemIdentifier, 
        SKDocumentToolbarZoomInActualOutItemIdentifier, 
        SKDocumentToolbarToolModeItemIdentifier, 
        SKDocumentToolbarNewNoteItemIdentifier, nil];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
    return [NSArray arrayWithObjects: 
        SKDocumentToolbarPreviousNextItemIdentifier, 
        SKDocumentToolbarPreviousNextFirstLastItemIdentifier, 
        SKDocumentToolbarPreviousItemIdentifier, 
        SKDocumentToolbarPageNumberItemIdentifier, 
        SKDocumentToolbarNextItemIdentifier, 
        SKDocumentToolbarBackForwardItemIdentifier, 
        SKDocumentToolbarZoomInActualOutItemIdentifier, 
        SKDocumentToolbarZoomInOutItemIdentifier, 
        SKDocumentToolbarZoomActualItemIdentifier, 
        SKDocumentToolbarZoomToFitItemIdentifier, 
        SKDocumentToolbarZoomToSelectionItemIdentifier, 
        SKDocumentToolbarScaleItemIdentifier, 
        SKDocumentToolbarSingleTwoUpItemIdentifier, 
        SKDocumentToolbarContinuousItemIdentifier, 
        SKDocumentToolbarDisplayModeItemIdentifier, 
        SKDocumentToolbarDisplayBoxItemIdentifier, 
        SKDocumentToolbarToolModeItemIdentifier, 
        SKDocumentToolbarRotateRightItemIdentifier, 
        SKDocumentToolbarRotateLeftItemIdentifier, 
        SKDocumentToolbarRotateLeftRightItemIdentifier, 
        SKDocumentToolbarCropItemIdentifier, 
        SKDocumentToolbarFullScreenItemIdentifier, 
        SKDocumentToolbarPresentationItemIdentifier, 
        SKDocumentToolbarContentsPaneItemIdentifier, 
        SKDocumentToolbarNotesPaneItemIdentifier, 
        SKDocumentToolbarColorSwatchItemIdentifier, 
        SKDocumentToolbarNewNoteItemIdentifier, 
        SKDocumentToolbarNewTextNoteItemIdentifier, 
        SKDocumentToolbarNewCircleNoteItemIdentifier, 
        SKDocumentToolbarNewMarkupItemIdentifier,
        SKDocumentToolbarNewLineItemIdentifier,
        SKDocumentToolbarInfoItemIdentifier, 
        SKDocumentToolbarColorsItemIdentifier, 
        SKDocumentToolbarFontsItemIdentifier, 
        SKDocumentToolbarLinesItemIdentifier, 
		SKDocumentToolbarPrintItemIdentifier,
		NSToolbarFlexibleSpaceItemIdentifier, 
		NSToolbarSpaceItemIdentifier, 
		NSToolbarSeparatorItemIdentifier, 
		SKDocumentToolbarCustomizeItemIdentifier, nil];
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)toolbarItem {
    NSString *identifier = [toolbarItem itemIdentifier];
    BOOL noPalette = NO == [[mainWindow toolbar] customizationPaletteIsRunning];
    
    if ([identifier isEqualToString:SKDocumentToolbarZoomActualItemIdentifier]) {
        return noPalette && fabsf([pdfView scaleFactor] - 1.0 ) > 0.01;
    } else if ([identifier isEqualToString:SKDocumentToolbarZoomToFitItemIdentifier]) {
        return noPalette && [pdfView autoScales] == NO;
    } else if ([identifier isEqualToString:SKDocumentToolbarZoomToSelectionItemIdentifier]) {
        return noPalette && NSIsEmptyRect([pdfView currentSelectionRect]) == NO;
    } else if ([identifier isEqualToString:SKDocumentToolbarNewTextNoteItemIdentifier] || [identifier isEqualToString:SKDocumentToolbarNewCircleNoteItemIdentifier] || [identifier isEqualToString:SKDocumentToolbarNewLineItemIdentifier]) {
        return noPalette && ([pdfView toolMode] == SKTextToolMode || [pdfView toolMode] == SKNoteToolMode) && [pdfView hideNotes] == NO;
    } else if ([identifier isEqualToString:SKDocumentToolbarNewMarkupItemIdentifier]) {
        return noPalette && ([pdfView toolMode] == SKTextToolMode || [pdfView toolMode] == SKNoteToolMode) && [[[pdfView currentSelection] pages] count] && [pdfView hideNotes] == NO;
    } else if ([identifier isEqualToString:SKDocumentToolbarNewNoteItemIdentifier]) {
        BOOL enabled = ([pdfView toolMode] == SKTextToolMode || [pdfView toolMode] == SKNoteToolMode) && [[[pdfView currentSelection] pages] count] && [pdfView hideNotes] == NO;
        [noteButton setEnabled:enabled forSegment:SKHighlightNote];
        [noteButton setEnabled:enabled forSegment:SKUnderlineNote];
        [noteButton setEnabled:enabled forSegment:SKStrikeOutNote];
        return noPalette && ([pdfView toolMode] == SKTextToolMode || [pdfView toolMode] == SKNoteToolMode) && [pdfView hideNotes] == NO;
    }
    return noPalette;
}

- (void)handleColorSwatchColorsChangedNotification:(NSNotification *)notification {
    NSToolbarItem *toolbarItem = [self toolbarItemForItemIdentifier:SKDocumentToolbarColorSwatchItemIdentifier];
    NSMenu *menu = [[toolbarItem menuFormRepresentation] submenu];
    
    NSEnumerator *colorEnum = [[colorSwatch colors] objectEnumerator];
    NSColor *color;
    NSRect rect = NSMakeRect(0.0, 0.0, 16.0, 16.0);
    NSRect lineRect = NSInsetRect(rect, 0.5, 0.5);
    NSRect swatchRect = NSInsetRect(rect, 1.0, 1.0);
    
    [menu removeAllItems];
    
    while (color = [colorEnum nextObject]) {
        NSImage *image = [[NSImage alloc] initWithSize:rect.size];
        NSMenuItem *item = [menu addItemWithTitle:@"" action:@selector(selectColor:) keyEquivalent:@""];
        
        [image lockFocus];
        [[NSColor lightGrayColor] setStroke];
        [NSBezierPath setDefaultLineWidth:1.0];
        [NSBezierPath strokeRect:lineRect];
        [color drawSwatchInRect:swatchRect];
        [image unlockFocus];
        [item setTarget:self];
        [item setRepresentedObject:color];
        [item setImage:image];
        [image release];
    }
    
    NSSize size = [colorSwatch bounds].size;
    [toolbarItem setMinSize:size];
    [toolbarItem setMaxSize:size];
}

@end
