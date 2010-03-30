//
//  SKMainToolbarController.m
//  Skim
//
//  Created by Christiaan Hofman on 4/2/08.
/*
 This software is Copyright (c) 2008-2010
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

#import "SKMainToolbarController.h"
#import "SKMainWindowController.h"
#import "SKMainWindowController_Actions.h"
#import "SKToolbarItem.h"
#import "NSSegmentedControl_SKExtensions.h"
#import "SKStringConstants.h"
#import "SKPDFView.h"
#import "SKColorSwatch.h"
#import "NSValueTransformer_SKExtensions.h"
#import "SKApplicationController.h"
#import "NSImage_SKExtensions.h"
#import "NSMenu_SKExtensions.h"
#import "PDFSelection_SKExtensions.h"
#import "SKTextFieldSheetController.h"
#import "NSWindowController_SKExtensions.h"
#import <SkimNotes/SkimNotes.h>
#import "NSEvent_SKExtensions.h"

#define SKDocumentToolbarIdentifier @"SKDocumentToolbar"

#define SKDocumentToolbarPreviousItemIdentifier @"SKDocumentToolbarPreviousItemIdentifier"
#define SKDocumentToolbarNextItemIdentifier @"SKDocumentToolbarNextItemIdentifier"
#define SKDocumentToolbarPreviousNextItemIdentifier @"SKDocumentToolbarPreviousNextItemIdentifier"
#define SKDocumentToolbarPreviousNextFirstLastItemIdentifier @"SKDocumentToolbarPreviousNextFirstLastItemIdentifier"
#define SKDocumentToolbarBackForwardItemIdentifier @"SKDocumentToolbarBackForwardItemIdentifier"
#define SKDocumentToolbarPageNumberItemIdentifier @"SKDocumentToolbarPageNumberItemIdentifier"
#define SKDocumentToolbarScaleItemIdentifier @"SKDocumentToolbarScaleItemIdentifier"
#define SKDocumentToolbarZoomActualItemIdentifier @"SKDocumentToolbarZoomActualItemIdentifier"
#define SKDocumentToolbarZoomToSelectionItemIdentifier @"SKDocumentToolbarZoomToSelectionItemIdentifier"
#define SKDocumentToolbarZoomToFitItemIdentifier @"SKDocumentToolbarZoomToFitItemIdentifier"
#define SKDocumentToolbarZoomInOutItemIdentifier @"SKDocumentToolbarZoomInOutItemIdentifier"
#define SKDocumentToolbarZoomInActualOutItemIdentifier @"SKDocumentToolbarZoomInActualOutItemIdentifier"
#define SKDocumentToolbarRotateRightItemIdentifier @"SKDocumentToolbarRotateRightItemIdentifier"
#define SKDocumentToolbarRotateLeftItemIdentifier @"SKDocumentToolbarRotateLeftItemIdentifier"
#define SKDocumentToolbarRotateLeftRightItemIdentifier @"SKDocumentToolbarRotateLeftRightItemIdentifier"
#define SKDocumentToolbarCropItemIdentifier @"SKDocumentToolbarCropItemIdentifier"
#define SKDocumentToolbarFullScreenItemIdentifier @"SKDocumentToolbarFullScreenItemIdentifier"
#define SKDocumentToolbarPresentationItemIdentifier @"SKDocumentToolbarPresentationItemIdentifier"
#define SKDocumentToolbarNewTextNoteItemIdentifier @"SKDocumentToolbarNewTextNoteItemIdentifier"
#define SKDocumentToolbarNewCircleNoteItemIdentifier @"SKDocumentToolbarNewCircleNoteItemIdentifier"
#define SKDocumentToolbarNewMarkupItemIdentifier @"SKDocumentToolbarNewMarkupItemIdentifier"
#define SKDocumentToolbarNewLineItemIdentifier @"SKDocumentToolbarNewLineItemIdentifier"
#define SKDocumentToolbarNewNoteItemIdentifier @"SKDocumentToolbarNewNoteItemIdentifier"
#define SKDocumentToolbarInfoItemIdentifier @"SKDocumentToolbarInfoItemIdentifier"
#define SKDocumentToolbarToolModeItemIdentifier @"SKDocumentToolbarToolModeItemIdentifier"
#define SKDocumentToolbarSingleTwoUpItemIdentifier @"SKDocumentToolbarSingleTwoUpItemIdentifier"
#define SKDocumentToolbarContinuousItemIdentifier @"SKDocumentToolbarContinuousItemIdentifier"
#define SKDocumentToolbarDisplayModeItemIdentifier @"SKDocumentToolbarDisplayModeItemIdentifier"
#define SKDocumentToolbarDisplayBoxItemIdentifier @"SKDocumentToolbarDisplayBoxItemIdentifier"
#define SKDocumentToolbarColorSwatchItemIdentifier @"SKDocumentToolbarColorSwatchItemIdentifier"
#define SKDocumentToolbarColorsItemIdentifier @"SKDocumentToolbarColorsItemIdentifier"
#define SKDocumentToolbarFontsItemIdentifier @"SKDocumentToolbarFontsItemIdentifier"
#define SKDocumentToolbarLinesItemIdentifier @"SKDocumentToolbarLinesItemIdentifier"
#define SKDocumentToolbarContentsPaneItemIdentifier @"SKDocumentToolbarContentsPaneItemIdentifier"
#define SKDocumentToolbarNotesPaneItemIdentifier @"SKDocumentToolbarNotesPaneItemIdentifier"
#define SKDocumentToolbarPrintItemIdentifier @"SKDocumentToolbarPrintItemIdentifier"
#define SKDocumentToolbarCustomizeItemIdentifier @"SKDocumentToolbarCustomizeItemIdentifier"

static NSString *noteToolImageNames[] = {@"ToolbarTextNoteMenu", @"ToolbarAnchoredNoteMenu", @"ToolbarCircleNoteMenu", @"ToolbarSquareNoteMenu", @"ToolbarHighlightNoteMenu", @"ToolbarUnderlineNoteMenu", @"ToolbarStrikeOutNoteMenu", @"ToolbarLineNoteMenu", @"ToolbarInkNoteMenu"};

@interface SKToolbar : NSToolbar
@end

@implementation SKToolbar
- (BOOL)_allowsSizeMode:(NSToolbarSizeMode)sizeMode { return NO; }
@end

#pragma mark -

@interface SKMainToolbarController (SKPrivate)
- (void)handleColorSwatchColorsChangedNotification:(NSNotification *)notification;
@end


@implementation SKMainToolbarController

@synthesize mainController, backForwardButton, pageNumberField, previousNextPageButton, previousPageButton, nextPageButton, previousNextFirstLastPageButton, zoomInOutButton, zoomInActualOutButton, zoomActualButton, zoomFitButton, zoomSelectionButton, rotateLeftButton, rotateRightButton, rotateLeftRightButton, cropButton, fullScreenButton, presentationButton, leftPaneButton, rightPaneButton, toolModeButton, textNoteButton, circleNoteButton, markupNoteButton, lineNoteButton, singleTwoUpButton, continuousButton, displayModeButton, displayBoxButton, infoButton, colorsButton, fontsButton, linesButton, printButton, customizeButton, scaleField, noteButton, colorSwatch;

- (void)dealloc {
    @try { [colorSwatch unbind:@"colors"]; }
    @catch (id e) {}
	[[NSNotificationCenter defaultCenter] removeObserver: self];
    mainController = nil;
    pdfView = nil;
    SKDESTROY(toolbarItems);
    [super dealloc];
}

- (NSString *)nibName {
    return @"MainToolbar";
}

- (void)setupToolbar {
    // make sure the nib is loaded
    [self view];
    
    // Create a new toolbar instance, and attach it to our document window
    NSToolbar *toolbar = [[[SKToolbar alloc] initWithIdentifier:SKDocumentToolbarIdentifier] autorelease];
    
    // Set up toolbar properties: Allow customization, give a default display mode, and remember state in user defaults
    [toolbar setAllowsUserCustomization:YES];
    [toolbar setAutosavesConfiguration:YES];
    [toolbar setDisplayMode:NSToolbarDisplayModeDefault];
    
    pdfView = [mainController pdfView];
    
    // We are the delegate
    [toolbar setDelegate:self];
    
    // Attach the toolbar to the window
    [[mainController window] setToolbar:toolbar];
    
    [self registerForNotifications];
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
            [menu addItemWithTitle:NSLocalizedString(@"Previous", @"Menu item title") action:@selector(doGoToPreviousPage:) target:mainController];
            [menu addItemWithTitle:NSLocalizedString(@"Next", @"Menu item title") action:@selector(doGoToNextPage:) target:mainController];
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Previous/Next", @"Toolbar item label") submenu:menu] autorelease];
            
            [item setLabels:NSLocalizedString(@"Previous/Next", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Previous/Next", @"Tool tip message")];
            [previousNextPageButton setToolTip:NSLocalizedString(@"Go To Previous Page", @"Tool tip message") forSegment:0];
            [previousNextPageButton setToolTip:NSLocalizedString(@"Go To Next Page", @"Tool tip message") forSegment:1];
            [item setViewWithSizes:previousNextPageButton];
            [item setMenuFormRepresentation:menuItem];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarPreviousItemIdentifier]) {
            
            menu = [NSMenu menu];
            [menu addItemWithTitle:NSLocalizedString(@"Previous", @"Menu item title") action:@selector(doGoToPreviousPage:) target:mainController];
            menuItem = [menu addItemWithTitle:NSLocalizedString(@"First", @"Menu item title") action:@selector(doGoToFirstPage:) target:mainController];
            
            [item setLabels:NSLocalizedString(@"Previous", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Go To Previous Page", @"Tool tip message")];
            [previousPageButton setToolTip:NSLocalizedString(@"Go To First page", @"Tool tip message") forSegment:0];
            [previousPageButton setToolTip:NSLocalizedString(@"Go To Previous Page", @"Tool tip message") forSegment:1];
            [item setViewWithSizes:previousPageButton];
            [item setMenuFormRepresentation:menuItem];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarNextItemIdentifier]) {
            
            menu = [NSMenu menu];
            [menu addItemWithTitle:NSLocalizedString(@"Next", @"Menu item title") action:@selector(doGoToNextPage:) target:mainController];
            [menu addItemWithTitle:NSLocalizedString(@"Last", @"Menu item title") action:@selector(doGoToLastPage:) target:mainController];
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Page", @"Toolbar item label") submenu:menu] autorelease];
            
            [item setLabels:NSLocalizedString(@"Next", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Go To Next Page", @"Tool tip message")];
            [nextPageButton setToolTip:NSLocalizedString(@"Go To Next Page", @"Tool tip message") forSegment:0];
            [nextPageButton setToolTip:NSLocalizedString(@"Go To Last page", @"Tool tip message") forSegment:1];
            [item setViewWithSizes:nextPageButton];
            [item setMenuFormRepresentation:menuItem];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarPreviousNextFirstLastItemIdentifier]) {
            
            menu = [NSMenu menu];
            [menu addItemWithTitle:NSLocalizedString(@"Previous", @"Menu item title") action:@selector(doGoToPreviousPage:) target:mainController];
            [menu addItemWithTitle:NSLocalizedString(@"Next", @"Menu item title") action:@selector(doGoToNextPage:) target:mainController];
            [menu addItemWithTitle:NSLocalizedString(@"First", @"Menu item title") action:@selector(doGoToFirstPage:) target:mainController];
            [menu addItemWithTitle:NSLocalizedString(@"Last", @"Menu item title") action:@selector(doGoToLastPage:) target:mainController];
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Previous/Next", @"Toolbar item label") submenu:menu] autorelease];
            
            [item setLabels:NSLocalizedString(@"Previous/Next", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Go To First, Previous, Next or Last Page", @"Tool tip message")];
            [previousNextFirstLastPageButton setToolTip:NSLocalizedString(@"Go To First page", @"Tool tip message") forSegment:0];
            [previousNextFirstLastPageButton setToolTip:NSLocalizedString(@"Go To Previous Page", @"Tool tip message") forSegment:1];
            [previousNextFirstLastPageButton setToolTip:NSLocalizedString(@"Go To Next Page", @"Tool tip message") forSegment:2];
            [previousNextFirstLastPageButton setToolTip:NSLocalizedString(@"Go To Last page", @"Tool tip message") forSegment:3];
            [item setViewWithSizes:previousNextFirstLastPageButton];
            [item setMenuFormRepresentation:menuItem];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarBackForwardItemIdentifier]) {
            
            menu = [NSMenu menu];
            [menu addItemWithTitle:NSLocalizedString(@"Back", @"Menu item title") action:@selector(doGoBack:) target:mainController];
            [menu addItemWithTitle:NSLocalizedString(@"Forward", @"Menu item title") action:@selector(doGoForward:) target:mainController];
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Back/Forward", @"Toolbar item label") submenu:menu] autorelease];
            
            [item setLabels:NSLocalizedString(@"Back/Forward", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Back/Forward", @"Tool tip message")];
            [backForwardButton setToolTip:NSLocalizedString(@"Go Back", @"Tool tip message") forSegment:0];
            [backForwardButton setToolTip:NSLocalizedString(@"Go Forward", @"Tool tip message") forSegment:1];
            [item setViewWithSizes:backForwardButton];
            [item setMenuFormRepresentation:menuItem];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarPageNumberItemIdentifier]) {
            
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Page", @"Menu item title") action:@selector(doGoToPage:) target:mainController] autorelease];
            
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
            
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Actual Size", @"Menu item title") action:@selector(doZoomToActualSize:) target:mainController] autorelease];
            
            [item setLabels:NSLocalizedString(@"Actual Size", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Zoom To Actual Size", @"Tool tip message")];
            [item setViewWithSizes:zoomActualButton];
            [item setMenuFormRepresentation:menuItem];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarZoomToFitItemIdentifier]) {
            
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Zoom To Fit", @"Menu item title") action:@selector(doZoomToFit:) target:mainController] autorelease];
            
            [item setLabels:NSLocalizedString(@"Zoom To Fit", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Zoom To Fit", @"Tool tip message")];
            [item setViewWithSizes:zoomFitButton];
            [item setMenuFormRepresentation:menuItem];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarZoomToSelectionItemIdentifier]) {
            
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Zoom To Selection", @"Menu item title") action:@selector(doZoomToSelection:) target:mainController] autorelease];
            
            [item setLabels:NSLocalizedString(@"Zoom To Selection", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Zoom To Selection", @"Tool tip message")];
            [item setViewWithSizes:zoomSelectionButton];
            [item setMenuFormRepresentation:menuItem];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarZoomInOutItemIdentifier]) {
            
            menu = [NSMenu menu];
            [menu addItemWithTitle:NSLocalizedString(@"Zoom In", @"Menu item title") action:@selector(doZoomIn:) target:mainController];
            [menu addItemWithTitle:NSLocalizedString(@"Zoom Out", @"Menu item title") action:@selector(doZoomOut:) target:mainController];
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Zoom", @"Toolbar item label") submenu:menu] autorelease];
            
            [item setLabels:NSLocalizedString(@"Zoom", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Zoom", @"Tool tip message")];
            [zoomInOutButton setToolTip:NSLocalizedString(@"Zoom Out", @"Tool tip message") forSegment:0];
            [zoomInOutButton setToolTip:NSLocalizedString(@"Zoom In", @"Tool tip message") forSegment:1];
            [item setViewWithSizes:zoomInOutButton];
            [item setMenuFormRepresentation:menuItem];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarZoomInActualOutItemIdentifier]) {
            
            menu = [NSMenu menu];
            [menu addItemWithTitle:NSLocalizedString(@"Zoom In", @"Menu item title") action:@selector(doZoomIn:) target:mainController];
            [menu addItemWithTitle:NSLocalizedString(@"Zoom Out", @"Menu item title") action:@selector(doZoomOut:) target:mainController];
            [menu addItemWithTitle:NSLocalizedString(@"Actual Size", @"Menu item title") action:@selector(doZoomToActualSize:) target:mainController];
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Zoom", @"Toolbar item label") submenu:menu] autorelease];
            
            [item setLabels:NSLocalizedString(@"Zoom", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Zoom", @"Tool tip message")];
            [zoomInActualOutButton setToolTip:NSLocalizedString(@"Zoom Out", @"Tool tip message") forSegment:0];
            [zoomInActualOutButton setToolTip:NSLocalizedString(@"Zoom To Actual Size", @"Tool tip message") forSegment:1];
            [zoomInActualOutButton setToolTip:NSLocalizedString(@"Zoom In", @"Tool tip message") forSegment:2];
            [item setViewWithSizes:zoomInActualOutButton];
            [item setMenuFormRepresentation:menuItem];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarRotateRightItemIdentifier]) {
            
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Rotate Right", @"Menu item title") action:@selector(rotateAllRight:) target:mainController] autorelease];
            
            [item setLabels:NSLocalizedString(@"Rotate Right", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Rotate Right", @"Tool tip message")];
            [item setViewWithSizes:rotateRightButton];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarRotateLeftItemIdentifier]) {
            
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Rotate Left", @"Menu item title") action:@selector(rotateAllLeft:) target:mainController] autorelease];
            
            [item setLabels:NSLocalizedString(@"Rotate Left", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Rotate Left", @"Tool tip message")];
            [item setViewWithSizes:rotateLeftButton];
            [item setMenuFormRepresentation:menuItem];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarRotateLeftRightItemIdentifier]) {
            
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Rotate Left", @"Menu item title") action:@selector(rotateAllLeft:) target:mainController] autorelease];
            
            [item setLabels:NSLocalizedString(@"Rotate", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Rotate Left or Right", @"Tool tip message")];
            [item setViewWithSizes:rotateLeftRightButton];
            [item setMenuFormRepresentation:menuItem];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarCropItemIdentifier]) {
            
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Crop", @"Menu item title") action:@selector(cropAll:) target:mainController] autorelease];
            
            [item setLabels:NSLocalizedString(@"Crop", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Crop", @"Tool tip message")];
            [item setViewWithSizes:cropButton];
            [item setMenuFormRepresentation:menuItem];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarFullScreenItemIdentifier]) {
            
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Full Screen", @"Menu item title") action:@selector(enterFullScreen:) target:mainController] autorelease];
            
            [item setLabels:NSLocalizedString(@"Full Screen", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Full Screen", @"Tool tip message")];
            [item setViewWithSizes:fullScreenButton];
            [item setMenuFormRepresentation:menuItem];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarPresentationItemIdentifier]) {
            
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Presentation", @"Menu item title") action:@selector(enterPresentation:) target:mainController] autorelease];
            
            [item setLabels:NSLocalizedString(@"Presentation", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Presentation", @"Tool tip message")];
            [item setViewWithSizes:presentationButton];
            [item setMenuFormRepresentation:menuItem];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarNewTextNoteItemIdentifier]) {
            
            menu = [NSMenu menu];
            [menu addItemWithTitle:NSLocalizedString(@"Text Note", @"Menu item title") imageNamed:SKImageNameToolbarAddTextNote action:@selector(createNewTextNote:) target:self tag:SKFreeTextNote];
            [menu addItemWithTitle:NSLocalizedString(@"Anchored Note", @"Menu item title") imageNamed:SKImageNameToolbarAddAnchoredNote action:@selector(createNewTextNote:) target:self tag:SKAnchoredNote];
            [textNoteButton setMenu:menu forSegment:0];
            
            menu = [NSMenu menu];
            [menu addItemWithTitle:NSLocalizedString(@"Text Note", @"Menu item title") imageNamed:SKImageNameToolbarAddTextNote action:@selector(createNewNote:) target:mainController tag:SKFreeTextNote];
            [menu addItemWithTitle:NSLocalizedString(@"Anchored Note", @"Menu item title") imageNamed:SKImageNameToolbarAddAnchoredNote action:@selector(createNewNote:) target:mainController tag:SKAnchoredNote];
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Add Note", @"Toolbar item label") submenu:menu] autorelease];
            
            [item setLabels:NSLocalizedString(@"Add Note", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Add New Note", @"Tool tip message")];
            [item setViewWithSizes:textNoteButton];
            [item setMenuFormRepresentation:menuItem];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarNewCircleNoteItemIdentifier]) {
            
            menu = [NSMenu menu];
            [menu addItemWithTitle:NSLocalizedString(@"Circle", @"Menu item title") imageNamed:SKImageNameToolbarAddCircleNote action:@selector(createNewCircleNote:) target:self tag:SKCircleNote];
            [menu addItemWithTitle:NSLocalizedString(@"Box", @"Menu item title") imageNamed:SKImageNameToolbarAddSquareNote action:@selector(createNewCircleNote:) target:self tag:SKSquareNote];
            [circleNoteButton setMenu:menu forSegment:0];
            
            menu = [NSMenu menu];
            [menu addItemWithTitle:NSLocalizedString(@"Circle", @"Menu item title") imageNamed:SKImageNameToolbarAddCircleNote action:@selector(createNewNote:) target:mainController tag:SKCircleNote];
            [menu addItemWithTitle:NSLocalizedString(@"Box", @"Menu item title") imageNamed:SKImageNameToolbarAddSquareNote action:@selector(createNewNote:) target:mainController tag:SKSquareNote];
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Add Shape", @"Toolbar item label") submenu:menu] autorelease];
            
            [item setLabels:NSLocalizedString(@"Add Shape", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Add New Circle or Box", @"Tool tip message")];
            [item setViewWithSizes:circleNoteButton];
            [item setMenuFormRepresentation:menuItem];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarNewMarkupItemIdentifier]) {
            
            menu = [NSMenu menu];
            [menu addItemWithTitle:NSLocalizedString(@"Highlight", @"Menu item title") imageNamed:SKImageNameToolbarAddHighlightNote action:@selector(createNewMarkupNote:) target:self tag:SKHighlightNote];
            [menu addItemWithTitle:NSLocalizedString(@"Underline", @"Menu item title") imageNamed:SKImageNameToolbarAddUnderlineNote action:@selector(createNewMarkupNote:) target:self tag:SKUnderlineNote];
            [menu addItemWithTitle:NSLocalizedString(@"Strike Out", @"Menu item title") imageNamed:SKImageNameToolbarAddStrikeOutNote action:@selector(createNewMarkupNote:) target:self tag:SKStrikeOutNote];
            [markupNoteButton setMenu:menu forSegment:0];
            
            menu = [NSMenu menu];
            [menu addItemWithTitle:NSLocalizedString(@"Highlight", @"Menu item title") imageNamed:SKImageNameToolbarAddHighlightNote action:@selector(createNewNote:) target:mainController tag:SKHighlightNote];
            [menu addItemWithTitle:NSLocalizedString(@"Underline", @"Menu item title") imageNamed:SKImageNameToolbarAddUnderlineNote action:@selector(createNewNote:) target:mainController tag:SKUnderlineNote];
            [menu addItemWithTitle:NSLocalizedString(@"Strike Out", @"Menu item title") imageNamed:SKImageNameToolbarAddStrikeOutNote action:@selector(createNewNote:) target:mainController tag:SKStrikeOutNote];
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Add Markup", @"Toolbar item label") submenu:menu] autorelease];
            
            [item setLabels:NSLocalizedString(@"Add Markup", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Add New Markup", @"Tool tip message")];
            [item setViewWithSizes:markupNoteButton];
            [item setMenuFormRepresentation:menuItem];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarNewLineItemIdentifier]) {
            
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Add Line", @"Toolbar item label") action:@selector(createNewNote:) target:mainController tag:SKLineNote] autorelease];
            
            [item setLabels:NSLocalizedString(@"Add Line", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Add New Line", @"Tool tip message")];
            [item setTag:SKLineNote];
            [item setViewWithSizes:lineNoteButton];
            [item setMenuFormRepresentation:menuItem];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarNewNoteItemIdentifier]) {
            
            menu = [NSMenu menu];
            [menu addItemWithTitle:NSLocalizedString(@"Text Note", @"Menu item title") imageNamed:SKImageNameToolbarAddTextNote action:@selector(createNewNote:) target:mainController tag:SKFreeTextNote];
            [menu addItemWithTitle:NSLocalizedString(@"Anchored Note", @"Menu item title") imageNamed:SKImageNameToolbarAddAnchoredNote action:@selector(createNewNote:) target:mainController tag:SKAnchoredNote];
            [menu addItemWithTitle:NSLocalizedString(@"Circle", @"Menu item title") imageNamed:SKImageNameToolbarAddCircleNote action:@selector(createNewNote:) target:mainController tag:SKCircleNote];
            [menu addItemWithTitle:NSLocalizedString(@"Box", @"Menu item title") imageNamed:SKImageNameToolbarAddSquareNote action:@selector(createNewNote:) target:mainController tag:SKSquareNote];
            [menu addItemWithTitle:NSLocalizedString(@"Highlight", @"Menu item title") imageNamed:SKImageNameToolbarAddHighlightNote action:@selector(createNewNote:) target:mainController tag:SKHighlightNote];
            [menu addItemWithTitle:NSLocalizedString(@"Underline", @"Menu item title") imageNamed:SKImageNameToolbarAddUnderlineNote action:@selector(createNewNote:) target:mainController tag:SKUnderlineNote];
            [menu addItemWithTitle:NSLocalizedString(@"Strike Out", @"Menu item title") imageNamed:SKImageNameToolbarAddStrikeOutNote action:@selector(createNewNote:) target:mainController tag:SKStrikeOutNote];
            [menu addItemWithTitle:NSLocalizedString(@"Line", @"Menu item title") imageNamed:SKImageNameToolbarAddLineNote action:@selector(createNewNote:) target:mainController tag:SKLineNote];
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
            [item setViewWithSizes:noteButton];
            [item setMenuFormRepresentation:menuItem];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarToolModeItemIdentifier]) {
            
            menu = [NSMenu menu];
            [menu addItemWithTitle:NSLocalizedString(@"Text Note", @"Menu item title") imageNamed:SKImageNameTextNote action:@selector(changeAnnotationMode:) target:mainController tag:SKFreeTextNote];
            [menu addItemWithTitle:NSLocalizedString(@"Anchored Note", @"Menu item title") imageNamed:SKImageNameAnchoredNote action:@selector(changeAnnotationMode:) target:mainController tag:SKAnchoredNote];
            [menu addItemWithTitle:NSLocalizedString(@"Circle", @"Menu item title") imageNamed:SKImageNameCircleNote action:@selector(changeAnnotationMode:) target:mainController tag:SKCircleNote];
            [menu addItemWithTitle:NSLocalizedString(@"Box", @"Menu item title") imageNamed:SKImageNameSquareNote action:@selector(changeAnnotationMode:) target:mainController tag:SKSquareNote];
            [menu addItemWithTitle:NSLocalizedString(@"Highlight", @"Menu item title") imageNamed:SKImageNameHighlightNote action:@selector(changeAnnotationMode:) target:mainController tag:SKHighlightNote];
            [menu addItemWithTitle:NSLocalizedString(@"Underline", @"Menu item title") imageNamed:SKImageNameUnderlineNote action:@selector(changeAnnotationMode:) target:mainController tag:SKUnderlineNote];
            [menu addItemWithTitle:NSLocalizedString(@"Strike Out", @"Menu item title") imageNamed:SKImageNameStrikeOutNote action:@selector(changeAnnotationMode:) target:mainController tag:SKStrikeOutNote];
            [menu addItemWithTitle:NSLocalizedString(@"Line", @"Menu item title") imageNamed:SKImageNameLineNote action:@selector(changeAnnotationMode:) target:mainController tag:SKLineNote];
            [menu addItemWithTitle:NSLocalizedString(@"Freehand", @"Menu item title") imageNamed:SKImageNameInkNote action:@selector(changeAnnotationMode:) target:mainController tag:SKInkNote];
            [toolModeButton setMenu:menu forSegment:SKNoteToolMode];
            
            menu = [NSMenu menu];
            [menu addItemWithTitle:NSLocalizedString(@"Text Tool", @"Menu item title") action:@selector(changeToolMode:) target:mainController tag:SKTextToolMode];
            [menu addItemWithTitle:NSLocalizedString(@"Scroll Tool", @"Menu item title") action:@selector(changeToolMode:) target:mainController tag:SKMoveToolMode];
            [menu addItemWithTitle:NSLocalizedString(@"Magnify Tool", @"Menu item title") action:@selector(changeToolMode:) target:mainController tag:SKMagnifyToolMode];
            [menu addItemWithTitle:NSLocalizedString(@"Select Tool", @"Menu item title") action:@selector(changeToolMode:) target:mainController tag:SKSelectToolMode];
            [menu addItem:[NSMenuItem separatorItem]];
            [menu addItemWithTitle:NSLocalizedString(@"Text Note Tool", @"Menu item title") action:@selector(changeAnnotationMode:) target:mainController tag:SKFreeTextNote];
            [menu addItemWithTitle:NSLocalizedString(@"Anchored Note Tool", @"Menu item title") action:@selector(changeAnnotationMode:) target:mainController tag:SKAnchoredNote];
            [menu addItemWithTitle:NSLocalizedString(@"Circle Tool", @"Menu item title") action:@selector(changeAnnotationMode:) target:mainController tag:SKCircleNote];
            [menu addItemWithTitle:NSLocalizedString(@"Box Tool", @"Menu item title") action:@selector(changeAnnotationMode:) target:mainController tag:SKSquareNote];
            [menu addItemWithTitle:NSLocalizedString(@"Highlight Tool", @"Menu item title") action:@selector(changeAnnotationMode:) target:mainController tag:SKHighlightNote];
            [menu addItemWithTitle:NSLocalizedString(@"Underline Tool", @"Menu item title") action:@selector(changeAnnotationMode:) target:mainController tag:SKUnderlineNote];
            [menu addItemWithTitle:NSLocalizedString(@"Strike Out Tool", @"Menu item title") action:@selector(changeAnnotationMode:) target:mainController tag:SKStrikeOutNote];
            [menu addItemWithTitle:NSLocalizedString(@"Line Tool", @"Menu item title") action:@selector(changeAnnotationMode:) target:mainController tag:SKLineNote];
            [menu addItemWithTitle:NSLocalizedString(@"Freehand Tool", @"Menu item title") action:@selector(changeAnnotationMode:) target:mainController tag:SKInkNote];
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Tool Mode", @"Toolbar item label") submenu:menu] autorelease];
            
            [item setLabels:NSLocalizedString(@"Tool Mode", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Tool Mode", @"Tool tip message")];
            [toolModeButton setToolTip:NSLocalizedString(@"Text Tool", @"Tool tip message") forSegment:SKTextToolMode];
            [toolModeButton setToolTip:NSLocalizedString(@"Scroll Tool", @"Tool tip message") forSegment:SKMoveToolMode];
            [toolModeButton setToolTip:NSLocalizedString(@"Magnify Tool", @"Tool tip message") forSegment:SKMagnifyToolMode];
            [toolModeButton setToolTip:NSLocalizedString(@"Select Tool", @"Tool tip message") forSegment:SKSelectToolMode];
            [toolModeButton setToolTip:NSLocalizedString(@"Note Tool", @"Tool tip message") forSegment:SKNoteToolMode];
            [item setViewWithSizes:toolModeButton];
            [item setMenuFormRepresentation:menuItem];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarSingleTwoUpItemIdentifier]) {
            
            menu = [NSMenu menu];
            [menu addItemWithTitle:NSLocalizedString(@"Single Page", @"Menu item title") action:@selector(changeDisplaySinglePages:) target:mainController tag:kPDFDisplaySinglePage];
            [menu addItemWithTitle:NSLocalizedString(@"Two Pages", @"Menu item title") action:@selector(changeDisplaySinglePages:) target:mainController tag:kPDFDisplayTwoUp];
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Single/Two Pages", @"Toolbar item label") submenu:menu] autorelease];
            
            [item setLabels:NSLocalizedString(@"Single/Two Pages", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Single/Two Pages", @"Tool tip message")];
            [singleTwoUpButton setToolTip:NSLocalizedString(@"Single Page", @"Tool tip message") forSegment:0];
            [singleTwoUpButton setToolTip:NSLocalizedString(@"Two Pages", @"Tool tip message") forSegment:1];
            [item setViewWithSizes:singleTwoUpButton];
            [item setMenuFormRepresentation:menuItem];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarContinuousItemIdentifier]) {
            
            menu = [NSMenu menu];
            [menu addItemWithTitle:NSLocalizedString(@"Non Continuous", @"Menu item title") action:@selector(changeDisplayContinuous:) target:mainController tag:kPDFDisplaySinglePage];
            [menu addItemWithTitle:NSLocalizedString(@"Continuous", @"Menu item title") action:@selector(changeDisplayContinuous:) target:mainController tag:kPDFDisplaySinglePageContinuous];
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Continuous", @"Toolbar item label") submenu:menu] autorelease];
            
            [item setLabels:NSLocalizedString(@"Continuous", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Continuous", @"Tool tip message")];
            [continuousButton setToolTip:NSLocalizedString(@"Non Continuous", @"Tool tip message") forSegment:0];
            [continuousButton setToolTip:NSLocalizedString(@"Continuous", @"Tool tip message") forSegment:1];
            [item setViewWithSizes:continuousButton];
            [item setMenuFormRepresentation:menuItem];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarDisplayModeItemIdentifier]) {
            
            menu = [NSMenu menu];
            [menu addItemWithTitle:NSLocalizedString(@"Single Page", @"Menu item title") action:@selector(changeDisplayMode:) target:mainController tag:kPDFDisplaySinglePage];
            [menu addItemWithTitle:NSLocalizedString(@"Single Page Continuous", @"Menu item title") action:@selector(changeDisplayMode:) target:mainController tag:kPDFDisplaySinglePageContinuous];
            [menu addItemWithTitle:NSLocalizedString(@"Two Pages", @"Menu item title") action:@selector(changeDisplayMode:) target:mainController tag:kPDFDisplayTwoUp];
            [menu addItemWithTitle:NSLocalizedString(@"Two Pages Continuous", @"Menu item title") action:@selector(changeDisplayMode:) target:mainController tag:kPDFDisplayTwoUpContinuous];
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Display Mode", @"Toolbar item label") submenu:menu] autorelease];
            
            [item setLabels:NSLocalizedString(@"Display Mode", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Display Mode", @"Tool tip message")];
            [displayModeButton setToolTip:NSLocalizedString(@"Single Page", @"Tool tip message") forSegment:kPDFDisplaySinglePage];
            [displayModeButton setToolTip:NSLocalizedString(@"Single Page Continuous", @"Tool tip message") forSegment:kPDFDisplaySinglePageContinuous];
            [displayModeButton setToolTip:NSLocalizedString(@"Two Pages", @"Tool tip message") forSegment:kPDFDisplayTwoUp];
            [displayModeButton setToolTip:NSLocalizedString(@"Two Pages Continuous", @"Tool tip message") forSegment:kPDFDisplayTwoUpContinuous];
            [item setViewWithSizes:displayModeButton];
            [item setMenuFormRepresentation:menuItem];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarDisplayBoxItemIdentifier]) {
            
            menu = [NSMenu menu];
            [menu addItemWithTitle:NSLocalizedString(@"Media Box", @"Menu item title") action:@selector(changeDisplayBox:) target:mainController tag:kPDFDisplayBoxMediaBox];
            [menu addItemWithTitle:NSLocalizedString(@"Crop Box", @"Menu item title") action:@selector(changeDisplayBox:) target:mainController tag:kPDFDisplayBoxCropBox];
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Display Box", @"Toolbar item label") submenu:menu] autorelease];
            
            [item setLabels:NSLocalizedString(@"Display Box", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Display Box", @"Tool tip message")];
            [item setViewWithSizes:displayBoxButton];
            [item setMenuFormRepresentation:menuItem];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarColorSwatchItemIdentifier]) {
            
            NSDictionary *options = [NSDictionary dictionaryWithObject:SKUnarchiveFromDataArrayTransformerName forKey:NSValueTransformerNameBindingOption];
            [colorSwatch bind:@"colors" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:[NSString stringWithFormat:@"values.%@", SKSwatchColorsKey] options:options];
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
            [item setViewWithSizes:colorsButton];
            [item setMenuFormRepresentation:menuItem];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarFontsItemIdentifier]) {
            
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Fonts", @"Menu item title") action:@selector(orderFrontFontPanel:) keyEquivalent:@""] autorelease];
            
            [item setLabels:NSLocalizedString(@"Fonts", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Fonts", @"Tool tip message")];
            [item setImageNamed:@"ToolbarFonts"];
            [item setViewWithSizes:fontsButton];
            [item setMenuFormRepresentation:menuItem];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarLinesItemIdentifier]) {
            
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Lines", @"Menu item title") action:@selector(orderFrontLineInspector:) keyEquivalent:@""] autorelease];
            
            [item setLabels:NSLocalizedString(@"Lines", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Lines", @"Tool tip message")];
            [item setViewWithSizes:linesButton];
            [item setMenuFormRepresentation:menuItem];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarInfoItemIdentifier]) {
            
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Info", @"Menu item title") action:@selector(getInfo:) target:mainController] autorelease];
            
            [item setLabels:NSLocalizedString(@"Info", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Get Document Info", @"Tool tip message")];
            [item setViewWithSizes:infoButton];
            [item setMenuFormRepresentation:menuItem];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarContentsPaneItemIdentifier]) {
            
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Contents Pane", @"Menu item title") action:@selector(toggleLeftSidePane:) target:mainController] autorelease];
            
            [item setLabels:NSLocalizedString(@"Contents Pane", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Toggle Contents Pane", @"Tool tip message")];
            [item setViewWithSizes:leftPaneButton];
            [item setMenuFormRepresentation:menuItem];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarNotesPaneItemIdentifier]) {
            
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Notes Pane", @"Menu item title") action:@selector(toggleRightSidePane:) target:mainController] autorelease];
            
            [item setLabels:NSLocalizedString(@"Notes Pane", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Toggle Notes Pane", @"Tool tip message")];
            [item setViewWithSizes:rightPaneButton];
            [item setMenuFormRepresentation:menuItem];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarPrintItemIdentifier]) {
            
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Print", @"Menu item title") action:@selector(printDocument:) keyEquivalent:@""] autorelease];
            
            [item setLabels:NSLocalizedString(@"Print", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Print Document", @"Tool tip message")];
            [item setViewWithSizes:printButton];
            [item setMenuFormRepresentation:menuItem];
            
        } else if ([identifier isEqualToString:SKDocumentToolbarCustomizeItemIdentifier]) {
            
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Customize", @"Menu item title") action:@selector(runToolbarCustomizationPalette:) keyEquivalent:@""] autorelease];
            
            [item setLabels:NSLocalizedString(@"Customize", @"Toolbar item label")];
            [item setToolTip:NSLocalizedString(@"Customize Toolbar", @"Tool tip message")];
            [item setViewWithSizes:customizeButton];
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
    
    if ([[toolbarItem toolbar] customizationPaletteIsRunning]) {
        return NO;
    } else if ([identifier isEqualToString:SKDocumentToolbarZoomActualItemIdentifier]) {
        return fabs([mainController.pdfView scaleFactor] - 1.0 ) > 0.01;
    } else if ([identifier isEqualToString:SKDocumentToolbarZoomToFitItemIdentifier]) {
        return [mainController.pdfView autoScales] == NO;
    } else if ([identifier isEqualToString:SKDocumentToolbarZoomToSelectionItemIdentifier]) {
        return NSIsEmptyRect([mainController.pdfView currentSelectionRect]) == NO;
    } else if ([identifier isEqualToString:SKDocumentToolbarNewTextNoteItemIdentifier] || [identifier isEqualToString:SKDocumentToolbarNewCircleNoteItemIdentifier] || [identifier isEqualToString:SKDocumentToolbarNewLineItemIdentifier]) {
        return ([mainController.pdfView toolMode] == SKTextToolMode || [mainController.pdfView toolMode] == SKNoteToolMode) && [mainController.pdfView hideNotes] == NO;
    } else if ([identifier isEqualToString:SKDocumentToolbarNewMarkupItemIdentifier]) {
        return ([mainController.pdfView toolMode] == SKTextToolMode || [mainController.pdfView toolMode] == SKNoteToolMode) && [mainController.pdfView hideNotes] == NO && [[mainController.pdfView currentSelection] hasCharacters];
    } else if ([identifier isEqualToString:SKDocumentToolbarNewNoteItemIdentifier]) {
        BOOL enabled = ([mainController.pdfView toolMode] == SKTextToolMode || [mainController.pdfView toolMode] == SKNoteToolMode) && [mainController.pdfView hideNotes] == NO && [[mainController.pdfView currentSelection] hasCharacters];
        [noteButton setEnabled:enabled forSegment:SKHighlightNote];
        [noteButton setEnabled:enabled forSegment:SKUnderlineNote];
        [noteButton setEnabled:enabled forSegment:SKStrikeOutNote];
        return ([mainController.pdfView toolMode] == SKTextToolMode || [mainController.pdfView toolMode] == SKNoteToolMode) && [mainController.pdfView hideNotes] == NO;
    }
    return YES;
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    SEL action = [menuItem action];
    if (action == @selector(createNewTextNote:)) {
        [menuItem setState:[[textNoteButton cell] tagForSegment:0] == [menuItem tag] ? NSOnState : NSOffState];
        return [mainController isPresentation] == NO && ([pdfView toolMode] == SKTextToolMode || [pdfView toolMode] == SKNoteToolMode) && [pdfView hideNotes] == NO;
    } else if (action == @selector(createNewCircleNote:)) {
        [menuItem setState:[[circleNoteButton cell] tagForSegment:0] == [menuItem tag] ? NSOnState : NSOffState];
        return [mainController isPresentation] == NO && ([pdfView toolMode] == SKTextToolMode || [pdfView toolMode] == SKNoteToolMode) && [pdfView hideNotes] == NO;
    } else if (action == @selector(createNewMarkupNote:)) {
        [menuItem setState:[[markupNoteButton cell] tagForSegment:0] == [menuItem tag] ? NSOnState : NSOffState];
        return [mainController isPresentation] == NO && ([pdfView toolMode] == SKTextToolMode || [pdfView toolMode] == SKNoteToolMode) && [pdfView hideNotes] == NO && [[pdfView currentSelection] hasCharacters];
    }
    return YES;
}

- (void)handleColorSwatchColorsChangedNotification:(NSNotification *)notification {
    NSToolbarItem *toolbarItem = [self toolbarItemForItemIdentifier:SKDocumentToolbarColorSwatchItemIdentifier];
    NSMenu *menu = [[toolbarItem menuFormRepresentation] submenu];
    
    NSRect rect = NSMakeRect(0.0, 0.0, 16.0, 16.0);
    NSRect lineRect = NSInsetRect(rect, 0.5, 0.5);
    NSRect swatchRect = NSInsetRect(rect, 1.0, 1.0);
    
    [menu removeAllItems];
    
    for (NSColor *color in [colorSwatch colors]) {
        NSImage *image = [[NSImage alloc] initWithSize:rect.size];
        NSMenuItem *item = [menu addItemWithTitle:@"" action:@selector(selectColor:) target:self];
        
        [image lockFocus];
        [[NSColor lightGrayColor] setStroke];
        [NSBezierPath setDefaultLineWidth:1.0];
        [NSBezierPath strokeRect:lineRect];
        [color drawSwatchInRect:swatchRect];
        [image unlockFocus];
        [item setRepresentedObject:color];
        [item setImage:image];
        [image release];
    }
    
    NSSize size = [colorSwatch bounds].size;
    [toolbarItem setMinSize:size];
    [toolbarItem setMaxSize:size];
}

- (IBAction)goToPreviousNextFirstLastPage:(id)sender {
    NSInteger tag = [sender selectedTag];
    if (tag == -1)
        [pdfView goToPreviousPage:sender];
    else if (tag == 1)
        [pdfView goToNextPage:sender];
    else if (tag == -2)
        [pdfView goToFirstPage:sender];
    else if (tag == 2)
        [pdfView goToLastPage:sender];
}

- (IBAction)goBackOrForward:(id)sender {
    if ([sender selectedSegment] == 1)
        [pdfView goForward:sender];
    else
        [pdfView goBack:sender];
}

- (IBAction)changeScaleFactor:(id)sender {
    NSInteger scale = [sender integerValue];

	if (scale >= 10.0 && scale <= 500.0 ) {
		[pdfView setScaleFactor:scale / 100.0f];
		[pdfView setAutoScales:NO];
	}
}

- (void)scaleSheetDidEnd:(SKScaleSheetController *)controller returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSOKButton)
        [pdfView setScaleFactor:[[controller textField] integerValue]];
}

- (IBAction)chooseScale:(id)sender {
    SKScaleSheetController *scaleSheetController = [[[SKScaleSheetController alloc] init] autorelease];
    
    [[scaleSheetController textField] setIntegerValue:[pdfView scaleFactor]];
    
    [scaleSheetController beginSheetModalForWindow: [mainController window]
        modalDelegate: self
       didEndSelector: @selector(scaleSheetDidEnd:returnCode:contextInfo:)
          contextInfo: nil];
}

- (IBAction)zoomInActualOut:(id)sender {
    NSInteger tag = [sender selectedTag];
    if (tag == -1)
        [pdfView zoomOut:sender];
    else if (tag == 0)
        [pdfView setScaleFactor:1.0];
    else if (tag == 1)
        [pdfView zoomIn:sender];
}

- (IBAction)zoomToFit:(id)sender {
    [pdfView setAutoScales:YES];
    [pdfView setAutoScales:NO];
}

- (IBAction)zoomToSelection:(id)sender {
    [mainController doZoomToSelection:sender];
}

- (IBAction)rotateAllLeftRight:(id)sender {
    if ([sender selectedSegment] == 1)
        [mainController rotateAllRight:sender];
    else
        [mainController rotateAllLeft:sender];
}

- (IBAction)cropAll:(id)sender {
    [mainController cropAll:sender];
}

- (IBAction)enterFullScreen:(id)sender {
    [mainController enterFullScreen:sender];
}

- (IBAction)enterPresentation:(id)sender {
    [mainController enterPresentation:sender];
}

- (IBAction)toggleLeftSidePane:(id)sender {
    [mainController toggleLeftSidePane:sender];
}

- (IBAction)toggleRightSidePane:(id)sender {
    [mainController toggleRightSidePane:sender];
}

- (IBAction)changeDisplayBox:(id)sender {
    PDFDisplayBox displayBox = [sender selectedSegment];
    [pdfView setDisplayBox:displayBox];
}

- (IBAction)changeDisplaySinglePages:(id)sender {
    PDFDisplayMode tag = [sender selectedTag];
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

- (IBAction)changeDisplayContinuous:(id)sender {
    PDFDisplayMode tag = [sender selectedTag];
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
    PDFDisplayMode displayMode = [sender selectedTag];
    [pdfView setDisplayMode:displayMode];
}

- (void)createNewTextNote:(id)sender {
    if ([pdfView hideNotes] == NO) {
        NSInteger type = [sender tag];
        [pdfView addAnnotationWithType:type];
        if (type != [[textNoteButton cell] tagForSegment:0]) {
            [[textNoteButton cell] setTag:type forSegment:0];
            NSString *imgName = type == SKFreeTextNote ? SKImageNameToolbarAddTextNoteMenu : SKImageNameToolbarAddAnchoredNoteMenu;
            [textNoteButton setImage:[NSImage imageNamed:imgName] forSegment:0];
        }
    } else NSBeep();
}

- (void)createNewCircleNote:(id)sender {
    if ([pdfView hideNotes] == NO) {
        NSInteger type = [sender tag];
        [pdfView addAnnotationWithType:type];
        if (type != [[circleNoteButton cell] tagForSegment:0]) {
            [[circleNoteButton cell] setTag:type forSegment:0];
            NSString *imgName = type == SKCircleNote ? SKImageNameToolbarAddCircleNoteMenu : SKImageNameToolbarAddSquareNoteMenu;
            [circleNoteButton setImage:[NSImage imageNamed:imgName] forSegment:0];
        }
    } else NSBeep();
}

- (void)createNewMarkupNote:(id)sender {
    if ([pdfView hideNotes] == NO) {
        NSInteger type = [sender tag];
        [pdfView addAnnotationWithType:type];
        if (type != [[markupNoteButton cell] tagForSegment:0]) {
            [[markupNoteButton cell] setTag:type forSegment:0];
            NSString *imgName = type == SKHighlightNote ? SKImageNameToolbarAddHighlightNoteMenu : SKUnderlineNote ? SKImageNameToolbarAddUnderlineNoteMenu : SKImageNameToolbarAddStrikeOutNoteMenu;
            [markupNoteButton setImage:[NSImage imageNamed:imgName] forSegment:0];
        }
    } else NSBeep();
}

- (IBAction)createNewNote:(id)sender {
    if ([pdfView hideNotes] == NO) {
        NSInteger type = [sender selectedSegment];
        [pdfView addAnnotationWithType:type];
    } else NSBeep();
}

- (IBAction)changeToolMode:(id)sender {
    NSInteger newToolMode = [sender selectedSegment];
    [pdfView setToolMode:newToolMode];
}

- (IBAction)selectColor:(id)sender {
    PDFAnnotation *annotation = [pdfView activeAnnotation];
    if ([annotation isSkimNote]) {
        BOOL isFill = ([NSEvent standardModifierFlags] & NSAlternateKeyMask) != 0 && [annotation respondsToSelector:@selector(setInteriorColor:)];
        BOOL isText = ([NSEvent standardModifierFlags] & NSAlternateKeyMask) != 0 && [annotation respondsToSelector:@selector(setFontColor:)];
        NSColor *color = (isFill ? [(id)annotation interiorColor] : (isText ? [(id)annotation fontColor] : [annotation color])) ?: [NSColor clearColor];
        NSColor *newColor = [sender respondsToSelector:@selector(representedObject)] ? [sender representedObject] : [sender respondsToSelector:@selector(color)] ? [sender color] : nil;
        if (newColor && [color isEqual:newColor] == NO) {
            if (isFill)
                [(id)annotation setInteriorColor:[newColor alphaComponent] > 0.0 ? newColor : nil];
            else if (isText)
                [(id)annotation setFontColor:[newColor alphaComponent] > 0.0 ? newColor : nil];
            else
                [annotation setColor:newColor];
        }
    }
}

#pragma mark Notifications

- (void)handleChangedHistoryNotification:(NSNotification *)notification {
    [backForwardButton setEnabled:[pdfView canGoBack] forSegment:0];
    [backForwardButton setEnabled:[pdfView canGoForward] forSegment:1];
}

- (void)handlePageChangedNotification:(NSNotification *)notification {
    [previousNextPageButton setEnabled:[pdfView canGoToPreviousPage] forSegment:0];
    [previousNextPageButton setEnabled:[pdfView canGoToNextPage] forSegment:1];
    [previousPageButton setEnabled:[pdfView canGoToFirstPage] forSegment:0];
    [previousPageButton setEnabled:[pdfView canGoToPreviousPage] forSegment:1];
    [nextPageButton setEnabled:[pdfView canGoToNextPage] forSegment:0];
    [nextPageButton setEnabled:[pdfView canGoToLastPage] forSegment:1];
    [previousNextFirstLastPageButton setEnabled:[pdfView canGoToFirstPage] forSegment:0];
    [previousNextFirstLastPageButton setEnabled:[pdfView canGoToPreviousPage] forSegment:1];
    [previousNextFirstLastPageButton setEnabled:[pdfView canGoToNextPage] forSegment:2];
    [previousNextFirstLastPageButton setEnabled:[pdfView canGoToLastPage] forSegment:3];
}

- (void)handleScaleChangedNotification:(NSNotification *)notification {
    [scaleField setDoubleValue:[pdfView scaleFactor] * 100.0];
    
    [zoomInOutButton setEnabled:[pdfView canZoomOut] forSegment:0];
    [zoomInOutButton setEnabled:[pdfView canZoomIn] forSegment:1];
    [zoomInActualOutButton setEnabled:[pdfView canZoomOut] forSegment:0];
    [zoomInActualOutButton setEnabled:fabs([pdfView scaleFactor] - 1.0 ) > 0.01 forSegment:1];
    [zoomInActualOutButton setEnabled:[pdfView canZoomIn] forSegment:2];
    [zoomActualButton setEnabled:fabs([pdfView scaleFactor] - 1.0 ) > 0.01];
}

- (void)handleToolModeChangedNotification:(NSNotification *)notification {
    [toolModeButton selectSegmentWithTag:[pdfView toolMode]];
}

- (void)handleDisplayBoxChangedNotification:(NSNotification *)notification {
    [displayBoxButton selectSegmentWithTag:[pdfView displayBox]];
}

- (void)handleDisplayModeChangedNotification:(NSNotification *)notification {
    PDFDisplayMode displayMode = [pdfView displayMode];
    [displayModeButton selectSegmentWithTag:displayMode];
    [singleTwoUpButton selectSegmentWithTag:(displayMode == kPDFDisplaySinglePage || displayMode == kPDFDisplaySinglePageContinuous) ? kPDFDisplaySinglePage : kPDFDisplayTwoUp];
    [continuousButton selectSegmentWithTag:(displayMode == kPDFDisplaySinglePage || displayMode == kPDFDisplayTwoUp) ? kPDFDisplaySinglePage : kPDFDisplaySinglePageContinuous];
}

- (void)handleAnnotationModeChangedNotification:(NSNotification *)notification {
    [toolModeButton setImage:[NSImage imageNamed:noteToolImageNames[[pdfView annotationMode]]] forSegment:SKNoteToolMode];
}

- (void)registerForNotifications {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    [nc addObserver:self selector:@selector(handlePageChangedNotification:) 
                             name:PDFViewPageChangedNotification object:pdfView];
    [nc addObserver:self selector:@selector(handleScaleChangedNotification:) 
                             name:PDFViewScaleChangedNotification object:pdfView];
    [nc addObserver:self selector:@selector(handleToolModeChangedNotification:) 
                             name:SKPDFViewToolModeChangedNotification object:pdfView];
    [nc addObserver:self selector:@selector(handleAnnotationModeChangedNotification:) 
                             name:SKPDFViewAnnotationModeChangedNotification object:pdfView];
    [nc addObserver:self selector:@selector(handleDisplayModeChangedNotification:) 
                             name:PDFViewDisplayModeChangedNotification object:pdfView];
    [nc addObserver:self selector:@selector(handleDisplayBoxChangedNotification:) 
                             name:PDFViewDisplayBoxChangedNotification object:pdfView];
    [nc addObserver:self selector:@selector(handleChangedHistoryNotification:) 
                             name:PDFViewChangedHistoryNotification object:pdfView];
    
    [self handleChangedHistoryNotification:nil];
    [self handlePageChangedNotification:nil];
    [self handleScaleChangedNotification:nil];
    [self handleToolModeChangedNotification:nil];
    [self handleDisplayBoxChangedNotification:nil];
    [self handleDisplayModeChangedNotification:nil];
    [self handleAnnotationModeChangedNotification:nil];
}

@end
