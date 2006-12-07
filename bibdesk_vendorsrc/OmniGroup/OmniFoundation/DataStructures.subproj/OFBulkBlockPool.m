// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/OFBulkBlockPool.h>

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/DataStructures.subproj/OFBulkBlockPool.m 68913 2005-10-03 19:36:19Z kc $")

unsigned int _OFBulkBlockPageSize;


void  OFBulkBlockPoolInitialize(OFBulkBlockPool *pool, unsigned int blockSize)
{
    OBPRECONDITION(blockSize <= NSPageSize() - sizeof(OFBulkBlockPage));
                     
    // We set this each time -- doesn't really hurt anything
    _OFBulkBlockPageSize = NSPageSize();
    
    pool->pages          = NULL;
    pool->currentPage    = NULL;
    pool->pageCount      = 0;
    pool->blockSize      = blockSize;
    pool->freeList       = NULL;

    pool->allocationSize = (blockSize / sizeof(unsigned int)) * sizeof(unsigned int);
    if (pool->allocationSize * sizeof(unsigned int) < pool->blockSize)
        pool->allocationSize += sizeof(unsigned int);
}

void _OFBulkBlockPoolGetPage(OFBulkBlockPool *pool)
{
    OBPRECONDITION(!pool->freeList);
    
    if (pool->currentPage)
        // Update the page that we were dealing with
        pool->currentPage->freeList = NULL;

    // See if we have another page that has some free blocks
    if (pool->pages) {
        // We could start from the currentPage and loop around, but that would be more error prone.  This will cause full pages to get swapped in when they might not otherwise.
        unsigned int pageIndex;

        for (pageIndex = 0; pageIndex < pool->pageCount; pageIndex++) {
            if (pool->pages[pageIndex]->freeList) {
                pool->currentPage = pool->pages[pageIndex];
                pool->freeList    = pool->currentPage->freeList;
                break;
            }
        }
    }

    if (!pool->freeList) {
        void *block, *blockEnd;
        
        // There were no non-full pages
        // Make room to store another page
        pool->pageCount++;
        if (pool->pages)
            pool->pages = NSZoneRealloc(NSDefaultMallocZone(), pool->pages, sizeof(void *) * pool->pageCount);
        else
            pool->pages = NSZoneMalloc(NSDefaultMallocZone(), sizeof(void *) * pool->pageCount);

        // Allocate the page
        OBASSERT(_OFBulkBlockPageSize);
        pool->currentPage       = NSAllocateMemoryPages(_OFBulkBlockPageSize);
#ifdef DEBUG_PAGES
        fprintf(stderr, "pool 0x%08x allocated page 0x%08x\n", pool, pool->currentPage);
#endif
        
        pool->currentPage->pool = pool;
        pool->pages[pool->pageCount-1] = pool->currentPage;

        // Set up the free list in the new page
        block                       = &pool->currentPage->data[0];
        blockEnd                    = (void *)pool->currentPage + _OFBulkBlockPageSize - pool->allocationSize;
        pool->currentPage->freeList = block;

        //fprintf(stderr, "Block = 0x%08x, blockSize = %d, allocationSize = %d\n", block, pool->blockSize, pool->allocationSize);
        while (block <= blockEnd) {
            void *nextBlock;

            nextBlock = block + pool->allocationSize;
            *(void **)block = nextBlock;
            block = nextBlock;

            //fprintf(stderr, "  block = 0x%08x\n", block);
        }

        // Terminate the free list -- probably not necessary since we just did a low level page allocation, but it can't really hurt.
        //fprintf(stderr, "  blockEnd = 0x%08x\n", blockEnd);
        block -= pool->allocationSize;                   // back up to the last block
        OBASSERT((unsigned)(blockEnd - block) < pool->allocationSize); // there should not be a whole block left
        *(void **)block = NULL;                          // terminate the list

        // Cache the freeList
        pool->freeList = pool->currentPage->freeList;
    }
        
    OBPOSTCONDITION(pool->currentPage);
    OBPOSTCONDITION(pool->freeList);
    OBPOSTCONDITION(pool->currentPage->freeList == pool->freeList);
}

void OFBulkBlockPoolDeallocateAllBlocks(OFBulkBlockPool *pool)
{
    // Later, when we support user-defined allocation events, we'll need to do something cooler here
    if (pool->pages) {
        unsigned int pageIndex;
        
        OBASSERT(pool->pageCount);
        OBASSERT(pool->currentPage);

        for (pageIndex = 0; pageIndex < pool->pageCount; pageIndex++) {
            NSDeallocateMemoryPages(pool->pages[pageIndex], _OFBulkBlockPageSize);
#ifdef DEBUG_PAGES
            fprintf(stderr, "pool 0x%08x deallocated page 0x%08x\n", pool, pool->pages[pageIndex]);
#endif
        }


        NSZoneFree(NSDefaultMallocZone(), pool->pages);
        
        pool->pages       = NULL;
        pool->currentPage = NULL;
        pool->pageCount   = 0;
        pool->freeList    = NULL;
    }
}

void OFBulkBlockPoolReportStatistics(OFBulkBlockPool *pool)
{
    unsigned int pageIndex;
    unsigned int blocksPerPage;

    blocksPerPage = (NSPageSize() - sizeof(OFBulkBlockPage)) / pool->allocationSize;
    
    fprintf(stderr, "pool = 0x%08x\n", (unsigned int)pool);
    fprintf(stderr, "  number of pages       = %d\n", pool->pageCount);
    fprintf(stderr, "  bytes per block       = %d (%d allocated)\n", pool->blockSize, pool->allocationSize);
    fprintf(stderr, "  blocks per page       = %d\n", blocksPerPage);
    fprintf(stderr, "  wasted bytes per page = %d\n", NSPageSize() - blocksPerPage * pool->blockSize);

    for (pageIndex = 0; pageIndex < pool->pageCount; pageIndex++) {
        OFBulkBlockPage *page;
        unsigned int freeCount;
        void *freeBlock;
        
        page = pool->pages[pageIndex];
        freeCount = 0;

        if (page == pool->currentPage)
            freeBlock = pool->freeList;
        else
            freeBlock = page->freeList;
        while (freeBlock) {
            freeBlock = *(void **)freeBlock;
            freeCount++;
        }

        fprintf(stderr, "  page = 0x%08x, free blocks = %d, allocated blocks = %d\n", (unsigned int)page, freeCount, blocksPerPage - freeCount);
    }
}

#ifdef TEST

static BOOL OFBulkBlockPoolCheckFreeLists(OFBulkBlockPool *pool)
{
    unsigned int pageIndex;
    OFBulkBlockPage *page;
    void *freeBlock;

    for (pageIndex = 0; pageIndex < pool->pageCount; pageIndex++) {
        page = pool->pages[pageIndex];
        if (page == pool->currentPage)
            freeBlock = pool->freeList;
        else
            freeBlock = page->freeList;
        
        while (freeBlock) {
            OBASSERT((unsigned int)((void *)freeBlock - (void *)page) < _OFBulkBlockPageSize);
            freeBlock = *(void **)freeBlock;
        }
    }

    return YES;
}

#endif
