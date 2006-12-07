// Copyright 2002-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OAInspectorGroup.h"

#import <Cocoa/Cocoa.h>
#import <OmniBase/OmniBase.h>
#import <OmniFoundation/OmniFoundation.h>
#import <Carbon/Carbon.h> // for ChangeMenuItemAttributes()

#import "OAInspectorController.h"
#import "OAInspectorRegistry.h"
#import "OAInspectorGroupAnimatedMergeController.h"
#import "NSWindow-OAExtensions.h"

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Inspector.subproj/OAInspectorGroup.m,v 1.107 2004/02/10 04:07:33 kc Exp $");

@interface OAInspectorGroup (Private)
- (void)_showGroup;
- (void)_hideGroup;
- (void)disconnectWindows;
- (void)connectWindows;
- (NSString *)identifier;
- (NSPoint)topLeftPoint;
- (NSRect)firstFrame;
- (float)_horizontalPortionOfMungedDistanceToGroup:(OAInspectorGroup *)otherGroup withFrame:(NSRect)ourFrame;
- (float)_mungedDistanceToTopOfGroup:(OAInspectorGroup *)otherGroup withFrame:(NSRect)ourFrame;
- (float)_mungedDistanceToBottomOfGroup:(OAInspectorGroup *)otherGroup withFrame:(NSRect)ourFrame;
- (BOOL)willConnectToBottomOfGroup:(OAInspectorGroup *)otherGroup withFrame:(NSRect)aFrame;
- (BOOL)willConnectToTopOfGroup:(OAInspectorGroup *)otherGroup withFrame:(NSRect)aFrame;
- (void)connectToBottomOfGroup:(OAInspectorGroup *)otherGroup;
- (BOOL)willInsertInGroup:(OAInspectorGroup *)otherGroup withFrame:(NSRect)aRect index:(int *)anIndex position:(float *)aPosition;
- (BOOL)insertGroup:(OAInspectorGroup *)otherGroup withFrame:(NSRect)aFrame;
- (void)saveInspectorOrder;
- (void)saveExistingGroups;
- (void)restoreFromIdentifier:(NSString *)identifier withInspectors:(NSMutableDictionary *)inspectors;
- (void)setInitialBottommostInspector;
- (NSRect)calculateForInspector:(OAInspectorController *)aController willResizeToFrame:(NSRect)aFrame moveOthers:(BOOL)moveOthers;
- (void)controllerWindowDidResize:(NSNotification *)notification;
- (void)completeResize:(OAInspectorController *)aController;
- (void)matchWidths;
- (float)yPositionOfGroupBelowWithSingleHeight:(float)singleControllerHeight;
+ (void)updateMenuForControllers:(NSArray *)controllers;
@end

@interface OAInspectorGroup (UnpublishedAnimations)
- (void)_animatedShowGroup;
- (void)_animatedHideGroup;
@end

@implementation OAInspectorGroup

#define CONNECTION_DISTANCE_SQUARED 225.0
static NSMutableArray *existingGroups;
static NSMenu *dynamicMenu;
static unsigned int dynamicMenuItemIndex;
static unsigned int dynamicMenuItemCount;
static BOOL useWorkspaces = NO;

+ (void)initialize;
{
    existingGroups = [[NSMutableArray alloc] init];
}

+ (void)enableWorkspaces;
{
    useWorkspaces = YES;
}

static NSComparisonResult sortByDefaultDisplayOrderInGroup(OAInspectorController *a, OAInspectorController *b, void *context)
{
    int aOrder = [[a inspector] defaultDisplayOrderInGroup];
    int bOrder = [[b inspector] defaultDisplayOrderInGroup];

    if (aOrder < bOrder)
        return NSOrderedAscending;
    else if (aOrder > bOrder)
        return NSOrderedDescending;
    else
        return NSOrderedSame;
}

static NSComparisonResult sortGroupByGroupNumber(OAInspectorGroup *a, OAInspectorGroup *b, void *context)
{
    int aOrder = [[[[a inspectors] objectAtIndex:0] inspector] defaultDisplayGroupNumber];
    int bOrder = [[[[b inspectors] objectAtIndex:0] inspector] defaultDisplayGroupNumber];

    if (aOrder < bOrder)
        return NSOrderedAscending;
    else if (aOrder > bOrder)
        return NSOrderedDescending;
    else
        return NSOrderedSame;
}

+ (NSWindow *)_windowInRect:(NSRect)aRect fromWindows:(NSArray *)windows;
{
    int count = [windows count];
    
    while (count--) {
        NSWindow *window = [windows objectAtIndex:count];
        NSRect frame = [window frame];
        
        if (NSIntersectsRect(aRect, frame))
            return window;
    }
    return nil;
}

