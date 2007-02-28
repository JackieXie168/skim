// Copyright 2002-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OAToolbarWindowController.h"

#import <AppKit/AppKit.h>
#import <OmniFoundation/OmniFoundation.h>
#import <OmniBase/OmniBase.h>

#import "OAAquaButton.h"
#import "OAScriptToolbarHelper.h"
#import "OAToolbar.h"
#import "OAToolbarItem.h"

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniAppKit/OAToolbarWindowController.m 71356 2005-12-30 21:26:26Z bungi $")

@interface OAToolbarWindowController (Private)
+ (void)_loadToolbarNamed:(NSString *)toolbarName;
@end

@implementation OAToolbarWindowController

static NSMutableDictionary *ToolbarItemInfo = nil;
static NSMutableDictionary *allowedToolbarItems = nil;
static NSMutableDictionary *defaultToolbarItems = nil;
static NSMutableDictionary *helpersByExtension = nil;

+ (void)initialize;
{
    OBINITIALIZE;
    
    ToolbarItemInfo = [[NSMutableDictionary alloc] init];
    allowedToolbarItems = [[NSMutableDictionary alloc] init];
    defaultToolbarItems = [[NSMutableDictionary alloc] init];
    helpersByExtension = [[NSMutableDictionary alloc] init];
    
    [self registerToolbarHelper:[[OAScriptToolbarHelper alloc] init]];
}

+ (void)registerToolbarHelper:(NSObject <OAToolbarHelper> *)helperObject;
{
    [helpersByExtension setObject:helperObject forKey:[helperObject itemIdentifierExtension]];
}

+ (NSBundle *)toolbarBundle;
{
    // +bundleForClass: can get fooled, particularly by DYLD_INSERT_LIBRARIES used by OOM.  Subclass this if you want to look in a different bundle (and don't use +bundleForClass:, obviously, use +bundleWithIdentifier:).
    return [NSBundle mainBundle];
}

+ (Class)toolbarClass;
{
    return [OAToolbar class];
}

+ (Class)toolbarItemClass;
{
    return [OAToolbarItem class];
}

// Init and dealloc

- (void)dealloc;
{
    [toolbar setDelegate:nil];
    [toolbar release];
    [super dealloc];
}


// NSWindowController subclass

- (void)windowDidLoad; // Setup the toolbar and handle its delegate messages
{
    [super windowDidLoad]; // DOX: These are called immediately before and after the controller loads its nib file.  You can subclass these but should not call them directly.  Always call super from your override.
    [self createToolbar];
}

- (void)createToolbar;
{
    OBPRECONDITION(_isCreatingToolbar == NO);
    
    _isCreatingToolbar = YES;
    @try {
	if (toolbar) {
	    [toolbar setDelegate:nil];
	    [toolbar release];
	}
	
	// The subclass may change its response to all the subclass methods and then call this (see OmniOutliner's document-specific toolbar support)
	[isa _loadToolbarNamed:[self toolbarConfigurationName]];
	
	Class toolbarClass = [isa toolbarClass];
	OBASSERT(OBClassIsSubclassOfClass(toolbarClass, [OAToolbar class]));
	
	toolbar = [[toolbarClass alloc] initWithIdentifier:[self toolbarIdentifier]];
	[toolbar setAllowsUserCustomization:[self shouldAllowUserToolbarCustomization]];
	
	NSDictionary *config = nil;
	if ([self shouldAutosaveToolbarConfiguration])
	    [toolbar setAutosavesConfiguration:YES];
	else {
	    [toolbar setAutosavesConfiguration:NO];
	    config = [self toolbarConfigurationDictionary];
	}
	[toolbar setDelegate:self];
	[[self window] setToolbar:toolbar];
	
	// Have to set this after adding the toolbar to the window.  Otherwise, the toolbar will keep the size/mode, but will use the default identifiers.
	if (config)
	    [toolbar setConfigurationFromDictionary:config];
    } @finally {
	_isCreatingToolbar = NO;
    }
}

// This can be useful if you listen for toolbar item add/remove notifications and don't want to tell whether that's because we are creating a toolbar or whether the user is editing it.  We can't use -customizationPaletteIsRunning since that doesn't account for the user command-dragging items off the toolbar.
- (BOOL)isCreatingToolbar;
{
    return _isCreatingToolbar;
}

