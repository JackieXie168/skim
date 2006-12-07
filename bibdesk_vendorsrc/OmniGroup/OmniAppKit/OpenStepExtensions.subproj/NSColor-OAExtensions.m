// Copyright 2000-2006 Omni Development, Inc.  All rights reserved.
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

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSColor-OAExtensions.m 79079 2006-09-07 22:35:32Z kc $")

NSString *OAColorXMLAdditionalColorSpace = @"OAColorXMLAdditionalColorSpace";

static NSColorList *classicCrayonsColorList(void)
{
    static NSColorList *classicCrayonsColorList = nil;
    
    if (classicCrayonsColorList == nil) {
	NSString *colorListName = NSLocalizedStringFromTableInBundle(@"Classic Crayons", @"OmniAppKit", OMNI_BUNDLE, "color list name");
	classicCrayonsColorList = [[NSColorList alloc] initWithName:colorListName fromFile:[OMNI_BUNDLE pathForResource:@"Classic Crayons" ofType:@"clr"]];
    }
    return classicCrayonsColorList;
}

@interface NSColorPicker (Private)
- (void)attachColorList:(id)list makeSelected:(BOOL)flag;
- (void)refreashUI; // sic
@end

// Adding a color list to the color panel when it is NOT in list mode, will not to anything.  Radar #4341924.
@implementation NSColorPanel (OAHacks)
static void (*originalSwitchToPicker)(id self, SEL _cmd, NSColorPicker *picker);
+ (void)performPosing;
{
    // No public API for this
    if ([self instancesRespondToSelector:@selector(_switchToPicker:)])
	originalSwitchToPicker = (typeof(originalSwitchToPicker))OBReplaceMethodImplementationWithSelector(self, @selector(_switchToPicker:), @selector(_replacement_switchToPicker:));
}
- (void)_replacement_switchToPicker:(NSColorPicker *)picker;
{
    originalSwitchToPicker(self, _cmd, picker);

    static BOOL attached = NO;
    if (!attached && [NSStringFromClass([picker class]) isEqual:@"NSColorPickerPageableNameList"]) {
	attached = YES;
	
	// Look at the (private) preference for which color list to have selected.  If it is the one we are adding, use -attachColorList: (which will select it).  Otherwise, use the (private) -attachColorList:makeSelected: and specify to not select it (otherwise the color list selected when the real code sets up and reads the default will be overridden).  If we fail to select the color list we are adding, though, the picker will show an empty color list (since the real code will have tried to select it before it is added).  Pheh.  See <bug://30338> for some of these issues.  Logged Radar 4640063 to add for asks for -attachColorList:makeSelected: to be public.

	// Sadly, the (private) preference encodes the color list name with a '1' at the beginning.  I have no idea what this is for.  I'm uncomfortable using [defaultColorList hasSuffix:[colorList name]] below since that might match more than one color list.
	NSString *defaultColorList = [[NSUserDefaults standardUserDefaults] stringForKey:@"NSColorPickerPageableNameListDefaults"];
	if ([defaultColorList hasPrefix:@"1"])
	    defaultColorList = [defaultColorList substringFromIndex:1];
	
	NSColorList *colorList = classicCrayonsColorList();
	if ([picker respondsToSelector:@selector(attachColorList:makeSelected:)]) {
	    BOOL select = OFISEQUAL(defaultColorList, [colorList name]);

	    [picker attachColorList:colorList makeSelected:select];
	    if (select && [picker respondsToSelector:@selector(refreashUI)])
		// The picker is in a bad state from trying to select a color list that wasn't there when -restoreDefaults was called.  Passing makeSelected:YES will apparently bail since the picker things that color list is already selected and we'll be left with an empty list of colors displayed.  First, select some other color list if possible.
		[picker refreashUI];
	} else
	    [picker attachColorList:colorList];
    }
}
@end

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

typedef struct {
    NSString *name; // easy name lookup
    float     h, s, v, a; // avoid conversions
    float     r, g, B;
    NSColor  *color; // in the original color space
} OANamedColorEntry;

