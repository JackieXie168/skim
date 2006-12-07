// Copyright 2003-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniAppKit/OAInspectionSet.h>

#import <OmniFoundation/CFSet-OFExtensions.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Inspector.subproj/OAInspectionSet.m,v 1.6 2004/02/10 04:07:32 kc Exp $");

@implementation OAInspectionSet

// Init and dealloc

- init;
{
    if (!(self = [super init]))
        return nil;

    // We want pointer equality, not content equality (particularly for OAStyle)
    _objects = OFCreatePointerEqualObjectSet();
    return self;
}

- (void)dealloc;
{
    [_objects release];
    [super dealloc];
}

//
// API
//

- (void)addObject:(id)object;
{
    [_objects addObject:object];
}

- (void)addObjectsFromArray:(NSArray *)objects;
{
    [_objects addObjectsFromArray:objects];
}

- (void)removeObject:(id)object;
{
    [_objects removeObject:object];
}

- (BOOL)containsObject:(id)object;
{
    return ([_objects member:object] != nil);
}

- (NSArray *)allObjects;
{
    return [_objects allObjects];
}

- (NSArray *)objectsOfClass:(Class)cls;
{
    NSMutableArray *filteredObjects = nil;
    NSEnumerator   *objectEnum;
    id              object;

    objectEnum = [_objects objectEnumerator];
    while ((object = [objectEnum nextObject])) {
        if ([object isKindOfClass:cls]) {
            if (!filteredObjects)
                filteredObjects = [NSMutableArray array];
            [filteredObjects addObject:object];
        }
    }

    return filteredObjects;
}

- (void)removeObjectsOfClass:(Class)cls;
{
    // Can't modify a set we are enumerating, so collect objects to remove up front.
    NSArray *toRemove = [self objectsOfClass:cls];

    unsigned int objectIndex;
    objectIndex = [toRemove count];
    while (objectIndex--)
        [self removeObject:[toRemove objectAtIndex:objectIndex]];
}

//
// Debugging
//
- (NSMutableDictionary *)debugDictionary;
{
    NSMutableDictionary *dict = [super debugDictionary];

    [dict setObject:_objects forKey: @"_objects"];
    return dict;
}

@end
