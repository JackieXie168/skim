//
//  BDSKCountedSet.m
//  Bibdesk
//
//  Created by Adam Maxwell on 10/31/05.
/*
 This software is Copyright (c) 2005
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

#import "BDSKCountedSet.h"
#import <OmniFoundation/OFCFCallbacks.h>
#import <OmniFoundation/CFDictionary-OFExtensions.h>
#import <OmniFoundation/CFSet-OFExtensions.h>
#import <OmniBase/assertions.h>

@implementation BDSKCountedSet

+ (id)allocWithZone:(NSZone *)aZone
{
    return NSAllocateObject(self, 0, aZone);
}

// designated initializer
- (id)initWithKeyCallBacks:(const CFDictionaryKeyCallBacks *)keyCallBacks{
    
    if(self = [super initWithCapacity:0])
        dictionary = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, keyCallBacks, &OFIntegerDictionaryValueCallbacks);
    
    return self;
}

- (id)initCaseInsensitive:(BOOL)caseInsensitive withCapacity:(unsigned)numItems
{
    // used only for debug logging at present
    keysAreStrings = YES;

    if(caseInsensitive)
        return [self initWithKeyCallBacks:&OFCaseInsensitiveStringKeyDictionaryCallbacks];
    else
        return [self initWithKeyCallBacks:&OFNSObjectDictionaryKeyCallbacks];

}

- (id)copyWithZone:(NSZone *)zone
{
    BDSKCountedSet *copy = [[[self class] allocWithZone:zone] initWithCapacity:0];
    if(copy->dictionary != NULL)
        CFRelease(copy->dictionary);
    // create an immutable dictionary that will raise an exception when you try to add/remove from it; copying makes sure we get the same callbacks
    copy->dictionary = (CFMutableDictionaryRef)CFDictionaryCreateCopy(CFAllocatorGetDefault(), dictionary);    
    return copy;
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
    BDSKCountedSet *copy = [[[self class] allocWithZone:zone] initWithCapacity:0];
    if(copy->dictionary != NULL)
        CFRelease(copy->dictionary);
    // copy to get the same callbacks
    copy->dictionary = CFDictionaryCreateMutableCopy(CFAllocatorGetDefault(), 0, dictionary);
    return copy;
}

// if we ever need this, we could encode only for specific callbacks (see OFMultiValueDictionary)
- (void)encodeWithCoder:(NSCoder *)coder
{
    [NSException raise:NSGenericException format:@"Cannot serialize an %@ with custom key callbacks", [(id)isa name]];
}

#pragma mark NSCountedSet overrides

// designated initializer for NSCountedSet, which is a concrete subclass of NSMutableSet (not part of the class cluster)
- (id)initWithCapacity:(unsigned)numItems;
{
    return [self initCaseInsensitive:YES withCapacity:numItems];
}

// presumably the other init... methods call initWithCapacity:, so we should be fine with super's implementation
- (id)initWithArray:(NSArray *)array;
{
    return [super initWithArray:array];
}

- (id)initWithSet:(NSSet *)set;
{
    return [super initWithSet:set];
}

- (void)dealloc
{
    if(dictionary) CFRelease(dictionary);
    [super dealloc];
}

- (unsigned)countForObject:(id)object;
{
    CFIndex countOfObject = 0;
    CFDictionaryGetValueIfPresent(dictionary, (const void *)object, (const void **)&countOfObject);
    
    return countOfObject;
}

#pragma mark NSSet primitive methods

- (unsigned)count;
{
    return CFDictionaryGetCount(dictionary);
}

- (id)member:(id)object;
{
    return (void *)CFDictionaryGetValue(dictionary, (void *)object);
}

- (NSEnumerator *)objectEnumerator;
{
    return [(NSMutableDictionary *)dictionary keyEnumerator];
}

#pragma mark NSMutableSet primitive methods

- (void)addObject:(id)object;
{
    if(keysAreStrings) OBASSERT([object isKindOfClass:[NSString class]]);
    
    // each object starts with a count of 1
    CFIndex countOfObject = 1;
    if(CFDictionaryGetValueIfPresent(dictionary, (const void *)object, (const void **)&countOfObject)){
        // if it's already in the dictionary, increment the counter; the dictionary retains it for us
        countOfObject++;
    }
    
    CFDictionarySetValue(dictionary, object, (void *)countOfObject);
}
    
- (void)removeObject:(id)object;
{
    if(keysAreStrings) OBASSERT([object isKindOfClass:[NSString class]]);

    CFIndex countOfObject;
    if(CFDictionaryGetValueIfPresent(dictionary, (void *)object, (const void **)&countOfObject)){
        countOfObject--;
        // don't remove it until the count goes to zero; should lock here
        if(countOfObject == 0)
            CFDictionaryRemoveValue(dictionary, (const void *)object);
        else
            CFDictionarySetValue(dictionary, object, (const void *)countOfObject);
    }
    // no-op if the dictionary doesn't have this key
}

@end
