// Copyright 2000-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "NSColor-OAExtensions.h"

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <OmniBase/OmniBase.h>
#import <OmniFoundation/OmniFoundation.h>

#import "OAColorProfile.h"
#import "NSImage-OAExtensions.h"

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/SourceRelease_2005-10-03/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSColor-OAExtensions.m 68216 2005-09-12 19:05:31Z kc $")

NSString *OAColorXMLAdditionalColorSpace = @"OAColorXMLAdditionalColorSpace";

@implementation NSColor (OAExtensions)

+ (NSColor *)colorFromPropertyListRepresentation:(NSDictionary *)dict;
{
    id obj;
    id obj1, obj2, obj3;
    float alpha;
    
    obj = [dict objectForKey:@"archive"];
    if (obj) {
        NSColor *unarchived = [NSKeyedUnarchiver unarchiveObjectWithData:obj];
        if (unarchived != nil)
            return unarchived;
    }
    
    obj = [dict objectForKey:@"a"];
    if (obj)
        alpha = [obj floatValue];
    else
        alpha = 1.0;

    obj = [dict objectForKey:@"w"];
    if (obj) {
        return [NSColor colorWithCalibratedWhite:[obj floatValue] alpha:alpha];
    }
    
    obj = [dict objectForKey:@"catalog"];
    if (obj) {
        NSColor *color;
        obj1 = [dict objectForKey:@"name"];
        color = [NSColor colorWithCatalogName:obj colorName:obj1];
        if (!color)
            color = [NSColor whiteColor];
        return color;
    }
    obj = [dict objectForKey:@"r"];
    if (obj) {
        obj1 = [dict objectForKey:@"g"];
        obj2 = [dict objectForKey:@"b"];
        return [NSColor colorWithCalibratedRed:[obj floatValue] green:[obj1 floatValue] blue:[obj2 floatValue] alpha:alpha];
    }
    obj = [dict objectForKey:@"c"];
    if (obj) {
        obj1 = [dict objectForKey:@"m"];
        obj2 = [dict objectForKey:@"y"];
        obj3 = [dict objectForKey:@"k"];
        return [NSColor colorWithDeviceCyan:[obj floatValue] magenta:[obj1 floatValue] yellow:[obj2 floatValue] black:[obj3 floatValue] alpha:alpha];
    }
    
    obj = [dict objectForKey:@"png"];
    if (!obj)
        obj = [dict objectForKey:@"tiff"];
    if (obj) {
        NSImage *patternImage;
        NSBitmapImageRep *bitmapImageRep;
        NSSize imageSize;

        bitmapImageRep = (id)[NSBitmapImageRep imageRepWithData:obj];
        imageSize = [bitmapImageRep size];
        if (bitmapImageRep == nil || NSEqualSizes(imageSize, NSZeroSize)) {
            NSLog(@"Warning, could not rebuild pattern color from image rep %@, data %@", bitmapImageRep, obj);
            return [NSColor whiteColor];
        }
        patternImage = [[NSImage alloc] initWithSize:imageSize];
        [patternImage addRepresentation:bitmapImageRep];
        return [NSColor colorWithPatternImage:[patternImage autorelease]];
    }
    
    return [NSColor whiteColor];
}

