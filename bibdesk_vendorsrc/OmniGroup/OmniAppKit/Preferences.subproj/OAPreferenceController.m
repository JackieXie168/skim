// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniAppKit/OAPreferenceController.h>

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <OmniBase/OmniBase.h>
#import <OmniFoundation/OmniFoundation.h>

#import "OAApplication.h"
#import "NSBundle-OAExtensions.h"
#import "NSImage-OAExtensions.h"
#import "NSToolbar-OAExtensions.h"
#import "NSView-OAExtensions.h"
#import "OAPreferenceClient.h"
#import "OAPreferenceClientRecord.h"
#import "OAPreferencesIconView.h"
#import "OAPreferencesToolbar.h"
#import "OAPreferencesWindow.h"

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Preferences.subproj/OAPreferenceController.m,v 1.88 2004/02/10 04:07:36 kc Exp $") 

@interface OAPreferenceController (Private)
- (void)_loadInterface;
- (void)_createShowAllItemsView;
- (void)_setupMultipleToolbar;
- (void)_setupCustomizableToolbar;
- (void)_resetWindowTitle;
- (void)_setCurrentClientRecord:(OAPreferenceClientRecord *)clientRecord;
- (void)_showAllIcons:(id)sender;
- (void)_defaultsDidChange:(NSNotification *)notification;
- (void)_validateRestoreDefaultsButton;
//
- (NSArray *)_categoryNames;
- (void)_registerCategoryName:(NSString *)categoryName localizedName:(NSString *)localizedCategoryName priorityNumber:(NSNumber *)priorityNumber;
- (NSString *)_localizedCategoryNameForCategoryName:(NSString *)categoryName;
- (float)_priorityForCategoryName:(NSString *)categoryName;
//
- (void)_registerClassName:(NSString *)className inCategoryNamed:(NSString *)categoryName description:(NSDictionary *)description;
@end

@interface NSToolbar (KnownPrivateMethods)
- (NSView *)_toolbarView;
- (void)setSelectedItemIdentifier:(NSString *)itemIdentifier; // Panther only
@end

@implementation OAPreferenceController

static NSString *windowFrameSaveName = @"Preferences";
static OAPreferenceController *sharedPreferenceController = nil;

// OFBundleRegistryTarget informal protocol

+ (NSString *)overrideNameForCategoryName:(NSString *)categoryName;
{
    return categoryName;
}

+ (NSString *)overrideLocalizedNameForCategoryName:(NSString *)categoryName bundle:(NSBundle *)bundle;
{
    return [bundle localizedStringForKey:categoryName value:@"" table:@"Preferences"];
}

+ (void)registerItemName:(NSString *)itemName bundle:(NSBundle *)bundle description:(NSDictionary *)description;
{
    NSString *categoryName;
    OAPreferenceController *controller;
    
    [OFBundledClass createBundledClassWithName:itemName bundle:bundle description:description];

    if ((categoryName = [description objectForKey:@"category"]) == nil)
        categoryName = @"UNKNOWN";

    controller = [self sharedPreferenceController];
    
    categoryName = [self overrideNameForCategoryName:categoryName];
    NSString *localizedCategoryName = [self overrideLocalizedNameForCategoryName:categoryName bundle:bundle];
        
    [controller _registerCategoryName:categoryName localizedName:localizedCategoryName priorityNumber:[description objectForKey:@"categoryPriority"]];
    [controller _registerClassName:itemName inCategoryNamed:categoryName description:description];
}


// Init and dealloc

+ (OAPreferenceController *)sharedPreferenceController;
{
    if (sharedPreferenceController == nil)
        sharedPreferenceController = [[self alloc] init];
    
    return sharedPreferenceController;
}

- init;
{
    [super init];
	
    categoryNamesToClientRecordsArrays = [[NSMutableDictionary alloc] init];
    localizedCategoryNames = [[NSMutableDictionary alloc] init];
    categoryPriorities = [[NSMutableDictionary alloc] init];
    allClientRecords = [[NSMutableArray alloc] init];
    preferencesIconViews = [[NSMutableArray alloc] init];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_defaultsDidChange:) name:NSUserDefaultsDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_modifierFlagsChanged:) name:OAFlagsChangedNotification object:nil];
    return self;
}

- (void)dealloc;
{
    OBPRECONDITION(NO);
}


// API

- (void)close;
{
    if ([window isVisible])
        [window performClose:nil];
}

- (NSWindow *)window;  // in case you want to do something nefarious to it like change its level, as OmniGraffle does
{
    [self _loadInterface];
    return window;
}

- (void)setTitle:(NSString *)title;
{
    [window setTitle:title];
}

