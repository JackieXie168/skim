//
//  SKSeparatorView.m
//  Skim
//
//  Created by Christiaan Hofman on 9/25/09.
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

#import "SKSeparatorView.h"
#import "NSGeometry_SKExtensions.h"

#define SEPARATOR_LEFT_INDENT 4.0
#define SEPARATOR_RIGHT_INDENT 2.0


@implementation SKSeparatorView

@synthesize indentation;

+ (void)drawSeparatorInRect:(NSRect)rect {
    if (NSWidth(rect) > SEPARATOR_LEFT_INDENT + SEPARATOR_RIGHT_INDENT) {
        [NSGraphicsContext saveGraphicsState];
        [[NSColor gridColor] setStroke];
        [NSBezierPath setDefaultLineWidth:2.0];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(rect) + SEPARATOR_LEFT_INDENT, ceil(NSMidY(rect)) - 1.0) toPoint:NSMakePoint(NSMaxX(rect) - SEPARATOR_RIGHT_INDENT, ceil(NSMidY(rect)) - 1.0)];
        [NSBezierPath setDefaultLineWidth:1.0];
        [NSGraphicsContext restoreGraphicsState];
    }
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    [[self class] drawSeparatorInRect:SKShrinkRect([self bounds], [self indentation], NSMinXEdge)];
}

@end

