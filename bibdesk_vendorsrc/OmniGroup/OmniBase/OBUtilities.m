// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniBase/OBUtilities.h>

#import <Foundation/Foundation.h>
#import <objc/objc-runtime.h>

#import <OmniBase/assertions.h>
#import <OmniBase/rcsid.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/SourceRelease_2005-10-03/OmniGroup/Frameworks/OmniBase/OBUtilities.m 68913 2005-10-03 19:36:19Z kc $")

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
    struct objc_method *thisMethod;
    IMP oldImp = NULL;
    extern void _objc_flush_caches(Class);

    if ((thisMethod = class_getInstanceMethod(aClass, oldSelector))) {
        oldImp = thisMethod->method_imp;

        // Replace the method in place
        thisMethod->method_imp = newImp;

        // Flush the method cache
        _objc_flush_caches(aClass);
    }

    return oldImp;
}

IMP OBReplaceMethodImplementationWithSelector(Class aClass, SEL oldSelector, SEL newSelector)
{
    struct objc_method *newMethod;

    newMethod = class_getInstanceMethod(aClass, newSelector);
    OBASSERT(newMethod);
    
    return OBReplaceMethodImplementation(aClass, oldSelector, newMethod->method_imp);
}

IMP OBReplaceMethodImplementationWithSelectorOnClass(Class destClass, SEL oldSelector, Class sourceClass, SEL newSelector)
{
    struct objc_method *newMethod;

    newMethod = class_getInstanceMethod(sourceClass, newSelector);
    OBASSERT(newMethod);

    return OBReplaceMethodImplementation(destClass, oldSelector, newMethod->method_imp);
}

void OBRequestConcreteImplementation(id self, SEL _cmd)
{
    OBASSERT_NOT_REACHED("Concrete implementation needed");
    [NSException raise:OBAbstractImplementation format:@"%@ needs a concrete implementation of %c%s", [self class], OBPointerIsClass(self) ? '+' : '-', sel_getName(_cmd)];
    exit(1);  // notreached, but needed to pacify the compiler
}

void OBRejectUnusedImplementation(id self, SEL _cmd)
{
    OBASSERT_NOT_REACHED("Subclass rejects unused implementation");
    [NSException raise:OBUnusedImplementation format:@"%c[%@ %s] should not be invoked", OBPointerIsClass(self) ? '+' : '-', OBClassForPointer(self), sel_getName(_cmd)];
    exit(1);  // notreached, but needed to pacify the compiler
}

void OBRejectInvalidCall(id self, SEL _cmd, NSString *format, ...)
{
    const char *className, *methodName;
    NSString *complaint, *reasonString;
    va_list argv;

    className = OBClassForPointer(self)->name;
    methodName = sel_getName(_cmd);
    va_start(argv, format);
    complaint = [[NSString alloc] initWithFormat:format arguments:argv];
    va_end(argv);
    reasonString = [NSString stringWithFormat:@"%c[%s %s] %@", OBPointerIsClass(self) ? '+' : '-', className, methodName, complaint];
    [complaint release];
    [[NSException exceptionWithName:NSInvalidArgumentException reason:reasonString userInfo:nil] raise];
    exit(1);  // notreached, but needed to pacify the compiler
}

DEFINE_NSSTRING(OBAbstractImplementation);
DEFINE_NSSTRING(OBUnusedImplementation);
