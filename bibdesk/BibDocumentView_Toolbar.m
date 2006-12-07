//
//  BibDocumentView_Toolbar.m
//  Bibdesk
//
//  Created by Michael McCracken on Wed Jul 03 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import "BibDocumentView_Toolbar.h"

static NSString* 	BibDocToolbarIdentifier 		= @"BibDesk Browser Toolbar Identifier";
static NSString*	NewDocToolbarItemIdentifier 	= @"New Document Item Identifier";
static NSString*	QuickSearchDocToolbarItemIdentifier 	= @"QuickSearch Document Item Identifier";
static NSString*	EditDocToolbarItemIdentifier 	= @"Edit Document Item Identifier";
static NSString*	DelDocToolbarItemIdentifier 	= @"Del Document Item Identifier";
static NSString*	PrvDocToolbarItemIdentifier 	= @"Show Preview  Item Identifier";
static NSString*	SortByDocToolbarItemIdentifier 	= @"Sort by Item Identifier";
static NSString*	ToggleCiteDrawerToolbarItemIdentifier 	= @"Toggle Cite Drawer Identifier";

@implementation BibDocument (Toolbar)

// ----------------------------------------------------------------------------------------

// toolbar stuff

// ----------------------------------------------------------------------------------------

- (void) setupToolbar {
    // Create a new toolbar instance, and attach it to our document window
    NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier:BibDocToolbarIdentifier] autorelease];

    // Set up toolbar properties: Allow customization, give a default display mode, and remember state in user defaults
    [toolbar setAllowsUserCustomization: YES];
    [toolbar setAutosavesConfiguration: YES];
    [toolbar setDisplayMode: NSToolbarDisplayModeDefault];

    // We are the delegate
    [toolbar setDelegate: self];

    // this is a bad hack. i'm probably going to leak tons of NSButtons.
    [sortKeyButton retain];

    // Attach the toolbar to the document window
    [documentWindow setToolbar: toolbar];
}



- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted {
    NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdent] autorelease];

    if ([itemIdent isEqualToString: NewDocToolbarItemIdentifier]) {
        [toolbarItem setLabel:
            NSLocalizedString(@"New",@"")];
        [toolbarItem setPaletteLabel:
            NSLocalizedString(@"New Publication",@"")];
        [toolbarItem setToolTip:
            NSLocalizedString(@"Create New Publication",@"")];
        [toolbarItem setImage: [NSImage imageNamed: @"newdoc"]];
        [toolbarItem setTarget: self];
        [toolbarItem setAction: @selector(newPub:)];
    } else if([itemIdent isEqualToString:DelDocToolbarItemIdentifier]){
        [toolbarItem setLabel:
            NSLocalizedString(@"Delete",@"")];
        [toolbarItem setPaletteLabel:
            NSLocalizedString(@"Delete Publication",@"")];
        [toolbarItem setToolTip:
            NSLocalizedString(@"Delete Selected Publication(s)",@"")];
        [toolbarItem setImage: [NSImage imageNamed: @"deldoc"]];
        [toolbarItem setTarget: self];
        [toolbarItem setAction: @selector(delPub:)];
    } else if([itemIdent isEqualToString:EditDocToolbarItemIdentifier]){
        [toolbarItem setLabel:
            NSLocalizedString(@"Edit",@"")];
        [toolbarItem setPaletteLabel:
            NSLocalizedString(@"Edit Publication",@"")];
        [toolbarItem setToolTip:
            NSLocalizedString(@"Edit Selected Publication",@"")];
        [toolbarItem setImage: [NSImage imageNamed: @"editdoc"]];
        [toolbarItem setTarget: self];
        [toolbarItem setAction: @selector(editPubCmd:)];
    } else if([itemIdent isEqualToString: QuickSearchDocToolbarItemIdentifier]) {

        [toolbarItem setLabel:
            NSLocalizedString(@"Substring Search",@"")];
        [toolbarItem setPaletteLabel:
            NSLocalizedString(@"Substring Search",@"")];
        [toolbarItem setToolTip:
            NSLocalizedString(@"Search Publications",@"")];
        [toolbarItem setView: quickSearchBox];
        [toolbarItem setMinSize:NSMakeSize(300, NSHeight([quickSearchBox frame]))];
        [toolbarItem setMaxSize:NSMakeSize(400,NSHeight([quickSearchBox frame]))];

    } else if([itemIdent isEqualToString: PrvDocToolbarItemIdentifier]) {
        [toolbarItem setLabel:
            NSLocalizedString(@"Preview",@"")];
        [toolbarItem setPaletteLabel:
            NSLocalizedString(@"Show Preview",@"")];
        [toolbarItem setToolTip:
            NSLocalizedString(@"Show PDF Preview",@"")];
        [toolbarItem setImage: [NSImage imageNamed: @"previewdoc"]]; // get an image!
        [toolbarItem setTarget: nil]; //nil because bibappcontroller gets it.
        [toolbarItem setAction: @selector(toggleShowingPreviewPanel:)];

    } else if([itemIdent isEqualToString: SortByDocToolbarItemIdentifier]) {
        // this one switches between outline and tableviews.
        [toolbarItem setLabel:
            NSLocalizedString(@"Change View",@"")];
        [toolbarItem setPaletteLabel:
            NSLocalizedString(@"Change View",@"")];
        [toolbarItem setToolTip:
            NSLocalizedString(@"Change the way publications are viewed.",@"")];
        
        [toolbarItem setView:sortKeyButton];
        [toolbarItem setMinSize:NSMakeSize(100, NSHeight([quickSearchBox frame]))];
        [toolbarItem setMaxSize:NSMakeSize(100,NSHeight([quickSearchBox frame]))];
    }else if([itemIdent isEqualToString: ToggleCiteDrawerToolbarItemIdentifier]){
        [toolbarItem setLabel:
            NSLocalizedString(@"Cite Drawer",@"")];
        [toolbarItem setPaletteLabel:
            NSLocalizedString(@"Show Custom Citations Drawer",@"")];
        [toolbarItem setToolTip:
            NSLocalizedString(@"Show Custom Citations Drawer",@"")];
        [toolbarItem setImage: [NSImage imageNamed: @"drawerToolbarImage"]]; 
        [toolbarItem setTarget: self];
        [toolbarItem setAction: @selector(toggleShowingCustomCiteDrawer:)];

    }else {
        // itemIdent refered to a toolbar item that is not provide or supported by us or cocoa
        // Returning nil will inform the toolbar self kind of item is not supported
        toolbarItem = nil;
    }
    return toolbarItem;
}



- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar {
    //SortByDocToolbarItemIdentifier, will be added when the outline view works.
    return [NSArray arrayWithObjects:	NewDocToolbarItemIdentifier,  EditDocToolbarItemIdentifier, NSToolbarSeparatorItemIdentifier, QuickSearchDocToolbarItemIdentifier, DelDocToolbarItemIdentifier, ToggleCiteDrawerToolbarItemIdentifier, nil];
}


- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar {
    //SortByDocToolbarItemIdentifier, will be added when the outline view works.

    return [NSArray arrayWithObjects: SortByDocToolbarItemIdentifier, QuickSearchDocToolbarItemIdentifier, NewDocToolbarItemIdentifier, EditDocToolbarItemIdentifier, DelDocToolbarItemIdentifier,PrvDocToolbarItemIdentifier ,  NSToolbarFlexibleSpaceItemIdentifier, NSToolbarSpaceItemIdentifier, NSToolbarSeparatorItemIdentifier, NSToolbarCustomizeToolbarItemIdentifier, ToggleCiteDrawerToolbarItemIdentifier,nil];
}

- (void) toolbarWillAddItem: (NSNotification *) notif {
    NSToolbarItem *addedItem = [[notif userInfo] objectForKey: @"item"];

    if([[addedItem itemIdentifier] isEqualToString: QuickSearchDocToolbarItemIdentifier]) {
        quickSearchToolbarItem = [addedItem retain];
    }else if([[addedItem itemIdentifier] isEqualToString: SortByDocToolbarItemIdentifier]){
        sortKeyButton = [addedItem retain]; //hmmmm....
    }else if([[addedItem itemIdentifier] isEqualToString: DelDocToolbarItemIdentifier]){
        delPubButton = addedItem;
    }else if([[addedItem itemIdentifier] isEqualToString: EditDocToolbarItemIdentifier]){
        editPubButton = addedItem;
    }

}


- (void) toolbarDidRemoveItem: (NSNotification *) notif {
    // Optional delegate method   After an item is removed from a toolbar the notification is sent   self allows
    // the chance to tear down information related to the item that may have been cached   The notification object
    // is the toolbar to which the item is being added   The item being added is found by referencing the @"item"
    // key in the userInfo
    NSToolbarItem *removedItem = [[notif userInfo] objectForKey: @"item"];
    if(quickSearchToolbarItem==removedItem){
        [quickSearchToolbarItem autorelease];
        quickSearchToolbarItem = nil;
        [quickSearchBox retain];
        [quickSearchButton retain];
        [quickSearchTextField retain];
    }else if(removedItem == sortKeyButton){
        [sortKeyToolbarItem autorelease];
        sortKeyToolbarItem = nil;
        [sortKeyButton retain];
    }
}

- (BOOL) validateToolbarItem: (NSToolbarItem *) toolbarItem {
    // Optional method   self message is sent to us since we are the target of some toolbar item actions
    // (for example:  of the save items action)
    BOOL enable = YES;
    if ([[toolbarItem itemIdentifier] isEqualToString: NSToolbarPrintItemIdentifier]) {
        enable = NO;
    }else if([[toolbarItem itemIdentifier] isEqualToString: DelDocToolbarItemIdentifier]
             || [[toolbarItem itemIdentifier] isEqualToString: EditDocToolbarItemIdentifier]){
        if([self numberOfSelectedPubs] == 0) enable = NO;
    }

    return enable;
}


@end
