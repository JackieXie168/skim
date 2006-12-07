//
//  BibEditor_Toolbar.m
//  BibDesk
//
//  Created by Christiaan Hofman on 2/4/05.
/*
 This software is Copyright (c) 2005
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

#import "BibEditor_Toolbar.h"
#import <OmniAppKit/OAToolbarItem.h>
#import "OAToolbarItem_BDSKExtensions.h"
#import "BDSKImagePopUpButton.h"

NSString *BibEditorToolbarIdentifier = @"BibEditorToolbarIdentifier";
NSString *BibEditorToolbarViewLocalItemIdentifier = @"BibEditorToolbarViewLocalItemIdentifier";
NSString *BibEditorToolbarViewRemoteItemIdentifier = @"BibEditorToolbarViewRemoteItemIdentifier";
NSString *BibEditorToolbarSnoopDrawerItemIdentifier = @"BibEditorToolbarSnoopDrawerItemIdentifier";
NSString *BibEditorToolbarActionItemIdentifier = @"BibEditorToolbarActionItemIdentifier";
NSString *BibEditorToolbarAuthorTableItemIdentifier = @"BibEditorToolbarAuthorTableItemIdentifier";
NSString *BibEditorToolbarDeleteItemIdentifier = @"BibEditorToolbarDeleteItemIdentifier";
NSString *BibEditorToolbarAddWithCrossrefItemIdentifier = @"BibEditorToolbarAddWithCrossrefItemIdentifier";

@implementation BibEditor (Toolbar)

// called from WindowControllerDidLoadNib.
- (void) setupToolbar {
    // Create a new toolbar instance, and attach it to our document window
    NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier:BibEditorToolbarIdentifier] autorelease];
    OAToolbarItem *item;
    NSMenuItem *menuItem;
    NSMenu *submenu;
    NSZone *menuZone = [NSMenu menuZone];

    toolbarItems = [[NSMutableDictionary alloc] initWithCapacity:7];
    
    // Set up toolbar properties: Allow customization, give a default display mode, and remember state in user defaults
    [toolbar setAllowsUserCustomization: YES];
    [toolbar setAutosavesConfiguration: YES];
    [toolbar setDisplayMode: NSToolbarDisplayModeDefault];

    // We are the delegate
    [toolbar setDelegate: self];

    // Add template toolbar items
    
    // View File
	menuItem = [[[NSMenuItem allocWithZone:menuZone] initWithTitle:NSLocalizedString(@"View File",@"") 
											                action:NULL
                                                     keyEquivalent:@""] autorelease];
	submenu = [[[NSMenu allocWithZone:menuZone] initWithTitle:@""] autorelease];
    [menuItem setSubmenu:submenu];
    item = [[OAToolbarItem alloc] initWithItemIdentifier:BibEditorToolbarViewLocalItemIdentifier];
    [item setDelegate:self];
    [item setLabel:NSLocalizedString(@"View File",@"")];
    [item setPaletteLabel:NSLocalizedString(@"View File",@"")];
    [item setToolTip:NSLocalizedString(@"View File",@"")];
    [item setTarget:self];
    [item setView:viewLocalButton];
    [item setMinSize:[viewLocalButton bounds].size];
    [item setMaxSize:[viewLocalButton bounds].size];
    [item setMenuFormRepresentation:menuItem];
    [toolbarItems setObject:item forKey:BibEditorToolbarViewLocalItemIdentifier];
    [item release];
    
    // View Remote
	menuItem = [[[NSMenuItem allocWithZone:menuZone] initWithTitle:NSLocalizedString(@"View Remote",@"") 
											                action:NULL
                                                     keyEquivalent:@""] autorelease];
	submenu = [[[NSMenu allocWithZone:menuZone] initWithTitle:@""] autorelease];
    [menuItem setSubmenu:submenu];
    item = [[OAToolbarItem alloc] initWithItemIdentifier:BibEditorToolbarViewRemoteItemIdentifier];
    [item setDelegate:self];
    [item setLabel:NSLocalizedString(@"View Remote",@"")];
    [item setPaletteLabel:NSLocalizedString(@"View Remote URL",@"")];
    [item setToolTip:NSLocalizedString(@"View in Web Browser",@"")];
    [item setTarget:self];
    [item setView:viewRemoteButton];
    [item setMinSize:[viewRemoteButton bounds].size];
    [item setMaxSize:[viewRemoteButton bounds].size];
    [item setMenuFormRepresentation:menuItem];
    [toolbarItems setObject:item forKey:BibEditorToolbarViewRemoteItemIdentifier];
    [item release];
    
    // View in Drawer
	menuItem = [[[NSMenuItem allocWithZone:menuZone] initWithTitle:NSLocalizedString(@"View in Drawer",@"") 
											                action:NULL
                                                     keyEquivalent:@""] autorelease];
	submenu = [[[NSMenu allocWithZone:menuZone] initWithTitle:@""] autorelease];
    [menuItem setSubmenu:submenu];
    item = [[OAToolbarItem alloc] initWithItemIdentifier:BibEditorToolbarSnoopDrawerItemIdentifier];
    [item setDelegate:self];
    [item setLabel:NSLocalizedString(@"View in Drawer",@"")];
    [item setPaletteLabel:NSLocalizedString(@"View in Drawer",@"")];
    [item setToolTip:NSLocalizedString(@"View File in Drawer",@"")];
    [item setTarget:self];
    [item setView:documentSnoopButton];
    [item setMinSize:[documentSnoopButton bounds].size];
    [item setMaxSize:[documentSnoopButton bounds].size];
    [item setMenuFormRepresentation:menuItem];
    [toolbarItems setObject:item forKey:BibEditorToolbarSnoopDrawerItemIdentifier];
    [item release];
	
	// Action
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Action",@"") 
                                                                     action:NULL 
                                                              keyEquivalent:@""] autorelease];
	[menuItem setSubmenu:actionMenu];
    item = [[OAToolbarItem alloc] initWithItemIdentifier:BibEditorToolbarActionItemIdentifier];
    [item setDelegate:self];
    [item setLabel:NSLocalizedString(@"Action",@"")];
    [item setPaletteLabel:NSLocalizedString(@"Action",@"")];
    [item setToolTip:NSLocalizedString(@"Action for publication",@"")];
    [item setTarget:self];
    [item setView:actionMenuButton];
    [item setMinSize:[actionMenuButton bounds].size];
    [item setMaxSize:[actionMenuButton bounds].size];
    [item setMenuFormRepresentation:menuItem];
    [toolbarItems setObject:item forKey:BibEditorToolbarActionItemIdentifier];
    [item release];
    
    // Authors
	menuItem = [[[NSMenuItem allocWithZone:menuZone] initWithTitle:NSLocalizedString(@"Authors",@"") 
											                action:NULL
                                                     keyEquivalent:@""] autorelease];
	submenu = [[[NSMenu allocWithZone:menuZone] initWithTitle:@""] autorelease];
    [menuItem setSubmenu:submenu];
    item = [[OAToolbarItem alloc] initWithItemIdentifier:BibEditorToolbarAuthorTableItemIdentifier];
    [item setDelegate:self];
    [item setLabel:NSLocalizedString(@"Authors",@"")];
    [item setPaletteLabel:NSLocalizedString(@"Authors",@"")];
    [item setToolTip:NSLocalizedString(@"Authors",@"")];
    [item setTarget:self];
    [item setView:authorScrollView];
    [item setMinSize:[authorScrollView bounds].size];
    [item setMaxSize:[authorScrollView bounds].size];
    [item setMenuFormRepresentation:menuItem];
    [toolbarItems setObject:item forKey:BibEditorToolbarAuthorTableItemIdentifier];
    [item release];
    
    // Delete
    item = [[OAToolbarItem alloc] initWithItemIdentifier:BibEditorToolbarDeleteItemIdentifier];
    [item setLabel:NSLocalizedString(@"Delete",@"")];
    [item setPaletteLabel:NSLocalizedString(@"Delete Publication",@"")];
    [item setToolTip:NSLocalizedString(@"Delete selected publication",@"")];
    [item setTarget:self];
    [item setImage:[NSImage imageWithLargeIconForToolboxCode:kToolbarDeleteIcon]];
    [item setAction:@selector(deletePub:)];
    [toolbarItems setObject:item forKey:BibEditorToolbarDeleteItemIdentifier];
    [item release];
    
    // New
    NSImage *image = [[[NSImage alloc] initWithSize:NSMakeSize(32, 32)] autorelease];
    [image lockFocus];
	[[NSImage imageNamed: @"newdoc"] compositeToPoint:NSZeroPoint operation:NSCompositeSourceOver]; 
    [[NSImage imageWithLargeIconForToolboxCode:kAliasBadgeIcon] compositeToPoint:NSMakePoint(8,-10) operation:NSCompositeSourceOver];
    [image unlockFocus];
    item = [[OAToolbarItem alloc] initWithItemIdentifier:BibEditorToolbarAddWithCrossrefItemIdentifier];
    [item setLabel:NSLocalizedString(@"New",@"")];
    [item setPaletteLabel:NSLocalizedString(@"New with Crossref",@"")];
    [item setToolTip:NSLocalizedString(@"New Publication with Crossref",@"")];
    [item setTarget:self];
    [item setImage:image];
    [item setAction:@selector(createNewPubUsingCrossrefAction:)];
    [toolbarItems setObject:item forKey:BibEditorToolbarAddWithCrossrefItemIdentifier];
    [item release];
    
    // Attach the toolbar to the document window
    [[self window] setToolbar: toolbar];
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
		BibEditorToolbarViewLocalItemIdentifier,
		BibEditorToolbarViewRemoteItemIdentifier,
		BibEditorToolbarSnoopDrawerItemIdentifier,
		NSToolbarFlexibleSpaceItemIdentifier, 
		BibEditorToolbarAuthorTableItemIdentifier, nil];
}


- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar {
    return [NSArray arrayWithObjects: 
		BibEditorToolbarViewLocalItemIdentifier,
		BibEditorToolbarViewRemoteItemIdentifier,
		BibEditorToolbarSnoopDrawerItemIdentifier,
		BibEditorToolbarAuthorTableItemIdentifier,
        BibEditorToolbarActionItemIdentifier,
		BibEditorToolbarDeleteItemIdentifier,
		BibEditorToolbarAddWithCrossrefItemIdentifier,
		NSToolbarFlexibleSpaceItemIdentifier, 
		NSToolbarSpaceItemIdentifier, 
		NSToolbarSeparatorItemIdentifier, 
		NSToolbarCustomizeToolbarItemIdentifier, nil];
}

- (void) toolbarWillAddItem: (NSNotification *) notif {
    NSToolbarItem *addedItem = [[notif userInfo] objectForKey: @"item"];
    
	if([[addedItem itemIdentifier] isEqualToString: BibEditorToolbarViewLocalItemIdentifier]) {
		if (viewLocalToolbarItem != addedItem) {
			[viewLocalToolbarItem autorelease];
			viewLocalToolbarItem = [addedItem retain];
            [[[viewLocalToolbarItem menuFormRepresentation] submenu] setDelegate:self];
		}
    }
	else if([[addedItem itemIdentifier] isEqualToString: BibEditorToolbarViewRemoteItemIdentifier]) {
		if (viewRemoteToolbarItem != addedItem) {
			[viewRemoteToolbarItem autorelease];
			viewRemoteToolbarItem = [addedItem retain];
            [[[viewRemoteToolbarItem menuFormRepresentation] submenu] setDelegate:self];
		}
    }
	else if([[addedItem itemIdentifier] isEqualToString: BibEditorToolbarSnoopDrawerItemIdentifier]) {
		if (documentSnoopToolbarItem != addedItem) {
			[documentSnoopToolbarItem autorelease];
			documentSnoopToolbarItem = [addedItem retain];
            [[[documentSnoopToolbarItem menuFormRepresentation] submenu] setDelegate:self];
		}
    }
	else if([[addedItem itemIdentifier] isEqualToString: BibEditorToolbarAuthorTableItemIdentifier]) {
		if (authorsToolbarItem != addedItem) {
			[authorsToolbarItem autorelease];
			authorsToolbarItem = [addedItem retain];
            [[[authorsToolbarItem menuFormRepresentation] submenu] setDelegate:self];
		}
    }

}

/*
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

    return enable;
}


@end