- (NSMutableDictionary *)propertyListRepresentation;
{
    NSMutableDictionary *dict;
    NSString *colorSpace;
    BOOL hasAlpha = NO;
    
    dict = [NSMutableDictionary dictionary];
    colorSpace = [self colorSpaceName];
    if ([colorSpace isEqualToString:NSCalibratedWhiteColorSpace] || [colorSpace isEqualToString:NSDeviceWhiteColorSpace]) {
        [dict setObject:[NSString stringWithFormat:@"%g", [self whiteComponent]] forKey:@"w"];
        hasAlpha = YES;
    } else if ([colorSpace isEqualToString:NSCalibratedRGBColorSpace] || [colorSpace isEqualToString:NSDeviceRGBColorSpace]) {
        [dict setObject:[NSString stringWithFormat:@"%g", [self redComponent]] forKey:@"r"];
        [dict setObject:[NSString stringWithFormat:@"%g", [self greenComponent]] forKey:@"g"];
        [dict setObject:[NSString stringWithFormat:@"%g", [self blueComponent]] forKey:@"b"];
        hasAlpha = YES;
    } else if ([colorSpace isEqualToString:NSNamedColorSpace]) {
        [dict setObject:[self catalogNameComponent] forKey:@"catalog"];
        [dict setObject:[self colorNameComponent] forKey:@"name"];
    } else if ([colorSpace isEqualToString:NSDeviceCMYKColorSpace]) {
        [dict setObject:[NSString stringWithFormat:@"%g", [self cyanComponent]] forKey:@"c"];
        [dict setObject:[NSString stringWithFormat:@"%g", [self magentaComponent]] forKey:@"m"];
        [dict setObject:[NSString stringWithFormat:@"%g", [self yellowComponent]] forKey:@"y"];
        [dict setObject:[NSString stringWithFormat:@"%g", [self blackComponent]] forKey:@"k"];
        hasAlpha = YES;
    } else if ([colorSpace isEqualToString:NSPatternColorSpace]) {
        [dict setObject:[[self patternImage] TIFFRepresentation] forKey:@"tiff"];
    } else {
        NSDictionary *rgbFallback = [[self colorUsingColorSpaceName:NSCalibratedRGBColorSpace] propertyListRepresentation];
        if (rgbFallback)
            [dict addEntriesFromDictionary:rgbFallback];
        NSData *archive = [NSKeyedArchiver archivedDataWithRootObject:self];
        if (archive != nil && [archive length] > 0)
            [dict setObject:archive forKey:@"archive"];
        return dict;
    }
    if (hasAlpha) {
        float alpha;

        alpha = [self alphaComponent];
        if (alpha != 1.0)
            [dict setObject:[NSString stringWithFormat:@"%g", alpha] forKey:@"a"];
    }
    return dict;
}

//

- (BOOL)isSimilarToColor:(NSColor *)color;
{
    NSString *colorSpace = [self colorSpaceName];

    if (!([colorSpace isEqualToString:[color colorSpaceName]])) {
        return NO;
    }

    if ([colorSpace isEqualToString:NSCalibratedWhiteColorSpace] || [colorSpace isEqualToString:NSDeviceWhiteColorSpace]) {
        return (fabs([self whiteComponent]-[color whiteComponent]) < 0.001) && (fabs([self alphaComponent]-[color alphaComponent]) < 0.001);

    } else if ([colorSpace isEqualToString:NSCalibratedRGBColorSpace] || [colorSpace isEqualToString:NSDeviceRGBColorSpace]) {
        return (fabs([self redComponent]-[color redComponent]) < 0.001) && (fabs([self greenComponent]-[color greenComponent]) < 0.001) && (fabs([self blueComponent]-[color blueComponent]) < 0.001) && (fabs([self alphaComponent]-[color alphaComponent]) < 0.001);

    } else if ([colorSpace isEqualToString:NSNamedColorSpace]) {
        return [[self catalogNameComponent] isEqualToString:[color catalogNameComponent]] && [[self colorNameComponent] isEqualToString:[color colorNameComponent]];

    } else if ([colorSpace isEqualToString:NSDeviceCMYKColorSpace]) {
        return (fabs([self cyanComponent]-[color cyanComponent]) < 0.001) && (fabs([self magentaComponent]-[color magentaComponent]) < 0.001) && (fabs([self yellowComponent]-[color yellowComponent]) < 0.001) && (fabs([self blackComponent]-[color blackComponent]) < 0.001) && (fabs([self alphaComponent]-[color alphaComponent]) < 0.001);

    } else if ([colorSpace isEqualToString:NSPatternColorSpace]) {
        return [[[self patternImage] TIFFRepresentation] isEqualToData:[[color patternImage] TIFFRepresentation]];
    }
    
    return NO;
}


