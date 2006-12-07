// Copyright 2002-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import "OAInspectorRegistry.h"

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <OmniBase/OmniBase.h>
#import <OmniFoundation/OmniFoundation.h>
#import "NSBundle-OAExtensions.h"

#import "OAInspectableControllerProtocol.h"
#import "OAInspectorGroup.h"
#import "OAInspectorController.h"
#import "OAColorInspector.h"
#import "OAFontInspector.h"

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Inspector.subproj/OAInspectorRegistry.m,v 1.18 2003/04/01 01:02:12 toon Exp $");

@interface OAInspectorRegistry (Private)
- (void)_inspectMainWindow;
- (void)_inspectWindow:(NSWindow *)window;
- (void)_recalculateInspectorsAndInspectWindow;
- (void)_selectionMightHaveChangedNotification:(NSNotification *)notification;
- (void)_inspectWindowNotification:(NSNotification *)notification;
- (void)_uninspectWindowNotification:(NSNotification *)notification;
- (void)_registerForNotifications;
@end

// Defined in OAInspector while that class still exists
//NSString *OAInspectorSelectionDidChangeNotification = @"OAInspectorSelectionDidChangeNotification";

static NSMutableArray *inspectorControllers = nil;
static NSMutableArray *additionalPanels = nil;

@implementation OAInspectorRegistry

+ (void)initialize;
{
    OBINITIALIZE;
    inspectorControllers = [[NSMutableArray alloc] init];
    additionalPanels = [[NSMutableArray alloc] init];
}

+ (void)didLoad;
{
    // Allows us to bring up the Inspector panel if it was up when the app closed previously.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(controllerStartRunning:) name:NSApplicationDidFinishLaunchingNotification object:nil];
}

+ (void)controllerStartRunning:(NSNotification *)notification
{
    if ([inspectorControllers count]) {
        [self registerInspector:[[OAColorInspector alloc] init]];
        [self registerInspector:[[OAFontInspector alloc] init]];

        [[self sharedInspector] _registerForNotifications];
        [OAInspectorGroup queueSelector:@selector(restoreInspectorGroupsWithInspectors:) withObject:inspectorControllers];
    }
}

+ (OAInspectorController *)registerInspector:(NSObject <OAGroupedInspector> *)inspector;
{
    OAInspectorController *controller;
    
    controller = [[OAInspectorController alloc] initWithInspector:inspector];
    [inspectorControllers addObject:controller];
    return controller;
}

+ (void)registerAdditionalPanel:(NSWindowController *)additionalController;
{
    [additionalPanels addObject:additionalController];
}

+  (OAInspectorRegistry *)sharedInspector;
{
    static OAInspectorRegistry *sharedInspector = nil;
    
    if (sharedInspector == nil)
        sharedInspector = [[self alloc] init];
    return sharedInspector;
}

static NSMutableArray *hiddenGroups = nil;
static NSMutableArray *hiddenPanels = nil;
    
+ (void)tabShowHidePanels;
{
    NSMutableArray *visibleGroups = [NSMutableArray array];
    NSMutableArray *visiblePanels = [NSMutableArray array];
    NSArray *existingGroups = [OAInspectorGroup groups];
    int index, count = [existingGroups count];
    
    for (index = 0; index < count; index++) {
        OAInspectorGroup *group = [existingGroups objectAtIndex:index];
        
        if ([group isVisible]) {
            [visibleGroups addObject:group];
            [group hideGroup];
        }
    }
    
    count = [additionalPanels count];
    for (index = 0; index < count; index++) {
        NSWindowController *controller = [additionalPanels objectAtIndex:index];
        if ([[controller window] isVisible]) {
            [visiblePanels addObject:[controller window]];
            [[controller window] orderOut:self];
        }
    }
    
    if ([visibleGroups count] || [visiblePanels count]) {
        [hiddenGroups release];
        hiddenGroups = [visibleGroups retain];
        [hiddenPanels release];
        hiddenPanels = [visiblePanels retain];
    } else if ([hiddenGroups count] || [hiddenPanels count]) {
        [hiddenGroups makeObjectsPerformSelector:@selector(showGroup)];
        [hiddenGroups release];
        hiddenGroups = nil;
        [hiddenPanels makeObjectsPerformSelector:@selector(orderFront:) withObject:self];
        [hiddenPanels release];
        hiddenPanels = nil;
    } else {
        [existingGroups makeObjectsPerformSelector:@selector(showGroup)];
        
        count = [additionalPanels count];
        for (index = 0; index < count; index++)
            [[[additionalPanels objectAtIndex:index] window] orderFront:self];
    }
}

