// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSProcessInfo-OFExtensions.h,v 1.7 2003/01/15 22:52:00 kc Exp $

#import <Foundation/NSProcessInfo.h>

@class NSNumber;

@interface NSProcessInfo (OFExtensions)

- (NSNumber *)processNumber;
    // Returns a number uniquely identifying the current process among those running on the same host.  Assumes that this number can be described in a short.  While this may or may not be true on a particular system, it is generally true.

@end
