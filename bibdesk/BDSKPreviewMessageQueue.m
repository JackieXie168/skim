//
//  BDSKPreviewMessageQueue.m
//  Bibdesk
//
//  Created by Adam Maxwell on 08/02/05.
/*
 This software is Copyright (c) 2005,2006
 Adam Maxwell. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 
 - Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 
 - Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in
 the documentation and/or other materials provided with the
 distribution.
 
 - Neither the name of Adam Maxwell nor the names of any
 contributors may be used to endorse or promote products derived
 from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "BDSKPreviewMessageQueue.h"
#import <OmniFoundation/OFQueueProcessor.h>
#import <OmniBase/OmniBase.h>

static BOOL BDSKPreviewMessageQueueDebug = NO;

// Copied here from OFMessageQueue.h
typedef enum {
    QUEUE_HAS_NO_SCHEDULABLE_INVOCATIONS, QUEUE_HAS_INVOCATIONS,
} OFMessageQueueState;

@implementation BDSKPreviewMessageQueue

- (void)removeAllInvocations;
{
    unsigned invocationCount;
    [queueLock lock];
    invocationCount = [queue count];
    while(invocationCount--)
        [queue removeObjectAtIndex:invocationCount];
    [queueLock unlock];
}

// We override this single method to alter the invocation order of OFMessageQueue, so the BDSKPreviewer always gets invoked with the last invocation.  
// Basically, invocations pile up in the queue from various selection changes/documents, and we drop all of them off the stack except the most recent addition, rather than processing them as a FIFO queue.

- (OFInvocation *)nextRetainedInvocationWithBlock:(BOOL)shouldBlock;
{
    unsigned int invocationCount;
    OFInvocation *nextRetainedInvocation = nil;
    
    [queueLock lock];
    if ([queue count])
        [queueLock unlockWithCondition:QUEUE_HAS_INVOCATIONS];
    else
        [queueLock unlockWithCondition:QUEUE_HAS_NO_SCHEDULABLE_INVOCATIONS];
    
    unsigned int invocationIndex;
    unsigned int queueProcessorIndex, queueProcessorCount;
    
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
    OFMessageQueueSchedulingInfo currentGroupSchedulingInfo = OFMessageQueueSchedulingInfoDefault;
    unsigned int currentGroupThreadCount = 0;
    
    // Keep only the last added object
    while (--invocationCount)
        [queue removeObjectAtIndex:0];
    invocationCount = [queue count];
    
    OBASSERT(invocationCount == 1);
    
    invocationIndex = 0;            
    BOOL useCurrentInvocation;
    
    // get first invocation in queue
    OFInvocation *nextInvocation = [queue objectAtIndex:invocationIndex];
    OFMessageQueueSchedulingInfo schedulingInfo = [nextInvocation messageQueueSchedulingInfo];
    if (schedulingInfo.group == NULL || queueProcessorCount == 0) {  // Null group is special, and can use as many threads as it wants
        useCurrentInvocation = YES;
#ifdef DEBUG_kc0
        if (flags.schedulesBasedOnPriority) {
            NSLog(@"-[%@ %s] invocation has no group: %@", OBShortObjectDescription(self), _cmd, [nextInvocation shortDescription]);
        }
        OBASSERT(!flags.schedulesBasedOnPriority); // If a message queue schedules based on priority, its invocations really should have priorities!
#endif
    } else {  // Check to see if this group already has used up all its allotted threads
        if (schedulingInfo.group != currentGroupSchedulingInfo.group) {
            OBASSERT(schedulingInfo.maximumSimultaneousThreadsInGroup > 0);
            currentGroupThreadCount = 0;
            if (schedulingInfo.maximumSimultaneousThreadsInGroup >= queueProcessorCount) {
                // This group is allowed as many threads as we have processors, so we don't need to bother counting the actual threads being spent on this group
            } else {
                for (queueProcessorIndex = 0; queueProcessorIndex < queueProcessorCount; queueProcessorIndex++) {
                    if (currentGroupThreadCount >= schedulingInfo.maximumSimultaneousThreadsInGroup)
                        break;
                    
                    // Get group of object queue processer is working on
                    OFMessageQueueSchedulingInfo processorSchedulingInfo = [[queueProcessors objectAtIndex:queueProcessorIndex] schedulingInfo];
                    
                    if (processorSchedulingInfo.group == schedulingInfo.group)
                        currentGroupThreadCount++;
                }
            }
            
            currentGroupSchedulingInfo = schedulingInfo;
        }
        useCurrentInvocation = currentGroupThreadCount < currentGroupSchedulingInfo.maximumSimultaneousThreadsInGroup;
#ifdef DEBUG_kc0
        NSLog(@"useCurrentInvocation=%d group=%d groupThreadCount=%d maximumSimultaneousThreadsInGroup=%d", useCurrentInvocation, currentGroupSchedulingInfo.group, groupThreadCount, currentGroupSchedulingInfo.maximumSimultaneousThreadsInGroup, [nextInvocation shortDescription]);
#endif
    }
    
    if (useCurrentInvocation) {
        nextRetainedInvocation = [nextInvocation retain];
        OBASSERT([queue objectAtIndex:invocationIndex] == nextInvocation);
        [queue removeObjectAtIndex:invocationIndex];
        if (queueSet)
            [queueSet removeObject:nextInvocation];
    }    
    
    [queueProcessorsLock unlock];
            
    if (nextRetainedInvocation == nil || invocationCount == 1) {
        OBASSERT([queue count] == 0 || nextRetainedInvocation == nil);
        [queueLock unlockWithCondition:QUEUE_HAS_NO_SCHEDULABLE_INVOCATIONS];
    } else { // nextRetainedInvocation != nil && invocationCount != 1
        OBASSERT([queue count] != 0);
        [queueLock unlockWithCondition:QUEUE_HAS_INVOCATIONS];
    }
            
    if (BDSKPreviewMessageQueueDebug)
        NSLog(@"[%@ nextRetainedInvocation] = %@, group = %d, priority = %d, maxThreads = %d", [self shortDescription], [nextRetainedInvocation shortDescription], [nextRetainedInvocation messageQueueSchedulingInfo].group, [nextRetainedInvocation messageQueueSchedulingInfo].priority, [nextRetainedInvocation messageQueueSchedulingInfo].maximumSimultaneousThreadsInGroup);
    return nextRetainedInvocation;
}


@end

@interface OFMessageQueue (DeclaredInOFMessageQueueAndCopiedHereToShutCompilerUp)
- (void)addQueueEntryOnce:(OFInvocation *)aQueueEntry;
@end

@implementation OFMessageQueue (BDSKExtensions)

- (void)queueSelectorOnce:(SEL)aSelector forObject:(id <NSObject>)anObject withBool:(BOOL)aBool;
{
    OFInvocation *queueEntry;
    
    if (!anObject)
        return;
    
    queueEntry = [[OFInvocation alloc] initForObject:anObject selector:aSelector withBool:aBool];
    [self addQueueEntryOnce:queueEntry];
    [queueEntry release];
}

@end