- (NSDictionary *)toolbarInfoForItem:(NSString *)identifier;
{
    NSDictionary *toolbarItemInfo = [ToolbarItemInfo objectForKey:[self toolbarConfigurationName]];
    OBASSERT(toolbarItemInfo);
    NSDictionary *itemInfo = [toolbarItemInfo objectForKey:identifier];
    OBPOSTCONDITION(itemInfo);
    return itemInfo;
}

// Implement in subclasses

- (NSString *)toolbarConfigurationName;
{
    // TODO: This should really default to something useful (like the name of the class)
    return @"Toolbar";
}

- (NSString *)toolbarIdentifier;
{
    return [self toolbarConfigurationName];
}

- (BOOL)shouldAllowUserToolbarCustomization;
{
    return YES;
}

- (BOOL)shouldAutosaveToolbarConfiguration;
{
    return YES;
}

- (NSDictionary *)toolbarConfigurationDictionary;
{
    // This is called if -shouldAutosaveConfiguration is NO (i.e., the configuration isn't in user defaults, so it has to come from somewhere)
    OBRequestConcreteImplementation(isa, _cmd);
    return nil;
}

// NSObject (NSToolbarDelegate) subclass 

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)willInsert;
{
    OAToolbarItem *newItem;
    NSDictionary *itemInfo;
    NSString *itemImageName;
    NSArray *sizes;
    NSObject <OAToolbarHelper> *helper = nil;
    NSString *extension, *value;
    NSImage *itemImage = nil;
    
    // Always use OAToolbarItem since we can't know up front whether we'll need a delegate or not.
    newItem = [[[[isa toolbarItemClass] alloc] initWithItemIdentifier:itemIdentifier] autorelease];
    
    if ((extension = [itemIdentifier pathExtension])) 
        helper = [helpersByExtension objectForKey:extension];

    if (helper) {
        NSString *nameWithoutExtension = [[itemIdentifier lastPathComponent] stringByDeletingPathExtension];

        itemInfo = [self toolbarInfoForItem:[helper templateItemIdentifier]];

        if ((value = [itemInfo objectForKey:@"label"]))
            [newItem setLabel:[NSString stringWithFormat:value, nameWithoutExtension]];
        if ((value = [itemInfo objectForKey:@"paletteLabel"]))
            [newItem setPaletteLabel:[NSString stringWithFormat:value, nameWithoutExtension]];
        if ((value = [itemInfo objectForKey:@"toolTip"]))
            [newItem setToolTip:[NSString stringWithFormat:value, nameWithoutExtension]];

        // let custom item have custom image
        {
            NSString *customImageName = itemIdentifier;
            if ([customImageName containsString:@"/"])
                customImageName = [[customImageName pathComponents] componentsJoinedByString:@":"];

            if (OACurrentControlTint() == OAGraphiteTint)
                itemImage = [NSImage imageNamed:[customImageName stringByAppendingString:@"Graphite"]];
            if (!itemImage)
                itemImage = [NSImage imageNamed:customImageName];
        }
    } else {
        itemInfo = [self toolbarInfoForItem:itemIdentifier];

        if ((value = [itemInfo objectForKey:@"label"]))
            [newItem setLabel:value];
        if ((value = [itemInfo objectForKey:@"toolTip"]))
            [newItem setToolTip:value];
        if ((value = [itemInfo objectForKey:@"optionKeyLabel"]))
            [newItem setOptionKeyLabel:value];
        if ((value = [itemInfo objectForKey:@"optionKeyToolTip"]))
            [newItem setOptionKeyToolTip:value];
        if ((value = [itemInfo objectForKey:@"paletteLabel"]))
            [newItem setPaletteLabel:value];
    }
    
    if ((value = [itemInfo objectForKey:@"customView"])) {
        // customView should map to a method or ivar on a subclass
        NSView *customView;
        NSRect frame;
        
        customView = [self valueForKey: value];
        OBASSERT(customView);
        [newItem setView: customView];
        
        // We have to provide validation for items with custom views.
        [newItem setDelegate: self];
        
        // Default to having the min size be the current size of the view and the max size unbounded.
        frame = [customView frame];
        [newItem setMinSize: frame.size];
    }
    
    [newItem setTarget:self];
    if ((value = [itemInfo objectForKey:@"target"])) {
        if ([value isEqualToString:@"firstResponder"])
            [newItem setTarget:nil];
    }
    if ((value = [itemInfo objectForKey:@"action"]))
        [newItem setAction:NSSelectorFromString(value)];
    if ((value = [itemInfo objectForKey:@"optionKeyAction"]))
        [newItem setOptionKeyAction:NSSelectorFromString(value)];

    sizes = [itemInfo objectForKey:@"minSize"];
    if (sizes)
        [newItem setMinSize:NSMakeSize([[sizes objectAtIndex:0] floatValue], [[sizes objectAtIndex:1] floatValue])];
    sizes = [itemInfo objectForKey:@"maxSize"];
    if (sizes)
        [newItem setMaxSize:NSMakeSize([[sizes objectAtIndex:0] floatValue], [[sizes objectAtIndex:1] floatValue])];
    
    if (!itemImage && ((itemImageName = [itemInfo objectForKey:@"imageName"]))) {
        if (OACurrentControlTint() == OAGraphiteTint)
            itemImage = [NSImage imageNamed:[itemImageName stringByAppendingString:@"Graphite"]];
        if (!itemImage)
            itemImage = [NSImage imageNamed:itemImageName];
        OBASSERT(itemImage);
    }
    
    if (itemImage)
        [newItem setImage:itemImage];

    if ((itemImageName = [itemInfo objectForKey:@"optionKeyImageName"]) && (itemImage = [NSImage imageNamed:itemImageName]))
        [newItem setOptionKeyImage:itemImage];
        
    if (helper)
        [helper finishSetupForItem:newItem];
        
    return newItem;
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar;
{
    NSEnumerator *enumerator;
    NSObject <OAToolbarHelper> *helper;
    NSMutableArray *results;
    
    results = [NSMutableArray arrayWithArray:[allowedToolbarItems objectForKey:[self toolbarConfigurationName]]];
    enumerator = [helpersByExtension objectEnumerator];
    while ((helper = [enumerator nextObject])) {
        int itemIndex;
        
        itemIndex = [results indexOfObject:[helper templateItemIdentifier]];
        if (itemIndex == NSNotFound)
            continue;
        [results replaceObjectsInRange:NSMakeRange(itemIndex, 1) withObjectsFromArray:[helper allowedItems]];
    }
    return results;
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar;
{
    return [defaultToolbarItems objectForKey:[self toolbarConfigurationName]];
}

// NSObject (NSToolbarItemValidation)

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem;
{
    return YES;
}

@end


@implementation OAToolbarWindowController (Private)

+ (void)_loadToolbarNamed:(NSString *)toolbarName;
{
    NSDictionary *toolbarPropertyList;

    if ([allowedToolbarItems objectForKey:toolbarName] != nil)
        return;

    NSBundle *bundle = [self toolbarBundle];
    
    NSString *toolbarPath = [bundle pathForResource:toolbarName ofType:@"toolbar"];
    if (!toolbarPath) {
	NSLog(@"Unable to locate %@.toolbar from %@", toolbarName, bundle);
	OBASSERT_NOT_REACHED("Unable to locate toolbar file");
	return;
    }
    
    toolbarPropertyList = [NSDictionary dictionaryWithContentsOfFile:toolbarPath];
    if (!toolbarPropertyList) {
	NSLog(@"Unable to load %@.toolbar from %@", toolbarName, toolbarPath);
	OBASSERT_NOT_REACHED("Unable to load toolbar file");
	return;
    }

    [ToolbarItemInfo setObject:[toolbarPropertyList objectForKey:@"itemInfoByIdentifier"] forKey:toolbarName];
    [allowedToolbarItems setObject:[toolbarPropertyList objectForKey:@"allowedItemIdentifiers"] forKey:toolbarName];
    [defaultToolbarItems setObject:[toolbarPropertyList objectForKey:@"defaultItemIdentifiers"] forKey:toolbarName];
}

@end
