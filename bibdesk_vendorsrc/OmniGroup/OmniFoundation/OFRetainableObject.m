// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import <OmniFoundation/OFRetainableObject.h>

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OFRetainableObject.m,v 1.10 2003/01/15 22:51:50 kc Exp $")

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
