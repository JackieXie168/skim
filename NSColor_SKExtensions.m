//
//  NSColor_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 6/17/07.
/*
 This software is Copyright (c) 2007-2020
 Christiaan Hofman. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

 - Neither the name of Christiaan Hofman nor the names of any
    contributors may be used to endorse or promote products derived
    from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "NSColor_SKExtensions.h"
#import "SKRuntime.h"
#import "NSGraphics_SKExtensions.h"

@interface SKDynamicColor : NSColor {
    NSColor *aquaColor;
    NSColor *darkAquaColor;
}
- (id)initWithAquaColor:(NSColor *)aAquaColor darkAquaColor:(NSColor *)aDarkAquaColor;
@end

#pragma mark -

@implementation NSColor (SKExtensions)

- (CGColorRef)fallback_CGColor {
    NSColor *color = self;
    static NSSet *componentColorSpaces = nil;
    if (componentColorSpaces == nil)
        componentColorSpaces = [[NSSet alloc] initWithObjects:NSCalibratedRGBColorSpace, NSDeviceRGBColorSpace, NSCalibratedWhiteColorSpace, NSDeviceWhiteColorSpace, NSDeviceCMYKColorSpace, nil];
    if ([componentColorSpaces containsObject:[self colorSpaceName]] == NO)
        color = [self colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    const NSInteger numberOfComponents = [color numberOfComponents];
    CGFloat components[numberOfComponents];
    CGColorSpaceRef colorSpace = [[color colorSpace] CGColorSpace];
    [color getComponents:(CGFloat *)&components];
    return (CGColorRef)[(id)CGColorCreate(colorSpace, components) autorelease];
}

+ (void)load {
    SKAddInstanceMethodImplementationFromSelector(self, @selector(CGColor), @selector(fallback_CGColor));
}

static NSColor *activeSelectionHighlightColor = nil;
static NSColor *inactiveSelectionHighlightColor = nil;
static NSColor *activeSelectionHighlightInteriorColor = nil;
static NSColor *inactiveSelectionHighlightInteriorColor = nil;

+ (void)handleSystemColorsDidChange:(NSNotification *)notification {
    __block NSColor *activeOut = nil;
    __block NSColor *inactiveOut = nil;
    __block NSColor *activeIn = nil;
    __block NSColor *inactiveIn = nil;
    SKRunWithLightAppearance(^{
        activeOut = [[NSColor alternateSelectedControlColor] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
        inactiveOut = [[NSColor disabledControlTextColor] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
        activeIn = [[NSColor selectedControlColor] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
        inactiveIn = [[NSColor secondarySelectedControlColor] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    });
    @synchronized (self) {
        [activeSelectionHighlightColor release];
        activeSelectionHighlightColor = [activeOut retain];
        [inactiveSelectionHighlightColor release];
        inactiveSelectionHighlightColor = [inactiveOut retain];
        [activeSelectionHighlightInteriorColor release];
        activeSelectionHighlightInteriorColor = [activeIn retain];
        [inactiveSelectionHighlightInteriorColor release];
        inactiveSelectionHighlightInteriorColor = [inactiveIn retain];
    }
}

+ (void)makeColors {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSystemColorsDidChange:) name:NSSystemColorsDidChangeNotification object:nil];
    [self handleSystemColorsDidChange:nil];
}

+ (NSColor *)colorWithAquaColor:(NSColor *)aAquaColor darkAquaColor:(NSColor *)aDarkAquaColor {
    if (RUNNING_AFTER(10_13))
        return [[[SKDynamicColor alloc] initWithAquaColor:aAquaColor darkAquaColor:aDarkAquaColor] autorelease];
    return aAquaColor;
}

+ (NSColor *)colorWithCalibratedAquaWhite:(CGFloat)aquaWhite alpha:(CGFloat)aquaAlpha darkAquaWhite:(CGFloat)darkAquaWhite alpha:(CGFloat)darkAquaAlpha {
    return [self colorWithAquaColor:[NSColor colorWithCalibratedWhite:aquaWhite alpha:aquaAlpha] darkAquaColor:[NSColor colorWithCalibratedWhite:darkAquaWhite alpha:darkAquaAlpha]];
}

+ (NSColor *)colorWithCalibratedAquaRed:(CGFloat)aquaRed green:(CGFloat)aquaGreen blue:(CGFloat)aquaBlue alpha:(CGFloat)aquaAlpha darkAquaRed:(CGFloat)darkAquaRed green:(CGFloat)darkAquaGreen blue:(CGFloat)darkAquaBlue alpha:(CGFloat)darkAquaAlpha {
    return [self colorWithAquaColor:[NSColor colorWithCalibratedRed:aquaRed green:aquaGreen blue:aquaBlue alpha:aquaAlpha] darkAquaColor:[NSColor colorWithCalibratedRed:darkAquaRed green:darkAquaGreen blue:darkAquaBlue alpha:darkAquaAlpha]];
}

+ (NSColor *)keySourceListHighlightColor {
    static NSColor *color = nil;
    static NSColor *graphiteColor = nil;
    if ([NSColor currentControlTint] == NSGraphiteControlTint) {
        if (graphiteColor == nil)
            graphiteColor = [[NSColor colorWithCalibratedRed:0.555 green:0.555 blue:0.578 alpha:1.0] retain];
        return graphiteColor;
    } else {
        if (color == nil)
            color = [[NSColor colorWithCalibratedRed:0.251 green:0.487 blue:0.780 alpha:1.0] retain];
        return color;
    }
}

+ (NSColor *)mainSourceListHighlightColor {
    static NSColor *color = nil;
    static NSColor *graphiteColor = nil;
    if ([NSColor currentControlTint] == NSGraphiteControlTint) {
        if (graphiteColor == nil)
            graphiteColor = [[NSColor colorWithCalibratedRed:0.572 green:0.627 blue:0.680 alpha:1.0] retain];
        return graphiteColor;
    } else {
        if (color == nil)
            color = [[NSColor colorWithCalibratedRed:0.556 green:0.615 blue:0.748 alpha:1.0] retain];
        return color;
    }
}

+ (NSColor *)disabledSourceListHighlightColor {
    static NSColor *color = nil;
    static NSColor *graphiteColor = nil;
    if ([NSColor currentControlTint] == NSGraphiteControlTint) {
        if (graphiteColor == nil)
            graphiteColor = [[NSColor colorWithCalibratedRed:0.576 green:0.576 blue:0.576 alpha:1.0] retain];
        return graphiteColor;
    } else {
        if (color == nil)
            color = [[NSColor colorWithCalibratedRed:0.576 green:0.576 blue:0.576 alpha:1.0] retain];
        return color;
    }
}

// @@ Dark mode

+ (NSColor *)mainSourceListBackgroundColor {
    static NSColor *color = nil;
    if (color == nil)
        color = [[NSColor colorWithCalibratedAquaRed:0.839216 green:0.866667 blue:0.898039 alpha:1.0 darkAquaRed:0.211765 green:0.215686 blue:0.223529 alpha:1.0] retain];
    return color;
}

+ (NSColor *)selectionHighlightColor:(BOOL)active {
    NSColor *color = nil;
    @synchronized (self) {
        color = [active ? activeSelectionHighlightColor : inactiveSelectionHighlightColor retain];
    }
    return [color autorelease];
}

+ (NSColor *)selectionHighlightInteriorColor:(BOOL)active {
    NSColor *color = nil;
    @synchronized (self) {
        color = [active ? activeSelectionHighlightInteriorColor : inactiveSelectionHighlightInteriorColor retain];
    }
    return [color autorelease];
}

+ (NSColor *)pdfControlBackgroundColor {
    static NSColor *color = nil;
    if (color == nil) {
        color = [[NSColor colorWithCalibratedAquaWhite:0.95 alpha:0.95 darkAquaWhite:0.125 alpha:0.95] retain];
    }
    return color;
}

- (uint32_t)uint32HSBAValue {
    NSColor *rgbColor = [self colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    if (rgbColor) {
        CGFloat h = 0.0, s = 0.0, b = 0.0, a = 0.0;
        [rgbColor getHue:&h saturation:&s brightness:&b alpha:&a];
        union _ {
            struct {
                uint8_t h;
                uint8_t s;
                uint8_t b;
                uint8_t a;
            } hsba;
            uint32_t uintValue;
        } u;
        u.hsba.h = (uint8_t)(h * 255);
        u.hsba.s = (uint8_t)(s * 255);
        u.hsba.b = (uint8_t)(b * 255);
        u.hsba.a = (uint8_t)(a * 255);
        return CFSwapInt32HostToBig(u.uintValue);
    }
    return 0;
}

- (NSComparisonResult)colorCompare:(NSColor *)aColor {
    uint32_t value1 = [self uint32HSBAValue];
    uint32_t value2 = [aColor uint32HSBAValue];
    if (value1 < value2)
        return NSOrderedAscending;
    else if (value1 > value2)
        return NSOrderedDescending;
    else
        return NSOrderedSame;
}

- (CGFloat)luminance {
    CGFloat c[4];
    [[self colorUsingColorSpaceName:NSCalibratedRGBColorSpace] getComponents:c];
    NSUInteger i;
    for (i = 0; i < 3; i++)
        c[i] = c[i] <= 0.03928 ? c[i] / 12.92 : pow((c[i] + 0.055) / 1.055, 2.4);
    return 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2];
}

- (void)drawSwatchInRoundedRect:(NSRect)rect {
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:rect xRadius:3.0 yRadius:3.0];
    [path setLineWidth:2.0];
    [path addClip];
    [self drawSwatchInRect:rect];
    [[NSColor colorWithCalibratedWhite:0.0 alpha:0.3] setStroke];
    [path stroke];
}

+ (id)scriptingRgbaColorWithDescriptor:(NSAppleEventDescriptor *)descriptor {
    if ([descriptor descriptorType] == typeAEList) {
        CGFloat red = 0.0, green = 0.0, blue = 0.0, alpha = 0.0;
        if ([descriptor numberOfItems] > 0)
            red = green = blue = (CGFloat)[[descriptor descriptorAtIndex:1] int32Value] / 65535.0f;
        if ([descriptor numberOfItems] > 2) {
            green = (CGFloat)[[descriptor descriptorAtIndex:2] int32Value] / 65535.0f;
            blue = (CGFloat)[[descriptor descriptorAtIndex:3] int32Value] / 65535.0f;
        }
        if ([descriptor numberOfItems] == 2)
            alpha = (CGFloat)[[descriptor descriptorAtIndex:2] int32Value] / 65535.0f;
        else if ([descriptor numberOfItems] > 3)
            alpha = (CGFloat)[[descriptor descriptorAtIndex:4] int32Value] / 65535.0f;
        else
            alpha= 1.0;
        return [NSColor colorWithCalibratedRed:red green:green blue:blue alpha:alpha];
    } else if ([descriptor descriptorType] == typeEnumerated) {
        switch ([descriptor enumCodeValue]) {
            case SKScriptingColorRed: return [NSColor redColor];
            case SKScriptingColorGreen: return [NSColor greenColor];
            case SKScriptingColorBlue: return [NSColor blueColor];
            case SKScriptingColorYellow: return [NSColor yellowColor];
            case SKScriptingColorMagenta: return [NSColor magentaColor];
            case SKScriptingColorCyan: return [NSColor cyanColor];
            case SKScriptingColorDarkRed: return [NSColor colorWithCalibratedRed:0.5 green:0.0 blue:0.0 alpha:1.0];
            case SKScriptingColorDarkGreen: return [NSColor colorWithCalibratedRed:0.0 green:0.5 blue:0.0 alpha:1.0];
            case SKScriptingColorDarkBlue: return [NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.5 alpha:1.0];
            case SKScriptingColorBanana: return [NSColor colorWithCalibratedRed:1.0 green:1.0 blue:0.5 alpha:1.0];
            case SKScriptingColorTurquoise: return [NSColor colorWithCalibratedRed:1.0 green:0.5 blue:1.0 alpha:1.0];
            case SKScriptingColorViolet: return [NSColor colorWithCalibratedRed:0.5 green:1.0 blue:1.0 alpha:1.0];
            case SKScriptingColorOrange: return [NSColor orangeColor];
            case SKScriptingColorDeepPink: return [NSColor colorWithCalibratedRed:1.0 green:0.0 blue:0.5 alpha:1.0];
            case SKScriptingColorSpringGreen: return [NSColor colorWithCalibratedRed:0.0 green:1.0 blue:0.5 alpha:1.0];
            case SKScriptingColorAqua: return [NSColor colorWithCalibratedRed:0.0 green:0.5 blue:1.0 alpha:1.0];
            case SKScriptingColorLime: return [NSColor colorWithCalibratedRed:0.5 green:1.0 blue:0.0 alpha:1.0];
            case SKScriptingColorDarkViolet: return [NSColor colorWithCalibratedRed:0.5 green:0.0 blue:1.0 alpha:1.0];
            case SKScriptingColorPurple: return [NSColor purpleColor];
            case SKScriptingColorTeal: return [NSColor colorWithCalibratedRed:0.0 green:0.5 blue:0.5 alpha:1.0];
            case SKScriptingColorOlive: return [NSColor colorWithCalibratedRed:0.5 green:0.5 blue:0.0 alpha:1.0];
            case SKScriptingColorBrown: return [NSColor brownColor];
            case SKScriptingColorBlack: return [NSColor blackColor];
            case SKScriptingColorWhite: return [NSColor whiteColor];
            case SKScriptingColorGray: return [NSColor grayColor];
            case SKScriptingColorDarkGray: return [NSColor darkGrayColor];
            case SKScriptingColorLightGray: return [NSColor lightGrayColor];
            case SKScriptingColorClear: return [NSColor clearColor];
            default: return nil;
        }
    } else {
        NSString *string = nil;
        if ([descriptor descriptorType] == typeObjectSpecifier)
            string = [[descriptor descriptorForKeyword:keyAEKeyData] stringValue];
        else
            string = [descriptor stringValue];
        // Cocoa Scripting defines coercions from string to color for some standard color names
        NSColor *color = string ? [[NSScriptCoercionHandler sharedCoercionHandler] coerceValue:string toClass:[NSColor class]] : nil;
        // We should check the return value, because NSScriptCoercionHandler returns the input when it fails rather than nil, stupid
        return [color isKindOfClass:[NSColor class]] ? color : nil;
    }
}

- (id)scriptingRgbaColorDescriptor;
{
    CGFloat red, green, blue, alpha;
    [[self colorUsingColorSpaceName:NSCalibratedRGBColorSpace] getRed:&red green:&green blue:&blue alpha:&alpha];
    
    NSAppleEventDescriptor *descriptor = [NSAppleEventDescriptor listDescriptor];
    [descriptor insertDescriptor:[NSAppleEventDescriptor descriptorWithInt32:round(65535 * red)] atIndex:1];
    [descriptor insertDescriptor:[NSAppleEventDescriptor descriptorWithInt32:round(65535 * green)] atIndex:2];
    [descriptor insertDescriptor:[NSAppleEventDescriptor descriptorWithInt32:round(65535 * blue)] atIndex:3];
    [descriptor insertDescriptor:[NSAppleEventDescriptor descriptorWithInt32:round(65535 * alpha)] atIndex:4];
    
    return descriptor;
}

- (NSString *)accessibilityValue {
    static NSColorWell *colorWell = nil;
    if (colorWell == nil)
        colorWell = [[NSColorWell alloc] init];
    [colorWell setColor:self];
    return [colorWell accessibilityAttributeValue:NSAccessibilityValueAttribute];
}

- (NSString *)hexString {
    NSColor *rgbColor = [self colorUsingColorSpace:[NSColorSpace sRGBColorSpace]];
    if (rgbColor) {
        CGFloat r = 0.0, g = 0.0, b = 0.0, a = 0.0;
        [rgbColor getRed:&r green:&g blue:&b alpha:&a];
        return [NSString stringWithFormat:@"#%02x%02x%02x", (unsigned int)(r * 255), (unsigned int)(g * 255), (unsigned int)(b * 255)];
    }
    return nil;
}

- (NSString *)rgbString {
    NSColor *rgbColor = [self colorUsingColorSpace:[NSColorSpace sRGBColorSpace]];
    if (rgbColor) {
        CGFloat r = 0.0, g = 0.0, b = 0.0, a = 0.0;
        [rgbColor getRed:&r green:&g blue:&b alpha:&a];
        return [NSString stringWithFormat:@"(%u, %u, %u)", (unsigned int)(r * 255), (unsigned int)(g * 255), (unsigned int)(b * 255)];
    }
    return nil;
}

@end

#pragma mark -

@implementation SKDynamicColor

#define FORWARD( PROP, TYPE ) - (TYPE)PROP { return [[self effectiveColor] PROP]; }

- (id)initWithAquaColor:(NSColor *)aAquaColor darkAquaColor:(NSColor *)aDarkAquaColor {
    self = [super init];
    if (self) {
        aquaColor = [aAquaColor retain];
        darkAquaColor = [aDarkAquaColor retain];
    }
    return self;
}

- (void)dealloc {
    SKDESTROY(aquaColor);
    SKDESTROY(darkAquaColor);
    [super dealloc];
}

- (BOOL)isEqual:(id)other {
    if ([other isMemberOfClass:[self class]] == NO)
        return NO;
    return [aquaColor isEqual:((SKDynamicColor *)other)->aquaColor] && [darkAquaColor isEqual:((SKDynamicColor *)other)->darkAquaColor];
}

- (NSUInteger)hash {
    return [aquaColor hash] + 31 * [darkAquaColor hash];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"light = %@, dark = %@", aquaColor, darkAquaColor];
}

- (NSColor *)effectiveColor {
    return SKHasDarkAppearance(nil) ? darkAquaColor : aquaColor;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [[self effectiveColor] encodeWithCoder:aCoder];
}

- (void)set {
    [[self effectiveColor] set];
}

- (void)setStroke {
    [[self effectiveColor] setStroke];
}

- (void)setFill {
    [[self effectiveColor] setFill];
}

- (void)getWhite:(CGFloat *)white alpha:(CGFloat *)alpha {
    [[self effectiveColor] getWhite:white alpha:alpha];
}

- (void)getRed:(CGFloat *)red green:(CGFloat *)green blue:(CGFloat *)blue alpha:(CGFloat *)alpha {
    [[self effectiveColor] getRed:red green:green blue:blue alpha:alpha];
}

- (void)getHue:(CGFloat *)hue saturation:(CGFloat *)saturation brightness:(CGFloat *)brightness alpha:(CGFloat *)alpha {
    [[self effectiveColor] getHue:hue saturation:saturation brightness:brightness alpha:alpha];
}

- (void)getCyan:(CGFloat *)cyan magenta:(CGFloat *)magenta yellow:(CGFloat *)yellow black:(CGFloat *)black alpha:(CGFloat *)alpha {
    [[self effectiveColor] getCyan:cyan magenta:magenta yellow:yellow black:black alpha:alpha];
}

- (void)getComponents:(CGFloat *)components {
    [[self effectiveColor] getComponents:components];
}

- (NSColor *)colorWithAlphaComponent:(CGFloat)alpha {
    return [[self effectiveColor] colorWithAlphaComponent:alpha];
}

- (NSColor *)blendedColorWithFraction:(CGFloat)fraction ofColor:(NSColor *)color {
    return [[self effectiveColor] blendedColorWithFraction:fraction ofColor:color];
}

- (NSColor *)colorUsingColorSpace:(NSColorSpace *)space {
    return [[self effectiveColor] colorUsingColorSpace:space];
}

- (NSColor *)colorUsingColorSpaceName:(NSString *)name device:(NSDictionary *)deviceDescription {
    return [[self effectiveColor] colorUsingColorSpaceName:name device:deviceDescription];
}

- (NSColor *)colorUsingColorSpaceName:(NSString *)name {
    return [[self effectiveColor] colorUsingColorSpaceName:name];
}

FORWARD(classForCoder, Class)

FORWARD(colorSpace, NSColorSpace *)
FORWARD(colorSpaceName, NSString *)

FORWARD(numberOfComponents, NSInteger)

FORWARD(alphaComponent, CGFloat)
FORWARD(whiteComponent, CGFloat)
FORWARD(redComponent, CGFloat)
FORWARD(greenComponent, CGFloat)
FORWARD(blueComponent, CGFloat)
FORWARD(hueComponent, CGFloat)
FORWARD(saturationComponent, CGFloat)
FORWARD(brightnessComponent, CGFloat)
FORWARD(blackComponent, CGFloat)
FORWARD(cyanComponent, CGFloat)
FORWARD(magentaComponent, CGFloat)
FORWARD(yellowComponent, CGFloat)

@end
