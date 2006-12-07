// Copyright 2000-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import "NSFontManager-OAExtensions.h"

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <OmniBase/OmniBase.h>
#import <OmniFoundation/OmniFoundation.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSFontManager-OAExtensions.m,v 1.6 2003/01/15 22:51:37 kc Exp $")

@implementation NSFontManager (OAExtensions)

- (NSFont *)closestFontWithFamily:(NSString *)family traits:(NSFontTraitMask)traits size:(float)size;
{
    NSFont *font;
    
    font = [self fontWithFamily:family traits:traits weight:1.0 size:size];
    if (font && ([self traitsOfFont:font] & traits) == traits)
        return font;
    
    font = [self fontWithFamily:family traits:NULL weight:1.0 size:size];
    if ([font isFixedPitch])
        return [self fontWithFamily:@"Courier" traits:traits weight:1.0 size:size];
    else
        return [self fontWithFamily:@"Helvetica" traits:traits weight:1.0 size:size];
}

#warning WJS: I think this method is now obsolete, because it never worked very well and I replaced it with a semantically different method, above
- (NSFont *)convertFont:(NSFont *)aFont toHaveTraits:(NSFontTraitMask)desiredTraits switchFamilyIfNecessary:(BOOL)shouldSwitchFamily;
{
    NSFont *convertedFont;
    NSFont *alternateFont;
    NSArray *alternateFontNames;
    unsigned int alternateFontIndex, alternateFontCount;

    convertedFont = [self convertFont:aFont toHaveTrait:desiredTraits];
    if (!shouldSwitchFamily)
        return convertedFont;
    if (convertedFont == nil)
        convertedFont = aFont;
    if (([self traitsOfFont:convertedFont] & desiredTraits) == desiredTraits)
        return convertedFont;

    // First, look for an alternate in the Helvetica family
    alternateFont = [self convertFont:convertedFont toFamily:@"Helvetica"];
    if (alternateFont != nil) {
        if (([self traitsOfFont:alternateFont] & desiredTraits) == desiredTraits)
            return alternateFont;
        alternateFont = [self convertFont:alternateFont toHaveTrait:desiredTraits];
        if (alternateFont != nil && ([self traitsOfFont:alternateFont] & desiredTraits) == desiredTraits)
            return alternateFont;
    }

    // OK, let's see what fonts match our traits
    alternateFontNames = [self availableFontNamesWithTraits:desiredTraits];
    alternateFontCount = [alternateFontNames count];
    for (alternateFontIndex = 0; alternateFontIndex < alternateFontCount; alternateFontIndex++) {
        NSString *alternateFontName;

        alternateFontName = [alternateFontNames objectAtIndex:alternateFontIndex];
        alternateFont = [self convertFont:convertedFont toFace:alternateFontName];
        if (alternateFont != nil && ([self traitsOfFont:alternateFont] & desiredTraits) == desiredTraits)
            return alternateFont;
        if (alternateFont != nil) {
            alternateFont = [self convertFont:convertedFont toHaveTrait:desiredTraits];
            if (alternateFont != nil && ([self traitsOfFont:alternateFont] & desiredTraits) == desiredTraits)
                return alternateFont;
        }
    }
    return convertedFont;
}

@end
