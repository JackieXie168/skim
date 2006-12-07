//
//  NSMutableArray+ThreadSafety.m
//  BibDesk
//
//  Created by Adam Maxwell on 01/27/05.
/*
 This software is Copyright (c) 2005
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

#import "NSMutableArray+ThreadSafety.h"
#import "NSArray_BDSKExtensions.h"


@implementation NSMutableArray (ThreadSafety)

- (id)copyUsingLock:(NSLock *)aLock{
    
	id copy;
	
	[aLock lock];
	copy = [self copy];
    [aLock unlock];
	return copy;
}

- (unsigned)countUsingLock:(NSLock *)aLock{
    
	unsigned count;
	
	[aLock lock];
	count = [self count];
    [aLock unlock];
	return count;
}

- (id)objectAtIndex:(unsigned)index usingLock:(NSLock *)aLock{
    
    id result;
    
    [aLock lock];
    result = [self objectAtIndex:index];
    [[result retain] autorelease];
    [aLock unlock];
    
    return result;
}

- (id)objectsAtIndexes:(NSIndexSet *)indexes usingLock:(NSLock *)aLock{
    
    NSArray *result;
    
    [aLock lock];
    result = [self objectsAtIndexes:indexes];
    [aLock unlock];
    
    return result;
}

- (id)lastObjectUsingLock:(NSLock *)aLock{
    
    id result;
    
    [aLock lock];
    result = [self lastObject];
    [[result retain] autorelease];
    [aLock unlock];
    
    return result;
}


- (void)addObject:(id)anObject usingLock:(NSLock *)aLock{
    
    [aLock lock];
    [anObject retain];
    [self addObject:anObject];
    [anObject release];
    [aLock unlock];    
}

- (void)addObjectsFromArray:(NSArray *)anArray usingLock:(NSLock *)aLock{
    
    [aLock lock];
    [anArray retain];
    [self addObjectsFromArray:anArray];
    [anArray release];
    [aLock unlock];
}

- (void)insertObject:(id)anObject atIndex:(unsigned)index usingLock:(NSLock *)aLock{
    
    [aLock lock];
    [anObject retain];
    [self insertObject:anObject atIndex:index];
    [anObject release];
    [aLock unlock];    
}

- (void)insertObjects:(NSArray *)objects atIndexes:(NSIndexSet *)indexes usingLock:(NSLock *)aLock{
    
	[aLock lock];
    [objects retain];
	[self insertObjects:objects atIndexes:indexes];
	[objects release];
	[aLock unlock];
}
    
- (void)removeObjectAtIndex:(unsigned)index usingLock:(NSLock *)aLock{
    
    [aLock lock];
    [self removeObjectAtIndex:index];
    [aLock unlock];
}
    
- (void)removeObjectsAtIndexes:(NSIndexSet *)indexes usingLock:(NSLock *)aLock{
    
	[aLock lock];
	[self removeObjectsAtIndexes:indexes];
	[aLock unlock];
}

- (void)removeObject:(id)anObject usingLock:(NSLock *)aLock{
    
    [aLock lock];
    [self removeObject:anObject];
    [aLock unlock];
}

- (void)removeObjectIdenticalTo:(id)anObject usingLock:(NSLock *)aLock{
    
    [aLock lock];
    [self removeObjectIdenticalTo:anObject];
    [aLock unlock];
}

- (void)removeAllObjectsUsingLock:(NSLock *)aLock{
    
    [aLock lock];
    [self removeAllObjects];
    [aLock unlock];
}

- (void)setArray:(NSArray *)anArray usingLock:(NSLock *)aLock{
    
    [aLock lock];
    [self setArray:anArray];
    [aLock unlock];
	
}

- (BOOL)containsObject:(id)anObject usingLock:(NSLock *)aLock{
    
    BOOL yn;
    
    [aLock lock];
    [anObject retain];
    yn = [self containsObject:anObject];
    [anObject release];
    [aLock unlock];
    
    return yn;
}

- (unsigned)indexOfObjectIdenticalTo:(id)anObject usingLock:(NSLock *)aLock{
    
    unsigned index;
    [aLock lock];
    [anObject retain];
    index = [self indexOfObjectIdenticalTo:anObject];
    [anObject release];
    [aLock unlock];
    return index;
}

// this may give unexpected results if you have multiple instances of an object in an array; it will return only the lowest index
- (NSIndexSet *)indexesOfObjectsIdenticalTo:(NSArray *)objects usingLock:(NSLock *)aLock;
{
    NSIndexSet *indexes;;
    [aLock lock];
	indexes = [self indexesOfObjectsIdenticalTo:objects];
    [aLock unlock];
    return indexes;
}

- (NSEnumerator *)objectEnumeratorUsingLock:(NSLock *)aLock{
	
	[aLock lock];
	NSArray *array = [self copy];
	[aLock unlock];
	return [[array autorelease] objectEnumerator];
}

- (void)makeObjectsPerformSelector:(SEL)aSelector withObject:(id)anObject usingLock:(NSLock *)aLock{
    [aLock lock];
	[self makeObjectsPerformSelector:aSelector withObject:anObject];
    [aLock unlock];
}

- (void)makeObjectsPerformSelector:(SEL)aSelector usingLock:(NSLock *)aLock{
    [aLock lock];
	[self makeObjectsPerformSelector:aSelector];
    [aLock unlock];
}

- (void)sortUsingSelector:(SEL)comparator ascending:(BOOL)ascend usingLock:(NSLock *)aLock;
{
    [aLock lock];
    [self sortUsingSelector:comparator];
    [aLock unlock];
    
    if(ascend)
        return;
    
    [aLock lock];
    
    int rhIndex = ([self count] - 1);
    int lhIndex = 0;
    
    while( (rhIndex - lhIndex) > 0)
        [self exchangeObjectAtIndex:rhIndex-- withObjectAtIndex:lhIndex++];
    
    [aLock unlock];

}

- (void)sortUsingDescriptors:(NSArray *)sortDescriptors usingLock:(NSLock *)aLock;
{
    [aLock lock];
    [self sortUsingDescriptors:sortDescriptors];
    [aLock unlock];
}

- (void)removeObject:(id)obj usingReadWriteLock:(id <OFReadWriteLocking>)aLock;
{
    [aLock lockForWriting];
    [self removeObject:obj];
    [aLock unlockForWriting];
}

@end
