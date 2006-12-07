// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/Scheduling.subproj/OFQueueProcessor.h,v 1.11 2003/01/15 22:52:03 kc Exp $

#import <OmniFoundation/OFObject.h>
#import <OmniFoundation/FrameworkDefines.h>

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

- (OFInvocation *)retainedCurrentInvocation;

@end

OmniFoundation_EXTERN BOOL OFQueueProcessorDebug;