static OANamedColorEntry *_addColorsFromList(OANamedColorEntry *colorEntries, unsigned int *entryCount, NSColorList *colorList)
{
    if (colorList == nil)
	return colorEntries;

    NSArray *allColorKeys = [colorList allKeys];
    unsigned int colorIndex, colorCount = [allColorKeys count];
    
    // Make room for the extra entries
    colorEntries = (OANamedColorEntry *)realloc(colorEntries, sizeof(*colorEntries)*(*entryCount + colorCount));
    
    for (colorIndex = 0; colorIndex < colorCount; colorIndex++) {
	NSString *colorKey = [allColorKeys objectAtIndex:colorIndex];
	NSColor *color = [colorList colorWithKey:colorKey];
	
	OANamedColorEntry *entry = &colorEntries[*entryCount + colorIndex];
	entry->name = [colorKey copy];
	
	NSColor *rgbColor = [color colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	[rgbColor getHue:&entry->h saturation:&entry->s brightness:&entry->v alpha:&entry->a];
	[rgbColor getRed:&entry->r green:&entry->g blue:&entry->B alpha:&entry->a];
	
	entry->color = [color retain];
    }
    
    // Inform caller of new entry count, finally
    *entryCount += colorCount;
    return colorEntries;
}

static const OANamedColorEntry *_combinedColorEntries(unsigned int *outEntryCount)
{
    static OANamedColorEntry *entries = NULL;
    static unsigned int entryCount = 0;
    
    if (entries == NULL) {
	// Two built-in color lists that should get localized
        entries = _addColorsFromList(entries, &entryCount, [NSColorList colorListNamed:@"Apple"]);
        entries = _addColorsFromList(entries, &entryCount, [NSColorList colorListNamed:@"Crayons"]);
	
	// Load *our* color list last since it should be localized and has more colors than either of the above
	entries = _addColorsFromList(entries, &entryCount, classicCrayonsColorList());
    }
    
    *outEntryCount = entryCount;
    return entries;
}

static float _nearnessWithWrap(float a, float b)
{
    float value1 = 1.0 - a + b;
    float value2 = 1.0 - b + a;
    float value3 = a - b;
    return MIN(ABS(value1), MIN(ABS(value2), ABS(value3)));
}

static float _colorCloseness(const OANamedColorEntry *e1, const OANamedColorEntry *e2)
{
    // As saturation goes to zero, hue becomes irrelevant.  For example, black has h=0, but that doesn't mean it is "like" red.  So, we do the distance in RGB space.  But the modifier words in HSV.
    float sdiff = ABS(e1->s - e2->s);
    if (sdiff < 0.1 && e1->s < 0.1) {
	float rd = e1->r - e2->r;
	float gd = e1->g - e2->g;
	float bd = e1->B - e2->B;
	
	return sqrt(rd*rd + gd*gd + bd*bd);
    } else {
	// We weight the hue stronger than the saturation or brightness, since it's easier to talk about 'dark yellow' than it is 'yellow except for with a little red in it'
	return 3.0 * _nearnessWithWrap(e1->h, e2->h) + sdiff + ABS(e1->v - e2->v);
    }
}
        
- (NSString *)similarColorNameFromColorLists;
{
    if ([[self colorSpaceName] isEqualToString:NSNamedColorSpace])
        return [self localizedColorNameComponent];
    else if ([[self colorSpaceName] isEqualToString:NSPatternColorSpace])
        return NSLocalizedStringFromTableInBundle(@"Image", @"OmniAppKit", [OAColorProfile bundle], "generic color name for pattern colors");
    else if ([[self colorSpaceName] isEqualToString:NSCustomColorSpace])
        return NSLocalizedStringFromTableInBundle(@"Custom", @"OmniAppKit", [OAColorProfile bundle], "generic color name for custom colors");

    unsigned int entryCount;
    const OANamedColorEntry *entries = _combinedColorEntries(&entryCount);
    
    if (entryCount == 0) {
	// Avoid crasher below if something goes wrong in building the entries
	OBASSERT_NOT_REACHED("No color entries found");
	return @"";
    }
    
    OANamedColorEntry colorEntry;
    memset(&colorEntry, 0, sizeof(colorEntry));
    NSColor *rgbColor = [self colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    [rgbColor getHue:&colorEntry.h saturation:&colorEntry.s brightness:&colorEntry.v alpha:&colorEntry.a];
    [rgbColor getRed:&colorEntry.r green:&colorEntry.g blue:&colorEntry.B alpha:&colorEntry.a];

    const OANamedColorEntry *closestEntry = &entries[0];
    float closestEntryDistance = 1e9;

    // Entries at the end of the array have higher precedence; loop backwards
    unsigned int entryIndex = entryCount;
    while (entryIndex--) {
	const OANamedColorEntry *entry = &entries[entryIndex];
	float distance = _colorCloseness(&colorEntry, entry);
	if (distance < closestEntryDistance) {
	    closestEntryDistance = distance;
	    closestEntry = entry;
	}
    }

    float brightnessDifference = colorEntry.v - closestEntry->v;
    NSString *brightnessString = nil;
    if (brightnessDifference < -.1 && colorEntry.v < .1)
        brightnessString =  NSLocalizedStringFromTableInBundle(@"Near-black", @"OmniAppKit", [OAColorProfile bundle], "word comparing color brightnesss");
    else if (brightnessDifference < -.2)
        brightnessString =  NSLocalizedStringFromTableInBundle(@"Dark", @"OmniAppKit", [OAColorProfile bundle], "word comparing color brightnesss");
    else if (brightnessDifference < -.1)
        brightnessString =  NSLocalizedStringFromTableInBundle(@"Smokey", @"OmniAppKit", [OAColorProfile bundle], "word comparing color brightnesss");
    else if (brightnessDifference > .1 && colorEntry.v > .9)
        brightnessString =  NSLocalizedStringFromTableInBundle(@"Off-white", @"OmniAppKit", [OAColorProfile bundle], "word comparing color brightnesss");
    else if (brightnessDifference > .2)
        brightnessString =  NSLocalizedStringFromTableInBundle(@"Bright", @"OmniAppKit", [OAColorProfile bundle], "word comparing color brightnesss");
    else if (brightnessDifference > .1)
        brightnessString =  NSLocalizedStringFromTableInBundle(@"Light", @"OmniAppKit", [OAColorProfile bundle], "word comparing color brightnesss");

    // Input saturation less than some value means that the saturation is irrelevant.
    NSString *saturationString = nil;
    if (colorEntry.s > 0.01) {
	float saturationDifference = colorEntry.s - closestEntry->s;
	if (saturationDifference < -0.3)
	    saturationString =  NSLocalizedStringFromTableInBundle(@"Washed-out", @"OmniAppKit", [OAColorProfile bundle], "word comparing color saturations");
	else if (saturationDifference < -.2)
	    saturationString =  NSLocalizedStringFromTableInBundle(@"Faded", @"OmniAppKit", [OAColorProfile bundle], "word comparing color saturations");
	else if (saturationDifference < -.1)
	    saturationString =  NSLocalizedStringFromTableInBundle(@"Mild", @"OmniAppKit", [OAColorProfile bundle], "word comparing color saturations");
	else if (saturationDifference > -0.01 && saturationDifference < 0.01)
	    saturationString = nil;
	else if (saturationDifference < .1)
	    saturationString = nil;
	else if (saturationDifference < .2)
	    saturationString =  NSLocalizedStringFromTableInBundle(@"Rich", @"OmniAppKit", [OAColorProfile bundle], "word comparing color saturations");
	else if (saturationDifference < .3)
	    saturationString =  NSLocalizedStringFromTableInBundle(@"Deep", @"OmniAppKit", [OAColorProfile bundle], "word comparing color saturations");
	else
	    saturationString =  NSLocalizedStringFromTableInBundle(@"Intense", @"OmniAppKit", [OAColorProfile bundle], "word comparing color saturations");
    }
    
    NSString *closestColorDescription = nil;
    if (saturationString != nil && brightnessString != nil)
        closestColorDescription = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%@, %@ %@", @"OmniAppKit", [OAColorProfile bundle], "format string for color with saturation and brightness descriptions"), brightnessString, saturationString, closestEntry->name];
    else if (saturationString != nil)
        closestColorDescription = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%@ %@", @"OmniAppKit", [OAColorProfile bundle], "format string for color with saturation description"), saturationString, closestEntry->name];
    else if (brightnessString != nil)
        closestColorDescription = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%@ %@", @"OmniAppKit", [OAColorProfile bundle], "format string for color with brightness description"), brightnessString, closestEntry->name];
    else
        closestColorDescription = closestEntry->name;

    if (colorEntry.a <= 0.001)
        return NSLocalizedStringFromTableInBundle(@"Clear", @"OmniAppKit", [OAColorProfile bundle], "name of completely transparent color");
    else if (colorEntry.a < .999)
        return [NSString stringWithFormat:@"%d%% %@", (int)(colorEntry.a * 100), closestColorDescription];
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
    // special case clear
    if ([aName isEqualToString:@"Clear"] || [aName isEqualToString:NSLocalizedStringFromTableInBundle(@"Clear", @"OmniAppKit", [OAColorProfile bundle], "name of completely transparent color")])
        return [NSColor clearColor];
    
    unsigned int entryCount;
    const OANamedColorEntry *entries = _combinedColorEntries(&entryCount);
    
    if (entryCount == 0) {
	// Avoid crasher below if something goes wrong in building the entries
	OBASSERT_NOT_REACHED("No color entries found");
	return @"";
    }

    // Entries at the end of the array have higher precedence; loop backwards
    unsigned int entryIndex = entryCount;

    NSColor *baseColor = nil;
    unsigned int longestMatch = 0;
    
    // find base color
    while (entryIndex--) {
	const OANamedColorEntry *entry = &entries[entryIndex];
        NSString *colorKey = entry->name;
        unsigned int length;
        
        if ([aName hasSuffix:colorKey] && (length = [colorKey length]) > longestMatch) {
            baseColor = entry->color;
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
    if ([value isKindOfClass:[NSColor class]])
	return [(NSColor *)value propertyListRepresentation];
    return nil;
}

- (id)reverseTransformedValue:(id)value;
{
    if ([value isKindOfClass:[NSDictionary class]])
	return [NSColor colorFromPropertyListRepresentation:value];
    return nil;
}

@end

#endif
