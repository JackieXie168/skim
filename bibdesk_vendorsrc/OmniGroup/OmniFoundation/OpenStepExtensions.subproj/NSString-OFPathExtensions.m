// Copyright 1999-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import <OmniFoundation/NSString-OFPathExtensions.h>

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

#import <OmniFoundation/NSString-OFExtensions.h>
#import <OmniFoundation/OFCharacterSet.h>


RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSString-OFPathExtensions.m,v 1.9 2003/01/15 22:52:01 kc Exp $")

static OFCharacterSet *fileSystemSafeOFCharacterSet   = NULL;
static unsigned char fileSystemSafeQuoteCharacter = (char)0;
static const unsigned char hexEncoding[] = "0123456789abcdef";
static unsigned char hexDecoding[128];

static inline BOOL isHexChar(unsigned char c)
{
    return ((c >= '0' && c <= '9') ||
            (c >= 'a' && c <= 'f') ||
            (c >= 'A' && c <= 'F'));
}

/*"
This category provides a way to safely encode Unicode path components on any known supported filesystem.  The names don't look like Unicode in the OS-supplied file browser, of course, but this is intended for situations where the files aren't typically viewed directly by users, but are viewed through some cutom application that can decode the names before displaying them.

 DO NOT change the algorithm here without considering the effect on decoding existing filenames that were encoded with previous versions.  Otherwise, you may be invalidating a huge filesystem of encoding filenames.
"*/
@implementation NSString (OFPathExtensions)

