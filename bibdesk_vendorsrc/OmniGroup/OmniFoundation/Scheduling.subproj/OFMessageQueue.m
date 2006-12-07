// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/OFMessageQueue.h>

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

#import <OmniFoundation/OFInvocation.h>
#import <OmniFoundation/OFQueueProcessor.h>
#import <OmniFoundation/NSThread-OFExtensions.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/Scheduling.subproj/OFMessageQueue.m,v 1.29 2004/02/10 04:07:47 kc Exp $")

@interface OFMessageQueue (Private)
- (void)_createProcessorsForQueueSize:(unsigned int)queueCount;
- (void)_callFunction:(void (*)())aFunction argument:(void *)argument;
@end

typedef enum {
    QUEUE_HAS_NO_SCHEDULABLE_INVOCATIONS, QUEUE_HAS_INVOCATIONS,
} OFMessageQueueState;


@implementation OFMessageQueue

static BOOL OFMessageQueueDebug = NO;

+ (OFMessageQueue *)mainQueue;
{
    static OFMessageQueue *mainQueue = nil;

    if (!mainQueue) {
        mainQueue = [[OFMessageQueue alloc] init];
        [mainQueue setSchedulesBasedOnPriority:NO];
    }
    return mainQueue;
}

// Init and dealloc

- init;
{
    if (![super init])
	return nil;

    queue = [[NSMutableArray alloc] init];
    queueLock = [[NSConditionLock alloc] initWithCondition:QUEUE_HAS_NO_SCHEDULABLE_INVOCATIONS];
    delegate = nil;

    idleProcessors = 0;
    queueProcessorsLock = [[NSLock alloc] init];
    uncreatedProcessors = 0;
    queueProcessors = [[NSMutableArray alloc] init];
    flags.schedulesBasedOnPriority = YES;

    return self;
}

- (void)dealloc;
{
    [queueProcessors release];
    [queue release];
    [queueSet release];
    [queueLock release];
    [queueProcessorsLock release];
    [super dealloc];
}


//

- (void)setDelegate:(id <OFMessageQueueDelegate>)aDelegate;
{
    OBPRECONDITION([(id)aDelegate conformsToProtocol:@protocol(OFMessageQueueDelegate)]);
    delegate = aDelegate;
}

- (void)startBackgroundProcessors:(unsigned int)processorCount;
{
    [queueProcessorsLock lock];
    uncreatedProcessors += processorCount;
    [queueProcessorsLock unlock];

    // Now, go ahead and start some (or all) of those processors to handle messages already queued
    [queueLock lock];
    [self _createProcessorsForQueueSize:[queue count]];
    [queueLock unlock];
}

- (void)setSchedulesBasedOnPriority:(BOOL)shouldScheduleBasedOnPriority;
{
    flags.schedulesBasedOnPriority = shouldScheduleBasedOnPriority;
}

//

- (BOOL)hasInvocations;
{
    BOOL hasInvocations;

    [queueLock lock];
    hasInvocations = [queue count] > 0;
    [queueLock unlock];
    return hasInvocations;
}

- (OFInvocation *)nextRetainedInvocation;
{
    return [self nextRetainedInvocationWithBlock:YES];
}

