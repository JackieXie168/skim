//
//  NSMapTable_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 10/19/09.
/*
 This software is Copyright (c) 2009-2011
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

#import "NSMapTable_SKExtensions.h"


@implementation NSMapTable (SKExtensions)

#define STACK_BUFFER_SIZE 256

static BOOL caseInsensitiveStringEqual(const void *item1, const void *item2, NSUInteger (*size)(const void *item)) {
    return CFStringCompare(item1, item2, kCFCompareCaseInsensitive | kCFCompareNonliteral) == kCFCompareEqualTo;
}

static NSUInteger caseInsensitiveStringHash(const void *item, NSUInteger (*size)(const void *item)) {
    if(item == NULL) return 0;
    
    NSUInteger hash = 0;
    CFAllocatorRef allocator = CFGetAllocator(item);
    CFIndex len = CFStringGetLength(item);
    
    // use a generous length, in case the lowercase changes the number of characters
    UniChar *buffer, stackBuffer[STACK_BUFFER_SIZE];
    if (len + 10 >= STACK_BUFFER_SIZE)
        buffer = (UniChar *)CFAllocatorAllocate(allocator, (len + 10) * sizeof(UniChar), 0);
    else
        buffer = stackBuffer;
    CFStringGetCharacters(item, CFRangeMake(0, len), buffer);
    
    // If we create the string with external characters, CFStringGetCharactersPtr is guaranteed to succeed; since we're going to call CFStringGetCharacters anyway in fastHash if CFStringGetCharactsPtr fails, let's do it now when we lowercase the string
    CFMutableStringRef mutableString = CFStringCreateMutableWithExternalCharactersNoCopy(allocator, buffer, len, len + 10, (buffer != stackBuffer ? allocator : kCFAllocatorNull));
    CFStringLowercase(mutableString, NULL);
    hash = [(id)mutableString hash];
    // if we used the allocator, this should free the buffer for us
    CFRelease(mutableString);
    return hash;
}

- (id)initForCaseInsensitiveStringKeys {
    NSPointerFunctions *keyPointerFunctions = [NSPointerFunctions pointerFunctionsWithOptions:NSPointerFunctionsStrongMemory | NSPointerFunctionsObjectPersonality];
    [keyPointerFunctions setIsEqualFunction:&caseInsensitiveStringEqual];
    [keyPointerFunctions setHashFunction:&caseInsensitiveStringHash];
    NSPointerFunctions *valuePointerFunctions = [NSPointerFunctions pointerFunctionsWithOptions:NSPointerFunctionsStrongMemory | NSPointerFunctionsObjectPersonality];
    return [self initWithKeyPointerFunctions:keyPointerFunctions valuePointerFunctions:valuePointerFunctions capacity:0];
}

@end
