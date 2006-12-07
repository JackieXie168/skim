//
//  NSString_BDSKExtensions.m
//  bd2xtest
//
//  Created by Christiaan Hofman on 18/5/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "NSString_BDSKExtensions.h"
#import "NSCharacterSet_BDSKExtensions.h"

#define SAFE_ALLOCA_SIZE (8 * 8192)

static inline
CFStringRef __BDStringCreateByCollapsingAndTrimmingWhitespace(CFAllocatorRef allocator, CFStringRef aString)
{
    
    CFIndex length = CFStringGetLength(aString);
    
    if(length == 0)
        return CFRetain(CFSTR(""));
    
    // improves efficiency somewhat when adding autocomplete strings, since we can completely avoid allocation
    if(__BDStringContainsWhitespace(aString, length) == FALSE)
        return CFRetain(aString);
    
    // set up the buffer to fetch the characters
    CFIndex cnt = 0;
    CFStringInlineBuffer inlineBuffer;
    CFStringInitInlineBuffer(aString, &inlineBuffer, CFRangeMake(0, length));
    UniChar ch;
    UniChar *buffer;
    CFStringRef retStr;
    
    BOOL isLarge = NO;
    // see if we can allocate it on the stack (faster)
    buffer = NULL;
    size_t bufSize = sizeof(UniChar) * (length + 1);
    if(bufSize < SAFE_ALLOCA_SIZE)
        buffer = alloca(bufSize);
    
    allocator = (allocator == NULL) ? CFAllocatorGetDefault() : allocator;
    if(buffer == NULL){
        buffer = CFAllocatorAllocate(allocator, bufSize, 0);
        isLarge = YES; // too large for the stack
    }
    
    NSCAssert1(buffer != NULL, @"failed to allocate memory for string of length %d", length);
    
    BOOL isFirst = NO;
    int bufCnt = 0;
    for(cnt = 0; cnt < length; cnt++){
        ch = CFStringGetCharacterFromInlineBuffer(&inlineBuffer, cnt);
        if(!__BDCharacterIsWhitespace(ch)){
            isFirst = YES;
            buffer[bufCnt++] = ch; // not whitespace, so we want to keep it
        } else {
            if(isFirst){
                buffer[bufCnt++] = ' '; // if it's the first whitespace, we add a single space
                isFirst = NO;
            }
        }
    }
    
    if(buffer[(bufCnt-1)] == ' ') // we've collapsed any trailing whitespace, so disregard it
        bufCnt--;
    
    retStr = CFStringCreateWithCharacters(CFAllocatorGetDefault(), buffer, bufCnt);
    if(isLarge) CFAllocatorDeallocate(allocator, buffer);
    return retStr;
}

static inline
CFStringRef __BDStringCreateByCollapsingAndTrimmingWhitespaceAndNewlines(CFAllocatorRef allocator, CFStringRef aString)
{
    
    CFIndex length = CFStringGetLength(aString);
    
    if(length == 0)
        return CFRetain(CFSTR(""));
    
    // improves efficiency somewhat when adding autocomplete strings, since we can completely avoid allocation
    if(__BDStringContainsWhitespaceOrNewline(aString, length) == FALSE)
        return CFRetain(aString);
    
    // set up the buffer to fetch the characters
    CFIndex cnt = 0;
    CFStringInlineBuffer inlineBuffer;
    CFStringInitInlineBuffer(aString, &inlineBuffer, CFRangeMake(0, length));
    UniChar ch;
    UniChar *buffer;
    CFStringRef retStr;
    
    BOOL isLarge = NO;
    // see if we can allocate it on the stack (faster)
    buffer = NULL;
    size_t bufSize = sizeof(UniChar) * (length + 1);
    if(bufSize < SAFE_ALLOCA_SIZE)
        buffer = alloca(bufSize);
    
    allocator = (allocator == NULL) ? CFAllocatorGetDefault() : allocator;
    if(buffer == NULL){
        buffer = CFAllocatorAllocate(allocator, bufSize, 0);
        isLarge = YES; // too large for the stack
    }
    
    NSCAssert1(buffer != NULL, @"failed to allocate memory for string of length %d", length);
    
    BOOL isFirst = NO;
    int bufCnt = 0;
    for(cnt = 0; cnt < length; cnt++){
        ch = CFStringGetCharacterFromInlineBuffer(&inlineBuffer, cnt);
        if(!__BDCharacterIsWhitespaceOrNewline(ch)){
            isFirst = YES;
            buffer[bufCnt++] = ch; // not whitespace, so we want to keep it
        } else {
            if(isFirst){
                buffer[bufCnt++] = ' '; // if it's the first whitespace, we add a single space
                isFirst = NO;
            }
        }
    }
    
    if(buffer[(bufCnt-1)] == ' ') // we've collapsed any trailing whitespace, so disregard it
        bufCnt--;
    
    retStr = CFStringCreateWithCharacters(CFAllocatorGetDefault(), buffer, bufCnt);
    if(isLarge) CFAllocatorDeallocate(allocator, buffer);
    return retStr;
}

