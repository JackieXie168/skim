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


const void *SKNSObjectRetain(CFAllocatorRef allocator, const void *value) {
    return [(id)value retain];
}

void SKNSObjectRelease(CFAllocatorRef allocator, const void *value) {
    [(id)value release];
}

CFStringRef SKNSObjectCopyDescription(const void *value) {
    return (CFStringRef)[[(id)value description] retain];
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