- (OFInvocation *)nextRetainedInvocationWithBlock:(BOOL)shouldBlock;
{
    unsigned int invocationCount;
    OFInvocation *nextRetainedInvocation = nil;

    [queueLock lock];
    if ([queue count])
        [queueLock unlockWithCondition:QUEUE_HAS_INVOCATIONS];
    else
        [queueLock unlockWithCondition:QUEUE_HAS_NO_SCHEDULABLE_INVOCATIONS];
           
    do {
        unsigned int invocationIndex;
        unsigned int queueProcessorIndex, queueProcessorCount;
        unsigned int lastGroup, lastGroupThreadCount;

        if (shouldBlock) {
            [queueProcessorsLock lock];
            idleProcessors++;
            [queueProcessorsLock unlock];
            [queueLock lockWhenCondition:QUEUE_HAS_INVOCATIONS];
            [queueProcessorsLock lock];
            idleProcessors--;
            [queueProcessorsLock unlock];
        } else {
            [queueLock lock];
        }

        invocationCount = [queue count];
        if (invocationCount == 0) {
            OBASSERT(!shouldBlock);
            [queueLock unlock];
            return nil;
        }

        [queueProcessorsLock lock];

        queueProcessorCount = [queueProcessors count];
        lastGroup = lastGroupThreadCount = 0;

        for (invocationIndex = 0; invocationIndex < invocationCount; invocationIndex++) {
            unsigned int group;
            BOOL useCurrentInvocation;
            OFInvocation *nextInvocation = nil;

            // get first invocation in queue
            nextInvocation = [queue objectAtIndex:invocationIndex];
            group = [nextInvocation group];
            if (!group) {  // Group 0 is special, and can use as many threads as it wants
                useCurrentInvocation = YES;
            } else {  // Check to see if this group already has used up all its allotted threads
                unsigned int groupThreadCount, groupMaxThreads;

                groupMaxThreads = [nextInvocation maximumSimultaneousThreadsInGroup];
                if (group == lastGroup)
                    groupThreadCount = lastGroupThreadCount;
                else {
                    groupThreadCount = 0;

                    for (queueProcessorIndex = 0; queueProcessorIndex < queueProcessorCount; queueProcessorIndex++) {
                        OFInvocation *retainedQueueInvocation;

                        if (groupThreadCount >= groupMaxThreads)
                            break;

                        // Get group of object queue processer is working on
                        retainedQueueInvocation = [[queueProcessors objectAtIndex:queueProcessorIndex] retainedCurrentInvocation];

                        if ([retainedQueueInvocation group] == group)
                            groupThreadCount++;
                        [retainedQueueInvocation release];
                    }

                    lastGroup = group;
                    lastGroupThreadCount = groupThreadCount;
                }
                useCurrentInvocation = groupThreadCount < groupMaxThreads;
            }

            if (useCurrentInvocation) {
                nextRetainedInvocation = [nextInvocation retain];
                OBASSERT([queue objectAtIndex:invocationIndex] == nextInvocation);
                [queue removeObjectAtIndex:invocationIndex];
                if (queueSet)
                    [queueSet removeObject:nextInvocation];
                break;
            }
        }

        [queueProcessorsLock unlock];

        if (nextRetainedInvocation == nil || invocationCount == 1) {
            OBASSERT([queue count] == 0 || nextRetainedInvocation == nil);
            [queueLock unlockWithCondition:QUEUE_HAS_NO_SCHEDULABLE_INVOCATIONS];
        } else { // nextRetainedInvocation != nil && invocationCount != 1
            OBASSERT([queue count] != 0);
            [queueLock unlockWithCondition:QUEUE_HAS_INVOCATIONS];
        }

    } while (nextRetainedInvocation == nil);
    
    if (OFMessageQueueDebug)
        NSLog(@"[%@ nextRetainedInvocation] = %@, group = %d, priority = %d, maxThreads = %d", [self shortDescription], [nextRetainedInvocation shortDescription], [nextRetainedInvocation group], [nextRetainedInvocation priority], [nextRetainedInvocation maximumSimultaneousThreadsInGroup]);
    return nextRetainedInvocation;
}

