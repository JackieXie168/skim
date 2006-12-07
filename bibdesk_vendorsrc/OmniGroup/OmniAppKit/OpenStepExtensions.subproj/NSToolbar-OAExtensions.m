// Copyright 2001-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "NSToolbar-OAExtensions.h"

#import <Cocoa/Cocoa.h>
#import <OmniFoundation/OmniFoundation.h>
#import <OmniBase/rcsid.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSToolbar-OAExtensions.m 66043 2005-07-25 21:17:05Z kc $");

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

- (unsigned int)indexOfFirstItemWithIdentifier:(NSString *)identifier;
{
    NSArray *items = [self items];
    unsigned int itemIndex, itemCount = [items count];

    for (itemIndex = 0; itemIndex < itemCount; itemIndex++) {
        NSToolbarItem *item = [items objectAtIndex:itemIndex];
        NSString *itemIdentifier = [item itemIdentifier];
        if (OFISEQUAL(itemIdentifier, identifier))
            return itemIndex;
    }

    return NSNotFound;
}

@end
