// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/OFResultHolder.h>

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/Scheduling.subproj/OFResultHolder.m,v 1.11 2004/02/10 04:07:47 kc Exp $")

@implementation OFResultHolder

enum {RESULT_NOT_AVAILABLE, RESULT_AVAILABLE};

- init;
{
    if ([super init] == nil)
        return nil;
    result = nil;
    resultLock = [[NSConditionLock alloc] initWithCondition:RESULT_NOT_AVAILABLE];
    return self;
}

- (void)dealloc;
{
    [result release];
    [resultLock release];
    [super dealloc];
}

- (void)setResult:(id)newResult;
{
    [resultLock lock];
    if (result != newResult) {
        [result release];
        result = [newResult retain];
    }
    [resultLock unlockWithCondition:RESULT_AVAILABLE];
}

- (id)result;
{
    id resultSnapshot;

    [resultLock lockWhenCondition:RESULT_AVAILABLE];
    resultSnapshot = [result retain];
    [resultLock unlock];
    return [resultSnapshot autorelease];
}

- (id)getResult;
    // Deprecated API
{
    return [self result];
}

@end