+ (void)restoreInspectorGroupsWithInspectors:(NSArray *)inspectorList;
{
    NSArray *groups = [[[OAInspectorRegistry sharedInspector] workspaceDefaults] objectForKey:@"_groups"];
    NSMutableDictionary *inspectorById = [NSMutableDictionary dictionary];
    int index, count = [inspectorList count];
    
    [self updateMenuForControllers:inspectorList];

    // load controllers
    for (index = 0; index < count; index++) {
        OAInspectorController *controller = [inspectorList objectAtIndex:index];
        [inspectorById setObject:controller forKey:[controller identifier]];
    }
    
    // restore existing groups from defaults
    count = [groups count];
    for (index = 0; index < count; index++) {
        OAInspectorGroup *group = [[OAInspectorGroup alloc] init];
        
        [group restoreFromIdentifier:[groups objectAtIndex:index] withInspectors:inspectorById];
        [group autorelease];
    }      
      
    // build new groups out of any new inspectors
    {
        NSMutableDictionary *inspectorGroupsByNumber = [NSMutableDictionary dictionary];
        NSMutableArray *inspectorListSorted = [NSMutableArray arrayWithArray:[inspectorById allValues]];

        [inspectorListSorted sortUsingFunction:sortByDefaultDisplayOrderInGroup context:nil];
        count = [inspectorListSorted count];
        for (index = 0; index < count; index++) {
            OAInspectorGroup *group;
            NSNumber *groupKey;
            OAInspectorController *controller = [inspectorListSorted objectAtIndex:index];

            // Make sure we have our window set up for the size computations below.
            [controller loadInterface];
            
            groupKey = [NSNumber numberWithInt:[[controller inspector] defaultDisplayGroupNumber]];
            group = [inspectorGroupsByNumber objectForKey:groupKey];
            if (group == nil) {
                group = [[OAInspectorGroup alloc] init];
                [inspectorGroupsByNumber setObject:group forKey:groupKey];
            } 
            [group addInspector:controller];
        }

        {
            NSArray *groupsInOrder = [[inspectorGroupsByNumber allValues] sortedArrayUsingFunction:sortGroupByGroupNumber context:nil];
            NSMutableArray *otherWindows = [NSMutableArray arrayWithArray:[NSApp windows]];
            int index, count = [otherWindows count];
            NSRect mainScreenVisibleRect = [[NSScreen mainScreen] visibleFrame];
            NSPoint topLeft = NSMakePoint(NSMinX(mainScreenVisibleRect), NSMaxY(mainScreenVisibleRect));
            BOOL allowOverlap = NO;
            float nextX = topLeft.x + OAInspectorStartingHeaderButtonWidth + OAInspectorColumnSpacing;
            
            while (count--) {
                NSWindow *window = [otherWindows objectAtIndex:count];
                if (![window isVisible] || [[window delegate] isKindOfClass:[OAInspectorController class]])
                    [otherWindows removeObjectAtIndex:count];
            }
            
            count = [groupsInOrder count];
            for (index = 0; index < count; index++) {
                OAInspectorGroup *group = [groupsInOrder objectAtIndex:index];
                OAInspectorController *firstController = [[group inspectors] objectAtIndex:0];
                float singlePaneExpandedMaxHeight = [group singlePaneExpandedMaxHeight];
                
                while (1) {
                    NSWindow *overlap = nil;
                    NSRect overlapFrame;
                    
                    if ((topLeft.y - NSMinY(mainScreenVisibleRect)) < singlePaneExpandedMaxHeight) {
                        topLeft.x = nextX;
                        nextX = topLeft.x + OAInspectorStartingHeaderButtonWidth + OAInspectorColumnSpacing;
                        if ((topLeft.x + OAInspectorStartingHeaderButtonWidth) > NSMaxX(mainScreenVisibleRect)) {
                            topLeft.x = NSMinX(mainScreenVisibleRect);
                            allowOverlap = YES;
                        }
                        topLeft.y = NSMaxY(mainScreenVisibleRect);
                    } else if (!allowOverlap) {
                        NSRect possibleRect = NSMakeRect(topLeft.x, topLeft.y - singlePaneExpandedMaxHeight, OAInspectorStartingHeaderButtonWidth, singlePaneExpandedMaxHeight);
                        
                        if ((overlap = [self _windowInRect:possibleRect fromWindows:otherWindows])) {
                            overlapFrame = [overlap frame];
                            nextX = MAX(nextX, NSMaxX(overlapFrame) + OAInspectorColumnSpacing);
                            topLeft.y = NSMinY(overlapFrame) - OAInspectorStartingHeaderButtonHeight;
                            if ([[overlap delegate] isKindOfClass:[NSWindowController class]] && [[overlap delegate] document] != nil) {
                                // leave space for tiling documents, if possible
                                if (NSMaxX(mainScreenVisibleRect) > (nextX + 63.0 + OAInspectorStartingHeaderButtonWidth * 2 + OAInspectorColumnSpacing))
                                    nextX += 63.0;
                                topLeft.y -= 63.0;
                            }
                        } else
                            break;
                    } else        
                        break;
                }
                                
                [group setInitialBottommostInspector];
                [group setTopLeftPoint:topLeft];
                [firstController toggleExpandednessWithNewTopLeftPoint:topLeft animate:NO];
                [group matchWidths];
                [group saveInspectorOrder];
                [group saveExistingGroups];
                [group autorelease];
                
                if ([[firstController inspector] defaultGroupVisibility]) 
                    [group showGroup];
                else 
                    [group hideGroup];

                topLeft.y -= singlePaneExpandedMaxHeight;
                topLeft.y -= OAInspectorStartingHeaderButtonHeight;
                if (nextX > topLeft.x + OAInspectorStartingHeaderButtonWidth + OAInspectorColumnSpacing)
                    nextX = topLeft.x + OAInspectorStartingHeaderButtonWidth + OAInspectorColumnSpacing;
            }
        }
    }
}

- (void)_removeAllInspectors;
{
    [inspectors makeObjectsPerformSelector:@selector(setGroup:) withObject:nil];
    [inspectors removeAllObjects];
}

+ (void)clearAllGroups;
{
    [existingGroups makeObjectsPerformSelector:@selector(disconnectWindows)];
    [existingGroups makeObjectsPerformSelector:@selector(_removeAllInspectors)];
    [existingGroups removeAllObjects];
}

+ (void)setDynamicMenuPlaceholder:(NSMenuItem *)placeholder;
{
    dynamicMenu = [placeholder menu];
    dynamicMenuItemIndex = [[dynamicMenu itemArray] indexOfObject:placeholder];
    dynamicMenuItemCount = 0;
    
    [dynamicMenu removeItemAtIndex:dynamicMenuItemIndex];
}

static NSComparisonResult sortGroupByWindowZOrder(OAInspectorGroup *a, OAInspectorGroup *b, void *zOrder)
{
    int aOrder = [(NSArray *)zOrder indexOfObject:[[[a inspectors] objectAtIndex:0] window]];
    int bOrder = [(NSArray *)zOrder indexOfObject:[[[b inspectors] objectAtIndex:0] window]];

    // opposite order as in original zOrder array
    if (aOrder > bOrder)
        return NSOrderedAscending;
    else if (aOrder < bOrder)
        return NSOrderedDescending;
    else
        return NSOrderedSame;
}

+ (NSArray *)groups;
{
    [existingGroups sortUsingFunction:sortGroupByWindowZOrder context:[NSWindow windowsInZOrder]];
    return existingGroups;
}

+ (NSArray *)visibleGroups;
{
    NSMutableArray *visibleGroups = [NSMutableArray array];
    int index = [existingGroups count];

    while (index--) {
        OAInspectorGroup *group = [existingGroups objectAtIndex:index];

        if ([group isVisible])
            [visibleGroups addObject:group];
    }
    return visibleGroups;
}

// Init and dealloc

