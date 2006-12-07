// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OAColorPalette.h,v 1.11 2003/01/15 22:51:30 kc Exp $

#import <OmniFoundation/OFObject.h>

@class NSColor;

@interface OAColorPalette : OFObject
{
}

+ (NSColor *)colorForString:(NSString *)colorString gamma:(double)gamma;
+ (NSColor *)colorForString:(NSString *)colorString;
+ (NSString *)stringForColor:(NSColor *)color gamma:(double)gamma;
+ (NSString *)stringForColor:(NSColor *)color;

@end

#import <math.h> // for pow()
#import <AppKit/NSColor.h> // for +colorWithCalibratedRed...

static inline double
OAColorPaletteApplyGammaAndNormalize(unsigned int sample, unsigned int maxValue, double gamma)
{
    double normalizedSample;

    normalizedSample = ((double)sample / (double)maxValue);

    if (gamma == 1.0)
        return normalizedSample;
    else
        return pow(normalizedSample, gamma);
}

static inline NSColor *
OAColorPaletteColorWithRGBMaxAndGamma(unsigned int red, unsigned int green, unsigned int blue, unsigned int maxValue, double gamma)
{
    return [NSColor colorWithCalibratedRed:OAColorPaletteApplyGammaAndNormalize(red, maxValue, gamma) green:OAColorPaletteApplyGammaAndNormalize(green, maxValue, gamma) blue:OAColorPaletteApplyGammaAndNormalize(blue, maxValue, gamma) alpha:1.0];
}