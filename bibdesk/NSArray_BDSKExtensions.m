//
//  NSArray_BDSKExtensions.m
//  Bibdesk
//
//  Created by Adam Maxwell on 12/21/05.
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

#import "NSArray_BDSKExtensions.h"


@implementation NSArray (BDSKExtensions)

- (id)firstObject;
{
    return [self count] ? [self objectAtIndex:0] : nil;
}

// this may give unexpected results if you have multiple instances of an object in an array; it will return only the lowest index
- (NSIndexSet *)indexesOfObjectsIdenticalTo:(NSArray *)objects;
{
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    unsigned index;
    NSEnumerator *objEnum = [objects objectEnumerator];
	id obj;
    while(obj = [objEnum nextObject]){
        index = [self indexOfObjectIdenticalTo:obj];
        if(index == NSNotFound) [NSException raise:NSInvalidArgumentException format:@"Object %@ does not exist in %@", obj, self];
        [indexes addIndex:index];
    }
    return indexes;
}

@end

@implementation NSMutableArray (BDSKExtensions)

- (void)sortUsingSelector:(SEL)comparator ascending:(BOOL)ascend;
{
    [self sortUsingSelector:comparator];
    
    if(ascend)
        return;
    
    int rhIndex = ([self count] - 1);
    int lhIndex = 0;
    
    while( (rhIndex - lhIndex) > 0)
        [self exchangeObjectAtIndex:rhIndex-- withObjectAtIndex:lhIndex++];
}

/* Assumes the array is already sorted to insert the object quickly in the right place */
/* (new objects are inserted just after old objects that are NSOrderedSame) */
- (void)insertObject:anObject inArraySortedUsingDescriptors:(NSArray *)sortDescriptors;
{
    // nil or zero-length sortDescriptors arg is not handled
    NSParameterAssert([sortDescriptors count]);
    if([sortDescriptors count] > 1)
        NSLog(@"*** WARNING: Multiple sort descriptors are not supported by method %@.", NSStringFromSelector(_cmd));
    unsigned int low = 0;
    unsigned int range = 1;
    unsigned int test = 0;
    unsigned int count = [self count];
    NSComparisonResult result;
    IMP objectAtIndexImp = [self methodForSelector:@selector(objectAtIndex:)];
    NSSortDescriptor *sort = [sortDescriptors objectAtIndex:0];
    if([sort ascending] == NO)
        sort = [sort reversedSortDescriptor];
    
    typedef NSComparisonResult (*compareImpType)(id, SEL, id, id); 
    compareImpType compareImp = (compareImpType)[sort methodForSelector:@selector(compareObject:toObject:)];

    // @@ does not support multiple descriptors at this time
    while (count >= range) /* range is the lowest power of 2 > count */
        range <<= 1;
    
    while (range) {
        test = low + (range >>= 1);
        if (test >= count)
            continue;
        
        result = compareImp(sort, @selector(compareObject:toObject:), anObject, objectAtIndexImp(self, @selector(objectAtIndex:), test) );
        
        if (result == NSOrderedDescending)
            low = test+1;
    }
    [self insertObject:anObject atIndex:low];
}   

- (void)insertObjects:(NSArray *)objects inArraySortedUsingDescriptors:(NSArray *)sortDescriptors;
{
    NSParameterAssert(objects);
    NSParameterAssert(sortDescriptors);
    
    CFIndex idx = CFArrayGetCount((CFArrayRef)objects);
    while(idx--)
        [self insertObject:(id)CFArrayGetValueAtIndex((CFArrayRef)objects, idx) inArraySortedUsingDescriptors:sortDescriptors];
}

- (void)mergeSortUsingDescriptors:(NSArray *)sortDescriptors;
{
    [self setArray:[self sortedArrayUsingMergesortWithDescriptors:sortDescriptors]];
}

@end

@interface NSSortDescriptor (Mergesort)

- (NSComparisonResult)compareEndObject:(id)object1 toEndObject:(id)object2;

@end

#pragma mark -
#pragma mark NSSortDescriptor subclass performance improvements


@implementation NSSortDescriptor (Mergesort)

/* The objects an NSSortDescriptor receives in compareObject:toObject: are not the objects that will be compared; you need to call valueForKeyPath: on them.  Unfortunately, this is really inefficient, and also precludes caching on the data end, since the sort descriptor would then call valueForKeyPath: again.  Hence, we add this method to compare the results of valueForKeyPath:, which expects the objects that will be passed to the comparator selector directly.  This gives subclasses an override point that still allows data-side caching of valueForKeyPath: for efficiency.
*/
- (NSComparisonResult)compareEndObject:(id)object1 toEndObject:(id)object2;
{    
    
    typedef NSComparisonResult (*compareIMP)(id, SEL, id);    

    SEL theSelector = [self selector];
    BOOL isAscending = [self ascending];
    compareIMP comparator = (compareIMP)[object1 methodForSelector:theSelector];
    NSComparisonResult result = comparator(object1, theSelector, object2);
    
    return isAscending ? result : (result *= -1);
}