- init;
{
    if ([super init] == nil)
        return nil;

    [existingGroups addObject:self];
    inspectors = [[NSMutableArray alloc] init];
    screenChangesEnabled = YES;
    return self;
}

- (void)dealloc;
{
    [inspectors makeObjectsPerformSelector:@selector(setGroup:) withObject:nil];
    [inspectors release];
    [super dealloc];
}

// API

- (void)hideGroup;
{
    if (![self isVisible])
        return;

        if ([self respondsToSelector:@selector(_animatedHideGroup)])
            [self _animatedHideGroup];
        else
            [self _hideGroup];
    [[[OAInspectorRegistry sharedInspector] workspaceDefaults] removeObjectForKey:[NSString stringWithFormat:@"%@-Visible", [self identifier]]];
    [[OAInspectorRegistry sharedInspector] defaultsDidChange];
}

- (void)showGroup;
{
    if ([self isVisible]) {
        [self orderFrontGroup];
    } else {
        if ([self respondsToSelector:@selector(_animatedShowGroup)])
            [self _animatedShowGroup];
        else
            [self _showGroup];
        [[[OAInspectorRegistry sharedInspector] workspaceDefaults] setObject:@"YES" forKey:[NSString stringWithFormat:@"%@-Visible", [self identifier]]];
        [[OAInspectorRegistry sharedInspector] defaultsDidChange];
    }
}

- (void)orderFrontGroup;
{
    // make sure group is visible on screen
    [[inspectors objectAtIndex:0] windowDidChangeScreen:nil];
    [[[inspectors objectAtIndex:0] window] orderFront:self];
    [[[OAInspectorRegistry sharedInspector] workspaceDefaults] setObject:@"YES" forKey:[NSString stringWithFormat:@"%@-Visible", [self identifier]]];
    [[OAInspectorRegistry sharedInspector] defaultsDidChange];
}

- (void)addInspector:(OAInspectorController *)aController;
{
    NSWindow *window = [aController window];
    
    if ([inspectors count]) {
        NSWindow *top = [[inspectors objectAtIndex:0] window];
        OAInspectorController *bottomInspector = [inspectors lastObject];
        
        ignoreResizing = YES;
        [bottomInspector setBottommostInGroup:NO];
        ignoreResizing = NO;
        [window setFrameTopLeftPoint:[self groupFrame].origin];
        [top addChildWindow:window ordered:NSWindowAbove];
    } 
    [aController setGroup:self];
    [inspectors addObject:aController];
}

- (NSRect)inspector:(OAInspectorController *)aController willResizeToFrame:(NSRect)aFrame isSettingExpansion:(BOOL)calledIsSettingExpansion;
{
    NSRect result;
    float desired;
    
    if (ignoreResizing)
        return aFrame;
        
    result = [self calculateForInspector:aController willResizeToFrame:aFrame moveOthers:NO];
    isSettingExpansion = calledIsSettingExpansion;
    if (isSettingExpansion) {
        desired = [self desiredWidth];
        if (desired < NSWidth(result))
            result.size.width = desired;
    } 
   
    if (!isResizing) {
        isResizing = YES;
        [self disconnectWindows];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(controllerWindowDidResize:) name:NSWindowDidResizeNotification object:[aController window]];
        [self performSelector:@selector(completeResize:) withObject:aController afterDelay:([[aController window]  animationResizeTime:result]  + 0.01)];
    }
  
    return result;
}

- (void)detachFromGroup:(OAInspectorController *)aController;
{
    int originalIndex = [inspectors indexOfObject:aController];
    NSWindow *topWindow;
    OAInspectorGroup *newGroup;
    int index, count;
    
    if (!originalIndex)
        return;

    ignoreResizing = YES;
    [[inspectors objectAtIndex:(originalIndex - 1)] setBottommostInGroup:YES];
    ignoreResizing = NO;

    topWindow = [[inspectors objectAtIndex:0] window];
    newGroup = [[OAInspectorGroup alloc] init];
    count = [inspectors count];
    
    for (index = originalIndex; index < count; index++) {
        OAInspectorController *controller = [inspectors objectAtIndex:index];

        [topWindow removeChildWindow:[controller window]];
        [newGroup addInspector:controller];
    }
    [[[OAInspectorRegistry sharedInspector] workspaceDefaults] setObject:@"YES" forKey:[NSString stringWithFormat:@"%@-Visible", [newGroup identifier]]];
    [[OAInspectorRegistry sharedInspector] defaultsDidChange];

    [[aController window] resetCursorRects]; // for the close buttons to highlight correctly in all cases

    [inspectors removeObjectsInRange:NSMakeRange(originalIndex, count - originalIndex)];  
    [self matchWidths];
    [self saveExistingGroups];
    [self saveInspectorOrder];
    [newGroup matchWidths];
    [newGroup saveInspectorOrder];
}

- (BOOL)isHeadOfGroup:(OAInspectorController *)aController;
{
    return aController == [inspectors objectAtIndex:0];
}

- (NSArray *)inspectors;
{
    return inspectors;
}

- (NSRect)groupFrame;
{
    NSRect result = [[[inspectors objectAtIndex:0] window] frame];
    int index, count = [inspectors count];
    
    for (index = 1; index < count; index++) {
        NSRect rect = [[[inspectors objectAtIndex:index] window] frame];
        result.origin.y -= rect.size.height;
        result.size.height += rect.size.height;
    }
    return result;
}

- (BOOL)isVisible;
{
    return [[[inspectors objectAtIndex:0] window] isVisible];
}

- (BOOL)isBelowOverlappingGroup;
{
    NSArray *orderedGroups = [isa groups];
    int index, count = [orderedGroups count];
    NSRect groupFrame = [self groupFrame];
    
    for (index = [orderedGroups indexOfObject:self] + 1; index < count; index++) {
        NSRect otherFrame = [[orderedGroups objectAtIndex:index] groupFrame];
        
        if (NSIntersectsRect(groupFrame, otherFrame))
            return YES;
    }
    return NO;
}

- (float)minimumWidth;
{
    float result = 0.0;
    int index = [inspectors count];
    
    while (index--) {
        float inspectorMinimum = [[inspectors objectAtIndex:index] minimumWidth];
        
        if (inspectorMinimum > result)
            result = inspectorMinimum;
    }
    return result;
}

