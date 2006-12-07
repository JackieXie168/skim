// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/NSAttributedString-OFExtensions.h>

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSAttributedString-OFExtensions.m,v 1.15 2004/02/10 04:07:45 kc Exp $")

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
    } while (range.length);

    return components;
}

@end

@implementation NSMutableAttributedString (OFExtensions)
- (void)appendString:(NSString *)string attributes:(NSDictionary *)attributes;
{
    NSAttributedString *append;

    append = [[NSAttributedString alloc] initWithString:string attributes:attributes];
    [self appendAttributedString:append];
    [append release];
}

/*" Appends the given string to the receiver, using the attributes of the last character in the receiver for the new characters.  If the receiver is empty, the appended string has no attributes. "*/
- (void)appendString:(NSString *)string;
{
    NSDictionary *attributes = nil;
    unsigned int  length = [self length];

    if (length)
        attributes = [self attributesAtIndex:length-1 effectiveRange:NULL];
    [self appendString:string attributes:attributes];
}

@end
