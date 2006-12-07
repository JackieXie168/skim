// Copyright 2002-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import "NSAppleEventDescriptor-OAExtensions.h"

#ifdef MAC_OS_X_VERSION_10_2

#import <Foundation/Foundation.h>
#import <OmniBase/rcsid.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSAppleEventDescriptor-OAExtensions.m,v 1.3 2003/03/24 23:06:54 neo Exp $");

@implementation NSAppleEventDescriptor (OAExtensions)

+ (NSAppleEventDescriptor *)descriptorWithAEDescNoCopy:(const AEDesc *)aeDesc;
{
    return [[[self alloc] initWithAEDescNoCopy:aeDesc] autorelease];
}

@end

#endif