- (float)desiredWidth;
{
    float result = 0.0;
    int index = [inspectors count];
    
    while (index--) {
        float inspectorDesired = [[inspectors objectAtIndex:index] desiredWidth];
        
        if (inspectorDesired > result)
            result = inspectorDesired;
    }
    return result;
}

- (float)singlePaneExpandedMaxHeight;
{
    float result = 0.0;
    int index = [inspectors count];
    
    while (index--) {
        float inspectorDesired = [[inspectors objectAtIndex:index] desiredHeightWhenExpanded];
        
        if (inspectorDesired > result)
            result = inspectorDesired;
    }
    return result + OAInspectorStartingHeaderButtonHeight * ([inspectors count] - 1);
}

- (BOOL)ignoreResizing;
{
    return ignoreResizing;
}

- (BOOL)canBeginResizingOperation;
{
    return !isResizing;
}

- (BOOL)screenChangesEnabled;
{
    return screenChangesEnabled;
}

- (void)setScreenChangesEnabled:(BOOL)yn;
{
    screenChangesEnabled = yn;
}

- (void)setFloating:(BOOL)yn;
{
    int index, count = [inspectors count];
    
    for (index = 0; index < count; index++) {
        NSWindow *window = [[inspectors objectAtIndex:index] window];
        [window setLevel:yn ? NSFloatingWindowLevel : NSNormalWindowLevel];
    }
}

- (NSRect)fitFrame:(NSRect)aFrame onScreen:(NSScreen *)screen;
{
    NSRect screenRect = [screen visibleFrame];
    
    if (NSHeight(aFrame) > NSHeight(screenRect))
        aFrame.origin.y = floor(NSMaxY(screenRect) - NSHeight(aFrame));
    else if (NSMaxY(aFrame) > NSMaxY(screenRect))
        aFrame.origin.y = floor(NSMaxY(screenRect) - NSHeight(aFrame));
    else if (NSMinY(aFrame) < NSMinY(screenRect))
        aFrame.origin.y = ceil(NSMinY(screenRect));
                            
    if (NSMaxX(aFrame) > NSMaxX(screenRect))
        aFrame.origin.x = floor(NSMaxX(screenRect) - NSWidth(aFrame));
    else if (NSMinX(aFrame) < NSMinX(screenRect))
        aFrame.origin.x = ceil(NSMinX(screenRect));
    
    return aFrame;
}

- (void)setTopLeftPoint:(NSPoint)aPoint;
{
    NSWindow *topWindow = [[inspectors objectAtIndex:0] window];
    int index, count = [inspectors count];

    [topWindow setFrameTopLeftPoint:aPoint];
    for (index = 1; index < count; index++) {
        NSWindow *bottomWindow = [[inspectors objectAtIndex:index] window];
        
        [bottomWindow setFrameTopLeftPoint:[topWindow frame].origin];
        topWindow = bottomWindow;
    }
    [[[OAInspectorRegistry sharedInspector] workspaceDefaults] setObject:NSStringFromPoint(aPoint)  forKey:[NSString stringWithFormat:@"%@-Position", [self identifier]]];
    [[OAInspectorRegistry sharedInspector] defaultsDidChange];
}

