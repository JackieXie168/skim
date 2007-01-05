//  BibDocumentView_Toolbar.m

//  Created by Michael McCracken on Wed Jul 03 2002.
/*
 This software is Copyright (c) 2002,2003,2004,2005,2006,2007
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

#import "BibDocumentView_Toolbar.h"
#import "BibDocument_Search.h"
#import "BibAppController.h"
#import "NSImage+Toolbox.h"
#import <OmniAppKit/OAToolbarItem.h>
#import "OAToolbarItem_BDSKExtensions.h"
#import "BDSKImagePopUpButton.h"
#import "BibDocument_Actions.h"
#import "BDSKSearchField.h"
#import "BDSKCustomCiteDrawerController.h"

#define TOOLBAR_SEARCHFIELD_MIN_SIZE NSMakeSize(110.0, 22.0)
#define TOOLBAR_SEARCHFIELD_MAX_SIZE NSMakeSize(1000.0, 22.0)

static NSString *BibDocumentToolbarIdentifier = @"BibDocumentToolbarIdentifier";
static NSString *BibDocumentToolbarNewItemIdentifier = @"BibDocumentToolbarNewItemIdentifier";
static NSString *BibDocumentToolbarSearchItemIdentifier = @"BibDocumentToolbarSearchItemIdentifier";
static NSString *BibDocumentToolbarActionItemIdentifier = @"BibDocumentToolbarActionItemIdentifier";
static NSString *BibDocumentToolbarGroupActionItemIdentifier = @"BibDocumentToolbarGroupActionItemIdentifier";
static NSString *BibDocumentToolbarEditItemIdentifier = @"BibDocumentToolbarEditItemIdentifier";
static NSString *BibDocumentToolbarDeleteItemIdentifier = @"BibDocumentToolbarDeleteItemIdentifier";
static NSString *BibDocumentToolbarPreviewItemIdentifier = @"BibDocumentToolbarPreviewItemIdentifier";
static NSString *BibDocumentToolbarCiteDrawerItemIdentifier = @"BibDocumentToolbarCiteDrawerItemIdentifier";

@implementation BibDocument (Toolbar)

// called from WindowControllerDidLoadNib.
- (void) setupToolbar {
    // Create a new toolbar instance, and attach it to our document window
    NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier:BibDocumentToolbarIdentifier] autorelease];
    OAToolbarItem *item;
    NSMenuItem *menuItem;
    
    toolbarItems = [[NSMutableDictionary alloc] initWithCapacity:9];
    
    // Set up toolbar properties: Allow customization, give a default display mode, and remember state in user defaults
    [toolbar setAllowsUserCustomization: YES];
    [toolbar setAutosavesConfiguration: YES];
    [toolbar setDisplayMode: NSToolbarDisplayModeDefault];

    // We are the delegate
    [toolbar setDelegate: self];

    // Add template toolbar items
    
    // New
    NSImage *image = [[[NSImage alloc] initWithSize:NSMakeSize(32, 32)] autorelease];
    [image lockFocus];
    [[NSImage imageNamed: @"newdoc"] compositeToPoint:NSZeroPoint operation:NSCompositeSourceOver]; 
    [[NSImage imageWithLargeIconForToolboxCode:kAliasBadgeIcon] compositeToPoint:NSMakePoint(8,-10) operation:NSCompositeSourceOver];
    [image unlockFocus];
    item = [[OAToolbarItem alloc] initWithItemIdentifier:BibDocumentToolbarNewItemIdentifier];
    [item setLabel:NSLocalizedString(@"New", @"Toolbar item label")];
    [item setOptionKeyLabel:NSLocalizedString(@"New with Crossref", @"Toolbar item label")];
    [item setPaletteLabel:NSLocalizedString(@"New Publication", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Create new publication", @"Tool tip message")];
    [item setOptionKeyToolTip:NSLocalizedString(@"Create new publication with crossref", @"Tool tip message")];
    [item setTarget:self];
    [item setImage:[NSImage imageNamed: @"newdoc"]];
    [item setOptionKeyImage:image];
    [item setAction:@selector(newPub:)];
    [item setOptionKeyAction:@selector(createNewPubUsingCrossrefAction:)];
    [toolbarItems setObject:item forKey:BibDocumentToolbarNewItemIdentifier];
    [item release];
    
    // Delete
    item = [[OAToolbarItem alloc] initWithItemIdentifier:BibDocumentToolbarDeleteItemIdentifier];
    [item setLabel:NSLocalizedString(@"Delete", @"Toolbar item label")];
    [item setPaletteLabel:NSLocalizedString(@"Delete Publication", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Delete selected publication(s)", @"Tool tip message")];
    [item setTarget:self];
    [item setImage:[NSImage imageWithLargeIconForToolboxCode:kToolbarDeleteIcon]];
    [item setAction:@selector(deleteSelectedPubs:)];
    [toolbarItems setObject:item forKey:BibDocumentToolbarDeleteItemIdentifier];
    [item release];
    
    // Edit
    item = [[OAToolbarItem alloc] initWithItemIdentifier:BibDocumentToolbarEditItemIdentifier];
    [item setLabel:NSLocalizedString(@"Edit", @"Toolbar item label")];
    [item setPaletteLabel:NSLocalizedString(@"Edit Publication", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Edit selected publication(s)", @"Tool tip message")];
    [item setTarget:self];
    [item setImage:[NSImage imageNamed: @"editdoc"]];
    [item setAction:@selector(editPubCmd:)];
    [toolbarItems setObject:item forKey:BibDocumentToolbarEditItemIdentifier];
    [item release];
    
    // Preview (nil targeted -> app delegate)
    item = [[OAToolbarItem alloc] initWithItemIdentifier:BibDocumentToolbarPreviewItemIdentifier];
    [item setLabel:NSLocalizedString(@"Preview", @"Toolbar item label")];
    [item setPaletteLabel:NSLocalizedString(@"Show/Hide Preview", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Show/Hide preview panel", @"Tool tip message")];
    [item setTarget:nil];
    [item setImage:[NSImage imageNamed: @"preview"]];
    [item setAction:@selector(toggleShowingPreviewPanel:)];
    [toolbarItems setObject:item forKey:BibDocumentToolbarPreviewItemIdentifier];
    [item release];
    
    // Cite Drawer
    item = [[OAToolbarItem alloc] initWithItemIdentifier:BibDocumentToolbarCiteDrawerItemIdentifier];
    [item setLabel:NSLocalizedString(@"Cite Drawer", @"Toolbar item label")];
    [item setPaletteLabel:NSLocalizedString(@"Toggle Custom Citations Drawer", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Toggle custom citations drawer", @"Tool tip message")];
    [item setTarget:self];
    [item setImage:[NSImage imageNamed: @"drawerToolbarImage"]];
    [item setAction:@selector(toggleShowingCustomCiteDrawer:)];
    [toolbarItems setObject:item forKey:BibDocumentToolbarCiteDrawerItemIdentifier];
    [item release];
	
	// Search
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Search", @"Toolbar item label") 
										   action:@selector(performFindPanelAction:)
									keyEquivalent:@""] autorelease];
	[menuItem setTag:NSFindPanelActionShowFindPanel];
	[menuItem setTarget:self];
    item = [[OAToolbarItem alloc] initWithItemIdentifier:BibDocumentToolbarSearchItemIdentifier];
    [item setDelegate:self];
    [item setLabel:NSLocalizedString(@"Search", @"Toolbar item label")];
    [item setPaletteLabel:NSLocalizedString(@"Search", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Search using boolean '+' and '|', see Help for details", @"Tool tip message")];
    [item setTarget:self];
    [item setView:searchField];
    [item setMinSize:TOOLBAR_SEARCHFIELD_MIN_SIZE];
    [item setMaxSize:TOOLBAR_SEARCHFIELD_MAX_SIZE];
    [item setAction:@selector(search:)];
    [item setMenuFormRepresentation:menuItem];
    [toolbarItems setObject:item forKey:BibDocumentToolbarSearchItemIdentifier];
    [item release];
	
	// Action
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Action", @"Toolbar item label") 
										   action:NULL 
									keyEquivalent:@""] autorelease];
	[menuItem setSubmenu: actionMenu];
    item = [[OAToolbarItem alloc] initWithItemIdentifier:BibDocumentToolbarActionItemIdentifier];
    [item setDelegate:self];
    [item setLabel:NSLocalizedString(@"Action", @"Toolbar item label")];
    [item setPaletteLabel:NSLocalizedString(@"Publication Action", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Action for selected publications", @"Tool tip message")];
    [item setTarget:self];
    [item setView:actionMenuButton];
    [item setMinSize:[actionMenuButton bounds].size];
    [item setMaxSize:[actionMenuButton bounds].size];
    [item setMenuFormRepresentation:menuItem];
    [toolbarItems setObject:item forKey:BibDocumentToolbarActionItemIdentifier];
    [item release];
	
	// Group Action
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Group Action", @"Toolbar item label") 
										   action:NULL 
									keyEquivalent:@""] autorelease];
	[menuItem setSubmenu: groupMenu];
    item = [[OAToolbarItem alloc] initWithItemIdentifier:BibDocumentToolbarGroupActionItemIdentifier];
    [item setDelegate:self];
    [item setLabel:NSLocalizedString(@"Group Action", @"Toolbar item label")];
    [item setPaletteLabel:NSLocalizedString(@"Group Action", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Action for groups list", @"Tool tip message")];
    [item setTarget:self];
    [item setView:groupActionMenuButton];
    [item setMinSize:[groupActionMenuButton bounds].size];
    [item setMaxSize:[groupActionMenuButton bounds].size];
    [item setMenuFormRepresentation:menuItem];
    [toolbarItems setObject:item forKey:BibDocumentToolbarGroupActionItemIdentifier];
    [item release];
    
    // Attach the toolbar to the document window
    [documentWindow setToolbar: toolbar];
}

- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar
      itemForItemIdentifier: (NSString *)itemIdent
  willBeInsertedIntoToolbar:(BOOL) willBeInserted {

    OAToolbarItem *item = [toolbarItems objectForKey:itemIdent];
    OAToolbarItem *newItem = [[item copy] autorelease];
    // the view should not be copied
    if ([item view] && willBeInserted) [newItem setView:[item view]];
    return newItem;
}



- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar {
    return [NSArray arrayWithObjects:
		BibDocumentToolbarActionItemIdentifier,
		NSToolbarSpaceItemIdentifier, 
		BibDocumentToolbarNewItemIdentifier,
		BibDocumentToolbarEditItemIdentifier, 
		BibDocumentToolbarDeleteItemIdentifier, 
		NSToolbarSeparatorItemIdentifier, 
		BibDocumentToolbarPreviewItemIdentifier,
		NSToolbarFlexibleSpaceItemIdentifier, 
		BibDocumentToolbarSearchItemIdentifier,
		BibDocumentToolbarCiteDrawerItemIdentifier, nil];
}


- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar {
    return [NSArray arrayWithObjects: 
		BibDocumentToolbarNewItemIdentifier, 
		BibDocumentToolbarEditItemIdentifier, 
		BibDocumentToolbarDeleteItemIdentifier,
		BibDocumentToolbarPreviewItemIdentifier , 
		BibDocumentToolbarActionItemIdentifier,
		BibDocumentToolbarGroupActionItemIdentifier,
		BibDocumentToolbarSearchItemIdentifier,
		BibDocumentToolbarCiteDrawerItemIdentifier,
		NSToolbarPrintItemIdentifier,
		NSToolbarFlexibleSpaceItemIdentifier, 
		NSToolbarSpaceItemIdentifier, 
		NSToolbarSeparatorItemIdentifier, 
		NSToolbarCustomizeToolbarItemIdentifier, nil];
}

/*
- (void) toolbarWillAddItem: (NSNotification *) notif {
    NSToolbarItem *addedItem = [[notif userInfo] objectForKey: @"item"];

}

- (void) toolbarDidRemoveItem: (NSNotification *) notif {
    // Optional delegate method   After an item is removed from a toolbar the notification is sent   self allows
    // the chance to tear down information related to the item that may have been cached   The notification object
    // is the toolbar to which the item is being added   The item being added is found by referencing the @"item"
    // key in the userInfo
    NSToolbarItem *removedItem = [[notif userInfo] objectForKey: @"item"];


}*/

- (BOOL) validateToolbarItem: (NSToolbarItem *) toolbarItem {
    // Optional method   self message is sent to us since we are the target of some toolbar item actions
    // (for example:  of the save items action)
    BOOL enable = YES;
    if ([[toolbarItem itemIdentifier] isEqualToString: NSToolbarPrintItemIdentifier]) {
		enable = [self validatePrintDocumentMenuItem:nil];
    }else if([[toolbarItem itemIdentifier] isEqualToString: BibDocumentToolbarEditItemIdentifier]
			 || [[toolbarItem itemIdentifier] isEqualToString: BibDocumentToolbarActionItemIdentifier]){
        if([self numberOfSelectedPubs] == 0) enable = NO;
    }else if([[toolbarItem itemIdentifier] isEqualToString: BibDocumentToolbarDeleteItemIdentifier]){
        if([self numberOfSelectedPubs] == 0 || [documentWindow isKeyWindow] == NO) enable = NO;  // disable click-through
    }else if([[toolbarItem itemIdentifier] isEqualToString: BibDocumentToolbarNewItemIdentifier]){
        if(([NSApp currentModifierFlags] & NSAlternateKeyMask) && [self numberOfSelectedPubs] != 1) enable = NO;
    }
    return enable;
}


@end
