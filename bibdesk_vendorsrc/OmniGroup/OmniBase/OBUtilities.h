// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniBase/OBUtilities.h,v 1.28 2003/04/24 20:50:14 wiml Exp $

#import <Foundation/NSString.h>

#import <objc/objc.h>
#import <objc/objc-class.h>
#import <objc/objc-runtime.h>
#import <OmniBase/FrameworkDefines.h>

#ifndef NO_INLINE
#define INLINE inline
#else
#define INLINE
#endif // NO_INLINE

OmniBase_EXTERN void OBRequestConcreteImplementation(id self, SEL _cmd);
OmniBase_EXTERN void OBRejectUnusedImplementation(id self, SEL _cmd);
OmniBase_EXTERN NSString *OBAbstractImplementation;
OmniBase_EXTERN NSString *OBUnusedImplementation;


OmniBase_EXTERN IMP OBRegisterInstanceMethodWithSelector(Class aClass, SEL oldSelector, SEL newSelector);
/*.doc.
Provides the same functionality as +[NSObject registerInstanceMethod:withMethodTypes:forSelector: but does it without provoking +initialize on the target class.  Returns the original implementation.
*/

OmniBase_EXTERN IMP OBReplaceMethodImplementation(Class aClass, SEL oldSelector, IMP newImp);
/*.doc.
Replaces the given method implementation in place.  Returns the old implementation.
*/

OmniBase_EXTERN IMP OBReplaceMethodImplementationWithSelector(Class aClass, SEL oldSelector, SEL newSelector);
/*.doc.
Calls the above, but determines newImp by looking up the instance method for newSelector.  Returns the old implementation.
*/

OmniBase_EXTERN IMP OBReplaceMethodImplementationWithSelectorOnClass(Class destClass, SEL oldSelector, Class sourceClass, SEL newSelector);
/*.doc.
Calls OBReplaceMethodImplementation.  Derives newImp from newSelector on sourceClass and changes method implementation for oldSelector on destClass.
*/

// This returns YES if the given pointer is a class object
static INLINE BOOL OBPointerIsClass(id object)
{
    if (object)
        return CLS_GETINFO((struct objc_class *)(object->isa), CLS_META);
    return NO;
}

// This returns the class object for the given pointer.  For an instance, that means getting the class.  But for a class object, that means returning the pointer itself 

static INLINE Class OBClassForPointer(id object)
{
    if (!object)
	return object;

    if (OBPointerIsClass(object))
	return object;
    else
	return object->isa;
}

static INLINE BOOL OBClassIsSubclassOfClass(Class subClass, Class superClass)
{
    while (subClass) {
        if (subClass == superClass)
            return YES;
        else
            subClass = subClass->super_class;
    }
    return NO;
}

// This macro ensures that we call [super initialize] in our +initialize (since this behavior is necessary for some classes in Cocoa), but it keeps custom class initialization from executing more than once.
#define OBINITIALIZE \
    do { \
        static BOOL hasBeenInitialized = NO; \
        [super initialize]; \
        if (hasBeenInitialized) \
            return; \
        hasBeenInitialized = YES;\
    } while (0);

    
#ifdef USING_BUGGY_CPP_PRECOMP
// Versions of cpp-precomp released before April 2002 have a bug that makes us have to do this
#define NSSTRINGIFY(name) @ ## '"' ## name ## '"'
#else
#define NSSTRINGIFY(name) @ ## #name
#endif

// An easy way to define string constants.  For example, "NSSTRINGIFY(foo)" produces @"foo" and "DEFINE_NSSTRING(foo);" produces: NSString *foo = @"foo";

#define DEFINE_NSSTRING(name) \
	NSString *name = NSSTRINGIFY(name)

#ifdef WIN32

// BSD stuff that NT doesn't have.

double rint(double a);

#endif


// Emits a warning indicating that an obsolete method has been called.
#define OB_WARN_OBSOLETE_METHOD do { static BOOL warned = NO; if (!warned) { warned = YES; NSLog(@"Warning: obsolete method %c[%@ %s] invoked", OBPointerIsClass(self)?'+':'-', OBClassForPointer(self), _cmd); } } while(0)

