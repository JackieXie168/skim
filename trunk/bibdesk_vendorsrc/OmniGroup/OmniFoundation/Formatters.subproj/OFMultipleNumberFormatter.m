// Copyright 2002-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OFMultipleNumberFormatter.h"

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

#import "NSObject-OFExtensions.h"

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/Formatters.subproj/OFMultipleNumberFormatter.m 68913 2005-10-03 19:36:19Z kc $");

@interface OFMultipleNumberFormatter (Private)
@end

@implementation OFMultipleNumberFormatter

static NSCharacterSet *nonDigitOrSpaceSet;

+ (void)initialize;
{
    OBINITIALIZE;
    
    nonDigitOrSpaceSet = [[[NSCharacterSet characterSetWithCharactersInString:@"0123456789 "] invertedSet] retain];
}

- (NSString *)stringForObjectValue:(id)object;
{
    return [object componentsJoinedByString:@" "];
}

- (BOOL)getObjectValue:(id *)anObject forString:(NSString *)string errorDescription:(NSString **)error;
{    
    NSEnumerator *enumerator;
    NSMutableArray *result;
    
    if (!anObject)
        return YES;

    if (![string length]) {
        *anObject = nil;
        return YES;
    }

    if ([string rangeOfCharacterFromSet:nonDigitOrSpaceSet].length) {
        if (error)
            *error = NSLocalizedStringFromTableInBundle(@"Only enter numbers separated by spaces.", @"OmniFoundation", [OFMultipleNumberFormatter bundle], @"formatter input error");
        return NO;
    }
    
    enumerator = [[string componentsSeparatedByString:@" "] objectEnumerator];
    result = [NSMutableArray array];
    while ((string = [enumerator nextObject]))
        [result addObject:[NSNumber numberWithInt:[string intValue]]];
    *anObject = result;
    return YES;
}

- (BOOL)isPartialStringValid:(NSString *)partialString newEditingString:(NSString **)newString errorDescription:(NSString **)error;
{
    BOOL didCopy = NO;
    NSRange range;
    
    while ((range = [partialString rangeOfCharacterFromSet:nonDigitOrSpaceSet]).length) {
        if (!didCopy) {
            partialString = [partialString mutableCopy];
            didCopy = YES;
        }
        [(NSMutableString *)partialString deleteCharactersInRange:range];
    }

    if (didCopy)
        *newString = [partialString autorelease];
    return !didCopy;
}

@end

@implementation OFMultipleNumberFormatter (Private)
@end
