// Copyright 2002-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import "OAInspectorController.h"

#import <Cocoa/Cocoa.h>
#import <OmniFoundation/OmniFoundation.h>
#import <OmniBase/OmniBase.h>

#import "OAInspectorRegistry.h"
#import "OAInspectorHeaderView.h"
#import "OAInspectorResizer.h"
#import "OAInspectorGroup.h"
#import "OAInspectorWindow.h"
#import "OAInspectorGroupAnimatedMergeController.h"

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Inspector.subproj/OAInspectorController.m,v 1.72 2003/03/30 10:32:59 wjs Exp $");

@interface OAInspectorController (Private) <OAInspectorHeaderViewDelegateProtocol>
- (void)toggleDisplayAction:sender;
- (void)_buildHeadingView;
- (void)_buildWindow;
- (NSView *)_inspectorView;
@end

#warning This class uses Jaguar-specific NSWindow move group API

@interface NSWindow (JaguarAPI)
- (NSArray *)childWindows;
- (NSWindow *)parentWindow;
@end

@implementation OAInspectorController

// Init and dealloc

- initWithInspector:(NSObject <OAGroupedInspector> *)anInspector;
{
    if ([super init] == nil)
        return nil;

    inspector = [anInspector retain];
    isExpanded = NO;
    
    if ([inspector respondsToSelector:@selector(setInspectorController:)])
        [(id)inspector setInspectorController:self];
    
    return self;
}

// API

- (void)setGroup:(OAInspectorGroup *)aGroup;
{
    if (group != aGroup) {
        group = aGroup;
        [headingButton setNeedsDisplay:YES];
    }
}

- (NSObject <OAGroupedInspector> *)inspector;
{
    return inspector;
}

- (NSWindow *)window;
{
    return window;
}

- (BOOL)isExpanded;
{
    return isExpanded;
}

- (NSString *)identifier;
{
    return [inspector className];
}

- (void)_menuHideGroup:(id)sender;
{
    [group hideGroup];
}

- (NSMenuItem *)menuItem;
{
    if (!menuItem) {
        NSString *keyEquivalent = [inspector keyEquivalent];
        NSImage *menuImage;
        
        if (keyEquivalent == nil)
            keyEquivalent = @"";
        menuItem = [[NSMenuItem alloc] initWithTitle:[inspector inspectorName] action:@selector(toggleDisplayAction:) keyEquivalent:keyEquivalent];
        [menuItem setTarget:self];

        menuImage = [NSImage imageNamed:[inspector imageName]];
        [menuImage setSize:NSMakeSize(rint([menuImage size].width), rint([menuImage size].height))]; // Workaround 10.2 NSMenu bug because our images are bizarrely returning 13.00058 as their height, and this causes NSMenu to clip the bottom pixel of our image. 
        [menuItem setImage:menuImage];
        if ([keyEquivalent length])
            [menuItem setKeyEquivalentModifierMask:[inspector keyEquivalentModifierMask]];
    }
    return menuItem;
}

- (BOOL)validateMenuItem:(NSMenuItem *)item;
{
    [item setState:([group isVisible] ? NSOnState : NSOffState)];

    if ([item action] == @selector(_menuHideGroup:))
        return [group isVisible];
    else
        return YES;
}

- (float)minimumWidth;
{
    if (isExpanded)
        return minimumSize.width;
    else    
        return [headingButton minimumWidth];
}

- (float)desiredWidth;
{
    if (isExpanded && !collapseOnTakeNewPosition)
        return desiredWidth;
    else
        return [headingButton minimumWidth];
}

- (float)desiredHeightWhenExpanded;
{
    return NSHeight([[self _inspectorView] frame]) + NSHeight([headingButton frame]);
}

- (void)toggleDisplay;
{
    if ([group isVisible]) {
        [self headerViewDidToggleExpandedness:headingButton];
    } else {
        [group showGroup];
        if (!isExpanded)
            [self headerViewDidToggleExpandedness:headingButton];
    }
}

- (void)showInspector;
{
    if (![group isVisible] || !isExpanded)
        [self toggleDisplay];
}