- (NSData *)patternImagePNGData;
{
    NSString *colorSpace = [self colorSpaceName];
    NSImage *patternImage;
    NSBitmapImageRep *bitmapImageRep;

    if (!([colorSpace isEqualToString:NSPatternColorSpace]))
        return nil;

    patternImage = [self patternImage];
    bitmapImageRep = (id)[patternImage imageRepOfClass:[NSBitmapImageRep class]];
    if (bitmapImageRep == nil) {
        NSCachedImageRep *cachedImageRep;

        cachedImageRep = (NSCachedImageRep *)[patternImage imageRepOfClass:[NSCachedImageRep class]];
        if (cachedImageRep == nil) {
            NSLog(@"Warning: couldn't get PNG data for pattern color %@, because it had no cached image representation", self);
            return nil;
        }

        [[[cachedImageRep window] contentView] lockFocus]; {
            bitmapImageRep = [[[NSBitmapImageRep alloc] initWithFocusedViewRect:[cachedImageRep rect]] autorelease];
        } [[[cachedImageRep window] contentView] unlockFocus];
    }

    return [bitmapImageRep representationUsingType:NSPNGFileType properties:nil];
}

#ifdef MAC_OS_X_VERSION_10_2

static NSColorList *combinedColorList = nil;

static void _addColorsFromList(NSColorList *colorList)
{
    if (colorList == nil)
            return;

    NSArray *allColorKeys = [colorList allKeys];
    unsigned int colorIndex, colorCount = [allColorKeys count];
    for (colorIndex = 0; colorIndex < colorCount; colorIndex++) {
            NSString *colorKey = [allColorKeys objectAtIndex:colorIndex];
            NSColor *color = [colorList colorWithKey:colorKey];
            [combinedColorList setColor:color forKey:colorKey];
    }
}

+ (NSColorList *)_combinedColorList;
{
    if (combinedColorList == nil) {
        combinedColorList = [[NSColorList alloc] initWithName:@""];

        _addColorsFromList([NSColorList colorListNamed:@"Apple"]);
        _addColorsFromList([[[NSColorList alloc] initWithName:nil fromFile:[[OAColorProfile bundle] pathForResource:@"Classic Crayons" ofType:@"clr"]] autorelease]);
        _addColorsFromList([NSColorList colorListNamed:@"Crayons"]);
    }
    return combinedColorList;
}

static float _nearnessWithWrap(float a, float b)
{
    float value1 = 1.0 - a + b;
    float value2 = 1.0 - b + a;
    float value3 = a - b;
    return MIN(ABS(value1), MIN(ABS(value2), ABS(value3)));
}

static float _hsbCloseness(float hue1, float hue2, float saturation1, float saturation2, float brightness1, float brightness2)
{
    // We weight the hue stronger than the saturation or brightness, since it's easier to talk about 'dark yellow' than it is 'yellow except for with a little red in it'
    return _nearnessWithWrap(hue1, hue2) * 3.0 + ABS(saturation1 - saturation2) + ABS(brightness1 - brightness2);
}
        
