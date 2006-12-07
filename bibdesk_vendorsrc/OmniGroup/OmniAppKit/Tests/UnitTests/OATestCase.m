// Copyright 2003-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OATestCase.h"

#import <OmniAppKit/OAApplication.h>
#import <OmniBase/OmniBase.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Tests/UnitTests/OATestCase.m,v 1.5 2004/02/10 04:07:36 kc Exp $");

@implementation OATestCase

+ (void) initialize;
{
    OBINITIALIZE;
    [OAApplication sharedApplication];
}

@end