- (void)addQueueEntry:(OFInvocation *)aQueueEntry;
{
    BOOL shouldNotifyDelegate;
    unsigned int queueCount, entryIndex;
    unsigned int priority;

    OBPRECONDITION(aQueueEntry);
    
#ifdef OW_DISALLOW_MULTI_THREADING
    if (self != [OFMessageQueue mainQueue]) {
	[[OFMessageQueue mainQueue] addQueueEntry: aQueueEntry];
	return;
    }
#endif

    if (OFMessageQueueDebug)
	NSLog(@"[%@ addQueueEntry:%@]", [self shortDescription], [aQueueEntry shortDescription]);

    [queueLock lock];

    queueCount = [queue count];
    shouldNotifyDelegate = delegate != nil && queueCount == 0;
    entryIndex = queueCount;
    if (flags.schedulesBasedOnPriority) {
        // Figure out priority
        priority = [aQueueEntry priority];
        OBASSERT(priority != 0);

        // Find spot at end of other entries with same priority
        while (entryIndex--) {
            OFInvocation *otherEntry;

            otherEntry = [queue objectAtIndex:entryIndex];
            if ([otherEntry priority] <= priority)
                break;
        }
        entryIndex++;
    }

    // Insert object at entryIndex
    [queue insertObject:aQueueEntry atIndex:entryIndex];
    queueCount++;
    if (queueSet)
        [queueSet addObject:aQueueEntry];

    // Create new processor if needed and we can
    [self _createProcessorsForQueueSize:queueCount];

    [queueLock unlockWithCondition:QUEUE_HAS_INVOCATIONS];

    if (shouldNotifyDelegate)
	[delegate queueHasInvocations:self];
}

- (void)addQueueEntryOnce:(OFInvocation *)aQueueEntry;
{
    BOOL alreadyContainsObject;

    [queueLock lock];
    if (!queueSet)
	queueSet = [[NSMutableSet alloc] initWithArray:queue];
    alreadyContainsObject = [queueSet member:aQueueEntry] != nil;
    [queueLock unlock];
    if (!alreadyContainsObject)
	[self addQueueEntry:aQueueEntry];
}

- (void)queueInvocation:(NSInvocation *)anInvocation forObject:(id <NSObject>)anObject;
{
    OFInvocation *queueEntry;

    if (!anObject)
        return;
    
    queueEntry = [[OFInvocation alloc] initForObject:anObject nsInvocation:anInvocation];
    [self addQueueEntry:queueEntry];
    [queueEntry release];
}

- (void)queueSelector:(SEL)aSelector forObject:(id <NSObject>)anObject;
{
    OFInvocation *queueEntry;

    if (!anObject)
        return;
    
    queueEntry = [[OFInvocation alloc] initForObject:anObject selector:aSelector];
    [self addQueueEntry:queueEntry];
    [queueEntry release];
}

- (void)queueSelectorOnce:(SEL)aSelector forObject:(id <NSObject>)anObject;
{
    OFInvocation *queueEntry;

    if (!anObject)
        return;
    
    queueEntry = [[OFInvocation alloc] initForObject:anObject selector:aSelector];
    [self addQueueEntryOnce:queueEntry];
    [queueEntry release];
}

- (void)queueSelector:(SEL)aSelector forObject:(id <NSObject>)anObject withObject:(id <NSObject>)withObject;
{
    OFInvocation *queueEntry;

    if (!anObject)
        return;
    
    queueEntry = [[OFInvocation alloc] initForObject:anObject selector:aSelector withObject:withObject];
    [self addQueueEntry:queueEntry];
    [queueEntry release];
}

- (void)queueSelectorOnce:(SEL)aSelector forObject:(id <NSObject>)anObject withObject:(id <NSObject>)withObject;
{
    OFInvocation *queueEntry;

    if (!anObject)
        return;
    
    queueEntry = [[OFInvocation alloc] initForObject:anObject selector:aSelector withObject:withObject];
    [self addQueueEntryOnce:queueEntry];
    [queueEntry release];
}

- (void)queueSelector:(SEL)aSelector forObject:(id <NSObject>)anObject withObject:(id <NSObject>)object1 withObject:(id <NSObject>)object2;
{
    OFInvocation *queueEntry;

    if (!anObject)
        return;
    
    queueEntry = [[OFInvocation alloc] initForObject:anObject selector:aSelector withObject:object1 withObject:object2];
    [self addQueueEntry:queueEntry];
    [queueEntry release];
}

- (void)queueSelectorOnce:(SEL)aSelector forObject:(id <NSObject>)anObject withObject:(id <NSObject>)object1 withObject:(id <NSObject>)object2;
{
    OFInvocation *queueEntry;

    if (!anObject)
        return;
    
    queueEntry = [[OFInvocation alloc] initForObject:anObject selector:aSelector withObject:object1 withObject:object2];
    [self addQueueEntryOnce:queueEntry];
    [queueEntry release];
}

