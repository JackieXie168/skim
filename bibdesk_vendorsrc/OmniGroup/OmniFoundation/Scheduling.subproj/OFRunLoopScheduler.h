// Copyright 1999-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/Scheduling.subproj/OFRunLoopScheduler.h,v 1.7 2004/02/10 04:07:47 kc Exp $

#import <OmniFoundation/OFScheduler.h>

@class NSTimer;

@interface OFRunLoopScheduler : OFScheduler
{
    NSTimer *alarmTimer;
}

+ (OFRunLoopScheduler *)runLoopScheduler;

@end