- (void)setBottommostInGroup:(BOOL)isBottom;
{
    if (isBottom == isBottommostInGroup)
        return;
    
    isBottommostInGroup = isBottom;
    if (!isExpanded) {
        NSRect windowFrame = [window frame];
        NSRect headingFrame;
        
        headingFrame.origin = NSMakePoint(0, isBottommostInGroup ? 0.0 : OAInspectorSpaceBetweenButtons);
        headingFrame.size = [headingButton frame].size;
        [window setFrame:NSMakeRect(NSMinX(windowFrame), NSMaxY(windowFrame) - NSMaxY(headingFrame), NSWidth(headingFrame), NSMaxY(headingFrame)) display:YES animate:YES];
    }
}

- (void)toggleExpandednessWithNewTopLeftPoint:(NSPoint)topLeftPoint animate:(BOOL)animate;
{
    NSRect windowFrame;
    NSView *view = [self _inspectorView];
    
    isExpanded = !isExpanded;   
    isToggling = YES; 
    [group setScreenChangesEnabled:NO];
    [headingButton setExpanded:isExpanded];

    if (isExpanded) {
        NSRect viewFrame;
        float newHeight;
        
        [self updateInspector]; // call this first because the view could change sizes based on the selection in -updateInspector

        viewFrame = [view frame];
        newHeight = NSHeight([headingButton frame]) + NSHeight(viewFrame);
        windowFrame = NSMakeRect(topLeftPoint.x, topLeftPoint.y - newHeight, NSWidth([headingButton frame]), newHeight);
        if (forceResizeWidget) {
            windowFrame.size.width = MAX(NSWidth(viewFrame), NSWidth(windowFrame));
        } else {
            windowFrame.size.width = MAX(desiredWidth, NSWidth(windowFrame));
        }  
        windowFrame = [self windowWillResizeFromFrame:[window frame] toFrame:windowFrame];
        
        if (forceResizeWidget) {
            viewFrame = NSMakeRect(0, 0, NSWidth(windowFrame), NSHeight(viewFrame));
        } else if (widthSizable) {
            viewFrame = NSMakeRect(0, 0, NSWidth(windowFrame), NSHeight(viewFrame));
        } else {
            if (NSWidth(viewFrame) > NSWidth(windowFrame))
                viewFrame.origin.x = 0;
            else
                viewFrame.origin.x = floor((NSWidth(windowFrame) - NSWidth(viewFrame)) / 2.0);
            viewFrame.origin.y = 0;
        }

        [view setFrame:viewFrame];
        [view setAutoresizingMask:NSViewNotSizable];
        [[window contentView] addSubview:view positioned:NSWindowBelow relativeTo:headingButton];
        [window setFrame:windowFrame display:YES animate:animate];
        if (forceResizeWidget || widthSizable || heightSizable) {
            if (!resizerView) {
                resizerView = [[OAInspectorResizer alloc] initWithFrame:NSMakeRect(0, 0, OAInspectorResizerWidth, OAInspectorResizerWidth)];
                [resizerView setAutoresizingMask:NSViewMinXMargin | NSViewMaxYMargin];
            }
            [resizerView setFrameOrigin:NSMakePoint(NSWidth(windowFrame) - OAInspectorResizerWidth, 0)];
            [[window contentView] addSubview:resizerView];
        }
        [view setAutoresizingMask:NSViewHeightSizable | (widthSizable ? NSViewWidthSizable : (NSViewMinXMargin | NSViewMaxXMargin))];
        [[[OAInspectorRegistry sharedInspector] workspaceDefaults] setObject:@"YES" forKey:[self identifier]];
    } else {
        NSRect headingFrame;
        
        [resizerView removeFromSuperview];
        [view setAutoresizingMask:NSViewNotSizable];
        windowFrame = [window frame];
        headingFrame.origin = NSMakePoint(0, isBottommostInGroup ? 0.0 : OAInspectorSpaceBetweenButtons);
        if (group == nil)
            headingFrame.size = [headingButton frame].size;
        else
            headingFrame.size = NSMakeSize([group desiredWidth], [headingButton frame].size.height);
        [window setFrame:NSMakeRect(topLeftPoint.x, topLeftPoint.y - NSMaxY(headingFrame), NSWidth(headingFrame), NSMaxY(headingFrame)) display:YES animate:animate];
        [view removeFromSuperview];
        [self inspectNothing];
        [[[OAInspectorRegistry sharedInspector] workspaceDefaults] removeObjectForKey:[self identifier]];
    }
    [[OAInspectorRegistry sharedInspector] defaultsDidChange];
    [window makeFirstResponder:window];
    [group setScreenChangesEnabled:YES];
    isToggling = NO; 
}

