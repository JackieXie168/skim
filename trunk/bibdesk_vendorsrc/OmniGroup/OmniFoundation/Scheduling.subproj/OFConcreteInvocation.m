// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OFConcreteInvocation.h"

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/Scheduling.subproj/OFConcreteInvocation.m 68913 2005-10-03 19:36:19Z kc $")

#import <OmniFoundation/OFMessageQueuePriorityProtocol.h>

static void getSchedulingInfo(OFMessageQueueSchedulingInfo *returnValue, id target)
{
    if (returnValue->_private == 0) {
        if ([target respondsToSelector:@selector(messageQueueSchedulingInfo)]) {
            *returnValue = [(id <OFMessageQueuePriority>)target messageQueueSchedulingInfo];
            if (returnValue->maximumSimultaneousThreadsInGroup < 1)
                returnValue->maximumSimultaneousThreadsInGroup = 1;
        } else {
            *returnValue = OFMessageQueueSchedulingInfoDefault;
        }
        returnValue->_private = 1;
    }
}


@implementation OFConcreteInvocation

// Init and dealloc

+ alloc;
{
    // +[OFInvocation alloc] returns a temporary placeholder, so here we override +alloc to act normally again.

    return [self allocWithZone:NULL];
}

+ allocWithZone:(NSZone *)aZone;
{
    return NSAllocateObject(self, 0, aZone);
}

- initForObject:(id <NSObject>)targetObject;
{
    OBPRECONDITION(targetObject != nil); // since we are going to dereference it below

    [super init];
    object = [targetObject retain];
    
    return self;
}

- (void)dealloc;
{
    [object release];
    [super dealloc];
}

// API

- (void)setPriorityLevel:(unsigned short int)newPriorityLevel;
{
    getSchedulingInfo(&schedulingInfo, object);
    schedulingInfo.priority = newPriorityLevel;
}

// OFInvocation subclass

- (id <NSObject>)object;
{
    return object;
}

// OFMessageQueuePriority protocol

- (OFMessageQueueSchedulingInfo)messageQueueSchedulingInfo;
{
    getSchedulingInfo(&schedulingInfo, object);
    return schedulingInfo;
}

@end


#import "OFIObjectNSInvocation.h"
#import "OFIObjectSelector.h"
#import "OFIObjectSelectorBool.h"
#import "OFIObjectSelectorInt.h"
#import "OFIObjectSelectorIntInt.h"
#import "OFIObjectSelectorObject.h"
#import "OFIObjectSelectorObjectInt.h"
#import "OFIObjectSelectorObjectObject.h"
#import "OFIObjectSelectorObjectObjectObject.h"

@implementation OFInvocation (Inits)

- initForObject:(id <NSObject>)targetObject nsInvocation:(NSInvocation *)anInvocation;
{
    return [[OFIObjectNSInvocation alloc] initForObject:targetObject nsInvocation:anInvocation];
}

- initForObject:(id <NSObject>)targetObject selector:(SEL)aSelector;
{
    return [[OFIObjectSelector alloc] initForObject:targetObject selector:aSelector];
}

- initForObject:(id <NSObject>)targetObject selector:(SEL)aSelector withBool:(BOOL)aBool;
{
    return [[OFIObjectSelectorBool alloc] initForObject:targetObject selector:aSelector withBool:aBool];
}

- initForObject:(id <NSObject>)targetObject selector:(SEL)aSelector withInt:(int)anInt;
{
    return [[OFIObjectSelectorInt alloc] initForObject:targetObject selector:aSelector withInt:anInt];
}

- initForObject:(id <NSObject>)targetObject selector:(SEL)aSelector withInt:(int)anInt withInt:(int)anotherInt;
{
    return [[OFIObjectSelectorIntInt alloc] initForObject:targetObject selector:aSelector withInt:anInt withInt:anotherInt];
}

- initForObject:(id <NSObject>)targetObject selector:(SEL)aSelector withObject:(id <NSObject>)aWithObject;
{
    return [[OFIObjectSelectorObject alloc] initForObject:targetObject selector:aSelector withObject:aWithObject];
}

- initForObject:(id <NSObject>)targetObject selector:(SEL)aSelector withObject:(id <NSObject>)anObject withInt:(int)anInt;
{
    return [[OFIObjectSelectorObjectInt alloc] initForObject:targetObject selector:aSelector withObject:anObject withInt:anInt];
}

- initForObject:(id <NSObject>)targetObject selector:(SEL)aSelector withObject:(id <NSObject>)object1 withObject:(id <NSObject>)object2;
{
    return [[OFIObjectSelectorObjectObject alloc] initForObject:targetObject selector:aSelector withObject:object1 withObject:object2];
}

- initForObject:(id <NSObject>)targetObject selector:(SEL)aSelector withObject:(id <NSObject>)object1 withObject:(id <NSObject>)object2 withObject:(id <NSObject>)object3;
{
    return [[OFIObjectSelectorObjectObjectObject alloc] initForObject:targetObject selector:aSelector withObject:object1 withObject:object2 withObject:object3];
}

@end
