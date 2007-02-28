// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/OFObject.h>

#import <Foundation/Foundation.h>
#import <Foundation/NSDebug.h>
#import <OmniBase/OmniBase.h>

#import <OmniFoundation/OFNull.h>
#import <OmniFoundation/OFSimpleLock.h>
#import <OmniFoundation/NSThread-OFExtensions.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/OFObject.m 68913 2005-10-03 19:36:19Z kc $")

@implementation OFObject
/*" OFObject provides an inline retain count for much more efficient reference counting. "*/


/*
  We want to avoid as much locking contention as possible when running on SMP machines.
  Thus, we will have a pool of locks with each object uniquely assigned one lock in
  the pool by some function of its address.  We will pad the spacings of the locks to
  avoid putting more than one on the same cache line.  This should avoid extra memory
  contention when operating on the locks.
*/

#ifdef __ppc__
#define OF_CACHE_LINE_SIZE 32
#endif

#ifndef OF_CACHE_LINE_SIZE
#warning Cannot determine cache line size -- using default value
#define OF_CACHE_LINE_SIZE 32
#endif

// This should always be a power of two
#define OF_NUMBER_OF_LOCKS 32

typedef union _OFCacheLineLock {
    OFSimpleLockType lock;
    unsigned char filler[OF_CACHE_LINE_SIZE];
} OFCacheLineLock;

static OFCacheLineLock retainLocks[OF_NUMBER_OF_LOCKS];

static inline OFSimpleLockType *_lockForObject(OFObject *obj)
{
    unsigned int addr, lockIndex;
    
    addr = (unsigned int)obj;
    
    // Addresses should always be long aligned, but they could be aligned up to a larger number of bits by the malloc package.  We'll drop four bits for 16-byte alignment as the maximum probably alignment.
    addr >>= 4;
    
    lockIndex = addr % OF_NUMBER_OF_LOCKS;
    
    return &retainLocks[lockIndex].lock;
}


#ifdef DEBUG
#define SaneRetainCount 1000000
#define FreedObjectRetainCount SaneRetainCount + 234567;
#endif

+ (void)initialize;
{
    unsigned int lockIndex;
    
    OBINITIALIZE;

    for (lockIndex = 0; lockIndex < OF_NUMBER_OF_LOCKS; lockIndex++)
        OFSimpleLockInit(&retainLocks[lockIndex].lock);
        
    [NSThread setMainThread];
}

- (unsigned int)retainCount;
{
    return retainCount + 1;
}

- (id)retain;
{
    OFSimpleLockType *lock;
    
    lock = _lockForObject(self);
    OFSimpleLock(lock);
#ifdef DEBUG
    if (retainCount > SaneRetainCount) {
        OFSimpleUnlock(lock);
        OBASSERT(retainCount <= SaneRetainCount);
        [NSException raise:@"RetainInsane" format:@"-[%@ %s]: Insane retain count! count=%d", OBShortObjectDescription(self), _cmd, retainCount];
    }
#endif

    if (NSKeepAllocationStatistics) {
        // Repord our allocation statistics to make OOM and oh happy
        NSRecordAllocationEvent(NSObjectInternalRefIncrementedEvent, self, NULL, NULL, NULL);
    }
    retainCount++;
    OFSimpleUnlock(lock);
    return self;
}

- (oneway void)release;
{
    OFSimpleLockType *lock;
    
    lock = _lockForObject(self);
    OFSimpleLock(lock);

    if (NSKeepAllocationStatistics) {
        // Report our allocation statistics to make OOM and oh happy
        NSRecordAllocationEvent(NSObjectInternalRefDecrementedEvent, self, NULL, NULL, NULL);
    }

    if (retainCount == 0) {
#ifdef DEBUG
        retainCount = FreedObjectRetainCount;
#endif
        OFSimpleUnlock(lock);
        [self dealloc];
    } else {
#ifdef DEBUG
        if (retainCount > SaneRetainCount) {
            OFSimpleUnlock(lock);
            [NSException raise:@"RetainInsane" format:@"-[%@ %s]: Insane retain count! count=%d", OBShortObjectDescription(self), _cmd, retainCount];
        }
#endif
        retainCount--;
        OFSimpleUnlock(lock);
    }
}

@end
