// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/OFQueue.h>

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>



RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/DataStructures.subproj/OFQueue.m 68913 2005-10-03 19:36:19Z kc $")

NSString *OFQueueIsClosed = @"OFQueueIsClosed";

/*
I don't see how a NSConditionLock can be used to implement an overlapping state structure like this as efficiently as mutex/condition.  There are three states, empty, full and partially full.  Enqueue should block only on full, dequeue should only block on empty.  If you try to represent the states as not-empty and not-full, you have no way to represent the partially-full state.
*/

@implementation OFQueue

- initWithCount:(unsigned int)maxCount;
{
    closed = NO;
    max = maxCount;
    count = 0;
    head = 0;
    tail = 0;
    objects = (id *)NSZoneMalloc([self zone], sizeof(id) * max);

    pthread_mutex_init(&mutex, NULL);
    pthread_cond_init(&condition, NULL);
    
    return self;
}

- (void)dealloc;
{
    pthread_cond_destroy(&condition);
    pthread_mutex_destroy(&mutex);
    NSZoneFree([self zone], objects);
    [super dealloc];
}

- (unsigned int)maxCount;
{
    return max;
}

- (unsigned int)count;
{
    unsigned int ret;

    pthread_mutex_lock(&mutex);
    ret = count;
    pthread_mutex_unlock(&mutex);
    
    return ret;
}

- (void)close;
{
    pthread_mutex_lock(&mutex);
    closed = YES;
    pthread_cond_signal(&condition); /* in case anyone is trying to dequeue on a empty queue */
    pthread_mutex_unlock(&mutex);
}

- (BOOL)isClosed;
{
    BOOL ret;

    pthread_mutex_lock(&mutex);
    ret = closed;
    pthread_mutex_unlock(&mutex);
    
    return ret;
}

- (id)dequeueShouldWait:(BOOL)wait;
{
    id ret;

    pthread_mutex_lock(&mutex);

    while (!count && wait && !closed) {
        pthread_cond_wait(&condition, &mutex);
    }

    if (count) {
        ret = [objects[head] autorelease]; /* might want an exception handler here */
        count--;
        head++;
        if (head == max)
            head = 0;
        pthread_cond_signal(&condition);
    } else {
        ret = nil;
        /* don't signal, nothing happened */
    }

    pthread_mutex_unlock(&mutex);

    return ret;
}

- (BOOL)enqueue:(id)anObject shouldWait:(BOOL)wait;
{
    BOOL ret;

    pthread_mutex_lock(&mutex);

    if (closed) {
        pthread_mutex_unlock(&mutex);
        [NSException raise:OFQueueIsClosed format:@"Attempt to enqueue on a closed queue"];
    }

    while (count == max && wait) {
        pthread_cond_wait(&condition, &mutex);
    }

    if (count == max) {
        ret = NO;
        /* don't signal, nothing happened */
    } else {
        ret = YES;

        objects[tail] = [anObject retain]; /* might want an exception handler here */
        count++;
        tail++;
        if (tail == max)
            tail = 0;

        pthread_cond_signal(&condition); /* awake any readers */
    }

    pthread_mutex_unlock(&mutex);

    return ret;
}

@end
