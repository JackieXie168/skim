// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import <OmniBase/OBPostLoader.h>

#import <OmniBase/OBUtilities.h>
#import <OmniBase/assertions.h>

#import <Foundation/Foundation.h>
#import <objc/objc-class.h>
#import <objc/objc-runtime.h>
#import <OmniBase/rcsid.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniBase/OBPostLoader.m,v 1.35 2003/03/24 23:05:04 neo Exp $")

static NSRecursiveLock *lock = nil;
static NSHashTable *calledImplementations = NULL;
static BOOL isMultiThreaded = NO;
static BOOL isSendingBecomingMultiThreaded = NO;

extern void _objc_resolve_categories_for_class(struct objc_class *cls);

@interface OBPostLoader (PrivateAPI)
+ (BOOL)_processSelector:(SEL)selectorToCall inClass:(Class)aClass initialize:(BOOL)shouldInitialize;
+ (void)_preventBundleInitialization;
+ (void)_provokeBundleInitialization;

+ (void)_becomingMultiThreaded:(NSNotification *)note;
@end

//#define POSTLOADER_DEBUG

@implementation OBPostLoader
/*"
OBPostLoader provides the functionality that you might expect to get from implementing a +load method.  Unfortunately, some implementations of OpenStep have bugs with their  implementation of +load.  Rather than attempt to use +load, OBPostLoader provides similar functionality that actually works.  Early in your program startup, you should call +processClasses.  This will go through the ObjC runtime and invoke all of the +performPosing and +didLoad methods.  Each class may have multiple implementations of each of theses selectors -- all will be called.

OBPostLoader listens for bundle loaded notifications and will automatically reinvoke +processClasses to perform any newly loaded methods.

OBPostLoader also listens for NSBecomingMultiThreaded and will invoke every implementation of +becomingMultiThreaded.

On HP-UX, an additional pass is made through the classes looking for +registerFramework methods.  HP-UX doesn't support the automatic registration of framework paths.  This is intended to solve that problem.  The +registerFramework methods are processed BEFORE the +didLoad methods so that the code in the +didLoad methods may use +[NSBundle allFrameworks].
"*/

+ (void)initialize;
{
    OBINITIALIZE;

    // Set this up before we call any method implementations
    calledImplementations = NSCreateHashTable(NSNonOwnedPointerHashCallBacks, 0);

    // This will cause an error to be reported if someone does something in the +performPosing methods that causes +[NSBundle initialize] to be called.
    [self _preventBundleInitialization];

    // We have to do this before calling +[NSBundle initialize] since on HP-UX calling class_poseAs() after that point can cause SEGVs.  It is unclear why this is the case.
    // Also, we need -[NSBundle infoDictionary] to get replaced with -replacement_infoDictionary early on (before +processDefaults is called).
    [self processSelector:@selector(performPosing) initialize:NO];

    // Un-boobytrap and force a call to +[NSBundle initialize] now that we have done all of the +performPosing calls
    [self _provokeBundleInitialization];

#ifdef hpux
    // Register frameworks.  This is necessary since on HP-UX, frameworks aren't automatically registered, and the +processDefaults below will fail to find framework resources otherwise.  On HP-UX we need all of the +registerFramework methods to get called before +[NSBundle bundleForClass:] is invoked.
    [self processSelector:@selector(registerFramework) initialize:NO];
#endif
    
    // If any other bundles get loaded, make sure that we process them too.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bundleDidLoad:) name:NSBundleDidLoadNotification object:nil];

    // Register for the multi-threadedness here so that most classes won't have to
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_becomingMultiThreaded:) name:NSWillBecomeMultiThreadedNotification object:nil];
}

/*"
Searches the ObjC runtime for particular methods and invokes them.  Each implementation will be invoked exactly once.  Currently, there is no guarantee on the order that these messages will occur.  This should be called as the first line of main().  Once this has been called at the beginning of main, it will automatically be called each time a bundle is loaded (view the NSBundle loading notification).

This method makes several passes, each time invoking a different selector.  On the first pass, +performPosing implementations are invoked.  Then, if on HP-UX,  +registerFramework implementations are processed.  This is used by some to work around the fact that PDO 4.0 on HP-UX doesn't correctly register frameworks with NSBundle.  Finally, +didLoad implementations are processed.  Finally, on HP-UX, a third pass is processed in which
"*/
+ (void)processClasses;
{
    [self processSelector:@selector(performPosing) initialize:NO];
#ifdef hpux
    [self processSelector:@selector(registerFramework) initialize:NO];
#endif
    [self processSelector:@selector(didLoad) initialize:YES];

    // Handle the case that this doesn't get called until after we've gone multi-threaded
    if ([NSThread isMultiThreaded])
        [self _becomingMultiThreaded:nil];
}

