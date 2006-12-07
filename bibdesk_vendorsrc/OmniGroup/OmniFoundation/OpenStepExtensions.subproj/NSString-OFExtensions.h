// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSString-OFExtensions.h,v 1.50 2003/04/11 23:14:44 ryan Exp $

#import <Foundation/NSDecimalNumber.h>
#import <Foundation/NSString.h>
#import <Foundation/NSDate.h> // For NSTimeInterval
#import <CoreFoundation/CFString.h>  // for CFStringEncoding

#import <OmniBase/SystemType.h> // For YELLOW_BOX

#ifdef YELLOW_BOX
#import <Foundation/NSCalendarDate.h>
#else
#import <Foundation/NSDate.h>
#endif

@class OFCharacterSet;

@interface NSString (OFExtensions)
+ (NSString *)stringWithData:(NSData *)data encoding:(NSStringEncoding)encoding;
+ (NSString *)abbreviatedStringForBytes:(unsigned long long)bytes;
+ (NSString *)humanReadableStringForTimeInterval:(NSTimeInterval)timeInterval;
+ (NSString *)spacesOfLength:(unsigned int)aLength;
+ (NSString *)stringWithCharacter:(unsigned int)aCharacter; /* Returns a string containing the given Unicode character. Will generate a surrogate pair for characters > 0xFFFF (which cannot be represented by a single unichar). */
+ (NSString *)stringWithStrings:(NSString *)first, ... ;
+ (NSString *)stringWithFourCharCode:(FourCharCode)code;

// These methods return strings containing the indicated character

+ (NSString *)horizontalEllipsisString; // '...'
+ (NSString *)leftPointingDoubleAngleQuotationMarkString; // '<<'
+ (NSString *)rightPointingDoubleAngleQuotationMarkString; // '>>'
+ (NSString *)emdashString; // '---'
+ (NSString *)endashString; // '--'
+ (NSString *)commandKeyIndicatorString;
+ (NSString *)alternateKeyIndicatorString;
+ (NSString *)shiftKeyIndicatorString;

+ (BOOL)isEmptyString:(NSString *)string;
    // Returns YES if the string is nil or equal to @""

- (BOOL)containsCharacterInSet:(NSCharacterSet *)searchSet;
- (BOOL)containsString:(NSString *)searchString options:(unsigned int)mask;
- (BOOL)containsString:(NSString *)searchString;
- (BOOL)isEqualToCString:(const char *)cString;
- (BOOL)hasLeadingWhitespace;
- (BOOL)isPercentage;

- (BOOL)boolValue;
- (long long int)longLongValue;
- (unsigned int)unsignedIntValue;
- (NSDecimal)decimalValue;
- (NSDecimalNumber *)decimalNumberValue;
- (NSNumber *)numberValue;
- (NSArray *)arrayValue;
- (NSDictionary *)dictionaryValue;
- (NSData *)dataValue;
- (NSCalendarDate *)dateValue;
- (FourCharCode)fourCharCodeValue;

- (unsigned int)hexValue;

- (NSString *)stringByUppercasingAndUnderscoringCaseChanges;
- (NSString *)stringByRemovingSurroundingWhitespace;
    // Note: this may return the same NSString instance
- (NSString *)stringByCollapsingWhitespaceAndRemovingSurroundingWhitespace;
- (NSString *)stringByRemovingWhitespace;
- (NSString *)stringByRemovingCharactersInOFCharacterSet:(OFCharacterSet *)removeSet;
- (NSString *)stringByRemovingReturns;
- (NSString *)stringByRemovingString:(NSString *)removeString;
- (NSString *)stringByPaddingToLength:(unsigned int)aLength;
- (NSString *)stringByNormalizingPath;
    // Normalizes a path like /a/b/c/../../d to /a/d.
    // Note: Does not work properly on Windows at the moment because it is hardcoded to use forward slashes rather than using the native path separator.
- (unichar)firstCharacter;
- (unichar)lastCharacter;
- (NSString *)lowercaseFirst;
- (NSString *)uppercaseFirst;
- (NSString *)stringByReplacingCharactersInSet:(NSCharacterSet *)set withString:(NSString *)replaceString;

- (NSString *)stringByReplacingKeysInDictionary:(NSDictionary *)keywordDictionary startingDelimiter:(NSString *)startingDelimiterString endingDelimiter:(NSString *)endingDelimiterString removeUndefinedKeys: (BOOL) removeUndefinedKeys;
    // Useful for turning $(NEXT_ROOT)/LocalLibrary into C:/Apple/LocalLibrary.  If removeUndefinedKeys is YES and there is no key in the source dictionary, then @"" will be used to replace the variable substring.
