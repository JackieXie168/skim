// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/OFSlotManager.h>

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

#import <OmniFoundation/OFBitField.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/DataStructures.subproj/OFSlotManager.m 68913 2005-10-03 19:36:19Z kc $")

@implementation OFSlotManager

- (void) _setCurrentSlotCount: (unsigned int) newCurrentSlotCount;
{
    unsigned int                anIndex;
    NSZone                     *myZone = [self zone];

    OBPRECONDITION(newCurrentSlotCount > currentSlotCount &&
		 newCurrentSlotCount <= maxSlotCount);
    OBPRECONDITION(nextFreeSlot == currentSlotCount);

    if (!slots) {
	OBASSERT(!fullSlots);
        slots = (id *)NSZoneMalloc(myZone, sizeof(id) * newCurrentSlotCount);
	fullSlots = [[OFBitField allocWithZone:myZone] initWithLength:newCurrentSlotCount];
    } else {
	OBASSERT(fullSlots);
        slots = (id *)NSZoneRealloc(myZone, slots, sizeof(id) * newCurrentSlotCount);
	[fullSlots setLength:newCurrentSlotCount];
    }

    /* Extend the internal free list */
    for (anIndex = currentSlotCount; anIndex < newCurrentSlotCount; anIndex++)
	slots[anIndex] = (id)(anIndex + 1);

    currentSlotCount = newCurrentSlotCount;

    if (!currentSlotCount)
	nextFreeSlot = 0;
    else if (newCurrentSlotCount == maxSlotCount)
        slots[maxSlotCount - 1] = (id)OFNoFreeSlot;
}

- initWithCount: (unsigned int) slotCount;
{
    [super init];

    nextFreeSlot = 0;
    currentSlotCount = 0;
    maxSlotCount = slotCount;
    slots = NULL;

    [self _setCurrentSlotCount: 16];
    
    return self;
}

- (void)dealloc;
{
    unsigned int                anIndex;

    for (anIndex = 0; anIndex < currentSlotCount; anIndex++)
	if ([fullSlots boolValueAtIndex:anIndex])
	    [slots[anIndex] release];
    NSZoneFree(NSZoneFromPointer(slots), slots);
    [fullSlots release];
    [super dealloc];
}

- (unsigned int) addObjectInNextFreeSlot: anObject;
{
    unsigned int                slot;

    if (nextFreeSlot == OFNoFreeSlot)
	return nextFreeSlot;

    if (nextFreeSlot >= currentSlotCount) {
	[self _setCurrentSlotCount: MIN(currentSlotCount * 2, maxSlotCount)];
    } else {
        OBASSERT(![fullSlots boolValueAtIndex: nextFreeSlot]);
    }

    slot = nextFreeSlot;
    nextFreeSlot = (unsigned int)slots[nextFreeSlot];

    slots[slot] = [anObject retain];
    [fullSlots setBoolValue:YES atIndex:slot];

    OBPOSTCONDITION(![self slotIsFree:slot]);
    OBPOSTCONDITION([self objectAtSlot:slot] == anObject);

    return slot;
}

- (void) freeSlot: (unsigned int) slotNumber;
{
    if ([self slotIsFree:slotNumber])
	[NSException raise:NSInvalidArgumentException
	 format:@"No object is contained at slot %d", slotNumber];

    [slots[slotNumber] release];
    slots[slotNumber] = (id)nextFreeSlot;
    [fullSlots setBoolValue: NO atIndex: slotNumber];
    nextFreeSlot = slotNumber;
}

- (BOOL) slotIsFree: (unsigned int) slotNumber;
{
    if (slotNumber >= currentSlotCount)
	return YES;

    return ![fullSlots boolValueAtIndex: slotNumber];
}

- (BOOL) hasFreeSlot;
{
    return (nextFreeSlot != OFNoFreeSlot);
}

- (BOOL) hasTakenSlot;
{
    return [fullSlots firstBitSet] != NSNotFound;
}

- objectAtSlot: (unsigned int) slotNumber;
{
    if ([self slotIsFree:slotNumber])
	[NSException raise:NSInvalidArgumentException
	 format:@"No object is contained at slot %d", slotNumber];

    return slots[slotNumber];
}

- (NSString *)descriptionWithLocale:(NSDictionary *)locale
                             indent:(unsigned)level;
{
    NSMutableString *string;
    unsigned int slotIndex;

    string = [NSMutableString stringWithCapacity: 0];
    for (slotIndex = 0; slotIndex < currentSlotCount; slotIndex++)
        if (![self slotIsFree: slotIndex])
            [string appendFormat: @"%d -- %@\n", slotIndex, slots[slotIndex]];
    return string;
}

- (NSString *) description;
{
    return [self descriptionWithLocale: nil indent: 0];
}


@end
