// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSPopUpButton-OAExtensions.h,v 1.10 2003/01/15 22:51:38 kc Exp $

#import <AppKit/NSPopUpButton.h>

@interface NSPopUpButton (OAExtensions)
- (void)selectItemWithTag:(int)tag;
- (id <NSMenuItem>)itemWithTag:(int)tag;
- (void)addRepresentedObjects:(NSArray *)objects titleSelector:(SEL)titleSelector;
- (void)addRepresentedObjects:(NSArray *)objects titleKeyPath:(NSString *)keyPath;
@end
