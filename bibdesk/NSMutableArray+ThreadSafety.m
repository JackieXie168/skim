//
//  NSMutableArray+ThreadSafety.m
//  BibDesk
//
//  Created by Adam Maxwell on 01/27/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "NSMutableArray+ThreadSafety.h"


@implementation NSMutableArray (ThreadSafety)

- (void)addObject:(id)anObject usingLock:(NSLock *)aLock{
    
    [aLock lock];
    [[anObject retain] autorelease];
    [self addObject:anObject];
    [aLock unlock];    
}

- (void)insertObject:(id)anObject atIndex:(unsigned)index usingLock:(NSLock *)aLock{
    
    [aLock lock];
    [[anObject retain] autorelease];
    [self insertObject:anObject atIndex:index];
    [aLock unlock];    
}

- (id)objectAtIndex:(unsigned)index usingLock:(NSLock *)aLock{
    
    id result;
    
    [aLock lock];
    result = [self objectAtIndex:index];
    [[result retain] autorelease];
    [aLock unlock];
    
    return result;
}
    
- (void)removeObjectAtIndex:(unsigned)index usingLock:(NSLock *)aLock{
    
    [aLock lock];
    [self removeObjectAtIndex:index];
    [aLock unlock];
}

- (void)removeObject:(id)anObject usingLock:(NSLock *)aLock{
    
    [aLock lock];
    [self removeObject:anObject];
    [aLock unlock];
}

- (BOOL)containsObject:(id)anObject usingLock:(NSLock *)aLock{
    
    BOOL yn;
    
    [aLock lock];
    [[anObject retain] autorelease];
    yn = [self containsObject:anObject];
    [aLock unlock];
    
    return yn;
}

- (void)removeObjectIdenticalTo:(id)anObject usingLock:(NSLock *)aLock{
    
    [aLock lock];
    [self removeObjectIdenticalTo:anObject];
    [aLock unlock];
}

- (void)addObjectsFromArray:(NSArray *)anArray usingLock:(NSLock *)aLock{
    
    [aLock lock];
    [[anArray retain] autorelease];
    [self addObjectsFromArray:anArray];
    [aLock unlock];
}

- (void)removeAllObjectsUsingLock:(NSLock *)aLock{
    
    [aLock lock];
    [self removeAllObjects];
    [aLock unlock];
}
    
@end
