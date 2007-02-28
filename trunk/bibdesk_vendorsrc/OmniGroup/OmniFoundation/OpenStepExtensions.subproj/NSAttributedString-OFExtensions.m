// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/NSAttributedString-OFExtensions.h>

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSAttributedString-OFExtensions.m 66043 2005-07-25 21:17:05Z kc $")

@implementation NSAttributedString (OFExtensions)

- initWithString:(NSString *)string attributeName:(NSString *)attributeName attributeValue:(id)attributeValue;
{
    NSAttributedString *returnValue;
    NSDictionary *attributes;
    
    OBPRECONDITION(attributeName != nil);
    OBPRECONDITION(attributeValue != nil);
    
    attributes = [[NSDictionary alloc] initWithObjects:&attributeValue forKeys:&attributeName count:1];

    // May return a different object
    returnValue = [self initWithString:string attributes:attributes];

    [attributes release];

    return returnValue;
}

- (NSArray *)componentsSeparatedByString:(NSString *)separator;
{
    NSString *string;
    NSRange range, separatorRange, componentRange;
    NSMutableArray *components;

    string = [self string];
    components = [NSMutableArray array];

    range = NSMakeRange(0, [string length]);
    
    do {
        separatorRange = [string rangeOfString:separator options:0 range:range];
        if (separatorRange.length) {
            componentRange = NSMakeRange(range.location, separatorRange.location - range.location);
            range.length -= (NSMaxRange(separatorRange) - range.location);
            range.location = NSMaxRange(separatorRange);
        } else {
            componentRange = range;
            range.length = 0;
        }
        [components addObject:[self attributedSubstringFromRange:componentRange]];
    } while (separatorRange.length);

    return components;
}

@end
