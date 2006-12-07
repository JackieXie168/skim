// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/NSString-OFExtensions.h>

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

#import <OmniFoundation/OFStringDecoder.h>
#import <OmniFoundation/OFStringScanner.h>
#import <OmniFoundation/OFRegularExpression.h>
#import <OmniFoundation/OFRegularExpressionMatch.h>
#import <OmniFoundation/NSData-OFExtensions.h>
#import <OmniFoundation/NSMutableString-OFExtensions.h>
#import <OmniFoundation/NSThread-OFExtensions.h>
#import <OmniFoundation/NSFileManager-OFExtensions.h>
#import "NSObject-OFExtensions.h"
#import "OFStringScanner.h"

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSString-OFExtensions.m,v 1.89 2004/02/10 04:07:46 kc Exp $")

/* Character sets & variables used for URI encoding */
static NSMutableCharacterSet *EscapeCharacterSet;
static NSMutableCharacterSet *UnsafeCharacterSet;
static CFStringEncoding urlEncoding = kCFStringEncodingUTF8;

/* Character sets used for mail header encoding */
static NSCharacterSet *nonNonCTLChars = nil;
static NSCharacterSet *nonAtomChars = nil;
static NSCharacterSet *nonAtomCharsExceptLWSP = nil;

/* To set up character set used for deferred string decoding (see OFStringDecoder.[hm]) */
OmniFoundation_PRIVATE_EXTERN void OFStringDecoder_DidLoad(void);

@implementation NSString (OFExtensions)

+ (void) didLoad;
{
    NSCharacterSet *nonCTLChars;
    NSMutableCharacterSet *workSet;

    EscapeCharacterSet = [[NSMutableCharacterSet alloc] init];
    [EscapeCharacterSet addCharactersInString:@"*-.0123456789@ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz"];
    [EscapeCharacterSet invert];
    
    UnsafeCharacterSet = [[NSMutableCharacterSet alloc] init];
    [UnsafeCharacterSet addCharactersInRange:NSMakeRange(33, 95)];
    [UnsafeCharacterSet invert];
    [UnsafeCharacterSet addCharactersInString:@"#\"<[{|}]>\\^`"];
    // UnsafeCharacterSet should match the bitmap isSafe in -fullyEncodeAsIURI

    nonCTLChars = [NSCharacterSet characterSetWithRange:(NSRange){32, 95}];
    nonNonCTLChars = [[nonCTLChars invertedSet] retain];

    workSet = [nonNonCTLChars mutableCopy];
    [workSet addCharactersInString:@"()<>@,;:\\\".[] "];
    nonAtomChars = [workSet copy];
    
    [workSet removeCharactersInString:@" \t"];
    nonAtomCharsExceptLWSP = [workSet copy];
    
    [workSet release];

    OFStringDecoder_DidLoad();
}

+ (NSString *)stringWithData:(NSData *)data encoding:(NSStringEncoding)encoding;
{
    return [[[self alloc] initWithData:data encoding:encoding] autorelease];
}

+ (NSString *)abbreviatedStringForBytes:(unsigned long long)bytes;
{
    double kb, mb, gb, tb, pb;
    
    // We can't use [self bundle] or [NSString bundle], since that would try to load from Foundation, where NSString is defined. So we use [OFObject bundle]. If this file is ever moved to a bundle other than the one containing OFObject, that will have to be changed.
    
    if (bytes < 1000)
        return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%d bytes", @"OmniFoundation", [OFObject bundle], abbreviated string for bytes format), (int)bytes];
    kb = bytes / 1024.0;
    if (kb < 1000.0)
        return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%0.1f kB", @"OmniFoundation", [OFObject bundle], abbreviated string for bytes format), kb];
    mb = kb / 1024.0;
    if (mb < 1000.0)
        return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%0.1f MB", @"OmniFoundation", [OFObject bundle], abbreviated string for bytes format), mb];
    gb = mb / 1024.0;
    if (gb < 1000.0)
        return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%0.1f GB", @"OmniFoundation", [OFObject bundle], abbreviated string for bytes format), gb];
    tb = gb / 1024.0;
    if (tb < 1000.0)
        return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%0.1f TB", @"OmniFoundation", [OFObject bundle], abbreviated string for bytes format), tb];
    pb = tb / 1024.0;
    return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%0.1f PB", @"OmniFoundation", [OFObject bundle], abbreviated string for bytes format), pb];
}

+ (NSString *)humanReadableStringForTimeInterval:(NSTimeInterval)timeInterval;
{
    NSString *intervalString;
    unsigned long int days, hours, minutes, seconds;
    BOOL inThePast = NO;

    timeInterval = rint(timeInterval);
    if (timeInterval < 0) {
        inThePast = YES;
        timeInterval = -timeInterval;
    }
    days = timeInterval / (24 * 60 * 60);
    timeInterval -= days * (24 * 60 * 60);
    hours = timeInterval / (60 * 60);
    timeInterval -= hours * (60 * 60);
    minutes = timeInterval / 60;
    timeInterval -= minutes * 60;
    seconds = timeInterval;
    
    if (days > 1)
        intervalString = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%ld days, %ld:%02ld:%02ld", @"OmniFoundation", [OFObject bundle], humanReadableStringForTimeInterval), days, hours, minutes, seconds];
    else if (days == 1)
        intervalString = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%ld day, %ld:%02ld:%02ld", @"OmniFoundation", [OFObject bundle], humanReadableStringForTimeInterval), days, hours, minutes, seconds];
    else if (hours > 0)
        intervalString = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%ld:%02ld:%02ld", @"OmniFoundation", [OFObject bundle], humanReadableStringForTimeInterval), hours, minutes, seconds];
    else if (minutes > 0)
        intervalString = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%ld:%02ld", @"OmniFoundation", [OFObject bundle], humanReadableStringForTimeInterval), minutes, seconds];
    else if (seconds > 0)
        intervalString = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%ld seconds", @"OmniFoundation", [OFObject bundle], humanReadableStringForTimeInterval), seconds];
    else
        intervalString = NSLocalizedStringFromTableInBundle(@"right now", @"OmniFoundation", [OFObject bundle], humanReadableStringForTimeInterval);

    if (!inThePast)
        return intervalString;
    else
        return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%@ ago", @"OmniFoundation", [OFObject bundle], humanReadableStringForTimeInterval), intervalString];
}

+ (NSString *)spacesOfLength:(unsigned int)aLength;
{
    static NSMutableString *spaces = nil;
    static NSLock *spacesLock;
    static unsigned int spacesLength;

    if (!spaces) {
	spaces = [@"                " mutableCopy];
	spacesLength = [spaces length];
        spacesLock = [[NSLock alloc] init];
    }
    if (spacesLength < aLength) {
        [spacesLock lock];
        while (spacesLength < aLength) {
            [spaces appendString:spaces];
            spacesLength += spacesLength;
        }
        [spacesLock unlock];
    }
    return [spaces substringToIndex:aLength];
}

+ (NSString *)stringWithCharacter:(unsigned int)aCharacter;
{
    unichar utf16[2];
    NSString *result;

    OBASSERT(sizeof(aCharacter)*8 >= 21);
    /* aCharacter must be at least 21 bits to contain a full Unicode character */

    if (aCharacter <= 0xFFFF) {
        utf16[0] = (unichar)aCharacter;
        result = [[NSString alloc] initWithCharacters:utf16 length:1];
    } else {
        /* Convert Unicode characters in supplementary planes into pairs of UTF-16 surrogates */
        OFCharacterToSurrogatePair(aCharacter, utf16);
        result = [[NSString alloc] initWithCharacters:utf16 length:2];
    }
    return [result autorelease];
}

+ (NSString *)stringWithStrings:(NSString *)first, ...
{
    NSMutableString *buffer;
    NSString *prev;
    NSString *returnValue;
    va_list argList;

    buffer = [[NSMutableString alloc] init];

    va_start(argList, first);
    prev = first;
    while(prev != nil) {
        [buffer appendString:prev];
        prev = va_arg(argList, NSString *);
    }
    va_end(argList);

    returnValue = [buffer copy];
    [buffer release];
    return [returnValue autorelease];
}

+ (NSString *)stringWithFourCharCode:(FourCharCode)code;
{
     return [NSString stringWithCString:(const char *)&code length:4];
}

+ (NSString *)horizontalEllipsisString;
{
    static NSString *string = nil;

    if (!string)
        string = [[self stringWithCharacter:0x2026] retain];

    OBPOSTCONDITION(string);

    return string;
}

+ (NSString *)leftPointingDoubleAngleQuotationMarkString;
{
    static NSString *string = nil;

    if (!string)
        string = [[self stringWithCharacter:0xab] retain];

    OBPOSTCONDITION(string);

    return string;
}