- (NSString *)similarColorNameFromColorLists;
{
    if ([[self colorSpaceName] isEqualToString:NSNamedColorSpace])
        return [self localizedColorNameComponent];
    else if ([[self colorSpaceName] isEqualToString:NSPatternColorSpace])
        return NSLocalizedStringFromTableInBundle(@"Image", @"OmniAppKit", [OAColorProfile bundle], "generic color name for pattern colors");
    else if ([[self colorSpaceName] isEqualToString:NSCustomColorSpace])
        return NSLocalizedStringFromTableInBundle(@"Custom", @"OmniAppKit", [OAColorProfile bundle], "generic color name for custom colors");
    
    NSColorList *combinedColorList = [NSColor _combinedColorList];
    float hue, saturation, brightness, alpha;
    [[self colorUsingColorSpaceName:NSCalibratedRGBColorSpace] getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];
    
    NSString *closestColorKey = nil;
    float closestHue = -1000, closestSaturation = -1000, closestBrightness = -1000;

    NSArray *allColorKeys = [combinedColorList allKeys];
    unsigned int colorIndex, colorCount = [allColorKeys count];
    for (colorIndex = 0; colorIndex < colorCount; colorIndex++) {
        NSString *colorKey = [allColorKeys objectAtIndex:colorIndex];
        NSColor *color = [combinedColorList colorWithKey:colorKey];

        float otherHue, otherSaturation, otherBrightness, otherAlpha;
        [[color colorUsingColorSpaceName:NSCalibratedRGBColorSpace] getHue:&otherHue saturation:&otherSaturation brightness:&otherBrightness alpha:&otherAlpha];

        if (_hsbCloseness(hue, otherHue, saturation, otherSaturation, brightness, otherBrightness) < _hsbCloseness(hue, closestHue, saturation, closestSaturation, brightness, closestBrightness)) {
            closestHue = otherHue;
            closestSaturation = otherSaturation;
            closestBrightness = otherBrightness;
            closestColorKey = colorKey;
        }
    }

    float brightnessDifference = brightness - closestBrightness;
    NSString *brightnessString = nil;
    if (brightnessDifference < -.1 && brightness < .1)
        brightnessString =  NSLocalizedStringFromTableInBundle(@"Near-black", @"OmniAppKit", [OAColorProfile bundle], "word comparing color brightnesss");
    else if (brightnessDifference < -.2)
        brightnessString =  NSLocalizedStringFromTableInBundle(@"Dark", @"OmniAppKit", [OAColorProfile bundle], "word comparing color brightnesss");
    else if (brightnessDifference < -.1)
        brightnessString =  NSLocalizedStringFromTableInBundle(@"Smokey", @"OmniAppKit", [OAColorProfile bundle], "word comparing color brightnesss");
    else if (brightnessDifference > .1 && brightness > .9)
        brightnessString =  NSLocalizedStringFromTableInBundle(@"Off-white", @"OmniAppKit", [OAColorProfile bundle], "word comparing color brightnesss");
    else if (brightnessDifference > .2)
        brightnessString =  NSLocalizedStringFromTableInBundle(@"Bright", @"OmniAppKit", [OAColorProfile bundle], "word comparing color brightnesss");
    else if (brightnessDifference > .1)
        brightnessString =  NSLocalizedStringFromTableInBundle(@"Light", @"OmniAppKit", [OAColorProfile bundle], "word comparing color brightnesss");

    float saturationDifference = saturation - closestSaturation;
    NSString *saturationString = nil;
    if (saturationDifference < -0.3)
        saturationString =  NSLocalizedStringFromTableInBundle(@"Washed-out", @"OmniAppKit", [OAColorProfile bundle], "word comparing color saturations");
    else if (saturationDifference < -.2)
        saturationString =  NSLocalizedStringFromTableInBundle(@"Faded", @"OmniAppKit", [OAColorProfile bundle], "word comparing color saturations");
    else if (saturationDifference < -.1)
        saturationString =  NSLocalizedStringFromTableInBundle(@"Mild", @"OmniAppKit", [OAColorProfile bundle], "word comparing color saturations");
    else if (saturationDifference < -0)
        saturationString = nil;
    else if (saturationDifference < .1)
        saturationString = nil;
    else if (saturationDifference < .2)
        saturationString =  NSLocalizedStringFromTableInBundle(@"Rich", @"OmniAppKit", [OAColorProfile bundle], "word comparing color saturations");
    else if (saturationDifference < .3)
        saturationString =  NSLocalizedStringFromTableInBundle(@"Deep", @"OmniAppKit", [OAColorProfile bundle], "word comparing color saturations");
    else
        saturationString =  NSLocalizedStringFromTableInBundle(@"Intense", @"OmniAppKit", [OAColorProfile bundle], "word comparing color saturations");

    NSString *closestColorDescription = nil;
    if (saturationString != nil && brightnessString != nil)
        closestColorDescription = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%@, %@ %@", @"OmniAppKit", [OAColorProfile bundle], "format string for color with saturation and brightness descriptions"), brightnessString, saturationString, closestColorKey];
    else if (saturationString != nil)
        closestColorDescription = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%@ %@", @"OmniAppKit", [OAColorProfile bundle], "format string for color with saturation description"), saturationString, closestColorKey];
    else if (brightnessString != nil)
        closestColorDescription = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%@ %@", @"OmniAppKit", [OAColorProfile bundle], "format string for color with brightness description"), brightnessString, closestColorKey];
    else
        closestColorDescription = closestColorKey;

    if (alpha <= 0.001)
        return NSLocalizedStringFromTableInBundle(@"Clear", @"OmniAppKit", [OAColorProfile bundle], "name of completely transparent color");
    else if (alpha < .999)
        return [NSString stringWithFormat:@"%d%% %@", (int)(alpha * 100), closestColorDescription];
    else
        return closestColorDescription;
}

