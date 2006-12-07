// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/DataStructures.subproj/OFQueue.h,v 1.13 2004/02/10 04:07:43 kc Exp $

#import <Foundation/NSObject.h>

#import <pthread.h> // For pthread_mutex_t, pthread_cond_t

@interface OFQueue : NSObject
{
    BOOL closed;
    id *objects;
    unsigned int max, count, head, tail;
    pthread_mutex_t mutex;
    pthread_cond_t condition;
}

- initWithCount:(unsigned int)maxCount;

- (unsigned int)maxCount;
- (unsigned int)count;

- (BOOL)isClosed;
- (void)close;

- (id)dequeueShouldWait:(BOOL)wait;
- (BOOL)enqueue:(id)anObject shouldWait:(BOOL)wait;

@end
