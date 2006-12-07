// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniBase/mallocmap.h,v 1.11 2003/01/15 22:51:48 kc Exp $

#import <Foundation/NSZone.h>

// We should NEVER use the BSD malloc functions since they don't
// report zone allocation statistics.  Typically, this is verified
// by OmniMake, but for third-party libraries that we don't want to
// make extensive source changes to, we can import this file.

#define malloc(size)                 NSZoneMalloc(NULL, size)
#define calloc(numElems, elemSize)   NSZoneCalloc(NULL, numElems, elemSize)
#define realloc(oldPointer, newSize) NSZoneRealloc(NULL, oldPointer, newSize)
#define free(pointer)                NSZoneFree(NULL, pointer)
