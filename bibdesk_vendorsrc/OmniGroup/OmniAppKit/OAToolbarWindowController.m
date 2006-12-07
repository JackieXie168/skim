// Copyright 2002-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import "OAToolbarWindowController.h"

#import <AppKit/AppKit.h>
#import <OmniFoundation/OmniFoundation.h>
#import <OmniBase/OmniBase.h>

#import "OAAquaButton.h"
#import "OAScriptToolbarHelper.h"
#import "OAToolbarItem.h"

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OAToolbarWindowController.m,v 1.14 2003/04/10 09:39:39 wjs Exp $")

@interface OAToolbarWindowController (Private)
+ (void)_loadToolbarNamed:(NSString *)toolbarName;
@end

@implementation OAToolbarWindowController

static NSMutableDictionary *toolbarItemInfo = nil;
static NSMutableDictionary *allowedToolbarItems = nil;
static NSMutableDictionary *defaultToolbarItems = nil;
static NSMutableDictionary *helpersByExtension = nil;

+ (void)initialize;
{
    OBINITIALIZE;
    
    toolbarItemInfo = [[NSMutableDictionary alloc] init];
    allowedToolbarItems = [[NSMutableDictionary alloc] init];
    defaultToolbarItems = [[NSMutableDictionary alloc] init];
    helpersByExtension = [[NSMutableDictionary alloc] init];
    
    [self registerToolbarHelper:[[OAScriptToolbarHelper alloc] init]];
}

+ (void)registerToolbarHelper:(NSObject <OAToolbarHelper> *)helperObject;
{
    [helpersByExtension setObject:helperObject forKey:[helperObject itemIdentifierExtension]];
}

// Init and dealloc

- (void)dealloc;
{
    [toolbar release];
    [super dealloc];
}


// NSWindowController subclass

- (void)windowDidLoad; // Setup the toolbar and handle its delegate messages
{
    [super windowDidLoad]; // DOX: These are called immediately before and after the controller loads its nib file.  You can subclass these but should not call them directly.  Always call super from your override.

    [isa _loadToolbarNamed:[self toolbarConfigurationName]];
    toolbar = [[NSToolbar alloc] initWithIdentifier:[self toolbarIdentifier]];
    [toolbar setAllowsUserCustomization:YES];
    [toolbar setAutosavesConfiguration:YES];
    [toolbar setDelegate:self];
    [[self window] setToolbar:toolbar];
}


/* UNUSED? WJS DEC 2002
- (NSDictionary *)itemInfoForIdentifier:(NSString *)itemIdentifier;
{
    NSString *name;
    NSDictionary *info;
    
    name = [self toolbarConfigurationName];
    [isa _loadToolbarNamed:name];
    info = [[toolbarItemInfo objectForKey:name] objectForKey:itemIdentifier];
    OBPOSTCONDITION(info);
    return info;
}
*/


// Implement in subclasses

- (NSString *)toolbarConfigurationName;
{
#warning TJW: This should really default to something useful (like the name of the class)
    return @"Toolbar";
}

- (NSString *)toolbarIdentifier;
{
    return [self toolbarConfigurationName];
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
    newItem = [[[OAToolbarItem alloc] initWithItemIdentifier:itemIdentifier] autorelease];
    
    if ((extension = [itemIdentifier pathExtension])) 
        helper = [helpersByExtension objectForKey:extension];

    if (helper) {
        NSString *nameWithoutExtension = [[itemIdentifier lastPathComponent] stringByDeletingPathExtension];

        itemInfo = [[toolbarItemInfo objectForKey:[self toolbarConfigurationName]] objectForKey:[helper templateItemIdentifier]];

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
        itemInfo = [[toolbarItemInfo objectForKey:[self toolbarConfigurationName]] objectForKey:itemIdentifier];

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


// NSObject (NSToolbarNotifications)

- (void)toolbarWillAddItem:(NSNotification *)notification;
{
}

- (void)toolbarDidRemoveItem:(NSNotification *)notification;
{
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

    toolbarPropertyList = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle bundleForClass:self] pathForResource:toolbarName ofType:@"toolbar"]];
    OBASSERT(toolbarPropertyList);

    [toolbarItemInfo setObject:[toolbarPropertyList objectForKey:@"itemInfoByIdentifier"] forKey:toolbarName];
    [allowedToolbarItems setObject:[toolbarPropertyList objectForKey:@"allowedItemIdentifiers"] forKey:toolbarName];
    [defaultToolbarItems setObject:[toolbarPropertyList objectForKey:@"defaultItemIdentifiers"] forKey:toolbarName];
}

@end
