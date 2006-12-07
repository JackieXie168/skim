// Copyright 1998-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/OFZipCodeFormatter.h>

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

#import "NSObject-OFExtensions.h"

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/Formatters.subproj/OFZipCodeFormatter.m 68913 2005-10-03 19:36:19Z kc $")

@implementation OFZipCodeFormatter

- (NSString *)stringForObjectValue:(id)object;
{
    return object;
}

- (BOOL)getObjectValue:(id *)anObject forString:(NSString *)string errorDescription:(NSString **)error;
{
    if (!anObject)
        return YES;

    if (![string length]) {
        *anObject = nil;
        return YES;
    } else if ([string length] < 5) {
        if (error)
            *error = NSLocalizedStringFromTableInBundle(@"That is not a valid zip code.", @"OmniFoundation", [OFZipCodeFormatter bundle], @"formatter input error");
        *anObject = nil;
        return NO;
    } else if ([string length] < 10) {
        *anObject = [string substringToIndex:5];
    } else {
        *anObject = string;
    }
    return YES;
}

enum PhoneState {
    ScanZip, ScanDash, ScanExtended, Done
};

- (BOOL)isPartialStringValid:(NSString *)partialString newEditingString:(NSString **)newString errorDescription:(NSString **)error;
{
    unsigned int length = [partialString length];
    unsigned int index;
    unsigned int digits = 0;
    enum PhoneState state = ScanZip;
    unichar result[10];
    unichar *resultPtr = result;
    unichar c;
    BOOL changed = NO;

    for (index = 0; index < length; index++) {
	changed = NO;
        c = [partialString characterAtIndex:index];

        switch(state) {
            case ScanZip:
                if ((c >= '0') && (c <= '9')) {
                    *resultPtr++ = c;
                    if (++digits == 5)
                        state = ScanDash;
                } else {
                    changed = YES;
                }
                break;
            case ScanDash:
                if (c == '-') {
                    *resultPtr++ = c;
                    state = ScanExtended;
                    digits = 0;
                } else if ((c >= '0') && (c <= '9')) {
                    *resultPtr++ = '-';
                    *resultPtr++ = c;
                    state = ScanExtended;
                    digits = 1;
                    changed = YES;
                } else {
                    changed = YES;
                }
                break;
            case ScanExtended:
                if ((c >= '0') && (c <= '9')) {
                    *resultPtr++ = c;
                    if (++digits == 4)
                        state = Done;
                } else {
                    changed = YES;
                }
                break;
            case Done:
                changed = YES;
                break;
        }
    }
    if (changed)
        *newString = [NSString stringWithCharacters:result length:(resultPtr - result)];
    return !changed;
}

@end
