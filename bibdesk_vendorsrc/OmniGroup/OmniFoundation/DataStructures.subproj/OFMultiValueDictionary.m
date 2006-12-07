// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import <OmniFoundation/OFMultiValueDictionary.h>

#import <OmniFoundation/CFDictionary-OFExtensions.h>
#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/DataStructures.subproj/OFMultiValueDictionary.m,v 1.20 2003/01/15 22:51:54 kc Exp $")

@implementation OFMultiValueDictionary

- init;
{
    return [self initWithCaseInsensitiveKeys: NO];
}

- initWithCaseInsensitiveKeys: (BOOL) caseInsensitivity;
{
    if (caseInsensitivity)
        dictionary = OFCreateCaseInsensitiveKeyMutableDictionary();
    else
        dictionary = [[NSMutableDictionary allocWithZone:[self zone]] init];

    return self;
}

- (void)dealloc;
{
    [dictionary release];
    [super dealloc];
}

- (NSArray *)arrayForKey:(NSString *)aKey;
{
    return [dictionary objectForKey:aKey];
}

- (id)firstObjectForKey:(NSString *)aKey;
{
    return [[dictionary objectForKey:aKey] objectAtIndex:0];
}

- (id)lastObjectForKey:(NSString *)aKey;
{
    return [[dictionary objectForKey:aKey] lastObject];
}

- (void)addObject:(id)anObject forKey:(NSString *)aKey;
{
    NSMutableArray *valueArray;

    valueArray = [dictionary objectForKey:aKey];
    if (!valueArray) {
	valueArray = [NSMutableArray arrayWithObject:anObject];
	[dictionary setObject:valueArray forKey:aKey];
    } else
	[valueArray addObject:anObject];
}

- (void)addObjects:(NSArray *)moreObjects forKey:(NSString *)aKey;
{
    NSMutableArray *valueArray;

    valueArray = [dictionary objectForKey:aKey];
    if (!valueArray) {
        valueArray = [[NSMutableArray alloc] initWithArray:moreObjects];
        [dictionary setObject:valueArray forKey:aKey];
        [valueArray release];
    } else
        [valueArray addObjectsFromArray:moreObjects];
}

- (void)removeObject:(id)anObject forKey:(NSString *)aKey
{
    NSMutableArray *valueArray = [dictionary objectForKey:aKey];
    unsigned int objectIndex;
    
    if (!valueArray)
        return;
    
    objectIndex = [valueArray indexOfObject:anObject];
    if (objectIndex == NSNotFound)
        return;
    
    [valueArray removeObjectAtIndex:objectIndex];
    
    if ([valueArray count] == 0)
        [dictionary removeObjectForKey:aKey];
}


- (NSEnumerator *)keyEnumerator;
{
    return [dictionary keyEnumerator];
}

- (NSArray *)allKeys;
{
    return [dictionary allKeys];
}

- (NSArray *)allValues;
{
    NSArray *arrays;
    unsigned int arrayIndex, arrayCount;
    NSMutableArray *allValues;
    
    allValues = [NSMutableArray array];

    arrays = [dictionary allValues];
    arrayCount = [arrays count];
    for (arrayIndex = 0; arrayIndex < arrayCount; arrayIndex++) {
        [allValues addObjectsFromArray:[arrays objectAtIndex:arrayIndex]];
    }
    
    return allValues;
}

- (NSMutableDictionary *)dictionary;
{
    return dictionary;
}

- mutableCopyWithZone:(NSZone *)newZone
{
    OFMultiValueDictionary *newSelf;
    NSMutableDictionary *otherDictionary;
    NSString *aKey;
    NSEnumerator *keyEnumerator;
    
    newSelf = [[[self class] allocWithZone:newZone] init];
    otherDictionary = [newSelf dictionary];
    keyEnumerator = [dictionary keyEnumerator];
    while( (aKey = [keyEnumerator nextObject]) != nil) {
        NSArray *myArray = [dictionary objectForKey:aKey];
        NSMutableArray *arrayCopy = [[NSMutableArray allocWithZone:newZone] initWithCapacity:[myArray count]];
        [arrayCopy addObjectsFromArray:myArray];
        [otherDictionary setObject:arrayCopy forKey:aKey];
        [arrayCopy release];
    }
    
    return newSelf;
}

- mutableCopy
{
    return [self mutableCopyWithZone:NULL];
}

// Debugging

- (NSMutableDictionary *)debugDictionary;
{
    NSMutableDictionary *debugDictionary;

    debugDictionary = [super debugDictionary];
    if (dictionary)
	[debugDictionary setObject:dictionary forKey:@"dictionary"];
    return debugDictionary;
}

@end
