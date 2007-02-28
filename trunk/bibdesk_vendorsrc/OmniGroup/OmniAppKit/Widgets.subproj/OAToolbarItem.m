// Copyright 2001-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OAToolbarItem.h"

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <OmniBase/rcsid.h>

#import "OAApplication.h"

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OAToolbarItem.m 68913 2005-10-03 19:36:19Z kc $");

@interface OAToolbarItem (Private)
- (void)_swapImage;
- (void)_swapLabel;
- (void)_swapToolTip;
- (void)_swapAction;
@end

@implementation OAToolbarItem

- (id)initWithItemIdentifier:(NSString *)itemIdentifier;
{
    if (!(self = [super initWithItemIdentifier:itemIdentifier]))
        return nil;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(modifierFlagsChanged:) name:OAFlagsChangedNotification object:nil];
    inOptionKeyState = NO;
    
    return self;
}

- (void)dealloc;
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:OAFlagsChangedNotification object:nil];
    [_optionKeyImage release];
    [_optionKeyLabel release];
    [_optionKeyToolTip release];

    [super dealloc];
}


// API

- (id)delegate;
{
    return _delegate;
}

- (void)setDelegate:(id)delegate;
{
    _delegate = delegate;
}

- (NSImage *)optionKeyImage;
{
    return _optionKeyImage;
}

- (void)setOptionKeyImage:(NSImage *)image;
{
    if (image == _optionKeyImage)
        return;

    [_optionKeyImage release];
    _optionKeyImage = [image retain];
}

- (NSString *)optionKeyLabel;
{
    return _optionKeyLabel;
}

- (void)setOptionKeyLabel:(NSString *)label;
{
    if (label == _optionKeyLabel)
        return;

    [_optionKeyLabel release];
    _optionKeyLabel = [label retain];
}

- (NSString *)optionKeyToolTip;
{
    return _optionKeyToolTip;
}

- (void)setOptionKeyToolTip:(NSString *)toolTip;
{
    if (toolTip == _optionKeyToolTip)
        return;

    [_optionKeyToolTip release];
    _optionKeyToolTip = [toolTip retain];
}

- (SEL)optionKeyAction;
{
    return _optionKeyAction;
}

- (void)setOptionKeyAction:(SEL)action;
{
    _optionKeyAction = action;
}

// NSToolbarItem subclass

- (void)validate;
{
    [super validate];
    if (_delegate)
        [self setEnabled:[_delegate validateToolbarItem:self]];
}

@end

@implementation OAToolbarItem (NotificationsDelegatesDatasources)

- (void)modifierFlagsChanged:(NSNotification *)note;
{
    BOOL optionDown = ([[note object] modifierFlags] & NSAlternateKeyMask) ? YES : NO;

    if (optionDown != inOptionKeyState) {
        if ([self optionKeyImage])
            [self _swapImage];
        if ([self optionKeyLabel])
            [self _swapLabel];
        if ([self optionKeyToolTip])
            [self _swapToolTip];
        if ([self optionKeyAction])
            [self _swapAction];
        inOptionKeyState = optionDown;
    } 
}

@end

@implementation OAToolbarItem (Private)

- (void)_swapImage;
{
    NSImage *image;

    image = [[self image] retain];
    [self setImage:[self optionKeyImage]];
    [self setOptionKeyImage:image];
    [image release];
}

- (void)_swapLabel;
{
    NSString *label;

    label = [[self label] retain];
    [self setLabel:[self optionKeyLabel]];
    [self setOptionKeyLabel:label];
    [label release];
}

- (void)_swapToolTip;
{
    NSString *toolTip;

    toolTip = [[self toolTip] retain];
    [self setToolTip:[self optionKeyToolTip]];
    [self setOptionKeyToolTip:toolTip];
    [toolTip release];
}

- (void)_swapAction;
{
    SEL action;

    action = [self action];
    [self setAction:[self optionKeyAction]];
    [self setOptionKeyAction:action];
}

@end