- (NSRect)snapToOtherGroupWithFrame:(NSRect)aRect;
{
    int index, count = [inspectors count];
    id closestSoFar = nil;
    NSRect closestFrame;
    float closestDistance = 99999.0;
    float position;
    NSArray *documents;

    // Snap to top or bottom of other group
    count = [existingGroups count];
    for (index = 0; index < count; index++) {
        OAInspectorGroup *otherGroup = [existingGroups objectAtIndex:index];
            
        if (self == otherGroup || ![otherGroup isVisible])
            continue;
        if ([self willConnectToBottomOfGroup:otherGroup withFrame:aRect]) {
            aRect.origin.x = [otherGroup groupFrame].origin.x;
            aRect.origin.y = [otherGroup groupFrame].origin.y - aRect.size.height - OAInspectorSpaceBetweenButtons;
            [[OAInspectorGroupAnimatedMergeController sharedInspectorGroupAnimatedMergeController] closeWindow];
            return aRect;
        } else if ([self willConnectToTopOfGroup:otherGroup withFrame:aRect]) {
            aRect.origin.x = [otherGroup groupFrame].origin.x;
            aRect.origin.y = NSMaxY([otherGroup groupFrame]) + OAInspectorSpaceBetweenButtons;
            [[OAInspectorGroupAnimatedMergeController sharedInspectorGroupAnimatedMergeController] closeWindow];
            return aRect;
        } else if ([otherGroup willInsertInGroup:self withFrame:aRect index:NULL position:&position]) {
            aRect.origin.y = floor(position + OAInspectorStartingHeaderButtonHeight / 2) - aRect.size.height;
            [[OAInspectorGroupAnimatedMergeController sharedInspectorGroupAnimatedMergeController] closeWindow];
            return aRect;
        }
    }

    // Check for snap to side of other group
    
    count = [existingGroups count];
    for (index = 0; index < count; index++) {
        OAInspectorGroup *otherGroup = [existingGroups objectAtIndex:index];
        NSRect otherFrame;
        float distance;

        if (self == otherGroup || ![otherGroup isVisible])
            continue;
            
        otherFrame = [otherGroup groupFrame];
        if (NSMinY(otherFrame) > NSMaxY(aRect) || NSMaxY(otherFrame) < NSMinY(aRect))
            distance = ABS(NSMinX(otherFrame) - NSMinX(aRect));
        else
            distance = MIN(ABS(NSMinX(otherFrame) - OAInspectorColumnSpacing - NSMaxX(aRect)), ABS(NSMaxX(otherFrame) + OAInspectorColumnSpacing - NSMinX(aRect)));
            
        if (distance < closestDistance || (distance == closestDistance && ((NSMinY(closestFrame) > NSMinY(otherFrame)) || NSMinY(closestFrame) < NSMinY(aRect)) && (NSMinY(otherFrame) > NSMaxY(aRect)))) {
            closestDistance = distance;
            closestSoFar = otherGroup;
            closestFrame = otherFrame;
        }
    }
    
    // Check for snap to side of document window
    documents = [[NSDocumentController sharedDocumentController] documents];
    count = [documents count];
    for (index = 0; index < count; index++) {
        NSArray *windowControllers = [[documents objectAtIndex:index] windowControllers];
        int windowCount = [windowControllers count];
        
        while (windowCount--) {
            NSWindow *window = [[windowControllers objectAtIndex:windowCount] window];
            NSRect windowFrame = [window frame];
            float distance = MIN(ABS(NSMinX(windowFrame) - OAInspectorColumnSpacing - NSMaxX(aRect)), ABS(NSMaxX(windowFrame) + OAInspectorColumnSpacing - NSMinX(aRect)));

            if (![window isVisible])
                continue;

            if (distance < closestDistance) {
                closestDistance = distance;
                closestSoFar = window;
            }
        } 
    }
    
    if (closestDistance < 15.0) {
        BOOL normalWindow = [closestSoFar isKindOfClass:[NSWindow class]];
        NSRect frame = normalWindow ? [closestSoFar frame] : [closestSoFar groupFrame];
        
        if (ABS(NSMinX(frame) - NSMinX(aRect)) < 15.0) {
            aRect.origin.x = NSMinX(frame);
            
            if (!normalWindow) {
                float belowClosest = NSMaxY(frame) - [closestSoFar singlePaneExpandedMaxHeight] - OAInspectorStartingHeaderButtonHeight;
                
                if (ABS(NSMaxY(aRect) - belowClosest) < 10.0)
                    aRect.origin.y -= (NSMaxY(aRect) - belowClosest);
            }
            
        } else {
            frame = NSInsetRect(frame, -1.0, -1.0);
            if (ABS(NSMinX(frame) - OAInspectorColumnSpacing - NSMaxX(aRect)) < ABS(NSMaxX(frame) + OAInspectorColumnSpacing - NSMinX(aRect)))
                aRect.origin.x = NSMinX(frame) - NSWidth(aRect) - OAInspectorColumnSpacing;
            else
                aRect.origin.x = NSMaxX(frame) + OAInspectorColumnSpacing;
        }
    }    


    {
        OAInspectorGroup *closestGroupWithoutSnapping = nil;
        float closestGroupScore = 1e10;

        count = [existingGroups count];
        for (index = 0; index < count; index++) {
            OAInspectorGroup *otherGroup = [existingGroups objectAtIndex:index];
            float currentGroupScore;

            if (self == otherGroup || ![otherGroup isVisible])
                continue;

            currentGroupScore = [self _mungedDistanceToBottomOfGroup:otherGroup withFrame:aRect];
            if (currentGroupScore < closestGroupScore) {
                closestGroupScore = currentGroupScore;
                closestGroupWithoutSnapping = otherGroup;
            }
            currentGroupScore = [self _mungedDistanceToTopOfGroup:otherGroup withFrame:aRect];
            if (currentGroupScore < closestGroupScore) {
                closestGroupScore = currentGroupScore;
                closestGroupWithoutSnapping = otherGroup;
            }
        }

        if (closestGroupScore < 800) {
            OAInspectorGroupAnimatedMergeController *animatedMergeController = [OAInspectorGroupAnimatedMergeController sharedInspectorGroupAnimatedMergeController];
            [animatedMergeController animateWithFirstGroupRect:aRect andSecondGroupRect:[closestGroupWithoutSnapping groupFrame] atLevel:[[[inspectors objectAtIndex:0] window] level]];
        } else
            [[OAInspectorGroupAnimatedMergeController sharedInspectorGroupAnimatedMergeController] closeWindow];
    }
    
    return aRect;
}

- (void)windowsDidMoveToFrame:(NSRect)aFrame;
{
    int index, count = [inspectors count];
    
    [self retain];
    
    count = [existingGroups count];
    for (index = 0; index < count; index++) {
        OAInspectorGroup *otherGroup = [existingGroups objectAtIndex:index];
        
        if (self == otherGroup || ![otherGroup isVisible])
            continue;
        if ([self willConnectToBottomOfGroup:otherGroup withFrame:aFrame]) {
            [self connectToBottomOfGroup:otherGroup];
            break;
        } else if ([self willConnectToTopOfGroup:otherGroup withFrame:aFrame]) {
            [otherGroup connectToBottomOfGroup:self];
            break;
        } else if ([otherGroup insertGroup:self withFrame:aFrame]) {
            [inspectors removeAllObjects];
            break;
        }
    }
    
    if ([inspectors count]) {
        NSRect frame = [[[inspectors objectAtIndex:0] window] frame];
        NSString *position = NSStringFromPoint(NSMakePoint(NSMinX(frame), NSMaxY(frame)));

        [[[OAInspectorRegistry sharedInspector] workspaceDefaults] setObject:position forKey:[NSString stringWithFormat:@"%@-Position", [self identifier]]];
        [[OAInspectorRegistry sharedInspector] defaultsDidChange];
    }
    [self autorelease];
}

- (NSMutableDictionary *)debugDictionary;
{
    NSMutableDictionary *result = [super debugDictionary];
    int index, count = [inspectors count];
    NSMutableArray *inspectorInfo = [NSMutableArray arrayWithCapacity:count];
    
    for (index = 0; index < count ;index++)
        [inspectorInfo addObject:[[inspectors objectAtIndex:index] debugDictionary]];
    [result setObject:inspectorInfo forKey:@"inspectors"];
        
    [result setObject:([self isVisible] ? @"YES" : @"NO") forKey:@"isVisible"];

    return result;
}

@end

@implementation OAInspectorGroup (Private)

- (void)_hideGroup;
{
    int index = [inspectors count];

    while (index--) 
        [[[inspectors objectAtIndex:index] window] orderOut:self];
}

