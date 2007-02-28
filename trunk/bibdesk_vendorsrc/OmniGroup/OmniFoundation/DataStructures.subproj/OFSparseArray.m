// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/OFSparseArray.h>

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

#import <OmniFoundation/OFNull.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/DataStructures.subproj/OFSparseArray.m 68913 2005-10-03 19:36:19Z kc $")

@implementation OFSparseArray

static OFNull *nullValue = nil;

+ (void)initialize;
{
    OBINITIALIZE;

    nullValue = (id)[[OFNull nullStringObject] retain];
}

- initWithCapacity:(unsigned int)aCapacity;
{
    if (![super init])
	return nil;

    values = [[NSMutableArray alloc] initWithCapacity:aCapacity];
    valuesLength = 0;

    return self;
}

- init;
{
    return [self initWithCapacity:0];
}

- (void)dealloc;
{
    [values release];
    [defaultValue release];
    [super dealloc];
}

- (unsigned int)count;
{
    return valuesLength;
}

- (id)objectAtIndex:(unsigned int)anIndex;
{
    id value;

    if (anIndex >= valuesLength)
	return defaultValue;
    value = [values objectAtIndex:anIndex];
    if (value == nullValue)
	return defaultValue;
    return value;
}

static inline void setValuesLength(OFSparseArray *self, unsigned int anIndex)
{
    while (self->valuesLength < anIndex) {
	[self->values addObject:nullValue];
	self->valuesLength++;
    }
}

- (void)setObject:(id)anObject atIndex:(unsigned int)anIndex;
{
    if (!anObject || anObject == defaultValue)
	anObject = nullValue;
    if (anIndex < self->valuesLength) {
	[self->values replaceObjectAtIndex:anIndex withObject:anObject];
    } else if (anObject != nullValue) {
	setValuesLength(self, anIndex);
	[values addObject:anObject];
	valuesLength++;
    }
}

- (void)setDefaultValue:(id)aDefaultValue;
{
    if (defaultValue != aDefaultValue) {
	[defaultValue release];
        defaultValue = [aDefaultValue retain];
    }
}

- (NSArray *)valuesArray;
{
    return values;
}

// OBObject subclass
- (NSMutableDictionary *)debugDictionary;
{
    return (id)values;
}

@end
