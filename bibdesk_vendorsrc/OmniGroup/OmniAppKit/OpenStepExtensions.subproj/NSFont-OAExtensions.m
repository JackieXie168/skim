// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniAppKit/NSFont-OAExtensions.h>

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <OmniBase/OmniBase.h>
#import <OmniFoundation/OmniFoundation.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSFont-OAExtensions.m 68913 2005-10-03 19:36:19Z kc $")

@implementation NSFont (OAExtensions)

- (BOOL)isScreenFont;
{
    return [self screenFont] == self;
}

- (float)widthOfString:(NSString *)aString;
{
    static NSTextStorage *fontWidthTextStorage = nil;
    static NSLayoutManager *fontWidthLayoutManager = nil;
    static NSTextContainer *fontWidthTextContainer = nil;

    NSAttributedString *attributedString;
    NSRange drawGlyphRange;
    NSRect *rectArray;
    unsigned int rectCount;
    NSDictionary *attributes;

    if (!fontWidthTextStorage) {
        fontWidthTextStorage = [[NSTextStorage alloc] init];

        fontWidthLayoutManager = [[NSLayoutManager alloc] init];
        [fontWidthTextStorage addLayoutManager:fontWidthLayoutManager];

        fontWidthTextContainer = [[NSTextContainer alloc] initWithContainerSize:NSMakeSize(1e7, 1e7)];
        [fontWidthTextContainer setLineFragmentPadding:0];
        [fontWidthLayoutManager addTextContainer:fontWidthTextContainer];
    }

    attributes = [[NSDictionary alloc] initWithObjectsAndKeys: self, NSFontAttributeName, nil];
    attributedString = [[NSAttributedString alloc] initWithString:aString attributes:attributes];
    [fontWidthTextStorage setAttributedString:attributedString];
    [attributedString release];
    [attributes release];

    drawGlyphRange = [fontWidthLayoutManager glyphRangeForTextContainer:fontWidthTextContainer];
    if (drawGlyphRange.length == 0)
        return 0.0;

    rectArray = [fontWidthLayoutManager rectArrayForGlyphRange:drawGlyphRange withinSelectedGlyphRange:NSMakeRange(NSNotFound, 0) inTextContainer:fontWidthTextContainer rectCount:&rectCount];
    if (rectCount < 1)
        return 0.0;
    return rectArray[0].size.width;
}

+ (NSFont *)fontFromPropertyListRepresentation:(NSDictionary *)dict;
{
    return [NSFont fontWithName:[dict objectForKey:@"name"] size:[[dict objectForKey:@"size"] floatValue]];
}

- (NSDictionary *)propertyListRepresentation;
{
    NSMutableDictionary *result;
    
    result = [NSMutableDictionary dictionary];
    [result setObject:[NSNumber numberWithFloat:[self pointSize]] forKey:@"size"];
    [result setObject:[self fontName] forKey:@"name"];
    return result;
}

@end
