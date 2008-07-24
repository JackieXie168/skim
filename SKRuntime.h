//
//  SKRuntime.h
//  Skim
//
//  Created by Christiaan Hofman on 7/23/08.
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

#import <objc/objc-runtime.h>

// wrappers around 10.5 only functions, use 10.4 API when the function is not defined

extern Class SK_object_getClass(id object);

extern SEL SK_method_getName(Method aMethod);
extern IMP SK_method_getImplementation(Method aMethod);
extern const char *SK_method_getTypeEncoding(Method aMethod);
extern IMP SK_method_setImplementation(Method aMethod, IMP anImp);
extern void SK_method_exchangeImplementations(Method aMethod1, Method aMethod2);

extern Class SK_class_getSuperclass(Class aClass);
extern void SK_class_addMethod(Class aClass, SEL selector, IMP methodImp, const char *methodTypes);
extern IMP SK_class_replaceMethod(Class aClass, SEL selector, IMP methodImp, const char *methodTypes);
