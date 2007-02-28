// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

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

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSThread-OFExtensions.m 68913 2005-10-03 19:36:19Z kc $")

@implementation NSThread (OFExtensions)

static NSThread *mainThread;
static NSConditionLock *mainThreadInterlock;
static NSLock *threadsWaitingLock;
static unsigned int threadsWaiting;
static unsigned int recursionCount;
static NSThread *substituteMainThread;

enum {
    THREADS_WAITING, NO_THREADS_WAITING
};

+ (void)didLoad;
{
    [self setMainThread];
}

+ (void)setMainThread;
{
    NSThread *currentThread = [NSThread currentThread];

    if (mainThread != nil) {
        if (currentThread != mainThread) {
            NSLog(@"+[NSThread setMainThread called multiple times in different threads");
        }
    }

    if (mainThreadInterlock == nil) {
        mainThreadInterlock = [[NSConditionLock alloc] init];
        [mainThreadInterlock lock];
        threadsWaitingLock = [[NSLock alloc] init];
        threadsWaiting = 0;
        recursionCount = 0;
    }

    // Even in the error case above, don't leak an NSThread
    [mainThread autorelease];
    mainThread = [currentThread retain];
}

+ (NSThread *)mainThread;
{
    if (mainThread == nil) {
#ifdef DEBUG
        NSLog(@"Warning: +[NSThread setMainThread] not called early enough!");
#endif
        [self setMainThread];
    }

    return mainThread;
}

+ (BOOL)inMainThread;
{
    if (mainThread == nil) {
#ifdef DEBUG
        NSLog(@"Warning: +[NSThread setMainThread] not called early enough!");
#endif
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

    [threadsWaitingLock lock];
    threadsWaiting++;
    [threadsWaitingLock unlock];
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

    [threadsWaitingLock lock];
    if (--threadsWaiting > 0)
        [mainThreadInterlock unlockWithCondition:THREADS_WAITING];
    else
        [mainThreadInterlock unlockWithCondition:NO_THREADS_WAITING];
    [threadsWaitingLock unlock];
}

- (void)yield;
{
    if (![self yieldMainThreadLock])
        sched_yield();
}

- (BOOL)yieldMainThreadLock;
{
    if (self != mainThread)
        return NO;

    BOOL noThreadsWaiting;

    [threadsWaitingLock lock];
    noThreadsWaiting = (threadsWaiting == 0);
    [threadsWaitingLock unlock];
    if (noThreadsWaiting)
        return NO;

    [mainThreadInterlock unlockWithCondition:THREADS_WAITING];
    [mainThreadInterlock lockWhenCondition:NO_THREADS_WAITING];

    return YES;
}

@end