+ (BOOL)showAllInspectors;
{
    NSArray *existingGroups = [OAInspectorGroup groups];
    int index = [existingGroups count];
    BOOL shownAny = NO;
    
    while (index--) {
        OAInspectorGroup *group = [existingGroups objectAtIndex:index];
        
        if (![group isVisible]) {
            shownAny = YES;
            [group showGroup];
        }
    }
    [hiddenGroups removeAllObjects];
    return shownAny;
}

+ (void)toggleAllInspectors;
{
    if (![self showAllInspectors]) {
        [[OAInspectorGroup groups] makeObjectsPerformSelector:@selector(hideGroup)];
    }
}

+ (void)updateInspector;
{
    [[self sharedInspector] _inspectMainWindow];
}

// Init

- init
{
    [super init];
    objectsByClass = [[NSMutableDictionary alloc] init];
    workspaceDefaults = [[[NSUserDefaults standardUserDefaults] objectForKey:@"Inspector"] mutableCopy];
    if (!workspaceDefaults)
        workspaceDefaults = [[NSMutableDictionary alloc] init];
    workspaces = [[[NSUserDefaults standardUserDefaults] objectForKey:@"InspectorWorkspaces"] mutableCopy];
    if (!workspaces)
        workspaces = [[NSMutableArray alloc] init];
    return self;
}

- (NSArray *)inspectedObjectsOfClass:(Class)aClass;
{
    return [objectsByClass objectForKey:aClass];
}

- (NSArray *)inspectedObjects;
{
    return inspectedObjects;
}

- (NSMutableDictionary *)workspaceDefaults;
{
    return workspaceDefaults;
}

- (void)defaultsDidChange;
{
    [[NSUserDefaults standardUserDefaults] setObject:workspaceDefaults forKey:@"Inspector"];
}

- (BOOL)validateMenuItem:(NSMenuItem *)item;
{
    if ([item action] == @selector(deleteWorkspace:))
        return [workspaces count] > 0;
    else
        return YES;
}

- (void)_buildWorkspacesInMenu;
{
    int itemCount = [workspaceMenu numberOfItems];
    
    while (itemCount-- > 4)
        [workspaceMenu removeItemAtIndex:4];

    if ([workspaces count]) {
        int index, count = [workspaces count];
        
        [workspaceMenu addItem:[NSMenuItem separatorItem]];
        for (index = 0; index < count; index++) {
            NSString *title = [workspaces objectAtIndex:index];
            NSMenuItem *item;
            
            item = [workspaceMenu addItemWithTitle:title action:@selector(switchToWorkspace:) keyEquivalent:@""];
            [item setTarget:self];
            [item setRepresentedObject:title];
        }
    }
}

- (NSMenu *)workspaceMenu;
{
    if (!workspaceMenu) {
        NSMenuItem *item;
        NSBundle *bundle = [OAInspectorRegistry bundle];
        
        workspaceMenu = [[NSMenu alloc] initWithTitle:@"Workspace"];
        item = [workspaceMenu addItemWithTitle:NSLocalizedStringFromTableInBundle(@"Save Workspace...", @"OmniAppKit", bundle, @"Save Workspace menu item") action:@selector(saveWorkspace:) keyEquivalent:@""];
        [item setTarget:self];
        item = [workspaceMenu addItemWithTitle:NSLocalizedStringFromTableInBundle(@"Delete Workspace...", @"OmniAppKit", bundle, @"Delete Workspace menu item") action:@selector(deleteWorkspace:) keyEquivalent:@""];
        [item setTarget:self];
        [workspaceMenu addItem:[NSMenuItem separatorItem]];
        [workspaceMenu addItem:[self resetPanelsItem]];
        [self _buildWorkspacesInMenu];
    }
    return workspaceMenu;
}

- (NSMenuItem *)resetPanelsItem;
{
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Reset Inspector Locations", @"OmniAppKit", [OAInspectorRegistry bundle], @"Reset Inspector Locations menu item") action:@selector(switchToDefault:) keyEquivalent:@""];
    [item setTarget:self];
    return [item autorelease];
}

