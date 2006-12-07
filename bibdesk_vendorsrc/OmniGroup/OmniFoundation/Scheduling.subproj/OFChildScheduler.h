// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/Scheduling.subproj/OFChildScheduler.h,v 1.6 2003/01/15 22:52:01 kc Exp $

#import <OmniFoundation/OFScheduler.h>

@interface OFChildScheduler : OFScheduler
{
    OFScheduler *parent;
    OFScheduledEvent *parentAlarmEvent;
}

- initWithParentScheduler:(OFScheduler *)aParent;

@end