- (void)setCurrentClientByClassName:(NSString *)name;
{
    unsigned int clientRecordIndex;
    
    clientRecordIndex = [allClientRecords count];
    while (clientRecordIndex--) {
        OAPreferenceClientRecord *clientRecord;

        clientRecord = [allClientRecords objectAtIndex:clientRecordIndex];
        if ([[clientRecord className] isEqualToString:name]) {
            [self _setCurrentClientRecord:clientRecord];
            return;
        }
    }
}

- (NSArray *)allClientRecords;
{
    return allClientRecords;
}

- (OAPreferenceClientRecord *)clientRecordWithShortTitle:(NSString *)shortTitle;
{
    unsigned int clientRecordIndex;

    OBPRECONDITION(shortTitle != nil);
    clientRecordIndex = [allClientRecords count];
    while (clientRecordIndex--) {
        OAPreferenceClientRecord *clientRecord;

        clientRecord = [allClientRecords objectAtIndex:clientRecordIndex];
        if ([shortTitle isEqualToString:[clientRecord shortTitle]])
            return clientRecord;
    }
    return nil;
}

- (OAPreferenceClientRecord *)clientRecordWithIdentifier:(NSString *)identifier;
{
    unsigned int clientRecordIndex;

    OBPRECONDITION(identifier != nil);
    clientRecordIndex = [allClientRecords count];
    while (clientRecordIndex--) {
        OAPreferenceClientRecord *clientRecord;

        clientRecord = [allClientRecords objectAtIndex:clientRecordIndex];
        if ([identifier isEqualToString:[clientRecord identifier]])
            return clientRecord;
    }
    return nil;
}

- (OAPreferenceClient *)clientWithShortTitle:(NSString *)shortTitle;
{
    return [[self clientRecordWithShortTitle: shortTitle] clientInstanceInController: self];
}

- (OAPreferenceClient *)clientWithIdentifier:(NSString *)identifier;
{
    return [[self clientRecordWithIdentifier: identifier] clientInstanceInController: self];
}

- (OAPreferenceClient *)currentClient;
{
    return nonretained_currentClient;
}

- (void)iconView:(OAPreferencesIconView *)iconView buttonHitAtIndex:(unsigned int)index;
{
    [self _setCurrentClientRecord:[[iconView preferenceClientRecords] objectAtIndex:index]];
}

// Actions

- (IBAction)showPreferencesPanel:(id)sender;
{
    OBASSERT([allClientRecords count] > 0); // did you forget to register your clients?
    
    [self _loadInterface];
    [self _resetWindowTitle];
    
    // Let the current client know that it is about to be displayed.
    [nonretained_currentClient becomeCurrentPreferenceClient];
    [self _validateRestoreDefaultsButton];
    [window makeKeyAndOrderFront:sender];
}

