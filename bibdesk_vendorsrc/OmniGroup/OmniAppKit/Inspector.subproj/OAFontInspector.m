// Copyright 2002-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import "OAFontInspector.h"

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <OmniBase/rcsid.h>
#import "OAInspectorController.h"
#import <OmniFoundation/OmniFoundation.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Inspector.subproj/OAFontInspector.m,v 1.10 2003/05/05 17:31:03 toon Exp $");

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
    return _mainBox;
}
@end

@implementation OAFontInspector

- (NSString *)inspectorName;
{
    return NSLocalizedStringFromTableInBundle(@"Font", @"OmniAppKit", [OAFontInspector bundle], "window and menu title for Font inspector");
}

- (void)setInspectorController:(OAInspectorController *)aController;
{
    fontController = aController;
}

- (NSSize)inspectorWillResizeToSize:(NSSize)aSize;
{
    NSFontPanel *panel = [[NSFontManager sharedFontManager] fontPanel:YES];
    
    if (aSize.width < minimumContentSize.width)
        aSize.width = minimumContentSize.width;
    if (aSize.height < minimumContentSize.height)
        aSize.height = minimumContentSize.height;
    
    aSize.height += styleHeight;
    aSize = [panel windowWillResize:panel toSize:aSize];
    [panel setFrame:NSMakeRect(0, 0, aSize.width, aSize.height) display:YES];
    aSize.height -= styleHeight;
    return aSize;
}

- (NSView *)inspectorView;
{
    if (!contentView) {
        NSFontPanel *panel = [[NSFontManager sharedFontManager] fontPanel:YES];
        NSRect minFrame;
        
        contentView = [[panel _mainBox] retain];
        [contentView setAutoresizingMask:NSViewHeightSizable | NSViewWidthSizable];

        minFrame.origin = NSZeroPoint;
        minFrame.size = [panel minSize];
        minimumContentSize = [NSWindow contentRectForFrameRect:minFrame styleMask:[panel styleMask]].size;
        styleHeight = minFrame.size.height - minimumContentSize.height;
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
    return @"Font";
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
