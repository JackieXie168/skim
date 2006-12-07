// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OFRegularExpression.h,v 1.17 2003/04/17 22:27:45 kc Exp $

#import <OmniFoundation/OFObject.h>
#import <Foundation/NSString.h>

typedef enum {
    OpEnd, OpStartOfLine, OpEndOfLine, OpAnyCharacter, OpAnyOfString, OpAnyButString, OpBranch, OpReverseBranch, OpBack, OpExactlyString, OpNothing, OpZeroOrMore, OpOneOrMore, OpOpen, OpClose
} ExpressionOpCode;

typedef struct {
    ExpressionOpCode opCode	: 4;
    unsigned int argumentNumber	: 12;
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
    BOOL beGreedyWithRepetitions;
}

- initWithString:(NSString *)string isGreedy:(BOOL)isGreedy;
- initWithString:(NSString *)string;

- (unsigned int)subexpressionCount;

- (OFRegularExpressionMatch *)matchInString:(NSString *)string;
- (OFRegularExpressionMatch *)matchInScanner:(OFStringScanner *)scanner;
    // Both methods return nil if there is no match.

- (BOOL)hasMatchInString:(NSString *)string;
- (BOOL)hasMatchInScanner:(OFStringScanner *)scanner;

- (NSString *)patternString;

@end
