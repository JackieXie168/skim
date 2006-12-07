// Copyright 2000-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OFAbbreviationMatcher.h"

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

#import "NSArray-OFExtensions.h"
#import "OFAbbreviationMatch.h"

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/OFAbbreviationMatcher.m 68913 2005-10-03 19:36:19Z kc $")

@interface OFAbbreviationMatcher (Private)
- (NSArray *)matchesForAbbreviation:(NSString *)anAbbreviation includeScores:(BOOL)shouldIncludeScores;
@end

@implementation OFAbbreviationMatcher

- (id)initWithObjects:(NSArray *)targetObjects descriptionSelector:(SEL)aSEL;
{
    return [self initWithObjects:targetObjects descriptions:[targetObjects arrayByPerformingSelector:aSEL]];
}

// Designated intializer
- (id)initWithObjects:(NSArray *)targetObjects descriptions:(NSArray *)targetDescriptions;
{
    unsigned int descIndex, descCount;

    if ([super init] == nil)
        return nil;
        
    // Make sure the arrays are of the same length, since they're supposed to be parallel
    if ([targetObjects count] != [targetDescriptions count])
        [NSException raise:NSInvalidArgumentException format:@"The descriptions array must have the same count of objects as the target objects array.  Target objects count = %d, descriptions count = %d", [targetObjects count], [targetDescriptions count]];
        
    objects = [targetObjects retain];
    asciiRepresentations = [[NSMutableArray alloc] init];

    // Compute the ASCII data array from the descriptions (for rapid access as bytes)
    for (descIndex = 0, descCount = [targetDescriptions count]; descIndex < descCount; descIndex++) {
        NSString *description;
        NSData *asciiRepresentation = nil;
        
        description = [targetDescriptions objectAtIndex:descIndex];
        NS_DURING {
            asciiRepresentation = [description dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
        } NS_HANDLER {
            [self release];
            [localException raise];
        } NS_ENDHANDLER;

        if (asciiRepresentation == nil) {
            [self release];
            [NSException raise:NSInvalidArgumentException format:@"Unable to convert the following description to ASCII: %@", description];
        }
        
        [asciiRepresentations addObject:asciiRepresentation];
    }

    // Set default values for point scoring
    matchedCharPoints = 1;
    matchedFirstCharPoints = 3;
    matchedUpperCharPoints = 2;
    consecutiveMatchBonus = 1;
    minimumConsecutiveMatchesForBonus = 3;
    missingCharPenalty = 2;
    
    shouldUseNonlinearConsecutiveMatchPoints = YES;

    return self;
}

- (void)dealloc;
{
    [objects release];
    [asciiRepresentations release];

    [super dealloc];
}

// API

- (NSArray *)matchesForAbbreviation:(NSString *)anAbbreviation;
{
    return [self matchesForAbbreviation:anAbbreviation includeScores:NO];
}

- (NSArray *)scoredMatchesForAbbreviation:(NSString *)anAbbreviation;
{
    return [self matchesForAbbreviation:anAbbreviation includeScores:YES];
}

- (void)setMatchedCharPoints:(unsigned int)points;
{
    matchedCharPoints = points;
}

- (unsigned int)matchedCharPoints;
{
    return matchedCharPoints;
}

- (void)setMatchedFirstCharPoints:(unsigned int)points;
{
    matchedFirstCharPoints = points;
}

- (unsigned int)matchedFirstCharPoints;
{
    return matchedFirstCharPoints;
}

- (void)setMatchedUpperCharPoints:(unsigned int)points;
{
    matchedUpperCharPoints = points;
}

- (unsigned int)matchedUpperCharPoints;
{
    return matchedUpperCharPoints;
}

- (void)setConsecutiveMatchBonus:(unsigned int)points;
{
    consecutiveMatchBonus = points;
}

- (unsigned int)consecutiveMatchBonus;
{
    return consecutiveMatchBonus;
}

- (void)setMiniumConsecutiveMatchesForBonus:(unsigned int)min;
{
    minimumConsecutiveMatchesForBonus = min;
}

- (unsigned int)minimumConsecutiveMatchesForBonus;
{
    return minimumConsecutiveMatchesForBonus;
}

- (void)setMissingCharPenalty:(unsigned int)penalty;
{
    missingCharPenalty = penalty;
}

- (unsigned int)missingCharPenalty;
{
    return missingCharPenalty;
}

- (void)shouldUseNonlinearConsecutiveMatchPoints:(BOOL)shouldUseNonlinear;
{
    shouldUseNonlinearConsecutiveMatchPoints = shouldUseNonlinear;
}

- (BOOL)shouldUseNonlinearConsecutiveMatchPoints;
{
    return shouldUseNonlinearConsecutiveMatchPoints;
}

@end

@implementation OFAbbreviationMatcher (Private)

- (NSArray *)matchesForAbbreviation:(NSString *)anAbbreviation includeScores:(BOOL)shouldIncludeScores;
{
    NSMutableArray *matches;
    NSData *asciiAbbreviation;
    const char *abbrevBytes;
    unsigned int abbrevLength;
    unsigned int descIndex, descCount;
    
    // Convert the abbreviation to ASCII bytes for rapid access
    if (((asciiAbbreviation = [anAbbreviation dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES]) == nil) || [asciiAbbreviation length] == 0)
        [NSException raise:NSInvalidArgumentException format:@"Unable to convert the abbreviation to ASCII, '%@'", anAbbreviation];
        
    abbrevBytes = [asciiAbbreviation bytes];
    abbrevLength = [asciiAbbreviation length];
    
    matches = [NSMutableArray array];

    // Loop through the object descriptions scoring the matches
    for (descIndex = 0, descCount = [asciiRepresentations count]; descIndex < descCount; descIndex++) {
        NSData *description;
        NSNumber *scoreNumber;
        OFAbbreviationMatch *match;
        const char *descBytes;
        unsigned int descByteIndex, descLength;
        unsigned int abbrevIndex = 0;
        unsigned int lastMatchIndex = -1;
        unsigned int consecutiveMatches = 0;
        signed int score = 0;
        
        description = [asciiRepresentations objectAtIndex:descIndex];
        descBytes = [description bytes];
        
        // Loop through each byte of the ASCII description and compare it against the abbreviation
        for (descByteIndex = 0, descLength = [description length]; descByteIndex < descLength; descByteIndex++) {
            if (toupper(descBytes[descByteIndex]) == toupper(abbrevBytes[abbrevIndex])) {
                score += matchedCharPoints;

                if (descByteIndex == 0)
                    score += matchedFirstCharPoints;
                
                if (isupper(descBytes[descByteIndex]))
                    score += matchedUpperCharPoints;
                    
                // Do consecutive match scoring
                if (lastMatchIndex >= 0) {
                    if (descByteIndex - lastMatchIndex == 1)
                        consecutiveMatches++;
                    else
                        consecutiveMatches = 0;
                        
                    if (consecutiveMatches >= ABS((minimumConsecutiveMatchesForBonus - 1))) {
                        if (shouldUseNonlinearConsecutiveMatchPoints)
                            score += consecutiveMatches + consecutiveMatchBonus;
                        else
                            score += consecutiveMatchBonus;
                    }
                }
                
                lastMatchIndex = descByteIndex;
                
                if (abbrevIndex < abbrevLength)
                    abbrevIndex++;
                else
                    break;
            }
        }
        
        // Compute penalties for characters which didn't occur in the target object
        score -= missingCharPenalty * (abbrevLength - (abbrevIndex + 1));
        
        if (score > 0) {
            // Create the match object to hold the match and the score.  Since we're trying to be fairly efficient, avoid creating an autoreleased objects.
            scoreNumber = [[NSNumber alloc] initWithInt:score];
    
            match = [[OFAbbreviationMatch alloc] initWithMatch:[objects objectAtIndex:descIndex] score:scoreNumber];
            [matches addObject:match];
    
            [match release];
            [scoreNumber release];
        }
    }
    
    if (shouldIncludeScores)
        return [[matches sortedArrayUsingSelector:@selector(compare:)] reversedArray];
    else
        return [[[matches sortedArrayUsingSelector:@selector(compare:)] arrayByPerformingSelector:@selector(match)] reversedArray];
}

@end
