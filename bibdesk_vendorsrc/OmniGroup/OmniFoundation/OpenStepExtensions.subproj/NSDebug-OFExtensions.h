// Copyright 1998-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSDebug-OFExtensions.h,v 1.8 2003/01/15 22:51:59 kc Exp $

#import <OmniBase/SystemType.h> // For YELLOW_BOX
#import <Foundation/NSDebug.h>

#ifndef YELLOW_BOX

// These are defined in NSObject but weren't made fully public in OPENSTEP.  (They have been made public in the Rhapsody Developer Release.)  Objects that do not call the superclass version of -allocWithZone:, -dealloc, -copyWithZone:, -autorelaese, -retain, or -release should call NSRecordAllocationEvent.

// See <Foundation/NSDebug.h> for more details.

typedef enum _NSAllocationEvent {
    NSObjectAllocatedEvent = 0,
    NSObjectDeallocatedEvent,
    NSObjectCopiedEvent,
    NSObjectAutoreleasedEvent,
    NSObjectExtraRefIncrementedEvent,
    NSObjectExtraRefDecrementedEvent,
    NSObjectInternalRefIncrementedEvent,
    NSObjectInternalRefDecrementedEvent,
    NSObjectPoolDeallocStartedEvent,
    NSObjectPoolDeallocFinishedEvent,

    NSZoneMallocEvent = 16,
    NSZoneCallocEvent,
    NSZoneReallocEvent,
    NSZoneFreeEvent,
    NSVMAllocateEvent,
    NSVMDeallocateEvent,
    NSVMCopyEvent,
    NSZoneCreatedEvent,
    NSZoneRecycledEvent
} NSAllocationEvent;

FOUNDATION_EXPORT void NSRecordAllocationEvent(NSAllocationEvent event, id object, const void *data1, const void *data2, const void *data3);

#endif
