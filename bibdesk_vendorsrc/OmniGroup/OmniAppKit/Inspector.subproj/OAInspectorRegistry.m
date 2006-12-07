// Copyright 2002-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

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

#import "OAInspectionSet.h"

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Inspector.subproj/OAInspectorRegistry.m,v 1.32 2004/02/10 04:07:33 kc Exp $");

@interface OAInspectorRegistry (Private)
- (void)_inspectMainWindow;
- (void)_inspectWindow:(NSWindow *)window;
- (void)_mergeInspectedObjectsFromPotentialController:(id)object seenControllers:(NSMutableSet *)seenControllers;
- (void)_mergeInspectedObjectsFromResponder:(NSResponder *)responder seenControllers:(NSMutableSet *)seenControllers;
- (void)_getInspectedObjects;
- (void)_recalculateInspectorsAndInspectWindow;
- (void)_selectionMightHaveChangedNotification:(NSNotification *)notification;
- (void)_inspectWindowNotification:(NSNotification *)notification;
- (void)_uninspectWindowNotification:(NSNotification *)notification;
- (void)_registerForNotifications;
@end

NSString *OAInspectorSelectionDidChangeNotification = @"OAInspectorSelectionDidChangeNotification";

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

    if (sharedInspector == nil) {
        // Allow the main bundle to request a subclass
        NSString *className = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"OAInspectorRegistryClass"];
        Class cls = Nil;
        if (className) {
            if (!(cls = NSClassFromString(className)))
                NSLog(@"Unable to find %@ subclass '%@'", NSStringFromClass(self), className);
            if (!OBClassIsSubclassOfClass(cls, self)) {
                NSLog(@"'%@' is not a subclass of '%@'", className, NSStringFromClass(self));
                cls = Nil;
            }
        }
        if (!cls)
            cls = self;

        sharedInspector = [[cls alloc] init];
    }
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

/*" Shows all the registered inspectors.  Returns YES if any additional inspectors become visible. "*/
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

/*" Hides all the registered inspectors.  Returns YES if any additional inspectors become hidden. "*/
+ (BOOL)hideAllInspectors;
{
    NSArray *existingGroups = [OAInspectorGroup groups];
    int index = [existingGroups count];
    BOOL hiddenAny = NO;

    while (index--) {
        OAInspectorGroup *group = [existingGroups objectAtIndex:index];

        if ([group isVisible]) {
            hiddenAny = YES;
            [group hideGroup];
            [hiddenGroups addObject:group];
        }
    }

    return hiddenAny;
}

+ (void)toggleAllInspectors;
{
    if (![self showAllInspectors])
        [self hideAllInspectors];
}

+ (void)updateInspector;
{
    [[self sharedInspector] _inspectMainWindow];
}

+ (BOOL)hasVisibleInspector;
/*" Returns YES if any of the registered inspectors are on screen and expanded. "*/
{
    unsigned int controllerIndex = [inspectorControllers count];
    while (controllerIndex--) {
        OAInspectorController *controller = [inspectorControllers objectAtIndex:controllerIndex];
        if ([[controller window] isVisible] && [controller isExpanded])
            return YES;
    }
    return NO;
}

// Init

- init
{
    [super init];
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
    return [inspectionSet objectsOfClass:aClass];
}

- (NSArray *)inspectedObjects;
{
    return [inspectionSet allObjects];
}

- (OAInspectionSet *)inspectionSet;
    /*" This method allows fine tuning of the inspection.  If the inspection set is changed, -inspectionSetChanged must be called to update the inspectors "*/
{
    return inspectionSet;
}

- (void)inspectionSetChanged;
{
    [inspectorControllers makeObjectsPerformSelector:@selector(updateInspector)];
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
    if ([item action] == @selector(editWorkspace:))
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
        unichar functionChar = NSF2FunctionKey, lastFunctionChar = NSF8FunctionKey;
        
        [workspaceMenu addItem:[NSMenuItem separatorItem]];
        for (index = 0; index < count; index++) {
            NSString *title = [workspaces objectAtIndex:index];
            id <NSMenuItem> item;
            NSString *key = @"";
            
            if (functionChar <= lastFunctionChar) {
                key = [NSString stringWithCharacters:&functionChar length:1];
                functionChar++;
            }
            
            item = [workspaceMenu addItemWithTitle:title action:@selector(switchToWorkspace:) keyEquivalent:key];
            [item setKeyEquivalentModifierMask:0];
            [item setTarget:self];
            [item setRepresentedObject:title];
        }
    }
}

