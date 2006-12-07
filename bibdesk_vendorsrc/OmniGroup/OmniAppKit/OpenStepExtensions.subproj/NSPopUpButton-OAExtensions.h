// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSPopUpButton-OAExtensions.h 66348 2005-08-01 23:54:36Z bungi $

#import <AppKit/NSPopUpButton.h>

@interface NSPopUpButton (OAExtensions)
#if !defined(MAC_OS_X_VERSION_10_4) || (MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_4)
- (BOOL)selectItemWithTag:(int)tag;
#endif
- (void)selectItemWithRepresentedObject:(id)object;
- (id <NSMenuItem>)itemWithTag:(int)tag;
- (void)addRepresentedObjects:(NSArray *)objects titleSelector:(SEL)titleSelector;
- (void)addRepresentedObjects:(NSArray *)objects titleKeyPath:(NSString *)keyPath;
@end
