// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/Scheduling.subproj/OFScheduledEvent.h,v 1.11 2003/01/15 22:52:03 kc Exp $

#import <OmniFoundation/OFObject.h>

@class NSDate;
@class OFInvocation;

@interface OFScheduledEvent : OFObject
{
    OFInvocation *invocation;
    NSDate *date;
    BOOL fireOnTermination;
}

- initWithInvocation:(OFInvocation *)anInvocation atDate:(NSDate *)aDate;
- initWithInvocation:(OFInvocation *)anInvocation atDate:(NSDate *)aDate fireOnTermination:(BOOL)shouldFireOnTermination;
- initForObject:(id)anObject selector:(SEL)aSelector withObject:(id)aWithObject atDate:(NSDate *)date;

- (OFInvocation *)invocation;
- (NSDate *)date;
- (BOOL)fireOnTermination;

- (void)invoke;

- (NSComparisonResult)compare:(id)otherEvent;
- (unsigned int)hash;
- (BOOL)isEqual:(id)anObject;

@end
