// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/Scheduling.subproj/OFQueueProcessor.h,v 1.14 2004/02/10 04:07:47 kc Exp $

#import <OmniFoundation/OFObject.h>
#import <OmniFoundation/FrameworkDefines.h>
#import <Foundation/NSDate.h>

@class NSLock;
@class OFInvocation, OFMessageQueue;

@interface OFQueueProcessor : OFObject
{
    OFMessageQueue *messageQueue;

    NSLock *currentInvocationLock;
    OFInvocation *currentInvocation;
}

- initForQueue:(OFMessageQueue *)aQueue;

- (void)processQueueUntilEmpty;
- (void)processQueueForever;
- (void)startProcessingQueueInNewThread;

- (void)processQueueUntilEmpty:(BOOL)onlyUntilEmpty forTime:(NSTimeInterval)maximumTime;

- (OFInvocation *)retainedCurrentInvocation;

@end

OmniFoundation_EXTERN BOOL OFQueueProcessorDebug;

