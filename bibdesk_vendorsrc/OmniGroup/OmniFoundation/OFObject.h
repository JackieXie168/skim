// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OFObject.h,v 1.23 2004/02/10 04:07:40 kc Exp $

#ifndef __OFObjectHeader__
#define __OFObjectHeader__

#import <OmniBase/OBObject.h>

@interface OFObject : OBObject
{
    unsigned int retainCount; /*" Inline retain count for faster -retain/-release. "*/
}

@end

#endif // __OFObjectHeader__
