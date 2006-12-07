// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import <OmniFoundation/OFCondition.h>

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/Locks.subproj/OFCondition.m,v 1.5 2003/01/15 22:51:58 kc Exp $")

@implementation OFCondition

- init;
{
    if (![super init])
        return nil;

    lock = [[NSConditionLock alloc] init];
    flags.cleared = NO;

    return self;
}

- (void)dealloc;
{
    [lock release];
    [super dealloc];
}

- (void)waitForCondition;
{
    if (flags.cleared)
        return;
    [lock lockWhenCondition:1];
    if (!flags.cleared) {
        // TODO: If anyone else is waiting on this condition (say, if two data cursors are reading from the same data stream), they'll hang here until -clearCondition is called because we just reset their condition.
        [lock unlockWithCondition:0];
    } else {
        [lock unlock];
    }
}

- (void)signalCondition;
{
    [lock lock];
    [lock unlockWithCondition:1];
}

- (void)broadcastCondition;
{
    [lock lock];
    [lock unlockWithCondition:1];
}

- (void)clearCondition;
{
    flags.cleared = YES;
    [lock lock];
    [lock unlockWithCondition:1];
}

@end
