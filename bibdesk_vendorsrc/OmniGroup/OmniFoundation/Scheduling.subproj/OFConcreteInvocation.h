// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/Scheduling.subproj/OFConcreteInvocation.h,v 1.16 2004/02/10 04:07:46 kc Exp $

#import <OmniFoundation/OFInvocation.h>

@interface OFConcreteInvocation : OFInvocation
{
    id <NSObject> object;
    OFInvocationPriorityLevel priorityLevel;
    struct {
        unsigned int objectRespondsToPriority:1;
        unsigned int objectRespondsToGroup:1;
        unsigned int objectRespondsToMaximumSimultaneousThreadsInGroup:1;
    } flags;
}

- initForObject:(id <NSObject>)targetObject;

- (void)setPriorityLevel:(OFInvocationPriorityLevel)newPriorityLevel;

@end