- (void)_showGroup;
{
    int index, count = [inspectors count];

    isShowing = YES;

    // Remember whether there were previously any visible inspectors
    BOOL hadVisibleInspector = [OAInspectorRegistry hasVisibleInspector];
    
    // Position windows if we haven't already
    if (!_hasPositionedWindows) {
        _hasPositionedWindows = YES;
        
        NSDictionary *defaults = [[OAInspectorRegistry sharedInspector] workspaceDefaults];
        for (index = 0; index < count; index++) {
            OAInspectorController *controller = [inspectors objectAtIndex:index];
            NSString *identifier = [controller identifier];

            [controller loadInterface];
            NSWindow *window = [controller window];
            OBASSERT(window);
            if (!index) {
                NSString *position = [defaults objectForKey:[NSString stringWithFormat:@"%@-Position", identifier]];
                if (position)
                    [window setFrameTopLeftPoint:NSPointFromString(position)];
            }
        }
    }
    
    // Doing this here instead of in -restoreFromIdentifier:withInspectors: to avoid loading the nib until we are *really* going on screen
    [self matchWidths];

    index = count;
    while (index--) 
        [[inspectors objectAtIndex:index] prepareWindowForDisplay];
    [self setTopLeftPoint:[self topLeftPoint]];

    // to make sure they are placed visibly and ordered correctly
    [[inspectors objectAtIndex:0] windowDidChangeScreen:nil];  
      
    for (index = 0; index < count; index++)
        [[inspectors objectAtIndex:index] displayWindow];
        
    [self connectWindows];
    isShowing = NO;

    // Finally, if there were previously no visible inspectors, poke the update
    if (!hadVisibleInspector)
        [OAInspectorRegistry updateInspector];
}

- (void)disconnectWindows;
{
    NSWindow *topWindow = [[inspectors objectAtIndex:0] window];
    int index = [inspectors count];
    
    while (index-- > 1) 
        [topWindow removeChildWindow:[[inspectors objectAtIndex:index] window]];
}

- (void)connectWindows;
{
    int index, count = [inspectors count];
    NSWindow *topWindow = [[inspectors objectAtIndex:0] window];
    NSWindow *lastWindow = topWindow;
    
    if (![topWindow isVisible])
        return;
    
    for (index = 1; index < count; index++) {
        NSWindow *window = [[inspectors objectAtIndex:index] window];
        
        [window orderWindow:NSWindowAbove relativeTo:[lastWindow windowNumber]];
        [topWindow addChildWindow:window ordered:NSWindowAbove];
        lastWindow = window;
    }
}

- (NSString *)identifier;
{
    return [[inspectors objectAtIndex:0] identifier];
}

- (BOOL)isVisible;
{
    if (isShowing)
        return YES;
    else
        return [[[inspectors objectAtIndex:0] window] isVisible];
}

- (NSPoint)topLeftPoint;
{
    NSRect frameRect = [[[inspectors objectAtIndex:0] window] frame];
    
    return NSMakePoint(NSMinX(frameRect), NSMaxY(frameRect));
}

- (NSRect)firstFrame;
{
    return [[[inspectors objectAtIndex:0] window] frame];
}

- (float)_horizontalPortionOfMungedDistanceToGroup:(OAInspectorGroup *)otherGroup withFrame:(NSRect)ourFrame;
{
    NSRect otherFrame = [otherGroup groupFrame];

    const float requiredHorizontalOverlap = 5.0; // pixels overlap or no match no matter how close we are
    if (NSMinX(ourFrame) > NSMaxX(otherFrame) - requiredHorizontalOverlap || NSMaxX(ourFrame) - requiredHorizontalOverlap < NSMinX(otherFrame))
        return 1e10;
    
    return pow((NSMidX(ourFrame) - NSMidX(otherFrame)) / 6.0, 2.0);
}

- (float)_mungedDistanceToTopOfGroup:(OAInspectorGroup *)otherGroup withFrame:(NSRect)ourFrame;
{
    NSRect otherFrame = [otherGroup groupFrame];
    return [self _horizontalPortionOfMungedDistanceToGroup:otherGroup withFrame:ourFrame] + pow(NSMinY(ourFrame) - NSMaxY(otherFrame), 2.0);
}

- (float)_mungedDistanceToBottomOfGroup:(OAInspectorGroup *)otherGroup withFrame:(NSRect)ourFrame;
{
    NSRect otherFrame = [otherGroup groupFrame];
    return [self _horizontalPortionOfMungedDistanceToGroup:otherGroup withFrame:ourFrame] + pow(NSMaxY(ourFrame) - NSMinY(otherFrame), 2.0);
}


- (BOOL)willConnectToTopOfGroup:(OAInspectorGroup *)otherGroup withFrame:(NSRect)ourFrame;
{
    return [self _mungedDistanceToTopOfGroup:otherGroup withFrame:ourFrame] < CONNECTION_DISTANCE_SQUARED;
}

- (BOOL)willConnectToBottomOfGroup:(OAInspectorGroup *)otherGroup withFrame:(NSRect)ourFrame;
{
    return [self _mungedDistanceToBottomOfGroup:otherGroup withFrame:ourFrame] < CONNECTION_DISTANCE_SQUARED;
}

- (void)connectToBottomOfGroup:(OAInspectorGroup *)otherGroup;
{
    int controllerIndex, controllerCount = [inspectors count];

    [self retain];
    [self disconnectWindows];
    for (controllerIndex = 0; controllerIndex < controllerCount; controllerIndex++)
        [otherGroup addInspector:[inspectors objectAtIndex:controllerIndex]];
    [inspectors removeAllObjects];
    [existingGroups removeObject:self];
    [otherGroup matchWidths];
    [otherGroup saveInspectorOrder];
    [otherGroup saveExistingGroups];
    [self autorelease];
}

#define INSERTION_CLOSENESS	12.0

- (BOOL)willInsertInGroup:(OAInspectorGroup *)otherGroup withFrame:(NSRect)aFrame index:(int *)anIndex position:(float *)aPosition;
{
    NSRect groupFrame = [self groupFrame];
    float insertionPosition;
    float inspectorBreakpoint;
    int index, count;
    
    if (NSMinX(aFrame) + NSWidth(aFrame)/3 > NSMaxX(groupFrame) - NSWidth(aFrame)/3 || NSMaxX(aFrame) - NSWidth(aFrame)/3 < NSMinX(groupFrame) + NSWidth(groupFrame)/3)
        return NO;
    
    insertionPosition = NSMaxY(aFrame) - (OAInspectorStartingHeaderButtonHeight / 2);
    
    inspectorBreakpoint = NSMaxY(groupFrame) - NSHeight([[[inspectors objectAtIndex:0] window] frame]);
    count = [inspectors count];
    for (index = 1; index < count; index++) {
        if (ABS(inspectorBreakpoint - insertionPosition) <= INSERTION_CLOSENESS) {
            if (anIndex)
                *anIndex = index;
            if (aPosition)
                *aPosition = inspectorBreakpoint;
            return YES;
        }
        inspectorBreakpoint -= NSHeight([[[inspectors objectAtIndex:index] window] frame]);
    }    
    return NO;    
}

