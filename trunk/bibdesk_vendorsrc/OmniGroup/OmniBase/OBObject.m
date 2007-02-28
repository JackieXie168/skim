// Copyright 1997-2006 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniBase/OBObject.h>

#import <Foundation/Foundation.h>
#import <objc/objc.h>
#import <objc/objc-class.h>
#import <objc/objc-runtime.h>

#import <OmniBase/rcsid.h>
#import <OmniBase/OBPostLoader.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniBase/OBObject.m 79079 2006-09-07 22:35:32Z kc $")

@implementation OBObject
/*" OBObject is an immediate subclass of NSObject, and adds common functionality which Omni has found to be valuable in its own development. OBObject is a superclass for virtually all (if not all) of the classes in Omni's Frameworks (such as OmniFoundation, OmniAppkit, and the publically available OmniNetworking frameworks) as well as in Omni's commercial applications (including OmniWeb and OmniPDF). Also, the class header file includes a couple of other header files which are used in many to virtually all of our classes, and recommended for your use as well. This way you need not include these utility headers everywhere.

OBObject is essentially an abstract class; you are encouraged to subclass most or all of your classes from it, but it is highly unlikely that you would instantiate an OBObject itself.

The features afforded by this class are essentially debugging features. This class can help specifically with debugging allocation, deallocation, and class initialization errors, as well as provide a base for more useful readily examinable instance information via enhancements to the description methods.

"*/

static IMP                  nsObjectDescription;

#ifdef DEBUG_INITIALIZE
static NSMutableDictionary *initializedClasses;
#endif
#ifdef DEBUG_ALLOC
static BOOL OBObjectDebug = NO;
#endif

+ (void)initialize;
{
    static BOOL initialized = NO;
    Method descriptionMethod;

    [super initialize];

    if (!initialized) {
        initialized = YES;

        descriptionMethod = class_getInstanceMethod([NSObject class], @selector(description));
        nsObjectDescription = descriptionMethod->method_imp;

#ifdef DEBUG_INITIALIZE
#warning OBObject initialize debugging enabled
	NSLog(@"+[OBObject initialize] debugging enabled--"
		@"should deactivate this in production code");
	initializedClasses = [[NSMutableDictionary alloc] initWithCapacity:512];
#endif


        [OBPostLoader processClasses];
    }

#ifdef DEBUG_INITIALIZE
    [initializedClasses setObject:self forKey:NSStringFromClass(self)];
#endif
}

/*" This method is overriden from the superclass implementation in order to provide some class allocation, deallocation and initialization debugging support, since these are areas of fairly common errors.

If DEBUG_INITIALIZE is defined, then this method will complain if +initialize didn't call [super +initialize]. Apple's documentation for [NSObject +initialization] implies that subclass implementations of +initialize should not call the superclass implementation. Observation, however, shows that the runtime does in fact call +initialize on classes which don't implement +initialize. Therefore, superclass implementations of +initialize are invoked multiple times anyway, and we recommend that you continue this behavior when you implement +initialize for your custom classes. To put it succinctly, despite Apple's documentation, the first thing your custom +initialize should do is call [super +initialize]. Defining DEBUG_INITIALIZE provides you with a warning if you fail to do so.

If DEBUG_ALLOC is defined, then this method can log a message whenever +allocWithZone is invoked, providing you with some feedback whenever an object is allocated. Before logging this message, this method checks the OBObjectDebug flag, which defaults to NO, to make sure that it should in fact log each allocation (since otherwise you would drown in a flood of allocation logs), so you must manually set this flag to YES (typically while you are debugging in gdb) when you are interested in this information.

If neither DEBUG_INITIALIZE nor DEBUG_ALLOC are defined, then this method is not compiled at all, thus avoiding any performance penalty.

See also: + allocWithZone (NSObject)
"*/
#if defined(DEBUG_INITIALIZE) || defined(DEBUG_ALLOC)
+ allocWithZone:(NSZone *)zone;
{
#ifdef DEBUG_INITIALIZE
    if (![initializedClasses objectForKey:NSStringFromClass(self)]) {
	NSLog(@"+[%@ initialize] didn't call [super initialize]", self);
	[initializedClasses setObject:self forKey:NSStringFromClass(self)];
    }
#endif
#ifdef DEBUG_ALLOC
#warning OBObject alloc/dealloc debugging enabled
    if (OBObjectDebug) {
	OBObject *newObject;

        newObject = [super allocWithZone:zone];
        NSLog(@"alloc: %@", NSStringFromClass(self));
        
	return newObject;
    }
#endif
    return [super allocWithZone:zone];
}
#endif