@end

@implementation NSArray (Mergesort)

// statics used to call an Obj-C method from the BSD sort comparator
static id __sort = nil;
static SEL __selector = NULL;

// for thread safe usage of the cache (since we use static variables)
static NSLock *sortingLock = nil;

// typedef used for NSArray sorting category
typedef NSComparisonResult (*comparatorIMP)(id, SEL, id, id);    
static comparatorIMP __comparator = NULL;

// structure used for mapping objects to the value which will be passed to -[NSSortDescriptor compareEndObject:toEndObject:]
typedef struct _BDSortCacheValue {
    id sortValue;     // result of valueForKeyPath:
    id object;        // object in array
} BDSortCacheValue;

// this function may be passed to a stdlib mergesort/qsort function
static inline int __BDCompareSortCacheValues(const void *a, const void *b)
{
    return __comparator(__sort, __selector, ((BDSortCacheValue *)a)->sortValue, ((BDSortCacheValue *)b)->sortValue);
}

// for multiple sort descriptors; finds ranges of objects compare NSOrderedSame (concept from GNUStep's NSSortDescriptor)
static inline NSRange * __BDFindEqualRanges(BDSortCacheValue *buf, NSRange searchRange, NSRange *equalRanges, unsigned int *numRanges, NSZone *zone)
{
    unsigned i = searchRange.location, j;
    unsigned bufLen = NSMaxRange(searchRange);
    *numRanges = 0;
    if(bufLen > 1){
        while(i < bufLen - 1){
            for(j = i + 1; j < bufLen && __BDCompareSortCacheValues(&buf[i], &buf[j]) == 0; j++);
            if(j - i > 1){
                (*numRanges)++;
                equalRanges = (NSRange *)NSZoneRealloc(zone, equalRanges, (*numRanges) * sizeof(NSRange));
                equalRanges[(*numRanges) - 1].location = i;
                equalRanges[(*numRanges) - 1].length = j - i;
//                NSLog(@"equalityRange of %@", NSStringFromRange(NSMakeRange(i, j-i)));
//                NSLog(@"objects are %@ and %@", (BDSortCacheValue *)(&buf[i])->sortValue, (BDSortCacheValue *)(&buf[j-1])->sortValue);
                i = j;
            } else {
                i++;
            }
        }
    }
    return equalRanges;
}

#if defined (OMNI_ASSERTIONS_ON)

// for debugging only; prints a sort cache buffer (#ifdefed to avoid compiler warning)
static void print_buffer(BDSortCacheValue *buf, unsigned count, NSString *msg){
    // print the array before using the second sort descriptor...
    NSMutableArray *new = [[NSMutableArray alloc] initWithCapacity:count];
    BDSortCacheValue value;
    unsigned i;
    for(i = 0; i < count; i++){
        value = buf[i];
        [new addObject:value.object];
    }
    NSLog(@"%@: \n%@", msg, new);
    [new release];
}
#endif

// initialize the static variables
static inline void __BDSetupStaticsForDescriptor(NSSortDescriptor *sort)
{
    __sort = sort;
    __selector = @selector(compareEndObject:toEndObject:);
    __comparator = (comparatorIMP)[__sort methodForSelector:__selector];
}

// clear the static variables
static inline void __BDClearStatics()
{
    __sort = nil;
    __selector = NULL;
    __comparator = NULL;
}

+ (void)didLoad
{
    if(nil == sortingLock)
        sortingLock = [[NSLock alloc] init];
}

