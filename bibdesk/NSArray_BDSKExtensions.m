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

- (NSArray *)arrayDroppingFirstObject;
{
    return [self count] ? [self subarrayWithRange:NSMakeRange(1, [self count] - 1)] : self;
}

- (NSArray *)objectsAtIndexSpecifiers:(NSArray *)indexes;
{
    NSMutableArray *array = [NSMutableArray array];
    NSEnumerator *isEnum = [indexes objectEnumerator];
    NSIndexSpecifier *is;
    while(is = [isEnum nextObject])
        [array addObject:[self objectAtIndex:[is index]]];
    return array;
}

/* theSelector should be either indexOfObject:inRange: or indexOfObjectIdenticalTo:inRange */
static inline 
NSIndexSet *__BDIndexesOfObjectsUsingSelector(NSArray *arrayToSearch, NSArray *objectsToFind, SEL theSelector)
{
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    unsigned index;
    NSEnumerator *objEnum = [objectsToFind objectEnumerator];
	id obj;
    unsigned count = [arrayToSearch count];
    
    NSRange range = NSMakeRange(0, count);
    
    typedef unsigned int (*indexIMP)(id, SEL, id, NSRange);
    indexIMP indexOfObjectInRange = (indexIMP)[arrayToSearch methodForSelector:theSelector];
    
    while(obj = [objEnum nextObject]){
        
        // see if we have the first occurrence of this object
        index = indexOfObjectInRange(arrayToSearch, theSelector, obj, range);
        
        while(index != NSNotFound){ 
            [indexes addIndex:index];
            
            // shift search range to the right
            range.location = index + 1;
            range.length = count - index - 1;
            
            // NSArray seems to handle out-of-range here, but we'll be careful anyway
            index = NSMaxRange(range) < count ? indexOfObjectInRange(arrayToSearch, theSelector, obj, range) : NSNotFound;
        }
        
        // resetting to max range is always valid
        range.location = 0;
        range.length = count;
    }
    return indexes;        
}

- (NSIndexSet *)indexesOfObjects:(NSArray *)objects;
{
    return __BDIndexesOfObjectsUsingSelector(self, objects, @selector(indexOfObject:inRange:));
}
    
- (NSIndexSet *)indexesOfObjectsIdenticalTo:(NSArray *)objects;
{
    return __BDIndexesOfObjectsUsingSelector(self, objects, @selector(indexOfObjectIdenticalTo:inRange:));
}

- (id)sortedArrayUsingMergesortWithDescriptors:(NSArray *)sortDescriptors;
{
    NSMutableArray *array = [self mutableCopy];
    [array mergeSortUsingDescriptors:sortDescriptors];
    return [array autorelease];
}

@end

#pragma mark -
#pragma mark NSSortDescriptor subclass performance improvements

@interface NSSortDescriptor (Mergesort)

- (NSComparisonResult)compareEndObject:(id)object1 toEndObject:(id)object2;

@end

@implementation NSSortDescriptor (Mergesort)

// The objects an NSSortDescriptor receives in compareObject:toObject: are not the objects that will be compared; you need to call valueForKeyPath: on them.
// Unfortunately, this is really inefficient, and also precludes caching on the data end, since the sort descriptor would then call valueForKeyPath: again.
// Hence, we add this method to compare the results of valueForKeyPath:, which expects the objects that will be passed to the comparator selector directly.
// This gives subclasses an override point that still allows data-side caching of valueForKeyPath: for efficiency.
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

#pragma mark -

@implementation NSMutableArray (BDSKExtensions)

- (void)addNonDuplicateObjectsFromArray:(NSArray *)otherArray;
{
    NSEnumerator *objEnum = [otherArray objectEnumerator];
    id object;
    while(object = [objEnum nextObject]){
        if([self containsObject:object] == NO)
            [self addObject:object];
    }
}

- (void)addObjectsByMakingObjectsFromArray:(NSArray *)otherArray performSelector:(SEL)selector;
{
    NSEnumerator *objEnum = [otherArray objectEnumerator];
    id object;
    while(object = [objEnum nextObject])
        [self addObject:[object performSelector:selector]];
}

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

#pragma mark Merge sort

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

- (void)mergeSortUsingDescriptors:(NSArray *)sortDescriptors;
{
    [sortingLock lock];
    NSZone *zone = [self zone];
    size_t count = [self count];
    size_t size = sizeof(BDSortCacheValue);
    
    BDSortCacheValue *cache = (BDSortCacheValue *)NSZoneMalloc(zone, count * size);
    BDSortCacheValue aValue;
    
    unsigned int i, sortIdx = 0, numberOfDescriptors = [sortDescriptors count];
    
    // first "equal range" is considered to be the entire array
    NSRange *equalRanges = (NSRange *)NSZoneMalloc(zone, 1 * sizeof(NSRange));
    equalRanges[0].location = 0;
    equalRanges[0].length = count;
    unsigned numberOfEqualRanges = 1;
    
    for(i = 0; i < count; i++){
        
        // we add the actual object to the cache, which is basically a trivial dictionary
        // mergesort/qsort will sort the array of structures for us, so sortValue and object stay matched up
        aValue.object = [[self objectAtIndex:i] retain];
        
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
        __BDSetupStaticsForDescriptor([sortDescriptors objectAtIndex:sortIdx]);
        
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
    [self removeAllObjects];
    for(i = 0; i < count; i++){
        aValue = cache[i];
        [self addObject:aValue.object];
        [aValue.object release];
    }
    
    NSZoneFree(zone, cache);
    [sortingLock unlock];
}

@end
