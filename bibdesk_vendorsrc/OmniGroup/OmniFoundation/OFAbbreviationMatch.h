// Copyright 2000-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OFAbbreviationMatch.h,v 1.7 2004/02/10 04:07:40 kc Exp $

#import <OmniFoundation/OFObject.h>

@class NSNumber; // Foundation

@interface OFAbbreviationMatch : OFObject
{
    id match;
    NSNumber *score;
}

- (id)initWithMatch:(id)aMatch score:(NSNumber *)aScore;

// API

- (id)match;
- (NSNumber *)score;

- (NSComparisonResult)compare:(OFAbbreviationMatch *)aMatch;

@end
