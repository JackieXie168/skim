
#import "BDSKRegExFindPattern.h"

#import <Foundation/Foundation.h>
#import <AGRegex/AGRegex.h>
#import <OmniBase/OmniBase.h>
#import <OmniFoundation/OmniFoundation.h>

@implementation BDSKRegExFindPattern

- initWithString:(NSString *)aString ignoreCase:(BOOL)ignoreCase backwards:(BOOL)backwards;
{
    [super init];
    regularExpression = [[AGRegex alloc] initWithPattern:aString options:(ignoreCase ? AGRegexCaseInsensitive : 0)];
    patternString = [aString retain];
    optionsMask = 0;
    if (ignoreCase)
        optionsMask |= NSCaseInsensitiveSearch;
    if (backwards)
        optionsMask |= NSBackwardsSearch;
    return self;
}

- (void)dealloc;
{
    [regularExpression release];
    [lastMatch release];
    [patternString release];
    [replacementString release];
    [super dealloc];
}

//
// OAFindPattern protocol
//

- (void)setReplacementString:(NSString *)aString;
{
    if (aString != replacementString) {
        [replacementString release];
        replacementString = [aString retain];
    }
}

- (BOOL)findInString:(NSString *)aString foundRange:(NSRangePointer)rangePtr;
{
    AGRegexMatch *match;
    
    [lastMatch release];
    lastMatch = nil;
    
    if (aString == nil)
        return NO;

    if (optionsMask & NSBackwardsSearch) {
        NSArray *matches = [regularExpression findAllInString:aString];
        lastMatchCount = [matches count];
        if (lastMatchCount == 0)
            return NO;
        match = [matches lastObject];
    } else {
        match = [regularExpression findInString:aString];
        lastMatchCount = 1;
        if (match == nil)
            return NO;
    }
    
    if (rangePtr != NULL)
            *rangePtr = [match range];
    
    lastMatch = [match retain];
    return YES;
}

- (BOOL)findInRange:(NSRange)range ofString:(NSString *)aString foundRange:(NSRangePointer)rangePtr;
{
    BOOL result;
    
    if (aString == nil)
        return NO;

    result = [self findInString:[aString substringWithRange:range] foundRange:rangePtr];
    if (rangePtr != NULL)
        rangePtr->location += range.location;
    return result;
}

// I don't think we can support subexpression replace, it doesn't make sense to me
- (NSString *)replacementStringForLastFind;
{
    NSString *lastString = [lastMatch string];
    NSRange lastRange = [lastMatch range];
    NSString *interpolatingString = nil;
    NSRange interpolatingRange = lastRange;
    
    // we should only return the portion that was replaced
    if (lastMatchCount == 1) {
        interpolatingRange.length -= [lastString length];
    } else {
        // this gives us the range where the last match occured
        interpolatingString = [regularExpression replaceWithString:replacementString inString:lastString limit:lastMatchCount - 1];
        interpolatingRange.location += [interpolatingString length] - [lastString length];
        interpolatingRange.length -= [interpolatingString length];
    }
    
    interpolatingString = [regularExpression replaceWithString:replacementString inString:lastString limit:lastMatchCount];
    interpolatingRange.length += [interpolatingString length];
    
    return [interpolatingString substringWithRange:interpolatingRange];
}

// Allow the caller to inspect the contents of the find pattern (very helpful when they cannot efficiently reduce their target content to a string)

- (NSString *)findPattern;
{
    return patternString;
}

- (BOOL)isCaseSensitive;
{
    return (optionsMask & NSCaseInsensitiveSearch) == 0;
}

- (BOOL)isBackwards;
{
    return (optionsMask & NSBackwardsSearch) != 0;
}

- (BOOL)isRegularExpression;
{
    return YES;
}

@end
