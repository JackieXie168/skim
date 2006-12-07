//
//  NSMutableArray+ThreadSafety.h
//  BibDesk
//
//  Created by Adam Maxwell on 01/27/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//
//  From Apple TN2059
//

#import <Cocoa/Cocoa.h>


@interface NSMutableArray (ThreadSafety)

- (void)addObject:(id)anObject usingLock:(NSLock *)aLock;
- (void)insertObject:(id)anObject atIndex:(unsigned)index usingLock:(NSLock *)aLock;
- (id)objectAtIndex:(unsigned)index usingLock:(NSLock *)aLock;
- (void)removeObjectAtIndex:(unsigned)index usingLock:(NSLock *)aLock;
- (void)removeObject:(id)anObject usingLock:(NSLock *)aLock;
- (BOOL)containsObject:(id)anObject usingLock:(NSLock *)aLock;
- (void)removeObjectIdenticalTo:(id)anObject usingLock:(NSLock *)aLock;
- (void)addObjectsFromArray:(NSArray *)anArray usingLock:(NSLock *)aLock;
- (void)removeAllObjectsUsingLock:(NSLock *)aLock;

@end
