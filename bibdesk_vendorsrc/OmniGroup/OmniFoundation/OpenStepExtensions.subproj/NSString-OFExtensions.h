// Copyright 1997-2006 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSString-OFExtensions.h 79079 2006-09-07 22:35:32Z kc $

#import <Foundation/NSString.h>

#import <Foundation/NSCalendarDate.h>
#import <Foundation/NSDecimalNumber.h>
#import <Foundation/NSDate.h> // For NSTimeInterval

#import <CoreFoundation/CFString.h>  // for CFStringEncoding

#import <OmniFoundation/FrameworkDefines.h>

@class OFCharacterSet;
@class OFRegularExpression;

/* A note on deferred string decoding.

A recurring problem in OmniWeb is dealing with strings whose encoding is unknown. Usually this is because a protocol or format was originally specified in terms of 7-bit ASCII, and has later been extended to support larger character sets by adding a character encoding field (in ASCII). This shows up in HTML (the <META> tag is often used to specify its own file's interpretation), FTP (the MLST/MLSD response includes a charset field, possibly different for each line of the response), XML (the charset attribute in the declaration element), etc.

One way to handle this would be to treat these as octet-strings rather than character-strings, until their encoding is known. However, keeping octet-strings in NSDatas would keep us from using the large library of useful routines which manipulate NSStrings.

Instead, OmniFoundation sets aside a range of 256 code points in the Supplementary Private Use Area A to represent bytes which have not yet been converted into characters. OFStringDecoder understands a new encoding, OFDeferredASCIISupersetStringEncoding, which interprets ASCII as ASCII but maps all apparently non-ASCII bytes into the private use area. Later, the original byte sequence can be recovered (including interleaved high-bit-clear bytes, since the ASCII->Unicode->ASCII roundtrip is lossless) and the correct string encoding can be applied.

It's intended that strings containing these private-use code points have as short a lifetime and as limited a scope as possible. We don't want our private-use characters getting out into the rest of the world and gumming up glyph generation or being mistaken for someone else's private-use characters. As soon as the correct string encoding is known, all strings should be re-encoded using -stringByApplyingDeferredCFEncoding: or an equivalent function.

Low-level functions for dealing with NSStrings containing "deferred" bytes/characters can be found in OFStringDecoder. In general, searching, splitting, and combining strings containing deferred characters can be done safely, as long as you don't split up any deferred multibyte characters. In addition, the following methods in this file understand deferred-encoding strings and will do the right thing:

   -stringByApplyingDeferredCFEncoding:
   -dataUsingCFEncoding:
   -dataUsingCFEncoding:allowLossyConversion:
   -dataUsingCFEncoding:allowLossyConversion:hexEscapes:
   -encodeURLString:asQuery:leaveSlashes:leaveColons:
   -encodeURLString:encoding:asQuery:leaveSlashes:leaveColons:
   -fullyEncodeAsIURI:

Currently the only way to create strings with deferred bytes/characters is using OFStringDecoder (possibly via OWDataStreamCharacterCursor/Scanner).

*/

@interface NSString (OFExtensions)
+ (NSString *)stringWithData:(NSData *)data encoding:(NSStringEncoding)encoding;
+ (CFStringEncoding)cfStringEncodingForDefaultValue:(NSString *)encodingName;
+ (NSString *)defaultValueForCFStringEncoding:(CFStringEncoding)anEncoding;
+ (NSString *)abbreviatedStringForBytes:(unsigned long long)bytes;
+ (NSString *)abbreviatedStringForHertz:(unsigned long long)hz;
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
+ (NSString *)controlKeyIndicatorString;
+ (NSString *)alternateKeyIndicatorString;
+ (NSString *)shiftKeyIndicatorString;

+ (BOOL)isEmptyString:(NSString *)string;
    // Returns YES if the string is nil or equal to @""

- (BOOL)containsCharacterInOFCharacterSet:(OFCharacterSet *)searchSet;
- (BOOL)containsCharacterInSet:(NSCharacterSet *)searchSet;
- (BOOL)containsString:(NSString *)searchString options:(unsigned int)mask;
- (BOOL)containsString:(NSString *)searchString;
- (BOOL)isEqualToCString:(const char *)cString;
- (BOOL)hasLeadingWhitespace;
- (BOOL)isPercentage;

- (BOOL)boolValue;
- (long long int)longLongValue;
- (unsigned long long int)unsignedLongLongValue;
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
- (NSString *)stringByRemovingSurroundingWhitespace;  // New code should probably use -stringByTrimmingCharactersInSet: instead
- (NSString *)stringByCollapsingWhitespaceAndRemovingSurroundingWhitespace;
- (NSString *)stringByRemovingWhitespace;
- (NSString *)stringByRemovingCharactersInOFCharacterSet:(OFCharacterSet *)removeSet;
- (NSString *)stringByRemovingReturns;
- (NSString *)stringByRemovingRegularExpression:(OFRegularExpression *)regularExpression;
- (NSString *)stringByRemovingString:(NSString *)removeString;
// - (NSString *)stringByPaddingToLength:(unsigned int)aLength;  // Use Foundation's new -stringByPaddingToLength:withString:startingAtIndex: method.
- (NSString *)stringByNormalizingPath;
    // Normalizes a path like /a/b/c/../../d to /a/d.
    // Note: Does not work properly on Windows at the moment because it is hardcoded to use forward slashes rather than using the native path separator.
- (unichar)firstCharacter;
- (unichar)lastCharacter;
- (NSString *)lowercaseFirst;
- (NSString *)uppercaseFirst;

- (NSString *)stringByApplyingDeferredCFEncoding:(CFStringEncoding)newEncoding;