/*"
This method does the work of looping over the runtime searching for implementations of selectorToCall and invoking them when they haven't already been invoked.
"*/
+ (void)processSelector:(SEL)selectorToCall initialize:(BOOL)shouldInitialize;
{
    BOOL didInvokeSomething = YES;

    [lock lock];

    // We will collect the necessary information from the runtime before calling any method implementations.  This is necessary since any once of the implementations that we call could actually modify the ObjC runtime.  It could add classes or methods.

    while (didInvokeSomething) {
        int classCount = 0, newClassCount;
        Class *classes = NULL;

        // Start out claiming to have invoked nothing.  If this doesn't get reset to YES below, we're done.
        didInvokeSomething = NO;

        // Get the class list
        newClassCount = objc_getClassList(NULL, 0);
        while (classCount < newClassCount) {
            classCount = newClassCount;
            classes = realloc(classes, sizeof(Class) * classCount);
            newClassCount = objc_getClassList(classes, classCount);
        }

        // Now, use the class list; if NULL, there are no classes
        if (classes != NULL) {
            unsigned int classIndex;
            
            // Loop over the gathered classes and process the requested implementations
            for (classIndex = 0; classIndex < classCount; classIndex++) {
                Class aClass = classes[classIndex];

                _objc_resolve_categories_for_class(aClass);

                if ([self _processSelector:selectorToCall inClass:aClass initialize:shouldInitialize])
                    didInvokeSomething = YES;
            }
        }

        // Free the class list
        free(classes);
    }

    [lock unlock];
}

+ (void) bundleDidLoad: (NSNotification *) notification;
{
    [self processClasses];
}

/*"
This can be used instead of +[NSThread isMultiThreaded].  The difference is that this method doesn't return YES until after going multi-threaded, whereas the NSThread version starts returning YES before the NSWillBecomeMultiThreadedNotification is sent.
"*/
+ (BOOL)isMultiThreaded;
{
    return isMultiThreaded;
}

@end




//// Private API!
// We replace this method during +[NSBundle initialize] to avoid the tons of file system accesses during startup that are to resolve symlinks.  It doesn't seem like these access are really necessary since the kernel will do them for us

#ifndef WIN32
@interface NSPathStore2 : NSString
- (NSString *)stringByResolvingSymlinksInPath;
@end

@implementation NSPathStore2 (OFOverrides)

- (NSString *)replacement_stringByResolvingSymlinksInPath;
{
    // Can do this since we are a string
    return self;
}

@end
#endif

static Method NSBundleInitializeMethod = NULL;
static IMP originalNSBundleInitializeImplementation = NULL;

static id _NSBundleInitializationTooEarly(id self, SEL _cmd)
{
    fprintf(stderr, "+[NSBundle initialize] called too early!  This should not happen until OFPostLoader provokes it. Please rewrite your +performPosing method to not provoke +[NSBundle initialize].\n");
    abort();
    return nil;
}


@implementation OBPostLoader (PrivateAPI)

+ (BOOL)_processSelector:(SEL) selectorToCall inClass:(Class)aClass initialize:(BOOL)shouldInitialize;
{
    Class metaClass = aClass->isa; // we are looking at class methods
    void *iterator;
    struct objc_method_list *mlist;
    IMP *imps;
    unsigned int impIndex, impCount, impSize;

    impSize = 256;
    impCount = 0;
    imps = NSZoneMalloc(NULL, sizeof(IMP) * impSize);
    
    // Gather all the method implementations of interest on this class before invoking any of them.  This is necessary since they might modify the ObjC runtime.
    iterator = NULL;

    while ((mlist = class_nextMethodList(metaClass, &iterator))) {
        struct objc_method *methods;
        int methodCount;

        methodCount = mlist->method_count;
        methods = &mlist->method_list[0];

        while (methodCount--) {
            if (methods->method_name == selectorToCall) {
                IMP imp;

                imp = methods->method_imp;

                // Store this implementation if it hasn't already been called
                if (!NSHashGet(calledImplementations, imp)) {
                    if (impCount >= impSize) {
                        impSize *= 2;
                        imps = NSZoneRealloc(NULL, imps, sizeof(IMP) * impSize);
                    }

                    imps[impCount] = imp;
                    impCount++;
                    NSHashInsertKnownAbsent(calledImplementations, imp);

#if defined(POSTLOADER_DEBUG)
                    fprintf(stderr, "Recording +[%s %s] (0x%08x)\n", aClass->name, sel_getName(selectorToCall), imp);
#endif
                }
            }
            methods++;
        }
    }

    if (impCount) {
        // In DP4, we crash if we call +class on %NSFileWrapper (HFSFileWrapper posing as NSFileWrapper).
        if (shouldInitialize && strcmp(aClass->name, "%NSFileWrapper") != 0) {
            NSAutoreleasePool *pool;

            pool = [[NSAutoreleasePool alloc] init];
#if defined(POSTLOADER_DEBUG)
            fprintf(stderr, "Initializing %s\n", aClass->name);
#endif
            // try to make sure +initialize gets called
            if (class_getClassMethod(aClass, @selector(class)))
                [aClass class];
            else if (class_getClassMethod(aClass, @selector(initialize)))
                // Avoid a compiler warning
                objc_msgSend(aClass, @selector(initialize));
            [pool release];
        }

        for (impIndex = 0; impIndex < impCount; impIndex++) {
            NSAutoreleasePool *pool;

            pool = [[NSAutoreleasePool alloc] init];
#if defined(POSTLOADER_DEBUG)
            fprintf(stderr, "Calling (0x%08x) ... ", imps[impIndex]);
#endif
            // We now call this within an exception handler because twice now we've released versions of OmniWeb where something would raise within +didLoad on certain configurations (not configurations we had available for testing) and weren't getting caught, resulting in an application that won't launch on those configurations.  We could insist that everyone do their own exception handling in +didLoad, but if we're going to potentially crash because a +didLoad failed I'd rather crash later than now.  (Especially since the exceptions in question were perfectly harmless.)
            NS_DURING {
                imps[impIndex](aClass, selectorToCall);
            } NS_HANDLER {
                fprintf(stderr, "Exception raised by +[%s %s]: %s\n", aClass->name, sel_getName(selectorToCall), [[localException reason] cString]);
            } NS_ENDHANDLER;
#if defined(POSTLOADER_DEBUG)
            fprintf(stderr, "done\n");
#endif
            [pool release];
        }
    }

    NSZoneFree(NULL, imps);

    return impCount != 0;
}


