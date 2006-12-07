// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/Scheduling.subproj/OFInvocation.h,v 1.14 2003/01/15 22:52:03 kc Exp $

#import <OmniFoundation/OFObject.h>

#import <OmniFoundation/OFMessageQueuePriorityProtocol.h>

typedef enum {
    OFHighPriority = 100, OFMediumPriority = 800, OFLowPriority = 1600,
} OFInvocationPriorityLevel;

#define OFInvocationNoGroup 0

@interface OFInvocation : OFObject <OFMessageQueuePriority>

- (id <NSObject>)object;
- (void)invoke;

@end

@interface OFInvocation (Inits)
- initForObject:(id <NSObject>)targetObject nsInvocation:(NSInvocation *)anInvocation;
- initForObject:(id <NSObject>)targetObject selector:(SEL)aSelector;
- initForObject:(id <NSObject>)targetObject selector:(SEL)aSelector withBool:(BOOL)aBool;
- initForObject:(id <NSObject>)targetObject selector:(SEL)aSelector withInt:(int)int1;
- initForObject:(id <NSObject>)targetObject selector:(SEL)aSelector withInt:(int)int1 withInt:(int)int2;
- initForObject:(id <NSObject>)targetObject selector:(SEL)aSelector withObject:(id <NSObject>)anObject;
- initForObject:(id <NSObject>)targetObject selector:(SEL)aSelector withObject:(id <NSObject>)object1 withObject:(id <NSObject>)object2;
- initForObject:(id <NSObject>)targetObject selector:(SEL)aSelector withObject:(id <NSObject>)object1 withObject:(id <NSObject>)object2 withObject:(id <NSObject>)object3;
@end