/*" This method is overriden from the superclass implementation in order to provide some class allocation and deallocation debugging support, since these are areas of fairly common errors.

If DEBUG_ALLOC is defined, then this method can log a message whenever -dealloc is invoked. Before logging this message, this method checks the OBObjectDebug flag, which defaults to NO, to make sure that it should in fact log each allocation (since otherwise you would drown in a flood of deallocation logs), so you must manually set this flag to YES (typically while you are debugging in gdb) when you are interested in this information.

This method calls NSDeallocateObject(self) rather than calling the superclass implementation of -dealloc, to avoid the performance overhead of an extra method invocation (especially important if DEBUG_ALLOC is not defined). If Apple ever for some reason extend the implementation of [NSObject -dealloc] to do anything more than call NSDeallocateObject(self), this implementation will need to change to call the superclass implementation (or duplicate it's additional functionality).

If DEBUG_ALLOC is not defined, then this method is not compiled at all, thus avoiding any performance penalty.

See also: - dealloc (NSObject)
"*/

#ifdef DEBUG_ALLOC
- (void)dealloc;
{
    if (OBObjectDebug)
	NSLog(@"dealloc: %@", OBShortObjectDescription(self));
    NSDeallocateObject(self);
}
#endif

@end

@implementation OBObject (Debug)

unsigned int MaxDebugDepth = 3;

/*"
Returns a mutable dictionary describing the contents of the object. Subclasses should override this method, call the superclass implementation, and then add their contents to the returned dictionary. This is used for debugging purposes. It is highly recommended that you subclass this method in order to add information about your custom subclass (if appropriate), as this has no performance or memory requirement issues (it is never called unless you specifically call it, presumably from withing a gdb debugging session).

See also: - descriptionWithLocale:indent:
"*/
- (NSMutableDictionary *)debugDictionary;
{
    NSMutableDictionary        *debugDictionary;

    debugDictionary = [NSMutableDictionary dictionary];
    [debugDictionary setObject:OBShortObjectDescription(self) forKey:@"__self__"];

    return debugDictionary;
}

/*"
Normally, calls [self debugDictionary], asks that dictionary to perform descriptionWithLocale:indent:, and returns the result. To minimize the chance of the resulting description being extremely large (and therefore more confusing than useful), if level is greater than 2 this method simply returns [self shortDescription].

See also: - debugDictionary
"*/
- (NSString *)descriptionWithLocale:(NSDictionary *)locale
                             indent:(unsigned int)level
{
    if (level < MaxDebugDepth)
        return [[self debugDictionary] descriptionWithLocale:locale indent:level];
    else
	return [self shortDescription];
}

/*" Returns [self descriptionWithLocale:nil indent:0]. This often provides more meaningful information than the default implementation of description, and is (normally) automatically used by the debugger, gdb, when asked to print an object.

 See also: - description (NSObject), - shortDescription
"*/
- (NSString *)description;
{
    return [self descriptionWithLocale:nil indent:0];
}

/*"
Returns [super description]. See NSObject for details of its implementation of description; this method exists to provide access to the original implementation of description.

See also: - description (NSObject)
"*/
- (NSString *)shortDescription;
{
    return [super description];
}

@end

NSString *OBShortObjectDescription(id anObject)
{
    if (!anObject)
        return nil;
    return nsObjectDescription(anObject, @selector(description));
}
