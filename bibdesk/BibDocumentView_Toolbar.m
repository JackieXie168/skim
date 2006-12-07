//  BibDocumentView_Toolbar.m

//  Created by Michael McCracken on Wed Jul 03 2002.
/*
 This software is Copyright (c) 2002,2003,2004,2005,2006
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

#define TOOLBAR_BUTTON_SIZE NSMakeSize(39.0, 32.0)
#define TOOLBAR_SEARCHFIELD_MIN_SIZE NSMakeSize(110.0, 22.0)
#define TOOLBAR_SEARCHFIELD_MAX_SIZE NSMakeSize(1000.0, 22.0)

NSString *BibDocumentToolbarIdentifier = @"BibDocumentToolbarIdentifier";
NSString *BibDocumentToolbarNewItemIdentifier = @"BibDocumentToolbarNewItemIdentifier";
NSString *BibDocumentToolbarSearchItemIdentifier = @"BibDocumentToolbarSearchItemIdentifier";
NSString *BibDocumentToolbarActionItemIdentifier = @"BibDocumentToolbarActionItemIdentifier";
NSString *BibDocumentToolbarGroupActionItemIdentifier = @"BibDocumentToolbarGroupActionItemIdentifier";
NSString *BibDocumentToolbarEditItemIdentifier = @"BibDocumentToolbarEditItemIdentifier";
NSString *BibDocumentToolbarDeleteItemIdentifier = @"BibDocumentToolbarDeleteItemIdentifier";
NSString *BibDocumentToolbarPreviewItemIdentifier = @"BibDocumentToolbarPreviewItemIdentifier";
NSString *BibDocumentToolbarCiteDrawerItemIdentifier = @"BibDocumentToolbarCiteDrawerItemIdentifier";

@implementation BibDocument (Toolbar)

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
    NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier:BibDocumentToolbarIdentifier] autorelease];
    NSMenuItem *menuItem;

    toolbarItems=[[NSMutableDictionary dictionary] retain];
    
    // Set up toolbar properties: Allow customization, give a default display mode, and remember state in user defaults
    [toolbar setAllowsUserCustomization: YES];
    [toolbar setAutosavesConfiguration: YES];
    [toolbar setDisplayMode: NSToolbarDisplayModeDefault];

    // We are the delegate
    [toolbar setDelegate: self];

    // add toolbaritems:

    addToolbarItem(toolbarItems, BibDocumentToolbarNewItemIdentifier,
                   NSLocalizedString(@"New",@""), 
				   NSLocalizedString(@"New Publication",@""),
                   NSLocalizedString(@"Create new publication",@""),
                   self, @selector(setImage:),
				   [NSImage imageNamed: @"newdoc"], 
				   @selector(newPub:),
                   nil);

    addToolbarItem(toolbarItems, BibDocumentToolbarDeleteItemIdentifier,
                   NSLocalizedString(@"Delete",@""), 
				   NSLocalizedString(@"Delete Publication",@""),
                   NSLocalizedString(@"Delete selected publication(s)",@""),
                   self, @selector(setImage:),  
				   [NSImage imageWithLargeIconForToolboxCode:kToolbarDeleteIcon],
				   @selector(deleteSelectedPubs:),
                   nil);

    addToolbarItem(toolbarItems, BibDocumentToolbarEditItemIdentifier,
                   NSLocalizedString(@"Edit",@""),
                   NSLocalizedString(@"Edit Publication",@""),
                   NSLocalizedString(@"Edit selected publication(s)",@""),
                   self, @selector(setImage:), 
				   [NSImage imageNamed: @"editdoc"],
                   @selector(editPubCmd:), 
				   nil);

	addToolbarItem(toolbarItems, BibDocumentToolbarPreviewItemIdentifier,
                   NSLocalizedString(@"Preview",@""),
                   NSLocalizedString(@"Show/Hide Preview",@""),
                   NSLocalizedString(@"Show/Hide preview panel",@""),
                   nil, @selector(setImage:),
                   [NSImage imageNamed: @"preview"],
                   @selector(toggleShowingPreviewPanel:), NULL);
	
    addToolbarItem(toolbarItems, BibDocumentToolbarCiteDrawerItemIdentifier,
                   NSLocalizedString(@"Cite Drawer",@""),
                   NSLocalizedString(@"Toggle Custom Citations Drawer",@""),
                   NSLocalizedString(@"Toggle custom citations drawer",@""),
                   self, @selector(setImage:),
                   [NSImage imageNamed: @"drawerToolbarImage"],
                   @selector(toggleShowingCustomCiteDrawer:), nil);
	
	
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Search",@"") 
										   action:@selector(performFindPanelAction:)
									keyEquivalent:@""] autorelease];
	[menuItem setTag:NSFindPanelActionShowFindPanel];
	[menuItem setTarget:self];
    addToolbarItem(toolbarItems, BibDocumentToolbarSearchItemIdentifier,
                   NSLocalizedString(@"Search",@""),
                   NSLocalizedString(@"Search",@""),
                   NSLocalizedString(@"Search using boolean '+' and '|', see Help for details",@""),
                   self, @selector(setView:),
                   searchField,
                   @selector(searchFieldAction:), 
				   menuItem);
	
	
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Action",@"") 
										   action:NULL 
									keyEquivalent:@""] autorelease];
	[menuItem setSubmenu: actionMenu];
    addToolbarItem(toolbarItems, BibDocumentToolbarActionItemIdentifier,
                   NSLocalizedString(@"Action",@""),
                   NSLocalizedString(@"Action",@""),
                   NSLocalizedString(@"Action for selected publications",@""),
                   self, @selector(setView:),
                   actionMenuButton,
                   NULL, 
				   menuItem);
	
	
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Group Action",@"") 
										   action:NULL 
									keyEquivalent:@""] autorelease];
	[menuItem setSubmenu: groupMenu];
    addToolbarItem(toolbarItems, BibDocumentToolbarGroupActionItemIdentifier,
                   NSLocalizedString(@"Group Action",@""),
                   NSLocalizedString(@"Group Action",@""),
                   NSLocalizedString(@"Action for groups list",@""),
                   self, @selector(setView:),
                   groupActionMenuButton,
                   NULL, 
				   menuItem);
    
    // Attach the toolbar to the document window
    [documentWindow setToolbar: toolbar];
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
        // Set the sizes as a regular control size
        // The actual controlSize might be different, so we shouldn't use [self bounds].size
        if ([itemIdent isEqualToString:BibDocumentToolbarSearchItemIdentifier]) {
            [newItem setMinSize:TOOLBAR_SEARCHFIELD_MIN_SIZE];
            [newItem setMaxSize:TOOLBAR_SEARCHFIELD_MAX_SIZE];
        } else {
            // this is an action button
            [newItem setMinSize:TOOLBAR_BUTTON_SIZE];
            [newItem setMaxSize:TOOLBAR_BUTTON_SIZE];
        } 
    } else {
        [newItem setImage:[item image]];
        if([itemIdent isEqualToString: BibDocumentToolbarNewItemIdentifier]) {
            NSImage *image = [[[NSImage alloc] initWithSize:NSMakeSize(32, 32)] autorelease];
            [image lockFocus];
            [[item image] compositeToPoint:NSZeroPoint operation:NSCompositeSourceOver]; 
            [[NSImage imageWithLargeIconForToolboxCode:kAliasBadgeIcon] compositeToPoint:NSMakePoint(8,-10) operation:NSCompositeSourceOver];
            [image unlockFocus];
            [newItem setOptionKeyImage:image];
            [newItem setOptionKeyLabel:NSLocalizedString(@"New with Crossref", @"")];
            [newItem setOptionKeyToolTip:NSLocalizedString(@"Create new publication with crossref", @"")];
            [newItem setOptionKeyAction:@selector(createNewPubUsingCrossrefAction:)];
        }
    }
    [newItem setToolTip:[item toolTip]];
    [newItem setTarget:[item target]];
    [newItem setAction:[item action]];
    [newItem setMenuFormRepresentation:[item menuFormRepresentation]];

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

- (void) toolbarWillAddItem: (NSNotification *) notif {
    NSToolbarItem *addedItem = [[notif userInfo] objectForKey: @"item"];

    if([[addedItem itemIdentifier] isEqualToString: BibDocumentToolbarSearchItemIdentifier]) {
//		searchFieldToolbarItem = addedItem;
    }else if([[addedItem itemIdentifier] isEqualToString: BibDocumentToolbarDeleteItemIdentifier]){
//        delPubButton = addedItem;
    }else if([[addedItem itemIdentifier] isEqualToString: BibDocumentToolbarEditItemIdentifier]){
//        editPubButton = addedItem;
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
    if ([[toolbarItem itemIdentifier] isEqualToString: NSToolbarPrintItemIdentifier]) {
		enable = [self validatePrintDocumentMenuItem:nil];
    }else if([[toolbarItem itemIdentifier] isEqualToString: BibDocumentToolbarEditItemIdentifier]
			 || [[toolbarItem itemIdentifier] isEqualToString: BibDocumentToolbarActionItemIdentifier]){
        if([self numberOfSelectedPubs] == 0) enable = NO;
    }else if([[toolbarItem itemIdentifier] isEqualToString: BibDocumentToolbarDeleteItemIdentifier]){
        if([self numberOfSelectedPubs] == 0 || [documentWindow isKeyWindow] == NO) enable = NO;  // disable click-through
    }else if([[toolbarItem itemIdentifier] isEqualToString: BibDocumentToolbarNewItemIdentifier]){
        if(([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) && [self numberOfSelectedPubs] != 1) enable = NO;
    }
    return enable;
}


@end