+ (NSColor *)_adjustColor:(NSColor *)aColor withAdjective:(NSString *)adjective;
{
    float hue, saturation, brightness, alpha;
    [[aColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace] getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];

    if ([adjective isEqualToString:@"Near-black"]) {
        brightness = MIN(brightness, 0.05);
    } else if ([adjective isEqualToString:@"Dark"]) {
        brightness = MAX(0.0, brightness - 0.25);
    } else if ([adjective isEqualToString:@"Smokey"]) {
        brightness = MAX(0.0, brightness - 0.15);
    } else if ([adjective isEqualToString:@"Off-white"]) {
        brightness = MAX(brightness, 0.95);
    } else if ([adjective isEqualToString:@"Bright"]) {
        brightness = MIN(1.0, brightness + 0.25);
    } else if ([adjective isEqualToString:@"Light"]) {
        brightness = MIN(1.0, brightness + 0.15);
    } else if ([adjective isEqualToString:@"Washed-out"]) {
        saturation = MAX(0.0, saturation - 0.35);
    } else if ([adjective isEqualToString:@"Faded"]) {
        saturation = MAX(0.0, saturation - 0.25);
    } else if ([adjective isEqualToString:@"Mild"]) {
        saturation = MAX(0.0, saturation - 0.15);
    } else if ([adjective isEqualToString:@"Rich"]) {
        saturation = MIN(1.0, saturation + 0.15);
    } else if ([adjective isEqualToString:@"Deep"]) {
        saturation = MIN(1.0, saturation + 0.25);
    } else if ([adjective isEqualToString:@"Intense"]) {
        saturation = MIN(1.0, saturation + 0.35);
    }
    return [NSColor colorWithCalibratedHue:hue saturation:saturation brightness:brightness alpha:alpha];
}

+ (NSColor *)colorWithSimilarName:(NSString *)aName;
{
    NSColorList *combinedColorList = [NSColor _combinedColorList];
    NSArray *allColorKeys = [combinedColorList allKeys];
    unsigned int colorIndex, colorCount = [allColorKeys count];
    NSColor *baseColor = nil;
    unsigned int longestMatch = 0;

    // special case clear
    if ([aName isEqualToString:@"Clear"])
        return [NSColor clearColor];
    
    // find base color
    for (colorIndex = 0; colorIndex < colorCount; colorIndex++) {
        NSString *colorKey = [allColorKeys objectAtIndex:colorIndex];
        unsigned int length;
        
        if ([aName hasSuffix:colorKey] && (length = [colorKey length]) > longestMatch) {
            baseColor = [combinedColorList colorWithKey:colorKey];
            longestMatch = length;
        }
    }
    if (baseColor == nil)
        return nil;
    if ([aName length] == longestMatch)
        return baseColor;
    aName = [aName substringToIndex:([aName length] - longestMatch) - 1];
    
    // get alpha percentage
    NSRange percentRange = [aName rangeOfString:@"%"];
    if (percentRange.length == 1) {
        baseColor = [baseColor colorWithAlphaComponent:([aName floatValue] / 100.0)];
        if (NSMaxRange(percentRange) + 1 >= [aName length])
            return baseColor;
        aName = [aName substringFromIndex:NSMaxRange(percentRange) + 1];
    }
    
    // adjust by adjectives
    NSRange commaRange = [aName rangeOfString:@", "];
    if (commaRange.length == 2) {
        baseColor = [self _adjustColor:baseColor withAdjective:[aName substringToIndex:commaRange.location]];
        aName = [aName substringFromIndex:NSMaxRange(commaRange)];
    }
    return [self _adjustColor:baseColor withAdjective:aName];
}

