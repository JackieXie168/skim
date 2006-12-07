// Copyright 2003-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "NSColor-ColorSyncExtensions.h"
#import "OAColorProfile.h"
#import "NSImage-ColorSyncExtensions.h"

#import "OAVersion.h"

#import <AppKit/AppKit.h>
#import <OmniBase/OmniBase.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniAppKit/ColorSync/NSColor-ColorSyncExtensions.m 68913 2005-10-03 19:36:19Z kc $");

@implementation NSColor (ColorSyncExtensions)

static IMP originalPatternImp, originalCalibratedRGBImp, originalCalibratedGrayImp, originalDeviceRGBImp, originalDeviceGrayImp, originalDeviceCMYKImp;

+ (void)performPosing;
{
    BOOL alphaSupportForPrinting;
    
    // Version 663 is the value for a new 10.2 installation without patches (6C115).
    alphaSupportForPrinting = floor(NSAppKitVersionNumber) >= OAAppKitVersionNumber10_2;
    
    if (alphaSupportForPrinting) {	
        originalPatternImp = OBReplaceMethodImplementationWithSelectorOnClass(NSClassFromString(@"NSPatternColor"), @selector(set), self, @selector(_setPattern));
        originalCalibratedRGBImp = OBReplaceMethodImplementationWithSelectorOnClass(NSClassFromString(@"NSCalibratedRGBColor"), @selector(set), self, @selector(_setCalibratedRGB));
        originalCalibratedGrayImp = OBReplaceMethodImplementationWithSelectorOnClass(NSClassFromString(@"NSCalibratedWhiteColor"), @selector(set), self, @selector(_setCalibratedGray));
        originalDeviceRGBImp = OBReplaceMethodImplementationWithSelectorOnClass(NSClassFromString(@"NSDeviceRGBColor"), @selector(set), self, @selector(_setDeviceRGB));
        originalDeviceGrayImp = OBReplaceMethodImplementationWithSelectorOnClass(NSClassFromString(@"NSDeviceWhiteColor"), @selector(set), self, @selector(_setDeviceGray));
        originalDeviceCMYKImp = OBReplaceMethodImplementationWithSelectorOnClass(NSClassFromString(@"NSDeviceCMYKColor"), @selector(set), self, @selector(_setDeviceCMYK));
    }
}

- (void)setCoreGraphicsRGBValues;
{
    float components[4];
    CGContextRef contextRef;
    
    components[0] = [self redComponent];
    components[1] = [self greenComponent];
    components[2] = [self blueComponent];
    components[3] = [self alphaComponent];
        
    contextRef = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextSetFillColor(contextRef, components);
    CGContextSetStrokeColor(contextRef, components);
}

- (void)setCoreGraphicsCMYKValues;
{
    float components[5];
    CGContextRef contextRef;
    
    components[0] = [self cyanComponent];
    components[1] = [self magentaComponent];
    components[2] = [self yellowComponent];
    components[3] = [self blackComponent];
    components[4] = [self alphaComponent];
        
    contextRef = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextSetFillColor(contextRef, components);
    CGContextSetStrokeColor(contextRef, components);
}

- (void)setCoreGraphicsGrayValues;
{
    float components[2];
    CGContextRef contextRef;
    
    components[0] = [self whiteComponent];
    components[1] = [self alphaComponent];
        
    contextRef = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextSetFillColor(contextRef, components);
    CGContextSetStrokeColor(contextRef, components);
}

- (void)_setPattern;
{
    OAColorProfile *profile;
    
    if ((profile = [OAColorProfile currentProfile])) {
        NSImage *newImage = [[NSImage alloc] initWithData:[[self patternImage] TIFFRepresentation]];

        [newImage convertFromProfile:profile toProfile:[OAColorProfile defaultDisplayProfile]];
        NSColor *convertedPatternColor = [NSColor colorWithPatternImage:newImage];
        originalPatternImp(convertedPatternColor, @selector(set));
        [newImage autorelease];
    } else
        originalPatternImp(self, @selector(set));
}

