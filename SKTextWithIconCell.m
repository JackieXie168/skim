//
//  SKTextWithIconCell.m
//  Skim
//
//  Created by Christiaan Hofman on 9/13/07.
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

#import "SKTextWithIconCell.h"
#import "NSImage_SKExtensions.h"

// Almost all of this code is copy-and-paste from OmniAppKit/OATextWithIconCell, with some simplifications for features we're not interested in

NSString *SKTextWithIconCellImageKey = @"image";
NSString *SKTextWithIconCellStringKey = @"string";

#define BORDER_BETWEEN_EDGE_AND_IMAGE (2.0)
#define BORDER_BETWEEN_IMAGE_AND_TEXT (2.0)

@implementation SKTextWithIconCell

// Init and dealloc

- (id)init {
    if (self = [super initTextCell:@""]) {
        [self setEditable:YES];
        [self setScrollable:YES];
    }
    return self;
}

- (void)dealloc {
    [icon release];
    [super dealloc];
}

// NSCopying protocol

- (id)copyWithZone:(NSZone *)zone {
    SKTextWithIconCell *copy = [super copyWithZone:zone];
    copy->icon = [icon retain];
    return copy;
}

- (NSSize)cellSize {
    NSSize cellSize = [super cellSize];
    cellSize.width += [icon size].width + BORDER_BETWEEN_EDGE_AND_IMAGE + BORDER_BETWEEN_IMAGE_AND_TEXT;
    return cellSize;
}

#define CALCULATE_DRAWING_RECTS_AND_SIZES \
NSSize imageSize; \
imageSize = NSMakeSize(NSHeight(aRect) - 1, NSHeight(aRect) - 1); \
NSRect cellFrame = aRect, ignored; \
\
if (imageSize.width > 0) \
NSDivideRect(cellFrame, &ignored, &cellFrame, BORDER_BETWEEN_EDGE_AND_IMAGE, NSMinXEdge); \
\
NSRect imageRect, textRect; \
NSDivideRect(cellFrame, &imageRect, &textRect, imageSize.width, NSMinXEdge); \
\
if (imageSize.width > 0) \
NSDivideRect(textRect, &ignored, &textRect, BORDER_BETWEEN_IMAGE_AND_TEXT, NSMinXEdge);

- (void)drawInteriorWithFrame:(NSRect)aRect inView:(NSView *)controlView {
    CALCULATE_DRAWING_RECTS_AND_SIZES;
    
    // Draw the text
    [super drawInteriorWithFrame:textRect inView:controlView];
    
    // Draw the image
    imageRect.origin.x += 0.5 * (NSWidth(imageRect) - imageSize.width);
    imageRect.origin.y += 0.5 * (NSHeight(imageRect) - imageSize.height);
    imageRect.origin.y = [controlView isFlipped] ? ceilf(NSMinY(imageRect))  : floorf(NSMinY(imageRect));
    imageRect.size = imageSize;
    [[self icon] drawFlipped:[controlView isFlipped] inRect:imageRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
}

- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(int)selStart length:(int)selLength {
    CALCULATE_DRAWING_RECTS_AND_SIZES;
    
    [super selectWithFrame:textRect inView:controlView editor:textObj delegate:anObject start:selStart length:selLength];
}

- (void)setObjectValue:(id<NSCopying>)obj {
    NSImage *image;
    NSString *string;
    @try {
        image = [(id)obj valueForKey:SKTextWithIconCellImageKey];
        string = [(id)obj valueForKey:SKTextWithIconCellStringKey];
        [self setIcon:image];
        [super setObjectValue:string];
    }
    @catch (id exception) {
        [super setObjectValue:obj];
    }
}

// API

- (NSImage *)icon {
    return icon;
}

- (void)setIcon:(NSImage *)anIcon {
    if (anIcon != icon) {
        [icon release];
        icon = [anIcon retain];
    }
}

@end
