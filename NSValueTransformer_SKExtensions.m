//
//  NSValueTransformer_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 4/2/08.
/*
 This software is Copyright (c) 2008-2014
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

#import "NSValueTransformer_SKExtensions.h"


@interface SKOneWayArrayTransformer : NSValueTransformer {
    NSValueTransformer *valueTransformer;
}
- (NSValueTransformer *)valueTransformer;
- (id)initWithValueTransformer:(NSValueTransformer *)aValueTransformer;
- (NSArray *)transformedArray:(NSArray *)array usingSelector:(SEL)selector;
@end

#pragma mark -

@interface SKTwoWayArrayTransformer : SKOneWayArrayTransformer
@end

#pragma mark -

@implementation SKOneWayArrayTransformer

+ (Class)transformedValueClass {
    return [NSArray class];
}

+ (BOOL)allowsReverseTransformation {
    return NO;
}

- (id)initWithValueTransformer:(NSValueTransformer *)aValueTransformer {
    self = [super init];
    if (self) {
        if (aValueTransformer) {
            valueTransformer = [aValueTransformer retain];
        } else {
            [self release];
            self = nil;
        }
    }
    return self;
}

- (id)init {
    return [self initWithValueTransformer:[[[NSValueTransformer alloc] init] autorelease]];
}

- (void)dealloc {
    SKDESTROY(valueTransformer);
    [super dealloc];
}

- (NSValueTransformer *)valueTransformer {
    return valueTransformer;
}

- (NSArray *)transformedArray:(NSArray *)array usingSelector:(SEL)selector {
    NSMutableArray *transformedArray = [NSMutableArray arrayWithCapacity:[array count]];
    for (id obj in array)
        [transformedArray addObject:[valueTransformer performSelector:selector withObject:obj] ?: [NSNull null]];
    return transformedArray;
}

- (id)transformedValue:(id)array {
    return [self transformedArray:array usingSelector:_cmd];
}

@end

#pragma mark -

@implementation SKTwoWayArrayTransformer

+ (BOOL)allowsReverseTransformation {
    return YES;
}

- (id)reverseTransformedValue:(id)array {
    return [self transformedArray:array usingSelector:_cmd];
}

@end

#pragma mark -

@implementation NSValueTransformer (SKExtensions)

+ (NSValueTransformer *)arrayTransformerWithValueTransformer:(NSValueTransformer *)valueTransformer {
    if ([[valueTransformer class] allowsReverseTransformation])
        return [[[SKTwoWayArrayTransformer alloc] initWithValueTransformer:valueTransformer] autorelease];
    else if (valueTransformer)
        return [[[SKOneWayArrayTransformer alloc] initWithValueTransformer:valueTransformer] autorelease];
    else
        return nil;
}

+ (NSValueTransformer *)arrayTransformerWithValueTransformerForName:(NSString *)name {
    return [self arrayTransformerWithValueTransformer:[self valueTransformerForName:name]];
}

@end