#endif

//
// XML Archiving
//

static NSString *XMLElementName = @"color";

+ (NSString *)xmlElementName;
{
    return XMLElementName;
}

- (void)_appendXML:(OFXMLDocument *)doc;
{
    NSString *colorSpace;
    BOOL hasAlpha = NO;

    colorSpace = [self colorSpaceName];
    if ([colorSpace isEqualToString:NSCalibratedWhiteColorSpace] || [colorSpace isEqualToString:NSDeviceWhiteColorSpace]) {
        [doc setAttribute: @"w" real:[self whiteComponent]];
        hasAlpha = YES;
    } else if ([colorSpace isEqualToString:NSCalibratedRGBColorSpace] || [colorSpace isEqualToString:NSDeviceRGBColorSpace]) {
        [doc setAttribute: @"r" real:[self redComponent]];
        [doc setAttribute: @"g" real:[self greenComponent]];
        [doc setAttribute: @"b" real:[self blueComponent]];
        hasAlpha = YES;
    } else if ([colorSpace isEqualToString:NSNamedColorSpace]) {
        [doc setAttribute: @"catalog" string:[self catalogNameComponent]];
        [doc setAttribute: @"name" string:[self colorNameComponent]];
    } else if ([colorSpace isEqualToString:NSDeviceCMYKColorSpace]) {
        [doc setAttribute: @"c" real:[self cyanComponent]];
        [doc setAttribute: @"m" real:[self magentaComponent]];
        [doc setAttribute: @"y" real:[self yellowComponent]];
        [doc setAttribute: @"k" real:[self blackComponent]];
        hasAlpha = YES;
    } else if ([colorSpace isEqualToString:NSPatternColorSpace]) {
        // TJW: Is there a length limit on attribute data.  It seems pretty lame to put the tiff in an attribute.
        // Maybe should switch to <color image="tiff">data</color>.  Could then add 'png' and such.
        NSString *tiffString = [[[self patternImage] TIFFRepresentation] base64String];
        [doc setAttribute: @"tiff" string:tiffString];
    } else {
        // Fallback for unknown color spaces. Write them out as RGB, but also include an archived version of the actual color.
        [[self colorUsingColorSpaceName:NSCalibratedRGBColorSpace] _appendXML:doc];
        NSData *archivedVersion = [NSKeyedArchiver archivedDataWithRootObject:self];
        if (archivedVersion && [archivedVersion length] > 0)
            [doc setAttribute:@"archive" string:[archivedVersion base64String]];
        return;
    }
    if (hasAlpha) {
        float alpha;

        alpha = [self alphaComponent];
        if (alpha != 1.0)
            [doc setAttribute: @"a" real:alpha];
    }
}

- (void) appendXML:(OFXMLDocument *)doc;
{
    [doc pushElement: XMLElementName];
    {
        [self _appendXML:doc];

        // This is used in cases where you want to export both the real colorspace AND something that might be understandable to other XML readers (who won't be able to understand catalog colors).
        NSString *additionalColorSpace = [doc userObjectForKey:OAColorXMLAdditionalColorSpace];
        if (additionalColorSpace && OFNOTEQUAL(additionalColorSpace, [self colorSpaceName]))
            [[self colorUsingColorSpaceName:additionalColorSpace] _appendXML:doc];
    }
    [doc popElement];
}

