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
#import "BDSKMenuItem.h"

#define TOOLBAR_BUTTON_SIZE NSMakeSize(39.0, 32.0)

NSString *BibEditorToolbarIdentifier = @"BibEditorToolbarIdentifier";
NSString *BibEditorToolbarViewLocalItemIdentifier = @"BibEditorToolbarViewLocalItemIdentifier";
NSString *BibEditorToolbarViewRemoteItemIdentifier = @"BibEditorToolbarViewRemoteItemIdentifier";
NSString *BibEditorToolbarSnoopDrawerItemIdentifier = @"BibEditorToolbarSnoopDrawerItemIdentifier";
NSString *BibEditorToolbarAuthorTableItemIdentifier = @"BibEditorToolbarAuthorTableItemIdentifier";
NSString *BibEditorToolbarDeleteItemIdentifier = @"BibEditorToolbarDeleteItemIdentifier";
NSString *BibEditorToolbarAddWithCrossrefItemIdentifier = @"BibEditorToolbarAddWithCrossrefItemIdentifier";

@implementation BibEditor (Toolbar)

// ----------------------------------------------------------------------------------------
// toolbar stuff
// ----------------------------------------------------------------------------------------

// label, palettelabel, toolTip, action, and menu can all be NULL, depending upon what you want the item to do
static void addToolbarItem(NSMutableDictionary *theDict,NSString *identifier,NSString *label,NSString *paletteLabel,NSString *toolTip,id target,SEL settingSelector, id itemContent,SEL action, NSMenuItem *menuItem)
{
    // here we create the NSToolbarItem and setup its attributes in line with the parameters
    NSToolbarItem *item = [[[NSToolbarItem alloc] initWithItemIdentifier:identifier] autorelease];
    [item setLabel:label];
    [item setPaletteLabel:paletteLabel];
    [item setToolTip:toolTip];
    [item setTarget:target];
    // the settingSelector parameter can either be @selector(setView:) or @selector(setImage:).  Pass in the right
    // one depending upon whether your NSToolbarItem will have a custom view or an image, respectively
    // (in the itemContent parameter).  Then this next line will do the right thing automatically.
    [item performSelector:settingSelector withObject:itemContent];
    [item setAction:action];
    // The menuItem to be shown in text only mode. Don't reset this when we use the default behavior. 
	if (menuItem)
		[item setMenuFormRepresentation:menuItem];
    // Now that we've setup all the settings for this new toolbar item, we add it to the dictionary.
    // The dictionary retains the toolbar item for us, which is why we could autorelease it when we created
    // it (above).
    [theDict setObject:item forKey:identifier];
}

