// Copyright 2001-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "NSToolbar-OAExtensions.h"

#import <Foundation/Foundation.h>
#import <OmniBase/rcsid.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSToolbar-OAExtensions.m,v 1.8 2004/02/10 04:07:35 kc Exp $");

@implementation NSToolbar (OAExtensions)

- (NSWindow *)window;
{
    return _window;
}

- (NSView *)toolbarView;
{
    return _toolbarView;
}

- (BOOL)alwaysCustomizableByDrag;
{
    return _tbFlags.clickAndDragPerformsCustomization;
}

- (void)setAlwaysCustomizableByDrag:(BOOL)flag;
{
    _tbFlags.clickAndDragPerformsCustomization = (unsigned int)flag;
}

- (BOOL)showsContextMenu;
{
    return !_tbFlags.showsNoContextMenu;
}

- (void)setShowsContextMenu:(BOOL)flag;
{
    _tbFlags.showsNoContextMenu = (unsigned int)!flag;
}
    
- (unsigned int)indexOfFirstMovableItem;
{
    return _tbFlags.firstMoveableItemIndex;
}

- (void)setIndexOfFirstMovableItem:(unsigned int)anIndex;
{
    if (anIndex <= [[self items] count])
        _tbFlags.firstMoveableItemIndex = anIndex;
}

@end
