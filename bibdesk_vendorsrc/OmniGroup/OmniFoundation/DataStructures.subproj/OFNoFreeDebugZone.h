// Copyright 1998-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/DataStructures.subproj/OFNoFreeDebugZone.h,v 1.6 2004/02/10 04:07:43 kc Exp $

#import <objc/malloc.h>

extern malloc_zone_t *OFNoFreeDebugZoneCreate();

extern void OFUseNoFreeDebugZoneAsDefaultZone();
