// Copyright 1998-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/DataStructures.subproj/OFBulkBlockPool.h 66170 2005-07-28 17:40:10Z kc $

#import <OmniFoundation/OFObject.h>

#import <OmniBase/assertions.h>
#import <OmniFoundation/FrameworkDefines.h>
#import <OmniFoundation/OFByte.h>

#ifdef OMNI_ASSERTIONS_ON
// Uncomment this (or define this) to turn on more stringent (and costly) assertions
// #define OF_BULK_BLOCK_POOL_AGGRESSIVE_ASSERTIONS
#endif

#ifdef OF_BULK_BLOCK_POOL_AGGRESSIVE_ASSERTIONS
#warning OF_BULK_BLOCK_POOL_AGGRESSIVE_ASSERTIONS enabled
#endif

//
// OFBulkBlockPool provides an optimized way to allocate a large number of fixed size blocks quickly and with very little overhead.  Currently, only double-word alignment is guaranteed (so you shouldn't attempt to store doubles or long longs in your blocks).  This works best for small blocks.  The amount of wasted space goes up proportionally to the size of the block.  The block size must be at least the size of a pointer.  In order to maximize performance, OFBulkBlockPool is not thread-safe.  The caller is responsible for providing this functionality should it be needed.
//
// Allocation is slightly faster than deallocation.  Free pages are not deallocated when all of the contained blocks on that pages are deallocated.  This could be implemented without too much trouble, but it would take up some small amount of space and time.


typedef struct _OFBulkBlockPage {
    OFByte *freeList; // the head of a linked list of free blocks
    struct _OFBulkBlockPool *pool; // this backpointer allow us to free stuff w/o knowing the pool
    OFByte *data[0]; // the rest of the page;
} OFBulkBlockPage;

typedef struct _OFBulkBlockPool {
    OFByte *freeList; // A cache of the freeList of the current page
    OFBulkBlockPage *currentPage;
    OFBulkBlockPage **pages;
    unsigned int pageCount;
    unsigned int blockSize;
    unsigned int allocationSize; // blockSize rounded up to a multiple of sizeof(unsigned int)
} OFBulkBlockPool;


OmniFoundation_EXTERN void  OFBulkBlockPoolInitialize(OFBulkBlockPool *pool, unsigned int blockSize);
// Initializes the pool to be able to allocate blocks of the given size.  No memory is allocated.

OmniFoundation_EXTERN void OFBulkBlockPoolDeallocateAllBlocks(OFBulkBlockPool *pool);
// Frees all of the memory associated with the pool.  This does NOT deallocate the pool itself.  The caller is responsible for doing this.

OmniFoundation_EXTERN void OFBulkBlockPoolReportStatistics(OFBulkBlockPool *pool);
// Prints out a list of pages that are in use, how many blocks are used on each page and other interesting information

OmniFoundation_EXTERN void _OFBulkBlockPoolGetPage(OFBulkBlockPool *pool);
// A private function used to get another page when the free list on the current page has been exhausted.

#ifdef OF_BULK_BLOCK_POOL_AGGRESSIVE_ASSERTIONS
OmniFoundation_EXTERN BOOL OFBulkBlockPoolCheckFreeLists(OFBulkBlockPool *pool);
#endif


static inline OFByte *OFBulkBlockPoolAllocate(OFBulkBlockPool *pool)
// Allocates and returns a new block of memory.  The contents of the memory are indeterminant -- the caller must set any bytes to their proper value.
{
    OFByte *block;
#ifdef OMNI_ASSERTIONS_ON
    OmniFoundation_PRIVATE_EXTERN unsigned int _OFBulkBlockPageSize;
#endif

    OBPRECONDITION(pool);
    // Either the free list should be empty or it should point to something in the current page
    OBPRECONDITION(!pool->freeList || (unsigned int)((OFByte *)pool->freeList - (OFByte *)pool->currentPage) < _OFBulkBlockPageSize);
#ifdef OF_BULK_BLOCK_POOL_AGGRESSIVE_ASSERTIONS
    OBPRECONDITION(OFBulkBlockPoolCheckFreeLists(pool));
#endif
                 
    if (!pool->freeList)
        _OFBulkBlockPoolGetPage(pool);
    
    block = pool->freeList;
    pool->freeList = *(OFByte **)pool->freeList;

    // Either the free list should be empty or it should point to something in the current page
    OBPOSTCONDITION(!pool->freeList || (unsigned int)((OFByte *)pool->freeList - (OFByte *)pool->currentPage) < _OFBulkBlockPageSize);
#ifdef OF_BULK_BLOCK_POOL_AGGRESSIVE_ASSERTIONS
    OBPOSTCONDITION(OFBulkBlockPoolCheckFreeLists(pool));
#endif
            
    return block;
}

static inline OFBulkBlockPool *OFBulkBlockPoolForBlock(OFByte *block)
// Returns the bulk block pool for the given block which must have been allocated with OFBulkBlockPoolAllocate() (and not have been deallocated yet).
{
    OFBulkBlockPage *page;
    OFBulkBlockPool *pool;
    OmniFoundation_PRIVATE_EXTERN unsigned int _OFBulkBlockPageSize;

    page = (OFBulkBlockPage *)((unsigned int)block & ~(_OFBulkBlockPageSize-1));
    pool = page->pool;

    return pool;
}

static inline void OFBulkBlockPoolDeallocate(OFByte *block)
{
    OFBulkBlockPage *page;
    OFBulkBlockPool *pool;
    OmniFoundation_PRIVATE_EXTERN unsigned int _OFBulkBlockPageSize;

    page = (OFBulkBlockPage *)((unsigned int)block & ~(_OFBulkBlockPageSize-1));
    pool = page->pool;


#ifdef OF_BULK_BLOCK_POOL_AGGRESSIVE_ASSERTIONS
    OBASSERT(OFBulkBlockPoolCheckFreeLists(pool));
#endif

    if (page == pool->currentPage) {
        // Either the free list should be empty or it should point to something in the current page
        OBASSERT(!pool->freeList || (unsigned int)((OFByte *)pool->freeList - (OFByte *)pool->currentPage) < _OFBulkBlockPageSize);

        // Update our local cached freeList
        *(OFByte **)block = pool->freeList;
        pool->freeList  = block;

        // Either the free list should be empty or it should point to something in the current page
        OBPOSTCONDITION(!pool->freeList || (unsigned int)((OFByte *)pool->freeList - (OFByte *)pool->currentPage) < _OFBulkBlockPageSize);
    } else {
        // Either the free list should be empty or it should point to something in the current page
        OBASSERT(!page->freeList || (unsigned int)((OFByte *)page->freeList - (OFByte *)page) < _OFBulkBlockPageSize);

        // Update the freeList on the appropriate page
        *(OFByte **)block = page->freeList;
        page->freeList  = block;

        // Either the free list should be empty or it should point to something in the current page
        OBPOSTCONDITION(!page->freeList || (unsigned int)((OFByte *)page->freeList - (OFByte *)page) < _OFBulkBlockPageSize);
    }

#ifdef OF_BULK_BLOCK_POOL_AGGRESSIVE_ASSERTIONS
    OBPOSTCONDITION(OFBulkBlockPoolCheckFreeLists(pool));
#endif
}

