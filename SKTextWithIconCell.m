//
//  SKTextWithIconCell.m
//  Skim
//
//  Created by Christiaan Hofman on 9/13/07.
/*
 This software is Copyright (c) 2007
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

/* Almost all of this code is copy-and-paste from OmniAppKit/OATextWithIconCell, except for the text layout (which seems wrong in OATextWithIconCell). */

NSString *SKTextWithIconCellImageKey = @"image";
NSString *SKTextWithIconCellStringKey = @"string";


@interface NSLayoutManager (BDSKExtensions)
+ (float)defaultViewLineHeightForFont:(NSFont *)theFont;
@end


@implementation SKTextWithIconCell

// Init and dealloc

- (id)init {
    if (self = [super initTextCell:@""]) {
        [self setImagePosition:NSImageLeft];
        [self setEditable:YES];
        [self setScrollable:YES];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        [self setImagePosition:NSImageLeft];
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

#define BORDER_BETWEEN_EDGE_AND_IMAGE (2.0)
#define BORDER_BETWEEN_IMAGE_AND_TEXT (3.0)
#define SIZE_OF_TEXT_FIELD_BORDER (1.0)

#define CELL_SIZE_FUDGE_FACTOR 10.0

- (NSSize)cellSize {
    NSSize cellSize = [super cellSize];
    // TODO: WJS 1/31/04 -- I REALLY don't think this next line is accurate. It appears to not be used much, anyways, but still...
    cellSize.width += [icon size].width + (BORDER_BETWEEN_EDGE_AND_IMAGE * 2.0) + (BORDER_BETWEEN_IMAGE_AND_TEXT * 2.0) + (SIZE_OF_TEXT_FIELD_BORDER * 2.0) + CELL_SIZE_FUDGE_FACTOR;
    return cellSize;
}

#define CALCULATE_DRAWING_RECTS_AND_SIZES \
NSRectEdge rectEdge;  \
NSSize imageSize; \
\
if (imagePosition == NSImageLeft) { \
    rectEdge = NSMinXEdge; \
        imageSize = NSMakeSize(NSHeight(aRect) - 1, NSHeight(aRect) - 1); \
} else { \
    rectEdge =  NSMaxXEdge; \
        if (icon == nil) \
            imageSize = NSZeroSize; \
                else \
                    imageSize = [icon size]; \
} \
\
NSRect cellFrame = aRect, ignored; \
if (imageSize.width > 0) \
NSDivideRect(cellFrame, &ignored, &cellFrame, BORDER_BETWEEN_EDGE_AND_IMAGE, rectEdge); \
\
NSRect imageRect, textRect; \
NSDivideRect(cellFrame, &imageRect, &textRect, imageSize.width, rectEdge); \
\
if (imageSize.width > 0) \
NSDivideRect(textRect, &ignored, &textRect, BORDER_BETWEEN_IMAGE_AND_TEXT, rectEdge); \
\
/* this is the main difference from OATextWithIconCell, which ends up with a really weird text baseline for tall cells */\
float vOffset = 0.5f * (NSHeight(aRect) - [NSLayoutManager defaultViewLineHeightForFont:[self font]]); \
\
if (![controlView isFlipped]) \
textRect.origin.y -= vOffset; \
else \
textRect.origin.y += vOffset; \

- (void)drawInteriorWithFrame:(NSRect)aRect inView:(NSView *)controlView {
    CALCULATE_DRAWING_RECTS_AND_SIZES;
    
    NSDivideRect(textRect, &ignored, &textRect, SIZE_OF_TEXT_FIELD_BORDER, NSMinXEdge);
    textRect = NSInsetRect(textRect, 1.0f, 0.0);
    
    // Draw the text
    NSAttributedString *label = [self attributedStringValue];
    
    [label drawInRect:textRect];
    
    // Draw the image
    imageRect.origin.x += 0.5 * (NSWidth(imageRect) - imageSize.width);
    imageRect.origin.y += 0.5 * (NSHeight(imageRect) - imageSize.height);
    imageRect.origin.y = [controlView isFlipped] ? ceilf(NSMinY(imageRect))  : floorf(NSMinY(imageRect));
    imageRect.size = imageSize;
    [NSGraphicsContext saveGraphicsState];
    if ([controlView isFlipped]) {
        NSAffineTransform *transform = [NSAffineTransform transform];
        [transform translateXBy:0.0 yBy:NSMaxY(imageRect)];
        [transform scaleXBy:1.0 yBy:-1.0];
        [transform translateXBy:0.0 yBy:-NSMinY(imageRect)];
        [transform concat];
    }
    [[self icon] drawInRect:imageRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
	[NSGraphicsContext restoreGraphicsState];
}

- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(int)selStart length:(int)selLength {
    CALCULATE_DRAWING_RECTS_AND_SIZES;
    
    [super selectWithFrame:textRect inView:controlView editor:textObj delegate:anObject start:selStart length:selLength];
}

- (void)setObjectValue:(id<NSCopying>)obj {
    [self setIcon:[(id)obj valueForKey:SKTextWithIconCellImageKey]];
    [super setObjectValue:[(id)obj valueForKey:SKTextWithIconCellStringKey]];
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

- (NSCellImagePosition)imagePosition {
    return imagePosition;
}

- (void)setImagePosition:(NSCellImagePosition)aPosition {
    imagePosition = aPosition;
}

@end


@implementation NSLayoutManager (BDSKExtensions)

+ (float)defaultViewLineHeightForFont:(NSFont *)theFont {
    static NSLayoutManager *layoutManager = nil;
    if (layoutManager == nil) {
        layoutManager = [[NSLayoutManager alloc] init];
        [layoutManager setTypesetterBehavior:NSTypesetterBehavior_10_2_WithCompatibility];
    }
    return [layoutManager defaultLineHeightForFont:theFont];
}

@end
