//
//  SKRuntime.m
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

#import "SKRuntime.h"


#if MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_5

#pragma mark 10.4 + 10.5

extern void _objc_flush_caches(Class);

Class SK_object_getClass(id object) {
    return object_getClass != NULL ? object_getClass(object) : object->isa;
}

IMP SK_method_getImplementation(Method aMethod) {
    return method_getImplementation != NULL ? method_getImplementation(aMethod) : aMethod->method_imp;
}

const char *SK_method_getTypeEncoding(Method aMethod) {
    return method_getTypeEncoding != NULL ? method_getTypeEncoding(aMethod) : aMethod->method_types;
}

// generic implementation for SK_class_addMethod/SK_class_replaceMethod, but only for old API, modeled after actual runtime implementation of _class_addMethod
static inline IMP _SK_class_addMethod(Class aClass, SEL selector, IMP methodImp, const char *methodTypes, BOOL replace) {
    IMP imp = NULL;
    void *iterator = NULL;
    struct objc_method_list *mlist;
    Method m, method = NULL;
    int i;
    while (method == NULL && (mlist = class_nextMethodList(aClass, &iterator))) {
        for (i = 0; i < mlist->method_count; i++) {
            m = &mlist->method_list[i];
            if (m->method_name == selector) {
                method = m;
                break;
            }
        }
    }
    if (method) {
        imp = method->method_imp;
        if (replace)
            method->method_imp = methodImp;
    } else {
        mlist = (struct objc_method_list *)NSZoneCalloc(NSDefaultMallocZone(), 1, sizeof(struct objc_method_list));
        
        mlist->method_count = 1;
        mlist->method_list[0].method_name = selector;
        mlist->method_list[0].method_imp = methodImp;
        mlist->method_list[0].method_types = strdup(methodTypes);
        
        class_addMethods(aClass, mlist);
        
        // Flush the method cache
        _objc_flush_caches(aClass);
    }
    return imp;
}

IMP SK_class_replaceMethod(Class aClass, SEL selector, IMP methodImp, const char *methodTypes) {
    if (class_replaceMethod != NULL)
        return class_replaceMethod(aClass, selector, methodImp, methodTypes);
    else
        return _SK_class_addMethod(aClass, selector, methodImp, methodTypes, YES);
}

#else

#pragma mark 10.5

Class SK_object_getClass(id object) {
    return object_getClass(object);
}

IMP SK_method_getImplementation(Method aMethod) {
    return method_getImplementation(aMethod);
}

const char *SK_method_getTypeEncoding(Method aMethod) {
    return method_getTypeEncoding(aMethod);
}

IMP SK_class_replaceMethod(Class aClass, SEL selector, IMP methodImp, const char *methodTypes) {
    return class_replaceMethod(aClass, selector, methodImp, methodTypes);
}

#endif
