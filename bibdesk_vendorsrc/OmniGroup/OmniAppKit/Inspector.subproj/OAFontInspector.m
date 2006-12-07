// Copyright 2002-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OAFontInspector.h"

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <OmniBase/rcsid.h>
#import "OAInspectorController.h"
#import <OmniFoundation/OmniFoundation.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Inspector.subproj/OAFontInspector.m,v 1.19 2004/02/10 04:07:32 kc Exp $");

@interface OAFontInspector (Private)
@end

static OAInspectorController *fontController;

@interface NSFontPanel (Hacks)
- (NSView *)_mainBox;
@end

@implementation NSFontPanel (Hacks)
- (void)orderFront:sender;
{
    if (fontController != nil)
        [fontController showInspector];
    else
        [super orderFront:sender];
}

- (NSView *)_mainBox;
{
    NSView *contentView = [self contentView];
    NSView *replacement;
    NSArray *subviews = [contentView subviews];
    int index = [subviews count];
    
    while (index--) {
        NSView *view = [subviews objectAtIndex:index];
        if ([view isKindOfClass:[NSBox class]] && NSHeight([view frame]) > 10.0)
            return view;
    }
    
    [contentView retain];
    replacement = [[NSView alloc] initWithFrame:[contentView frame]];
    [self setContentView:replacement];
    [replacement release];
    return [contentView autorelease];
}
@end

@implementation OAFontInspector

+ (OAInspectorController *)inspectorController;
{
    return fontController;
}

- (NSString *)inspectorName;
{
    return NSLocalizedStringFromTableInBundle(@"Font", @"OmniAppKit", [OAFontInspector bundle], "window and menu title for Font inspector");
}

- (void)windowDidResize:(NSNotification *)notification;
{
    NSFontPanel *panel = [NSFontPanel sharedFontPanel];
    NSSize size = [contentView frame].size;
    
    size.height += styleHeight;
    [panel setFrame:NSMakeRect(0, 0, size.width, size.height) display:YES];
}

- (void)setInspectorController:(OAInspectorController *)aController;
{
    fontController = aController;
}

- (NSSize)inspectorWillResizeToSize:(NSSize)aSize;
{
    NSFontPanel *panel = [NSFontPanel sharedFontPanel];
    
    if (aSize.width < minimumContentSize.width)
        aSize.width = minimumContentSize.width;
    if (aSize.height < minimumContentSize.height)
        aSize.height = minimumContentSize.height;
    
    aSize.height += styleHeight;
    aSize = [panel windowWillResize:panel toSize:aSize];
    aSize.height -= styleHeight;
    return aSize;
}

- (NSView *)inspectorView;
{
    if (!contentView) {
        NSFontPanel *panel = [NSFontPanel sharedFontPanel];
        NSRect minFrame;
        
        contentView = [[panel _mainBox] retain];
        [contentView setAutoresizingMask:NSViewHeightSizable | NSViewWidthSizable];

        minFrame.origin = NSZeroPoint;
        minFrame.size = [panel minSize];
        minimumContentSize = [NSWindow contentRectForFrameRect:minFrame styleMask:[panel styleMask]].size;
        styleHeight = minFrame.size.height - minimumContentSize.height;

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidResize:) name:NSWindowDidResizeNotification object:[fontController window]];
    }
    return contentView;
}
    
- (unsigned int)defaultDisplayGroupNumber;
{
    return 99;
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
    return @"t";
}

- (unsigned int)keyEquivalentModifierMask;
{
    return NSCommandKeyMask;
}

- (NSString *)imageName;
{
    return @"OAFontInspector";
}

- (void)inspectObjects:(NSArray *)list;
{
}

- (Class)inspectsClass;
{
    return [NSObject class];
}

@end

@implementation OAFontInspector (Private)
@end