- (void)saveWorkspace:sender;
{
    NSWindow *window;
    
    if (!newWorkspaceTextField)
        [[OAInspectorRegistry bundle] loadNibNamed:@"OAInspectorWorkspacePanels" owner:self];
    
    [newWorkspaceTextField setStringValue:NSLocalizedStringFromTableInBundle(@"Untitled", @"OmniAppKit", [OAInspectorRegistry bundle], @"Save Workspace default title")];
    window = [newWorkspaceTextField window];
    [window center];
    [window makeKeyAndOrderFront:self];
    [NSApp runModalForWindow:window];
}

- (void)saveWorkspaceConfirmed:sender;
{
    NSString *name = [newWorkspaceTextField stringValue];

    if ([workspaces containsObject:name]) {
        NSString *withNumber;
        int index = 1;
        
        do {
            withNumber = [NSString stringWithFormat:@"%@-%d", name, index++];
        } while ([workspaces containsObject:withNumber]);
        name = withNumber;
    }

    [workspaces addObject:name];
    [workspaces sortUsingSelector:@selector(compare:)];
    [[NSUserDefaults standardUserDefaults] setObject:workspaces forKey:@"InspectorWorkspaces"];
    
    [[NSUserDefaults standardUserDefaults] setObject:workspaceDefaults forKey:[NSString stringWithFormat:@"InspectorWorkspace-%@", name]];
    
    [self _buildWorkspacesInMenu];
    [self cancelWorkspacePanel:sender];
}

- (void)deleteWorkspace:sender;
{
    NSWindow *window;
    int itemCount;
    int index, count;
    
    if (!deleteWorkspacePopup)
        [[OAInspectorRegistry bundle] loadNibNamed:@"OAInspectorWorkspacePanels" owner:self];
        
    itemCount = [deleteWorkspacePopup numberOfItems];    
    while (itemCount-- > 2)
        [deleteWorkspacePopup removeItemAtIndex:0];
    
    count = [workspaces count];
    for (index = 0; index < count; index++)
        [deleteWorkspacePopup insertItemWithTitle:[workspaces objectAtIndex:index] atIndex:index];

    window = [deleteWorkspacePopup window];
    [window center];
    [window makeKeyAndOrderFront:self];
    [NSApp runModalForWindow:window];
}

- (void)deleteWorkspaceConfirmed:sender;
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    int index = [deleteWorkspacePopup indexOfSelectedItem];
    
    if (index >= [workspaces count]) { // selected all...
        index = [workspaces count];
        while (index--)
            [defaults removeObjectForKey:[NSString stringWithFormat:@"InspectorWorkspace-%@", [workspaces objectAtIndex:index]]];
        [workspaces removeAllObjects];
    } else {
        [defaults removeObjectForKey:[NSString stringWithFormat:@"InspectorWorkspace-%@", [workspaces objectAtIndex:index]]];
        [workspaces removeObjectAtIndex:index];
    }

    [defaults setObject:workspaces forKey:@"InspectorWorkspaces"];
    [self _buildWorkspacesInMenu];
    [self cancelWorkspacePanel:sender];
}

- (void)cancelWorkspacePanel:sender;
{
    [[sender window] orderOut:self];
    [NSApp stopModal];
}

- (void)switchToWorkspace:sender;
{
    [hiddenGroups removeAllObjects];
    [OAInspectorGroup clearAllGroups];
    [workspaceDefaults release];
    workspaceDefaults = [[[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"InspectorWorkspace-%@", [sender representedObject]]] mutableCopy];
    [self defaultsDidChange];
    [OAInspectorGroup queueSelector:@selector(restoreInspectorGroupsWithInspectors:) withObject:inspectorControllers];
}

- (void)switchToDefault:sender;
{
    [hiddenGroups removeAllObjects];
    [OAInspectorGroup clearAllGroups];
    [workspaceDefaults removeAllObjects];
    [self defaultsDidChange];
    [OAInspectorGroup queueSelector:@selector(restoreInspectorGroupsWithInspectors:) withObject:inspectorControllers];
}

@end


//
// Private API.
//

@implementation OAInspectorRegistry (Private)

