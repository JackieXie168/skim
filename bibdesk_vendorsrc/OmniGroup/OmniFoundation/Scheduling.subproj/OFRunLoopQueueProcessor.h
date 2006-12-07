// Copyright 1998-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/Scheduling.subproj/OFRunLoopQueueProcessor.h,v 1.9 2003/01/15 22:52:03 kc Exp $

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