- (void)setNewPosition:(NSPoint)aPosition;
{
    newPosition = aPosition;
}

- (void)setCollapseOnTakeNewPosition:(BOOL)yn;
{
    collapseOnTakeNewPosition = yn;
}

- (float)heightAfterTakeNewPosition;
{
    if (collapseOnTakeNewPosition)
        return OAInspectorStartingHeaderButtonHeight + (isBottommostInGroup ? OAInspectorSpaceBetweenButtons : 0.0);
    else
        return NSHeight([window frame]);
}

- (void)takeNewPositionWithWidth:(float)aWidth;
{
    if (collapseOnTakeNewPosition) {
        [self toggleExpandednessWithNewTopLeftPoint:newPosition animate:NO];
    } else {
        NSRect frame = [window frame];
        
        frame.origin.x = newPosition.x;
        frame.origin.y = newPosition.y - frame.size.height;
        frame.size.width = aWidth;
        [window setFrame:frame display:YES];
        if (isExpanded && !isToggling && resizerView != nil)
            desiredWidth = aWidth;
    }
    collapseOnTakeNewPosition = NO;
}

- (void)loadInterface;
{
    if (!window)
        [self _buildWindow];

    if (([[[OAInspectorRegistry sharedInspector] workspaceDefaults] objectForKey:[self identifier]] != nil) != isExpanded) {
        NSRect windowFrame = [window frame];
        [self toggleExpandednessWithNewTopLeftPoint:NSMakePoint(NSMinX(windowFrame), NSMaxY(windowFrame)) animate:NO];
    }
}

- (void)displayWindow;
{
    [window orderFront:self];
}

- (void)updateInspector;
{
    NSArray *list;

    if (![group isVisible] || !isExpanded)
        return;
        
    list = [[OAInspectorRegistry sharedInspector] inspectedObjectsOfClass:[inspector inspectsClass]];
    NS_DURING {
        [inspector inspectObjects:list];
    } NS_HANDLER {
        [self inspectNothing];
    } NS_ENDHANDLER;
}

- (void)inspectNothing;
{
    NS_DURING {
        [inspector inspectObjects:nil];
    } NS_HANDLER {
    } NS_ENDHANDLER;
}

- (void)windowDidResignKey:(NSNotification *)notification;
{
    [window makeFirstResponder:window];
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)aWindow;
{
    NSWindow *mainWindow;
    NSResponder *nextResponder;
    NSUndoManager *undoManager = nil;

    mainWindow = [NSApp mainWindow];
    nextResponder = [mainWindow firstResponder];
    if (nextResponder == nil)
        nextResponder = mainWindow;

    do {
        if ([nextResponder respondsToSelector:@selector(undoManager)])
            undoManager = [nextResponder undoManager];
        else if ([nextResponder respondsToSelector:@selector(delegate)] && [[(id)nextResponder delegate] respondsToSelector:@selector(undoManager)])
            undoManager = [[(id)nextResponder delegate] undoManager];
        nextResponder = [nextResponder nextResponder];
    } while (nextResponder && !undoManager);
    
    return undoManager;
}