// DON'T Make ourselves key here
- (void)_updateInspector;
{
    [self _inspectMainWindow];
}

- (void)_inspectMainWindow;
{
    [self _inspectWindow:[NSApp mainWindow]];
}

- (void)_inspectWindow:(NSWindow *)window;
{
    if (!isInspectionQueued) {
        [self queueSelector:@selector(_recalculateInspectorsAndInspectWindow)];
        isInspectionQueued = YES;
    }
    lastWindowAskedToInspect = window;
}

- (void)_getInspectedObjects;
{
    static BOOL isFloating = YES;
    BOOL shouldFloat;
    NSWindow *window;
    NSResponder *nextResponder;
    id <OAInspectableController> inspectableController;

    window = lastWindowAskedToInspect;
    
    // Don't float over non-document windows
    shouldFloat = window == nil || ([[window delegate] isKindOfClass:[NSWindowController class]] && [[window delegate] document] != nil);
    if (isFloating != shouldFloat) {
        NSArray *array = [OAInspectorGroup groups];
        int index = [array count];
        while (index--)
            [[array objectAtIndex:index] setFloating:shouldFloat];
        isFloating = shouldFloat;
        
        if (!shouldFloat)
            [window orderFront:self];
    }
        
    // Get the controller and inspected objects...
    nextResponder = [window firstResponder];
    if (nextResponder == nil)
        nextResponder = window;
    inspectableController = nil;
    do {
        if ([nextResponder conformsToProtocol:@protocol(OAInspectableController)])
            inspectableController = (id)nextResponder;
        else if ([nextResponder respondsToSelector:@selector(delegate)] && [[(id)nextResponder delegate] conformsToProtocol:@protocol(OAInspectableController)])
            inspectableController = [(id)nextResponder delegate];
        else
            nextResponder = [nextResponder nextResponder];
    } while (nextResponder != nil && inspectableController == nil);

    [inspectedObjects release];

    if (inspectableController) {
        if ([inspectableController respondsToSelector:@selector(inspectedObjects)]) {
            inspectedObjects = [[(id <OAComplexInspectableController>)inspectableController inspectedObjects] retain];
        } else {
            id object = [inspectableController inspectedObject];
            
            if (object)
                inspectedObjects = [[NSArray arrayWithObject:object] retain];
            else
                inspectedObjects = nil;
        }
    } else {
        inspectedObjects = nil;
    }
}

- (void)_recalculateInspectorsAndInspectWindow;
{
    unsigned int index, count;
    NSMutableArray *list;
    
    isInspectionQueued = NO;
    [self _getInspectedObjects];
    
    // Sort inspected objects by their class
    [objectsByClass removeAllObjects];
    count = [inspectedObjects count];
    for (index = 0; index < count; index++) {
        id object;

        object = [inspectedObjects objectAtIndex:index];
        list = [objectsByClass objectForKey:[object class]];
        if (!list) {
            list = [[NSMutableArray alloc] init];
            [objectsByClass setObject:list forKey:[object class]];
            [list release];
        }
        [list addObject:object];
    }
    
    [inspectorControllers makeObjectsPerformSelector:@selector(updateInspector)];
}

- (void)_selectionMightHaveChangedNotification:(NSNotification *)notification;
{
    [self _inspectMainWindow];
}

- (void)_inspectWindowNotification:(NSNotification *)notification;
{
    [self _inspectWindow:(NSWindow *)[notification object]];
}

- (void)_uninspectWindowNotification:(NSNotification *)notification;
{
    [self _inspectWindow:nil];
}

- (void)_registerForNotifications;
{
    // While the Inspector is visible, watch for any window to become main.  When that happens, determine if that window's delegate responds to the OAInspectableControllerProtocol, and act accordingly.
    NSNotificationCenter *defaultNotificationCenter = [NSNotificationCenter defaultCenter];
    [defaultNotificationCenter addObserver:self selector:@selector(_inspectWindowNotification:) name:NSWindowDidBecomeMainNotification object:nil];
    [defaultNotificationCenter addObserver:self selector:@selector(_uninspectWindowNotification:) name:NSWindowDidResignMainNotification object:nil];
    [defaultNotificationCenter addObserver:self selector:@selector(_selectionMightHaveChangedNotification:) name:OAInspectorSelectionDidChangeNotification object:nil];
}

@end
