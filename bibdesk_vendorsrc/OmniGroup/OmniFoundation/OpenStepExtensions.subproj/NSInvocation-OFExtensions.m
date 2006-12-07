// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/NSInvocation-OFExtensions.h>

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

// This is not included in OmniBase.h since system.h shouldn't be used except when covering OS specific behaviour
#import <OmniBase/system.h>
#import <objc/Protocol.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSInvocation-OFExtensions.m 68913 2005-10-03 19:36:19Z kc $")

@implementation NSInvocation (OFExtensions)

- (BOOL)isDefinedByProtocol:(Protocol *)aProtocol
{
    SEL invocationSelector;

    invocationSelector = [self selector];
    if ([aProtocol descriptionForInstanceMethod:invocationSelector])
        return YES;
    else
        return NO;
}

@end