- (NSString *)stringByReplacingKeysInDictionary:(NSDictionary *)keywordDictionary startingDelimiter:(NSString *)startingDelimiterString endingDelimiter:(NSString *)endingDelimiterString;
    // Calls -stringByReplacingKeysInDictionary:startingDelimiter:endingDelimiter:removeUndefinedKeys: with removeUndefinedKeys NO.
- (NSString *)stringByReplacingOccurancesOfString:(NSString *)targetString withObjectsFromArray:(NSArray *)sourceArray;

- (NSString *)stringBySeparatingSubstringsOfLength:(unsigned int)substringLength withString:(NSString *)separator startingFromBeginning:(BOOL)startFromBeginning;

- (NSString *)substringStartingWithString:(NSString *)startString;
- (NSString *)substringStartingAfterString:(NSString *)startString;
- (NSString *)stringByRemovingPrefix:(NSString *)prefix;
- (NSString *)stringByRemovingSuffix:(NSString *)suffix;

- (NSString *)stringByIndenting:(int)spaces;
- (NSString *)stringByWordWrapping:(int)columns;
- (NSString *)stringByIndenting:(int)spaces andWordWrapping:(int)columns;
- (NSString *)stringByIndenting:(int)spaces andWordWrapping:(int)columns withFirstLineIndent:(int)firstLineSpaces;


- (NSRange)findString:(NSString *)string selectedRange:(NSRange)selectedRange options:(unsigned int)options wrap:(BOOL)wrap;

- (NSRange)rangeOfCharactersAtIndex:(unsigned)pos
                        delimitedBy:(NSCharacterSet *)delim;
- (NSRange)rangeOfWordContainingCharacter:(unsigned)pos;
- (NSRange)rangeOfWordsIntersectingRange:(NSRange)range;

- (unsigned)indexOfCharacterNotRepresentableInCFEncoding:(CFStringEncoding)anEncoding;
- (unsigned)indexOfCharacterNotRepresentableInCFEncoding:(CFStringEncoding)anEncoding range:(NSRange)aRange;
- (NSRange)rangeOfCharactersNotRepresentableInCFEncoding:(CFStringEncoding)anEncoding;

/* Covers for the C functions in CoreFoundation */
- (NSData *)dataUsingCFEncoding:(CFStringEncoding)anEncoding;
- (NSData *)dataUsingCFEncoding:(CFStringEncoding)anEncoding allowLossyConversion:(BOOL)lossy;

- (BOOL)writeToFile:(NSString *)path atomically:(BOOL)useAuxiliaryFile createDirectories:(BOOL)shouldCreateDirectories;

#define OF_CHARACTER_BUFFER_SIZE 1024

#define OFStringStartLoopThroughCharacters(string, ch)			\
{									\
    unichar characterBuffer[OF_CHARACTER_BUFFER_SIZE];			\
    unsigned int charactersProcessed, length;				\
									\
    charactersProcessed = 0;						\
    length = [string length];						\
    while (charactersProcessed < length) {				\
        unsigned int charactersInThisBuffer;				\
        unichar *input;							\
									\
        charactersInThisBuffer = MIN(length - charactersProcessed, OF_CHARACTER_BUFFER_SIZE); \
        [string getCharacters:characterBuffer range:NSMakeRange(charactersProcessed, charactersInThisBuffer)]; \
        charactersProcessed += charactersInThisBuffer;			\
        input = characterBuffer;					\
									\
        while (charactersInThisBuffer--) {				\
            unichar ch = *input++;


#define OFStringEndLoopThroughCharacters	 			\
        }								\
    }									\
}

/* URL encoding */
+ (void)setURLEncoding:(CFStringEncoding)newURLEncoding;
+ (CFStringEncoding)urlEncoding;

+ (NSString *)decodeURLString:(NSString *)encodedString encoding:(CFStringEncoding)thisUrlEncoding;
+ (NSString *)decodeURLString:(NSString *)encodedString;

+ (NSString *)encodeURLString:(NSString *)unencodedString asQuery:(BOOL)asQuery leaveSlashes:(BOOL)leaveSlashes leaveColons:(BOOL)leaveColons;
+ (NSString *)encodeURLString:(NSString *)unencodedString encoding:(CFStringEncoding)thisUrlEncoding asQuery:(BOOL)asQuery leaveSlashes:(BOOL)leaveSlashes leaveColons:(BOOL)leaveColons;
- (NSString *)fullyEncodeAsIURI;  // This takes a string which is already in %-escaped URI format and fully escapes any characters which are not safe. Slashes, question marks, etc. are unaffected.

- (NSString *)htmlString;

@end
