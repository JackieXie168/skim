//
//  NSMutableDictionary+ThreadSafety.m
//  Bibdesk
//
//  Created by Adam Maxwell on 01/27/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "NSMutableDictionary+ThreadSafety.h"


@implementation NSMutableDictionary (ThreadSafety)

- (id)objectForKey:(id)aKey usingLock:(NSLock *)aLock{

    id result;
    
    [aLock lock];
    result = [self objectForKey:aKey];
    [[result retain] autorelease];
    [aLock unlock];
    
    return result;
}

- (void)removeObjectForKey:(id)aKey usingLock:(NSLock *)aLock{
    
    [aLock lock];
    [self removeObjectForKey:aKey];
    [aLock unlock];
}

- (void)setObject:(id)anObject forKey:(id)aKey usingLock:(NSLock *)aLock{
    
    [aLock lock];
    [[anObject retain] autorelease];
    [self setObject:anObject forKey:aKey];
    [aLock unlock];
}

- (NSArray *)allKeysUsingLock:(NSLock *)aLock{
    
    NSArray *result;
    
    [aLock lock];
    result = [self allKeys];
    [[result retain] autorelease];
    [aLock unlock];
    
    return result;
}

- (void)removeObjectsForKeys:(NSArray *)keyArray usingLock:(NSLock *)aLock{
    
    [aLock lock];
    [self removeObjectsForKeys:keyArray];
    [aLock unlock];
}

@end
