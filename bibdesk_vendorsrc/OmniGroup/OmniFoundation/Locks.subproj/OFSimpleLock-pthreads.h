// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/Locks.subproj/OFSimpleLock-pthreads.h,v 1.4 2003/01/15 22:51:58 kc Exp $

#define OFSimpleLockDefined

#import <pthread.h>

typedef pthread_mutex_t OFSimpleLockType;

static inline void OFSimpleLockInit(OFSimpleLockType *simpleLock)
{
    // Only allow mutexing within this process
    pthread_mutex_init(simpleLock, NULL);
}

static inline void OFSimpleLockFree(OFSimpleLockType *simpleLock)
{
    pthread_mutex_destroy(simpleLock);
}

static inline void OFSimpleLock(OFSimpleLockType *simpleLock)
{
    pthread_mutex_lock(simpleLock);
}

static inline void OFSimpleLockTry(OFSimpleLockType *simpleLock)
{
    pthread_mutex_trylock(simpleLock);
}

static inline void OFSimpleUnlock(OFSimpleLockType *simpleLock)
{
    pthread_mutex_unlock(simpleLock);
}
