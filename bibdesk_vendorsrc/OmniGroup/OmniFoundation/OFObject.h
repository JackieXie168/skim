// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/OFObject.h 68913 2005-10-03 19:36:19Z kc $

#ifndef __OFObjectHeader__
#define __OFObjectHeader__

#import <OmniBase/OBObject.h>

@interface OFObject : OBObject
{
    unsigned int retainCount; /*" Inline retain count for faster -retain/-release. "*/
}

@end

#endif // __OFObjectHeader__