+ (void) didLoad;
{
    // All filsystems allow alpha numeric and space.
    fileSystemSafeOFCharacterSet = [[OFCharacterSet alloc] initWithString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 "];

    // Non-lossy ASCII encoding uses '\' as the quote character, but that is
    // not really safe on Windows.
    fileSystemSafeQuoteCharacter = '_';

    memset(hexDecoding, 0, sizeof(hexDecoding));
    hexDecoding['0'] = 0;
    hexDecoding['1'] = 1;
    hexDecoding['2'] = 2;
    hexDecoding['3'] = 3;
    hexDecoding['4'] = 4;
    hexDecoding['5'] = 5;
    hexDecoding['6'] = 6;
    hexDecoding['7'] = 7;
    hexDecoding['8'] = 8;
    hexDecoding['9'] = 9;
    hexDecoding['a'] = 0xa;
    hexDecoding['b'] = 0xb;
    hexDecoding['c'] = 0xc;
    hexDecoding['d'] = 0xd;
    hexDecoding['e'] = 0xe;
    hexDecoding['f'] = 0xf;
    hexDecoding['A'] = 0xA;
    hexDecoding['B'] = 0xB;
    hexDecoding['C'] = 0xC;
    hexDecoding['D'] = 0xD;
    hexDecoding['E'] = 0xE;
    hexDecoding['F'] = 0xF;
}

/*"
When called on a path component, this returns a new path component that can be safely stored in any relevant filesystem.  This eliminates special chararacters by encoding them in a recoverable fashion.  This does NOT eliminate case issues.  That is, it is still not safe to store two files with differing cases.
"*/
- (NSString *) fileSystemSafeNonLossyPathComponent;
{
    
    NSZone        *zone;
    unsigned int   characterCount, characterIndex, conversionCount, convertedLength;
    unichar       *oldCharacters;
    unsigned char *newCharacters, *conversionPoint;

    characterCount = [self length];
    if (!characterCount)
        [NSException raise: NSInvalidArgumentException
                    format: @"A zero lenght string cannot be used as a path component."];
    
    zone = [self zone];
    oldCharacters = NSZoneMalloc(zone, sizeof(unichar) * characterCount);
    [self getCharacters: oldCharacters];

    // Count the number of characters that need conversion so we know how much
    // space to allocate (and so that we can bail w/o allocating more space
    // we if are safe already).
    conversionCount = 0;
    for (characterIndex = 0; characterIndex < characterCount; characterIndex++) {
        if (!OFCharacterSetHasMember(fileSystemSafeOFCharacterSet, oldCharacters[characterIndex]))
            conversionCount++;
    }

    if (!conversionCount) {
        // We are safe already
        NSZoneFree(zone, oldCharacters);
        return self;
    }
    
    // Allocate enough space for the unconverted characters, plus the space needed for the
    // converted characters.  Each converted character takes 5 bytes.  One for the quote
    // and four for the hex encoding of the unichar.
    convertedLength = (characterCount - conversionCount) + (conversionCount * 5);
    newCharacters = NSZoneMalloc(zone, convertedLength);

    // Convert the characters into the new buffer
    conversionPoint = newCharacters;
    for (characterIndex = 0; characterIndex < characterCount; characterIndex++) {
        unichar character;

        character = oldCharacters[characterIndex];
        if (OFCharacterSetHasMember(fileSystemSafeOFCharacterSet, character)) {
            *conversionPoint = (unsigned char)(character & 0x00ff);
            conversionPoint++;
        } else {
            // Need to encode the character
            *conversionPoint = fileSystemSafeQuoteCharacter;
            conversionPoint++;

            // Encode the character as a four digit hex string (big-endian)
            conversionPoint[0] = hexEncoding[(character & 0xf000) >> 12];
            conversionPoint[1] = hexEncoding[(character & 0x0f00) >>  8];
            conversionPoint[2] = hexEncoding[(character & 0x00f0) >>  4];
            conversionPoint[3] = hexEncoding[(character & 0x000f) >>  0];

            conversionPoint += 4;
        }
    }

    return [[[NSString allocWithZone: zone] initWithCStringNoCopy: newCharacters
                                                           length: convertedLength
                                                     freeWhenDone: YES] autorelease];
}

/*"
Returns the original string used to generate this string via -fileSystemSafeNonLossyPathComponent.
"*/
- (NSString *) decodedFileSystemSafeNonLossyPathComponent;
{
    NSZone        *zone;
    unsigned char *oldCharacters;
    unichar       *newCharacters, *conversionPoint;
    unsigned int   characterIndex, oldCharacterCount, newCharacterCount;
    unsigned int   encodedCharacterCount;
    

    oldCharacterCount = [self length];
    if (!oldCharacterCount)
        [NSException raise: NSInvalidArgumentException
                    format: @"A zero lenght string cannot be used as a path component."];

    zone = [self zone];
    oldCharacters = NSZoneMalloc(zone, oldCharacterCount + 1); // -- dunno if getCString: wants to write the null
    [self getCString: oldCharacters];

    // Count the number of quoted characters.  Since the quote character is
    // not one of the characters that is used when encoding a character
    // we don't have to skip the encoded characters (although we could).
    encodedCharacterCount = 0;
    for (characterIndex = 0; characterIndex < oldCharacterCount; characterIndex++) {
        if (oldCharacters[characterIndex] == fileSystemSafeQuoteCharacter) {
            // Make sure that this string is encoded validly...  the
            // next four characters must (a) exist, and (b), be valid hex characters
            if (oldCharacterCount - (characterIndex + 1) < 4) {
                [NSException raise: NSInvalidArgumentException
                            format: @"The string '%@' is not a validly coded safe non-lossy path component.", self];
            }

            if (!isHexChar(oldCharacters[characterIndex + 1]) ||
                !isHexChar(oldCharacters[characterIndex + 2]) ||
                !isHexChar(oldCharacters[characterIndex + 3]) ||
                !isHexChar(oldCharacters[characterIndex + 4])) {
                [NSException raise: NSInvalidArgumentException
                            format: @"The string '%@' is not a validly coded safe non-lossy path component.", self];
            }
                
            encodedCharacterCount++;
        }
    }

    if (!encodedCharacterCount) {
        // We don't have any encoded characters...
        NSZoneFree(zone, oldCharacters);
        return self;
    }

    // Allocate enough space for the new characters.  Each encoded character takes
    // 5 input characters and one output character.  That is, for each encoded
    // character, we need four fewer characters than we counted.
    newCharacterCount = oldCharacterCount - 4 * encodedCharacterCount;
    newCharacters = NSZoneMalloc(zone, sizeof(unichar) * newCharacterCount);

    conversionPoint = newCharacters;
    characterIndex = 0;
    while (characterIndex < oldCharacterCount) {
        unsigned char c;

        c = oldCharacters[characterIndex];
        if (c != fileSystemSafeQuoteCharacter) {
            *conversionPoint = (unichar)c;
            conversionPoint++;
            characterIndex++;
        } else {
            unichar decodedCharacter;

            // index 1-4 to skip the quote character...
            decodedCharacter  = hexDecoding[oldCharacters[characterIndex+1]] << 12;
            decodedCharacter |= hexDecoding[oldCharacters[characterIndex+2]] <<  8;
            decodedCharacter |= hexDecoding[oldCharacters[characterIndex+3]] <<  4;
            decodedCharacter |= hexDecoding[oldCharacters[characterIndex+4]] <<  0;

            *conversionPoint = decodedCharacter;
            conversionPoint++;
            characterIndex += 5;
        }
    }

    return [[[NSString allocWithZone: zone] initWithCharactersNoCopy: newCharacters
                                                              length: newCharacterCount
                                                        freeWhenDone: YES] autorelease];
}


/*" Reformats a path as 'lastComponent emdash stringByByRemovingLastPathComponent' "*/
- (NSString *) prettyPathString;
{
    NSString *last, *prefix;
    
    last = [self lastPathComponent];
    prefix = [self stringByDeletingLastPathComponent];
    
    if (![last length] || ![prefix length])
        // was a single component?
        return self;
    
    return [NSString stringWithFormat: @"%@ %@ %@", last, [NSString emdashString], prefix];
}

+ (NSString *)pathSeparator;
{
    return [NSOpenStepRootDirectory() substringToIndex:1];
}

+ (NSString *)commonRootPathOfFilename:(NSString *)filename andFilename:(NSString *)otherFilename;
{
    int minLength, i;
    NSArray *filenameArray, *otherArray;
    NSMutableArray *resultArray;

    filenameArray = [filename pathComponents];
    otherArray = [[otherFilename stringByStandardizingPath] pathComponents];
    minLength = MIN([filenameArray count], [otherArray count]);
    resultArray = [NSMutableArray arrayWithCapacity:minLength];

    for (i = 0; i < minLength; i++)
        if ([[filenameArray objectAtIndex:i] isEqualToString:[otherArray objectAtIndex:i]])
            [resultArray addObject:[filenameArray objectAtIndex:i]];
        
    if ([resultArray count] == 0)
        return nil;

    return [NSString pathWithComponents:resultArray];
}

- (NSString *)relativePathToFilename:(NSString *)otherFilename;
{
    NSString *commonRoot, *myUniquePart, *otherUniquePart;
    int numberOfStepsUp, i;
    NSMutableString *stepsUpString;

    commonRoot = [[NSString commonRootPathOfFilename:self andFilename:otherFilename] stringByAppendingString:[NSString pathSeparator]];
    if (commonRoot == nil)
        return otherFilename;
    
    myUniquePart = [[self stringByStandardizingPath] stringByRemovingPrefix:commonRoot];
    otherUniquePart = [[otherFilename stringByStandardizingPath] stringByRemovingPrefix:commonRoot];

    numberOfStepsUp = [[myUniquePart pathComponents] count];
    if (![self hasSuffix:[NSString pathSeparator]])
        numberOfStepsUp--; // Assume we're not a directory unless we end in /. May result in incorrect paths, but we can't do much about it.

    stepsUpString = [NSMutableString stringWithCapacity:(numberOfStepsUp * 3)];
    for (i = 0; i < numberOfStepsUp; i++) {
        [stepsUpString appendString:@".."];
        [stepsUpString appendString:[NSString pathSeparator]];
    }

    return [[stepsUpString stringByAppendingString:otherUniquePart] stringByStandardizingPath];
}


@end