- (BOOL)insertGroup:(OAInspectorGroup *)otherGroup withFrame:(NSRect)aFrame;
{
    NSArray *insertions;
    NSArray *below;
    int index, count;
    
    if (![self willInsertInGroup:otherGroup withFrame:aFrame index:&index position:NULL])
        return NO;
    
    count = [inspectors count];
    insertions = [otherGroup inspectors];
    below = [inspectors subarrayWithRange:NSMakeRange(index, count - index)];
            
    [inspectors removeObjectsInRange:NSMakeRange(index, count - index)];
            
    [otherGroup disconnectWindows];
    [existingGroups removeObject:otherGroup];

    count = [insertions count];
    for (index = 0; index < count; index++)
        [self addInspector:[insertions objectAtIndex:index]];
    count = [below count];
    for (index = 0; index < count; index++)
        [self addInspector:[below objectAtIndex:index]]; 
                
    [self matchWidths];
    [self saveInspectorOrder];
    [self saveExistingGroups];
    return YES;
}

- (void)saveInspectorOrder;
{
    NSMutableArray *identifiers = [NSMutableArray array];
    int index, count = [inspectors count];
    
    for (index = 0; index < count; index++)
        [identifiers addObject:[[inspectors objectAtIndex:index] identifier]];

    [[[OAInspectorRegistry sharedInspector] workspaceDefaults] setObject:identifiers  forKey:[NSString stringWithFormat:@"%@-Order", [self identifier]]];
    [[OAInspectorRegistry sharedInspector] defaultsDidChange];
}

- (void)saveExistingGroups;
{
    NSMutableArray *identifiers = [NSMutableArray array];
    int index, count = [existingGroups count];
    
    for (index = 0; index < count; index++)
        [identifiers addObject:[[existingGroups objectAtIndex:index] identifier]];

    [[[OAInspectorRegistry sharedInspector] workspaceDefaults] setObject:identifiers forKey:@"_groups"];
    [[OAInspectorRegistry sharedInspector] defaultsDidChange];
}

- (void)restoreFromIdentifier:(NSString *)identifier withInspectors:(NSMutableDictionary *)inspectorsById;
{
    NSDictionary *defaults = [[OAInspectorRegistry sharedInspector] workspaceDefaults];
    NSArray *identifiers = [defaults objectForKey:[NSString stringWithFormat:@"%@-Order", identifier]];
    int index, count = [identifiers count];
    BOOL willBeVisible = [defaults objectForKey:[NSString stringWithFormat:@"%@-Visible", identifier]] != nil;
    
    for (index = 0; index < count; index++) {
        NSString *identifier = [identifiers objectAtIndex:index];
        OAInspectorController *controller = [inspectorsById objectForKey:identifier];

        // The controller might not have a window yet if its never been displayed.  On the other hand, we might be switching workspaces, so we can't assume it doesn't have a window.
        NSWindow *window = [controller window];

        if (controller == nil) // new version of program with inspector names changed
            continue;

        if (!willBeVisible)
            [window orderOut:self];
    
        [inspectorsById removeObjectForKey:identifier];
        [self addInspector:controller];
        if (!index) {
            NSString *position = [defaults objectForKey:[NSString stringWithFormat:@"%@-Position", identifier]];
            if (position)
                [window setFrameTopLeftPoint:NSPointFromString(position)];
        }
    }
    if (![inspectors count]) {
        [existingGroups removeObject:self];
        return;
    }
    
    [self setInitialBottommostInspector];
    
    if (willBeVisible) 
        [self _showGroup];
    else
        [self _hideGroup];
}

- (void)setInitialBottommostInspector;
{
    ignoreResizing = YES;
    [[inspectors lastObject] setBottommostInGroup:YES];
    ignoreResizing = NO;
}

- (NSRect)calculateForInspector:(OAInspectorController *)aController willResizeToFrame:(NSRect)aFrame moveOthers:(BOOL)moveOthers;
{
    int index, count = [inspectors count];
    NSWindow *firstWindow = [[inspectors objectAtIndex:0] window];
    NSRect firstWindowFrame = [firstWindow frame];
    float height = 0.0;
    float maxHeight;
    NSRect returnValue = aFrame;
    NSPoint topLeft;
    BOOL didCollapsing = NO;
    
    if (ignoreResizing)
        return aFrame;
    
    topLeft.x = NSMinX(firstWindowFrame);
    topLeft.y = NSMaxY(firstWindowFrame);
    
    // If the controller involved is shrinking vertically, we don't want to do anything complicated like collapse other panes
    if (isSettingExpansion && NSHeight(aFrame) > (aController ? NSHeight([[aController window] frame]) : 0.0)) {
        // Calculate height and max height
        for (index = 0; index < count; index++) {
            OAInspectorController *controller = [inspectors objectAtIndex:index];
            
            if (controller == aController)
                height += aFrame.size.height;
            else
                height += [[controller window] frame].size.height;
        }
        maxHeight = NSMaxY(firstWindowFrame) - [self yPositionOfGroupBelowWithSingleHeight:aFrame.size.height];
    
        // If height is too large, collapse panes to make space, if neccessary. 
        for (index = count - 1; height > maxHeight && index >= 0; index--) {
            OAInspectorController *controller = [inspectors objectAtIndex:index];
            
            if (controller != aController && [controller isExpanded]) {
                [controller setCollapseOnTakeNewPosition:YES];
                height -= [[controller window] frame].size.height;
                height += OAInspectorStartingHeaderButtonHeight;
                if (index != count - 1)
                    height += OAInspectorSpaceBetweenButtons;
                didCollapsing = YES;
            }
        }
    }

    // Set positions of all panes    
    ignoreResizing = YES;
    for (index = 0; index < count; index++) {
        OAInspectorController *controller = [inspectors objectAtIndex:index];

        if (controller == aController) {
            returnValue.origin.x = topLeft.x;
            returnValue.origin.y = topLeft.y - returnValue.size.height;
            topLeft.y -= returnValue.size.height;
        } else {
            height = [controller heightAfterTakeNewPosition];
            [controller setNewPosition:topLeft];
            topLeft.y -= height;
            if (moveOthers) 
                [controller takeNewPositionWithWidth:aFrame.size.width];
        }
    }
    ignoreResizing = NO;
    return returnValue;
}

