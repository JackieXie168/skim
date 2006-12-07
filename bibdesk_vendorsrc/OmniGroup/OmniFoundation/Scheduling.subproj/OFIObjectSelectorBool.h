// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/Scheduling.subproj/OFIObjectSelectorBool.h,v 1.13 2004/02/10 04:07:47 kc Exp $

#import "OFIObjectSelector.h"

@interface OFIObjectSelectorBool : OFIObjectSelector
{
    BOOL theBool;
}

- initForObject:(id)anObject selector:(SEL)aSelector withBool:(BOOL)aBool;

@end
