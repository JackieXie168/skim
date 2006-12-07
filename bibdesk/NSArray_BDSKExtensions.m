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

/* Assumes the array is already sorted to insert the object quickly in the right place */
/* (new objects are inserted just after old objects that are NSOrderedSame) */
- (void)insertObject:anObject inArraySortedUsingDescriptors:(NSArray *)sortDescriptors;
{
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

#warning multiple descriptors
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

@end

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

    // remove from the end of the array; removing from the beginning will change the indexing
    unsigned index = [indexes lastIndex];
    while (index != NSNotFound) {
        [self removeObjectAtIndex:index];
        index = [indexes indexLessThanIndex:index];
    }
}

@end
