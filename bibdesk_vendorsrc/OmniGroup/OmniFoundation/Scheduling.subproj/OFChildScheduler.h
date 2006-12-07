// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/Scheduling.subproj/OFChildScheduler.h,v 1.8 2004/02/10 04:07:46 kc Exp $

#import <OmniFoundation/OFScheduler.h>

@interface OFChildScheduler : OFScheduler
{
    OFScheduler *parent;
    OFScheduledEvent *parentAlarmEvent;
}

- initWithParentScheduler:(OFScheduler *)aParent;

@end
