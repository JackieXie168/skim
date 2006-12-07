// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OFByteOrder.h,v 1.13 2003/01/15 22:51:49 kc Exp $

#import <Foundation/NSByteOrder.h>
#import <OmniBase/SystemType.h> // For YELLOW_BOX

#ifdef YELLOW_BOX
typedef enum _NSByteOrder OFByteOrder;
#else
typedef enum NSByteOrder OFByteOrder;
#endif
