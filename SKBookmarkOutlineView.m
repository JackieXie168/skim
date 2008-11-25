//
//  SKBookmarkOutlineView.m
//  Skim
//
//  Created by Christiaan Hofman on 7/2/08.
/*
 This software is Copyright (c) 2008
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

#import "SKBookmarkOutlineView.h"


@implementation SKBookmarkOutlineView

+ (BOOL)usesDefaultFontSize { return YES; }

#define SEPARATOR_LEFT_INDENT 20.0
#define SEPARATOR_RIGHT_INDENT 2.0

- (void)drawRow:(int)rowIndex clipRect:(NSRect)clipRect {
    if ([[self delegate] respondsToSelector:@selector(outlineView:drawSeparatorRowForItem:)] &&
        [[self delegate] outlineView:self drawSeparatorRowForItem:[self itemAtRow:rowIndex]]) {
        float indent = [self levelForItem:[self itemAtRow:rowIndex]] * [self indentationPerLevel];
        NSRect rect = [self rectOfRow:rowIndex];
        [[NSColor gridColor] setStroke];
        [NSBezierPath setDefaultLineWidth:1.0];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(rect) + indent + SEPARATOR_LEFT_INDENT, floorf(NSMidY(rect)) + 0.5) toPoint:NSMakePoint(NSMaxX(rect) - SEPARATOR_RIGHT_INDENT, floorf(NSMidY(rect)) + 0.5)];
    } else {
        [super drawRow:rowIndex clipRect:clipRect];
    }
}

@end