- (void)queueSelector:(SEL)aSelector forObject:(id <NSObject>)anObject withObject:(id <NSObject>)object1 withObject:(id <NSObject>)object2 withObject:(id <NSObject>)object3;
{
    OFInvocation *queueEntry;

    if (!anObject)
        return;
    
    queueEntry = [[OFInvocation alloc] initForObject:anObject selector:aSelector withObject:object1 withObject:object2 withObject:object3];
    [self addQueueEntry:queueEntry];
    [queueEntry release];
}

- (void)queueSelector:(SEL)aSelector forObject:(id <NSObject>)anObject withBool:(BOOL)aBool;
{
    OFInvocation *queueEntry;

    if (!anObject)
        return;
    
    queueEntry = [[OFInvocation alloc] initForObject:anObject selector:aSelector withBool:aBool];
    [self addQueueEntry:queueEntry];
    [queueEntry release];
}

- (void)queueSelector:(SEL)aSelector forObject:(id <NSObject>)anObject withInt:(int)anInt;
{
    OFInvocation *queueEntry;

    if (!anObject)
        return;
    
    queueEntry = [[OFInvocation alloc] initForObject:anObject selector:aSelector withInt:anInt];
    [self addQueueEntry:queueEntry];
    [queueEntry release];
}

- (void)queueSelector:(SEL)aSelector forObject:(id <NSObject>)anObject withInt:(int)anInt withInt:(int)anotherInt;
{
    OFInvocation *queueEntry;

    if (!anObject)
        return;
    
    queueEntry = [[OFInvocation alloc] initForObject:anObject selector:aSelector withInt:anInt withInt:anotherInt];
    [self addQueueEntry:queueEntry];
    [queueEntry release];
}

@end


@implementation OFMessageQueue (Private)

// Debugging

+ (void)setDebug:(BOOL)shouldDebug;
{
    OFMessageQueueDebug = shouldDebug;
}

- (NSMutableDictionary *)debugDictionary;
{
    NSMutableDictionary *debugDictionary;

    debugDictionary = [super debugDictionary];
    [debugDictionary setObject:queue forKey:@"queue"];
    [debugDictionary setObject:[NSNumber numberWithInt:idleProcessors] forKey:@"idleProcessors"];
    [debugDictionary setObject:[NSNumber numberWithInt:uncreatedProcessors] forKey:@"uncreatedProcessors"];
    [debugDictionary setObject:flags.schedulesBasedOnPriority ? @"YES" : @"NO" forKey:@"flags.schedulesBasedOnPriority"];
    if (delegate)
	[debugDictionary setObject:delegate forKey:@"delegate"];

    return debugDictionary;
}

- (void)_createProcessorsForQueueSize:(unsigned int)queueCount;
{
    unsigned int projectedIdleProcessors;

    [queueProcessorsLock lock];
    projectedIdleProcessors = idleProcessors;
    while (projectedIdleProcessors < queueCount && uncreatedProcessors > 0) {
	OFQueueProcessor *newProcessor;

	newProcessor = [[OFQueueProcessor alloc] initForQueue:self];
	[newProcessor startProcessingQueueInNewThread];
        [queueProcessors addObject:newProcessor];
        [newProcessor release];
	uncreatedProcessors--;
        projectedIdleProcessors++;
    }
    [queueProcessorsLock unlock];
}

- (void)_callFunction:(void (*)())aFunction argument:(void *)argument;
{
    aFunction(argument);
}

@end


void OFQueueFunction(void (*aFunction)(void *arg), void *arg)
{
    OFMessageQueue *queue;
    
    queue = [OFMessageQueue mainQueue];
    [queue queueSelector:@selector(_callFunction:argument:) forObject:queue withInt:(int)aFunction withInt:(int)arg];
}

BOOL OFMainThreadPerformFunction(void (*aFunction)(void *arg), void *arg)
{
    if ([NSThread inMainThread]) {
        aFunction(arg);
        return YES;
    } else {
        OFQueueFunction(aFunction, arg);
        return NO;
    }
}
