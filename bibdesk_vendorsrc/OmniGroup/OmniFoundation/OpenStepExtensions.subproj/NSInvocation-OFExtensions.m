// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
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

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSInvocation-OFExtensions.m,v 1.11 2004/02/10 04:07:45 kc Exp $")

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