- (void)controllerWindowDidResize:(NSNotification *)notification;
{
    int index = [inspectors count];
    NSWindow *window = [notification object];
    OAInspectorController *controller = nil;;

    while (index--) {
        controller = [inspectors objectAtIndex:index];
        if ([controller window] == window) 
            break;
    }
    [self calculateForInspector:controller willResizeToFrame:[window frame] moveOthers:YES];
}

- (void)completeResize:(OAInspectorController *)aController;
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidResizeNotification object:nil];
    [self connectWindows];
    isResizing = NO;
}

- (void)matchWidths;
{
    int index, count = [inspectors count];
    NSRect rect = [[[inspectors objectAtIndex:0] window] frame];
    rect.origin.y += rect.size.height;
    rect.size.width = [self desiredWidth];
    
    ignoreResizing = YES;
    [self disconnectWindows];
    for (index = 0; index < count; index++) {
        NSWindow *window = [[inspectors objectAtIndex:index] window];
        NSSize size = [window frame].size;

        rect.size.height = size.height;
        rect.origin.y -= size.height;

        if (size.width != rect.size.width)
            [window setFrame:rect display:NO animate:NO];
    }
    [self connectWindows];
    ignoreResizing = NO;
}

#define OVERLAP_ALLOWANCE 10.0

- (float)yPositionOfGroupBelowWithSingleHeight:(float)singleControllerHeight;
{
    NSRect firstFrame = [self firstFrame];
    int index = [existingGroups count];
    float result = NSMinY([[[[inspectors objectAtIndex:0] window] screen] visibleFrame]);
    float ignoreAbove = NSMaxY(firstFrame) - (([inspectors count] - 1) * OAInspectorStartingHeaderButtonHeight) - singleControllerHeight;
    
    while (index--) {
        OAInspectorGroup *group = [existingGroups objectAtIndex:index];
        NSRect otherFirstFrame;
        
        if (group == self || ![group isVisible])
            continue;
            
        otherFirstFrame = [group firstFrame];        
        if (NSMaxY(otherFirstFrame) > ignoreAbove) // above us
            continue;

        if ((NSMaxX(firstFrame) - OVERLAP_ALLOWANCE) < NSMinX(otherFirstFrame) || (NSMinX(firstFrame) + OVERLAP_ALLOWANCE) > NSMaxX(otherFirstFrame)) // non overlapping
            continue;        
        
        if (NSMaxY(otherFirstFrame) > result)
            result = NSMaxY(otherFirstFrame);
    }
    return result;
}

static NSComparisonResult sortByGroupAndDisplayOrder(OAInspectorController *a, OAInspectorController *b, void *context)
{
    int aOrder = [[a inspector] defaultDisplayGroupNumber] * 1000 + [[a inspector] defaultDisplayOrderInGroup];
    int bOrder = [[b inspector] defaultDisplayGroupNumber] * 1000 + [[b inspector] defaultDisplayOrderInGroup];

    if (aOrder < bOrder)
        return NSOrderedAscending;
    else if (aOrder > bOrder)
        return NSOrderedDescending;
    else
        return NSOrderedSame;
}

extern MenuRef _NSGetCarbonMenu(NSMenu *);

+ (void)updateMenuForControllers:(NSArray *)controllers;
{
    int index, count, itemIndex;
    NSMutableArray *dynamicIndexes = [NSMutableArray array];
    MenuRef menu;
    unsigned int lastGroupIdentifier, itemsInGroup;
    NSMenuItem *item;
    NSBundle *bundle = [self bundle];
    
    if (!dynamicMenu)
        return;
    while (dynamicMenuItemCount--)
        [dynamicMenu removeItemAtIndex:dynamicMenuItemIndex];
    itemIndex = dynamicMenuItemIndex;

    if (useWorkspaces) {
        item = [[NSMenuItem alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Workspace", @"OmniAppKit", bundle, @"Workspace submenu item") action:NULL keyEquivalent:@""];
        [item setSubmenu:[[OAInspectorRegistry sharedInspector] workspaceMenu]];
    } else {
        item = [[OAInspectorRegistry sharedInspector] resetPanelsItem];
    }
    [dynamicMenu insertItem:item atIndex:itemIndex++];
    [dynamicMenu insertItem:[NSMenuItem separatorItem] atIndex:itemIndex++];

            
    controllers = [controllers sortedArrayUsingFunction:sortByGroupAndDisplayOrder context:NULL];
    count = [controllers count];
    lastGroupIdentifier = [[[controllers objectAtIndex:0] inspector] defaultDisplayGroupNumber];
    itemsInGroup = 0;
    for (index = 0; index < count; index++) {
        OAInspectorController *controller = [controllers objectAtIndex:index];
        NSString *keyEquivalent;

        if ([[controller inspector] defaultDisplayGroupNumber] != lastGroupIdentifier) {
            if (itemsInGroup > 1)
                [dynamicMenu insertItem:[NSMenuItem separatorItem] atIndex:itemIndex++];
            lastGroupIdentifier = [[controller inspector] defaultDisplayGroupNumber];
            itemsInGroup = 0;
        } 
        itemsInGroup++;

        item = [controller menuItem];
        keyEquivalent = [item keyEquivalent];
        if ([keyEquivalent length]) {
            NSMenuItem *close = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Close %@", @"OmniAppKit", bundle, @"Close inspector panel menu item format"), [item title]] action:@selector(_menuHideGroup:) keyEquivalent:keyEquivalent];        
            [close setKeyEquivalentModifierMask:[item keyEquivalentModifierMask] | NSControlKeyMask];
            [close setTarget:controller];
            [dynamicIndexes addObject:[NSNumber numberWithInt:itemIndex]];
            [dynamicMenu insertItem:close atIndex:itemIndex++];
            [dynamicIndexes addObject:[NSNumber numberWithInt:itemIndex]];
        }
        [dynamicMenu insertItem:item atIndex:itemIndex++];
    }
        
    dynamicMenuItemCount = itemIndex - dynamicMenuItemIndex;
    
    menu = _NSGetCarbonMenu(dynamicMenu);
    itemIndex = [dynamicIndexes count];
    while (itemIndex--)
        ChangeMenuItemAttributes(menu, [[dynamicIndexes objectAtIndex:itemIndex] intValue]+1, kMenuItemAttrDynamic, 0);    
}

@end
