// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import <OmniFoundation/OFQueueProcessor.h>

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

#import <OmniFoundation/NSThread-OFExtensions.h>
#import <OmniFoundation/OFInvocation.h>
#import <OmniFoundation/OFMessageQueue.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/Scheduling.subproj/OFQueueProcessor.m,v 1.20 2003/01/15 22:52:03 kc Exp $")

@interface OFQueueProcessor (Private)
- (BOOL)shouldProcessQueueEnd;
- (void)processQueueInThread;
@end

BOOL OFQueueProcessorDebug = NO;

@implementation OFQueueProcessor

static NSConditionLock *detachThreadLock;
static OFQueueProcessor *detachingQueueProcessor;

+ (void)initialize;
{
    OBINITIALIZE;

    detachThreadLock = [[NSConditionLock alloc] init];
    detachingQueueProcessor = nil;

    // This will trigger +[NSPort initialize], which registers for the NSBecomingMultiThreaded notification and avoids a race condition between NSThread and NSPort.
    [NSPort class];
}

- initForQueue:(OFMessageQueue *)aQueue;
{
    if (![super init])
	return nil;

    messageQueue = [aQueue retain];
    currentInvocationLock = [[NSLock alloc] init];

    return self;
}

- (void)dealloc;
{
    [messageQueue release];
    [currentInvocationLock release];
    [super dealloc];
}

- (void)processQueueUntilEmpty:(BOOL)onlyUntilEmpty;
{
    OFInvocation *retainedInvocation;
    BOOL waitForMessages = !onlyUntilEmpty;
#ifdef DEBUG
    BOOL setThreadNames = !onlyUntilEmpty;
#else
    BOOL setThreadNames = NO;
#endif
    NSAutoreleasePool *autoreleasePool;
    NSTimeInterval startingInterval, now;
    
    startingInterval = [NSDate timeIntervalSinceReferenceDate];
    autoreleasePool = [[NSAutoreleasePool alloc] init];
    
    if (detachingQueueProcessor == self) {
        detachingQueueProcessor = nil;
        [detachThreadLock lock];
        [detachThreadLock unlockWithCondition: 0];
    }

    if (OFQueueProcessorDebug)
        NSLog(@"%@: processQueueUntilEmpty: %d", [self shortDescription], onlyUntilEmpty);
        
    // This should be #ifndef PRODUCTION_BUILD, except we don't have a symbol for that right now.
    if (setThreadNames)
        [[NSThread currentThread] setName:@"(new queue)"];
    
    while ((retainedInvocation = [messageQueue nextRetainedInvocationWithBlock:waitForMessages])) {
        [currentInvocationLock lock];
        currentInvocation = retainedInvocation;
        [currentInvocationLock unlock];
        
        // This should be #ifndef PRODUCTION_BUILD, except we don't have a symbol for that right now.
        if (setThreadNames)
            [[NSThread currentThread] setName:[retainedInvocation shortDescription]];

        if (OFQueueProcessorDebug) {
            NSLog(@"%@: invoking %@", [self shortDescription], [retainedInvocation shortDescription]);
            if (setThreadNames)
                [[NSThread currentThread] setName:[retainedInvocation shortDescription]];
        }

        NS_DURING {
            [retainedInvocation invoke];
        } NS_HANDLER {
            NSLog(@"%@: %@", [retainedInvocation shortDescription], [localException reason]);
        } NS_ENDHANDLER;

        if (OFQueueProcessorDebug) {
	    NSLog(@"%@: finished %@", [self shortDescription], [retainedInvocation shortDescription]);
        }

        [currentInvocationLock lock];
        currentInvocation = nil;
        [currentInvocationLock unlock];

        if (setThreadNames)
            [[NSThread currentThread] setName:@"(idle)"];

        [retainedInvocation release];

        if (waitForMessages) {
            [autoreleasePool release];
            autoreleasePool = [[NSAutoreleasePool alloc] init];
        } else {
            // TJW -- Bug #332 about why this time check is here
            now = [NSDate timeIntervalSinceReferenceDate];
            if ((now - startingInterval > 0.25) || [self shouldProcessQueueEnd])
                break;
        }
    }

    if (setThreadNames)
        [[NSThread currentThread] setName:@"(exiting)"];

    if (OFQueueProcessorDebug)
        NSLog(@"%@: processQueueUntilEmpty: (exiting)", [self shortDescription]);
        
    
    [autoreleasePool release];
}

- (void)processQueueUntilEmpty;
{
    [self processQueueUntilEmpty:YES];
}

- (void)processQueueForever;
{
    [self processQueueUntilEmpty:NO];
}

- (void)startProcessingQueueInNewThread;
{
    [detachThreadLock lockWhenCondition: 0];
    [detachThreadLock unlockWithCondition: 1];
    [NSThread detachNewThreadSelector:@selector(processQueueInThread) toTarget:self withObject:nil];
}

- (OFInvocation *)retainedCurrentInvocation;
{
    OFInvocation *invocation;
    
    [currentInvocationLock lock];
    invocation = [currentInvocation retain];
    [currentInvocationLock unlock];

    return invocation;
}

// Debugging

- (NSMutableDictionary *)debugDictionary;
{
    NSMutableDictionary *debugDictionary;

    debugDictionary = [super debugDictionary];
    [debugDictionary setObject:messageQueue forKey:@"messageQueue"];
    return debugDictionary;
}

@end

@implementation OFQueueProcessor (Private)

- (BOOL)shouldProcessQueueEnd;
{
    return NO;
}

- (void)processQueueInThread;
{
    detachingQueueProcessor = self;
    for (;;) {
        NS_DURING {
            [self processQueueForever];
        } NS_HANDLER {
            NSLog(@"%@", [localException reason]);
        } NS_ENDHANDLER;
    }
}

@end
