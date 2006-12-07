// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import <OmniFoundation/NSHost-OFExtensions.h>

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>
#import <OmniBase/system.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSHost-OFExtensions.m,v 1.9 2003/01/15 22:52:00 kc Exp $")

@implementation NSHost (OFExtensions)

- (NSNumber *)addressNumber
{
    return [NSNumber numberWithUnsignedLong:inet_addr([[self address] cString])];
}

@end
