// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/Scheduling.subproj/OFIObjectSelectorIntInt.h,v 1.10 2003/01/15 22:52:03 kc Exp $

#import "OFConcreteInvocation.h"

@interface OFIObjectSelectorIntInt : OFConcreteInvocation
{
    SEL selector;
    int theInt;
    int otherInt;
}

- initForObject:(id)anObject selector:(SEL)aSelector withInt:(int)anInt withInt:(int)anotherInt;

@end
