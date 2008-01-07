//
//  NSColor_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 6/17/07.
/*
 This software is Copyright (c) 2007-2008
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

+ (NSColor *)tableBackgroundColor {
    static NSColor *tableBackgroundColor = nil;
    if (nil == tableBackgroundColor) {
        tableBackgroundColor = [[NSColor colorWithCalibratedRed:0.905882 green:0.929412 blue:0.964706 alpha:1.0] retain];
    }
    return tableBackgroundColor;
}

+ (NSColor *)secondarySelectedTableColor {
    static NSColor *secondarySelectedTableColor = nil;
    if (nil == secondarySelectedTableColor) {
        secondarySelectedTableColor = [self tableBackgroundColor];
        secondarySelectedTableColor = [[NSColor colorWithCalibratedRed:0.724706 green:0.743529 blue:0.771765 alpha:1.0] retain];
    }
    return secondarySelectedTableColor;
}

+ (id)scriptingRgbaColorWithDescriptor:(NSAppleEventDescriptor *)descriptor {
    float red, green, blue, alpha = 1.0;
    switch ([descriptor numberOfItems]) {
        case 0:
            switch ([descriptor enumCodeValue]) {
                case SKASColorRed: return [NSColor redColor];
                case SKASColorGreen: return [NSColor greenColor];
                case SKASColorBlue: return [NSColor blueColor];
                case SKASColorYellow: return [NSColor yellowColor];
                case SKASColorMagenta: return [NSColor magentaColor];
                case SKASColorCyan: return [NSColor cyanColor];
                case SKASColorDarkRed: return [NSColor colorWithCalibratedRed:0.5 green:0.0 blue:0.0 alpha:1.0];
                case SKASColorDarkGreen: return [NSColor colorWithCalibratedRed:0.0 green:0.5 blue:0.0 alpha:1.0];
                case SKASColorDarkBlue: return [NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.5 alpha:1.0];
                case SKASColorBanana: return [NSColor colorWithCalibratedRed:1.0 green:1.0 blue:0.5 alpha:1.0];
                case SKASColorTurquoise: return [NSColor colorWithCalibratedRed:1.0 green:0.5 blue:1.0 alpha:1.0];
                case SKASColorViolet: return [NSColor colorWithCalibratedRed:0.5 green:1.0 blue:1.0 alpha:1.0];
                case SKASColorOrange: return [NSColor orangeColor];
                case SKASColorDeepPink: return [NSColor colorWithCalibratedRed:1.0 green:0.0 blue:0.5 alpha:1.0];
                case SKASColorSpringGreen: return [NSColor colorWithCalibratedRed:0.0 green:1.0 blue:0.5 alpha:1.0];
                case SKASColorAqua: return [NSColor colorWithCalibratedRed:0.0 green:0.5 blue:1.0 alpha:1.0];
                case SKASColorLime: return [NSColor colorWithCalibratedRed:0.5 green:1.0 blue:0.0 alpha:1.0];
                case SKASColorDarkViolet: return [NSColor colorWithCalibratedRed:0.5 green:0.0 blue:1.0 alpha:1.0];
                case SKASColorPurple: return [NSColor purpleColor];
                case SKASColorTeal: return [NSColor colorWithCalibratedRed:0.0 green:0.5 blue:0.5 alpha:1.0];
                case SKASColorOlive: return [NSColor colorWithCalibratedRed:0.5 green:0.5 blue:0.0 alpha:1.0];
                case SKASColorBrown: return [NSColor brownColor];
                case SKASColorBlack: return [NSColor blackColor];
                case SKASColorWhite: return [NSColor whiteColor];
                case SKASColorGray: return [NSColor grayColor];
                case SKASColorDarkGray: return [NSColor darkGrayColor];
                case SKASColorLightGray: return [NSColor lightGrayColor];
                case SKASColorClear: return [NSColor clearColor];
                default: return nil;
            }
            break;
        case 4:
            alpha = (float)[[descriptor descriptorAtIndex:4] int32Value] / 65535.0f;
        case 3:
            red = (float)[[descriptor descriptorAtIndex:1] int32Value] / 65535.0f;
            green = (float)[[descriptor descriptorAtIndex:2] int32Value] / 65535.0f;
            blue = (float)[[descriptor descriptorAtIndex:3] int32Value] / 65535.0f;
            break;
        case 2:
            alpha = (float)[[descriptor descriptorAtIndex:2] int32Value] / 65535.0f;
        case 1:
            red = green = blue = (float)[[descriptor descriptorAtIndex:1] int32Value] / 65535.0f;
            break;
        default:
            return nil;
    }
    return [NSColor colorWithCalibratedRed:red green:green blue:blue alpha:alpha];
}

- (id)scriptingRgbaColorDescriptor;
{
    float red, green, blue, alpha;
    [[self colorUsingColorSpaceName:NSCalibratedRGBColorSpace] getRed:&red green:&green blue:&blue alpha:&alpha];
    
    NSAppleEventDescriptor *descriptor = [NSAppleEventDescriptor listDescriptor];
    [descriptor insertDescriptor:[NSAppleEventDescriptor descriptorWithInt32:round(65535 * red)] atIndex:1];
    [descriptor insertDescriptor:[NSAppleEventDescriptor descriptorWithInt32:round(65535 * green)] atIndex:2];
    [descriptor insertDescriptor:[NSAppleEventDescriptor descriptorWithInt32:round(65535 * blue)] atIndex:3];
    [descriptor insertDescriptor:[NSAppleEventDescriptor descriptorWithInt32:round(65535 * alpha)] atIndex:4];
    
    return descriptor;
}

@end
