//
//  NSColor_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 6/17/07.
/*
 This software is Copyright (c) 2007-2009
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


@implementation NSColor (SKExtensions)

typedef union _SKHSBAInt {
    struct {
        uint8_t h;
        uint8_t s;
        uint8_t b;
        uint8_t a;
    } hsba;
    uint32_t uintValue;
} SKHSBAInt;

- (NSComparisonResult)colorCompare:(NSColor *)aColor {
    NSColor *rgbColor1 = [self colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    NSColor *rgbColor2 = [aColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    if (rgbColor1 && rgbColor2) {
        CGFloat h1 = 0.0, s1 = 0.0, b1 = 0.0, a1 = 0.0, h2 = 0.0, s2 = 0.0, b2 = 0.0, a2 = 0.0;
        [rgbColor1 getHue:&h1 saturation:&s1 brightness:&b1 alpha:&a1];
        [rgbColor2 getHue:&h2 saturation:&s2 brightness:&b2 alpha:&a2];
        SKHSBAInt u1, u2;
        u1.hsba.h = (uint8_t)(h1 * 255);
        u1.hsba.s = (uint8_t)(s1 * 255);
        u1.hsba.b = (uint8_t)(b1 * 255);
        u1.hsba.a = (uint8_t)(a1 * 255);
        u2.hsba.h = (uint8_t)(h2 * 255);
        u2.hsba.s = (uint8_t)(s2 * 255);
        u2.hsba.b = (uint8_t)(b2 * 255);
        u2.hsba.a = (uint8_t)(a2 * 255);
        uint32_t value1 = CFSwapInt32HostToBig(u1.uintValue);
        uint32_t value2 = CFSwapInt32HostToBig(u2.uintValue);
        if (value1 < value2)
            return NSOrderedAscending;
        else if (value1 > value2)
            return NSOrderedDescending;
        else
            return NSOrderedSame;
    } else if (rgbColor1) {
        return NSOrderedDescending;
    } else if (rgbColor2) {
        return NSOrderedAscending;
    } else {
        return NSOrderedSame;
    }
}

+ (id)scriptingRgbaColorWithDescriptor:(NSAppleEventDescriptor *)descriptor {
    if ([descriptor numberOfItems] > 0) {
        CGFloat red, green, blue, alpha;
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
    } else {
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
            default:
            {
                // Cocoa Scripting defines coercions from string to color for some standard color names
                NSString *string = [descriptor stringValue];
                if (string) {
                    NSColor *color = [[NSScriptCoercionHandler sharedCoercionHandler] coerceValue:string toClass:[NSColor class]];
                    // We should check the return value, because NSScriptCoercionHandler returns the input when it fails rather than nil, stupid
                    return [color isKindOfClass:[NSColor class]] ? color : nil;
                }
            }
        }
        return nil;
    }
}

- (id)scriptingRgbaColorDescriptor;
{
    CGFloat red, green, blue, alpha;
    [[self colorUsingColorSpaceName:NSCalibratedRGBColorSpace] getRed:&red green:&green blue:&blue alpha:&alpha];
    
    NSAppleEventDescriptor *descriptor = [NSAppleEventDescriptor listDescriptor];
    [descriptor insertDescriptor:[NSAppleEventDescriptor descriptorWithInt32:SKRound(65535 * red)] atIndex:1];
    [descriptor insertDescriptor:[NSAppleEventDescriptor descriptorWithInt32:SKRound(65535 * green)] atIndex:2];
    [descriptor insertDescriptor:[NSAppleEventDescriptor descriptorWithInt32:SKRound(65535 * blue)] atIndex:3];
    [descriptor insertDescriptor:[NSAppleEventDescriptor descriptorWithInt32:SKRound(65535 * alpha)] atIndex:4];
    
    return descriptor;
}

- (NSString *)accessibilityValue {
    static NSColorWell *colorWell = nil;
    if (colorWell == nil)
        colorWell = [[NSColorWell alloc] init];
    [colorWell setColor:self];
    return [colorWell accessibilityAttributeValue:NSAccessibilityValueAttribute];
}

@end
