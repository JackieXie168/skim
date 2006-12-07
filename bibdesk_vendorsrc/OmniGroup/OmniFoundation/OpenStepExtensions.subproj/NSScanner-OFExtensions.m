// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/NSScanner-OFExtensions.h>
#import <OmniFoundation/NSString-OFExtensions.h>
#import <OmniFoundation/NSMutableString-OFExtensions.h>

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSScanner-OFExtensions.m 66170 2005-07-28 17:40:10Z kc $")

@implementation NSScanner (OFExtensions)

- (BOOL)scanStringOfLength:(unsigned int)length intoString:(NSString **)result;
{
    NSString                   *string;
    unsigned int                scanLocation;

    string = [self string];
    scanLocation = [self scanLocation];
    if (scanLocation + length > [string length])
	return NO;
    if (result)
	*result = [string substringWithRange: NSMakeRange(scanLocation, length)];
    [self setScanLocation:scanLocation + length];
    return YES;
}

- (BOOL)scanStringWithEscape:(NSString *)escape terminator:(NSString *)quoteMark intoString:(NSString **)output
{
    NSCharacterSet *stopSet;
    NSMutableString *prefixes;
    NSString *value;
    NSMutableString *buffer;
    NSCharacterSet *oldCharactersToBeSkipped;
#if defined(OMNI_ASSERTIONS_ON)
    unsigned beganLocation = [self scanLocation];
#endif

    OBPRECONDITION(![NSString isEmptyString:escape]);
    OBPRECONDITION(![NSString isEmptyString:quoteMark]);

    if ([self isAtEnd])
        return NO;

    prefixes = [[NSMutableString alloc] initWithCapacity:2];
    [prefixes appendCharacter:[escape characterAtIndex:0]];
    [prefixes appendCharacter:[quoteMark characterAtIndex:0]];
    stopSet = [NSCharacterSet characterSetWithCharactersInString:prefixes];
    [prefixes release];

    buffer = nil;
    value = nil;

    oldCharactersToBeSkipped = [self charactersToBeSkipped];
    [self setCharactersToBeSkipped:nil];

    do {
        NSString *fragment;

        if ([self scanUpToCharactersFromSet:stopSet intoString:&fragment]) {
            if (value && !buffer) {
                buffer = [value mutableCopy];
                value = nil;
            }
            if (buffer) {
                OBASSERT(value == nil);
                [buffer appendString:fragment];
            } else {
                value = fragment;
            }
        }

        if ([self scanString:quoteMark intoString:NULL])
            break;

        /* Two cases: either we scan the escape sequence successfully, and then we pull one (uninterpreted) character out of the string into the buffer; or we don't scan the escape sequence successfully (i.e. false alarm from the stopSet), in which we pull one uninterpreted character out of the string into the buffer. */

        if (!buffer) {
            if (value) {
                buffer = [value mutableCopy];
                value = nil;
            } else
                buffer = [[NSMutableString alloc] init];
        }

        [self scanString:escape intoString:NULL];
        if ([self scanStringOfLength:1 intoString:&fragment])
            [buffer appendString:fragment];
    } while (![self isAtEnd]);

    [self setCharactersToBeSkipped:oldCharactersToBeSkipped];

    if (buffer) {
        if (output)
            *output = [[buffer copy] autorelease];
        [buffer release];
        return YES;
    }
    if (value) {
        if (output)
            *output = value;
        return YES;
    }

    // Edge case --- we scanned an escape sequence and then hit EOF immediately afterwards. Still, we *did* advance our scan location, so we should return YES.
    OBASSERT([self scanLocation] != beganLocation);
    OBASSERT([self isAtEnd]);
    if (output)
        *output = @"";
    return YES;
}

@end
