// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import <OmniFoundation/NSThread-OFExtensions.h>

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>
#import <OmniBase/system.h>


#ifdef __MACH__
#import <mach/mach.h>
#import <mach/mach_init.h>
#import <mach/mach_error.h>
#endif

#import <OmniFoundation/OFMessageQueue.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSThread-OFExtensions.m,v 1.25 2003/01/15 22:52:01 kc Exp $")

@implementation NSThread (OFExtensions)

static NSThread *mainThread = nil;
static NSConditionLock *mainThreadInterlock = nil;
static unsigned int threadsWaiting;
static unsigned int recursionCount;
static NSThread *substituteMainThread = nil;

enum {
    THREADS_WAITING, NO_THREADS_WAITING
};

+ (void)didLoad;
{
    [self setMainThread];
}

+ (void)setMainThread;
{
    NSThread *newThread;

    newThread = [NSThread currentThread];
    if (mainThread) {
        if (newThread != mainThread) {
            NSLog(@"+[NSThread setMainThread called multiple times in different threads");
        }
    }

    if (!mainThread) {
        mainThreadInterlock = [[NSConditionLock alloc] init];
        [mainThreadInterlock lock];
        threadsWaiting = 0;
        recursionCount = 0;
    }

    // Even in the error case above, don't leak an NSThread
    [mainThread autorelease];
    mainThread = [newThread retain];
}

+ (NSThread *)mainThread;
{
    if (!mainThread) {
        NSLog(@"Warning: +[NSThread setMainThread] not called early enough!");
        [self setMainThread];
    }

    return mainThread;
}

+ (BOOL)inMainThread;
{
    if (!mainThread) {
        NSLog(@"Warning: +[NSThread setMainThread] not called early enough!");
        [self setMainThread];
    }
    return [self currentThread] == mainThread;
}

+ (BOOL)mainThreadOpsOK;
{
    return ([self inMainThread] || ([self currentThread] == substituteMainThread));
}
    
+ (void)lockMainThread;
{
    if ([self inMainThread])
        return;

    if ([self currentThread] == substituteMainThread) {
        recursionCount++;
        return;
    }
    
    threadsWaiting++;
    [[OFMessageQueue mainQueue] queueSelectorOnce:@selector(yieldMainThreadLock) forObject:mainThread];
    [mainThreadInterlock lock];
    OBASSERT(substituteMainThread == nil);
    substituteMainThread = [self currentThread];
    recursionCount = 1;
}

+ (void)unlockMainThread;
{
    if ([self inMainThread])
        return;

    OBASSERT(substituteMainThread == [self currentThread]);
    
    if (--recursionCount)
        return;
    
    substituteMainThread = nil;

    if (--threadsWaiting > 0)
        [mainThreadInterlock unlockWithCondition:THREADS_WAITING];
    else
        [mainThreadInterlock unlockWithCondition:NO_THREADS_WAITING];
}

- (void)yield;
{
    if (![self yieldMainThreadLock])
        sched_yield();
}

- (BOOL)yieldMainThreadLock;
{
    if (self != mainThread || threadsWaiting == 0)
        return NO;
    [mainThreadInterlock unlockWithCondition:THREADS_WAITING];
    [mainThreadInterlock lockWhenCondition:NO_THREADS_WAITING];
    return YES;
}

- (void)setName:(NSString *)aName
{
// #ifdef DEBUG
#if !defined(NeXT_PDO) && !defined(sun) && OBOperatingSystemMajorVersion < 5
#warning -[NSThread setName:] should be disabled for production builds.
    char *buf;
    NSData *newNameData;
    
    // These gyrations are necessary because the cthread library does not copy the name; it merely remembers the pointer.

    buf = alloca([aName cStringLength] + 1);
    [aName getCString:buf];
    newNameData = [[NSData alloc] initWithBytes:buf length:1 + strlen(buf)];
    cthread_set_name(cthread_self(), [newNameData bytes]);
    // this next line also deallocates the old name buffer if any
    [[self threadDictionary] setObject:newNameData forKey:@"nameData"];
    [newNameData release];
#endif
    
// #endif /* DEBUG */
}

