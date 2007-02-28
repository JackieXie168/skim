// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniBase/mallocmap.h 68913 2005-10-03 19:36:19Z kc $

#import <Foundation/NSZone.h>

// We should NEVER use the BSD malloc functions since they don't
// report zone allocation statistics.  Typically, this is verified
// by OmniMake, but for third-party libraries that we don't want to
// make extensive source changes to, we can import this file.

#define malloc(size)                 NSZoneMalloc(NULL, size)
#define calloc(numElems, elemSize)   NSZoneCalloc(NULL, numElems, elemSize)
#define realloc(oldPointer, newSize) NSZoneRealloc(NULL, oldPointer, newSize)
#define free(pointer)                NSZoneFree(NULL, pointer)