- (IBAction)restoreDefaults:(id)sender;
{
    if (([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) && ([[NSApp currentEvent] modifierFlags] & NSShiftKeyMask)) {
        // warn & wipe the entire defaults domain
        NSString *mainPrompt, *secondaryPrompt, *defaultButton, *otherButton;
        NSBundle *bundle;

        bundle = [OAPreferenceClient bundle];
        mainPrompt = NSLocalizedStringFromTableInBundle(@"Reset all preferences and other settings to their original values?", @"OmniAppKit", bundle, "message text for reset-to-defaults alert");
        secondaryPrompt = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Choosing Reset will restore all settings (including options not in this Preferences window, such as window sizes and toolbars) to the state they were in when %@ was first installed.", @"OmniAppKit", bundle, "informative text for reset-to-defaults alert"), [[NSProcessInfo processInfo] processName]];
        defaultButton = NSLocalizedStringFromTableInBundle(@"Reset", @"OmniAppKit", bundle, "alert panel button");
        otherButton = NSLocalizedStringFromTableInBundle(@"Cancel", @"OmniAppKit", bundle, "alert panel button");
        NSBeginAlertSheet(mainPrompt, defaultButton, otherButton, nil, window, self, NULL, @selector(_restoreDefaultsSheetDidEnd:returnCode:contextInfo:), @"RestoreEverything", secondaryPrompt);
    } else if ([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) {
        // warn & wipe all prefs shown in the panel
        NSString *mainPrompt, *secondaryPrompt, *defaultButton, *otherButton;
        NSBundle *bundle;

        bundle = [OAPreferenceClient bundle];
        mainPrompt = NSLocalizedStringFromTableInBundle(@"Reset all preferences to their original values?", @"OmniAppKit", bundle, "message text for reset-to-defaults alert");
        secondaryPrompt = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Choosing Reset will restore all settings in all preference panes to the state they were in when %@ was first installed.", @"OmniAppKit", bundle, "informative text for reset-to-defaults alert"), [[NSProcessInfo processInfo] processName]];
        defaultButton = NSLocalizedStringFromTableInBundle(@"Reset", @"OmniAppKit", bundle, "alert panel button");
        otherButton = NSLocalizedStringFromTableInBundle(@"Cancel", @"OmniAppKit", bundle, "alert panel button");
        NSBeginAlertSheet(mainPrompt, defaultButton, otherButton, nil, window, self, NULL, @selector(_restoreDefaultsSheetDidEnd:returnCode:contextInfo:), NULL, secondaryPrompt);
    } else {
        // OAPreferenceClient will handle warning & reverting
        [nonretained_currentClient restoreDefaults:sender];
    }
}

- (IBAction)showNextClient:(id)sender;
{
    NSMutableArray *sortedClientRecords;
    NSEnumerator *enumerator;
    NSString *key;
    unsigned int newIndex;

    sortedClientRecords = [[NSMutableArray alloc] init];
    enumerator = [[self _categoryNames] objectEnumerator];
    while ((key = [enumerator nextObject])) {
        [sortedClientRecords addObjectsFromArray:[categoryNamesToClientRecordsArrays objectForKey:key]];
    }
    
    newIndex = [sortedClientRecords indexOfObject:nonretained_currentClientRecord] + 1;
    if (newIndex < [sortedClientRecords count])
        [self _setCurrentClientRecord:[sortedClientRecords objectAtIndex:newIndex]];
    else
        [self _setCurrentClientRecord:[sortedClientRecords objectAtIndex:0]];
    
    [sortedClientRecords release];
}

- (IBAction)showPreviousClient:(id)sender;
{
    NSMutableArray *sortedClientRecords;
    NSEnumerator *enumerator;
    NSString *key;
    int newIndex;

    sortedClientRecords = [[NSMutableArray alloc] init];
    enumerator = [[self _categoryNames] objectEnumerator];
    while ((key = [enumerator nextObject])) {
        [sortedClientRecords addObjectsFromArray:[categoryNamesToClientRecordsArrays objectForKey:key]];
    }

    newIndex = [sortedClientRecords indexOfObject:nonretained_currentClientRecord] - 1;
    if (newIndex < 0)
        [self _setCurrentClientRecord:[sortedClientRecords objectAtIndex:([sortedClientRecords count] - 1)]];
    else
        [self _setCurrentClientRecord:[sortedClientRecords objectAtIndex:newIndex]];
    
    [sortedClientRecords release];
}

- (IBAction)setCurrentClientFromToolbarItem:(id)sender;
{
    [self _setCurrentClientRecord:[self clientRecordWithIdentifier:[sender itemIdentifier]]];
}

- (IBAction)showHelpForClient:(id)sender;
{
    NSString *helpURL = [nonretained_currentClientRecord helpURL];
    
    if (helpURL)
        [NSApp showHelpURL:helpURL];
}


// NSWindow delegate

- (void)windowWillClose:(NSNotification *)notification;
{
    [[notification object] makeFirstResponder:nil];
    [nonretained_currentClient resignCurrentPreferenceClient];
}

- (void)windowDidResignKey:(NSNotification *)notification;
{
    [[notification object] makeFirstResponder:nil];
}


// NSToolbar delegate (We use an NSToolbar in OAPreferencesViewCustomizable)

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag;
{
    NSToolbarItem *newItem;

    newItem = [[[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier] autorelease];
    [newItem setTarget:self];
    if ([itemIdentifier isEqualToString:@"OAPreferencesShowAll"]) {
        [newItem setAction:@selector(_showAllIcons:)];
        [newItem setLabel:NSLocalizedStringFromTableInBundle(@"Show All", @"OmniAppKit", [OAPreferenceController bundle], "preferences panel button")];
        [newItem setImage:[NSImage imageNamed:@"NSApplicationIcon"]];
    } else if ([itemIdentifier isEqualToString:@"OAPreferencesNext"]) {
        [newItem setAction:@selector(showNextClient:)];
        [newItem setLabel:NSLocalizedStringFromTableInBundle(@"Next", @"OmniAppKit", [OAPreferenceController bundle], "preferences panel button")];
        [newItem setImage:[NSImage imageNamed:@"OAPreferencesNextButton" inBundleForClass:[OAPreferenceController class]]];
        [newItem setEnabled:NO]; // the first time these get added, we'll be coming up in "show all" mode, so they'll immediately diable anyway...
    } else if ([itemIdentifier isEqualToString:@"OAPreferencesPrevious"]) {
        [newItem setAction:@selector(showPreviousClient:)];
        [newItem setLabel:NSLocalizedStringFromTableInBundle(@"Previous", @"OmniAppKit", [OAPreferenceController bundle], "preferences panel button")];
        [newItem setImage:[NSImage imageNamed:@"OAPreferencesPreviousButton" inBundleForClass:[OAPreferenceController class]]];
        [newItem setEnabled:NO]; // ... so we disable them now to prevent visible flickering.
    } else { // it's for a preference client
        if ([self clientRecordWithIdentifier:itemIdentifier] == nil)
            return nil;
        
        [newItem setAction:@selector(setCurrentClientFromToolbarItem:)];
        [newItem setLabel:[[self clientRecordWithIdentifier:itemIdentifier] shortTitle]];
        [newItem setImage:[[self clientRecordWithIdentifier:itemIdentifier] iconImage]];
    }
    return newItem;
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar;
{
    return defaultToolbarItems;
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar;
{
    return allowedToolbarItems;
}

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar;
{
    return allowedToolbarItems;
}

// NSToolbar validation
- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem;
{
    NSString *itemIdentifier;
    
    itemIdentifier = [theItem itemIdentifier];
    if ([itemIdentifier isEqualToString:@"OAPreferencesPrevious"] || [itemIdentifier isEqualToString:@"OAPreferencesNext"])
        return (nonretained_currentClientRecord != nil);
    
    return YES;
}

// NSMenuItemValidation informal protocol

- (BOOL)validateMenuItem:(NSMenuItem *)item;
{
    SEL action;
    
    action = [item action];
    if (action == @selector(runToolbarCustomizationPalette:))
        return NO;
        
    return YES;
}

@end


@implementation OAPreferenceController (Private)

- (void)_loadInterface;
{
    if (window != nil)
        return;    

    [[OAPreferenceController bundle] loadNibNamed:@"OAPreferences.nib" owner:self];

    [globalControlsView retain];

    [window center];
    [window setFrameAutosaveName:windowFrameSaveName];
    [window setFrameUsingName:windowFrameSaveName force:YES];
    
    if (![[allClientRecords objectAtIndex:0] helpURL]) {
        [helpButton removeFromSuperview];
        helpButton = nil;
    }
    
    if ([allClientRecords count] == 1) {
        viewStyle = OAPreferencesViewSingle;
        [toolbar setVisible:NO];
    } else if ([allClientRecords count] > 10 || [[self _categoryNames] count] > 1) {
        viewStyle = OAPreferencesViewCustomizable;
    } else {
        viewStyle = OAPreferencesViewMultiple;
    }

    switch (viewStyle) {
        case OAPreferencesViewSingle:
            [self _setCurrentClientRecord:[allClientRecords lastObject]];
            break;
        case OAPreferencesViewMultiple:
            [allClientRecords sortUsingSelector:@selector(compareOrdering:)];
            [self _setupMultipleToolbar];
            [self _setCurrentClientRecord:[allClientRecords objectAtIndex:0]];
            break;
        case OAPreferencesViewCustomizable:
            [self _createShowAllItemsView];
            [self _setupCustomizableToolbar];
            [self _showAllIcons:nil];
            break;
    }
}

- (void)_createShowAllItemsView;
{
    const unsigned int verticalSpaceBelowTextField = 4, verticalSpaceAboveTextField = 7, sideMargin = 12;
    unsigned int boxHeight = 12;
    NSArray *categoryNames;
    unsigned int categoryIndex;

    showAllIconsView = [[NSView alloc] initWithFrame:NSZeroRect];

    // This is lame.  We should really think up some way to specify the ordering of preferences in the plists.  But this is difficult since preferences can come from many places.
    categoryNames = [self _categoryNames];
    categoryIndex = [categoryNames count];
    while (categoryIndex--) {
        NSString *categoryName;
        NSArray *categoryClientRecords;
        OAPreferencesIconView *preferencesIconView;
        NSTextField *categoryHeaderTextField;

        categoryName = [categoryNames objectAtIndex:categoryIndex];
        categoryClientRecords = [categoryNamesToClientRecordsArrays objectForKey:categoryName];

        // category preferences view
        preferencesIconView = [[OAPreferencesIconView alloc] initWithFrame:[preferenceBox bounds]];
        [preferencesIconView setPreferenceController:self];
        [preferencesIconView setPreferenceClientRecords:categoryClientRecords];

        [showAllIconsView addSubview:preferencesIconView];
        [preferencesIconView setFrameOrigin:NSMakePoint(0, boxHeight)];
        [preferencesIconViews addObject:preferencesIconView];

        boxHeight += NSHeight([preferencesIconView frame]);
        [preferencesIconView release];

        // category header
        categoryHeaderTextField = [[NSTextField alloc] initWithFrame:NSZeroRect];
        [categoryHeaderTextField setDrawsBackground:NO];
        [categoryHeaderTextField setBordered:NO];
        [categoryHeaderTextField setEditable:NO];
        [categoryHeaderTextField setSelectable:NO];
        [categoryHeaderTextField setTextColor:[NSColor controlTextColor]];
        [categoryHeaderTextField setFont:[NSFont boldSystemFontOfSize:[NSFont systemFontSize]]];
        [categoryHeaderTextField setAlignment:NSLeftTextAlignment];
        [categoryHeaderTextField setStringValue:[self _localizedCategoryNameForCategoryName:categoryName]];
        [categoryHeaderTextField sizeToFit];
        [showAllIconsView addSubview:categoryHeaderTextField];
        [categoryHeaderTextField setFrame:NSMakeRect(sideMargin, boxHeight + verticalSpaceBelowTextField, NSWidth([preferenceBox bounds]) - sideMargin, NSHeight([categoryHeaderTextField frame]))];

        boxHeight += NSHeight([categoryHeaderTextField frame]) + verticalSpaceAboveTextField;
        [categoryHeaderTextField release];

        if (categoryIndex != 0) {
            NSBox *separator;
            const unsigned int separatorMargin = 15;

            separator = [[NSBox alloc] initWithFrame:NSMakeRect(separatorMargin, boxHeight + verticalSpaceBelowTextField, NSWidth([preferenceBox bounds]) - separatorMargin - separatorMargin, 1)];
            [separator setBoxType:NSBoxSeparator];
            [showAllIconsView addSubview:separator];
            boxHeight += verticalSpaceAboveTextField + verticalSpaceBelowTextField;
        }
        boxHeight += verticalSpaceBelowTextField + 1;
    }

    [showAllIconsView setFrameSize:NSMakeSize(NSWidth([preferenceBox bounds]), boxHeight)];
}

- (void)_setupMultipleToolbar;
{
    NSMutableArray *allClients;
    NSEnumerator *enumerator;
    id aClientRecord;

    allClients = [[NSMutableArray alloc] initWithCapacity:[allClientRecords count]];
    enumerator = [allClientRecords objectEnumerator];
    while ((aClientRecord = [enumerator nextObject])) {
        [allClients addObject:[(OAPreferenceClientRecord *)aClientRecord identifier]];
    }

    allowedToolbarItems = [[NSArray arrayWithArray:allClients] retain];
    defaultToolbarItems = [[NSArray arrayWithArray:allClients] retain];
    [allClients release];
    
    toolbar = [[OAPreferencesToolbar alloc] initWithIdentifier:@"OAPreferences"];
    [toolbar setAllowsUserCustomization:NO];
    [toolbar setAutosavesConfiguration:YES];
    [toolbar setDelegate:self];
    [toolbar setShowsContextMenu:NO];
    [window setToolbar:toolbar];
}

- (void)_setupCustomizableToolbar;
{
    NSArray *constantToolbarItems, *defaultClients;
    NSMutableArray *allClients;
    NSEnumerator *enumerator;
    id aClientRecord;

    constantToolbarItems = [NSArray arrayWithObjects:
        @"OAPreferencesShowAll", @"OAPreferencesPrevious", @"OAPreferencesNext", NSToolbarSeparatorItemIdentifier,
        nil];

    defaultClients = [[NSUserDefaults standardUserDefaults] arrayForKey:@"Favorite Preferences"];

    allClients = [[NSMutableArray alloc] initWithCapacity:[allClientRecords count]];
    enumerator = [allClientRecords objectEnumerator];
    while ((aClientRecord = [enumerator nextObject])) {
        [allClients addObject:[(OAPreferenceClientRecord *)aClientRecord identifier]];
    }

    defaultToolbarItems = [[constantToolbarItems arrayByAddingObjectsFromArray:defaultClients] retain];
    allowedToolbarItems = [[constantToolbarItems arrayByAddingObjectsFromArray:allClients] retain];

    toolbar = [[OAPreferencesToolbar alloc] initWithIdentifier:@"OAPreferences"];
    [toolbar setAllowsUserCustomization:YES];
    [toolbar setAutosavesConfiguration:YES];
    [toolbar setDelegate:self];
    [toolbar setAlwaysCustomizableByDrag:YES];
    [toolbar setShowsContextMenu:NO];
    [window setToolbar:toolbar];
    [toolbar setIndexOfFirstMovableItem:4]; // first four items are always ShowAll, Previous, Next, and Separator
}

- (void)_resetWindowTitle;
{
    NSString *name = nil;
    
    if (viewStyle != OAPreferencesViewSingle) {
        name = [nonretained_currentClientRecord title];
        if ([toolbar respondsToSelector:@selector(setSelectedItemIdentifier:)]) {
            if (nonretained_currentClientRecord != nil)
                [toolbar setSelectedItemIdentifier:[nonretained_currentClientRecord identifier]];
            else
                [toolbar setSelectedItemIdentifier:@"OAPreferencesShowAll"];
        }
    }
    if (name == nil || [name isEqualToString:@""])
        name = [[NSProcessInfo processInfo] processName];
    [window setTitle:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%@ Preferences", @"OmniAppKit", [OAPreferenceController bundle], "preferences panel title format"), name]];
}

// Setting the current preference client

- (void)_setCurrentClientRecord:(OAPreferenceClientRecord *)clientRecord
{
    NSView *contentView, *controlBox;
    unsigned int newWindowHeight;
    NSRect controlBoxFrame, windowFrame, newWindowFrame;
    NSView *oldView;
    NSTimeInterval animationResizeTime;
    
    if (nonretained_currentClientRecord == clientRecord)
        return;
        
    // Save changes in any editing text fields
    [window setInitialFirstResponder:nil];
    [window makeFirstResponder:nil];
        
    // Only do this when we are on screen to avoid sending become/resign twice.  If we are off screen, the client got resigned when it went off and the new one will get a become when it goes on screen.
    if ([window isVisible])
        [nonretained_currentClient resignCurrentPreferenceClient];
        
    nonretained_currentClientRecord = clientRecord;
    nonretained_currentClient = [clientRecord clientInstanceInController:self];
    
    [self _resetWindowTitle];
    
    // Remove old client box
    contentView = [preferenceBox contentView];
    oldView = [[contentView subviews] lastObject];
    [oldView removeFromSuperview];

    controlBox = [nonretained_currentClient controlBox];
    // It's an error for controlBox to be nil, but it's pretty unfriendly to resize our window to be infinitely high when that happens.
    controlBoxFrame = controlBox != nil ? [controlBox frame] : NSZeroRect;
    
    // Resize the window
    // We don't just tell the window to resize, because that tends to move the upper left corner (which will confuse the user)
    windowFrame = [NSWindow contentRectForFrameRect:[window frame] styleMask:[window styleMask]];
    newWindowHeight = NSHeight(controlBoxFrame) + NSHeight([globalControlsView frame]);    
    if ([toolbar isVisible])
        newWindowHeight += NSHeight([[toolbar _toolbarView] frame]); 

    newWindowFrame = [NSWindow frameRectForContentRect:NSMakeRect(NSMinX(windowFrame), NSMaxY(windowFrame) - newWindowHeight, NSWidth(windowFrame), newWindowHeight) styleMask:[window styleMask]];
    animationResizeTime = [window animationResizeTime:newWindowFrame];
    [window setFrame:newWindowFrame display:YES animate:[window isVisible]];
                               
    // As above, don't do this unless we are onscreen to avoid double become/resigns.
    // Do this before putting the view in the view hierarchy to avoid flashiness in the controls.
    if ([window isVisible]) {
        [nonretained_currentClient becomeCurrentPreferenceClient];
        [self _validateRestoreDefaultsButton];
    }
    [nonretained_currentClient updateUI];

    // set up the global controls view
    if (helpButton)
        [helpButton setEnabled:([nonretained_currentClientRecord helpURL] != nil)];        
    [contentView addSubview:globalControlsView];
    
    // Add the new client box to the view hierarchy
    [controlBox setFrameOrigin:NSMakePoint(floor((NSWidth([contentView frame]) - NSWidth(controlBoxFrame)) / 2.0), NSHeight([globalControlsView frame]))];
    [contentView addSubview:controlBox];

    // Highlight the initial first responder, and also tell the window what it should be because I think there is some voodoo with nextKeyView not working unless the window has an initial first responder.
    [window setInitialFirstResponder:[nonretained_currentClient initialFirstResponder]];
    [window makeFirstResponder:[nonretained_currentClient initialFirstResponder]];
    
    // Hook up the pane's keyView loop to ours
    if (helpButton)
        [[nonretained_currentClient lastKeyView] setNextKeyView:helpButton];
    else
        [[nonretained_currentClient lastKeyView] setNextKeyView:returnToOriginalValuesButton];
    [returnToOriginalValuesButton setNextKeyView:[nonretained_currentClient initialFirstResponder]];
}

- (void)_showAllIcons:(id)sender;
{
    NSRect windowFrame, newWindowFrame;
    unsigned int newWindowHeight;
    NSTimeInterval animationResizeTime;

    // Are we already showing?
    if ([[[preferenceBox contentView] subviews] lastObject] == showAllIconsView)
        return;

    // Save changes in any editing text fields
    [window setInitialFirstResponder:nil];
    [window makeFirstResponder:nil];

    // Clear out current preference and reset window title
    nonretained_currentClientRecord = nil;
    nonretained_currentClient = nil;
    [[[preferenceBox contentView] subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self _resetWindowTitle];
        
    // Resize window
    windowFrame = [NSWindow contentRectForFrameRect:[window frame] styleMask:[window styleMask]];
    newWindowHeight = NSHeight([showAllIconsView frame]);
    if ([toolbar isVisible])
        newWindowHeight += NSHeight([[toolbar _toolbarView] frame]);
    newWindowFrame = [NSWindow frameRectForContentRect:NSMakeRect(NSMinX(windowFrame), NSMaxY(windowFrame) - newWindowHeight, NSWidth(windowFrame), newWindowHeight) styleMask:[window styleMask]];
    animationResizeTime = [window animationResizeTime:newWindowFrame];
    [window setFrame:newWindowFrame display:YES animate:[window isVisible]];

    // Add new icons view
    [preferenceBox addSubview:showAllIconsView];
}

- (void)_defaultsDidChange:(NSNotification *)notification;
{
    if ([window isVisible]) {
        // Do this later since this gets called inside a lock that we need
        [self queueSelector: @selector(_validateRestoreDefaultsButton)];
    }
}

- (void)_modifierFlagsChanged:(NSNotification *)note;
{
    BOOL optionDown = ([[note object] modifierFlags] & NSAlternateKeyMask) ? YES : NO;

    if (optionDown) {
        [returnToOriginalValuesButton setEnabled:YES];
        [returnToOriginalValuesButton setTitle:NSLocalizedStringFromTableInBundle(@"Reset All", @"OmniAppKit", [OAPreferenceController bundle], "reset-to-defaults button title")];
    } else {
        [returnToOriginalValuesButton setEnabled:[nonretained_currentClient haveAnyDefaultsChanged]];
        [returnToOriginalValuesButton setTitle:NSLocalizedStringFromTableInBundle(@"Reset", @"OmniAppKit", [OAPreferenceController bundle], "reset-to-defaults button title")];
    }
}

- (void)_validateRestoreDefaultsButton;
{
    [returnToOriginalValuesButton setEnabled:[nonretained_currentClient haveAnyDefaultsChanged]];
}

- (void)_restoreDefaultsSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
{
    if (returnCode != NSAlertDefaultReturn)
        return;

    if (contextInfo != NULL) {
        [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:[[NSBundle mainBundle] bundleIdentifier]];
        [[NSUserDefaults standardUserDefaults] synchronize];
    } else {
        NSEnumerator *clientEnumerator;
        OAPreferenceClientRecord *aClientRecord;
        
        clientEnumerator = [[self allClientRecords] objectEnumerator];
        while ((aClientRecord = [clientEnumerator nextObject])) {
            NSArray *preferenceKeys;
            NSEnumerator *keyEnumerator;
            NSString *aKey;

            preferenceKeys = [[NSArray array] arrayByAddingObjectsFromArray:[[aClientRecord defaultsDictionary] allKeys]];
            preferenceKeys = [preferenceKeys arrayByAddingObjectsFromArray:[aClientRecord defaultsArray]];
            keyEnumerator = [preferenceKeys objectEnumerator];
            while ((aKey = [keyEnumerator nextObject])) 
                [[OFPreference preferenceForKey:aKey] restoreDefaultValue];
        }
    }
    [nonretained_currentClient valuesHaveChanged];
}

// 

static int _OAPreferenceControllerCompareCategoryNames(id name1, id name2, void *context)
{
    OAPreferenceController *self = context;
    float priority1, priority2;

    priority1 = [self _priorityForCategoryName:name1];
    priority2 = [self _priorityForCategoryName:name2];
    if (priority1 == priority2)
        return [[self _localizedCategoryNameForCategoryName:name1] caseInsensitiveCompare:[self _localizedCategoryNameForCategoryName:name2]];
    else if (priority1 > priority2)
        return NSOrderedAscending;
    else // priority1 < priority2
        return NSOrderedDescending;
}

- (NSArray *)_categoryNames;
{
    return [[categoryNamesToClientRecordsArrays allKeys] sortedArrayUsingFunction:_OAPreferenceControllerCompareCategoryNames context:self];
}

- (void)_registerCategoryName:(NSString *)categoryName localizedName:(NSString *)localizedCategoryName priorityNumber:(NSNumber *)priorityNumber;
{
    if (localizedCategoryName != nil && ![localizedCategoryName isEqualToString:categoryName])
        [localizedCategoryNames setObject:localizedCategoryName forKey:categoryName];
    if (priorityNumber != nil)
        [categoryPriorities setObject:priorityNumber forKey:categoryName];
}

- (NSString *)_localizedCategoryNameForCategoryName:(NSString *)categoryName;
{
    return [localizedCategoryNames objectForKey:categoryName defaultObject:categoryName];
}

- (float)_priorityForCategoryName:(NSString *)categoryName;
{
    NSNumber *priority;

    priority = [categoryPriorities objectForKey:categoryName];
    if (priority != nil)
        return [priority floatValue];
    else
        return 0.0;
}

- (void)_registerClassName:(NSString *)className inCategoryNamed:(NSString *)categoryName description:(NSDictionary *)description;
{
    NSMutableArray *categoryClientRecords;
    OAPreferenceClientRecord *newRecord;
    NSDictionary *defaultsDictionary;
    NSString *titleEnglish, *title, *iconName, *nibName, *identifier, *shortTitleEnglish, *shortTitle;
    NSBundle *classBundle = [OFBundledClass bundleForClassNamed:className];

    categoryClientRecords = [categoryNamesToClientRecordsArrays objectForKey:categoryName];
    if (categoryClientRecords == nil) {
        categoryClientRecords = [NSMutableArray array];
        [categoryNamesToClientRecordsArrays setObject:categoryClientRecords forKey:categoryName];
    }
    
    defaultsDictionary = [description objectForKey:@"defaultsDictionary"];
    if (defaultsDictionary)
        [[NSUserDefaults standardUserDefaults] registerDefaults:defaultsDictionary];
    else
        defaultsDictionary = [NSDictionary dictionary]; // placeholder

    titleEnglish = [description objectForKey:@"title"];
    if (titleEnglish == nil)
        titleEnglish = [NSString stringWithFormat:@"Localized Title for Preference Class %@", className];
    title = [classBundle localizedStringForKey:titleEnglish value:@"" table:@"Preferences"];

    if (!(className && title))
        return;

    iconName = [description objectForKey:@"icon"];
    if (iconName == nil || [iconName isEqualToString:@""])
        iconName = className;
    nibName = [description objectForKey:@"nib"];
    if (nibName == nil || [nibName isEqualToString:@""])
        nibName = className;

    shortTitleEnglish = [description objectForKey:@"shortTitle"];
    if (shortTitleEnglish == nil) {
        shortTitleEnglish = [NSString stringWithFormat:@"Localized Short Title for Preference Class %@", className];
        shortTitle = [classBundle localizedStringForKey:shortTitleEnglish value:@"" table:@"Preferences"];
        if ([shortTitle isEqualToString:shortTitleEnglish])
            shortTitle = nil; // there's no localization for the short title specifically, so we'll let it client class default the short title to the localized version of the @"title" key's value
    } else
        shortTitle = [classBundle localizedStringForKey:shortTitleEnglish value:@"" table:@"Preferences"];
    
    identifier = [description objectForKey:@"identifier"];
    if (identifier == nil) {
        // Before we introduced a separate notion of identifiers, we simply used the short title (which defaulted to the title)
        identifier = [description objectForKey:@"shortTitle" defaultObject:titleEnglish];
    }

    newRecord = [[OAPreferenceClientRecord alloc] initWithCategoryName:categoryName];
    [newRecord setIdentifier:identifier];
    [newRecord setClassName:className];
    [newRecord setTitle:title];
    [newRecord setShortTitle:shortTitle];
    [newRecord setIconName:iconName];
    [newRecord setNibName:nibName];
    [newRecord setHelpURL:[description objectForKey:@"helpURL"]];
    [newRecord setOrdering:[description objectForKey:@"ordering"]];
    [newRecord setDefaultsDictionary:defaultsDictionary];
    [newRecord setDefaultsArray:[description objectForKey:@"defaultsArray"]];

    [categoryClientRecords addObject:newRecord];
    [categoryClientRecords sortUsingSelector:@selector(compareOrdering:)];

    [allClientRecords addObject:newRecord];
    [newRecord release];
}

@end
