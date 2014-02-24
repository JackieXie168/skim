//
//  NSPointerArray_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 9/23/09.
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

#import "NSPointerArray_SKExtensions.h"


@implementation NSPointerArray (SKExtensions)

static NSUInteger rectSizeFunction(const void *item) { return sizeof(NSRect); }

static NSUInteger rangeSizeFunction(const void *item) { return sizeof(NSRange); }

static NSString *rectDescriptionFunction(const void *item) { return NSStringFromRect(*(NSRectPointer)item); }

static NSString *rangeDescriptionFunction(const void *item) { return [NSString stringWithFormat:@"(%lu, %lu)", (unsigned long)(((NSRange *)item)->location), (unsigned long)(((NSRange *)item)->length)]; }

+ (id)rectPointerArray { return [[[self alloc] initForRectPointers] autorelease]; }

+ (id)rangePointerArray { return [[[self alloc] initForRangePointers] autorelease]; }

- (id)initForStructPointersWithSizeFunction:(NSUInteger (*)(const void *))sizeFunction descriptionFunction:(NSString *(*)(const void *))descriptionFunction {
    NSPointerFunctions *pointerFunctions = [NSPointerFunctions pointerFunctionsWithOptions:NSPointerFunctionsMallocMemory | NSPointerFunctionsCopyIn | NSPointerFunctionsStructPersonality];
    [pointerFunctions setSizeFunction:sizeFunction];
    [pointerFunctions setDescriptionFunction:descriptionFunction];
    return [self initWithPointerFunctions:pointerFunctions];
}

- (id)initForRectPointers {
    return [self initForStructPointersWithSizeFunction:&rectSizeFunction descriptionFunction:&rectDescriptionFunction];
}

- (id)initForRangePointers {
    return [self initForStructPointersWithSizeFunction:&rangeSizeFunction descriptionFunction:&rangeDescriptionFunction];
}

@end
