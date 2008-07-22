//
//  NSObject_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 2/15/07.

/* Some of the following functions are inspired by OmniBase/NSObject_SKExtensions.h and subject to the following copyright */

// Copyright 1997-2008 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "NSObject_SKExtensions.h"
#import <Foundation/Foundation.h>
#import <objc/objc.h>
#import <objc/objc-class.h>
#import <objc/objc-runtime.h>


// wrappers around 10.5 only functions, use 10.4 API when the function is not defined

#if MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_5

extern void _objc_flush_caches(Class);

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
        
        // Flush the method cache
        _objc_flush_caches(aClass);
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

static IMP SKSetMethodImplementation(Class aClass, SEL aSelector, IMP anImp, const char *types, BOOL isInstance)
{
    Method superMethod = NULL;
    Method localMethod = SK_class_getMethod(aClass, aSelector, isInstance);
    IMP oldImp = NULL;
    Class superCls = Nil;
    Class realClass = isInstance ? aClass : SK_object_getClass(aClass);
    
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
            // We don't need to flush the method cach because the cache contains pointers to the Methods, so the cache is automatically updated
            // See <http://kevin.sb.org/2006/11/16/objective-c-caching-and-method-swizzling/>
        }
    } else if (types != NULL) {
        SK_class_addMethod(realClass, aSelector, anImp, types);
    }
    
    return oldImp;
}

static const char *SKGetTypeEncoding(Class aClass, SEL aSelector, BOOL isInstance)
{
    Method method = SK_class_getMethod(aClass, aSelector, isInstance);
    return method ? SK_method_getTypeEncoding(method) : NULL;
}

@implementation NSObject (SKExtensions)

+ (IMP)setMethod:(IMP)anImp typeEncoding:(const char *)types forSelector:(SEL)aSelector {
	return SKSetMethodImplementation(self, aSelector, anImp, types, NO);
}

- (IMP)setMethod:(IMP)anImp typeEncoding:(const char *)types forSelector:(SEL)aSelector {
	return [[self class] setInstanceMethod:anImp typeEncoding:types forSelector:aSelector];
}

+ (IMP)setInstanceMethod:(IMP)anImp typeEncoding:(const char *)types forSelector:(SEL)aSelector {
	return SKSetMethodImplementation(self, aSelector, anImp, types, YES);
}

+ (IMP)setMethodFromSelector:(SEL)impSelector forSelector:(SEL)aSelector {
	return SKSetMethodImplementation(self, aSelector, [self methodForSelector:impSelector], SKGetTypeEncoding(self, impSelector, NO), NO);
}

- (IMP)setMethodFromSelector:(SEL)impSelector forSelector:(SEL)aSelector {
    return [[self class] setInstanceMethodFromSelector:impSelector forSelector:aSelector];
}

+ (IMP)setInstanceMethodFromSelector:(SEL)impSelector forSelector:(SEL)aSelector {
	return SKSetMethodImplementation(self, aSelector, [self instanceMethodForSelector:impSelector], SKGetTypeEncoding(self, impSelector, YES), YES);
}

@end