+ (void)_preventBundleInitialization;
{
    Class  bundleClass;
    Method bundleMethod, superMethod;

    // See if +[NSBundle initialize] is implemented.  If it is, we have are on an older system (like OpenStep 4.2) that we have an optimization for that makes the NSBundle stuff WAY faster.  But, on newer systems, +[NSBundle initialize] doesn't exist.  So, we have to make sure we don't get +[NSObject initialize] here!
    bundleClass = objc_getClass("NSBundle");
    bundleMethod = class_getClassMethod(bundleClass, @selector(initialize));
    superMethod = class_getClassMethod(bundleClass->super_class, @selector(initialize));

    if (!bundleMethod || bundleMethod == superMethod) {
        // NSBundle doesn't have its own implementation.
        NSBundleInitializeMethod = NULL;
    } else {
        NSBundleInitializeMethod = class_getClassMethod(bundleClass, @selector(initialize));
        originalNSBundleInitializeImplementation = NSBundleInitializeMethod->method_imp;
        NSBundleInitializeMethod->method_imp = (IMP)_NSBundleInitializationTooEarly;
    }
}

+ (void)_provokeBundleInitialization;
{
    //time_t t;
#ifndef WIN32
    IMP oldImp;
    Class pathStoreClass;
#endif

    if (!NSBundleInitializeMethod)
        // We didn't do anything in the first place...
        return;

    // Replace the original +[NSBundle initialize] implementation
    NSBundleInitializeMethod->method_imp = originalNSBundleInitializeImplementation;

    // Turn off symlink resolution in NSPathStore2.  This causes the seearch through the NSBundles to be vastly faster.

    // CHRIS Kane says this is necessary on NT to get the correct case in the file names since they are used as keys in a dictionary.
#ifndef WIN32
    // Prevent NSPathStore2 from actually resolving symlinks.
    // Don't provoke +initialize
    pathStoreClass = objc_getClass("NSPathStore2");
    oldImp = OBReplaceMethodImplementationWithSelector(pathStoreClass,                                                        @selector(stringByResolvingSymlinksInPath),                                                        @selector(replacement_stringByResolvingSymlinksInPath));
#endif

    //t = time(NULL);
    //fprintf(stderr, "%s: Intializing NSBundle...\n", ctime(&t));
    [NSBundle initialize];
    //t = time(NULL);
    //fprintf(stderr, "%s: Done initializing NSBundle.\n", ctime(&t));

#ifndef WIN32
    // Put the method back in case someone really needs to resolve symlinks
    OBReplaceMethodImplementation(pathStoreClass, @selector(stringByResolvingSymlinksInPath), oldImp);
#endif
}

+ (void)_becomingMultiThreaded:(NSNotification *)note;
{
    if (isSendingBecomingMultiThreaded)
        return;

    isSendingBecomingMultiThreaded = YES;

    NS_DURING {
        // Lets be thread-safe, shall we.
        if (!lock)
            lock = [[NSRecursiveLock alloc] init];

        [self processSelector:@selector(becomingMultiThreaded) initialize:NO];
    } NS_HANDLER {
        NSLog(@"Ignoring exception raised while sending -becomingMultiThreaded.  %@", localException);
    } NS_ENDHANDLER;

    isMultiThreaded = YES;
    isSendingBecomingMultiThreaded = NO;
}

@end
