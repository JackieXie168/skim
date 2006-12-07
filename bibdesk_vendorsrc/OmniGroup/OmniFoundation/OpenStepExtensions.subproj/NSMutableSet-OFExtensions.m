// Copyright 2002-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import "NSMutableSet-OFExtensions.h"

#import <Foundation/Foundation.h>
#import <OmniBase/rcsid.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSMutableSet-OFExtensions.m,v 1.3 2003/01/15 22:52:00 kc Exp $");

@implementation NSMutableSet (OFExtensions)

- (void) removeObjectsFromArray: (NSArray *) objects;
{
    unsigned int objectIndex;
    
    objectIndex = [objects count];
    while (objectIndex--)
        [self removeObject: [objects objectAtIndex: objectIndex]];
}

- (void) exclusiveDisjoinSet: (NSSet *) otherSet;
{
    NSEnumerator *otherEnumerator;
    id otherElement;

    /* special case: avoid modifying set while enumerating over it */
    if (otherSet == self) {
        [self removeAllObjects];
        return;
    }

    /* general case */
    otherEnumerator = [otherSet objectEnumerator];
    while( (otherElement = [otherEnumerator nextObject]) != nil ) {
        if ([self containsObject:otherElement])
            [self removeObject:otherElement];
        else
            [self addObject:otherElement];
    }
}


@end
