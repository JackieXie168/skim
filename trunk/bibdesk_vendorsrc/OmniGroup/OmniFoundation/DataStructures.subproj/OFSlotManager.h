// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/DataStructures.subproj/OFSlotManager.h 68913 2005-10-03 19:36:19Z kc $

#import <OmniFoundation/OFObject.h>

@class OFBitField;

#define OFNoFreeSlot ((unsigned int) -1)

@interface OFSlotManager : OFObject
/*.doc.
OFSlotManager maintains a mapping from the set of integers [0..N] to some objects. Finding a free slot is O(1) as is looking up the object for a slot. Each slot can hold any object, including nil. A slot is not free if it contains nil. Freeing a slot may be accomplished by -freeSlot:.
*/
{
    unsigned int                nextFreeSlot;
    /*.doc. The index of the head of the internal free slot list. */

    unsigned int		currentSlotCount;
    /*.doc. The size of the current slot's array. */

    unsigned int                maxSlotCount;
    /*.doc. The maximum size to which the slot's array can grow. */

    id                         *slots;
    /*.doc. Storage for the objects being held. */

    OFBitField                *fullSlots;
    /*.doc. Markers for the full slots. */
}

- initWithCount: (unsigned int) slotCount;
/*.doc.
Initializes the receiver and gives it the given numbers of slots.
*/

- (void)dealloc;
/*.doc.
Releases the resources for the receiver.
*/

- (unsigned int) addObjectInNextFreeSlot: anObject;
/*.doc.
Performs a setObject:atSlot: given the next free slot. Returns the slot that the object was inserted in or OFNoFreeSlot if there is no free slot.
*/

- (void) freeSlot: (unsigned int) slotNumber;
/*.doc.
Removes the object at slotNumber and marks the slot as free. If slotNumber is already free, raises NSInvalidArgumentException.
*/

- (BOOL) slotIsFree: (unsigned int) slotNumber;
/*.doc.
Returns YES if the given slot contains no object.
*/

- (BOOL) hasFreeSlot;
/*.doc.
Returns YES if there is currently an available slot.
*/

- (BOOL) hasTakenSlot;
/*.doc.
Returns YES if any slot is occupied.
*/

- objectAtSlot: (unsigned int) slotNumber;
/*.doc.
Returns the object at the given slot. Raises NSInvalidArgumentException if there is no object at the given slot.
*/

@end
