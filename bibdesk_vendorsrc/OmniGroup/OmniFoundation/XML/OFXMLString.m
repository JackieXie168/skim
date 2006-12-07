// Copyright 2003-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/OFXMLString.h>

#import <Foundation/Foundation.h>
#import <OmniBase/rcsid.h>

#import <OmniFoundation/OFStringDecoder.h>
#import <OmniFoundation/NSString-OFExtensions.h>

#import <OmniFoundation/OFXMLDocument.h>
#import <OmniFoundation/OFXMLElement.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/XML/OFXMLString.m,v 1.8 2004/02/10 04:07:49 kc Exp $");

@interface OFXMLString (Private)
@end

@implementation OFXMLString

- initWithString: (NSString *) unquotedString quotingMask: (unsigned int) quotingMask newlineReplacment: (NSString *) newlineReplacment;
{
    _unquotedString     = [unquotedString copy];
    _quotingMask        = quotingMask;
    _newlineReplacement = [newlineReplacment copy];
    return self;
}

- (void) dealloc;
{
    [_unquotedString release];
    [_newlineReplacement release];
}

- (NSString *) unquotedString;
{
    return _unquotedString;
}

//
// Writing support called from OFXMLDocument
//
- (CFXMLTreeRef) createTreeWithParentWhiteSpaceBehavior: (OFXMLWhitespaceBehaviorType) parentBehavior document: (OFXMLDocument *) doc level: (unsigned int) level;
{
    return [OFXMLElement createTextTree: _unquotedString quotingMask: _quotingMask newlineReplacement: _newlineReplacement stringEncoding: [doc stringEncoding]];
}

@end

#define APPEND_PREVIOUS() \
string = [[NSString alloc] initWithCharacters:begin length:(ptr - begin)]; \
[result appendString:string]; \
[string release]; \
begin = ptr + 1;

// Replace characters with basic entities
static NSString *_OFXMLCreateStringWithEntityReferences(NSString *sourceString, unsigned int entityMask, NSString *optionalNewlineString)
{
    unichar *ptr, *begin, *end;
    NSMutableString *result;
    NSString *string;
    int length;

    length = [sourceString length];
    ptr = alloca(length * sizeof(unichar));
    end = ptr + length;
    [sourceString getCharacters:ptr];
    result = [[NSMutableString alloc] initWithCapacity:length];

    begin = ptr;
    while (ptr < end) {
        if (*ptr == '&') {
            APPEND_PREVIOUS();
            [result appendString:@"&amp;"];
        } else if (*ptr == '<') {
            APPEND_PREVIOUS();
            [result appendString:@"&lt;"];
        } else if (*ptr == '\"' && (entityMask & OFXMLQuotEntityMask) == OFXMLQuotEntityMask) {
            APPEND_PREVIOUS();
            [result appendString:@"&quot;"];
        } else if (*ptr == '\'' && (entityMask & OFXMLAposEntityMask) == OFXMLAposEntityMask) {
            APPEND_PREVIOUS();
            [result appendString:@"&apos;"];
        } else if (*ptr == '\'' && (entityMask & OFXMLAposAlternateEntityMask) == OFXMLAposAlternateEntityMask) {
            APPEND_PREVIOUS();
            [result appendString:@"&#39;"];
        } else if (*ptr == '>' && (entityMask & OFXMLGtEntityMask) == OFXMLGtEntityMask) {
            APPEND_PREVIOUS();
            [result appendString:@"&gt;"];
        } else if (*ptr == '\n' && (entityMask & OFXMLNewlineEntityMask) == OFXMLNewlineEntityMask) {
            APPEND_PREVIOUS();
            if (optionalNewlineString != nil)
                [result appendString:optionalNewlineString];
        }
        ptr++;
    }

    APPEND_PREVIOUS();

    return result;
}

