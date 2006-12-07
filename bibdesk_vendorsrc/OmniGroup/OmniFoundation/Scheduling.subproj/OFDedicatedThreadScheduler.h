// Copyright 1999-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/Scheduling.subproj/OFDedicatedThreadScheduler.h,v 1.5 2003/01/15 22:52:02 kc Exp $

#import <OmniFoundation/OFScheduler.h>

@class NSConditionLock, NSLock;

@interface OFDedicatedThreadScheduler : OFScheduler
{
    NSConditionLock *scheduleConditionLock;
    NSConditionLock *mainThreadSynchronizationLock;
    NSDate *wakeDate;
    NSLock *wakeDateLock;
    struct {
        unsigned int invokesEventsInMainThread:1;
    } flags;
}

+ (OFDedicatedThreadScheduler *)dedicatedThreadScheduler;

- (void)setInvokesEventsInMainThread:(BOOL)shouldInvokeEventsInMainThread;
- (void)runScheduleForeverInNewThread;
- (void)runScheduleForeverInCurrentThread;

@end
