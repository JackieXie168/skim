// Copyright 2002-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "NSAppleEventDescriptor-OAExtensions.h"

#ifdef MAC_OS_X_VERSION_10_2

#import <Foundation/Foundation.h>
#import <OmniBase/rcsid.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSAppleEventDescriptor-OAExtensions.m 68913 2005-10-03 19:36:19Z kc $");

@implementation NSAppleEventDescriptor (OAExtensions)

+ (NSAppleEventDescriptor *)descriptorWithAEDescNoCopy:(const AEDesc *)aeDesc;
{
    return [[[self alloc] initWithAEDescNoCopy:aeDesc] autorelease];
}

@end

#endif