- (void)windowDidChangeScreen:(NSNotification *)aNotification;
{
    if ([group isHeadOfGroup:self] && [group screenChangesEnabled]) {
        NSScreen *screen = [window screen];
        NSRect groupRect = [group groupFrame];
        NSRect result, windowFrame;
        
        if (screen == nil) 
            screen = [NSScreen mainScreen];
        result = [group fitFrame:groupRect onScreen:screen];
        windowFrame = [window frame];
        
        result.origin.y = NSMaxY(result) - NSHeight(windowFrame);
        result.size.height = NSHeight(windowFrame);
        [window setFrame:result display:YES animate:NO];
    }
}

- (NSMutableDictionary *)debugDictionary;
{
    NSMutableDictionary *result = [super debugDictionary];
    
    
    [result setObject:[self identifier] forKey:@"identifier"];
    [result setObject:([window isVisible] ? @"YES" : @"NO") forKey:@"isVisible"];
    [result setObject:[window description] forKey:@"window"];
    if ([window childWindows])
        [result setObject:[[window childWindows] description] forKey:@"childWindows"];
    if ([window parentWindow])
        [result setObject:[[window parentWindow] description] forKey:@"parentWindow"];
    return result;
}

@end

@implementation OAInspectorController (Private)

- (void)toggleDisplayAction:sender;
{
    if (isExpanded && [group isVisible] && [group isBelowOverlappingGroup]) {
        [group orderFrontGroup]; 
        return;
    }

    if (!isExpanded && [group isVisible])
        [group orderFrontGroup];
    [self toggleDisplay];
}

- (void)_buildHeadingView;
{
    NSString *keyEquivalent;
    
    headingButton = [[OAInspectorHeaderView alloc] initWithFrame:NSZeroRect];
    [headingButton setTitle:[inspector inspectorName]];
    [headingButton setImage:[NSImage imageNamed:[inspector imageName]]];
    
    keyEquivalent = [inspector keyEquivalent];
    if ([keyEquivalent length]) {
        unsigned int mask = [inspector keyEquivalentModifierMask];
        NSString *fullString = [NSString commandKeyIndicatorString];

        if (mask & NSAlternateKeyMask)
            fullString = [[NSString alternateKeyIndicatorString] stringByAppendingString:fullString];
        if (mask & NSShiftKeyMask)
            fullString = [[NSString shiftKeyIndicatorString] stringByAppendingString:fullString];
        
        fullString = [fullString stringByAppendingString:[keyEquivalent uppercaseString]];
        [headingButton setKeyEquivalent:fullString];
    }
    [headingButton setFrame:NSMakeRect(0.0, OAInspectorSpaceBetweenButtons, [headingButton minimumWidth], OAInspectorStartingHeaderButtonHeight)];
    [headingButton setDelegate:self];
    [headingButton setAutoresizingMask:NSViewWidthSizable | NSViewMinYMargin];
}

