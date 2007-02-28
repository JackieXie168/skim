// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/OFRegularExpression.h 68913 2005-10-03 19:36:19Z kc $

#import <OmniFoundation/OFObject.h>
#import <Foundation/NSString.h>

typedef enum {
    OpEnd, OpStartOfLine, OpEndOfLine, OpAnyCharacter, OpAnyOfString, OpAnyButString, OpBranch, OpReverseBranch, OpBack, OpExactlyString, OpNothing, OpZeroOrMore, OpZeroOrMoreGreedy, OpOneOrMore, OpOneOrMoreGreedy, OpOpen, OpClose
} ExpressionOpCode;

typedef struct {
    ExpressionOpCode opCode	: 5;
    unsigned int argumentNumber	: 11;
    unsigned int nextState	: 16;
} ExpressionState;

@class OFStringScanner, OFRegularExpressionMatch;

@interface OFRegularExpression : OFObject
{
    NSString *patternString;
    unichar startCharacter;
    BOOL matchStartsLine;
    unichar *matchString;
    unsigned int subExpressionCount;
    ExpressionState *program;
    unichar *stringBuffer;
}

- initWithString:(NSString *)string;

- (unsigned int)subexpressionCount;

- (OFRegularExpressionMatch *)matchInString:(NSString *)string;
- (OFRegularExpressionMatch *)matchInString:(NSString *)string range:(NSRange)range;
- (OFRegularExpressionMatch *)matchInScanner:(OFStringScanner *)scanner;
    // All three methods return nil if there is no match.

- (BOOL)hasMatchInString:(NSString *)string;
- (BOOL)hasMatchInScanner:(OFStringScanner *)scanner;

- (NSString *)patternString;
- (NSString *)prefixString;
- (BOOL)isPrefixOnly;


@end
