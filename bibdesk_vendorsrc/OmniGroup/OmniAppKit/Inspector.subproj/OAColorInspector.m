// Copyright 2002-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import "OAColorInspector.h"

#import <AppKit/AppKit.h>
#import <OmniBase/rcsid.h>
#import "OAInspectorController.h"
#import "OAInspectorWindow.h"
#import "NSToolbar-OAExtensions.h"
#import <OmniFoundation/OmniFoundation.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Inspector.subproj/OAColorInspector.m,v 1.16 2003/05/05 17:31:03 toon Exp $");

static OAInspectorController *colorController;
static NSView *colorPanelControls;
BOOL reportZeroForHeight;

@interface NSColorPanel (Hacks)
- (void)fixupResizability;
- (void)undoResizability;
- (NSView *)boxAboveSwatch;
- (NSSize)minColorPanelSize;
- (float)swatchHeight;
@end

@interface NSColorPanel (Hidden)
- (void)_dimpleDragStarted:(id)sender event:(NSEvent *)event;
@end

@implementation NSColorPanel (Hacks)

- (void)orderFront:sender;
{
    if (colorController != nil)
        [colorController showInspector];
    else
        [super orderFront:sender];
}

- (void)fixupResizability;
{
    reportZeroForHeight = YES;
    [_colorSwatch setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [_middleView setAutoresizingMask:NSViewWidthSizable | NSViewMinYMargin];
    [[self boxAboveSwatch] setAutoresizingMask:NSViewWidthSizable | NSViewMinYMargin];
}

- (void)undoResizability;
{
    reportZeroForHeight = NO;
    [_colorSwatch setAutoresizingMask:NSViewWidthSizable | NSViewMaxYMargin];
    [_middleView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [[self boxAboveSwatch] setAutoresizingMask:NSViewWidthSizable | NSViewMaxYMargin];
}

- (NSView *)boxAboveSwatch;
{
#ifdef MAC_OS_X_VERSION_10_2
    return _boxAboveSwatch;
#else
    return nil;
#endif
}

- (NSSize)minColorPanelSize;
{
    NSSize result = [self minSize]; 

    if (reportZeroForHeight) 
        result.height = 0.0;
    return result;
}

- (float)swatchHeight;
{
    return NSHeight([_colorSwatch frame]);
}

@end


@implementation OAInspectorWindow (Hack)
- (void)_dimpleDragStarted:(id)sender event:(NSEvent *)event;
{
    NSRect windowFrame = [self frame];
    NSColorPanel *colorPanel = [NSColorPanel sharedColorPanel];
    NSSize startingMinSize = [colorPanel minSize];
    float startingWindowTop = NSMaxY(windowFrame);
    float startingWindowHeight = NSHeight(windowFrame);
    float startingMouseY = [self convertBaseToScreen:[event locationInWindow]].y;
    float minimumChange = - [colorPanel swatchHeight];
    float change = 0.0;
    
    [[NSColorPanel sharedColorPanel] fixupResizability];
    while (1) {        
        event = [NSApp nextEventMatchingMask:NSLeftMouseDraggedMask|NSLeftMouseUpMask untilDate:[NSDate distantFuture] inMode:NSEventTrackingRunLoopMode dequeue:NO];

        if ([event type] == NSLeftMouseUp)
            break;
           
        [NSApp nextEventMatchingMask:NSLeftMouseDraggedMask untilDate:[NSDate distantFuture] inMode:NSEventTrackingRunLoopMode dequeue:YES];
        change = startingMouseY - [self convertBaseToScreen:[event locationInWindow]].y;
        change = MAX(minimumChange, change);
        windowFrame.size.height = startingWindowHeight + change;
        windowFrame.origin.y = startingWindowTop - windowFrame.size.height;
        [self setFrame:windowFrame display:YES animate:NO];
        
        [colorPanel setContentSize:[colorPanelControls frame].size];
    }
    [colorPanel undoResizability];
    // -32.0 why? the color panel does something odd with that call
    [colorPanel setMinSize:NSMakeSize(startingMinSize.width, startingMinSize.height + change - 32.0)];
}
@end


@interface OAColorInspector (Private)
@end

@implementation OAColorInspector

// So it turns out that if the color panel mode is 1-4, the color panel is created with the slider picker, which has a popup on it that grabs cmd-1 through cmd-4. We want those key equivalents for ourselves, so we need to keep the color panel from stealing them. The easiest (only?) way to do that is to make sure some other picker comes up first so we have a chance to use cmd-1 through cmd-4 in the menu bar. Mode 6 is the color wheel.
- init;
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    int currentMode = [defaults integerForKey:@"NSColorPanelMode"];
    
    [super init];
    
    if (currentMode >= 1 && currentMode <= 4)
        [defaults setInteger:6 forKey:@"NSColorPanelMode"];
    [defaults synchronize];
    return self;
}

- (NSString *)inspectorName;
{
    return NSLocalizedStringFromTableInBundle(@"Color", @"OmniAppKit", [OAColorInspector bundle], "window and menu title for Color inspector");
}

- (void)setInspectorController:(OAInspectorController *)aController;
{
    colorController = aController;
}

/*
- (NSSize)inspectorWillResizeToSize:(NSSize)aSize;
{
    NSColorPanel *panel = [NSColorPanel sharedColorPanel];
    
    aSize.height -= [[[panel toolbar] toolbarView] frame].size.height;
    
    if (aSize.width < minimumContentSize.width)
        aSize.width = minimumContentSize.width;
    if (aSize.height < minimumContentSize.height)
        aSize.height = minimumContentSize.height;
        
    aSize = [panel windowWillResize:panel toSize:aSize];
    [panel setFrame:NSMakeRect(0, 0, aSize.width, aSize.height) display:YES];
    return aSize;
}
*/

- (NSSize)inspectorMinimumSize;
{
    return [[NSColorPanel sharedColorPanel] minColorPanelSize];
}

- (void)contentsFrameDidChange:(NSNotification *)notification;
{
    if (!nestedResize) {
        NSView *interior = [notification object];
    
        nestedResize = YES;
        [[NSColorPanel sharedColorPanel] setContentSize:[interior frame].size];
        nestedResize = NO;
    }
}

// The NSColorPanel resized itself
- (void)windowDidResize:(NSNotification *)notification;
{
    if (!nestedResize) {
        NSColorPanel *colorPanel = [notification object];
        NSWindow *inspectorWindow = [colorController window];
        NSView *toolbar = [[[NSColorPanel sharedColorPanel] toolbar] toolbarView];        
        NSRect contentRect = [NSWindow contentRectForFrameRect:[colorPanel frame] styleMask:[colorPanel styleMask]];
        NSRect inspectorFrame = [inspectorWindow frame];
        
        contentRect.size.height += [toolbar frame].size.height;
        nestedResize = YES;
        [colorPanel undoResizability];
        [inspectorWindow setFrame:NSMakeRect(NSMinX(inspectorFrame), NSMaxY(inspectorFrame) - NSHeight(contentRect), NSWidth(contentRect), NSHeight(contentRect)) display:YES animate:NO];
        nestedResize = NO;
    }
}



- (NSView *)inspectorView;
{
    if (!contentView) {
        NSColorPanel *panel = [NSColorPanel sharedColorPanel];
        NSView *contents = [panel contentView];
        NSRect contentsRect = [contents frame];
        NSView *toolbar = [[panel toolbar] toolbarView];
        NSRect toolbarRect = [toolbar frame];
        
        [panel setFrameOrigin:NSZeroPoint];
        colorPanelControls = contents;
//        [panel fixupResizability];
        
        [panel setDelegate:self];
        [panel setContentView:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contentsFrameDidChange:) name:NSViewFrameDidChangeNotification object:contents];      
        contentView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, NSWidth(contentsRect), NSHeight(contentsRect) + NSHeight(toolbarRect))];
                
        [contents setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        [contentView addSubview:contents];
        [toolbar setFrame:NSMakeRect(0, NSHeight(contentsRect), NSWidth(contentsRect), NSHeight(toolbarRect))];
        [toolbar setAutoresizingMask:NSViewWidthSizable | NSViewMinYMargin];
        [contentView addSubview:toolbar];
        
        toolbarRect.origin = NSZeroPoint;
        toolbarRect.size = [panel minSize];
        minimumContentSize = [NSWindow contentRectForFrameRect:toolbarRect styleMask:[panel styleMask]].size;
        
        [contentView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    }
    return contentView;
}
    
- (unsigned int)defaultDisplayGroupNumber;
{
    return 98;
}

- (unsigned int)defaultDisplayOrderInGroup;
{
    return 0;
}

- (BOOL)defaultGroupVisibility;
{
    return NO;
}

- (NSString *)keyEquivalent;
{
    return @"C";
}

- (unsigned int)keyEquivalentModifierMask;
{
    return NSCommandKeyMask | NSShiftKeyMask;
}

- (NSString *)imageName;
{
    return @"Colors";
}

- (void)inspectObjects:(NSArray *)list;
{
}

- (Class)inspectsClass;
{
    return [NSObject class];
}

@end

@implementation OAColorInspector (Private)
@end
