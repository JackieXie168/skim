//
//  OBUtilities.m
//  Skim
//
//  Created by Christiaan Hofman on 2/15/07.

/* Following functions are from OmniBase/OBUtilities.h and subject to the following copyright */

// Copyright 1997-2008 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OBUtilities.h"
#import <Foundation/Foundation.h>

static void _OBRegisterMethod(IMP methodImp, Class class, const char *methodTypes, SEL selector)
{
    struct objc_method_list *newMethodList;
    
    newMethodList = (struct objc_method_list *) NSZoneMalloc(NSDefaultMallocZone(), sizeof(struct objc_method_list));
    
    newMethodList->method_count = 1;
    newMethodList->method_list[0].method_name = selector;
    newMethodList->method_list[0].method_imp = methodImp;
    newMethodList->method_list[0].method_types = (char *)methodTypes;
    
    class_addMethods(class, newMethodList);
}

IMP OBRegisterInstanceMethodWithSelector(Class aClass, SEL oldSelector, SEL newSelector)
{
    struct objc_method *thisMethod;
    IMP oldImp = NULL;
    
    if ((thisMethod = class_getInstanceMethod(aClass, oldSelector))) {
        oldImp = thisMethod->method_imp;
        _OBRegisterMethod(thisMethod->method_imp, aClass, thisMethod->method_types, newSelector);
    }
    
    return oldImp;
}

IMP OBReplaceMethodImplementation(Class aClass, SEL oldSelector, IMP newImp)
{
    struct objc_method *localMethod, *superMethod;
    IMP oldImp = NULL;
    extern void _objc_flush_caches(Class);
    
    if ((localMethod = class_getInstanceMethod(aClass, oldSelector))) {
        oldImp = localMethod->method_imp;
        superMethod = aClass->super_class ? class_getInstanceMethod(aClass->super_class, oldSelector) : NULL;
        
        if (superMethod == localMethod) {
            // We are inheriting this method from the superclass.  We do *not* want to clobber the superclass's Method structure as that would replace the implementation on a greater scope than the caller wanted.  In this case, install a new method at this class and return the superclass's implementation as the old implementation (which it is).
            _OBRegisterMethod(newImp, aClass, localMethod->method_types, oldSelector);
        } else {
            // Replace the method in place
            localMethod->method_imp = newImp;
        }
        
        // Flush the method cache
        _objc_flush_caches(aClass);
    }
    
    return oldImp;
}

IMP OBReplaceMethodImplementationWithSelector(Class aClass, SEL oldSelector, SEL newSelector)
{
    struct objc_method *newMethod;
    
    newMethod = class_getInstanceMethod(aClass, newSelector);
    
    return OBReplaceMethodImplementation(aClass, oldSelector, newMethod->method_imp);
}
