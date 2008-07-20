//
//  SKUtilities.m
//  Skim
//
//  Created by Christiaan Hofman on 2/15/07.

/* Some of the following functions are inspired by OmniBase/SKUtilities.h and subject to the following copyright */

// Copyright 1997-2008 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "SKUtilities.h"
#import <Foundation/Foundation.h>


// wrappers around 10.5 only functions, use 10.4 API when the function is not defined

#if MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_5

static Class SK_object_getClass(id object)
{
    return object_getClass != NULL ? object_getClass(object) : object->isa;
}

static IMP SK_method_getImplementation(Method aMethod)
{
    return method_getImplementation != NULL ? method_getImplementation(aMethod) : aMethod->method_imp;
} 

static IMP SK_method_setImplementation(Method aMethod, IMP anImp)
{
    if (method_setImplementation != NULL) {
        return method_setImplementation(aMethod, anImp);
    } else {
        IMP oldImp = aMethod->method_imp;
        aMethod->method_imp = anImp;
        return oldImp;
    }
} 

static const char *SK_method_getTypeEncoding(Method aMethod)
{
    return method_getTypeEncoding != NULL ? method_getTypeEncoding(aMethod) : aMethod->method_types;
}

static Class SK_class_getSuperclass(Class aClass)
{
    return class_getSuperclass != NULL ? class_getSuperclass(aClass) : aClass->super_class;
}

static void SK_class_addMethod(Class aClass, SEL selector, IMP methodImp, const char *methodTypes)
{
    if (class_addMethod != NULL) {
        class_addMethod(aClass, selector, methodImp, methodTypes);
    } else {
        struct objc_method_list *newMethodList;
        
        newMethodList = (struct objc_method_list *) NSZoneMalloc(NSDefaultMallocZone(), sizeof(struct objc_method_list));
        
        newMethodList->method_count = 1;
        newMethodList->method_list[0].method_name = selector;
        newMethodList->method_list[0].method_imp = methodImp;
        newMethodList->method_list[0].method_types = (char *)methodTypes;
        
        class_addMethods(aClass, newMethodList);
    }
}

#else

static Class SK_object_getClass(id object)
{
    return object_getClass(object);
}

static IMP SK_method_getImplementation(Method aMethod)
{
    return method_getImplementation(aMethod);
} 

static IMP SK_method_setImplementation(Method aMethod, IMP anImp)
{
    return method_setImplementation(aMethod, anImp);
} 

static const char *SK_method_getTypeEncoding(Method aMethod)
{
    return method_getTypeEncoding(aMethod);
}

static Class SK_class_getSuperclass(Class aClass)
{
    return class_getSuperclass(aClass);
}

static void SK_class_addMethod(Class aClass, SEL selector, IMP methodImp, const char *methodTypes)
{
    class_addMethod(aClass, selector, methodImp, methodTypes);
}

#endif

static Method SK_class_getMethod(Class aClass, SEL aSelector, BOOL isInstance)
{
    return isInstance ? class_getInstanceMethod(aClass, aSelector) : class_getClassMethod(aClass, aSelector);
}

IMP SKReplaceMethodImplementation(Class aClass, SEL aSelector, IMP anImp, BOOL isInstance)
{
    Method superMethod = NULL;
    Method localMethod = SK_class_getMethod(aClass, aSelector, isInstance);
    IMP oldImp = NULL;
    Class superCls = Nil;
    Class realClass = isInstance ? aClass : SK_object_getClass(aClass);
    extern void _objc_flush_caches(Class);
    
    if (localMethod) {
        if (superCls = SK_class_getSuperclass(aClass))
            superMethod = SK_class_getMethod(superCls, aSelector, isInstance);
        
        if (superMethod == localMethod) {
            // We are inheriting this method from the superclass.  We do *not* want to clobber the superclass's Method structure as that would replace the implementation on a greater scope than the caller wanted.  In this case, install a new method at this class and return the superclass's implementation as the old implementation (which it is).
            oldImp = SK_method_getImplementation(localMethod);
            SK_class_addMethod(realClass, aSelector, anImp, SK_method_getTypeEncoding(localMethod));
        } else {
            // Replace the method in place
            oldImp = SK_method_setImplementation(localMethod, anImp);
        }
        
        // Flush the method cache, deprecated on 10.5
        if (_objc_flush_caches != NULL)
            _objc_flush_caches(realClass);
    }
    
    return oldImp;
}

IMP SKReplaceMethodImplementationWithSelector(Class aClass, SEL aSelector, SEL impSelector)
{
    return SKReplaceMethodImplementation(aClass, aSelector, SK_method_getImplementation(class_getInstanceMethod(aClass, impSelector)), YES);
}

IMP SKReplaceClassMethodImplementationWithSelector(Class aClass, SEL aSelector, SEL impSelector)
{
    return SKReplaceMethodImplementation(aClass, aSelector, SK_method_getImplementation(class_getClassMethod(aClass, impSelector)), NO);
}

void SKRegisterMethodImplementation(Class aClass, SEL aSelector, IMP anImp, const char *types, BOOL isInstance)
{
    Class realClass = isInstance ? aClass : SK_object_getClass(aClass);
    extern void _objc_flush_caches(Class);
    
    SK_class_addMethod(realClass, aSelector, anImp, types);
    
    // Flush the method cache, deprecated on 10.5
    if (_objc_flush_caches != NULL)
        _objc_flush_caches(realClass);
}

void SKRegisterMethodImplementationWithSelector(Class aClass, SEL aSelector, SEL impSelector)
{
    Method method = class_getInstanceMethod(aClass, impSelector);
    if (method)
        SKRegisterMethodImplementation(aClass, aSelector, SK_method_getImplementation(method), SK_method_getTypeEncoding(method), YES);
}

void SKRegisterClassMethodImplementationWithSelector(Class aClass, SEL aSelector, SEL impSelector)
{
    Method method = class_getClassMethod(aClass, impSelector);
    if (method)
        SKRegisterMethodImplementation(aClass, aSelector, SK_method_getImplementation(method), SK_method_getTypeEncoding(method), NO);
}
