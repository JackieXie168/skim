//
//  SKTextWithIconCell.m
//  Skim
//
//  Created by Christiaan Hofman on 9/13/07.
/*
 This software is Copyright (c) 2007-2014
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

#import "SKTextWithIconCell.h"
#import "SKDictionaryFormatter.h"
#import "NSImage_SKExtensions.h"
#import "NSGeometry_SKExtensions.h"
#import "NSEvent_SKExtensions.h"

NSString *SKTextWithIconStringKey = @"string";
NSString *SKTextWithIconImageKey = @"image";

#define BORDER_BETWEEN_EDGE_AND_IMAGE (2.0)
#define BORDER_BETWEEN_IMAGE_AND_TEXT (2.0)
#define IMAGE_OFFSET (1.0)

@implementation SKTextWithIconCell

static SKDictionaryFormatter *textWithIconCellFormatter = nil;

+ (void)initialize {
    SKINITIALIZE;
    textWithIconCellFormatter = [[SKDictionaryFormatter alloc] initWithKey:SKTextWithIconStringKey];
}

- (void)commonInit {
    imageCell = [[NSImageCell alloc] init];
    [imageCell setImageScaling:NSImageScaleProportionallyUpOrDown];
    if ([self formatter] == nil)
        [self setFormatter:textWithIconCellFormatter];
}

- (id)initTextCell:(NSString *)aString {
    self = [super initTextCell:aString];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    SKTextWithIconCell *copy = [super copyWithZone:zone];
    copy->imageCell = [imageCell copyWithZone:zone];
    return copy;
}

- (void)dealloc {
    SKDESTROY(imageCell);
    [super dealloc];
}

- (NSSize)cellSizeForBounds:(NSRect)aRect {
    NSSize cellSize = [super cellSizeForBounds:aRect];
    cellSize.width += cellSize.height - 1 + BORDER_BETWEEN_EDGE_AND_IMAGE + BORDER_BETWEEN_IMAGE_AND_TEXT;
    cellSize.width = fmin(cellSize.width, NSWidth(aRect));
    return cellSize;
}

- (NSRect)textRectForBounds:(NSRect)aRect {
    return SKShrinkRect(aRect, NSHeight(aRect) - 1 + BORDER_BETWEEN_EDGE_AND_IMAGE + BORDER_BETWEEN_IMAGE_AND_TEXT, NSMinXEdge);
}

- (NSRect)iconRectForBounds:(NSRect)aRect {
    return SKSliceRect(SKShrinkRect(aRect, BORDER_BETWEEN_EDGE_AND_IMAGE, NSMinXEdge), NSHeight(aRect) - 1, NSMinXEdge);
}

- (void)drawInteriorWithFrame:(NSRect)aRect inView:(NSView *)controlView {
    // let super draw the text
    NSRect textRect = [self textRectForBounds:aRect];
    [super drawInteriorWithFrame:textRect inView:controlView];
    
    // Draw the image
    NSRect imageRect = [self iconRectForBounds:aRect];
    imageRect = SKCenterRectVertically(imageRect, NSWidth(imageRect), [controlView isFlipped]);
    imageRect.origin.y += [controlView isFlipped] ? -IMAGE_OFFSET : IMAGE_OFFSET;
    [imageCell drawInteriorWithFrame:imageRect inView:controlView];
}

- (void)editWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject event:(NSEvent *)theEvent {
    [super editWithFrame:[self textRectForBounds:aRect] inView:controlView editor:textObj delegate:anObject event:theEvent];
}

- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(NSInteger)selStart length:(NSInteger)selLength {
    [super selectWithFrame:[self textRectForBounds:aRect] inView:controlView editor:textObj delegate:anObject start:selStart length:selLength];
}

- (NSUInteger)hitTestForEvent:(NSEvent *)event inRect:(NSRect)cellFrame ofView:(NSView *)controlView {
    NSRect textRect = [self textRectForBounds:cellFrame];
    NSPoint mouseLoc = [event locationInView:controlView];
    NSUInteger hit = NSCellHitNone;
    if (NSMouseInRect(mouseLoc, textRect, [controlView isFlipped]))
        hit = [super hitTestForEvent:event inRect:textRect ofView:controlView];
    else if (NSMouseInRect(mouseLoc, [self iconRectForBounds:cellFrame], [controlView isFlipped]))
        hit = NSCellHitContentArea;
    return hit;
}

- (void)setObjectValue:(id <NSCopying>)obj {
    [super setObjectValue:obj];
    if ([(id)obj respondsToSelector:@selector(objectForKey:)])
        [imageCell setImage:[(id)obj objectForKey:SKTextWithIconImageKey]];
}

- (NSImage *)icon {
    return [imageCell image];
}

@end
