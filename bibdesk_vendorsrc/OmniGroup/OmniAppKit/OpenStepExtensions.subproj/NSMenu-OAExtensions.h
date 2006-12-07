// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSMenu-OAExtensions.h,v 1.9 2004/02/10 04:07:34 kc Exp $

#import <AppKit/NSMenu.h>

@class NSScreen;

typedef enum _OAContextMenuLayout {
    OAAutodetectContextMenuLayout,
    OAWideContextMenuLayout,
    OASmallContextMenuLayout,

    OAContextMenuLayoutCount,
} OAContextMenuLayout;

@interface NSMenu (OAExtensions)

+ (OAContextMenuLayout) contextMenuLayoutDefaultValue;
+ (void) setContextMenuLayoutDefaultValue: (OAContextMenuLayout) newValue;

+ (OAContextMenuLayout) contextMenuLayoutForScreen: (NSScreen *) screen;
+ (NSString *) lengthAdjustedContextMenuLabel: (NSString *) label layout: (OAContextMenuLayout) layout;

- (void) removeAllItems;
- (NSMenuItem *)itemWithAction:(SEL)action;

@end
