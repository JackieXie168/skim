// Copyright 1998-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/Scheduling.subproj/OFRunLoopQueueProcessor.h,v 1.11 2004/02/10 04:07:47 kc Exp $

#import <OmniFoundation/OFQueueProcessor.h>
#import <OmniFoundation/OFMessageQueueDelegateProtocol.h>

@class NSPort, NSPortMessage, NSArray;

@interface OFRunLoopQueueProcessor : OFQueueProcessor <OFMessageQueueDelegate>
{
    NSPort *notificationPort;
    NSPortMessage *portMessage;
    unsigned int disableCount;
}

+ (NSArray *) mainThreadRunLoopModes;
+ (Class) mainThreadRunLoopProcessorClass;

+ (OFRunLoopQueueProcessor *) mainThreadProcessor;
+ (void) disableMainThreadQueueProcessing;
+ (void) reenableMainThreadQueueProcessing;

- initForQueue:(OFMessageQueue *)aQueue;
- (void)runFromCurrentRunLoopInModes:(NSArray *)modes;
- (void)enable;
- (void)disable;

@end