+ (BOOL) enabledFixedPriorityMode;
{
#if defined(__MACH__) && (OBOperatingSystemMajorVersion <= 5)
    kern_return_t       error;
    processor_set_t     default_set, default_set_priv;
    struct processor_set_sched_info set_sched_info;
    host_t              host;
    int         processor_set_sched_info_count =
                    PROCESSOR_SET_SCHED_INFO_COUNT;

#if 0
    // TJW - There is a bug in MacOS X Server where if you have a process
    // running in the debugger in a Terminal window and the process is
    // using fixed priority threads, AND you resize the window, the
    // entire machine will crash.
    //
    // This is a hack to avoid that.  This is the address, determined via
    // 'nm /usr/lib/dyld' of the port used for the debug server.  If this
    // is non-zero, then we are in the debugger and we will not turn on
    // fixed priority.  I tried using the varioud dyld APIs to get this
    // variable w/o hardcoding the address, but I was unable to do so
    // since the APIs apparently won't inspect dyld itself.
    //
    // Hopefully this shouldn't matter though since this (a) shouldn't
    // change very often, (b) shouldn't be used by many programs and
    // (c) the consequences are pretty obvious if this fails to work.
    //
    // I *could* examine the mach header for the current process, find
    // its dylinker, open that file, find the symbol therein, and lookup
    // the value that way, but that would be a LOT of work.
    {
        port_t *debugPort = (port_t *)0x4112c50c;

        if (*debugPort) {
            fprintf(stderr, "This process is running under the debugger -- fixed priority threads disabled.\n");
            return NO;
        }
    }
#else
    // dyld DID change in the latest MacOS X Server patch.  Instead of attacking
    // the problem this way, we'll simple check if we are being run from the
    // command line.
    if (isatty(fileno(stdin))) {
        fprintf(stderr, "This process is running in Terminal -- fixed priority threads disabled.\n");
        return NO;
    }
#endif
    
    error = processor_set_default(host_self(), &default_set);
    if (error != KERN_SUCCESS) {
        mach_error("Error calling processor_set_default()", error);
        return NO;
    }

    /* Maybe fixed priorities are already enabled */
    error = processor_set_info(default_set, PROCESSOR_SET_SCHED_INFO,
            &host, (void *)&set_sched_info, &processor_set_sched_info_count);
    if (set_sched_info.policies & POLICY_FIXEDPRI)
        return YES;

    /* Fix default processor set to take a fixed priority thread. */
    error = host_processor_set_priv(host_priv_self(), default_set, &default_set_priv);
    if (error != KERN_SUCCESS) {
        mach_error("Call to host_processor_set_priv() failed", error);
        return NO;
    }
    error = processor_set_policy_enable(default_set_priv, POLICY_FIXEDPRI);
    if (error != KERN_SUCCESS) {
        mach_error("Call to processor_set_policy_enable() failed", error);
        return NO;
    }

    return YES;
#else
    return NO;
#endif
}

#define QUANTUM 100          /* in ms */
#define MAX_SAFE_PRIORITY 23 /* Sez Mike Paquette @ NeXT */

+ (void) maximizePriority;
{
#if defined(__MACH__) && (OBOperatingSystemMajorVersion <= 5)
    int                 info[THREAD_INFO_MAX];
    kern_return_t       error;
    thread_sched_info_t scheduleInfo;
    unsigned int        count = THREAD_INFO_MAX;
    thread_t            thread;

    thread = thread_self();
    error = thread_info(thread, THREAD_SCHED_INFO, (thread_info_t) info, &count);
    if (error != KERN_SUCCESS) {
        mach_error("Can't get thread scheduling info", error);
        return;
    }

    scheduleInfo = (thread_sched_info_t) info;

    /*
     * Check for special strange case of priority greater than max, as can
     * happen with nice -20!.
     */
    if (scheduleInfo->base_priority < scheduleInfo->max_priority) {

        error = thread_policy(thread, POLICY_FIXEDPRI, QUANTUM);
        if (error != KERN_SUCCESS) {
            mach_error("Can't set thread policy to fixed", error);
            return;
        }

        error = thread_priority(thread, MIN(scheduleInfo->max_priority, MAX_SAFE_PRIORITY), 0);
        if (error != KERN_SUCCESS)
            mach_error("Can't set thread priority", error);
    }
#endif
}


@end
