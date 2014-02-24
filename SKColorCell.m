//
//  SKColorCell.m
//  Skim
//
//  Created by Christiaan Hofman on 10/5/09.
/*
 This software is Copyright (c) 2009-2014
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

- (NSSize)cellSizeForBounds:(NSRect)aRect {
    return NSMakeSize(fmin(16.0, NSWidth(aRect)), fmin(16.0, NSHeight(aRect)));
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    NSColor *color = [self objectValue];
    if ([color respondsToSelector:@selector(drawSwatchInRect:)]) {
        color = [color colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
        NSRect rect = NSInsetRect(cellFrame, 1.0, 1.0);
        CGFloat height = fmin(NSWidth(rect), NSHeight(rect));
        CGFloat offset = 0.5 * (NSHeight(rect) - height);
        rect.origin.y += [controlView isFlipped] ? floor(offset) - 1.0 : ceil(offset) + 1.0;
        rect.size.height = height;
        [NSGraphicsContext saveGraphicsState];
        [color drawSwatchInRoundedRect:rect];
        [NSGraphicsContext restoreGraphicsState];
    }
}

- (id)accessibilityValueAttribute {
    return [[self objectValue] respondsToSelector:@selector(accessibilityValue)] ? [[self objectValue] accessibilityValue] : nil;
}

@end
