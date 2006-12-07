// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OFRegularExpressionMatch.h,v 1.14 2004/02/10 04:07:41 kc Exp $

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
