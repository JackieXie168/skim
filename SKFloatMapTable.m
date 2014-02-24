//
//  SKFloatMapTable.m
//  Skim
//
//  Created by Christiaan Hofman on 9/24/09.
/*
 This software is Copyright (c) 2009-2014
 Christiaan Hofman. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

 - Neither the name of Christiaan Hofman nor the names of any
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

#import "SKFloatMapTable.h"


@implementation SKFloatMapTable

- (id)init {
    self = [super init];
    if (self) {
        table = NSCreateMapTable(NSObjectMapKeyCallBacks, NSOwnedPointerMapValueCallBacks, 0);
    }
    return self;
}

- (void)dealloc {
    NSFreeMapTable(table);
    [super dealloc];
}

- (NSString *)description {
    NSMutableString *desc = [NSMutableString stringWithFormat:@"<%@> { ", [self class]];
    for (id key in NSAllMapTableKeys(table))
        [desc appendFormat:@"%@ -> %f; ", key, *(CGFloat *)NSMapGet(table, key)];
    [desc appendString:@"}"];
    return desc;
}

- (NSUInteger)count {
    return NSCountMapTable(table);
}

- (BOOL)hasKey:(id)key {
    return NULL != NSMapGet(table, key);
}

- (CGFloat)floatForKey:(id)key {
    CGFloat *floatPtr = (CGFloat *)NSMapGet(table, key);
    return floatPtr == NULL ? 0.0 : *floatPtr;
}

- (void)setFloat:(CGFloat)aFloat forKey:(id)key {
    CGFloat *floatPtr = NSZoneMalloc([self zone], sizeof(CGFloat));
    *floatPtr = aFloat;
    NSMapInsert(table, key, floatPtr);
}

- (void)removeFloatForKey:(id)key {
    NSMapRemove(table, key);
}

- (void)removeAllFloats {
    NSResetMapTable(table);
}

@end
