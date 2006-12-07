// Copyright 2000-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OFAbbreviationMatch.h"

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OFAbbreviationMatch.m,v 1.7 2004/02/10 04:07:40 kc Exp $")

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
