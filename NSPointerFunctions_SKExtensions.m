//
//  NSPointerFunctions_SKExtensions.m
//  Skim
//
//  Created by Christiaan on 9/23/09.
/*
 This software is Copyright (c) 2009
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

#import "NSPointerFunctions_SKExtensions.h"


@implementation NSPointerFunctions (SKExtensions)

static NSUInteger floatSizeFunction(const void *item) { return sizeof(CGFloat); }

static NSUInteger pointSizeFunction(const void *item) { return sizeof(NSPoint); }

static NSUInteger rectSizeFunction(const void *item) { return sizeof(NSRect); }

static NSUInteger rangeSizeFunction(const void *item) { return sizeof(NSRange); }

static NSString *floatDescriptionFunction(const void *item) { return [NSString stringWithFormat:@"%f", *(CGFloat *)item]; }

static NSString *pointDescriptionFunction(const void *item) { return NSStringFromPoint(*(NSPointPointer)item); }

static NSString *rectDescriptionFunction(const void *item) { return NSStringFromRect(*(NSRectPointer)item); }

static NSString *rangeDescriptionFunction(const void *item) { return [NSString stringWithFormat:@"(%lu, %lu)", (unsigned long)((*(NSRange *)item).location), (unsigned long)((*(NSRange *)item).length)]; }

#define STACK_BUFFER_SIZE 256

static BOOL caseInsensitiveStringEqual(const void *item1, const void *item2, NSUInteger (*size)(const void *item)) {
    return (CFStringGetLength(item1) == CFStringGetLength(item2) && CFStringCompareWithOptions(item1, item2, CFRangeMake(0, CFStringGetLength(item1)), kCFCompareCaseInsensitive) == kCFCompareEqualTo);
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

+ (id)strongObjectPointerFunctions {
    return [self pointerFunctionsWithOptions:NSPointerFunctionsStrongMemory | NSPointerFunctionsObjectPersonality];
}

+ (id)integerPointerFunctions {
    return [self pointerFunctionsWithOptions:NSPointerFunctionsOpaqueMemory | NSPointerFunctionsIntegerPersonality];
}

+ (id)structPointerFunctionsWithSizeFunction:(NSUInteger (*)(const void *))sizeFunction descriptionFunction:(NSString *(*)(const void *))descriptionFunction {
    NSPointerFunctions *pointerFunctions = [self pointerFunctionsWithOptions:NSPointerFunctionsMallocMemory | NSPointerFunctionsCopyIn | NSPointerFunctionsStructPersonality];
    [pointerFunctions setSizeFunction:sizeFunction];
    [pointerFunctions setDescriptionFunction:descriptionFunction];
    return pointerFunctions;
}

+ (id)floatPointerFunctions {
    return [self structPointerFunctionsWithSizeFunction:&floatSizeFunction descriptionFunction:&floatDescriptionFunction];
}

+ (id)pointPointerFunctions {
    return [self structPointerFunctionsWithSizeFunction:&pointSizeFunction descriptionFunction:&pointDescriptionFunction];
}

+ (id)rectPointerFunctions {
    return [self structPointerFunctionsWithSizeFunction:&rectSizeFunction descriptionFunction:&rectDescriptionFunction];
}

+ (id)rangePointerFunctions {
    return [self structPointerFunctionsWithSizeFunction:&rangeSizeFunction descriptionFunction:&rangeDescriptionFunction];
}

+ (id)caseInsensitiveStringPointerFunctions {
    NSPointerFunctions *pointerFunctions = [self pointerFunctionsWithOptions:NSPointerFunctionsStrongMemory | NSPointerFunctionsObjectPersonality];
    [pointerFunctions setIsEqualFunction:&caseInsensitiveStringEqual];
    [pointerFunctions setHashFunction:&caseInsensitiveStringHash];
    return pointerFunctions;
}

@end
