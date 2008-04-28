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

@implementation SKMainWindowController (Toolbar)

+ (void)load {
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    [NSValueTransformer setValueTransformer:[[[SKUnarchiveFromDataArrayTransformer alloc] init] autorelease] forName:SKUnarchiveFromDataArrayTransformerName];
    [pool release];
}

- (void)handleColorSwatchColorsChangedNotification:(NSNotification *)notification {
    NSToolbarItem *toolbarItem = [toolbarItems objectForKey:SKDocumentToolbarColorSwatchItemIdentifier];
    NSMenu *menu = [[toolbarItem menuFormRepresentation] submenu];
    
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

- (void)setupToolbar {
    // Create a new toolbar instance, and attach it to our document window
    NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier:SKDocumentToolbarIdentifier] autorelease];
    SKToolbarItem *item;
    NSMenu *menu;
    NSMenuItem *menuItem;
    
    toolbarItems = [[NSMutableDictionary alloc] init];
    
    // Set up toolbar properties: Allow customization, give a default display mode, and remember state in user defaults
    [toolbar setAllowsUserCustomization: YES];
    [toolbar setAutosavesConfiguration: YES];
    [toolbar setDisplayMode: NSToolbarDisplayModeDefault];
    
    // We are the delegate
    [toolbar setDelegate: self];
    
    // Add template toolbar items
    