- (NSMenu *)workspaceMenu;
{
    if (!workspaceMenu) {
        id <NSMenuItem> item;
        NSBundle *bundle = [OAInspectorRegistry bundle];
        
        workspaceMenu = [[NSMenu alloc] initWithTitle:@"Workspace"];
        item = [workspaceMenu addItemWithTitle:NSLocalizedStringFromTableInBundle(@"Save Workspace...", @"OmniAppKit", bundle, @"Save Workspace menu item") action:@selector(saveWorkspace:) keyEquivalent:@""];
        [item setTarget:self];
        item = [workspaceMenu addItemWithTitle:NSLocalizedStringFromTableInBundle(@"Edit Workspaces...", @"OmniAppKit", bundle, @"Edit Workspaces menu item") action:@selector(editWorkspace:) keyEquivalent:@""];
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
    [[NSUserDefaults standardUserDefaults] setObject:workspaces forKey:@"InspectorWorkspaces"];
    [[NSUserDefaults standardUserDefaults] setObject:[workspaceDefaults copy] forKey:[NSString stringWithFormat:@"InspectorWorkspace-%@", name]];
    [self _buildWorkspacesInMenu];
    [self cancelWorkspacePanel:sender];
}

- (void)editWorkspace:sender;
{
    NSWindow *window;
    
    if (!editWorkspaceTable)
        [[OAInspectorRegistry bundle] loadNibNamed:@"OAInspectorWorkspacePanels" owner:self];
    
    [editWorkspaceTable reloadData];
    [deleteWorkspaceButton setEnabled:([editWorkspaceTable numberOfSelectedRows] > 0)];

    window = [editWorkspaceTable window];
    [window center];
    [window makeKeyAndOrderFront:self];
    [NSApp runModalForWindow:window];
}

static NSString *OAWorkspaceOrderPboardType = @"OAWorkspaceOrder";

- (void)awakeFromNib;
{
    [editWorkspaceTable registerForDraggedTypes:[NSArray arrayWithObject:OAWorkspaceOrderPboardType]];
}

- (void)deleteWorkspace:sender;
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *sortedSelection = [[[editWorkspaceTable selectedRowEnumerator] allObjects] sortedArrayUsingSelector:@selector(compare:)];
    NSEnumerator *enumerator = [sortedSelection reverseObjectEnumerator];
    NSNumber *row;
    int index;
    
    while ((row = [enumerator nextObject])) {
        index = [row intValue];
        [defaults removeObjectForKey:[NSString stringWithFormat:@"InspectorWorkspace-%@", [workspaces objectAtIndex:index]]];
        [workspaces removeObjectAtIndex:index];
    }
    [defaults setObject:workspaces forKey:@"InspectorWorkspaces"];
    [editWorkspaceTable reloadData];
    [self _buildWorkspacesInMenu];
}

- (void)cancelWorkspacePanel:sender;
{
    [[sender window] orderOut:self];
    [NSApp stopModal];
}

- (void)switchToWorkspace:sender;
{
    NSDictionary *newSettings = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"InspectorWorkspace-%@", [sender representedObject]]];
    
    if (newSettings == nil)
        return;
    
    [hiddenGroups removeAllObjects];
    [OAInspectorGroup clearAllGroups];
    [workspaceDefaults release];
    workspaceDefaults = [newSettings mutableCopy];
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

//
// NSTableView data source methods
//


- (int)numberOfRowsInTableView:(NSTableView *)aTableView;
{
    return [workspaces count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
{
    if ([[aTableColumn identifier] isEqualToString:@"Name"]) {
        return [workspaces objectAtIndex:rowIndex];
    } else {
        int fKey = rowIndex + 2;
        
        if (fKey <= 8)
            return [NSString stringWithFormat:@"F%d", fKey];
        else
            return @"";
    }
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *oldName = [workspaces objectAtIndex:rowIndex];
    NSString *oldDefault = [NSString stringWithFormat:@"InspectorWorkspace-%@", oldName];
    
    [defaults setObject:[defaults objectForKey:oldDefault] forKey:[NSString stringWithFormat:@"InspectorWorkspace-%@", anObject]];
    [defaults removeObjectForKey:oldDefault];
    [workspaces replaceObjectAtIndex:rowIndex withObject:anObject];
    [self _buildWorkspacesInMenu];
}

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)operation;
{
    NSArray *names = [[info draggingPasteboard] propertyListForType:OAWorkspaceOrderPboardType];
    int workspaceIndex, nameIndex = [names count];

    while (nameIndex--) {
        workspaceIndex = [workspaces indexOfObject:[names objectAtIndex:nameIndex]];
        if (workspaceIndex < row)
            row--;
        [workspaces removeObjectAtIndex:workspaceIndex];
    }
    [workspaces insertObjectsFromArray:names atIndex:row];
    [tableView reloadData];
    [self _buildWorkspacesInMenu];
    return YES;
}

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)operation;
{
    if (row == -1)
        row = [tableView numberOfRows];
    [tableView setDropRow:row dropOperation:NSTableViewDropAbove];
    return NSDragOperationMove;
}

