//
//  SKColorCell.m
//  Skim
//
//  Created by Christiaan Hofman on 10/5/09.
/*
 This software is Copyright (c) 2009-2020
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

#import "SKColorCell.h"
#import "NSColor_SKExtensions.h"


@implementation SKColorCell

@synthesize shouldFill;

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
    if (self) {
        color = [[decoder decodeObjectForKey:@"color"] retain];
        shouldFill = [decoder decodeBoolForKey:@"shouldFill"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:color forKey:@"color"];
    [coder encodeBool:shouldFill forKey:@"shouldFill"];
}

- (void)dealloc {
    SKDESTROY(color);
    [super dealloc];
}

- (void)setObjectValue:(id)anObject {
    if ([anObject isKindOfClass:[NSColor class]]) {
        if (color != anObject) {
            [color release];
            color = [anObject retain];
        }
    } else {
        [super setObjectValue:anObject];
    }
}

- (NSSize)cellSizeForBounds:(NSRect)aRect {
    return NSMakeSize(fmin(16.0, NSWidth(aRect)), fmin(16.0, NSHeight(aRect)));
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    NSColor *safeColor = [color colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    [NSGraphicsContext saveGraphicsState];
    if ([self shouldFill] == NO) {
        NSRect rect = NSInsetRect(cellFrame, 1.0, 1.0);
        CGFloat height = fmin(NSWidth(rect), NSHeight(rect));
        CGFloat offset = 0.5 * (NSHeight(rect) - height);
        rect.origin.y += [controlView isFlipped] ? floor(offset) - 1.0 : ceil(offset) + 1.0;
        rect.size.height = height;
        [safeColor drawSwatchInRoundedRect:rect];
    } else if ([safeColor alphaComponent] > 0.0) {
        [safeColor drawSwatchInRect:cellFrame];
    } else {
        [[NSColor whiteColor] setFill];
        [[NSColor redColor] setStroke];
        [NSBezierPath fillRect:cellFrame];
        [NSBezierPath setDefaultLineWidth:2.0];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(cellFrame), NSMinY(cellFrame)) toPoint:NSMakePoint(NSMaxX(cellFrame), NSMaxY(cellFrame))];
        [NSBezierPath setDefaultLineWidth:1.0];
    }
    [NSGraphicsContext restoreGraphicsState];
}

- (id)accessibilityValueAttribute {
    return [color accessibilityValue];
}

@end
