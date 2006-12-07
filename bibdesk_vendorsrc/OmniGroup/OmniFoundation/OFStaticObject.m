// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/OFStaticObject.h>

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OFStaticObject.m,v 1.10 2004/02/10 04:07:41 kc Exp $")

@implementation OFStaticObject

- (void)dealloc;
{
}

- (unsigned int)retainCount;
{
    return 1;
}

- retain;
{
    return self;
}

- (void)release;
{
}

- autorelease;
{
    return self;
}

@end