- (BOOL)tableView:(NSTableView *)tableView writeRows:(NSArray *)rows toPasteboard:(NSPasteboard *)pboard;
{
    NSMutableArray *names = [NSMutableArray array];
    NSEnumerator *enumerator = [rows objectEnumerator];
    NSNumber *row;
    
    if ([workspaces count] <= 1)
        return NO;
        
    while ((row = [enumerator nextObject]))
        [names addObject:[workspaces objectAtIndex:[row intValue]]];

    [pboard declareTypes:[NSArray arrayWithObject:OAWorkspaceOrderPboardType] owner:nil];
    [pboard setPropertyList:names forType:OAWorkspaceOrderPboardType];
    return YES;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification;
{
    [deleteWorkspaceButton setEnabled:([editWorkspaceTable numberOfSelectedRows] > 0)];
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

- (void)_mergeInspectedObjectsFromPotentialController:(id)object seenControllers:(NSMutableSet *)seenControllers;
{
    if ([object conformsToProtocol:@protocol(OAInspectableController)]) {
        // A controller may be accessible along two paths in the responder chain by being the delegate for multiple NSResponders.  Only give each object one chance to add its stuff, otherwise controllers that want to override a particular class via -[OAInspectionSet removeObjectsWithClass:] may itself be overriden by the duplicate delegate!
        if ([seenControllers member:object] == nil) {
            [seenControllers addObject:object];
            [(id <OAInspectableController>)object addInspectedObjects:inspectionSet];
        }
    }
}

- (void)_mergeInspectedObjectsFromResponder:(NSResponder *)responder seenControllers:(NSMutableSet *)seenControllers;
{
    NSResponder *nextResponder = [responder nextResponder];

    if (nextResponder) {
        [self _mergeInspectedObjectsFromResponder:nextResponder seenControllers:seenControllers];
    }


    [self _mergeInspectedObjectsFromPotentialController:responder seenControllers:seenControllers];
    
    // Also allow delegates of responders to be inspectable.  They follow the object of which they are a delegate so they can overrid it
    if ([responder respondsToSelector:@selector(delegate)])
        [self _mergeInspectedObjectsFromPotentialController:[(id)responder delegate] seenControllers:seenControllers];
}

- (void)_getInspectedObjects;
{
    static BOOL isFloating = YES;
    BOOL shouldFloat;
    NSWindow *window;

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

    // Clear the old inspection
    [inspectionSet release];
    inspectionSet = [[OAInspectionSet alloc] init];

    // Fill the inspection set across all inspectable controllers in the responder chain, starting from the 'oldest' (probably the app delegate) to 'newest' the first responder.  This allows responders that are 'closer' to the user to override inspection from 'further' responders.
    NSResponder *responder = [window firstResponder];
    if (!responder)
        responder = window;
    [self _mergeInspectedObjectsFromResponder:responder seenControllers:[NSMutableSet set]];
}

- (void)_recalculateInspectorsAndInspectWindow;
{
    isInspectionQueued = NO;

    // Don't calculate inspection set if it would be pointless
    if (![isa hasVisibleInspector])
        return;
    
    [self _getInspectedObjects];
    [self inspectionSetChanged];
}

- (void)_selectionMightHaveChangedNotification:(NSNotification *)notification;
{
    [self _inspectMainWindow];
}

- (void)_inspectWindowNotification:(NSNotification *)notification;
{
    NSWindow *window = [notification object];
    
    if (window != lastMainWindowBeforeAppSwitch) 
        [self _inspectWindow:window];
    lastMainWindowBeforeAppSwitch = nil;
}

- (void)_uninspectWindowNotification:(NSNotification *)notification;
{
    if (lastMainWindowBeforeAppSwitch == nil)
        [self _inspectWindow:nil];
}

- (void)_applicationWillResignActive:(NSNotification *)notification;
{
    lastMainWindowBeforeAppSwitch = [NSApp mainWindow];
}

- (void)_registerForNotifications;
{
    // While the Inspector is visible, watch for any window to become main.  When that happens, determine if that window's delegate responds to the OAInspectableControllerProtocol, and act accordingly.
    NSNotificationCenter *defaultNotificationCenter = [NSNotificationCenter defaultCenter];
    [defaultNotificationCenter addObserver:self selector:@selector(_applicationWillResignActive:) name:NSApplicationWillResignActiveNotification object:NSApp];
    [defaultNotificationCenter addObserver:self selector:@selector(_inspectWindowNotification:) name:NSWindowDidBecomeMainNotification object:nil];
    [defaultNotificationCenter addObserver:self selector:@selector(_uninspectWindowNotification:) name:NSWindowDidResignMainNotification object:nil];
    [defaultNotificationCenter addObserver:self selector:@selector(_selectionMightHaveChangedNotification:) name:OAInspectorSelectionDidChangeNotification object:nil];
}

@end
