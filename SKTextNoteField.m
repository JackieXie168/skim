//
//  SKTextNoteField.m
//  Skim
//
//  Created by Christiaan Hofman on 10/31/13.
/*
 This software is Copyright (c)2013-2014
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

#import "SKTextNoteField.h"
#import "NSColor_SKExtensions.h"
#import "NSUserDefaults_SKExtensions.h"
#import "SKStringConstants.h"


@implementation SKTextNoteField

+ (Class)cellClass { return [SKTextNoteFieldCell class]; }

- (BOOL)isOpaque { return YES; }

- (void)drawRect:(NSRect)rect {
    [([[NSUserDefaults standardUserDefaults] colorForKey:SKPageBackgroundColorKey] ?: [NSColor whiteColor]) setFill];
    NSRectFill([self bounds]);
    [super drawRect:rect];
}

@end


@implementation SKTextNoteFieldCell

@synthesize scaleFactor, lineWidth, dashPattern;

- (id)initTextCell:(NSString *)aString {
    self = [super initTextCell:aString];
    if (self) {
        scaleFactor = 1.0;
        lineWidth = 0.0;
        dashPattern = nil;
    }
    return self;
}

- (void)setScaleFactor:(CGFloat)newScaleFactor {
    scaleFactor = newScaleFactor;
    [(NSControl *)[self controlView] updateCell:self];
}

- (void)setLineWidth:(CGFloat)newLineWidth {
    lineWidth = newLineWidth;
    [(NSControl *)[self controlView] updateCell:self];
}

- (void)setDashPattern:(NSArray *)newDashPattern {
    if (dashPattern != newDashPattern) {
        [dashPattern release];
        dashPattern = [newDashPattern copy];
        [(NSControl *)[self controlView] updateCell:self];
    }
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    [NSGraphicsContext saveGraphicsState];
    
    [[self backgroundColor] setFill];
    [NSBezierPath fillRect:cellFrame];
    
    CGFloat width = [self lineWidth] / [self scaleFactor];
    if (width > 0.0) {
        NSBezierPath *path = [NSBezierPath bezierPathWithRect:NSInsetRect(cellFrame, 0.5 * width, 0.5 * width)];
        NSUInteger count = [[self dashPattern] count];
        if (count > 0) {
            if ([controlView isFlipped]) {
                path = [NSBezierPath bezierPath];
                [path moveToPoint:NSMakePoint(NSMinX(cellFrame) + 0.5 * width, NSMaxY(cellFrame) - 0.5 * width)];
                [path lineToPoint:NSMakePoint(NSMaxY(cellFrame) - 0.5 * width, NSMaxY(cellFrame) - 0.5 * width)];
                [path lineToPoint:NSMakePoint(NSMaxY(cellFrame) - 0.5 * width, NSMinY(cellFrame) + 0.5 * width)];
                [path lineToPoint:NSMakePoint(NSMinX(cellFrame) + 0.5 * width, NSMinY(cellFrame) + 0.5 * width)];
                [path closePath];
            }
            NSUInteger i;
            CGFloat pattern[count];
            for (i = 0; i < count; i++)
                pattern[i] = [[[self dashPattern] objectAtIndex:i] doubleValue] / [self scaleFactor];
            [path setLineDash:pattern count:count phase:0.0];
        }
        [path setLineWidth:width];
        [[NSColor blackColor] setStroke];
        [path stroke];
    }
    
    [[self showsFirstResponder] ? [NSColor selectionHighlightColor] : [NSColor disabledSelectionHighlightColor] setFill];
    NSFrameRectWithWidth(cellFrame, 1.0 / [self scaleFactor]);
    
    [NSGraphicsContext restoreGraphicsState];
    
    [self drawInteriorWithFrame:cellFrame inView:controlView];
}

@end
