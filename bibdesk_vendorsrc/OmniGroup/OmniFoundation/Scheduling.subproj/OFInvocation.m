// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/OFInvocation.h>

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

#import "OFTemporaryPlaceholderInvocation.h"

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/Scheduling.subproj/OFInvocation.m,v 1.16 2004/02/10 04:07:47 kc Exp $")

@implementation OFInvocation

OFTemporaryPlaceholderInvocation *temporaryPlaceholderInvocation;

+ (void)initialize;
{
    OBINITIALIZE;
    temporaryPlaceholderInvocation = [OFTemporaryPlaceholderInvocation alloc];
}


+ alloc;
{
    return temporaryPlaceholderInvocation;
}

+ allocWithZone:(NSZone *)aZone;
{
    // If I really cared about zones, I'd return a different placeholder for each zone.
    return temporaryPlaceholderInvocation;
}

- (id <NSObject>)object;
{
    return nil;
}

- (SEL)selector;
{
    OBRequestConcreteImplementation(self, _cmd);
    return (SEL)0;
}

- (void)invoke;
{
    OBRequestConcreteImplementation(self, _cmd);
}

// OFMessageQueuePriority protocol

- (unsigned int)priority;
{
    OBRequestConcreteImplementation(self, _cmd);
    return 0;
}

- (unsigned int)group;
{
    OBRequestConcreteImplementation(self, _cmd);
    return 0;
}

- (unsigned int)maximumSimultaneousThreadsInGroup;
{
    OBRequestConcreteImplementation(self, _cmd);
    return 0;
}

@end
