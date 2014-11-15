//
//  SKRuntime.m
//  Skim
//
//  Created by Christiaan Hofman on 7/23/08.
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

#import "SKRuntime.h"
#import <objc/objc-runtime.h>


// this is essentially class_replaceMethod, but returns any inherited implementation, and can get the types from an inherited implementation
IMP SKSetMethodImplementation(Class aClass, SEL aSelector, IMP anImp, const char *types, BOOL isInstance, NSInteger options) {
    IMP imp = NULL;
    if (anImp) {
        Method method = isInstance ? class_getInstanceMethod(aClass, aSelector) : class_getClassMethod(aClass, aSelector);
        if (method) {
            imp = method_getImplementation(method);
            if (types == NULL)
                types = method_getTypeEncoding(method);
        }
        if (types != NULL && (options != SKAddOnly || imp == NULL) && (options != SKReplaceOnly || imp != NULL))
            class_replaceMethod(isInstance ? aClass : object_getClass(aClass), aSelector, anImp, types);
    }
    return imp;
}

IMP SKSetMethodImplementationFromSelector(Class aClass, SEL aSelector, SEL impSelector, BOOL isInstance, NSInteger options) {
    Method method = isInstance ? class_getInstanceMethod(aClass, impSelector) : class_getClassMethod(aClass, impSelector);
    return method ? SKSetMethodImplementation(aClass, aSelector, method_getImplementation(method), method_getTypeEncoding(method), isInstance, options) : NULL;
}

IMP SKReplaceInstanceMethodImplementation(Class aClass, SEL aSelector, IMP anImp) {
    return SKSetMethodImplementation(aClass, aSelector, anImp, NULL, YES, SKReplaceOnly);
}

void SKAddInstanceMethodImplementation(Class aClass, SEL aSelector, IMP anImp, const char *types) {
    SKSetMethodImplementation(aClass, aSelector, anImp, types, YES, SKAddOnly);
}

IMP SKReplaceInstanceMethodImplementationFromSelector(Class aClass, SEL aSelector, SEL impSelector) {
    return SKSetMethodImplementationFromSelector(aClass, aSelector, impSelector, YES, SKReplaceOnly);
}

void SKAddInstanceMethodImplementationFromSelector(Class aClass, SEL aSelector, SEL impSelector) {
    SKSetMethodImplementationFromSelector(aClass, aSelector, impSelector, YES, SKAddOnly);
}

IMP SKReplaceClassMethodImplementation(Class aClass, SEL aSelector, IMP anImp) {
    return SKSetMethodImplementation(aClass, aSelector, anImp, NULL, NO, SKReplaceOnly);
}

void SKAddClassMethodImplementation(Class aClass, SEL aSelector, IMP anImp, const char *types) {
    SKSetMethodImplementation(aClass, aSelector, anImp, types, NO, SKAddOnly);
}

IMP SKReplaceClassMethodImplementationFromSelector(Class aClass, SEL aSelector, SEL impSelector) {
    return SKSetMethodImplementationFromSelector(aClass, aSelector, impSelector, NO, SKReplaceOnly);
}

void SKAddClassMethodImplementationFromSelector(Class aClass, SEL aSelector, SEL impSelector) {
    SKSetMethodImplementationFromSelector(aClass, aSelector, impSelector, NO, SKAddOnly);
}