- (void)_buildWindow;
{    
    [self _buildHeadingView];
    window = [[OAInspectorWindow alloc] initWithContentRect:NSMakeRect(500.0, 300.0, NSWidth([headingButton frame]), OAInspectorStartingHeaderButtonHeight + OAInspectorSpaceBetweenButtons) styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
    [window setDelegate:self];    
    [[window contentView] addSubview:headingButton];
}

- (NSView *)_inspectorView;
{
    NSView *inspectorView = [inspector inspectorView];
    
    if (!loadedInspectorView) {
        NSString *savedSize;

        forceResizeWidget = [inspector respondsToSelector:@selector(inspectorWillResizeToSize:)]; 
        heightSizable = [inspectorView autoresizingMask] & NSViewHeightSizable ? YES : NO;
        widthSizable = [inspectorView autoresizingMask] & NSViewWidthSizable ? YES : NO;
        if (forceResizeWidget) {
            minimumSize = NSZeroSize;
        } else if ([inspector respondsToSelector:@selector(inspectorMinimumSize)]) { 
            minimumSize = [inspector inspectorMinimumSize];
        } else {
            minimumSize = [inspectorView frame].size;
        }
        
        savedSize = [[[OAInspectorRegistry sharedInspector] workspaceDefaults] objectForKey:[NSString stringWithFormat:@"%@-Size", [self identifier]]];
        if (savedSize != nil)
            [inspectorView setFrameSize:NSSizeFromString(savedSize)];        
        desiredWidth = [inspectorView frame].size.width;
        loadedInspectorView = YES;
    }
    return inspectorView;
}

- (void)_saveInspectorSize;
{
    OAInspectorRegistry *registry = [OAInspectorRegistry sharedInspector];
    NSSize size = [[self _inspectorView] frame].size;
    
    desiredWidth = size.width;
    [[registry workspaceDefaults] setObject:NSStringFromSize(size) forKey:[NSString stringWithFormat:@"%@-Size", [self identifier]]];
    [registry defaultsDidChange];
}

- (NSRect)windowWillResizeFromFrame:(NSRect)fromRect toFrame:(NSRect)toRect;
{
    NSRect result;
    
    if ([group ignoreResizing])
        return toRect;
        
    if (isExpanded && !isToggling) {
        float groupMinimumWidth;
        
        if ([inspector respondsToSelector:@selector(inspectorMinimumSize)])
            minimumSize = [inspector inspectorMinimumSize];
        
        groupMinimumWidth = [group minimumWidth];
            
        if (NSWidth(toRect) < groupMinimumWidth)
            toRect.size.width = groupMinimumWidth;
        if (NSHeight(toRect) < minimumSize.height)
            toRect.size.height = minimumSize.height;
                
        if (!forceResizeWidget) {
            if (!widthSizable && NSWidth(toRect) > NSWidth(fromRect))
                toRect.size.width = NSWidth(fromRect);
    
            if (!heightSizable) {
                toRect.origin.y += NSHeight(fromRect) - NSHeight(toRect);
                toRect.size.height = NSHeight(fromRect);
            } 
        }
    }
    if (isExpanded && forceResizeWidget) {
        toRect.size.height -= OAInspectorStartingHeaderButtonHeight;
        toRect.size = [inspector inspectorWillResizeToSize:toRect.size];
        toRect.size.height += OAInspectorStartingHeaderButtonHeight;
    }
    
    if (group != nil)
        result = [group inspector:self willResizeToFrame:toRect isToggling:isToggling];
    else
        result = toRect;
    
    if (isExpanded && !isToggling && resizerView != nil)
        [self queueSelectorOnce:@selector(_saveInspectorSize)];
    return result;
}

// OAInspectorHeaderViewDelegateProtocol

- (BOOL)headerViewShouldDisplayCloseButton:(OAInspectorHeaderView *)view;
{
    return [group isHeadOfGroup:self];
}

- (float)headerViewDraggingHeight:(OAInspectorHeaderView *)view;
{
    return NSMaxY([window frame]) - [group groupFrame].origin.y;
}

- (void)headerViewDidBeginDragging:(OAInspectorHeaderView *)view;
{
    [group detachFromGroup:self];
}

- (NSRect)headerView:(OAInspectorHeaderView *)view willDragWindowToFrame:(NSRect)aFrame onScreen:(NSScreen *)screen;
{
    aFrame = [group fitFrame:aFrame onScreen:screen];
    aFrame = [group snapToOtherGroupWithFrame:aFrame];
    return aFrame;
}

- (void)headerViewDidEndDragging:(OAInspectorHeaderView *)view toFrame:(NSRect)aFrame;
{
    [[OAInspectorGroupAnimatedMergeController sharedInspectorGroupAnimatedMergeController] closeWindow];
    [group windowsDidMoveToFrame:aFrame];
}

- (void)headerViewDidToggleExpandedness:(OAInspectorHeaderView *)senderButton;
{
    if ([group canBeginResizingOperation]) {
        NSRect windowFrame = [window frame];
        [self toggleExpandednessWithNewTopLeftPoint:NSMakePoint(NSMinX(windowFrame), NSMaxY(windowFrame)) animate:YES];
    } else {
        // try again when the current resizing operation may be done
        [self performSelector:@selector(headerViewDidToggleExpandedness:) withObject:senderButton afterDelay:0.1];
    }
}

- (void)headerViewDidClose:(OAInspectorHeaderView *)view;
{
    [group hideGroup];
}

@end
