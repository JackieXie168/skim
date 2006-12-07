// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSMenu-OAExtensions.h,v 1.6 2003/01/15 22:51:37 kc Exp $

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

@end
