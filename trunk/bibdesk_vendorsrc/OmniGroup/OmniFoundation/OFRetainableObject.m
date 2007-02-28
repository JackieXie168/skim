// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/OFRetainableObject.h>

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/OFRetainableObject.m 68913 2005-10-03 19:36:19Z kc $")

@implementation OFRetainableObject

+ (void) initialize;
{
}

+ alloc;
{
    return [self allocWithZone:NULL];
}

+ allocWithZone:(NSZone *)aZone;
{
    return NSAllocateObject(self, 0, aZone);
}

- (Class)class;
{
    return isa;
}

- (unsigned)retainCount;
{
    return NSExtraRefCount(self) + 1;
}

- (id)retain;
{
    NSIncrementExtraRefCount(self);
    return self;
}

- (void)release;
{
    if (NSDecrementExtraRefCountWasZero(self))
	[self dealloc];
}

- (id)autorelease;
{
    [NSAutoreleasePool addObject:self];
    return self;
}

- (void)dealloc;
{
    NSDeallocateObject((id <NSObject>)self);
}


@end
