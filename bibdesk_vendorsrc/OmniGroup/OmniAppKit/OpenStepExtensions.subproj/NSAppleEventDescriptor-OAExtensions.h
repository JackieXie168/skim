// Copyright 2002-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSAppleEventDescriptor-OAExtensions.h,v 1.3 2003/03/24 23:06:54 neo Exp $

#import <Foundation/NSAppleEventDescriptor.h>

#ifdef MAC_OS_X_VERSION_10_2

@interface NSAppleEventDescriptor (OAExtensions)

// Why Apple dodn't write this convenience method, I don't know.
+ (NSAppleEventDescriptor *)descriptorWithAEDescNoCopy:(const AEDesc *)aeDesc;

@end

#endif
