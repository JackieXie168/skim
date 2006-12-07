// Copyright 2003-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/ColorSync/OACompositeColorProfile.h,v 1.5 2004/02/10 04:07:32 kc Exp $

#import "OAColorProfile.h"

@class NSArray, NSColor, OAColorProfile;

@interface OACompositeColorProfile : OAColorProfile
{
    NSArray *profiles;
}

// API
- initWithProfiles:(NSArray *)someProfiles;

@end
