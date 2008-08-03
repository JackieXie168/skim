//
//  SKCFCallBacks.m
//  Skim
//
//  Created by Christiaan Hofman on 3/20/08.
/*
 This software is Copyright (c) 2008
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

#import "SKCFCallBacks.h"

#define STACK_BUFFER_SIZE 256

const void *SKNSObjectRetain(CFAllocatorRef allocator, const void *value) {
    return [(id)value retain];
}

void SKNSObjectRelease(CFAllocatorRef allocator, const void *value) {
    [(id)value release];
}

CFStringRef SKNSObjectCopyDescription(const void *value) {
    return (CFStringRef)[[(id)value description] retain];
}

Boolean SKCaseInsensitiveStringEqual(const void *value1, const void *value2) {
    return (CFStringCompareWithOptions(value1, value2, CFRangeMake(0, CFStringGetLength(value1)), kCFCompareCaseInsensitive) == kCFCompareEqualTo);
}

CFHashCode SKCaseInsensitiveStringHash(const void *value)
{
    if(value == NULL) return 0;
    
    CFAllocatorRef allocator = CFGetAllocator(value);
    CFIndex len = CFStringGetLength(value);
    
    // use a generous length, in case the lowercase changes the number of characters
    UniChar *buffer, stackBuffer[STACK_BUFFER_SIZE];
    if(len + 10 >= STACK_BUFFER_SIZE) {
        buffer = (UniChar *)CFAllocatorAllocate(allocator, (len + 10) * sizeof(UniChar), 0);
    } else {
        buffer = stackBuffer;
    }
    CFStringGetCharacters(value, CFRangeMake(0, len), buffer);
    
    // If we create the string with external characters, CFStringGetCharactersPtr is guaranteed to succeed; since we're going to call CFStringGetCharacters anyway in fastHash if CFStringGetCharactsPtr fails, let's do it now when we lowercase the string
    CFMutableStringRef mutableString = CFStringCreateMutableWithExternalCharactersNoCopy(allocator, buffer, len, len + 10, (buffer != stackBuffer ? allocator : kCFAllocatorNull));
    CFStringLowercase(mutableString, NULL);
    
    // Golden ratio - arbitrary start value to avoid mapping all 0's to all 0's
    // or anything like that.
    static const uint32_t PHI = 0x9e3779b9U;
    
    // Paul Hsieh's SuperFastHash
    // http://www.azillionmonkeys.com/qed/hash.html
    // Implementation from Apple's WebCore/khtml/xml/dom_stringimpl.cpp, designed
    // to hash UTF-16 characters.
    
    unsigned l = CFStringGetLength(mutableString);
    uint32_t hash = PHI;
    uint32_t tmp;
    
    const UniChar *s = CFStringGetCharactersPtr(mutableString);
    UniChar *buf = NULL, stackBuf[STACK_BUFFER_SIZE];
    
    if (s == NULL) {
        
        if (l > STACK_BUFFER_SIZE) {
            buf = (UniChar *)CFAllocatorAllocate(allocator, l * sizeof(UniChar), 0);
            NSCAssert(buf != NULL, @"unable to allocate memory");
        } else {
            buf = stackBuf;
        }
        CFStringGetCharacters(mutableString, CFRangeMake(0, l), buf);
        s = buf;
    }
    
    int rem = l & 1;
    l >>= 1;
    
    // Main loop
    for (; l > 0; l--) {
        hash += s[0];
        tmp = (s[1] << 11) ^ hash;
        hash = (hash << 16) ^ tmp;
        s += 2;
        hash += hash >> 11;
    }
    
    // Handle end case
    if (rem) {
        hash += s[0];
        hash ^= hash << 11;
        hash += hash >> 17;
    }
    
    if (buf != stackBuf) CFAllocatorDeallocate(allocator, buf);
    
    // Force "avalanching" of final 127 bits
    hash ^= hash << 3;
    hash += hash >> 5;
    hash ^= hash << 2;
    hash += hash >> 15;
    hash ^= hash << 10;
    
    // this avoids ever returning a hash code of 0, since that is used to
    // signal "hash not computed yet", using a value that is likely to be
    // effectively the same as 0 when the low bits are masked
    if (hash == 0)
        hash = 0x80000000;
    
    // if we used the allocator, this should free the buffer for us
    CFRelease(mutableString);
    return hash;
}
    
const void *SKFloatRetain(CFAllocatorRef allocator, const void *value) {
    float *floatPtr = (float *)CFAllocatorAllocate(allocator, sizeof(float), 0);
    *floatPtr = *(float *)value;
    return floatPtr;
}

void SKFloatRelease(CFAllocatorRef allocator, const void *value) {
    CFAllocatorDeallocate(allocator, (float *)value);
}

CFStringRef SKFloatCopyDescription(const void *value) {
    return CFStringCreateWithFormat(NULL, NULL, CFSTR("%f"), *(float *)value);
}

Boolean	SKFloatEqual(const void *value1, const void *value2) {
    return fabsf(*(float *)value1 - *(float *)value2) < 0.00000001;
}

const void *SKNSRectRetain(CFAllocatorRef allocator, const void *value) {
    NSRect *rectPtr = (NSRect *)CFAllocatorAllocate(allocator, sizeof(NSRect), 0);
    *rectPtr = *(NSRect *)value;
    return rectPtr;
}

void SKNSRectRelease(CFAllocatorRef allocator, const void *value) {
    CFAllocatorDeallocate(allocator, (NSRect *)value);
}

CFStringRef SKNSRectCopyDescription(const void *value) {
    return (CFStringRef)[NSStringFromRect(*(NSRect *)value) retain];
}

Boolean	SKNSRectEqual(const void *value1, const void *value2) {
    return NSEqualRects(*(NSRect *)value1, *(NSRect *)value2);
}

const CFDictionaryKeyCallBacks SKPointerEqualObjectDictionaryKeyCallbacks = {
    0,   // version
    SKNSObjectRetain,
    SKNSObjectRelease,
    SKNSObjectCopyDescription,
    NULL, // equal
    NULL // hash
};

const CFDictionaryKeyCallBacks SKCaseInsensitiveDictionaryKeyCallbacks = {
    0,   // version
    SKNSObjectRetain,
    SKNSObjectRelease,
    SKNSObjectCopyDescription,
    SKCaseInsensitiveStringEqual,
    SKCaseInsensitiveStringHash
};

const CFDictionaryValueCallBacks SKFloatDictionaryValueCallbacks = {
    0, // version
    SKFloatRetain,
    SKFloatRelease,
    SKFloatCopyDescription,
    SKFloatEqual
};

const CFDictionaryValueCallBacks SKNSRectDictionaryValueCallbacks = {
    0, // version
    SKNSRectRetain,
    SKNSRectRelease,
    SKNSRectCopyDescription,
    SKNSRectEqual
};

const CFArrayCallBacks SKNSRectArrayCallbacks = {
    0, // version
    SKNSRectRetain,
    SKNSRectRelease,
    SKNSRectCopyDescription,
    SKNSRectEqual
};

const CFSetCallBacks SKPointerEqualObjectSetCallbacks = {
    0,   // version
    SKNSObjectRetain,
    SKNSObjectRelease,
    SKNSObjectCopyDescription,
    NULL, // equal
    NULL // hash
};