- (void)_setCalibratedRGB;
{
    OAColorProfile *profile;
    
    if ((profile = [OAColorProfile currentProfile])) {
        if ([profile _hasRGBSpace])
            [profile _setRGBColor:self];
        else if ([profile _hasCMYKSpace])
            [profile _setCMYKColor:[self colorUsingColorSpaceName:NSDeviceCMYKColorSpace]];
        else
            [profile _setGrayColor:[self colorUsingColorSpaceName:NSDeviceWhiteColorSpace]];
    } else
        originalCalibratedRGBImp(self, @selector(set));
}

- (void)_setCalibratedGray;
{
    OAColorProfile *profile;
    
    if ((profile = [OAColorProfile currentProfile])) {
        if ([profile _hasGraySpace])
            [profile _setGrayColor:self];
        else if ([profile _hasRGBSpace])
            [profile _setRGBColor:[self colorUsingColorSpaceName:NSDeviceRGBColorSpace]];
        else
            [profile _setCMYKColor:[self colorUsingColorSpaceName:NSDeviceCMYKColorSpace]];
    } else
        originalCalibratedGrayImp(self, @selector(set));
}

- (void)_setDeviceRGB;
{
    OAColorProfile *profile;
    
    if ((profile = [OAColorProfile currentProfile])) {
        if ([profile _hasRGBSpace])
            [profile _setRGBColor:self];
        else if ([profile _hasCMYKSpace])
            [profile _setCMYKColor:[self colorUsingColorSpaceName:NSDeviceCMYKColorSpace]];
        else
            [profile _setGrayColor:[self colorUsingColorSpaceName:NSDeviceWhiteColorSpace]];
    } else
        originalDeviceRGBImp(self, @selector(set));
}

- (void)_setDeviceGray;
{
    OAColorProfile *profile;
    
    if ((profile = [OAColorProfile currentProfile])) {
        if ([profile _hasGraySpace])
            [profile _setGrayColor:self];
        else if ([profile _hasRGBSpace])
            [profile _setRGBColor:[self colorUsingColorSpaceName:NSDeviceRGBColorSpace]];
        else
            [profile _setCMYKColor:[self colorUsingColorSpaceName:NSDeviceCMYKColorSpace]];
    } else
        originalDeviceGrayImp(self, @selector(set));
}

- (void)_setDeviceCMYK;
{
    OAColorProfile *profile;
    
    if ((profile = [OAColorProfile currentProfile])) {
        if ([profile _hasCMYKSpace])
            [profile _setCMYKColor:self];
        else if ([profile _hasRGBSpace])
            [profile _setRGBColor:[self colorUsingColorSpaceName:NSDeviceRGBColorSpace]];
        else
            [profile _setGrayColor:[self colorUsingColorSpaceName:NSDeviceWhiteColorSpace]];
    } else
        originalDeviceCMYKImp(self, @selector(set));
}

#define MAXUINT16 ((1 << 16) - 1)

- (NSColor *)_rgbConvertUsingColorWorld:(CMWorldRef)colorWorldRef;
{
    CMColor cmColor;
    
    if (colorWorldRef == NULL)
        return self;

    cmColor.rgb.red = [self redComponent] * MAXUINT16;
    cmColor.rgb.green = [self greenComponent] * MAXUINT16;
    cmColor.rgb.blue = [self blueComponent] * MAXUINT16;
    CWMatchColors(colorWorldRef, &cmColor, 1);
    return [NSColor colorWithDeviceRed:((float)cmColor.rgb.red / (float)MAXUINT16) green:((float)cmColor.rgb.green / (float)MAXUINT16) blue:((float)cmColor.rgb.blue / (float)MAXUINT16) alpha:[self alphaComponent]];
}

