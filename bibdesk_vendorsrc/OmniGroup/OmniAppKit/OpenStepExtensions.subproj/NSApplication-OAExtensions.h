// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSApplication-OAExtensions.h,v 1.9 2003/01/15 22:51:35 kc Exp $

#import <AppKit/NSApplication.h>

@interface NSApplication (OAExtensions)
- (BOOL)useColor;
- (NSEvent *) peekEvent;
@end
