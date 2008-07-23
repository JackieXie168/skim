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


#pragma mark Runtime compatibility
// wrappers around 10.5 only functions, use 10.4 API when the function is not defined

#if MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_5

#pragma mark 10.4 + 10.5

extern void _objc_flush_caches(Class);

static inline Class SK_object_getClass(id object) {
    return object_getClass != NULL ? object_getClass(object) : object->isa;
}

static inline IMP SK_method_getImplementation(Method aMethod) {
    return method_getImplementation != NULL ? method_getImplementation(aMethod) : aMethod->method_imp;
} 

static inline IMP SK_method_setImplementation(Method aMethod, IMP anImp) {
    if (method_setImplementation != NULL) {
        return method_setImplementation(aMethod, anImp);
    } else {
        IMP oldImp = aMethod->method_imp;
        aMethod->method_imp = anImp;
        return oldImp;
    }
} 

static inline void SK_method_exchangeImplementations(Method aMethod1, Method aMethod2) {
    if (method_exchangeImplementations != NULL) {
        method_exchangeImplementations(aMethod1, aMethod2);
    } else {
        IMP imp = aMethod1->method_imp;
        aMethod1->method_imp = aMethod2->method_imp;
        aMethod2->method_imp = imp;
    }
}

static inline const char *SK_method_getTypeEncoding(Method aMethod) {
    return method_getTypeEncoding != NULL ? method_getTypeEncoding(aMethod) : aMethod->method_types;
}

static inline Class SK_class_getSuperclass(Class aClass) {
    return class_getSuperclass != NULL ? class_getSuperclass(aClass) : aClass->super_class;
}

static inline void SK_class_addMethod(Class aClass, SEL selector, IMP methodImp, const char *methodTypes) {
    if (class_addMethod != NULL) {
        class_addMethod(aClass, selector, methodImp, methodTypes);
    } else {
        struct objc_method_list *newMethodList = (struct objc_method_list *)NSZoneMalloc(NSDefaultMallocZone(), sizeof(struct objc_method_list));
        
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

#pragma mark 10.5

static inline Class SK_object_getClass(id object) {
    return object_getClass(object);
}

static inline IMP SK_method_getImplementation(Method aMethod) {
    return method_getImplementation(aMethod);
} 

static inline IMP SK_method_setImplementation(Method aMethod, IMP anImp) {
    return method_setImplementation(aMethod, anImp);
} 

static inline void SK_method_exchangeImplementations(Method aMethod1, Method aMethod2) {
    method_exchangeImplementations(aMethod1, aMethod2);
}

static inline const char *SK_method_getTypeEncoding(Method aMethod) {
    return method_getTypeEncoding(aMethod);
}

static inline Class SK_class_getSuperclass(Class aClass) {
    return class_getSuperclass(aClass);
}

static inline void SK_class_addMethod(Class aClass, SEL selector, IMP methodImp, const char *methodTypes) {
    class_addMethod(aClass, selector, methodImp, methodTypes);
}

#endif

static inline Method SK_class_getMethod(Class aClass, SEL aSelector, BOOL isInstance) {
    return isInstance ? class_getInstanceMethod(aClass, aSelector) : class_getClassMethod(aClass, aSelector);
}

#pragma mark Basic functions

static IMP SKSetMethodImplementation(Class aClass, SEL aSelector, IMP anImp, const char *types, BOOL isInstance) {
    Method method = SK_class_getMethod(aClass, aSelector, isInstance);
    BOOL inherited = NO;
    IMP oldImp = NULL;
    Class superCls = Nil;
    Class realClass = isInstance ? aClass : SK_object_getClass(aClass);
    
    if (method) {
        if (superCls = SK_class_getSuperclass(aClass))
            inherited = (method == SK_class_getMethod(superCls, aSelector, isInstance));
        if (inherited) {
            // We are inheriting this method from the superclass.  We do *not* want to clobber the superclass's Method structure as that would replace the implementation on a greater scope than the caller wanted.  In this case, install a new method at this class and return the superclass's implementation as the old implementation (which it is).
            oldImp = SK_method_getImplementation(method);
            SK_class_addMethod(realClass, aSelector, anImp, SK_method_getTypeEncoding(method));
        } else {
            // Replace the method in place
            oldImp = SK_method_setImplementation(method, anImp);
            // We don't need to flush the method cach because the cache contains pointers to the Methods, so the cache is automatically updated
            // See <http://kevin.sb.org/2006/11/16/objective-c-caching-and-method-swizzling/>
        }
    } else if (types != NULL) {
        SK_class_addMethod(realClass, aSelector, anImp, types);
    }
    
    return oldImp;
}

static void SKExchangeMethodImplementations(Class aClass, SEL aSelector1, SEL aSelector2, BOOL isInstance) {
    Method method1 = SK_class_getMethod(aClass, aSelector1, isInstance);
    Method method2 = SK_class_getMethod(aClass, aSelector2, isInstance);
    BOOL inherited1 = NO;
    BOOL inherited2 = NO;
    Class superCls = Nil;
    Class realClass = isInstance ? aClass : SK_object_getClass(aClass);
    
    if (method1 && method2) {
        if (superCls = SK_class_getSuperclass(aClass)) {
            inherited1 = (method1 == SK_class_getMethod(superCls, aSelector1, isInstance));
            inherited2 = (method2 == SK_class_getMethod(superCls, aSelector2, isInstance));
        }
        if (inherited1 || inherited2) {
            IMP imp1 = SK_method_getImplementation(method1);
            IMP imp2 = SK_method_getImplementation(method2);
            const char *types = SK_method_getTypeEncoding(method1);
            
            if (inherited1)
                SK_class_addMethod(realClass, aSelector1, imp2, types);
            else
                SK_method_setImplementation(method1, imp2);
            
            if (inherited2)
                SK_class_addMethod(realClass, aSelector2, imp1, types);
            else
                SK_method_setImplementation(method2, imp1);
        } else {
            SK_method_exchangeImplementations(method1, method2);
        }
    }
}

static const char *SKGetTypeEncoding(Class aClass, SEL aSelector, BOOL isInstance) {
    Method method = SK_class_getMethod(aClass, aSelector, isInstance);
    return method ? SK_method_getTypeEncoding(method) : NULL;
}

#pragma mark API

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

+ (void)exchangeMethodForSelector:(SEL)aSelector1 withMethodForSelector:(SEL)aSelector2 {
    SKExchangeMethodImplementations(self, aSelector1, aSelector2, NO);
}

- (void)exchangeMethodForSelector:(SEL)aSelector1 withMethodForSelector:(SEL)aSelector2 {
    [[self class] exchangeInstanceMethodForSelector:aSelector1 withInstanceMethodForSelector:aSelector2];
}

+ (void)exchangeInstanceMethodForSelector:(SEL)aSelector1 withInstanceMethodForSelector:(SEL)aSelector2 {
    SKExchangeMethodImplementations(self, aSelector1, aSelector2, YES);
}

@end