+ (NSString *)rightPointingDoubleAngleQuotationMarkString;
{
    static NSString *string = nil;

    if (!string)
        string = [[self stringWithCharacter:0xbb] retain];

    OBPOSTCONDITION(string);

    return string;
}

+ (NSString *)emdashString;
{
    static NSString *string = nil;

    if (!string)
        string = [[self stringWithCharacter:0x2014] retain];

    OBPOSTCONDITION(string);

    return string;
}

+ (NSString *)endashString;
{
    static NSString *string = nil;

    if (!string)
        string = [[self stringWithCharacter:0x2013] retain];

    OBPOSTCONDITION(string);

    return string;
}

+ (NSString *)commandKeyIndicatorString;
{
    static NSString *string = nil;

    if (!string)
        string = [[self stringWithCharacter:0x2318] retain];

    OBPOSTCONDITION(string);

    return string;
}

+ (NSString *)alternateKeyIndicatorString;
{
    static NSString *string = nil;

    if (!string)
        string = [[self stringWithCharacter:0x2325] retain];

    OBPOSTCONDITION(string);

    return string;
}

+ (NSString *)shiftKeyIndicatorString;
{
    static NSString *string = nil;

    if (!string)
        string = [[self stringWithCharacter:0x21E7] retain];

    OBPOSTCONDITION(string);

    return string;
}

+ (BOOL)isEmptyString:(NSString *)string;
    // Returns YES if the string is nil or equal to @""
{
    // Note that [string length] == 0 can be false when [string isEqualToString:@""] is true, because these are Unicode strings.
    return string == nil || [string isEqualToString:@""];
}

- (BOOL)containsCharacterInSet:(NSCharacterSet *)searchSet;
{
    NSRange characterRange;

    characterRange = [self rangeOfCharacterFromSet:searchSet];
    return characterRange.length != 0;
}

- (BOOL)containsString:(NSString *)searchString options:(unsigned int)mask;
{
    return !searchString || [searchString length] == 0 || [self rangeOfString:searchString options:mask].length > 0;
}

- (BOOL)containsString:(NSString *)searchString;
{
    return !searchString || [searchString length] == 0 || [self rangeOfString:searchString].length > 0;
}

- (BOOL)isEqualToCString:(const char *)cString;
{
    if (!cString)
	return NO;
    return [self isEqualToString:[NSString stringWithCString:cString]];
}

- (BOOL)hasLeadingWhitespace;
{
    if ([self length] == 0)
	return NO;
    switch ([self characterAtIndex:0]) {
        case ' ':
        case '\t':
        case '\r':
        case '\n':
            return YES;
        default:
            return NO;
    }
}

- (BOOL)isPercentage;
{
    int index, count;
    unichar c;
    
    count = [self length];
    for (index = 0; index < count; index++) {
        c = [self characterAtIndex:index];
        if (c == '%')
            return YES;
        else if ((c >= '0' && c <= '9') || c == '.')
            continue;
        else
            break;
    }        
    return NO;
}

- (BOOL)boolValue;
{
    // Should maybe later add a configurable dictionary that contains the valid YES and NO values
    if ([self isEqualToString:@"YES"] || [self isEqualToString:@"Y"] || [self isEqualToString:@"yes"] || [self isEqualToString:@"y"] || [self isEqualToString:@"1"])
        return YES;
    else
        return NO;
}

- (long long int)longLongValue;
{
    long long int longLongValue;
    NSScanner *scanner;

    scanner = [[NSScanner alloc] initWithString:self];
    if (![scanner scanLongLong:&longLongValue])
        longLongValue = 0;
    [scanner release];
    return longLongValue;
}

- (unsigned int)unsignedIntValue;
{
    return (unsigned int)[self intValue];
}

- (NSDecimal)decimalValue;
{
    return [[NSDecimalNumber decimalNumberWithString:self] decimalValue];
}

- (NSDecimalNumber *)decimalNumberValue;
{
    return [NSDecimalNumber decimalNumberWithString:self];
}

- (NSNumber *)numberValue;
{
    return [NSNumber numberWithInt:[self intValue]];
}

- (NSArray *)arrayValue;
{
    return [NSArray arrayWithObject:self];
}

- (NSDictionary *)dictionaryValue;
{
    return (NSDictionary *)[self propertyList];
}