+ (NSColor *)colorFromXML:(OFXMLCursor *)cursor;
{
    OBPRECONDITION([[cursor name] isEqualToString: XMLElementName]);
    
    id obj;
    id obj1, obj2, obj3;
    float alpha;
    
    obj = [cursor attributeNamed:@"archive"];
    if (obj) {
        NSData *archivedVersion = [[NSData alloc] initWithBase64String:obj];
        NSColor *color = nil;
        if ([archivedVersion length] > 0)
            color = [NSKeyedUnarchiver unarchiveObjectWithData:archivedVersion];
        [archivedVersion release];
        if (color)
            return color;
    }

    obj = [cursor attributeNamed:@"a"];
    if (obj)
        alpha = [obj floatValue];
    else
        alpha = 1.0;

    obj = [cursor attributeNamed:@"w"];
    if (obj) {
        return [NSColor colorWithCalibratedWhite:[obj floatValue] alpha:alpha];
    }

    obj = [cursor attributeNamed:@"catalog"];
    if (obj) {
        NSColor *color;
        obj1 = [cursor attributeNamed:@"name"];
        color = [NSColor colorWithCatalogName:obj colorName:obj1];
        if (!color)
            color = [NSColor whiteColor];
        return color;
    }
    obj = [cursor attributeNamed:@"r"];
    if (obj) {
        obj1 = [cursor attributeNamed:@"g"];
        obj2 = [cursor attributeNamed:@"b"];
        return [NSColor colorWithCalibratedRed:[obj floatValue] green:[obj1 floatValue] blue:[obj2 floatValue] alpha:alpha];
    }
    obj = [cursor attributeNamed:@"c"];
    if (obj) {
        obj1 = [cursor attributeNamed:@"m"];
        obj2 = [cursor attributeNamed:@"y"];
        obj3 = [cursor attributeNamed:@"k"];
        return [NSColor colorWithDeviceCyan:[obj floatValue] magenta:[obj1 floatValue] yellow:[obj2 floatValue] black:[obj3 floatValue] alpha:alpha];
    }

    obj = [cursor attributeNamed:@"png"];
    if (!obj)
        obj = [cursor attributeNamed:@"tiff"];
    if (obj) {
        NSImage *patternImage;
        NSBitmapImageRep *bitmapImageRep;
        NSSize imageSize;

        NSData *data = [[[NSData alloc] initWithBase64String:obj] autorelease];
        bitmapImageRep = (id)[NSBitmapImageRep imageRepWithData:data];
        imageSize = [bitmapImageRep size];
        if (bitmapImageRep == nil || NSEqualSizes(imageSize, NSZeroSize)) {
            NSLog(@"Warning, could not rebuild pattern color from image rep %@, data %@", bitmapImageRep, obj);
            return [NSColor whiteColor];
        }
        patternImage = [[NSImage alloc] initWithSize:imageSize];
        [patternImage addRepresentation:bitmapImageRep];
        return [NSColor colorWithPatternImage:[patternImage autorelease]];
    }

    return [NSColor whiteColor];
}
@end


// Value transformer
#if MAC_OS_X_VERSION_10_3 <= MAC_OS_X_VERSION_MAX_ALLOWED
NSString *OAColorToPropertyListTransformerName = @"OAColorToPropertyList";

@interface OAColorToPropertyList : NSValueTransformer
@end

@implementation OAColorToPropertyList

+ (void)didLoad;
{
    [NSValueTransformer setValueTransformer:[[self alloc] init] forName:OAColorToPropertyListTransformerName];
}

+ (Class)transformedValueClass;
{
    return [NSDictionary class];
}

+ (BOOL)allowsReverseTransformation;
{
    return YES;
}

- (id)transformedValue:(id)value;
{
    return [(NSColor *)value propertyListRepresentation];
}

- (id)reverseTransformedValue:(id)value;
{
    return [NSColor colorFromPropertyListRepresentation:value];
}

@end

#endif
