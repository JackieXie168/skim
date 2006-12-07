// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import "OFIObjectNSInvocation.h"

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/Scheduling.subproj/OFIObjectNSInvocation.m,v 1.9 2003/01/15 22:52:02 kc Exp $")

@implementation OFIObjectNSInvocation;

static Class myClass;

+ (void)initialize;
{
    static BOOL initialized = NO;

    [super initialize];
    if (initialized)
	return;
    initialized = YES;

    myClass = self;
}

- initForObject:(id)anObject nsInvocation:(NSInvocation *)anInvocation;
{
    [super initForObject:anObject];
    nsInvocation = [anInvocation retain];
    return self;
}

- (void)dealloc;
{
    [nsInvocation release];
    [super dealloc];
}

- (void)invoke;
{
    [nsInvocation invokeWithTarget:object];
}

- (unsigned int)hash;
{
    return (unsigned int)object + [nsInvocation hash];
}

- (BOOL)isEqual:(id)anObject;
{
    OFIObjectNSInvocation *otherInvocation;

    otherInvocation = anObject;
    if (otherInvocation->isa != myClass)
	return NO;
    return object == otherInvocation->object && [nsInvocation isEqual:otherInvocation->nsInvocation];
}

- (NSMutableDictionary *)debugDictionary;
{
    NSMutableDictionary *debugDictionary;

    debugDictionary = [super debugDictionary];
    if (object)
	[debugDictionary setObject:object forKey:@"object"];
    if (nsInvocation)
	[debugDictionary setObject:nsInvocation forKey:@"nsInvocation"];
    return debugDictionary;
}

- (NSString *)shortDescription;
{
    return [NSString stringWithFormat:@"-[%@ %@%d]", OBShortObjectDescription(object), [nsInvocation description]];
}

@end
