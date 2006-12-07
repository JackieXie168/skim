//
//  BDSKThreadSafeMutableDictionary.m
//  BibDesk
//
//  Created by Adam Maxwell on 01/27/05.
/*
 This software is Copyright (c) 2005, 2006
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

#import "BDSKThreadSafeMutableDictionary.h"

@implementation BDSKThreadSafeMutableDictionary

- (id)init {
    if (self = [super init]) {
        embeddedDictionary = [[NSMutableDictionary allocWithZone:[self zone]] init];
		pthread_rwlock_init(&rwlock, NULL);
    }
    return self;
}

- (id)initWithCapacity:(unsigned)capacity {
    if (self = [super init]) {
        embeddedDictionary = [[NSMutableDictionary allocWithZone:[self zone]] initWithCapacity:capacity];
		pthread_rwlock_init(&rwlock, NULL);
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    pthread_rwlock_rdlock(&rwlock);
    id copy = [embeddedDictionary copyWithZone:zone];
    pthread_rwlock_unlock(&rwlock);
	return copy;
}

- (id)mutableCopyWithZone:(NSZone *)zone {
    pthread_rwlock_rdlock(&rwlock);
	id copy = [[[self class] allocWithZone:zone] initWithDictionary:embeddedDictionary];
    pthread_rwlock_unlock(&rwlock);
	return copy;
}

- (void)dealloc {
    pthread_rwlock_wrlock(&rwlock);
	[embeddedDictionary release];
    embeddedDictionary = nil;
    pthread_rwlock_unlock(&rwlock);
    pthread_rwlock_destroy(&rwlock);
	[super dealloc];
}

- (unsigned)count {
    pthread_rwlock_rdlock(&rwlock);
	unsigned count = [embeddedDictionary count];
    pthread_rwlock_unlock(&rwlock);
    return count;
}

- (id)objectForKey:(id)key {
    pthread_rwlock_rdlock(&rwlock);
    id object = [[[embeddedDictionary objectForKey:key] retain] autorelease];
    pthread_rwlock_unlock(&rwlock);
    return object;
}

- (NSEnumerator *)keyEnumerator {
    pthread_rwlock_rdlock(&rwlock);
    // copy in case it returns internal state
	NSArray *keys = [[embeddedDictionary allKeys] copy];
    pthread_rwlock_unlock(&rwlock);
    NSEnumerator *enumerator = [keys objectEnumerator];
    [keys release];
	return enumerator;
}

- (void)setObject:(id)object forKey:(id)key {
    pthread_rwlock_wrlock(&rwlock);
    [object retain]; // @@ retain the key?  I don't think Apple's sample did...
	[embeddedDictionary setObject:object forKey:key];
    [object release];
    pthread_rwlock_unlock(&rwlock);
}

- (void)removeObjectForKey:(id)key {
    pthread_rwlock_wrlock(&rwlock);
    id obj = [[embeddedDictionary objectForKey:key] retain];
	[embeddedDictionary removeObjectForKey:key];
    [obj autorelease];
    pthread_rwlock_unlock(&rwlock);
}

@end