- (NSString *)stringByReplacingAllOccurrencesOfString:(NSString *)stringToReplace withString:(NSString *)replacement;
    // Can be better than making a mutable copy and calling -[NSMutableString replaceOccurrencesOfString:withString:options:range:] -- if stringToReplace is not found in the receiver, then the receiver is retained, autoreleased, and returned immediately.

- (NSString *)stringByReplacingCharactersInSet:(NSCharacterSet *)set withString:(NSString *)replaceString;


- (NSString *)stringByReplacingKeysInDictionary:(NSDictionary *)keywordDictionary startingDelimiter:(NSString *)startingDelimiterString endingDelimiter:(NSString *)endingDelimiterString removeUndefinedKeys: (BOOL) removeUndefinedKeys;
    // Useful for turning $(NEXT_ROOT)/LocalLibrary into C:/Apple/LocalLibrary.  If removeUndefinedKeys is YES and there is no key in the source dictionary, then @"" will be used to replace the variable substring. Uses -stringByReplacingKeys:.
- (NSString *)stringByReplacingKeysInDictionary:(NSDictionary *)keywordDictionary startingDelimiter:(NSString *)startingDelimiterString endingDelimiter:(NSString *)endingDelimiterString;
    // Calls -stringByReplacingKeysInDictionary:startingDelimiter:endingDelimiter:removeUndefinedKeys: with removeUndefinedKeys NO.

typedef NSString *(*OFVariableReplacementFunction)(NSString *, void *);
- (NSString *)stringByReplacingKeys:(OFVariableReplacementFunction)replacer startingDelimiter:(NSString *)startingDelimiterString endingDelimiter:(NSString *)endingDelimiterString context:(void *)context;
    // The most generic form of variable replacement, letting you use your own replacer instead of providing a keyword dictionary
    
- (NSString *)stringByReplacingOccurancesOfString:(NSString *)targetString withObjectsFromArray:(NSArray *)sourceArray;

// Generalized replacement function, and some convenience covers.
typedef NSString *(*OFSubstringReplacementFunction)(NSString *, NSRange *, void *);
- (NSString *)stringByPerformingReplacement:(OFSubstringReplacementFunction)replacer
                               onCharacters:(NSCharacterSet *)replaceMe
                                    context:(void *)context
                                    options:(unsigned int)options
                                      range:(NSRange)touchMe;
- (NSString *)stringByPerformingReplacement:(OFSubstringReplacementFunction)replacer
                               onCharacters:(NSCharacterSet *)replaceMe;

- (NSString *)stringBySeparatingSubstringsOfLength:(unsigned int)substringLength withString:(NSString *)separator startingFromBeginning:(BOOL)startFromBeginning;

- (NSString *)substringStartingWithString:(NSString *)startString;
- (NSString *)substringStartingAfterString:(NSString *)startString;
- (NSArray *)componentsSeparatedByString:(NSString *)separator maximum:(unsigned)atMost;
- (NSArray *)componentsSeparatedByCharactersFromSet:(NSCharacterSet *)delimiterSet;
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

#define OF_CHARACTER_BUFFER_SIZE (1024u)

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

- (NSData *)dataUsingCFEncoding:(CFStringEncoding)anEncoding allowLossyConversion:(BOOL)lossy hexEscapes:(NSString *)escapePrefix;

+ (NSString *)encodeURLString:(NSString *)unencodedString asQuery:(BOOL)asQuery leaveSlashes:(BOOL)leaveSlashes leaveColons:(BOOL)leaveColons;
+ (NSString *)encodeURLString:(NSString *)unencodedString encoding:(CFStringEncoding)thisUrlEncoding asQuery:(BOOL)asQuery leaveSlashes:(BOOL)leaveSlashes leaveColons:(BOOL)leaveColons;
- (NSString *)fullyEncodeAsIURI;  // This takes a string which is already in %-escaped URI format and fully escapes any characters which are not safe. Slashes, question marks, etc. are unaffected.

- (NSString *)htmlString;

/* Regular expression encoding */
- (NSString *)regularExpressionForLiteralString;


/* Mail header encoding according to RFCs 822 and 2047 */
- (NSString *)asRFC822Word;         /* Returns an 'atom' or 'quoted-string', or nil if not possible */
- (NSString *)asRFC2047EncodedWord; /* Returns an 'encoded-word' representing the receiver */
- (NSString *)asRFC2047Phrase;      /* Returns a sequence of atoms, quoted-strings, and encoded-words, as appropriate to represent the receiver in the syntax defined by RFC822 and RFC2047. */

@end

/* Creating an ASCII representation of a floating-point number, without using exponential notation. */
/* OFCreateDecimalStringFromDouble() formats a double into an NSString (which must be released by the caller, hence the word 'create' in the function name). This function will never return a value in exponential notation: it will always be in integer/decimal notation. If the returned string includes a decimal point, there will always be at least one digit on each side of the decimal point. */
OmniFoundation_EXTERN NSString *OFCreateDecimalStringFromDouble(double value);
/* OFASCIIDecimalStringFromDouble() returns a malloc()d buffer containing the decimal string, in ASCII. */
OmniFoundation_EXTERN char *OFASCIIDecimalStringFromDouble(double value);
/* OFShortASCIIDecimalStringFromDouble() returns a malloc()d buffer containing the decimal string, in ASCII.
   eDigits indicates the number of significant digits of the number, in base e.
   allowExponential indicates that an exponential representation may be returned if it's shorter than the plain decimal representation.
   forceLeadingZero forces a digit before the decimal point (e.g. 0.1 instead of .1). */
OmniFoundation_EXTERN char *OFShortASCIIDecimalStringFromDouble(double value, double eDigits, BOOL allowExponential, BOOL forceLeadingZero);
#define OF_FLT_DIGITS_E (16.6355323334)  // equal to log(FLT_MANT_DIG) / log(FLT_RADIX)