CFStringRef BDStringCreateByCollapsingAndTrimmingWhitespace(CFAllocatorRef allocator, CFStringRef string){ return __BDStringCreateByCollapsingAndTrimmingWhitespace(allocator, string); }
CFStringRef BDStringCreateByCollapsingAndTrimmingWhitespaceAndNewlines(CFAllocatorRef allocator, CFStringRef string){ return __BDStringCreateByCollapsingAndTrimmingWhitespaceAndNewlines(allocator, string); }

@implementation NSString (BDSKExtensions)

- (BOOL)isStringTeXQuotingBalancedWithBraces:(BOOL)braces connected:(BOOL)connected{
	return [self isStringTeXQuotingBalancedWithBraces:braces connected:connected range:NSMakeRange(0,[self length])];
}

- (BOOL)isStringTeXQuotingBalancedWithBraces:(BOOL)braces connected:(BOOL)connected range:(NSRange)range{
	int nesting = 0;
	NSCharacterSet *delimCharSet;
	unichar rightDelim;
	
	if (braces) {
		delimCharSet = [NSCharacterSet curlyBraceCharacterSet];
		rightDelim = '}';
	} else {
		delimCharSet = [NSCharacterSet characterSetWithCharactersInString:@"\""];
		rightDelim = '"';
	}
	
	NSRange delimRange = [self rangeOfCharacterFromSet:delimCharSet options:NSLiteralSearch range:range];
	int delimLoc = delimRange.location;
	
	while (delimLoc != NSNotFound) {
		if (delimLoc == 0 || [self characterAtIndex:delimLoc - 1] != '\\') {
			// we found an unescaped delimiter
			if (connected && nesting == 0) // connected quotes cannot have a nesting of 0 in the middle
				return NO;
			if ([self characterAtIndex:delimLoc] == rightDelim) {
				--nesting;
			} else {
				++nesting;
			}
			if (nesting < 0) // we should never get a negative nesting
				return NO;
		}
		// set the range to the part of the range after the last found brace
		range = NSMakeRange(delimLoc + 1, range.length - delimLoc + range.location - 1);
		// search for the next brace
		delimRange = [self rangeOfCharacterFromSet:delimCharSet options:NSLiteralSearch range:range];
		delimLoc = delimRange.location;
	}
	
	return (nesting == 0);
}

- (NSString *)fastStringByCollapsingWhitespaceAndRemovingSurroundingWhitespace;
{
    return [(id)BDStringCreateByCollapsingAndTrimmingWhitespace(CFAllocatorGetDefault(), (CFStringRef)self) autorelease];
}

- (NSString *)fastStringByCollapsingWhitespaceAndNewlinesAndRemovingSurroundingWhitespaceAndNewlines;
{
    return [(id)BDStringCreateByCollapsingAndTrimmingWhitespaceAndNewlines(CFAllocatorGetDefault(), (CFStringRef)self) autorelease];
}

- (BOOL)containsCharacterInSet:(NSCharacterSet *)searchSet;
{
    NSRange characterRange;

    characterRange = [self rangeOfCharacterFromSet:searchSet];
    return characterRange.length != 0;
}

- (NSString *)stringByReplacingCharactersInSet:(NSCharacterSet *)set withString:(NSString *)replaceString;
{
    NSMutableString *newString;

    if (![self containsCharacterInSet:set])
	return [[self retain] autorelease];
    newString = [[self mutableCopy] autorelease];
    [newString replaceAllOccurrencesOfCharactersInSet:set withString:replaceString];
    return newString;
}

@end


@implementation NSMutableString (BDSKExtensions)

- (void)appendCharacter:(unichar)aCharacter;
{
    // There isn't a particularly efficient way to do this using the ObjC interface, so...
    const UniChar unicodeCharacters[1] = { aCharacter };
    
    CFStringAppendCharacters((CFMutableStringRef)self, unicodeCharacters, 1);
}

- (void)replaceAllOccurrencesOfCharactersInSet:(NSCharacterSet *)set withString:(NSString *)replaceString;
{
    NSRange characterRange, searchRange;
    unsigned int replaceStringLength;

    searchRange = NSMakeRange(0, [self length]);
    replaceStringLength = [replaceString length];
    while ((characterRange = [self rangeOfCharacterFromSet:set options:NSLiteralSearch range:searchRange]).length) {
	[self replaceCharactersInRange:characterRange withString:replaceString];
	searchRange.location = characterRange.location + replaceStringLength;
	searchRange.length = [self length] - searchRange.location;
	if (searchRange.length == 0)
	    break; // Might as well save that extra method call.
    }
}

@end
