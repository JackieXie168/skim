// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import <OmniFoundation/OFInvocation.h>

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

#import "OFTemporaryPlaceholderInvocation.h"

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/Scheduling.subproj/OFInvocation.m,v 1.11 2003/01/15 22:52:03 kc Exp $")

@implementation OFInvocation

OFTemporaryPlaceholderInvocation *temporaryPlaceholderInvocation;

+ (void)initialize;
{
    static BOOL initialized = NO;

    [super initialize];
    if (initialized)
	return;
    initialized = YES;

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

- (void)invoke;
{
}

// OFMessageQueuePriority protocol

- (unsigned int)priority;
{
    return 0;
}

- (unsigned int)group;
{
    return 0;
}

- (unsigned int)maximumSimultaneousThreadsInGroup;
{
    return 0;
}

@end