// Replace characters not representable in string encoding with numbered character references
static NSString *_OFXMLCreateStringInCFEncoding(NSString *sourceString, CFStringEncoding anEncoding)
{
    NSMutableString *resultString;
    unsigned int thisBad;
    NSRange scanningRange;
    NSRange aRange, composedRange;
    unichar *composedCharacter;
    unsigned int index;

    resultString = [[NSMutableString alloc] init];

    scanningRange.location = 0;
    scanningRange.length = [sourceString length];
    while (scanningRange.length > 0) {
        thisBad = [sourceString indexOfCharacterNotRepresentableInCFEncoding:anEncoding range:scanningRange];
        if (thisBad == NSNotFound) {
            if (scanningRange.location == 0) {
                [resultString release];
                return [sourceString retain];  // Shortcut for common case
            }
            [resultString appendString:[sourceString substringWithRange:scanningRange]];
            break;
        }
        aRange.location = scanningRange.location;
        aRange.length = thisBad - aRange.location;
        if (aRange.length > 0)
            [resultString appendString:[sourceString substringWithRange:aRange]];

        composedRange = [sourceString rangeOfComposedCharacterSequenceAtIndex:thisBad];
        composedCharacter = malloc(composedRange.length * sizeof(*composedCharacter));
        [sourceString getCharacters:composedCharacter range:composedRange];
        for (index = 0; index < composedRange.length; index++) {
            UnicodeScalarValue ch;  // this is a full 32-bit Unicode value

            if (OFCharacterIsSurrogate(composedCharacter[index]) == OFIsSurrogate_HighSurrogate &&
                (index + 1 < composedRange.length) &&
                OFCharacterIsSurrogate(composedCharacter[index+1]) == OFIsSurrogate_LowSurrogate) {
                ch = OFCharacterFromSurrogatePair(composedCharacter[index], composedCharacter[index+1]);
                index ++;
            } else {
                ch = composedCharacter[index];
            }

            [resultString appendFormat:@"&#%u;", ch];
        }
        free(composedCharacter);
        composedCharacter = NULL;
        scanningRange.location = NSMaxRange(composedRange);
        scanningRange.length -= aRange.length + composedRange.length;
    }

    // (this point is not reached if no changes are necessary to the source string)
    return resultString;
}

// 1. Replace characters with basic entities
// 2. Replace characters not representable in string encoding with numbered character references
NSString *OFXMLCreateStringWithEntityReferencesInCFEncoding(NSString *sourceString, unsigned int entityMask, NSString *optionalNewlineString, CFStringEncoding anEncoding)
{
    NSString *str;

    if (sourceString == nil)
        return nil;

    str = _OFXMLCreateStringWithEntityReferences(sourceString, entityMask, optionalNewlineString);
    if (str != nil)
        str = _OFXMLCreateStringInCFEncoding(str, anEncoding);

    return str;
}

// TODO: This is nowhere near as efficient as it could be.  In particular, it shouldn't use NSScanner at all, much less create one for an input w/o any entity references.
NSString *OFXMLCreateParsedEntityString(NSString *sourceString)
{
    NSMutableString *result;
    NSScanner *scanner;
    NSString *scannedString;
    NSCharacterSet *letterCharacterSet;

    result = [[NSMutableString alloc] init];
    scanner = [[NSScanner alloc] initWithString:sourceString];
    [scanner setCharactersToBeSkipped:nil];

    letterCharacterSet = [NSCharacterSet letterCharacterSet];

    while ([scanner isAtEnd] == NO) {
        //NSLog(@"Start of loop, scan location: %d", [scanner scanLocation]);
        //NSLog(@"remaining string: %@", [sourceString substringFromIndex:[scanner scanLocation]]);
        if ([scanner scanUpToString:@"&" intoString:&scannedString] == YES)
            [result appendString:scannedString];

        if ([scanner scanString:@"&" intoString:NULL] == YES) {
            NSString *entityName, *entityValue;

            entityName = nil;
            if ([scanner scanUpToString:@";" intoString:&entityName] == YES) {
                [scanner scanString:@";" intoString:NULL];

                entityValue = OFStringForEntityName(entityName);
                if (entityValue == nil) {
                    // OFStringForEntityName() will already have logged a warning
                    entityValue = [NSString stringWithFormat:@"&%@;", entityName];
                }

                [result appendString:entityValue];
            } else {
                NSLog(@"Misformed entity reference at location %d (not terminated)", [scanner scanLocation]);
                [result appendString:@"&"];
            }
        } else {
            // May just be at end of string.
        }
    }

    [scanner release];

    return result;
}

NSString *OFStringForEntityName(NSString *entityName)
{
    if ([entityName isEqual:@"lt"] == YES) {
        return @"<";
    } else if ([entityName isEqual:@"amp"] == YES) {
        return @"&";
    } else if ([entityName isEqual:@"gt"] == YES) {
        return @">";
    } else if ([entityName isEqual:@"quot"] == YES) {
        return @"\"";
    } else if ([entityName isEqual:@"apos"] == YES) {
        return @"'";
    } else if ([entityName hasPrefix:@"#x"] == YES &&
               [entityName length] > 2) {
        UnicodeScalarValue ch;

        ch = [[entityName substringFromIndex:2] hexValue];
        return [NSString stringWithCharacter:ch];
    } else if ([entityName hasPrefix:@"#"] == YES &&
               [entityName length] > 1) {
        // Avoid 'unichar' here because it is only 16 bits wide and will truncate Supplementary Plane characters
        UnicodeScalarValue ch;

        ch = [[entityName substringFromIndex:1] intValue];
        return [NSString stringWithCharacter:ch];
    }

    NSLog(@"Warning: Unknown entity: %@", entityName);

    return nil;
}

