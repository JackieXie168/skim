
#import <Foundation/NSObject.h>

@class AGRegex, AGRegexMatch;

#import <OmniAppKit/OAFindControllerTargetProtocol.h>

@interface BDSKRegExFindPattern : NSObject <OAFindPattern>
{
    AGRegex *regularExpression;
    unsigned int optionsMask;
    NSString *patternString;
    NSString *replacementString;
    AGRegexMatch *lastMatch;
    unsigned int lastMatchCount;
}

- initWithString:(NSString *)aString ignoreCase:(BOOL)ignoreCase backwards:(BOOL)backwards;

@end
