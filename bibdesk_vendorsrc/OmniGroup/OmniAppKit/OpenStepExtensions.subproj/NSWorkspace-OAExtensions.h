// Copyright 2003-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSWorkspace-OAExtensions.h,v 1.3 2004/02/10 04:07:35 kc Exp $

#import <AppKit/NSWorkspace.h>

@interface NSWorkspace (OAExtensions)

- (NSString *)fullPathForApplicationWithIdentifier:(NSString *)bundleIdentifier;
// convenience cover for LaunchServices API. Use this instead of -fullPathForApplication: -- not only is it more accurate, it avoids the problem of -fullPathForApplication: being implemented as a deep slow filesystem search on 10.1.

@end
