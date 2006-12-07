// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/OFRegularExpressionMatch.h 68913 2005-10-03 19:36:19Z kc $

#import <OmniFoundation/OFObject.h>
#import <Foundation/NSRange.h>

@class OFRegularExpression, OFStringScanner;

#define INVALID_SUBEXPRESSION_LOCATION	(unsigned int)-1

@interface OFRegularExpressionMatch : OFObject
{
    OFRegularExpression *expression;
    OFStringScanner *scanner;
@public    
    NSRange *subExpressionMatches;
    NSRange matchRange;
}

- (NSRange)matchRange;
- (NSString *)matchString;
- (NSRange)rangeOfSubexpressionAtIndex:(unsigned int)index;
- (NSString *)subexpressionAtIndex:(unsigned int)index;

- (BOOL)findNextMatch;
- (OFRegularExpressionMatch *)nextMatch;

@end