#pragma mark SKDocumentToolbarPreviousNextItemIdentifier
    
    menu = [[[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:@""] autorelease];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Previous", @"Menu item title") action:@selector(doGoToPreviousPage:) keyEquivalent:@""];
	[menuItem setTarget:self];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Next", @"Menu item title") action:@selector(doGoToNextPage:) keyEquivalent:@""];
	[menuItem setTarget:self];
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Previous/Next", @"Toolbar item label") action:NULL keyEquivalent:@""] autorelease];
    [menuItem setSubmenu:menu];
    
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarPreviousNextItemIdentifier];
    [item setLabels:NSLocalizedString(@"Previous/Next", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Previous/Next", @"Tool tip message")];
    [previousNextPageButton setToolTip:NSLocalizedString(@"Go To Previous Page", @"Tool tip message") forSegment:0];
    [previousNextPageButton setToolTip:NSLocalizedString(@"Go To Next Page", @"Tool tip message") forSegment:1];
    [previousNextPageButton makeCapsule];
    [item setViewWithSizes:previousNextPageButton];
    [item setMenuFormRepresentation:menuItem];
    [toolbarItems setObject:item forKey:SKDocumentToolbarPreviousNextItemIdentifier];
    [item release];
    
#pragma mark SKDocumentToolbarPreviousItemIdentifier
    
    menu = [[[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:@""] autorelease];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Previous", @"Menu item title") action:@selector(doGoToPreviousPage:) keyEquivalent:@""];
	[menuItem setTarget:self];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"First", @"Menu item title") action:@selector(doGoToFirstPage:) keyEquivalent:@""];
	[menuItem setTarget:self];
    
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarPreviousItemIdentifier];
    [item setLabels:NSLocalizedString(@"Previous", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Go To Previous Page", @"Tool tip message")];
    [previousPageButton setToolTip:NSLocalizedString(@"Go To First page", @"Tool tip message") forSegment:0];
    [previousPageButton setToolTip:NSLocalizedString(@"Go To Previous Page", @"Tool tip message") forSegment:1];
    [previousPageButton makeCapsule];
    [item setViewWithSizes:previousPageButton];
    [item setMenuFormRepresentation:menuItem];
    [toolbarItems setObject:item forKey:SKDocumentToolbarPreviousItemIdentifier];
    [item release];
    
#pragma mark SKDocumentToolbarNextItemIdentifier
    
    menu = [[[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:@""] autorelease];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Next", @"Menu item title") action:@selector(doGoToNextPage:) keyEquivalent:@""];
	[menuItem setTarget:self];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Last", @"Menu item title") action:@selector(doGoToLastPage:) keyEquivalent:@""];
	[menuItem setTarget:self];
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Page", @"Toolbar item label") action:NULL keyEquivalent:@""] autorelease];
    [menuItem setSubmenu:menu];
    
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarNextItemIdentifier];
    [item setLabels:NSLocalizedString(@"Next", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Go To Next Page", @"Tool tip message")];
    [nextPageButton setToolTip:NSLocalizedString(@"Go To Next Page", @"Tool tip message") forSegment:0];
    [nextPageButton setToolTip:NSLocalizedString(@"Go To Last page", @"Tool tip message") forSegment:1];
    [nextPageButton makeCapsule];
    [item setViewWithSizes:nextPageButton];
    [item setMenuFormRepresentation:menuItem];
    [toolbarItems setObject:item forKey:SKDocumentToolbarNextItemIdentifier];
    [item release];
    
#pragma mark SKDocumentToolbarPreviousNextFirstLastItemIdentifier
    
    menu = [[[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:@""] autorelease];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Previous", @"Menu item title") action:@selector(doGoToPreviousPage:) keyEquivalent:@""];
	[menuItem setTarget:self];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Next", @"Menu item title") action:@selector(doGoToNextPage:) keyEquivalent:@""];
	[menuItem setTarget:self];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"First", @"Menu item title") action:@selector(doGoToFirstPage:) keyEquivalent:@""];
	[menuItem setTarget:self];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Last", @"Menu item title") action:@selector(doGoToLastPage:) keyEquivalent:@""];
	[menuItem setTarget:self];
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Previous/Next", @"Toolbar item label") action:NULL keyEquivalent:@""] autorelease];
    [menuItem setSubmenu:menu];
    
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarPreviousNextFirstLastItemIdentifier];
    [item setLabels:NSLocalizedString(@"Previous/Next", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Go To First, Previous, Next or Last Page", @"Tool tip message")];
    [previousNextFirstLastPageButton setToolTip:NSLocalizedString(@"Go To First page", @"Tool tip message") forSegment:0];
    [previousNextFirstLastPageButton setToolTip:NSLocalizedString(@"Go To Previous Page", @"Tool tip message") forSegment:1];
    [previousNextFirstLastPageButton setToolTip:NSLocalizedString(@"Go To Next Page", @"Tool tip message") forSegment:2];
    [previousNextFirstLastPageButton setToolTip:NSLocalizedString(@"Go To Last page", @"Tool tip message") forSegment:3];
    [previousNextFirstLastPageButton makeCapsule];
    [item setViewWithSizes:previousNextFirstLastPageButton];
    [item setMenuFormRepresentation:menuItem];
    [toolbarItems setObject:item forKey:SKDocumentToolbarPreviousNextFirstLastItemIdentifier];
    [item release];
    
#pragma mark SKDocumentToolbarBackForwardItemIdentifier
    
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
    [backForwardButton setToolTip:NSLocalizedString(@"Go Back", @"Tool tip message") forSegment:0];
    [backForwardButton setToolTip:NSLocalizedString(@"Go Forward", @"Tool tip message") forSegment:1];
    [backForwardButton makeCapsule];
    [item setViewWithSizes:backForwardButton];
    [item setMenuFormRepresentation:menuItem];
    [toolbarItems setObject:item forKey:SKDocumentToolbarBackForwardItemIdentifier];
    [item release];
    
#pragma mark SKDocumentToolbarPageNumberItemIdentifier
	
    menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Page", @"Menu item title") action:@selector(doGoToPage:) keyEquivalent:@""] autorelease];
	[menuItem setTarget:self];
    
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarPageNumberItemIdentifier];
    [item setLabels:NSLocalizedString(@"Page", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Go To Page", @"Tool tip message")];
    [item setViewWithSizes:pageNumberField];
    [item setMenuFormRepresentation:menuItem];
    [toolbarItems setObject:item forKey:SKDocumentToolbarPageNumberItemIdentifier];
    [item release];
    
#pragma mark SKDocumentToolbarScaleItemIdentifier
	
    menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Scale", @"Menu item title") action:@selector(chooseScale:) keyEquivalent:@""] autorelease];
	[menuItem setTarget:self];
    
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarScaleItemIdentifier];
    [item setLabels:NSLocalizedString(@"Scale", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Scale", @"Tool tip message")];
    [item setViewWithSizes:scaleField];
    [item setMenuFormRepresentation:menuItem];
    [toolbarItems setObject:item forKey:SKDocumentToolbarScaleItemIdentifier];
    [item release];
    
#pragma mark SKDocumentToolbarZoomActualItemIdentifier
	
    menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Actual Size", @"Menu item title") action:@selector(doZoomToActualSize:) keyEquivalent:@""] autorelease];
	[menuItem setTarget:self];
    
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarZoomActualItemIdentifier];
    [item setLabels:NSLocalizedString(@"Actual Size", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Zoom To Actual Size", @"Tool tip message")];
    [zoomActualButton makeCapsule];
    [item setViewWithSizes:zoomActualButton];
    [item setMenuFormRepresentation:menuItem];
    [toolbarItems setObject:item forKey:SKDocumentToolbarZoomActualItemIdentifier];
    [item release];
    
#pragma mark SKDocumentToolbarZoomToFitItemIdentifier
	
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Zoom To Fit", @"Menu item title") action:@selector(doZoomToFit:) keyEquivalent:@""] autorelease];
	[menuItem setTarget:self];
    
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarZoomToFitItemIdentifier];
    [item setLabels:NSLocalizedString(@"Zoom To Fit", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Zoom To Fit", @"Tool tip message")];
    [zoomFitButton makeCapsule];
    [item setViewWithSizes:zoomFitButton];
    [item setMenuFormRepresentation:menuItem];
    [toolbarItems setObject:item forKey:SKDocumentToolbarZoomToFitItemIdentifier];
    [item release];
    
#pragma mark SKDocumentToolbarZoomToSelectionItemIdentifier
	
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Zoom To Selection", @"Menu item title") action:@selector(doZoomToSelection:) keyEquivalent:@""] autorelease];
	[menuItem setTarget:self];
    
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarZoomToSelectionItemIdentifier];
    [item setLabels:NSLocalizedString(@"Zoom To Selection", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Zoom To Selection", @"Tool tip message")];
    [zoomSelectionButton makeCapsule];
    [item setViewWithSizes:zoomSelectionButton];
    [item setMenuFormRepresentation:menuItem];
    [toolbarItems setObject:item forKey:SKDocumentToolbarZoomToSelectionItemIdentifier];
    [item release];
    
#pragma mark SKDocumentToolbarZoomInOutItemIdentifier
	
    menu = [[[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:@""] autorelease];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Zoom In", @"Menu item title") action:@selector(doZoomIn:) keyEquivalent:@""];
	[menuItem setTarget:self];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Zoom Out", @"Menu item title") action:@selector(doZoomOut:) keyEquivalent:@""];
	[menuItem setTarget:self];
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Zoom", @"Toolbar item label") action:NULL keyEquivalent:@""] autorelease];
    [menuItem setSubmenu:menu];
    
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarZoomInOutItemIdentifier];
    [item setLabels:NSLocalizedString(@"Zoom", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Zoom", @"Tool tip message")];
    [zoomInOutButton setToolTip:NSLocalizedString(@"Zoom Out", @"Tool tip message") forSegment:0];
    [zoomInOutButton setToolTip:NSLocalizedString(@"Zoom In", @"Tool tip message") forSegment:1];
    [zoomInOutButton makeCapsule];
    [item setViewWithSizes:zoomInOutButton];
    [item setMenuFormRepresentation:menuItem];
    [toolbarItems setObject:item forKey:SKDocumentToolbarZoomInOutItemIdentifier];
    [item release];
    
#pragma mark SKDocumentToolbarZoomInActualOutItemIdentifier
	
    menu = [[[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:@""] autorelease];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Zoom In", @"Menu item title") action:@selector(doZoomIn:) keyEquivalent:@""];
	[menuItem setTarget:self];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Zoom Out", @"Menu item title") action:@selector(doZoomOut:) keyEquivalent:@""];
	[menuItem setTarget:self];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Actual Size", @"Menu item title") action:@selector(doZoomToActualSize:) keyEquivalent:@""];
	[menuItem setTarget:self];
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Zoom", @"Toolbar item label") action:NULL keyEquivalent:@""] autorelease];
    [menuItem setSubmenu:menu];
    
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarZoomInActualOutItemIdentifier];
    [item setLabels:NSLocalizedString(@"Zoom", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Zoom", @"Tool tip message")];
    [zoomInActualOutButton setToolTip:NSLocalizedString(@"Zoom Out", @"Tool tip message") forSegment:0];
    [zoomInActualOutButton setToolTip:NSLocalizedString(@"Zoom To Actual Size", @"Tool tip message") forSegment:1];
    [zoomInActualOutButton setToolTip:NSLocalizedString(@"Zoom In", @"Tool tip message") forSegment:2];
    [zoomInActualOutButton makeCapsule];
    [item setViewWithSizes:zoomInActualOutButton];
    [item setMenuFormRepresentation:menuItem];
    [toolbarItems setObject:item forKey:SKDocumentToolbarZoomInActualOutItemIdentifier];
    [item release];
    
#pragma mark SKDocumentToolbarRotateRightItemIdentifier
	
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Rotate Right", @"Menu item title") action:@selector(rotateAllRight:) keyEquivalent:@""] autorelease];
	[menuItem setTarget:self];
    
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarRotateRightItemIdentifier];
    [item setLabels:NSLocalizedString(@"Rotate Right", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Rotate Right", @"Tool tip message")];
    [rotateRightButton makeCapsule];
    [item setViewWithSizes:rotateRightButton];
    [toolbarItems setObject:item forKey:SKDocumentToolbarRotateRightItemIdentifier];
    [item release];
    
#pragma mark SKDocumentToolbarRotateLeftItemIdentifier
	
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Rotate Left", @"Menu item title") action:@selector(rotateAllLeft:) keyEquivalent:@""] autorelease];
	[menuItem setTarget:self];
    
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarRotateLeftItemIdentifier];
    [item setLabels:NSLocalizedString(@"Rotate Left", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Rotate Left", @"Tool tip message")];
    [rotateLeftButton makeCapsule];
    [item setViewWithSizes:rotateLeftButton];
    [item setMenuFormRepresentation:menuItem];
    [toolbarItems setObject:item forKey:SKDocumentToolbarRotateLeftItemIdentifier];
    [item release];
    
#pragma mark SKDocumentToolbarRotateLeftRightItemIdentifier
	
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Rotate Left", @"Menu item title") action:@selector(rotateAllLeft:) keyEquivalent:@""] autorelease];
	[menuItem setTarget:self];
    
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarRotateLeftRightItemIdentifier];
    [item setLabels:NSLocalizedString(@"Rotate", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Rotate Left or Right", @"Tool tip message")];
    [rotateLeftRightButton makeCapsule];
    [item setViewWithSizes:rotateLeftRightButton];
    [item setMenuFormRepresentation:menuItem];
    [toolbarItems setObject:item forKey:SKDocumentToolbarRotateLeftRightItemIdentifier];
    [item release];
    
#pragma mark SKDocumentToolbarCropItemIdentifier
	
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Crop", @"Menu item title") action:@selector(cropAll:) keyEquivalent:@""] autorelease];
	[menuItem setTarget:self];
    
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarCropItemIdentifier];
    [item setLabels:NSLocalizedString(@"Crop", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Crop", @"Tool tip message")];
    [cropButton makeCapsule];
    [item setViewWithSizes:cropButton];
    [item setMenuFormRepresentation:menuItem];
    [toolbarItems setObject:item forKey:SKDocumentToolbarCropItemIdentifier];
    [item release];
    
#pragma mark SKDocumentToolbarFullScreenItemIdentifier
	
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Full Screen", @"Menu item title") action:@selector(enterFullScreen:) keyEquivalent:@""] autorelease];
	[menuItem setTarget:self];
    
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarFullScreenItemIdentifier];
    [item setLabels:NSLocalizedString(@"Full Screen", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Full Screen", @"Tool tip message")];
    [fullScreenButton makeCapsule];
    [item setViewWithSizes:fullScreenButton];
    [item setMenuFormRepresentation:menuItem];
    [toolbarItems setObject:item forKey:SKDocumentToolbarFullScreenItemIdentifier];
    [item release];
    
#pragma mark SKDocumentToolbarPresentationItemIdentifier
	
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Presentation", @"Menu item title") action:@selector(enterPresentation:) keyEquivalent:@""] autorelease];
	[menuItem setTarget:self];
    
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarPresentationItemIdentifier];
    [item setLabels:NSLocalizedString(@"Presentation", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Presentation", @"Tool tip message")];
    [presentationButton makeCapsule];
    [item setViewWithSizes:presentationButton];
    [item setMenuFormRepresentation:menuItem];
    [toolbarItems setObject:item forKey:SKDocumentToolbarPresentationItemIdentifier];
    [item release];
    
#pragma mark SKDocumentToolbarNewTextNoteItemIdentifier
	
    menu = [[[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:@""] autorelease];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Text Note", @"Menu item title") action:@selector(createNewTextNote:) keyEquivalent:@""];
    [menuItem setTag:SKFreeTextNote];
    [menuItem setImage:[NSImage imageNamed:SKImageNameToolbarAddTextNote]];
    [menuItem setTarget:self];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Anchored Note", @"Menu item title") action:@selector(createNewTextNote:) keyEquivalent:@""];
    [menuItem setTag:SKAnchoredNote];
    [menuItem setImage:[NSImage imageNamed:SKImageNameToolbarAddAnchoredNote]];
    [menuItem setTarget:self];
    [textNoteButton setMenu:menu forSegment:0];
    
    menu = [[[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:@""] autorelease];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Text Note", @"Menu item title") action:@selector(createNewNote:) keyEquivalent:@""];
    [menuItem setTag:SKFreeTextNote];
    [menuItem setImage:[NSImage imageNamed:SKImageNameToolbarAddTextNote]];
    [menuItem setTarget:self];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Anchored Note", @"Menu item title") action:@selector(createNewNote:) keyEquivalent:@""];
    [menuItem setTag:SKAnchoredNote];
    [menuItem setImage:[NSImage imageNamed:SKImageNameToolbarAddAnchoredNote]];
    [menuItem setTarget:self];
    menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Add Note", @"Toolbar item label") action:NULL keyEquivalent:@""] autorelease];
    [menuItem setSubmenu:menu];
    
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarNewTextNoteItemIdentifier];
    [item setLabels:NSLocalizedString(@"Add Note", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Add New Note", @"Tool tip message")];
    [textNoteButton makeCapsule];
    [item setViewWithSizes:textNoteButton];
    [item setMenuFormRepresentation:menuItem];
    [toolbarItems setObject:item forKey:SKDocumentToolbarNewTextNoteItemIdentifier];
    [item release];
    
#pragma mark SKDocumentToolbarNewCircleNoteItemIdentifier
	
    menu = [[[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:@""] autorelease];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Circle", @"Menu item title") action:@selector(createNewCircleNote:) keyEquivalent:@""];
    [menuItem setTag:SKCircleNote];
    [menuItem setImage:[NSImage imageNamed:SKImageNameToolbarAddCircleNote]];
    [menuItem setTarget:self];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Box", @"Menu item title") action:@selector(createNewCircleNote:) keyEquivalent:@""];
    [menuItem setTag:SKSquareNote];
    [menuItem setImage:[NSImage imageNamed:SKImageNameToolbarAddSquareNote]];
    [menuItem setTarget:self];
    [circleNoteButton setMenu:menu forSegment:0];
    
    menu = [[[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:@""] autorelease];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Circle", @"Menu item title") action:@selector(createNewNote:) keyEquivalent:@""];
    [menuItem setTag:SKCircleNote];
    [menuItem setImage:[NSImage imageNamed:SKImageNameToolbarAddCircleNote]];
    [menuItem setTarget:self];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Box", @"Menu item title") action:@selector(createNewNote:) keyEquivalent:@""];
    [menuItem setTag:SKSquareNote];
    [menuItem setImage:[NSImage imageNamed:SKImageNameToolbarAddSquareNote]];
    [menuItem setTarget:self];
    menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Add Shape", @"Toolbar item label") action:NULL keyEquivalent:@""] autorelease];
    [menuItem setSubmenu:menu];
    
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarNewCircleNoteItemIdentifier];
    [item setLabels:NSLocalizedString(@"Add Shape", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Add New Circle or Box", @"Tool tip message")];
    [circleNoteButton makeCapsule];
    [item setViewWithSizes:circleNoteButton];
    [item setMenuFormRepresentation:menuItem];
    [toolbarItems setObject:item forKey:SKDocumentToolbarNewCircleNoteItemIdentifier];
    [item release];
    
#pragma mark SKDocumentToolbarNewMarkupItemIdentifier
	
    menu = [[[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:@""] autorelease];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Highlight", @"Menu item title") action:@selector(createNewMarkupNote:) keyEquivalent:@""];
    [menuItem setTag:SKHighlightNote];
    [menuItem setImage:[NSImage imageNamed:SKImageNameToolbarAddHighlightNote]];
    [menuItem setTarget:self];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Underline", @"Menu item title") action:@selector(createNewMarkupNote:) keyEquivalent:@""];
    [menuItem setTag:SKUnderlineNote];
    [menuItem setTarget:self];
    [menuItem setImage:[NSImage imageNamed:SKImageNameToolbarAddUnderlineNote]];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Strike Out", @"Menu item title") action:@selector(createNewMarkupNote:) keyEquivalent:@""];
    [menuItem setTag:SKStrikeOutNote];
    [menuItem setImage:[NSImage imageNamed:SKImageNameToolbarAddStrikeOutNote]];
    [menuItem setTarget:self];
    [markupNoteButton setMenu:menu forSegment:0];
    
    menu = [[[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:@""] autorelease];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Highlight", @"Menu item title") action:@selector(createNewNote:) keyEquivalent:@""];
    [menuItem setTag:SKHighlightNote];
    [menuItem setImage:[NSImage imageNamed:SKImageNameToolbarAddHighlightNote]];
    [menuItem setTarget:self];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Underline", @"Menu item title") action:@selector(createNewNote:) keyEquivalent:@""];
    [menuItem setTag:SKUnderlineNote];
    [menuItem setTarget:self];
    [menuItem setImage:[NSImage imageNamed:SKImageNameToolbarAddUnderlineNote]];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Strike Out", @"Menu item title") action:@selector(createNewNote:) keyEquivalent:@""];
    [menuItem setTag:SKStrikeOutNote];
    [menuItem setImage:[NSImage imageNamed:SKImageNameToolbarAddStrikeOutNote]];
    [menuItem setTarget:self];
    menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Add Markup", @"Toolbar item label") action:NULL keyEquivalent:@""] autorelease];
    [menuItem setSubmenu:menu];
    
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarNewMarkupItemIdentifier];
    [item setLabels:NSLocalizedString(@"Add Markup", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Add New Markup", @"Tool tip message")];
    [markupNoteButton makeCapsule];
    [item setViewWithSizes:markupNoteButton];
    [item setMenuFormRepresentation:menuItem];
    [toolbarItems setObject:item forKey:SKDocumentToolbarNewMarkupItemIdentifier];
    [item release];
    
#pragma mark SKDocumentToolbarNewLineItemIdentifier
	
    menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Add Line", @"Toolbar item label") action:@selector(createNewNote:) keyEquivalent:@""] autorelease];
    [menuItem setTag:SKLineNote];
    [menuItem setTarget:self];
    
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarNewLineItemIdentifier];
    [item setLabels:NSLocalizedString(@"Add Line", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Add New Line", @"Tool tip message")];
    [item setTag:SKLineNote];
    [lineNoteButton makeCapsule];
    [item setViewWithSizes:lineNoteButton];
    [item setMenuFormRepresentation:menuItem];
    [toolbarItems setObject:item forKey:SKDocumentToolbarNewLineItemIdentifier];
    [item release];
    
#pragma mark SKDocumentToolbarNewNoteItemIdentifier
	
    menu = [[[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:@""] autorelease];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Text Note", @"Menu item title") action:@selector(createNewNote:) keyEquivalent:@""];
	[menuItem setTarget:self];
	[menuItem setTag:SKFreeTextNote];
	[menuItem setImage:[NSImage imageNamed:SKImageNameToolbarAddTextNote]];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Anchored Note", @"Menu item title") action:@selector(createNewNote:) keyEquivalent:@""];
	[menuItem setTarget:self];
	[menuItem setTag:SKAnchoredNote];
	[menuItem setImage:[NSImage imageNamed:SKImageNameToolbarAddAnchoredNote]];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Circle", @"Menu item title") action:@selector(createNewNote:) keyEquivalent:@""];
	[menuItem setTarget:self];
	[menuItem setTag:SKCircleNote];
	[menuItem setImage:[NSImage imageNamed:SKImageNameToolbarAddCircleNote]];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Box", @"Menu item title") action:@selector(createNewNote:) keyEquivalent:@""];
	[menuItem setTarget:self];
	[menuItem setTag:SKSquareNote];
	[menuItem setImage:[NSImage imageNamed:SKImageNameToolbarAddSquareNote]];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Highlight", @"Menu item title") action:@selector(createNewNote:) keyEquivalent:@""];
	[menuItem setTarget:self];
	[menuItem setTag:SKHighlightNote];
	[menuItem setImage:[NSImage imageNamed:SKImageNameToolbarAddHighlightNote]];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Underline", @"Menu item title") action:@selector(createNewNote:) keyEquivalent:@""];
	[menuItem setTarget:self];
	[menuItem setTag:SKUnderlineNote];
	[menuItem setImage:[NSImage imageNamed:SKImageNameToolbarAddUnderlineNote]];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Strike Out", @"Menu item title") action:@selector(createNewNote:) keyEquivalent:@""];
	[menuItem setTarget:self];
	[menuItem setTag:SKStrikeOutNote];
	[menuItem setImage:[NSImage imageNamed:SKImageNameToolbarAddStrikeOutNote]];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Line", @"Menu item title") action:@selector(createNewNote:) keyEquivalent:@""];
	[menuItem setTarget:self];
	[menuItem setTag:SKLineNote];
	[menuItem setImage:[NSImage imageNamed:SKImageNameToolbarAddLineNote]];
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Add Note", @"Toolbar item label") action:NULL keyEquivalent:@""] autorelease];
    [menuItem setSubmenu:menu];
    
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarNewNoteItemIdentifier];
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
    [noteButton makeCapsule];
    [item setViewWithSizes:noteButton];
    [item setMenuFormRepresentation:menuItem];
    [toolbarItems setObject:item forKey:SKDocumentToolbarNewNoteItemIdentifier];
    [item release];
    
#pragma mark SKDocumentToolbarToolModeItemIdentifier
    
    menu = [[[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:@""] autorelease];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Text Note", @"Menu item title") action:@selector(changeAnnotationMode:) keyEquivalent:@""];
	[menuItem setTarget:self];
	[menuItem setTag:SKFreeTextNote];
	[menuItem setImage:[NSImage imageNamed:SKImageNameToolbarTextNote]];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Anchored Note", @"Menu item title") action:@selector(changeAnnotationMode:) keyEquivalent:@""];
	[menuItem setTarget:self];
	[menuItem setTag:SKAnchoredNote];
	[menuItem setImage:[NSImage imageNamed:SKImageNameToolbarAnchoredNote]];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Circle", @"Menu item title") action:@selector(changeAnnotationMode:) keyEquivalent:@""];
	[menuItem setTarget:self];
	[menuItem setTag:SKCircleNote];
	[menuItem setImage:[NSImage imageNamed:SKImageNameToolbarCircleNote]];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Box", @"Menu item title") action:@selector(changeAnnotationMode:) keyEquivalent:@""];
	[menuItem setTarget:self];
	[menuItem setTag:SKSquareNote];
	[menuItem setImage:[NSImage imageNamed:SKImageNameToolbarSquareNote]];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Highlight", @"Menu item title") action:@selector(changeAnnotationMode:) keyEquivalent:@""];
	[menuItem setTarget:self];
	[menuItem setTag:SKHighlightNote];
	[menuItem setImage:[NSImage imageNamed:SKImageNameToolbarHighlightNote]];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Underline", @"Menu item title") action:@selector(changeAnnotationMode:) keyEquivalent:@""];
	[menuItem setTarget:self];
	[menuItem setTag:SKUnderlineNote];
	[menuItem setImage:[NSImage imageNamed:SKImageNameToolbarUnderlineNote]];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Strike Out", @"Menu item title") action:@selector(changeAnnotationMode:) keyEquivalent:@""];
	[menuItem setTarget:self];
	[menuItem setTag:SKStrikeOutNote];
	[menuItem setImage:[NSImage imageNamed:SKImageNameToolbarStrikeOutNote]];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Line", @"Menu item title") action:@selector(changeAnnotationMode:) keyEquivalent:@""];
	[menuItem setTarget:self];
	[menuItem setTag:SKLineNote];
	[menuItem setImage:[NSImage imageNamed:SKImageNameToolbarLineNote]];
    [toolModeButton setMenu:menu forSegment:SKNoteToolMode];
	
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
    [toolModeButton setToolTip:NSLocalizedString(@"Text Tool", @"Tool tip message") forSegment:SKTextToolMode];
    [toolModeButton setToolTip:NSLocalizedString(@"Scroll Tool", @"Tool tip message") forSegment:SKMoveToolMode];
    [toolModeButton setToolTip:NSLocalizedString(@"Magnify Tool", @"Tool tip message") forSegment:SKMagnifyToolMode];
    [toolModeButton setToolTip:NSLocalizedString(@"Select Tool", @"Tool tip message") forSegment:SKSelectToolMode];
    [toolModeButton setToolTip:NSLocalizedString(@"Note Tool", @"Tool tip message") forSegment:SKNoteToolMode];
    [toolModeButton makeCapsule];
    [item setViewWithSizes:toolModeButton];
    [item setMenuFormRepresentation:menuItem];
    [toolbarItems setObject:item forKey:SKDocumentToolbarToolModeItemIdentifier];
    [item release];
    
#pragma mark SKDocumentToolbarSingleTwoUpItemIdentifier
	
    menu = [[[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:@""] autorelease];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Single Page", @"Menu item title") action:@selector(changeDisplaySinglePages:) keyEquivalent:@""];
	[menuItem setTarget:self];
	[menuItem setTag:kPDFDisplaySinglePage];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Two Pages", @"Menu item title") action:@selector(changeDisplaySinglePages:) keyEquivalent:@""];
	[menuItem setTarget:self];
	[menuItem setTag:kPDFDisplayTwoUp];
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Single/Two Pages", @"Toolbar item label") action:NULL keyEquivalent:@""] autorelease];
    [menuItem setSubmenu:menu];
    
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarSingleTwoUpItemIdentifier];
    [item setLabels:NSLocalizedString(@"Single/Two Pages", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Single/Two Pages", @"Tool tip message")];
    [singleTwoUpButton setToolTip:NSLocalizedString(@"Single Page", @"Tool tip message") forSegment:0];
    [singleTwoUpButton setToolTip:NSLocalizedString(@"Two Pages", @"Tool tip message") forSegment:1];
    [singleTwoUpButton makeCapsule];
    [item setViewWithSizes:singleTwoUpButton];
    [item setMenuFormRepresentation:menuItem];
    [toolbarItems setObject:item forKey:SKDocumentToolbarSingleTwoUpItemIdentifier];
    [item release];
    
#pragma mark SKDocumentToolbarContinuousItemIdentifier
	
    menu = [[[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:@""] autorelease];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Non Continuous", @"Menu item title") action:@selector(changeDisplayContinuous:) keyEquivalent:@""];
	[menuItem setTarget:self];
	[menuItem setTag:kPDFDisplaySinglePage];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Continuous", @"Menu item title") action:@selector(changeDisplayContinuous:) keyEquivalent:@""];
	[menuItem setTarget:self];
	[menuItem setTag:kPDFDisplaySinglePageContinuous];
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Continuous", @"Toolbar item label") action:NULL keyEquivalent:@""] autorelease];
    [menuItem setSubmenu:menu];
    
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarContinuousItemIdentifier];
    [item setLabels:NSLocalizedString(@"Continuous", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Continuous", @"Tool tip message")];
    [continuousButton setToolTip:NSLocalizedString(@"Non Continuous", @"Tool tip message") forSegment:0];
    [continuousButton setToolTip:NSLocalizedString(@"Continuous", @"Tool tip message") forSegment:1];
    [continuousButton makeCapsule];
    [item setViewWithSizes:continuousButton];
    [item setMenuFormRepresentation:menuItem];
    [toolbarItems setObject:item forKey:SKDocumentToolbarContinuousItemIdentifier];
    [item release];
    
#pragma mark SKDocumentToolbarDisplayModeItemIdentifier
	
    menu = [[[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:@""] autorelease];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Single Page", @"Menu item title") action:@selector(changeDisplayMode:) keyEquivalent:@""];
	[menuItem setTarget:self];
	[menuItem setTag:kPDFDisplaySinglePage];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Single Page Continuous", @"Menu item title") action:@selector(changeDisplayMode:) keyEquivalent:@""];
	[menuItem setTarget:self];
	[menuItem setTag:kPDFDisplaySinglePageContinuous];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Two Pages", @"Menu item title") action:@selector(changeDisplayMode:) keyEquivalent:@""];
	[menuItem setTarget:self];
	[menuItem setTag:kPDFDisplayTwoUp];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Two Pages Continuous", @"Menu item title") action:@selector(changeDisplayMode:) keyEquivalent:@""];
	[menuItem setTarget:self];
	[menuItem setTag:kPDFDisplayTwoUpContinuous];
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Display Mode", @"Toolbar item label") action:NULL keyEquivalent:@""] autorelease];
    [menuItem setSubmenu:menu];
    
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarDisplayModeItemIdentifier];
    [item setLabels:NSLocalizedString(@"Display Mode", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Display Mode", @"Tool tip message")];
    [displayModeButton setToolTip:NSLocalizedString(@"Single Page", @"Tool tip message") forSegment:kPDFDisplaySinglePage];
    [displayModeButton setToolTip:NSLocalizedString(@"Single Page Continuous", @"Tool tip message") forSegment:kPDFDisplaySinglePageContinuous];
    [displayModeButton setToolTip:NSLocalizedString(@"Two Pages", @"Tool tip message") forSegment:kPDFDisplayTwoUp];
    [displayModeButton setToolTip:NSLocalizedString(@"Two Pages Continuous", @"Tool tip message") forSegment:kPDFDisplayTwoUpContinuous];
    [displayModeButton makeCapsule];
    [item setViewWithSizes:displayModeButton];
    [item setMenuFormRepresentation:menuItem];
    [toolbarItems setObject:item forKey:SKDocumentToolbarDisplayModeItemIdentifier];
    [item release];
    
#pragma mark SKDocumentToolbarDisplayBoxItemIdentifier
	
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
    [displayBoxButton makeCapsule];
    [item setViewWithSizes:displayBoxButton];
    [item setMenuFormRepresentation:menuItem];
    [toolbarItems setObject:item forKey:SKDocumentToolbarDisplayBoxItemIdentifier];
    [item release];
    
#pragma mark SKDocumentToolbarColorSwatchItemIdentifier
	
    NSDictionary *options = [NSDictionary dictionaryWithObject:SKUnarchiveFromDataArrayTransformerName forKey:NSValueTransformerNameBindingOption];
    [colorSwatch bind:SKColorSwatchColorsKey toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:[NSString stringWithFormat:@"values.%@", SKSwatchColorsKey] options:options];
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
    
#pragma mark SKDocumentToolbarColorsItemIdentifier
	
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Colors", @"Menu item title") action:@selector(orderFrontColorPanel:) keyEquivalent:@""] autorelease];
	[menuItem setTarget:self];
    
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarColorsItemIdentifier];
    [item setLabels:NSLocalizedString(@"Colors", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Colors", @"Tool tip message")];
    [colorsButton makeCapsule];
    [item setViewWithSizes:colorsButton];
    [item setMenuFormRepresentation:menuItem];
    [toolbarItems setObject:item forKey:SKDocumentToolbarColorsItemIdentifier];
    [item release];
    
#pragma mark SKDocumentToolbarFontsItemIdentifier
	
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Fonts", @"Menu item title") action:@selector(orderFrontFontPanel:) keyEquivalent:@""] autorelease];
	[menuItem setTarget:self];
    
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarFontsItemIdentifier];
    [item setLabels:NSLocalizedString(@"Fonts", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Fonts", @"Tool tip message")];
    [item setImageNamed:@"ToolbarFonts"];
    [fontsButton makeCapsule];
    if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_4)
        [fontsButton setImage:[NSImage imageNamed:@"ToolbarFontsBlack"] forSegment:0];
    [item setViewWithSizes:fontsButton];
    [item setMenuFormRepresentation:menuItem];
    [toolbarItems setObject:item forKey:SKDocumentToolbarFontsItemIdentifier];
    [item release];
    
#pragma mark SKDocumentToolbarLinesItemIdentifier
	
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Lines", @"Menu item title") action:@selector(orderFrontLineInspector:) keyEquivalent:@""] autorelease];
    
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarLinesItemIdentifier];
    [item setLabels:NSLocalizedString(@"Lines", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Lines", @"Tool tip message")];
    [linesButton makeCapsule];
    [item setViewWithSizes:linesButton];
    [item setMenuFormRepresentation:menuItem];
    [toolbarItems setObject:item forKey:SKDocumentToolbarLinesItemIdentifier];
    [item release];
    
#pragma mark SKDocumentToolbarInfoItemIdentifier
	
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Info", @"Menu item title") action:@selector(getInfo:) keyEquivalent:@""] autorelease];
	[menuItem setTarget:self];
    
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarInfoItemIdentifier];
    [item setLabels:NSLocalizedString(@"Info", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Get Document Info", @"Tool tip message")];
    [infoButton makeCapsule];
    [item setViewWithSizes:infoButton];
    [item setMenuFormRepresentation:menuItem];
    [toolbarItems setObject:item forKey:SKDocumentToolbarInfoItemIdentifier];
    [item release];
    
#pragma mark SKDocumentToolbarContentsPaneItemIdentifier
	
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Contents Pane", @"Menu item title") action:@selector(toggleLeftSidePane:) keyEquivalent:@""] autorelease];
	[menuItem setTarget:self];
    
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarContentsPaneItemIdentifier];
    [item setLabels:NSLocalizedString(@"Contents Pane", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Toggle Contents Pane", @"Tool tip message")];
    [leftPaneButton makeCapsule];
    [item setViewWithSizes:leftPaneButton];
    [item setMenuFormRepresentation:menuItem];
    [toolbarItems setObject:item forKey:SKDocumentToolbarContentsPaneItemIdentifier];
    [item release];
    
#pragma mark SKDocumentToolbarNotesPaneItemIdentifier
	
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Notes Pane", @"Menu item title") action:@selector(toggleRightSidePane:) keyEquivalent:@""] autorelease];
	[menuItem setTarget:self];
    
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarNotesPaneItemIdentifier];
    [item setLabels:NSLocalizedString(@"Notes Pane", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Toggle Notes Pane", @"Tool tip message")];
    [rightPaneButton makeCapsule];
    [item setViewWithSizes:rightPaneButton];
    [item setMenuFormRepresentation:menuItem];
    [toolbarItems setObject:item forKey:SKDocumentToolbarNotesPaneItemIdentifier];
    [item release];
    
#pragma mark SKDocumentToolbarPrintItemIdentifier
	
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Print", @"Menu item title") action:@selector(printDocument:) keyEquivalent:@""] autorelease];
    
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarPrintItemIdentifier];
    [item setLabels:NSLocalizedString(@"Print", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Print Document", @"Tool tip message")];
    [printButton makeCapsule];
    [item setViewWithSizes:printButton];
    [item setMenuFormRepresentation:menuItem];
    [toolbarItems setObject:item forKey:SKDocumentToolbarPrintItemIdentifier];
    [item release];
    
#pragma mark SKDocumentToolbarCustomizeItemIdentifier
	
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Customize", @"Menu item title") action:@selector(runToolbarCustomizationPalette:) keyEquivalent:@""] autorelease];
    
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKDocumentToolbarCustomizeItemIdentifier];
    [item setLabels:NSLocalizedString(@"Customize", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Customize Toolbar", @"Tool tip message")];
    [customizeButton makeCapsule];
    [item setViewWithSizes:customizeButton];
    [item setMenuFormRepresentation:menuItem];
    [toolbarItems setObject:item forKey:SKDocumentToolbarCustomizeItemIdentifier];
    [item release];
    
    // Attach the toolbar to the window
    [[self window] setToolbar:toolbar];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdent willBeInsertedIntoToolbar:(BOOL)willBeInserted {

    SKToolbarItem *item = [toolbarItems objectForKey:itemIdent];
    
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

@end
