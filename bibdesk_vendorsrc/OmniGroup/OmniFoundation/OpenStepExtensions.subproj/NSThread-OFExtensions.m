// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
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

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSThread-OFExtensions.m,v 1.29 2004/02/10 04:07:46 kc Exp $")

@implementation NSThread (OFExtensions)

static NSThread *mainThread = nil;
static NSConditionLock *mainThreadInterlock = nil;
#warning Access to our threadsWaiting variable is not thread safe
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

@end