// called from WindowControllerDidLoadNib.
- (void) setupToolbar {
    // Create a new toolbar instance, and attach it to our document window
    NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier:BibEditorToolbarIdentifier] autorelease];
    BDSKMenuItem *menuItem;

    toolbarItems=[[NSMutableDictionary dictionary] retain];
    
    // Set up toolbar properties: Allow customization, give a default display mode, and remember state in user defaults
    [toolbar setAllowsUserCustomization: YES];
    [toolbar setAutosavesConfiguration: YES];
    [toolbar setDisplayMode: NSToolbarDisplayModeDefault];

    // We are the delegate
    [toolbar setDelegate: self];

    // add toolbaritems:

	menuItem = [[[BDSKMenuItem alloc] initWithTitle:NSLocalizedString(@"View File",@"") 
											 action:NULL
									  keyEquivalent:@""] autorelease];
    [menuItem setDelegate:self];
	addToolbarItem(toolbarItems, BibEditorToolbarViewLocalItemIdentifier,
                   NSLocalizedString(@"View File",@""), 
				   NSLocalizedString(@"View File",@""),
                   NSLocalizedString(@"View File",@""),
                   nil, @selector(setView:),
				   viewLocalButton, 
				   NULL,
                   menuItem);

	menuItem = [[[BDSKMenuItem alloc] initWithTitle:NSLocalizedString(@"View Remote",@"") 
										   action:NULL
									keyEquivalent:@""] autorelease];
    [menuItem setDelegate:self];
    addToolbarItem(toolbarItems, BibEditorToolbarViewRemoteItemIdentifier,
                   NSLocalizedString(@"View Remote",@""), 
				   NSLocalizedString(@"View Remote URL",@""),
                   NSLocalizedString(@"View in Web Browser",@""),
                   nil, @selector(setView:),
				   viewRemoteButton, 
				   NULL,
                   menuItem);

	menuItem = [[[BDSKMenuItem alloc] initWithTitle:NSLocalizedString(@"View in Drawer",@"") 
											 action:NULL
									  keyEquivalent:@""] autorelease];
    [menuItem setDelegate:self];
    addToolbarItem(toolbarItems, BibEditorToolbarSnoopDrawerItemIdentifier,
                   NSLocalizedString(@"View in Drawer",@""), 
				   NSLocalizedString(@"View in Drawer",@""),
                   NSLocalizedString(@"View File in Drawer",@""),
                   nil, @selector(setView:),
				   documentSnoopButton, 
				   NULL,
                   menuItem);

	menuItem = [[[BDSKMenuItem alloc] initWithTitle:NSLocalizedString(@"Authors",@"") 
											 action:@selector(showPersonDetailCmd:)
									  keyEquivalent:@""] autorelease];
    [menuItem setTarget:self];
    addToolbarItem(toolbarItems, BibEditorToolbarAuthorTableItemIdentifier,
                   NSLocalizedString(@"Authors",@""), 
				   NSLocalizedString(@"Authors",@""),
                   NSLocalizedString(@"Authors",@""),
                   nil, @selector(setView:),  
				   authorScrollView,
				   NULL,
                   menuItem);

	menuItem = [[[BDSKMenuItem alloc] initWithTitle:NSLocalizedString(@"Delete",@"Delete") 
											 action:@selector(deletePub:)
									  keyEquivalent:@""] autorelease];
    [menuItem setDelegate:self];
    addToolbarItem(toolbarItems, BibEditorToolbarDeleteItemIdentifier,
                   NSLocalizedString(@"Delete",@"Delete"), 
				   NSLocalizedString(@"Delete Publication",@"Delete Publication"),
                   NSLocalizedString(@"Delete Publication",@"Delete Publication"),
                   nil, @selector(setImage:),
				   [NSImage imageWithLargeIconForToolboxCode:kToolbarDeleteIcon],
				   @selector(deletePub:),
                   menuItem);

	menuItem = [[[BDSKMenuItem alloc] initWithTitle:NSLocalizedString(@"New",@"New") 
											 action:@selector(createNewPubUsingCrossrefAction:)
									  keyEquivalent:@""] autorelease];
    [menuItem setDelegate:self];
    NSImage *image = [[[NSImage alloc] initWithSize:NSMakeSize(32, 32)] autorelease];
    [image lockFocus];
	[[NSImage imageNamed: @"newdoc"] compositeToPoint:NSZeroPoint operation:NSCompositeSourceOver]; 
    [[NSImage imageWithLargeIconForToolboxCode:kAliasBadgeIcon] compositeToPoint:NSMakePoint(8,-10) operation:NSCompositeSourceOver];
    [image unlockFocus];
    addToolbarItem(toolbarItems, BibEditorToolbarAddWithCrossrefItemIdentifier,
                   NSLocalizedString(@"New",@"New"), 
				   NSLocalizedString(@"New with Crossref",@"New with Crossref"),
                   NSLocalizedString(@"New Publication with Crossref",@"New Publication with Crossref"),
                   nil, @selector(setImage:),
				   image, 
				   @selector(createNewPubUsingCrossrefAction:),
                   menuItem);
    
    // Attach the toolbar to the document window
    [[self window] setToolbar: toolbar];
}



- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar
      itemForItemIdentifier: (NSString *)itemIdent
  willBeInsertedIntoToolbar:(BOOL) willBeInserted {

    OAToolbarItem *newItem = [[[OAToolbarItem alloc] initWithItemIdentifier:itemIdent] autorelease];
    NSToolbarItem *item = [toolbarItems objectForKey:itemIdent];

    [newItem setLabel:[item label]];
    [newItem setPaletteLabel:[item paletteLabel]];
    if ([item view] != nil) {
        [newItem setView:[item view]];
		[newItem setDelegate:self];
        // If we have a custom view, we *have* to set the min/max size - otherwise, it'll default to 0,0 and the custom
        // view won't show up at all!  This doesn't affect toolbar items with images, however.
        if ([itemIdent isEqualToString:BibEditorToolbarAuthorTableItemIdentifier]) {
            [newItem setMinSize:[[item view] bounds].size];
            [newItem setMaxSize:[[item view] bounds].size];
        } else {
            // This is an BDSKImagePopUpButton
            // Set the sizes as a regular control size
            // The actual controlSize might be different, so we shouldn't use [self bounds].size
            [newItem setMinSize:TOOLBAR_BUTTON_SIZE];
            [newItem setMaxSize:TOOLBAR_BUTTON_SIZE];
        }
    } else {
        [newItem setImage:[item image]];
    }
    [newItem setToolTip:[item toolTip]];
    [newItem setTarget:[item target]];
    [newItem setAction:[item action]];
    [newItem setMenuFormRepresentation:[item menuFormRepresentation]];

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
		}
    }
	else if([[addedItem itemIdentifier] isEqualToString: BibEditorToolbarViewRemoteItemIdentifier]) {
		if (viewRemoteToolbarItem != addedItem) {
			[viewRemoteToolbarItem autorelease];
			viewRemoteToolbarItem = [addedItem retain];
		}
    }
	else if([[addedItem itemIdentifier] isEqualToString: BibEditorToolbarSnoopDrawerItemIdentifier]) {
		if (documentSnoopToolbarItem != addedItem) {
			[documentSnoopToolbarItem autorelease];
			documentSnoopToolbarItem = [addedItem retain];
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