- (NSColor *)_cmykConvertUsingColorWorld:(CMWorldRef)colorWorldRef intoRGB:(BOOL)intoRGB;
{
    CMColor cmColor;
    
    if (colorWorldRef == NULL)
        return self;
    
    cmColor.cmyk.cyan = [self cyanComponent] * MAXUINT16;
    cmColor.cmyk.magenta = [self magentaComponent] * MAXUINT16;
    cmColor.cmyk.yellow = [self yellowComponent] * MAXUINT16;
    cmColor.cmyk.black = [self blackComponent] * MAXUINT16;
    
    CWMatchColors(colorWorldRef, &cmColor, 1);
    if (intoRGB)
        return [NSColor colorWithDeviceRed:((float)cmColor.rgb.red / (float)MAXUINT16) green:((float)cmColor.rgb.green / (float)MAXUINT16) blue:((float)cmColor.rgb.blue / (float)MAXUINT16) alpha:[self alphaComponent]];
    else
        return [NSColor colorWithDeviceCyan:((float)cmColor.cmyk.cyan / (float)MAXUINT16) magenta:((float)cmColor.cmyk.magenta / (float)MAXUINT16) yellow:((float)cmColor.cmyk.yellow / (float)MAXUINT16) black:((float)cmColor.cmyk.black / (float)MAXUINT16) alpha:[self alphaComponent]];
}

- (NSColor *)_grayConvertUsingColorWorld:(CMWorldRef)colorWorldRef intoRGB:(BOOL)intoRGB;
{
    CMColor cmColor;
    
    if (colorWorldRef == NULL)
        return self;

    cmColor.gray.gray = [self whiteComponent] * MAXUINT16;
    
    CWMatchColors(colorWorldRef, &cmColor, 1);
    if (intoRGB)
        return [NSColor colorWithDeviceRed:((float)cmColor.rgb.red / (float)MAXUINT16) green:((float)cmColor.rgb.green / (float)MAXUINT16) blue:((float)cmColor.rgb.blue / (float)MAXUINT16) alpha:[self alphaComponent]];
    else
        return [NSColor colorWithDeviceWhite:((float)cmColor.gray.gray / (float)MAXUINT16) alpha:[self alphaComponent]];
}

- (NSColor *)convertFromProfile:(OAColorProfile *)inProfile toProfile:(OAColorProfile *)outProfile;
{
    NSString *colorSpaceName;
        
    colorSpaceName = [self colorSpaceName];
    if (colorSpaceName == NSPatternColorSpace) {
        CMWorldRef world = [inProfile _rgbConversionWorldForOutput:outProfile];
        NSImage *newImage;
        NSColor *result;
        
        if (!world)
            return self;
            
        newImage = [[self patternImage] copy];
        [newImage convertFromProfile:inProfile toProfile:outProfile];
        result = [NSColor colorWithPatternImage:newImage];
        [newImage release];
        return result;
    } else if (colorSpaceName == NSDeviceCMYKColorSpace) {
        return [self _cmykConvertUsingColorWorld:[inProfile _cmykConversionWorldForOutput:outProfile] intoRGB:![outProfile _hasCMYKSpace]];
    } else if (colorSpaceName == NSDeviceWhiteColorSpace || colorSpaceName == NSCalibratedWhiteColorSpace) {
        return [self _grayConvertUsingColorWorld:[inProfile _grayConversionWorldForOutput:outProfile] intoRGB:![outProfile _hasGraySpace]];
    } else {
        CMWorldRef world = [inProfile _rgbConversionWorldForOutput:outProfile];
        
        if (!world)
            return self;
        if (colorSpaceName == NSDeviceRGBColorSpace || NSCalibratedRGBColorSpace)
            return [self _rgbConvertUsingColorWorld:world];
        else
            return [[self colorUsingColorSpaceName:NSDeviceRGBColorSpace] _rgbConvertUsingColorWorld:world];
    }
}

@end

