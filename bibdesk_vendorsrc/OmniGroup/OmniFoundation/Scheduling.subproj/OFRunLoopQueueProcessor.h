// Copyright 1998-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/SourceRelease_2005-10-03/OmniGroup/Frameworks/OmniFoundation/Scheduling.subproj/OFRunLoopQueueProcessor.h 68913 2005-10-03 19:36:19Z kc $

#import <OmniFoundation/OFQueueProcessor.h>

@class NSPort, NSPortMessage, NSArray;
@protocol OFMessageQueueDelegate;

#import <OmniFoundation/OFWeakRetainConcreteImplementation.h>

@interface OFRunLoopQueueProcessor : OFQueueProcessor <OFMessageQueueDelegate>
{
    NSPort *notificationPort;
    NSPortMessage *portMessage;
    unsigned int disableCount;

    OFWeakRetainConcreteImplementation_IVARS;
}

+ (NSArray *)mainThreadRunLoopModes;
+ (Class)mainThreadRunLoopProcessorClass;

+ (OFRunLoopQueueProcessor *)mainThreadProcessor;
+ (void)disableMainThreadQueueProcessing;
+ (void)reenableMainThreadQueueProcessing;

- (id)initForQueue:(OFMessageQueue *)aQueue;
- (void)runFromCurrentRunLoopInModes:(NSArray *)modes;
- (void)enable;
- (void)disable;

@end
