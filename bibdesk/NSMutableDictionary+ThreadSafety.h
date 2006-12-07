//
//  NSMutableDictionary+ThreadSafety.h
//  Bibdesk
//
//  Created by Adam Maxwell on 01/27/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//
//  From Apple TN2059
//

#import <Cocoa/Cocoa.h>


@interface NSMutableDictionary (ThreadSafety)

- (id)objectForKey:(id)aKey usingLock:(NSLock *)aLock;
- (void)removeObjectForKey:(id)aKey usingLock:(NSLock *)aLock;
- (void)setObject:(id)anObject forKey:(id)aKey usingLock:(NSLock *)aLock;
- (NSArray *)allKeysUsingLock:(NSLock *)aLock;
- (void)removeObjectsForKeys:(NSArray *)keyArray usingLock:(NSLock *)aLock;

@end
