// Copyright 2005-2006 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OFDimensionedValue.h"

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>
#import <OmniFoundation/OmniFoundation.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/DataStructures.subproj/OFDimensionedValue.m 79079 2006-09-07 22:35:32Z kc $");

@implementation OFDimensionedValue

+ (OFDimensionedValue *)valueWithDimension:(OFUnit *)dim integerValue:(int)i;
{
    return [self valueWithDimension:dim value:[NSNumber numberWithInt:i]];
    
}

+ (OFDimensionedValue *)valueWithDimension:(OFUnit *)dim value:(NSNumber *)r;
{
    if (!r)
        return nil;
    return [[[self alloc] initWithDimension:dim value:r] autorelease];
}

- initWithDimension:(OFUnit *)dim value:(NSNumber *)r;
{
    self = [super init];
    value = [r retain];
    dimension = [dim retain];
    return self;
}

- (void)dealloc
{
    [value release];
    [dimension release];
    [super dealloc];
}

- (NSNumber *)value;
{
    return value;
}

- (OFUnit *)dimension;
{
    return dimension;
}

- (BOOL)isEqual:anotherObject_
{
    if (!anotherObject_)
        return NO;
    
    if(![anotherObject_ isKindOfClass:[self class]])
        return NO;
    
    OFDimensionedValue *anotherObject = anotherObject_;
    
    OFUnit *otherDimension = [anotherObject dimension];
    if (dimension != otherDimension && ![dimension isEqual:otherDimension])
        return NO;
    NSNumber *otherValue = [anotherObject value];
    if (value != otherValue && ![value isEqual:otherValue])
        return NO;
    
    return YES;
}

@end

