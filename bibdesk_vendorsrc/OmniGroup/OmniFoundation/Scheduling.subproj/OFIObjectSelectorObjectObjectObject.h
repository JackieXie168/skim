// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/Scheduling.subproj/OFIObjectSelectorObjectObjectObject.h,v 1.11 2004/02/10 04:07:47 kc Exp $

#import "OFIObjectSelector.h"

@interface OFIObjectSelectorObjectObjectObject : OFIObjectSelector
{
    id object1;
    id object2;
    id object3;
}

- initForObject:(id)targetObject selector:(SEL)aSelector withObject:(id)anObject1 withObject:(id)anObject2 withObject:(id)anObject3;

@end
