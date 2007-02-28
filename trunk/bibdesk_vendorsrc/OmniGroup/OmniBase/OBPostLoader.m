// Copyright 1997-2006 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniBase/OBPostLoader.h>

#import <OmniBase/OBUtilities.h>
#import <OmniBase/assertions.h>

#import <Foundation/Foundation.h>
#import <objc/objc-class.h>
#import <objc/objc-runtime.h>
#import <OmniBase/rcsid.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniBase/OBPostLoader.m 79079 2006-09-07 22:35:32Z kc $")

static NSRecursiveLock *lock = nil;
static NSHashTable *calledImplementations = NULL;
static BOOL isMultiThreaded = NO;
static BOOL isSendingBecomingMultiThreaded = NO;

extern void _objc_resolve_categories_for_class(struct objc_class *cls);

@interface OBPostLoader (PrivateAPI)
+ (BOOL)_processSelector:(SEL)selectorToCall inClass:(Class)aClass initialize:(BOOL)shouldInitialize;
+ (void)_becomingMultiThreaded:(NSNotification *)note;
@end

//#define POSTLOADER_DEBUG

@implementation OBPostLoader
/*"
OBPostLoader provides the functionality that you might expect to get from implementing a +load method.  Unfortunately, some implementations of OpenStep have bugs with their implementation of +load.  Rather than attempt to use +load, OBPostLoader provides similar functionality that actually works.  Early in your program startup, you should call +processClasses.  This will go through the ObjC runtime and invoke all of the +performPosing and +didLoad methods.  Each class may have multiple implementations of each of theses selectors -- all will be called.

OBPostLoader listens for bundle loaded notifications and will automatically reinvoke +processClasses to perform any newly loaded methods.

OBPostLoader also listens for NSBecomingMultiThreaded and will invoke every implementation of +becomingMultiThreaded.
"*/

+ (void)initialize;
{
    OBINITIALIZE;

    // Set this up before we call any method implementations
    calledImplementations = NSCreateHashTable(NSNonOwnedPointerHashCallBacks, 0);

    // If any other bundles get loaded, make sure that we process them too.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bundleDidLoad:) name:NSBundleDidLoadNotification object:nil];

    // Register for the multi-threadedness here so that most classes won't have to
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_becomingMultiThreaded:) name:NSWillBecomeMultiThreadedNotification object:nil];
}

/*"
Searches the ObjC runtime for particular methods and invokes them.  Each implementation will be invoked exactly once.  Currently, there is no guarantee on the order that these messages will occur.  This should be called as the first line of main().  Once this has been called at the beginning of main, it will automatically be called each time a bundle is loaded (view the NSBundle loading notification).

This method makes several passes, each time invoking a different selector.  On the first pass, +performPosing implementations are invoked, allowing modifictions to the ObjC runtime to happen early (before +initialize).  Then, +didLoad implementations are processed.
"*/
+ (void)processClasses;
{
    [self processSelector:@selector(performPosing) initialize:NO];
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
        unsigned int classCount = 0, newClassCount;
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

                // TJW: After some investiation, I tracked down the ObjC runtime bug that Steve was running up against in OmniOutliner when he needed to add this (I also hit it in OmniGraffle when trying to get rid of this line).  The bug is essentially that categories don't get registered when you pose before +initialize.  Logged as Radar #3319132.
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
                    fprintf(stderr, "Recording +[%s %s] (0x%08x)\n", aClass->name, sel_getName(selectorToCall), (int)imp);
#endif
                }
            }
            methods++;
        }
    }

    if (impCount) {
        if (shouldInitialize) {
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
            fprintf(stderr, "Calling (0x%08x) ... ", (int)imps[impIndex]);
#endif
            // We now call this within an exception handler because twice now we've released versions of OmniWeb where something would raise within +didLoad on certain configurations (not configurations we had available for testing) and weren't getting caught, resulting in an application that won't launch on those configurations.  We could insist that everyone do their own exception handling in +didLoad, but if we're going to potentially crash because a +didLoad failed I'd rather crash later than now.  (Especially since the exceptions in question were perfectly harmless.)
            NS_DURING {
                // We discovered that we'll crash if we use aClass after it has posed as another class.  So, we go look up the imposter class that resulted from the +poseAs: and use it instead.
                Class imposterClass = objc_getClass(metaClass->name);
                if (imposterClass != Nil)
                    aClass = imposterClass;
                
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
