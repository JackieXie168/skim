// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/NSHost-OFExtensions.h>

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>
#import <OmniBase/system.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSHost-OFExtensions.m,v 1.11 2004/02/10 04:07:45 kc Exp $")

@implementation NSHost (OFExtensions)

- (NSNumber *)addressNumber
{
    return [NSNumber numberWithUnsignedLong:inet_addr([[self address] cString])];
}

@end