- (NSData *)dataValue;
{
    return [self dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
}

- (NSCalendarDate *)dateValue;
{
    return [NSCalendarDate dateWithNaturalLanguageString:self];
}

- (FourCharCode)fourCharCodeValue;
{
    char *chars; //[4]
    FourCharCode code;
    
    OBASSERT([self length] >= 4);
    
    chars = (char*)[[self substringWithRange:NSMakeRange(0, 4)] cString];
    
    code = 0;
    code += chars[0] << 24;
    code += chars[1] << 16;
    code += chars[2] << 8;
    code += chars[3];
    
    return code;
}

#define MAX_HEX_TEXT_LENGTH 40

static inline unsigned int parseHexString(NSString *hexString, unsigned long long int *parsedHexValue)
{
    unsigned int hexLength;
    unichar hexText[MAX_HEX_TEXT_LENGTH];
    unichar hexDigit;
    unsigned int textIndex;
    unsigned long long int hexValue;
    unsigned int hexDigitsFound;

    hexLength = [hexString length];
    if (hexLength > MAX_HEX_TEXT_LENGTH)
        hexLength = MAX_HEX_TEXT_LENGTH;
    [hexString getCharacters:hexText range:NSMakeRange(0, hexLength)];

    textIndex = 0;
    hexValue = 0;
    hexDigitsFound = 0;

    while (textIndex < hexLength && isspace(hexText[textIndex])) {
        // Skip leading whitespace
        textIndex++;
    }

    if (hexText[textIndex] == '0' && hexText[textIndex + 1] == 'x') {
        // Skip leading "0x"
        textIndex += 2;
    }

    while (textIndex < hexLength) {
        hexDigit = hexText[textIndex++];

        if (hexDigit >= '0' && hexDigit <= '9') {
            hexDigit = hexDigit - '0';
        } else if (hexDigit >= 'A' && hexDigit <= 'F') {
            hexDigit = hexDigit - 'A' + 10;
        } else if (hexDigit >= 'a' && hexDigit <= 'f') {
            hexDigit = hexDigit - 'a' + 10;
        } else if (isspace(hexDigit)) {
            continue;
        } else {
            hexDigitsFound = 0;
            break;
        }
        hexDigitsFound++;
        hexValue <<= 4;
        hexValue |= hexDigit;
    }

    *parsedHexValue = hexValue;
    return hexDigitsFound;
}

- (unsigned int)hexValue;
{
    unsigned int hexDigitsParsed;
    unsigned long long int hexValue;

    hexDigitsParsed = parseHexString(self, &hexValue);
    if (hexDigitsParsed > 0) {
        // More than one hex digit parsed
        // Since we return a long and we just parsed a long long, let's be explicit about throwing away the high bits.
        return (unsigned int)(hexValue & 0xffffffff);
    } else {
        // No hex digits, use the default return value
        return 0;
    }
}

- (NSString *)stringByUppercasingAndUnderscoringCaseChanges;
{
    static OFCharacterSet *lowercaseOFCharacterSet, *uppercaseOFCharacterSet, *numberOFCharacterSet, *currentOFCharacterSet;
    NSMutableArray *words;
    OFStringScanner *scanner;
    unsigned int wordStartIndex = 0;
    static BOOL hasInitialized = NO;

    if (![self length])
        return nil;
    
    if (!hasInitialized) {
        // Potential minor memory leak here due to multithreading
        lowercaseOFCharacterSet = [[OFCharacterSet alloc] initWithCharacterSet:[NSCharacterSet lowercaseLetterCharacterSet]];
        uppercaseOFCharacterSet = [[OFCharacterSet alloc] initWithCharacterSet:[NSCharacterSet uppercaseLetterCharacterSet]];
        numberOFCharacterSet = [[OFCharacterSet alloc] initWithCharacterSet:[NSCharacterSet decimalDigitCharacterSet]];

        hasInitialized = YES;
    }

    words = [NSMutableArray array];
    scanner = [[[OFStringScanner alloc] initWithString:self] autorelease];
    
    while (scannerHasData(scanner)) {
        unichar peekedChar;

        peekedChar = scannerPeekCharacter(scanner);
        if ([lowercaseOFCharacterSet characterIsMember:peekedChar])
            currentOFCharacterSet = lowercaseOFCharacterSet;
        else if ([uppercaseOFCharacterSet characterIsMember:peekedChar])
            currentOFCharacterSet = uppercaseOFCharacterSet;
        else if ([numberOFCharacterSet characterIsMember:peekedChar])
            currentOFCharacterSet = numberOFCharacterSet;
        else {
            [NSException raise:NSInvalidArgumentException format:@"Character: %@, at index: %d, not found in lowercase, uppercase, or decimal digit character sets", [NSString stringWithCharacter:peekedChar], scannerScanLocation];
        }

        if (scannerScanUpToCharacterNotInOFCharacterSet(scanner, currentOFCharacterSet)) {
            unsigned int scanLocation;

            scanLocation = scannerScanLocation(scanner);
            if (currentOFCharacterSet == lowercaseOFCharacterSet || currentOFCharacterSet == numberOFCharacterSet) {
                [words addObject:[self substringWithRange:NSMakeRange(wordStartIndex, scanLocation - wordStartIndex)]];
                wordStartIndex = scanLocation;
            } else if (currentOFCharacterSet == uppercaseOFCharacterSet) {
                if (scanLocation - wordStartIndex == 1) {
                    continue;
                } else if ([numberOFCharacterSet characterIsMember:scannerPeekCharacter(scanner)]) {
                    [words addObject:[self substringWithRange:NSMakeRange(wordStartIndex, scanLocation - wordStartIndex)]];
                    wordStartIndex = scanLocation;
                } else {
                    scanLocation--;
                    [scanner setScanLocation:scanLocation];
                    [words addObject:[self substringWithRange:NSMakeRange(wordStartIndex, scanLocation - wordStartIndex)]];
                    wordStartIndex = scanLocation;
                }
            } else {
                OBASSERT(NO);
            }
        }
    }

    [words addObject:[self substringWithRange:NSMakeRange(wordStartIndex, scannerScanLocation(scanner) - wordStartIndex)]];

    return [[words componentsJoinedByString:@"_"] uppercaseString];
}

- (NSString *)stringByRemovingSurroundingWhitespace;
{
    static NSCharacterSet *nonWhitespace = nil;
    NSRange firstValidCharacter, lastValidCharacter;

    if (!nonWhitespace) {
        nonWhitespace = [[[NSCharacterSet characterSetWithCharactersInString:
            @" \t\r\n"] invertedSet] retain];
    }
    
    firstValidCharacter = [self rangeOfCharacterFromSet:nonWhitespace];
    if (firstValidCharacter.length == 0)
	return @"";
    lastValidCharacter = [self rangeOfCharacterFromSet:nonWhitespace options:NSBackwardsSearch];

    if (firstValidCharacter.location == 0 && lastValidCharacter.location == [self length] - 1)
	return [[self retain] autorelease];
    else
	return [self substringWithRange:NSUnionRange(firstValidCharacter, lastValidCharacter)];
}

- (NSString *)stringByCollapsingWhitespaceAndRemovingSurroundingWhitespace;
{
    OFCharacterSet *whitespaceOFCharacterSet;
    OFStringScanner *stringScanner;
    NSMutableString *collapsedString;
    BOOL firstSubstring;
    unsigned int length;

    whitespaceOFCharacterSet = [OFCharacterSet whitespaceOFCharacterSet];
    length = [self length];
    if (length == 0)
        return @""; // Trivial optimization

    stringScanner = [[OFStringScanner alloc] initWithString:self];
    collapsedString = [[NSMutableString alloc] initWithCapacity:length];
    firstSubstring = YES;
    while (scannerScanUpToCharacterNotInOFCharacterSet(stringScanner, whitespaceOFCharacterSet)) {
        NSString *nonWhitespaceSubstring;

        nonWhitespaceSubstring = [stringScanner readFullTokenWithDelimiterOFCharacterSet:whitespaceOFCharacterSet forceLowercase:NO];
        if (nonWhitespaceSubstring) {
            if (firstSubstring) {
                firstSubstring = NO;
            } else {
                [collapsedString appendString:@" "];
            }
            [collapsedString appendString:nonWhitespaceSubstring];
        }
    }
    [stringScanner release];
    return [collapsedString autorelease];
}

- (NSString *)stringByRemovingWhitespace;
{
    return [self stringByRemovingCharactersInOFCharacterSet:[OFCharacterSet whitespaceOFCharacterSet]];
}

- (NSString *)stringByRemovingCharactersInOFCharacterSet:(OFCharacterSet *)removeSet;
{
    OFStringScanner *stringScanner;
    NSMutableString *strippedString;
    unsigned int length;

    length = [self length];
    if (length == 0)
        return @""; // Trivial optimization

    stringScanner = [[OFStringScanner alloc] initWithString:self];
    strippedString = [[NSMutableString alloc] initWithCapacity:length];
    while (scannerScanUpToCharacterNotInOFCharacterSet(stringScanner, removeSet)) {
        NSString *nonWhitespaceSubstring;

        nonWhitespaceSubstring = [stringScanner readFullTokenWithDelimiterOFCharacterSet:removeSet forceLowercase:NO];
        if (nonWhitespaceSubstring != nil)
            [strippedString appendString:nonWhitespaceSubstring];
    }
    [stringScanner release];
    return [strippedString autorelease];
}

- (NSString *)stringByRemovingReturns;
{
    return [self stringByRemovingCharactersInOFCharacterSet:[OFCharacterSet characterSetWithString:@"\r\n"]];
}

- (NSString *)stringByRemovingRegularExpression:(OFRegularExpression *)regularExpression;
{
    OFRegularExpressionMatch *match = [regularExpression matchInString:self];
        
    if (match == nil)
       return self;
    return [[self stringByRemovingString:[match matchString]] stringByRemovingRegularExpression:regularExpression];
}

- (NSString *)stringByRemovingString:(NSString *)removeString
{
    NSArray *lines;
    NSMutableString *newString;
    NSString *returnValue;
    unsigned int lineIndex, lineCount;

    if (![self containsString:removeString])
	return [[self copy] autorelease];
    newString = [[NSMutableString alloc] initWithCapacity:[self length]];
    lines = [self componentsSeparatedByString:removeString];
    lineCount = [lines count];
    for (lineIndex = 0; lineIndex < lineCount; lineIndex++)
	[newString appendString:[lines objectAtIndex:lineIndex]];
    returnValue = [newString copy];
    [newString release];
    return [returnValue autorelease];
}

- (NSString *)stringByPaddingToLength:(unsigned int)aLength;
{
    unsigned int currentLength;

    currentLength = [self length];

    if (currentLength == aLength)
	return [[self retain] autorelease];
    if (currentLength > aLength)
	return [self substringToIndex:aLength];
    return [self stringByAppendingString:[[self class] spacesOfLength:aLength - currentLength]];
}

- (NSString *)stringByNormalizingPath;
{
    NSArray *pathElements;
    NSMutableArray *newPathElements;
    unsigned int preserveCount;
    unsigned int elementIndex, elementCount;

    // Split on slashes and chop out '.' and '..' correctly.

    pathElements = [self componentsSeparatedByString:@"/"];
    elementCount = [pathElements count];
    newPathElements = [NSMutableArray arrayWithCapacity:elementCount];
    if (elementCount > 0 && [[pathElements objectAtIndex:0] isEqualToString:@""])
	preserveCount = 1;
    else
        preserveCount = 0;
    for (elementIndex = 0; elementIndex < elementCount; elementIndex++) {
	NSString *pathElement;

	pathElement = [pathElements objectAtIndex:elementIndex];
	if ([pathElement isEqualToString:@".."]) {
	    if ([pathElements count] > preserveCount)
		[newPathElements removeLastObject];
	} else if (![pathElement isEqualToString:@"."])
	    [newPathElements addObject:pathElement];
    }
    return [newPathElements componentsJoinedByString:@"/"];
}

- (unichar)firstCharacter;
{
    if ([self length] == 0)
	return '\0';
    return [self characterAtIndex:0];
}

- (unichar)lastCharacter;
{
    unsigned int length;

    length = [self length];
    if (length == 0)
        return '\0';
    return [self characterAtIndex:length - 1];
}

- (NSString *)lowercaseFirst;
{
    return [[[self substringToIndex:1] lowercaseString] stringByAppendingString:[self substringFromIndex:1]];
}

- (NSString *)uppercaseFirst;
{
    return [[[self substringToIndex:1] uppercaseString] stringByAppendingString:[self substringFromIndex:1]];
}

- (NSString *)stringByApplyingDeferredCFEncoding:(CFStringEncoding)newEncoding;
{
    if (!OFStringContainsDeferredEncodingCharacters(self)) {
        return [[self copy] autorelease];
    } else {
        return OFApplyDeferredEncoding(self, newEncoding);
    }
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

- (NSString *)stringByReplacingKeysInDictionary:(NSDictionary *)keywordDictionary startingDelimiter:(NSString *)startingDelimiterString endingDelimiter:(NSString *)endingDelimiterString removeUndefinedKeys: (BOOL) removeUndefinedKeys;
{
    NSScanner *scanner = [NSScanner scannerWithString:self];
    NSMutableString *interpolatedString = [NSMutableString string];
    NSString *scannerOutput;
    BOOL didInterpolate = NO;

    while (![scanner isAtEnd]) {
        NSString *key = nil;
        NSString *value;
        BOOL gotInitialString, gotStartDelimiter, gotEndDelimiter;
        BOOL gotKey;

        gotInitialString = [scanner scanUpToString:startingDelimiterString intoString:&scannerOutput];
        if (gotInitialString) {
            [interpolatedString appendString:scannerOutput];
        }

        gotStartDelimiter = [scanner scanString:startingDelimiterString intoString:NULL];
        gotKey = [scanner scanUpToString:endingDelimiterString intoString:&key];
        gotEndDelimiter = [scanner scanString:endingDelimiterString intoString:NULL];

        if (gotKey) {
            value = [keywordDictionary objectForKey:key];
            if (!value && removeUndefinedKeys)
                value = @"";
            if (value != nil && [value isKindOfClass:[NSString class]]) {
                [interpolatedString appendString:value];
                didInterpolate = YES;
            }
        } else {
            if (gotStartDelimiter)
                [interpolatedString appendString:startingDelimiterString];
            if (gotKey)
                [interpolatedString appendString:key];
            if (gotEndDelimiter)
                [interpolatedString appendString:endingDelimiterString];
        }
    }
    return didInterpolate ? [[interpolatedString copy] autorelease] : self;
}

- (NSString *)stringByReplacingKeysInDictionary:(NSDictionary *)keywordDictionary startingDelimiter:(NSString *)startingDelimiterString endingDelimiter:(NSString *)endingDelimiterString;
{
    return [self stringByReplacingKeysInDictionary: keywordDictionary
                                 startingDelimiter: startingDelimiterString
                                   endingDelimiter: endingDelimiterString
                               removeUndefinedKeys: NO];
}

- (NSString *)stringByReplacingOccurancesOfString:(NSString *)targetString withObjectsFromArray:(NSArray *)sourceArray;
{
    NSMutableString *resultString;
    OFStringScanner *replacementScanner;
    unsigned int occurranceIndex = 0;
    unsigned int lastAppendedIndex = 0;
    unsigned int sourceCount;
    unsigned int targetStringLength;

    replacementScanner = [[[OFStringScanner alloc] initWithString:self] autorelease];
    resultString = [NSMutableString string];

    targetStringLength = [targetString length];
    sourceCount = [sourceArray count];
    
    while ([replacementScanner scanUpToString:targetString]) {
        NSRange beforeMatchRange;
        NSString *itemDescription;
        unsigned int scanLocation;

        scanLocation = [replacementScanner scanLocation];
        beforeMatchRange = NSMakeRange(lastAppendedIndex, scanLocation - lastAppendedIndex);
        if (beforeMatchRange.length > 0)
            [resultString appendString:[self substringWithRange:beforeMatchRange]];

        if (occurranceIndex >= sourceCount) {
            [NSException raise:NSInvalidArgumentException format:@"The string being scanned has more occurrances of the target string than the source array has items (scannedString = %@, targetString = %@, sourceArray = %@)."];
        }
        
        itemDescription = [[sourceArray objectAtIndex:occurranceIndex] description];
        [resultString appendString:itemDescription];

        occurranceIndex++;
        [replacementScanner setScanLocation:scanLocation + targetStringLength];
        lastAppendedIndex = [replacementScanner scanLocation];
    }

    if (lastAppendedIndex < [self length])
        [resultString appendString:[self substringFromIndex:lastAppendedIndex]];

    return [[resultString copy] autorelease];
}

- (NSString *) stringBySeparatingSubstringsOfLength:(unsigned int)substringLength                                          withString:(NSString *)separator startingFromBeginning:(BOOL)startFromBeginning;
{
    unsigned int     lengthLeft, offset = 0;
    NSMutableString *result;

    lengthLeft = [self length];
    if (lengthLeft <= substringLength)
        // Use <= since you have to have more than one group to need a separator.
        return [[self retain] autorelease];

    if (!substringLength)
        [NSException raise: NSInvalidArgumentException
                    format: @"-[%@ %@], substringLength must be non-zero.",
            NSStringFromClass(isa), NSStringFromSelector(_cmd), substringLength];
    
    result = [NSMutableString string];
    if (!startFromBeginning) {
        unsigned int mod;
        
        // We'll still really start from the beginning, but first we'll trim off
        // whatever the extra count is that would have gone on the end.  This
        // produces the same effect.

        mod = lengthLeft % substringLength;
        if (mod) {
            [result appendString: [self substringWithRange: NSMakeRange(offset, mod)]];
            [result appendString: separator];
            offset     += mod;
            lengthLeft -= mod;
        }
    }

    while (lengthLeft) {
        unsigned int lengthToCopy;

        lengthToCopy = MIN(lengthLeft, substringLength);
        [result appendString: [self substringWithRange: NSMakeRange(offset, lengthToCopy)]];
        lengthLeft -= lengthToCopy;
        offset     += lengthToCopy;

        if (lengthLeft)
            [result appendString: separator];
    }

    return result;
}

- (NSString *)substringStartingWithString:(NSString *)startString;
{
    NSRange startRange;

    startRange = [self rangeOfString:startString];
    if (startRange.length == 0)
        return nil;
    return [self substringFromIndex:startRange.location];
}

- (NSString *)substringStartingAfterString:(NSString *)aString;
{
    NSRange aRange;

    aRange = [self rangeOfString:aString];
    if (aRange.length == 0)
        return nil;
    return [self substringFromIndex:aRange.location + aRange.length];
}

- (NSString *)stringByRemovingPrefix:(NSString *)prefix;
{
    NSRange aRange;

    aRange = [self rangeOfString:prefix];
    if ((aRange.length == 0) || (aRange.location != 0))
        return [[self retain] autorelease];
    return [self substringFromIndex:aRange.location + aRange.length];
}

- (NSString *)stringByRemovingSuffix:(NSString *)suffix;
{
    if (![self hasSuffix:suffix])
        return [[self retain] autorelease];
    return [self substringToIndex:[self length] - [suffix length]];
}

- (NSString *)stringByIndenting:(int)spaces;
{
    return [self stringByIndenting:spaces andWordWrapping:999999 withFirstLineIndent:spaces];
}

- (NSString *)stringByWordWrapping:(int)columns;
{
    return [self stringByIndenting:0 andWordWrapping:columns withFirstLineIndent:0];
}

- (NSString *)stringByIndenting:(int)spaces andWordWrapping:(int)columns;
{
    return [self stringByIndenting:spaces andWordWrapping:columns withFirstLineIndent:spaces];
}

- (NSString *)stringByIndenting:(int)spaces andWordWrapping:(int)columns withFirstLineIndent:(int)firstLineSpaces;
{
    NSMutableString *result;
    NSString *indent;
    NSCharacterSet *whitespace;
    NSRange remainingRange, lineRange, breakRange, spaceRange;
    unsigned int start, end, contentEnd, available, length;
    BOOL isFirstLine;
    
    if (columns <= 0)
        return nil;
    if (spaces > columns)
        spaces = columns - 1;
    
    available = columns - firstLineSpaces;
    indent = [NSString spacesOfLength:firstLineSpaces];
    isFirstLine = YES;
    
    result = [NSMutableString string];
    whitespace = [NSCharacterSet whitespaceCharacterSet];
    length = [self length];
    remainingRange = NSMakeRange(0, [self length]);
    
    while (remainingRange.length) {
        [self getLineStart:&start end:&end contentsEnd:&contentEnd forRange:remainingRange];
        lineRange = NSMakeRange(start, contentEnd - start);
        while (lineRange.length > available) {
            breakRange = NSMakeRange(lineRange.location, available);
            spaceRange = [self rangeOfCharacterFromSet:whitespace options:NSBackwardsSearch range:breakRange];
            if (spaceRange.length) {
                breakRange = NSMakeRange(lineRange.location, spaceRange.location - lineRange.location);
                lineRange.length = NSMaxRange(lineRange) - NSMaxRange(spaceRange);
                lineRange.location = NSMaxRange(spaceRange);
            } else {
                lineRange.length = NSMaxRange(lineRange) - NSMaxRange(breakRange);
                lineRange.location = NSMaxRange(breakRange);
            }
            [result appendFormat:@"%@%@\n", indent, [self substringWithRange:breakRange]];
            if (isFirstLine) {	
                isFirstLine = NO;
                available = columns - spaces;
                indent = [NSString spacesOfLength:spaces];
            }
        }
        [result appendFormat:@"%@%@\n", indent, [self substringWithRange:lineRange]];
        if (isFirstLine) {	
            isFirstLine = NO;
            available = columns - spaces;
            indent = [NSString spacesOfLength:spaces];
        }
        remainingRange = NSMakeRange(end, length - end);
    }
    return result;
}

- (NSRange)findString:(NSString *)string selectedRange:(NSRange)selectedRange options:(unsigned int)options wrap:(BOOL)wrap;
{
    BOOL forwards;
    unsigned int length;
    NSRange searchRange, range;

    length = [self length];
    forwards = (options & NSBackwardsSearch) == 0;
    if (forwards) {
	searchRange.location = NSMaxRange(selectedRange);
	searchRange.length = length - searchRange.location;
	range = [self rangeOfString:string options:options range:searchRange];
        if ((range.length == 0) && wrap) {
            // If not found look at the first part of the string
	    searchRange.location = 0;
            searchRange.length = selectedRange.location;
            range = [self rangeOfString:string options:options range:searchRange];
        }
    } else {
	searchRange.location = 0;
	searchRange.length = selectedRange.location;
        range = [self rangeOfString:string options:options range:searchRange];
        if ((range.length == 0) && wrap) {
            searchRange.location = NSMaxRange(selectedRange);
            searchRange.length = length - searchRange.location;
            range = [self rangeOfString:string options:options range:searchRange];
        }
    }
    return range;
}        

- (NSRange)rangeOfCharactersAtIndex:(unsigned)pos delimitedBy:(NSCharacterSet *)delim;
{
    unsigned int myLength;
    NSRange searchRange, foundRange;
    unsigned int first, after;

    myLength = [self length];
    searchRange.location = 0;
    searchRange.length = pos;
    foundRange = [self rangeOfCharacterFromSet:delim options:NSBackwardsSearch range:searchRange];
    if (foundRange.length > 0)
      first = foundRange.location + foundRange.length;
    else
      first = 0;

    searchRange.location = pos;
    searchRange.length = myLength - pos;
    foundRange = [self rangeOfCharacterFromSet:delim options:0 range:searchRange];
    if (foundRange.length > 0)
      after = foundRange.location;
    else
      after = myLength;

    foundRange.location = first;
    foundRange.length = after - first;
    return foundRange;
}

- (NSRange)rangeOfWordContainingCharacter:(unsigned int)pos;
{
    NSCharacterSet *wordSep;
    unichar ch;

    // XXX TODO: This should depend on what your notion of a "word" is.
    wordSep = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    ch = [self characterAtIndex:pos];
    if ([wordSep characterIsMember:ch])
        return [self rangeOfCharactersAtIndex:pos delimitedBy:[wordSep invertedSet]];
    else
        return [self rangeOfCharactersAtIndex:pos delimitedBy:wordSep];
}

- (NSRange)rangeOfWordsIntersectingRange:(NSRange)range;
{
    unsigned int first, last;
    NSRange firstRange, lastRange;

    if (range.length == 0)
        return NSMakeRange(0, 0);

    first = range.location;
    last = NSMaxRange(range) - 1;
    firstRange = [self rangeOfWordContainingCharacter:first];
    lastRange = [self rangeOfWordContainingCharacter:last];
    return NSMakeRange(firstRange.location, NSMaxRange(lastRange) - firstRange.location);
}

- (unsigned)indexOfCharacterNotRepresentableInCFEncoding:(CFStringEncoding)anEncoding;
{
    return [self indexOfCharacterNotRepresentableInCFEncoding:anEncoding range:NSMakeRange(0, [self length])];
}

- (unsigned)indexOfCharacterNotRepresentableInCFEncoding:(CFStringEncoding)anEncoding range:(NSRange)aRange;
{
    CFIndex usedBufLen;
    CFIndex thisBufferCharacters;
    CFRange scanningRange;
    CFIndex bufLen = 1024;  // warning: this routine will fail if any single character requires more than 1024 bytes to represent! (ha, ha)
    
    scanningRange.location = aRange.location;
    scanningRange.length = aRange.length;
    while (1) {
        if (!(scanningRange.length))
            return NSNotFound;
            
        usedBufLen = 0;
        thisBufferCharacters = CFStringGetBytes((CFStringRef)self, scanningRange, anEncoding, 0, FALSE, NULL, bufLen, &usedBufLen);
        if (thisBufferCharacters == 0)
            break;
        OBASSERT(thisBufferCharacters <= scanningRange.length);
        scanningRange.location += thisBufferCharacters;
        scanningRange.length -= thisBufferCharacters;
    }
    
    return scanningRange.location;
}

- (NSRange)rangeOfCharactersNotRepresentableInCFEncoding:(CFStringEncoding)anEncoding
{
    unsigned firstBad;
    CFIndex thisBad;
    CFIndex charactersConverted;
    NSRange testNSRange;
    CFRange testCFRange;
    CFIndex bufLen = 1024;
    CFIndex usedBufLen;
    int myLength; 

    myLength = [self length];
    firstBad = [self indexOfCharacterNotRepresentableInCFEncoding:anEncoding];
    if (firstBad == NSNotFound)
        return NSMakeRange(myLength, 0);
 
    for (thisBad = firstBad; thisBad < myLength; thisBad += testCFRange.length) {

        // there's no CoreFoundation function for this, sigh
        testNSRange = [self rangeOfComposedCharacterSequenceAtIndex:thisBad];
        if (testNSRange.length == 0) {
            // We've reached the end of the string buffer
            break;
        }

        testCFRange.location = thisBad;
        testCFRange.length = testNSRange.length;

        usedBufLen = 0;
        charactersConverted = CFStringGetBytes((CFStringRef)self, testCFRange, anEncoding, 0, FALSE, NULL, bufLen, &usedBufLen);
        if (charactersConverted > 0)
            break;
    };

    return NSMakeRange(firstBad, thisBad - firstBad);
}

- (NSData *)dataUsingCFEncoding:(CFStringEncoding)anEncoding;
{
    CFDataRef result;

    result = OFCreateDataFromStringWithDeferredEncoding((CFStringRef)self, (CFRange){location: 0, length:[self length]}, anEncoding, (char)0);

    return [(NSData *)result autorelease];
}

- (NSData *)dataUsingCFEncoding:(CFStringEncoding)anEncoding allowLossyConversion:(BOOL)lossy;
{
    CFDataRef result;
    
    result = OFCreateDataFromStringWithDeferredEncoding((CFStringRef)self, (CFRange){location: 0, length:[self length]}, anEncoding, lossy?'?':0);

    return [(NSData *)result autorelease];
}

- (BOOL)writeToFile:(NSString *)path atomically:(BOOL)useAuxiliaryFile createDirectories:(BOOL)shouldCreateDirectories;
    // Will raise an exception if it can't create the required directories.
{
    if (shouldCreateDirectories) {
        // TODO: We ought to make the attributes configurable
        [[NSFileManager defaultManager] createPathToFile:path attributes:nil];
    }

    return [self writeToFile:path atomically:useAuxiliaryFile];
}

//
// URL encoding
//

+ (void)setURLEncoding:(CFStringEncoding)newURLEncoding;
{
    urlEncoding = newURLEncoding;
    if (urlEncoding == kCFStringEncodingInvalidId)
        urlEncoding = kCFStringEncodingUTF8;
}

+ (CFStringEncoding)urlEncoding
{
    return urlEncoding;
}

static inline unichar hexDigit(unichar digit)
{
    if (isdigit(digit))
	return digit - '0';
    else if (isupper(digit))
	return 10 + digit - 'A';
    else 
	return 10 + digit - 'a';
}

static inline int valueOfHexPair(unichar highNybble, unichar lowNybble)
{
    short hnValue, lnValue;
    
    static const short hexValues[103] =
    {
          -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,
          -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,
          -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,
        0x00,0x11,0x22,0x33,0x44,0x55,0x66,0x77,0x88,0x99,  -1,  -1,  -1,  -1,  -1,  -1,
          -1,0xAA,0xBB,0xCC,0xDD,0xEE,0xFF,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,
          -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,
          -1,0xAA,0xBB,0xCC,0xDD,0xEE,0xFF
    };
    
    if (highNybble > 'f' || lowNybble > 'f')
        return -1;

    hnValue = hexValues[highNybble];
    lnValue = hexValues[lowNybble];
    if (hnValue == -1 || lnValue == -1)
        return -1;

    return ( hnValue & 0xF0 ) | ( lnValue & 0x0F );
}

+ (NSString *)decodeURLString:(NSString *)encodedString encoding:(CFStringEncoding)thisUrlEncoding;
{
    unsigned int length;
    unichar *characters, *inPtr;
    char *outPtr;
    unsigned int characterCount;
    NSString *decodedString;

    length = [encodedString length];
    characters = NSZoneMalloc(NULL, length * sizeof(unichar));
    // Note: we're using the characters buffer as both input and output:  since the input is unichar in the range 0 - 255 and the output is char (half the size, not counting decoded multiple bytes) we should never overrun ourselves.
    [encodedString getCharacters:characters];
    inPtr = characters;
    outPtr = (char *)characters;
    characterCount = length;
    while (characterCount--) {
	unichar character;

	character = *inPtr++;
	if (character == '%' && characterCount >= 2) {
	    character  = hexDigit(*inPtr++) << 4;
	    character |= hexDigit(*inPtr++);
	    characterCount -= 2;
	}
	*outPtr++ = character & 0xff;
    }
    *outPtr = '\0';
    if (thisUrlEncoding == kCFStringEncodingInvalidId)
        thisUrlEncoding = urlEncoding;
    decodedString = (NSString *)CFStringCreateWithCString(NULL, (char *)characters, thisUrlEncoding);
    NSZoneFree(NULL, characters);
    return [decodedString autorelease];
}

+ (NSString *)decodeURLString:(NSString *)encodedString;
{
    return [self decodeURLString:encodedString encoding:urlEncoding];
}

- (NSData *)dataUsingCFEncoding:(CFStringEncoding)anEncoding allowLossyConversion:(BOOL)lossy hexEscapes:(NSString *)escapePrefix;
{
    unsigned int stringLength;
    NSMutableData *buffer;
    NSRange remaining;
    
    stringLength = [self length];
    if (stringLength == 0)
        return [NSData data];

    buffer = nil;
    remaining = (NSRange){ location: 0, length: stringLength };
    while (remaining.length > 0) {
        NSRange prefix;
        CFRange escapelessRange;
        CFDataRef appendage;

        if (1) {
            prefix = [self rangeOfString:escapePrefix options:0 range:remaining];
        } else {
        continueAndSkipBogusEscapePrefix:
            prefix = [self rangeOfString:escapePrefix options:0 range:(NSRange){ remaining.location + 1, remaining.length - 1}];
        }
        
        escapelessRange.location = remaining.location;
        if (prefix.length == 0)
            escapelessRange.length = remaining.length;
        else
            escapelessRange.length = prefix.location - escapelessRange.location;
        remaining.length -= escapelessRange.length;
        remaining.location += escapelessRange.length;

        if (escapelessRange.length > 0) {
            appendage = OFCreateDataFromStringWithDeferredEncoding((CFStringRef)self, escapelessRange, anEncoding, lossy?'?':0);
            if (buffer == nil && remaining.length == 0)
                return [(NSData *)appendage autorelease];
            else if (buffer == nil)
                buffer = [[(NSData *)appendage mutableCopy] autorelease];
            else
                [buffer appendData:(NSData *)appendage];
            CFRelease(appendage);
        } else if (buffer == nil) {
            buffer = [NSMutableData data];
        }

        if (prefix.length > 0) {
            unichar highNybble, lowNybble;
            int byteValue;
            unsigned char buf[1];

            if (prefix.length+2 > remaining.length)
                goto continueAndSkipBogusEscapePrefix;

            highNybble = [self characterAtIndex: NSMaxRange(prefix)];
            lowNybble =  [self characterAtIndex: NSMaxRange(prefix)+1];
            byteValue = valueOfHexPair(highNybble, lowNybble);
            if (byteValue < 0)
                goto continueAndSkipBogusEscapePrefix;
            buf[0] = byteValue;
            [buffer appendBytes:buf length:1];

            remaining.location += prefix.length+2;
            remaining.length   -= prefix.length+2;
        }
    }

    return buffer;
}

static inline unichar hex(int i)
{
    static const char hexDigits[16] = {
        '0', '1', '2', '3', '4', '5', '6', '7',
        '8', '9', 'A', 'B', 'C', 'D', 'E', 'F'
    };
    
    return (unichar)hexDigits[i];
}

+ (NSString *)encodeURLString:(NSString *)unencodedString asQuery:(BOOL)asQuery leaveSlashes:(BOOL)leaveSlashes leaveColons:(BOOL)leaveColons;
{
    return [self encodeURLString:unencodedString encoding:urlEncoding asQuery:asQuery leaveSlashes:leaveSlashes leaveColons:leaveColons];
}

#define USE_GENERIC_QP_DECODER 0

#if USE_GENERIC_QP_DECODER

#define SIXTEEN_OF(x) x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x
#define ONE_HUNDRED_TWENTY_EIGHT_OF(x) SIXTEEN_OF(x),SIXTEEN_OF(x),SIXTEEN_OF(x),SIXTEEN_OF(x),SIXTEEN_OF(x),SIXTEEN_OF(x),SIXTEEN_OF(x),SIXTEEN_OF(x) 

#define TEMPLATE(S,C,V) {	\
    1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,       /* 0x control characters	*/ \
    1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,       /* 1x control characters	*/ \
    S,1,1,1,1,1,1,1,1,1,0,1,1,0,0,V,	   /* 2x   !"#$%&'()*+,-./	*/ \
    0,0,0,0,0,0,0,0,0,0,C,1,1,1,1,1,	   /* 3x  0123456789:;<=>?	*/ \
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,	   /* 4x  @ABCDEFGHIJKLMNO	*/ \
    0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,0,	   /* 5X  PQRSTUVWXYZ[\]^_	*/ \
    1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,	   /* 6x  `abcdefghijklmno	*/ \
    0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,	   /* 7X  pqrstuvwxyz{|}~  DEL	*/ \
    ONE_HUNDRED_TWENTY_EIGHT_OF(1)         /* 8x through FF       	*/ \
    }

static const OFQuotedPrintableMapping urlCodingVariants[8] = {
    { TEMPLATE(1,1,1), { '%', '+' } },
    { TEMPLATE(1,1,0), { '%', '+' } },
    { TEMPLATE(1,0,1), { '%', '+' } },
    { TEMPLATE(1,0,0), { '%', '+' } },
    { TEMPLATE(2,1,1), { '%', '+' } },
    { TEMPLATE(2,1,0), { '%', '+' } },
    { TEMPLATE(2,0,1), { '%', '+' } },
    { TEMPLATE(2,0,0), { '%', '+' } }
};

#endif  /* USE_GENERIC_QP_DECODER */

+ (NSString *)encodeURLString:(NSString *)unencodedString encoding:(CFStringEncoding)thisUrlEncoding asQuery:(BOOL)asQuery leaveSlashes:(BOOL)leaveSlashes leaveColons:(BOOL)leaveColons;
{
    NSString *escapedString;
    NSData *sourceData;
#if !USE_GENERIC_QP_DECODER
    unsigned const char *sourceBuffer;
    int sourceLength;
    int sourceIndex;
    unichar *destinationBuffer;
    int destinationBufferSize;
    int destinationIndex;
    static const BOOL isAcceptable[96] =
    //   0 1 2 3 4 5 6 7 8 9 A B C D E F
    {    0,0,0,0,0,0,0,0,0,0,1,0,0,1,1,0,	// 2x   !"#$%&'()*+,-./
	 1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,	// 3x  0123456789:;<=>?
	 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,	// 4x  @ABCDEFGHIJKLMNO
	 1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,1,	// 5X  PQRSTUVWXYZ[\]^_
	 0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,	// 6x  `abcdefghijklmno
	 1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0 };	// 7X  pqrstuvwxyz{|}~	DEL
#endif

    // TJW: This line here is why these are class methods, not instance methods.  If these were instance methods, we wouldn't do this check and would get a nil instead.  Maybe later this can be revisited.
    if (!unencodedString)
	return @"";

    // This is actually a pretty common occurrence
    if (![unencodedString rangeOfCharacterFromSet:EscapeCharacterSet].length)
        return unencodedString;

    if (thisUrlEncoding == kCFStringEncodingInvalidId)
        thisUrlEncoding = urlEncoding;
    sourceData = [unencodedString dataUsingCFEncoding:thisUrlEncoding allowLossyConversion:YES];
#if USE_GENERIC_QP_DECODER
    {
        int variantIndex = ( asQuery? 4 : 0 ) | ( leaveColons? 2 : 0 ) | ( leaveSlashes? 1 : 0 );
        escapedString = [sourceData quotedPrintableStringWithMapping:&(urlCodingVariants[variantIndex]) lengthHint:0];
    }
#else
    sourceBuffer = [sourceData bytes];
    sourceLength = [sourceData length];
    
    destinationBufferSize = sourceLength + (sourceLength >> 2) + 12;
    destinationBuffer = NSZoneMalloc(NULL, (destinationBufferSize) * sizeof(unichar));
    destinationIndex = 0;
    
    for (sourceIndex = 0; sourceIndex < sourceLength; sourceIndex++) {
	unsigned char ch;
	
	ch = sourceBuffer[sourceIndex];
	
	if (destinationIndex >= destinationBufferSize - 3) {
	    destinationBufferSize += destinationBufferSize >> 2;
	    destinationBuffer = NSZoneRealloc(NULL, destinationBuffer, (destinationBufferSize) * sizeof(unichar));
	}
	
        if (ch >= 32 && ch <= 127 && isAcceptable[ch - 32]) {
	    destinationBuffer[destinationIndex++] = ch;
	} else if (asQuery && ch == ' ') {
	    destinationBuffer[destinationIndex++] = '+';
	} else if (leaveSlashes && ch == '/') {
	    destinationBuffer[destinationIndex++] = '/';
	} else if (leaveColons && ch == ':') {
	    destinationBuffer[destinationIndex++] = ':';
	} else {
	    destinationBuffer[destinationIndex++] = '%';
	    destinationBuffer[destinationIndex++] = hex((ch & 0xF0) >> 4);
	    destinationBuffer[destinationIndex++] = hex(ch & 0x0F);
	}
    }
    
    escapedString = [[[NSString alloc] initWithCharactersNoCopy:destinationBuffer length:destinationIndex freeWhenDone:YES] autorelease];
#endif
    
    return escapedString;
}

- (NSString *)fullyEncodeAsIURI;
{
    NSRange escapeMeRange;
    NSData *utf8BytesData;
    NSString *resultString;
    const unsigned char *sourceBuffer;
    unsigned char *destinationBuffer;
    int destinationBufferUsed, destinationBufferSize;
    int sourceBufferIndex, sourceBufferSize;
    static const BOOL isSafe[96] =
    //   0 1 2 3 4 5 6 7 8 9 A B C D E F               0123456789ABCDEF
    {    0,1,0,0,1,1,1,1,1,1,1,1,1,1,1,1,	// 2x   !"#$%&'()*+,-./
         1,1,1,1,1,1,1,1,1,1,1,1,0,1,0,1,	// 3x  0123456789:;<=>?
         1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,	// 4x  @ABCDEFGHIJKLMNO
         1,1,1,1,1,1,1,1,1,1,1,0,1,0,1,1,	// 5X  PQRSTUVWXYZ[\]^_
         0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,	// 6x  `abcdefghijklmno
         1,1,1,1,1,1,1,1,1,1,1,0,0,0,1,0 };	// 7X  pqrstuvwxyz{|}~	DEL
    // the above is approximately the set of characters that may appear in a URI according to RFC2396.  Note that it's a bit different from isAcceptable[]; it has a different purpose.
    
    // NB/TODO: RFC2396 requires us to escape backslashes and carets, which we don't do because that prevents us from interoperating with some broken Microsoft servers. 
    
    escapeMeRange = [self rangeOfCharacterFromSet:EscapeCharacterSet];
    if (escapeMeRange.length == 0) {
        return [[self copy] autorelease];
    }
    
    utf8BytesData = [self dataUsingCFEncoding:kCFStringEncodingUTF8 allowLossyConversion:NO];
    sourceBufferSize = [utf8BytesData length];
    sourceBuffer = [utf8BytesData bytes];

    destinationBufferSize = sourceBufferSize;
    if (destinationBufferSize < 20)
        destinationBufferSize *= 3;
    else
        destinationBufferSize += ( destinationBufferSize >> 1 );
    
    destinationBuffer = NSZoneMalloc(NULL, destinationBufferSize);
    destinationBufferUsed = 0;
    
    for (sourceBufferIndex = 0; sourceBufferIndex < sourceBufferSize; sourceBufferIndex++) {
        unsigned char ch = sourceBuffer[sourceBufferIndex];
        
        // Headroom: we may insert up to three bytes into destinationBuffer.
        if (destinationBufferUsed + 3 >= destinationBufferSize) {
            int newSize = destinationBufferSize + ( destinationBufferSize >> 1 );
            destinationBuffer = NSZoneRealloc(NULL, destinationBuffer, newSize);
            destinationBufferSize = newSize;
        }
        
        if (ch >= 32 && !(ch & 0x80) && isSafe[ch - 32]) {
            destinationBuffer[destinationBufferUsed++] = ch;
        } else {
            destinationBuffer[destinationBufferUsed++] = '%';
            destinationBuffer[destinationBufferUsed++] = hex((ch & 0xF0) >> 4);
            destinationBuffer[destinationBufferUsed++] = hex( ch & 0x0F      );
        }
    }
    
    resultString = (NSString *)CFStringCreateWithBytes(kCFAllocatorDefault, destinationBuffer, destinationBufferUsed, kCFStringEncodingASCII, FALSE);
    NSZoneFree(NULL, destinationBuffer);
    
    return [resultString autorelease];
}
        

- (NSString *)htmlString;
{
    unichar *ptr, *begin, *end;
    NSMutableString *result;
    NSString *string;
    int length;
    
#define APPEND_PREVIOUS() \
    string = [[NSString alloc] initWithCharacters:begin length:(ptr - begin)]; \
    [result appendString:string]; \
    [string release]; \
    begin = ptr + 1;
    
    length = [self length];
    ptr = alloca(length * sizeof(unichar));
    end = ptr + length;
    [self getCharacters:ptr];
    result = [NSMutableString stringWithCapacity:length];
    
    begin = ptr;
    while (ptr < end) {
        if (*ptr > 127) {
            APPEND_PREVIOUS();
            [result appendFormat:@"&#%d;", (int)*ptr];
        } else if (*ptr == '&') {
            APPEND_PREVIOUS();
            [result appendString:@"&amp;"];
        } else if (*ptr == '\"') {
            APPEND_PREVIOUS();
            [result appendString:@"&quot;"];
        } else if (*ptr == '<') {
             APPEND_PREVIOUS();
            [result appendString:@"&lt;"];
        } else if (*ptr == '>') {
            APPEND_PREVIOUS();
            [result appendString:@"&gt;"];
        } else if (*ptr == '\n') {
            APPEND_PREVIOUS();
            [result appendString:@"<br/>"];
        }
        ptr++;
    }
    APPEND_PREVIOUS();
    return result;
}

// Regular expression encoding

- (NSString *)regularExpressionForLiteralString;
{
    OFStringScanner *scanner;
    NSMutableString *result;
    static OFCharacterSet *regularExpressionLiteralDelimiterSet = nil;
    
    if (regularExpressionLiteralDelimiterSet == nil)
        regularExpressionLiteralDelimiterSet = [[OFCharacterSet alloc] initWithString:@"^$.[()|\\?*+"];

    result = [NSMutableString stringWithCapacity:[self length]];
    scanner = [[OFStringScanner alloc] initWithString:self];
    while (scannerHasData(scanner)) {
        unichar character;
        NSString *nextLiteralFragment;

        character = scannerPeekCharacter(scanner);
        if (OFCharacterSetHasMember(regularExpressionLiteralDelimiterSet, character)) {
            [result appendString:@"\\"];
            [result appendString:[NSString stringWithCharacter:character]];
            scannerSkipPeekedCharacter(scanner);
        } else {
            nextLiteralFragment = [scanner readFullTokenWithDelimiterOFCharacterSet:regularExpressionLiteralDelimiterSet];
            [result appendString:nextLiteralFragment];
        }
    }
    [scanner release];
    return result;
}

// Encoding mail headers

- (NSString *)asRFC822Word
{
    if ([self length] > 0 &&
        [self rangeOfCharacterFromSet:nonAtomChars].length == 0 &&
        !([self hasPrefix:@"=?"] && [self hasSuffix:@"?="])) {
        /* We're an atom. */
        return [[self copy] autorelease];
    }

    /* The nonNonCTLChars set has a wacky name, but what the heck. It contains all the characters that we are not willing to represent in a quoted-string. Technically, we're allowed to have qtext, which is "any CHAR excepting <">, "\" & CR, and including linear-white-space" (RFC822 3.3); CHAR means characters 0 through 127 (inclusive), and so a qtext may contain arbitrary ASCII control characters. But to be on the safe side, we don't include those. */
    /* TODO: Consider adding a few specific control characters, perhaps HTAB */

    if ([self rangeOfCharacterFromSet:nonNonCTLChars].length == 0) {
        /* We don't contain any characters that aren't "nonCTLChars", so we can be represented as a quoted-string. */
        NSMutableString *buffer = [self mutableCopy];
        NSString *result;
        unsigned int chIndex = [buffer length];

        while(chIndex > 0) {
            unichar ch = [buffer characterAtIndex:(-- chIndex)];
            OBASSERT( !( ch < 32 || ch >= 127 ) ); // guaranteed by definition of nonNonCTLChars
            if (ch == '"' || ch == '\\' /* || ch < 32 || ch >= 127 */) {
                [buffer replaceCharactersInRange:(NSRange){chIndex, 0} withString:@"\\"];
            }
        }

        [buffer replaceCharactersInRange:(NSRange){0, 0} withString:@"\""];
        [buffer appendString:@"\""];

        result = [[buffer copy] autorelease];
        [buffer release];

        return result;
    }

    /* Otherwise, we cannot be represented as an RFC822 word (atom or quoted-string). If appropriate, the caller can use the RFC2047 encoded-word format. */
    return nil;
}

/* Preferred encodings as alluded in RFC2047 */
static const CFStringEncoding preferredEncodings[] = {
    kCFStringEncodingISOLatin1,
    kCFStringEncodingISOLatin2,
    kCFStringEncodingISOLatin3,
    kCFStringEncodingISOLatin4,
    kCFStringEncodingISOLatinCyrillic,
    kCFStringEncodingISOLatinArabic,
    kCFStringEncodingISOLatinGreek,
    kCFStringEncodingISOLatinHebrew,
    kCFStringEncodingISOLatin5,
    kCFStringEncodingISOLatin6,
    kCFStringEncodingISOLatinThai,
    kCFStringEncodingISOLatin7,
    kCFStringEncodingISOLatin8,
    kCFStringEncodingISOLatin9,
    kCFStringEncodingInvalidId /* sentinel */
};

/* Some encodings we like, which we try out if preferredEncodings fails */
static const CFStringEncoding desirableEncodings[] = {
    kCFStringEncodingUTF8,
    kCFStringEncodingUnicode,
    kCFStringEncodingHZ_GB_2312,
    /* TODO: Determine preferred encoding for Japanese mail? */
    kCFStringEncodingInvalidId /* sentinel */
};


/* Characters which do not need to be quoted in an RFC2047 quoted-printable-encoded word.
   Note that 0x20 is treated specially by the routine that uses this bitmap. */
static const char qpNonSpecials[128] = {
    0, 0, 0, 0, 0, 0, 0, 0,   //  
    0, 0, 0, 0, 0, 0, 0, 0,   //  
    0, 0, 0, 0, 0, 0, 0, 0,   //  
    0, 0, 0, 0, 0, 0, 0, 0,   //  
    1, 1, 0, 0, 0, 0, 0, 0,   //  SP and !
    0, 0, 1, 1, 0, 1, 0, 1,   //    *+ - /
    1, 1, 1, 1, 1, 1, 1, 1,   //  01234567
    1, 1, 0, 0, 0, 0, 0, 0,   //  89
    0, 1, 1, 1, 1, 1, 1, 1,   //   ABCDEFG
    1, 1, 1, 1, 1, 1, 1, 1,   //  HIJKLMNO
    1, 1, 1, 1, 1, 1, 1, 1,   //  PQRSTUVW
    1, 1, 1, 0, 0, 0, 0, 0,   //  XYZ
    0, 1, 1, 1, 1, 1, 1, 1,   //   abcdefg
    1, 1, 1, 1, 1, 1, 1, 1,   //  hijklmno
    1, 1, 1, 1, 1, 1, 1, 1,   //  pqrstuvw
    1, 1, 1, 0, 0, 0, 0, 0    //  xyz
};


/* TODO: RFC2047 requires us to break up encoded-words so that each one is no longer than 75 characters. We don't do that, which means it's possible for us to produce non-conforming tokens if called on a long string. */
- (NSString *)asRFC2047EncodedWord
{
    CFStringEncoding fastestEncoding, bestEncoding;
    int encodingIndex, byteIndex, byteCount, qpSize, b64Size;
    CFStringRef cfSelf = (CFStringRef)self;
    CFDataRef convertedBytes;
    CFStringRef charsetName;
    const UInt8 *bytePtr;
    NSString *encodedWord;

    bestEncoding = kCFStringEncodingInvalidId;
    convertedBytes = NULL;

    fastestEncoding = CFStringGetFastestEncoding(cfSelf);
    for(encodingIndex = 0; preferredEncodings[encodingIndex] != kCFStringEncodingInvalidId; encodingIndex ++) {
        if (fastestEncoding == preferredEncodings[encodingIndex]) {
            bestEncoding = fastestEncoding;
            break;
        }
    }

    if (bestEncoding == kCFStringEncodingInvalidId) {
        // The fastest encoding is not in the preferred encodings list. Check whether any of the preferred encodings are possible at all.

        for(encodingIndex = 0; preferredEncodings[encodingIndex] != kCFStringEncodingInvalidId; encodingIndex ++) {
            convertedBytes = CFStringCreateExternalRepresentation(kCFAllocatorDefault, cfSelf, preferredEncodings[encodingIndex], 0);
            if (convertedBytes != NULL) {
                bestEncoding = preferredEncodings[encodingIndex];
                break;
            }
        }
    }

    if (bestEncoding == kCFStringEncodingInvalidId) {
        // We can't use any of the preferred encodings, so use the smallest one.
        bestEncoding = CFStringGetSmallestEncoding(cfSelf);
    }

    if (convertedBytes == NULL)
        convertedBytes = CFStringCreateExternalRepresentation(kCFAllocatorDefault, cfSelf, bestEncoding, 0);

    // CFStringGetSmallestEncoding() doesn't always return the smallest encoding, so try out a few others on our own
    {
        CFStringEncoding betterEncoding = kCFStringEncodingInvalidId;
        CFDataRef betterBytes = NULL;
        
        for(encodingIndex = 0; desirableEncodings[encodingIndex] != kCFStringEncodingInvalidId; encodingIndex ++) {
            CFDataRef alternateBytes;
            if (desirableEncodings[encodingIndex] == bestEncoding)
                continue;
            alternateBytes = CFStringCreateExternalRepresentation(kCFAllocatorDefault, cfSelf, desirableEncodings[encodingIndex], 0);
            if (alternateBytes != NULL) {
                if (betterBytes == NULL) {
                    betterEncoding = desirableEncodings[encodingIndex];
                    betterBytes = alternateBytes;
                } else if(CFDataGetLength(betterBytes) > CFDataGetLength(alternateBytes)) {
                    CFRelease(betterBytes);
                    betterEncoding = desirableEncodings[encodingIndex];
                    betterBytes = alternateBytes;
                } else {
                    CFRelease(alternateBytes);
                }
            }
        }

        if (betterBytes != NULL) {
            if (CFDataGetLength(betterBytes) < CFDataGetLength(convertedBytes)) {
                CFRelease(convertedBytes);
                convertedBytes = betterBytes;
                bestEncoding = betterEncoding;
            } else {
                CFRelease(betterBytes);
            }
        }
    }

    OBASSERT(bestEncoding != kCFStringEncodingInvalidId);
    OBASSERT(convertedBytes != NULL);

    charsetName = CFStringConvertEncodingToIANACharSetName(bestEncoding);

    byteCount = CFDataGetLength(convertedBytes);
    bytePtr = CFDataGetBytePtr(convertedBytes);

    // Now decide whether to use quoted-printable or base64 encoding. Again, we choose the smallest size.
    qpSize = 0;
    for(byteIndex = 0; byteIndex < byteCount; byteIndex ++) {
        if (bytePtr[byteIndex] < 128 && qpNonSpecials[bytePtr[byteIndex]])
            qpSize += 1;
        else
            qpSize += 3;
    }

    b64Size = (( byteCount + 2 ) / 3) * 4;

    if (b64Size < qpSize) {
        // Base64 is smallest. Use it.
        encodedWord = [NSString stringWithFormat:@"=?%@?B?%@?=", charsetName, [(NSData *)convertedBytes base64String]];
    } else {
        NSMutableString *encodedContent;
        // Quoted-Printable is smallest (or, at least, not larger than Base64).
        encodedContent = [[NSMutableString alloc] initWithCapacity:qpSize];
        for(byteIndex = 0; byteIndex < byteCount; byteIndex ++) {
            UInt8 byte = bytePtr[byteIndex];
            if (byte < 128 && qpNonSpecials[byte]) {
                if (byte == 0x20) /* RFC2047 4.2(2) */
                    byte = 0x5F;
                [encodedContent appendCharacter:byte];
            } else {
                unichar highNybble, lowNybble;

                highNybble = hex((byte & 0xF0) >> 4);
                lowNybble = hex(byte & 0x0F);
                [encodedContent appendCharacter:'='];
                [encodedContent appendCharacter:highNybble];
                [encodedContent appendCharacter:lowNybble];
            }
        }
        encodedWord = [NSString stringWithFormat:@"=?%@?Q?%@?=", charsetName, encodedContent];
        [encodedContent release];
    }

    CFRelease(convertedBytes);

    return encodedWord;
}

- (NSString *)asRFC2047Phrase
{
    NSString *result;

    if ([self rangeOfCharacterFromSet:nonAtomCharsExceptLWSP].length == 0) {
        /* We look like a sequence of atoms. However, we need to check for strings like "foo =?bl?e?gga?= bar", which have special semantics described in RFC2047. (This test is a little over-cautious but that's OK.) */

        if (!([self rangeOfString:@"=?"].length > 0 &&
              [self rangeOfString:@"?="].length > 0))
            return self;
    }

    /* -asRFC822Word will produce a single double-quoted string for all our text; e.g. if called with [John Q. Public] we'll return ["John Q. Public"] rather than [John "Q." Public]. */
    result = [self asRFC822Word];

    /* If we can't be represented as an RFC822 word, use the extended syntax from RFC2047. */
    if (result == nil)
        result = [self asRFC2047EncodedWord];

    return result;
}

@end
