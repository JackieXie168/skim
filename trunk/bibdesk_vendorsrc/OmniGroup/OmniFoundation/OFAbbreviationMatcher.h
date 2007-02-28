// Copyright 2000-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/OFAbbreviationMatcher.h 68913 2005-10-03 19:36:19Z kc $

#import <OmniFoundation/OFObject.h>

// Forward declarations
@class NSArray, NSMutableArray; // Foundation

@interface OFAbbreviationMatcher : OFObject
{
    NSArray *objects;
    NSMutableArray *asciiRepresentations;
    
    unsigned int matchedCharPoints;
    unsigned int matchedFirstCharPoints;
    unsigned int matchedUpperCharPoints;
    unsigned int consecutiveMatchBonus;
    unsigned int minimumConsecutiveMatchesForBonus;
    unsigned int missingCharPenalty;
    
    BOOL shouldUseNonlinearConsecutiveMatchPoints;
}

// Please note that the descriptions and abbreviations must be convertable to NSASCIIStringEncoding (lossily if necessary)
- (id)initWithObjects:(NSArray *)targetObjects descriptionSelector:(SEL)aSEL;

// Designated initializer
- (id)initWithObjects:(NSArray *)targetObjects descriptions:(NSArray *)targetDescriptions;

// API

// Returns an array of matching objects, sorted in descending order (best match is last)
- (NSArray *)matchesForAbbreviation:(NSString *)anAbbreviation;

// Returns an array of OFAbbreviationMatch objects, sorted in descending order (best match is last)
- (NSArray *)scoredMatchesForAbbreviation:(NSString *)anAbbreviation;

- (void)setMatchedCharPoints:(unsigned int)points;
- (unsigned int)matchedCharPoints;

- (void)setMatchedFirstCharPoints:(unsigned int)points;
- (unsigned int)matchedFirstCharPoints;

- (void)setMatchedUpperCharPoints:(unsigned int)points;
- (unsigned int)matchedUpperCharPoints;

- (void)setConsecutiveMatchBonus:(unsigned int)points;
- (unsigned int)consecutiveMatchBonus;

- (void)setMiniumConsecutiveMatchesForBonus:(unsigned int)min;
- (unsigned int)minimumConsecutiveMatchesForBonus;

- (void)setMissingCharPenalty:(unsigned int)penalty;
- (unsigned int)missingCharPenalty;

- (void)shouldUseNonlinearConsecutiveMatchPoints:(BOOL)shouldUseNonlinear;
- (BOOL)shouldUseNonlinearConsecutiveMatchPoints;

@end
