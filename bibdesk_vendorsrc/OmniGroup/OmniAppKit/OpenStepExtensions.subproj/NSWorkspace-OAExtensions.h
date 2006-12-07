// Copyright 2003-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSWorkspace-OAExtensions.h 68913 2005-10-03 19:36:19Z kc $

#import <AppKit/NSWorkspace.h>

@interface NSWorkspace (OAExtensions)

- (NSString *)fullPathForApplicationWithIdentifier:(NSString *)bundleIdentifier;
// convenience cover for LaunchServices API. Use this instead of -fullPathForApplication: -- not only is it more accurate, it avoids the problem of -fullPathForApplication: being implemented as a deep slow filesystem search on 10.1.

@end
