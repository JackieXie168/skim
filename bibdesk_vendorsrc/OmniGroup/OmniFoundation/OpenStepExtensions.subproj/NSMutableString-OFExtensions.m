// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/NSMutableString-OFExtensions.h>

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>
#import <OmniFoundation/OFStringScanner.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/SourceRelease_2005-10-03/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSMutableString-OFExtensions.m 68913 2005-10-03 19:36:19Z kc $")

@implementation NSMutableString (OFExtensions)

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

// This is similar to the above, but replaces contiguous sequences of characters from the pattern set with a single occurrence of the replacement string
- (void)collapseAllOccurrencesOfCharactersInSet:(NSCharacterSet *)set toString:(NSString *)replaceString;
{
    NSRange characterRange, searchRange, replaceRange;
    unsigned int replaceStringLength, selfLength;

    replaceStringLength = [replaceString length];
    selfLength = [self length];
    characterRange = [self rangeOfCharacterFromSet:set options:NSLiteralSearch range:NSMakeRange(0, selfLength)];
    while (characterRange.length > 0) {
        replaceRange = characterRange;
        searchRange.location = replaceRange.location + replaceRange.length;
        searchRange.length = selfLength - searchRange.location;
        for (;;) {
            characterRange = [self rangeOfCharacterFromSet:set options:NSLiteralSearch range:searchRange];
            if (characterRange.length == 0 ||
                characterRange.location != searchRange.location)
                break;
            replaceRange.length += characterRange.length;
            searchRange.length -= characterRange.length;
            searchRange.location += characterRange.length;
        }
        [self replaceCharactersInRange:replaceRange withString:replaceString];
        characterRange.location += replaceStringLength - replaceRange.length;
        selfLength += replaceStringLength - replaceRange.length;
        OBASSERT(selfLength == [self length]);
    }
}

- (BOOL)replaceAllOccurrencesOfString:(NSString *)oldString withString:(NSString *)newString;
{
    OFStringScanner *scanner;
    NSMutableString *replacementString = nil;
    NSRange partialStringRange;
    unsigned int oldStringLength = 0;
    unsigned int lastPosition = 0;
    BOOL foundOccurrences;
    
    scanner = [[OFStringScanner alloc] initWithString:self];

    while ([scanner scanUpToString:oldString]) {
        if (!replacementString) {
            oldStringLength = [oldString length];
            replacementString = [[NSMutableString alloc] init];
        }

        partialStringRange = NSMakeRange(lastPosition, [scanner scanLocation] - lastPosition);
        [replacementString appendString:[self substringWithRange:partialStringRange]];
        [replacementString appendString:newString];
        lastPosition += partialStringRange.length + oldStringLength;
        [scanner skipCharacters:oldStringLength];
    }

    if (replacementString) {
        partialStringRange = NSMakeRange(lastPosition, [scanner scanLocation] - lastPosition);
        [replacementString appendString:[self substringWithRange:partialStringRange]];
        [self setString:replacementString];
        [replacementString release];
        foundOccurrences = YES;
    } else
        foundOccurrences = NO;

    [scanner release];
    return foundOccurrences;
}

- (void)replaceAllLineEndingsWithString:(NSString *)newString;
{
    // It might be nice to make this more efficient by doing everything in one pass rather than three (but this was sure simpler to write!)
    [self replaceAllOccurrencesOfString:@"\r\n" withString:@"\n"];
    [self replaceAllOccurrencesOfString:@"\r" withString:@"\n"];
    if (![@"\n" isEqualToString:newString]) // Trivial optimization of a reasonably likely case
        [self replaceAllOccurrencesOfString:@"\n" withString:newString];
}

- (void)appendCharacter:(unichar)aCharacter;
{
    // There isn't a particularly efficient way to do this using the ObjC interface, so...
    const UniChar unicodeCharacters[1] = { aCharacter };
    
    CFStringAppendCharacters((CFMutableStringRef)self, unicodeCharacters, 1);
}

- (void)appendStrings: (NSString *)first, ...
{
    va_list argList;
    NSString *next;

    if (!first)
        return;

    [self appendString:first];

    va_start(argList, first);
    while ((next = va_arg(argList, NSString *)))
        [self appendString:next];
    va_end(argList);
}

- (void)removeSurroundingWhitespace;
{
    // ARM: original Omni implementation used @" \t\r\n" as charset, and had an off-by-one error in trimming @" string"
    CFStringTrimWhitespace((CFMutableStringRef)self);
}

@end
