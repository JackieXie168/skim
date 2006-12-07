// Copyright 2000-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>
#import <OmniFoundation/OFBTree.h>
#import <stdio.h>
#import <mach/mach.h>
#import <mach/mach_error.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/Tests/OFBTreeTest.m,v 1.9 2003/01/15 22:52:04 kc Exp $")

void *mallocAllocator(OFBTree *btree)
{
    return malloc(btree->nodeSize);
}

void mallocDeallocator(OFBTree *btree, void *node)
{
    free(node);
}

void *pageAllocator(struct _OFBTree *tree)
{
    kern_return_t	err;
    vm_address_t	addr;
    
    err = vm_allocate(mach_task_self(), &addr, vm_page_size, 1);
    if (err) {
        mach_error("vm_allocate", err);
        abort();
    }
    return (void *)addr;
}

void pageDeallocator(OFBTree *btree, void *node)
{
    kern_return_t	err;
    err = vm_deallocate(mach_task_self(), (vm_address_t)node, vm_page_size);
    if (err) {
        mach_error("vm_deallocate", err);
        abort();
    }
}

int testComparator(OFBTree *btree, const void *a, const void *b)
{
    return *(const int *)a - *(const int *)b;
}

static void testEnumerator(OFBTree *tree, void *element, void *arg)
{
    printf("%d ", *(int *)element);
}

NSString *testNodeDescription(void *node) {
    NSMutableString *string = [[NSMutableString alloc] init];
    int *ptr = node;
    int count = *ptr++;

    while(count--)
        [string appendFormat:@"%x<%d>", *ptr++, *ptr++];
    [string appendFormat:@"%x", *ptr];
    return [string autorelease];
}

void permute(unsigned int *numbers, unsigned int count)
{
    unsigned int i, j, tmp;
    
    // loop through the vector spwaping each element with another random element
    for (i = 0; i < count; i++) {
        j = random() % count;
        tmp = numbers[i];
        numbers[i] = numbers[j];
        numbers[j] = tmp;
    }
}

void test()
{
    OFBTree btree;
    int i;

#if 0    
    OFBTreeInit(&btree, sizeof(int) * 12, sizeof(int), mallocAllocator, mallocDeallocator, testComparator);
    
    i = 1;
    OFBTreeInsert(&btree, &i);
    i = 2;
    OFBTreeInsert(&btree, &i);
    i = 3;
    OFBTreeInsert(&btree, &i);
    i = 4;
    OFBTreeInsert(&btree, &i);
    i = 5;
    OFBTreeInsert(&btree, &i);
    i = 6;
    OFBTreeInsert(&btree, &i);
    i = 7;
    OFBTreeInsert(&btree, &i);
    i = 8;
    OFBTreeInsert(&btree, &i);
    i = 9;
    OFBTreeInsert(&btree, &i);
    i = 10;
    OFBTreeInsert(&btree, &i);
    
    printf("Tree with 1-10:\n");
    OFBTreeEnumerate(&btree, testEnumerator, NULL);
    printf("\n");
    
    i = 4;
    NSLog(@"find 4: %d", *(int *)OFBTreeFind(&btree, &i));
    i = 7;
    NSLog(@"find 7: %d", *(int *)OFBTreeFind(&btree, &i));

    i = 4;
    NSLog(@"previous 4: %d", *(int *)OFBTreePrevious(&btree, &i));
    NSLog(@"next 4: %d", *(int *)OFBTreeNext(&btree, &i));
    i = 10;
    NSLog(@"previous 10: %d", *(int *)OFBTreePrevious(&btree, &i));
    NSLog(@"next 10: %@", OFBTreeNext(&btree, &i) ? @"YES" : @"NO");
    i = 1;
    NSLog(@"previous 1: %@", OFBTreePrevious(&btree, &i) ? @"YES" : @"NO");
    NSLog(@"next 1: %d", *(int *)OFBTreeNext(&btree, &i));
    
    i = 6;
    OFBTreeDelete(&btree, &i);
    i = 2;
    OFBTreeDelete(&btree, &i);

    printf("Tree with: 1 3 4 5 7 8 9 10\n");
    OFBTreeEnumerate(&btree, testEnumerator, NULL);
    printf("\n");

    OFBTreeDestroy(&btree);
#endif
    
#define INSERT_COUNT 1000000
    {
        unsigned int *numbers, i, seed;
        
        seed = time(NULL);
        srandom(seed);
        numbers = malloc(sizeof(*numbers) * INSERT_COUNT);
        
        OFBTreeInit(&btree, vm_page_size, sizeof(int), pageAllocator, pageDeallocator, testComparator);

        printf("Inserting 1..%d in random order (seed = %d)\n", INSERT_COUNT, seed);
        // fill the vector
        for (i = 0; i < INSERT_COUNT; i++)
            numbers[i] = i+1;

        // Insert them all in random order
        permute(numbers, INSERT_COUNT);
        for (i = 0; i < INSERT_COUNT; i++) {
            //printf("inserting %d\n", numbers[i]);
            OFBTreeInsert(&btree, &numbers[i]);
        }
        
        printf("Finding 1..%d in random order\n", INSERT_COUNT);
        permute(numbers, INSERT_COUNT);
        for (i = 0; i < INSERT_COUNT; i++) {
            if (!OFBTreeFind(&btree, &numbers[i])) {
                printf("UNABLE TO FIND %d!\n", numbers[i]);
                fflush(stdout);
                abort();
            }
        }
        printf("Removing 1..%d in random order\n", INSERT_COUNT);
        permute(numbers, INSERT_COUNT);
        for (i = 0; i < INSERT_COUNT; i++) {
            //printf("deleting %d\n", numbers[i]);
            if (!OFBTreeDelete(&btree, &numbers[i])) {
                printf("UNABLE TO DELETE %d!\n", numbers[i]);
                fflush(stdout);
                abort();
            }
        }
        
        printf("Done\n");
        
        // Clean up
        OFBTreeDestroy(&btree);
        free(numbers);
    }
    
}

int main(int argc, char *argv[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    test();
    [pool release];
    return 0;
}
