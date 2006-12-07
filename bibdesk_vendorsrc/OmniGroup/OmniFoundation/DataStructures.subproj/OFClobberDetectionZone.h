// Copyright 2001-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/DataStructures.subproj/OFClobberDetectionZone.h,v 1.3 2003/01/15 22:51:53 kc Exp $

#import <objc/malloc.h>

extern malloc_zone_t *OFClobberDetectionZoneCreate();

extern void OFUseClobberDetectionZoneAsDefaultZone();
