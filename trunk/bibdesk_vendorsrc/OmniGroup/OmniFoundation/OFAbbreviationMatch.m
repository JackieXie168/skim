// Copyright 2000-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OFAbbreviationMatch.h"

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/OFAbbreviationMatch.m 68913 2005-10-03 19:36:19Z kc $")

@implementation OFAbbreviationMatch

- (id)initWithMatch:(id)aMatch score:(NSNumber *)aScore;
{
    if ([super init] == nil)
        return nil;
        
    match = [aMatch retain];
    score = [aScore retain];

    return self;
}

- (void)dealloc;
{
    [match release];
    [score release];
    
    [super dealloc];
}

// API

- (id)match;
{
    return match;
}

- (NSNumber *)score;
{
    return score;
}

- (NSComparisonResult)compare:(OFAbbreviationMatch *)aMatch;
{
    return [score compare:[aMatch score]];
}

- (NSMutableDictionary *) debugDictionary;
{
    NSMutableDictionary *dict;
    
    dict = [super debugDictionary];
    [dict setObject: match forKey: @"match"];
    [dict setObject: score forKey: @"score"];
    
    return dict;
}

@end
