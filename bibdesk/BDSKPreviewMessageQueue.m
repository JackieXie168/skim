//
//  BDSKPreviewMessageQueue.m
//  Bibdesk
//
//  Created by Adam Maxwell on 08/02/05.
/*
 This software is Copyright (c) 2005
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
        
        // drop everyone but the last object off the stack
        for (invocationIndex = 0; invocationIndex < invocationCount - 1; invocationIndex++)
            [queue removeObjectAtIndex:0];
        
        // now we pick the last added object
        for (invocationIndex = 0;;) {
            unsigned int group;
            BOOL useCurrentInvocation;
            OFInvocation *nextInvocation = nil;
            
            // get first invocation in queue
            nextInvocation = [queue lastObject];
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
    
    if (BDSKPreviewMessageQueueDebug)
        NSLog(@"[%@ nextRetainedInvocation] = %@, group = %d, priority = %d, maxThreads = %d", [self shortDescription], [nextRetainedInvocation shortDescription], [nextRetainedInvocation group], [nextRetainedInvocation priority], [nextRetainedInvocation maximumSimultaneousThreadsInGroup]);
    return nextRetainedInvocation;
}


@end
