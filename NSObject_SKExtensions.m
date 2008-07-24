//
//  NSObject_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 7/22/08.
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

#import "NSObject_SKExtensions.h"
#import "SKRuntime.h"


static inline IMP SKReplaceMethodImplementation(Class aClass, SEL aSelector, IMP anImp, const char *types, BOOL isInstance) {
    IMP imp = NULL;
    if (anImp) {
        Method method = isInstance ? class_getInstanceMethod(aClass, aSelector) : class_getClassMethod(aClass, aSelector);
        if (method) {
            imp = SK_method_getImplementation(method);
            if (types == NULL)
                types = SK_method_getTypeEncoding(method);
        }
        if (types)
            SK_class_replaceMethod(isInstance ? aClass : SK_object_getClass(aClass), aSelector, anImp, types);
    }
    return imp;
}

static inline IMP SKReplaceMethodImplementationFromSelector(Class aClass, SEL aSelector, SEL impSelector, BOOL isInstance) {
    Method method = isInstance ? class_getInstanceMethod(aClass, impSelector) : class_getClassMethod(aClass, impSelector);
    return method ? SKReplaceMethodImplementation(aClass, aSelector, SK_method_getImplementation(method), SK_method_getTypeEncoding(method), isInstance) : NULL;
}

@implementation NSObject (SKExtensions)

+ (IMP)setMethod:(IMP)anImp typeEncoding:(const char *)types forSelector:(SEL)aSelector {
    return SKReplaceMethodImplementation(self, aSelector, anImp, types, NO);
}

- (IMP)setMethod:(IMP)anImp typeEncoding:(const char *)types forSelector:(SEL)aSelector {
	return [[self class] setInstanceMethod:anImp typeEncoding:types forSelector:aSelector];
}

+ (IMP)setInstanceMethod:(IMP)anImp typeEncoding:(const char *)types forSelector:(SEL)aSelector {
    return SKReplaceMethodImplementation(self, aSelector, anImp, types, YES);
}

+ (IMP)setMethodFromSelector:(SEL)impSelector forSelector:(SEL)aSelector {
    return SKReplaceMethodImplementationFromSelector(self, aSelector, impSelector, NO);
}

- (IMP)setMethodFromSelector:(SEL)impSelector forSelector:(SEL)aSelector {
    return [[self class] setInstanceMethodFromSelector:impSelector forSelector:aSelector];
}

+ (IMP)setInstanceMethodFromSelector:(SEL)impSelector forSelector:(SEL)aSelector {
    return SKReplaceMethodImplementationFromSelector(self, aSelector, impSelector, YES);
}

+ (void)exchangeMethodForSelector:(SEL)aSelector1 withMethodForSelector:(SEL)aSelector2 {
    [self setMethod:[self setMethodFromSelector:aSelector2 forSelector:aSelector1] typeEncoding:NULL forSelector:aSelector2];
}

- (void)exchangeMethodForSelector:(SEL)aSelector1 withMethodForSelector:(SEL)aSelector2 {
    [[self class] exchangeInstanceMethodForSelector:aSelector1 withInstanceMethodForSelector:aSelector2];
}

+ (void)exchangeInstanceMethodForSelector:(SEL)aSelector1 withInstanceMethodForSelector:(SEL)aSelector2 {
    [self setInstanceMethod:[self setInstanceMethodFromSelector:aSelector2 forSelector:aSelector1] typeEncoding:NULL forSelector:aSelector2];
}

@end
