// Copyright 1999-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/Scheduling.subproj/OFRunLoopScheduler.h,v 1.5 2003/01/15 22:52:03 kc Exp $

#import <OmniFoundation/OFScheduler.h>

@class NSTimer;

@interface OFRunLoopScheduler : OFScheduler
{
    NSTimer *alarmTimer;
}

+ (OFRunLoopScheduler *)runLoopScheduler;

@end
