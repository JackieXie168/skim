//
//  NSString_BDSKExtensions.h
//  bd2xtest
//
//  Created by Christiaan Hofman on 18/5/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


extern CFStringRef BDStringCreateByCollapsingAndTrimmingWhitespace(CFAllocatorRef allocator, CFStringRef string);
extern CFStringRef BDStringCreateByCollapsingAndTrimmingWhitespaceAndNewlines(CFAllocatorRef allocator, CFStringRef string);

static inline Boolean BDIsEmptyString(CFStringRef aString)
{ 
    return (aString == NULL || CFStringCompare(aString, CFSTR(""), 0) == kCFCompareEqualTo); 
}

@interface NSString (BDSKExtensions)

- (BOOL)isStringTeXQuotingBalancedWithBraces:(BOOL)braces connected:(BOOL)connected;
- (BOOL)isStringTeXQuotingBalancedWithBraces:(BOOL)braces connected:(BOOL)connected range:(NSRange)range;
- (NSString *)fastStringByCollapsingWhitespaceAndRemovingSurroundingWhitespace;
- (NSString *)fastStringByCollapsingWhitespaceAndNewlinesAndRemovingSurroundingWhitespaceAndNewlines;
- (BOOL)containsCharacterInSet:(NSCharacterSet *)searchSet;
- (NSString *)stringByReplacingCharactersInSet:(NSCharacterSet *)set withString:(NSString *)replaceString;

@end


@interface NSMutableString (BDSKExtensions)

- (void)appendCharacter:(unichar)aCharacter;
- (void)replaceAllOccurrencesOfCharactersInSet:(NSCharacterSet *)set withString:(NSString *)replaceString;

@end

