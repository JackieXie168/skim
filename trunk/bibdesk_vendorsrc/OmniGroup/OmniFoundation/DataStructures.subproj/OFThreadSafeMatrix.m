// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/OFThreadSafeMatrix.h>

#import <Foundation/NSLock.h>
#import <OmniBase/OmniBase.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/DataStructures.subproj/OFThreadSafeMatrix.m 68913 2005-10-03 19:36:19Z kc $")

@implementation OFThreadSafeMatrix

- init;
{
    if (![super init])
	return nil;

    lock = [[NSRecursiveLock alloc] init];

    return self;
}

- (void)dealloc;
{
    [lock release];
    [super dealloc];
}

- objectAtRowIndex:(unsigned int)rowIndex
  columnIndex:(unsigned int)columnIndex;
{
    id                          object;

    [lock lock];
    object = [super objectAtRowIndex:rowIndex columnIndex:columnIndex];
    [[object retain] autorelease];
    [lock unlock];
    return object;
}

- (void)setObject:anObject
  atRowIndex:(unsigned int)rowIndex columnIndex:(unsigned int)columnIndex;
{
    [lock lock];
    [super setObject:anObject atRowIndex:rowIndex columnIndex:columnIndex];
    [lock unlock];
}

- (void)setObject:anObject
  atRowIndex:(unsigned int)rowIndex span:(unsigned int)aRowCount
  columnIndex:(unsigned int)columnIndex span:(unsigned int)aColCount;
{
    [lock lock];
    [super setObject:anObject atRowIndex:rowIndex span:aRowCount
     columnIndex:columnIndex span:aColCount];
    [lock unlock];
}

- (unsigned int)rowCount;
{
    int                         count;

    [lock lock];
    count = [super rowCount];
    [lock unlock];

    return count;
}

- (unsigned int)columnCount;
{
    int                         count;

    [lock lock];
    count = [super columnCount];
    [lock unlock];

    return count;
}


@end