- (id)sortedArrayUsingMergesortWithDescriptors:(NSArray *)descriptors;
{
    [sortingLock lock];
    NSZone *zone = [self zone];
    size_t count = [self count];
    size_t size = sizeof(BDSortCacheValue);
    
    BDSortCacheValue *cache = (BDSortCacheValue *)NSZoneMalloc(zone, count * size);
    BDSortCacheValue aValue;
    
    unsigned int i, sortIdx = 0, numberOfDescriptors = [descriptors count];
    
    // first "equal range" is considered to be the entire array
    NSRange *equalRanges = (NSRange *)NSZoneMalloc(zone, 1 * sizeof(NSRange));
    equalRanges[0].location = 0;
    equalRanges[0].length = count;
    unsigned numberOfEqualRanges = 1;
    
    for(i = 0; i < count; i++){
        
        // we add the actual object to the cache, which is basically a trivial dictionary
        // mergesort/qsort will sort the array of structures for us, so sortValue and object stay matched up
        aValue.object = [self objectAtIndex:i];
        
        // this is handled later, per-key, so just initialize it
        aValue.sortValue = nil;
        
        // add objects to sort cache in current (unsorted) order
        cache[i] = aValue;
    }
    
    // for each sort descriptor, cache the valueForKeyPath: result, then determine the ranges of equal (ordered same) objects
    for(sortIdx = 0; sortIdx < numberOfDescriptors && NULL != equalRanges; sortIdx++){
        
        // temporary (local to this loop)
        unsigned rangeIdx;
        
        // setup the statics for this descriptor, so we can use the sort functions
        __BDSetupStaticsForDescriptor([descriptors objectAtIndex:sortIdx]);
        
        NSString *keyPath = [__sort key];
        
        for(rangeIdx = 0; rangeIdx < numberOfEqualRanges; rangeIdx++){
            
            // this is a range of the array that needs to be sorted
            NSRange sortRange = equalRanges[rangeIdx];
            
            // update cache for objects in equality range(s)
            // only the sortValue needs to change, as it's dependent on the key path
            unsigned maxRange = NSMaxRange(sortRange);
            for(i = sortRange.location; i < maxRange; i++)
                ((BDSortCacheValue *)&cache[i])->sortValue = [cache[i].object valueForKeyPath:keyPath];
            
            // mergesort seems faster than qsort for my casual testing with NSString/NSNumber instances
            mergesort(&cache[sortRange.location], sortRange.length, size, __BDCompareSortCacheValues);
        }
        
        // find equal ranges based on the current descriptor, if we have another sort descriptor to process
        if(sortIdx + 1 < numberOfDescriptors){            
            NSRange *newEqualRanges = NULL;
            unsigned newNumberOfRanges = 0;
            
            // don't check the entire array; only previously equal ranges (of course, for the second sort descriptor, this will still cover the entire array)
            for(rangeIdx = 0; rangeIdx < numberOfEqualRanges; rangeIdx++)
                newEqualRanges = __BDFindEqualRanges(cache, equalRanges[rangeIdx], newEqualRanges, &newNumberOfRanges, zone);
            
            NSZoneFree(zone, equalRanges);
            equalRanges = newEqualRanges;
            numberOfEqualRanges = newNumberOfRanges;
        }
        
        __BDClearStatics();
    }
        
    if(equalRanges) NSZoneFree(zone, equalRanges);
    
    // our array of structures is now sorted correctly, so we just loop through it and create an array with the contents
    NSMutableArray *new = [[NSMutableArray alloc] initWithCapacity:count];
    for(i = 0; i < count; i++){
        aValue = cache[i];
        [new addObject:aValue.object];
    }
    
    NSZoneFree(zone, cache);
    [sortingLock unlock];
    return [new autorelease];
}

@end

#pragma mark -
#pragma mark Posing Classes

@interface BDSKArray : NSArray @end

#import <OmniBase/assertions.h>

@implementation BDSKArray

/* ARM:  Since Foundation implements objectsAtIndexes: on 10.4+, we just ignore this implementation, which is crude anyway.  We could also implement this using a different method name in a category, e.g. "objectsAtArrayIndexes:", but that's annoying to maintain, and we'd have to check a variable each time to get the 10.4 implementation.  What I really want is a way to conditionally add a category, but can't figure out how to do that.
*/

+ (void)performPosing;
{
    if(floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_3)
        class_poseAs(self, NSClassFromString(@"NSArray"));
}

- (NSArray *)objectsAtIndexes:(NSIndexSet *)indexes;
{
    OBASSERT(floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_3);
    NSParameterAssert(indexes != nil);
    
    // could be more clever/efficient by using getObjects:range:
    unsigned index;
    index = [indexes firstIndex];
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:[indexes count]];
    
    while(index != NSNotFound){
        [array addObject:(id)CFArrayGetValueAtIndex((CFArrayRef)self, index)];
        index = [indexes indexGreaterThanIndex:index];
    }
    
    return [array autorelease];
}      

@end

@interface BDSKMutableArray : NSMutableArray @end

@implementation BDSKMutableArray

+ (void)performPosing;
{
    if(floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_3)
        class_poseAs(self, NSClassFromString(@"NSMutableArray"));
}

- (void)insertObjects:(NSArray *)objects atIndexes:(NSIndexSet *)indexes
{
    OBASSERT(floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_3);
	OBASSERT([objects count] == [indexes count]);
    NSParameterAssert(indexes != nil);

    unsigned index = [indexes firstIndex];
    unsigned i = 0;
    while (index != NSNotFound) {
        [self insertObject:[objects objectAtIndex:i++] atIndex:index];
        index = [indexes indexGreaterThanIndex:index];
    }
}

- (void)removeObjectsAtIndexes:(NSIndexSet *)indexes;
{
    OBASSERT(floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_3);
    NSParameterAssert(indexes != nil);

    // remove from the end of the array; removing from the beginning will change the indexing
    unsigned index = [indexes lastIndex];
    while (index != NSNotFound) {
        [self removeObjectAtIndex:index];
        index = [indexes indexLessThanIndex:index];
    }
}

@end
