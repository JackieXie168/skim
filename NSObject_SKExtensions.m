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


@implementation NSObject (SKExtensions)

+ (IMP)setMethod:(IMP)anImp typeEncoding:(const char *)types forSelector:(SEL)aSelector {
    return SK_class_replaceMethod(SK_object_getClass(self), aSelector, anImp, types);
}

- (IMP)setMethod:(IMP)anImp typeEncoding:(const char *)types forSelector:(SEL)aSelector {
	return [[self class] setInstanceMethod:anImp typeEncoding:types forSelector:aSelector];
}

+ (IMP)setInstanceMethod:(IMP)anImp typeEncoding:(const char *)types forSelector:(SEL)aSelector {
    return SK_class_replaceMethod(self, aSelector, anImp, types);
}

+ (IMP)setMethodFromSelector:(SEL)impSelector forSelector:(SEL)aSelector {
    Method method = class_getClassMethod(self, aSelector);
    return method ? SK_class_replaceMethod(SK_object_getClass(self), aSelector, SK_method_getImplementation(method), SK_method_getTypeEncoding(method)) : NULL;
}

- (IMP)setMethodFromSelector:(SEL)impSelector forSelector:(SEL)aSelector {
    return [[self class] setInstanceMethodFromSelector:impSelector forSelector:aSelector];
}

+ (IMP)setInstanceMethodFromSelector:(SEL)impSelector forSelector:(SEL)aSelector {
    Method method = class_getInstanceMethod(self, aSelector);
    return method ? SK_class_replaceMethod(self, aSelector, SK_method_getImplementation(method), SK_method_getTypeEncoding(method)) : NULL;
}

+ (void)exchangeMethodForSelector:(SEL)aSelector1 withMethodForSelector:(SEL)aSelector2 {
    Method method1 = class_getClassMethod(self, aSelector1);
    Method method2 = class_getClassMethod(self, aSelector2);
    if (method1 && method2) {
        Class metaClass = SK_object_getClass(self);
        IMP imp = SK_method_getImplementation(method2);
        imp = SK_class_replaceMethod(metaClass, aSelector1, imp, SK_method_getTypeEncoding(method1));
        SK_class_replaceMethod(metaClass, aSelector2, imp, SK_method_getTypeEncoding(method2));
    }
}

- (void)exchangeMethodForSelector:(SEL)aSelector1 withMethodForSelector:(SEL)aSelector2 {
    [[self class] exchangeInstanceMethodForSelector:aSelector1 withInstanceMethodForSelector:aSelector2];
}

+ (void)exchangeInstanceMethodForSelector:(SEL)aSelector1 withInstanceMethodForSelector:(SEL)aSelector2 {
    Method method1 = class_getInstanceMethod(self, aSelector1);
    Method method2 = class_getInstanceMethod(self, aSelector2);
    if (method1 && method2) {
        IMP imp = SK_method_getImplementation(method2);
        imp = SK_class_replaceMethod(self, aSelector1, imp, SK_method_getTypeEncoding(method1));
        SK_class_replaceMethod(self, aSelector2, imp, SK_method_getTypeEncoding(method2));
    }
}

@end
