//  BibDocumentView_Toolbar.m

//  Created by Michael McCracken on Wed Jul 03 2002.
/*
This software is Copyright (c) 2002, Michael O. McCracken
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
-  Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
-  Neither the name of Michael O. McCracken nor the names of any contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "BibDocumentView_Toolbar.h"

NSString* 	BibDocToolbarIdentifier 		= @"BibDesk Browser Toolbar Identifier";
NSString*	NewDocToolbarItemIdentifier 	= @"New Document Item Identifier";
NSString*	SearchFieldDocToolbarItemIdentifier 	= @"NSSearchField Document Item Identifier";
NSString*	ActionMenuToolbarItemIdentifier 	= @"Action Menu Item Identifier";
NSString*	EditDocToolbarItemIdentifier 	= @"Edit Document Item Identifier";
NSString*	DelDocToolbarItemIdentifier 	= @"Del Document Item Identifier";
NSString*	PrvDocToolbarItemIdentifier 	= @"Show Preview  Item Identifier";
NSString*	ToggleCiteDrawerToolbarItemIdentifier 	= @"Toggle Cite Drawer Identifier";

@implementation BibDocument (Toolbar)

// ----------------------------------------------------------------------------------------
// toolbar stuff
// ----------------------------------------------------------------------------------------

// label, palettelabel, toolTip, action, and menu can all be NULL, depending upon what you want the item to do
static void addToolbarItem(NSMutableDictionary *theDict,NSString *identifier,NSString *label,NSString *paletteLabel,NSString *toolTip,id target,SEL settingSelector, id itemContent,SEL action, NSMenuItem *menuItem)
{
    NSMenuItem *mItem;
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
    NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier:BibDocToolbarIdentifier] autorelease];
    NSMenuItem *menuItem;

    toolbarItems=[[NSMutableDictionary dictionary] retain];
    
    // Set up toolbar properties: Allow customization, give a default display mode, and remember state in user defaults
    [toolbar setAllowsUserCustomization: YES];
    [toolbar setAutosavesConfiguration: YES];
    [toolbar setDisplayMode: NSToolbarDisplayModeDefault];

    // We are the delegate
    [toolbar setDelegate: self];

    // add toolbaritems:

    addToolbarItem(toolbarItems, NewDocToolbarItemIdentifier,
                   NSLocalizedString(@"New",@""), 
				   NSLocalizedString(@"New Publication",@""),
                   NSLocalizedString(@"Create New Publication",@""),
                   self, @selector(setImage:),
				   [NSImage imageNamed: @"newdoc"], 
				   @selector(newPub:),
                   nil);

    addToolbarItem(toolbarItems, DelDocToolbarItemIdentifier,
                   NSLocalizedString(@"Delete",@""), 
				   NSLocalizedString(@"Delete Publication",@""),
                   NSLocalizedString(@"Delete Selected Publication(s)",@""),
                   self, @selector(setImage:),  
				   [NSImage imageWithLargeIconForToolboxCode:kToolbarDeleteIcon],
				   @selector(delPub:),
                   nil);

    addToolbarItem(toolbarItems, EditDocToolbarItemIdentifier,
                   NSLocalizedString(@"Edit",@""),
                   NSLocalizedString(@"Edit Publication",@""),
                   NSLocalizedString(@"Edit Selected Publication(s)",@""),
                   self, @selector(setImage:), 
				   [NSImage imageNamed: @"editdoc"],
                   @selector(editPubCmd:), 
				   nil);

    addToolbarItem(toolbarItems, EditDocToolbarItemIdentifier,
                   NSLocalizedString(@"Edit",@""),
                   NSLocalizedString(@"Edit Publication",@""),
                   NSLocalizedString(@"Edit Selected Publication(s)",@""),
                   self, @selector(setImage:), 
				   [NSImage imageNamed: @"editdoc"],
                   @selector(editPubCmd:), 
				   nil);
	
	
	addToolbarItem(toolbarItems, PrvDocToolbarItemIdentifier,
                   NSLocalizedString(@"Preview",@""),
                   NSLocalizedString(@"Show/Hide Preview",@""),
                   NSLocalizedString(@"Show/Hide Preview Panel",@""),
                   nil, @selector(setImage:),
                   [NSImage imageNamed: @"preview"],
                   @selector(toggleShowingPreviewPanel:), NULL);
	
	
    addToolbarItem(toolbarItems, ToggleCiteDrawerToolbarItemIdentifier,
                   NSLocalizedString(@"Cite Drawer",@""),
                   NSLocalizedString(@"Toggle Custom Citations Drawer",@""),
                   NSLocalizedString(@"Toggle Custom Citations Drawer",@""),
                   self, @selector(setImage:),
                   [NSImage imageNamed: @"drawerToolbarImage"],
                   @selector(toggleShowingCustomCiteDrawer:), nil);
	
	
	menuItem = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Search",@"") 
										   action:@selector(find:)
									keyEquivalent:@""] autorelease];
	[menuItem setTarget:self];
    addToolbarItem(toolbarItems, SearchFieldDocToolbarItemIdentifier,
                   NSLocalizedString(@"Search",@""),
                   NSLocalizedString(@"Search",@""),
                   NSLocalizedString(@"Search using Boolean AND and OR, see Help for details",@""),
                   self, @selector(setView:),
                   searchFieldView,
                   NULL, 
				   menuItem);
	
	
	menuItem = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Action",@"") 
										   action:NULL 
									keyEquivalent:@""] autorelease];
	[menuItem setSubmenu: actionMenu];
    addToolbarItem(toolbarItems, ActionMenuToolbarItemIdentifier,
                   NSLocalizedString(@"Action",@""),
                   NSLocalizedString(@"Action",@""),
                   NSLocalizedString(@"Action for Selection",@""),
                   self, @selector(setView:),
                   actionMenuButton,
                   NULL, 
				   menuItem);
    
    // Attach the toolbar to the document window
    [documentWindow setToolbar: toolbar];
}

- (IBAction)find:(id)sender{
    NSToolbar *tb = [documentWindow toolbar];
    [tb setVisible:YES];
    if([tb displayMode] == NSToolbarDisplayModeLabelOnly)
	[tb setDisplayMode:NSToolbarDisplayModeIconAndLabel];
    if(BDSK_USING_JAGUAR)
	[searchFieldTextField selectText:nil];
    else
	[searchField selectText:nil];
}

- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar
      itemForItemIdentifier: (NSString *)itemIdent
  willBeInsertedIntoToolbar:(BOOL) willBeInserted {

    OAToolbarItem *newItem = [[[OAToolbarItem alloc] initWithItemIdentifier:itemIdent] autorelease];
    NSToolbarItem *item=[toolbarItems objectForKey:itemIdent];

    [newItem setLabel:[item label]];
    [newItem setPaletteLabel:[item paletteLabel]];
    if ([item view]!=nil)
    {
        [newItem setView:[item view]];
		[newItem setDelegate:self];
    }
    else
    {
        [newItem setImage:[item image]];
    }
    [newItem setToolTip:[item toolTip]];
    [newItem setTarget:[item target]];
    [newItem setAction:[item action]];
    [newItem setMenuFormRepresentation:[item menuFormRepresentation]];
    // If we have a custom view, we *have* to set the min/max size - otherwise, it'll default to 0,0 and the custom
    // view won't show up at all!  This doesn't affect toolbar items with images, however.
    if ([itemIdent isEqualToString:SearchFieldDocToolbarItemIdentifier])
    {
        [newItem setMinSize:NSMakeSize(110,NSHeight([[item view] bounds]))];
        [newItem setMaxSize:NSMakeSize(1000,NSHeight([[item view] bounds]))];
    }
	else if ([newItem view]!=nil)
    {
        [newItem setMinSize:[[item view] bounds].size];
        [newItem setMaxSize:[[item view] bounds].size];
    }

    return newItem;
}



- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar {
    return [NSArray arrayWithObjects:
		ActionMenuToolbarItemIdentifier,
		NSToolbarSpaceItemIdentifier, 
		NewDocToolbarItemIdentifier,
		EditDocToolbarItemIdentifier, 
		DelDocToolbarItemIdentifier, 
		NSToolbarSeparatorItemIdentifier, 
		PrvDocToolbarItemIdentifier,
		NSToolbarFlexibleSpaceItemIdentifier, 
		SearchFieldDocToolbarItemIdentifier,
		ToggleCiteDrawerToolbarItemIdentifier, nil];
}


- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar {
    return [NSArray arrayWithObjects: 
		NewDocToolbarItemIdentifier, 
		EditDocToolbarItemIdentifier, 
		DelDocToolbarItemIdentifier,
		PrvDocToolbarItemIdentifier , 
		ActionMenuToolbarItemIdentifier,
		SearchFieldDocToolbarItemIdentifier,
		ToggleCiteDrawerToolbarItemIdentifier,
		NSToolbarPrintItemIdentifier,
		NSToolbarFlexibleSpaceItemIdentifier, 
		NSToolbarSpaceItemIdentifier, 
		NSToolbarSeparatorItemIdentifier, 
		NSToolbarCustomizeToolbarItemIdentifier, nil];
}

- (void) toolbarWillAddItem: (NSNotification *) notif {
    NSToolbarItem *addedItem = [[notif userInfo] objectForKey: @"item"];

    if([[addedItem itemIdentifier] isEqualToString: SearchFieldDocToolbarItemIdentifier]) {
//		searchFieldToolbarItem = addedItem;
    }else if([[addedItem itemIdentifier] isEqualToString: DelDocToolbarItemIdentifier]){
//        delPubButton = addedItem;
    }else if([[addedItem itemIdentifier] isEqualToString: EditDocToolbarItemIdentifier]){
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
    }else if([[toolbarItem itemIdentifier] isEqualToString: DelDocToolbarItemIdentifier]
             || [[toolbarItem itemIdentifier] isEqualToString: EditDocToolbarItemIdentifier]
			 || [[toolbarItem itemIdentifier] isEqualToString: ActionMenuToolbarItemIdentifier]){
        if([self numberOfSelectedPubs] == 0) enable = NO;
    }

    return enable;
}


@end
