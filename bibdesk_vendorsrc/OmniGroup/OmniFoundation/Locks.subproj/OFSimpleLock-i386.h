// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/Locks.subproj/OFSimpleLock-i386.h 68913 2005-10-03 19:36:19Z kc $

#define OFSimpleLockDefined

#import <pthread.h>

typedef unsigned int OFSimpleLockBoolean;

typedef struct {
    OFSimpleLockBoolean locked;
} OFSimpleLockType;

#define OFSimpleLockIsNotLocked ((OFSimpleLockBoolean)0)
#define OFSimpleLockIsLocked ((OFSimpleLockBoolean)1)

static inline void OFSimpleLockInit(OFSimpleLockType *simpleLock)
{
    simpleLock->locked = OFSimpleLockIsNotLocked;
}

#define OFSimpleLockFree(lock) /**/

static inline OFSimpleLockBoolean
OFSimpleLockTry(OFSimpleLockType *simpleLock)
{
    OFSimpleLockBoolean result;

    asm volatile(
    	"xchgl %1,%0; xorl %3,%0"
	    : "=r" (result), "=m" (simpleLock->locked)
	    : "0" (OFSimpleLockIsLocked), "i" (OFSimpleLockIsLocked));
	    
    return result;
}

static inline void OFSimpleLock(OFSimpleLockType *simpleLock)
{
    do {
	while (simpleLock->locked) {
	    sched_yield();
	    continue;
	}
    } while (!OFSimpleLockTry(simpleLock));
}

static inline void OFSimpleUnlock(OFSimpleLockType *simpleLock)
{
    OFSimpleLockBoolean result;
    
    asm volatile(
	"xchgl %1,%0"
	    : "=r" (result), "=m" (simpleLock->locked)
	    : "0" (OFSimpleLockIsNotLocked));
}
