//
//  BDSKTextWithIconCell.m
//  Bibdesk
//
//  Created by Adam Maxwell on 12/10/05.
/*
 This software is Copyright (c) 2005,2006
 Adam Maxwell. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 
 - Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 
 - Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in
 the documentation and/or other materials provided with the
 distribution.
 
 - Neither the name of Adam Maxwell nor the names of any
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
#import "BDSKTextWithIconCell.h"

/* Almost all of this code is copy-and-paste from OATextWithIconCell, except for the text layout (which seems wrong in OATextWithIconCell). */

static NSMutableParagraphStyle *BDSKTextWithIconCellParagraphStyle = nil;

@implementation BDSKTextWithIconCell

+ (void)initialize;
{
    OBINITIALIZE;
    
    BDSKTextWithIconCellParagraphStyle = [[NSMutableParagraphStyle alloc] init];
    [BDSKTextWithIconCellParagraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
}

// Init and dealloc

- (id)init;
{
    if (self = [super initTextCell:@""]) {
        [self setImagePosition:NSImageLeft];
        [self setEditable:YES];
        [self setDrawsHighlight:YES];
        [self setScrollable:YES];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder;
{
    if (self = [super initWithCoder:coder]) {
        [self setImagePosition:NSImageLeft];
        [self setDrawsHighlight:YES];
    }
    return self;
}

- (void)dealloc;
{
    [icon release];
    
    [super dealloc];
}

// NSCopying protocol

- (id)copyWithZone:(NSZone *)zone;
{
    BDSKTextWithIconCell *copy = [super copyWithZone:zone];
    
    copy->icon = [icon retain];
    copy->_oaFlags.drawsHighlight = _oaFlags.drawsHighlight;
    
    return copy;
}

- (NSColor *)highlightColorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;
{
    if (!_oaFlags.drawsHighlight)
        return nil;
    else
        return [super highlightColorWithFrame:cellFrame inView:controlView];
}

- (NSColor *)textColor;
{
    if (_oaFlags.settingUpFieldEditor)
        return [NSColor blackColor];
    else if (!_oaFlags.drawsHighlight && _cFlags.highlighted)
        return [NSColor textBackgroundColor];
    else
        return [super textColor];
}

#define BORDER_BETWEEN_EDGE_AND_IMAGE (2.0)
#define BORDER_BETWEEN_IMAGE_AND_TEXT (3.0)
#define SIZE_OF_TEXT_FIELD_BORDER (1.0)

#define CELL_SIZE_FUDGE_FACTOR 10.0

- (NSSize)cellSize;
{
    NSSize cellSize = [super cellSize];
    // TODO: WJS 1/31/04 -- I REALLY don't think this next line is accurate. It appears to not be used much, anyways, but still...
    cellSize.width += [icon size].width + (BORDER_BETWEEN_EDGE_AND_IMAGE * 2.0) + (BORDER_BETWEEN_IMAGE_AND_TEXT * 2.0) + (SIZE_OF_TEXT_FIELD_BORDER * 2.0) + CELL_SIZE_FUDGE_FACTOR;
    return cellSize;
}

#define _calculateDrawingRectsAndSizes \
NSRectEdge rectEdge;  \
NSSize imageSize; \
\
if (_oaFlags.imagePosition == NSImageLeft) { \
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
NSLayoutManager *lm = [[NSLayoutManager alloc] init]; \
float vOffset = (NSHeight(aRect) - [lm defaultLineHeightForFont:[self font]])/2; \
[lm release];  \
\
if (![controlView isFlipped]) \
textRect.origin.y -= vOffset; \
else \
textRect.origin.y += vOffset; \

- (void)drawInteriorWithFrame:(NSRect)aRect inView:(NSView *)controlView;
{
    _calculateDrawingRectsAndSizes;
    
    NSDivideRect(textRect, &ignored, &textRect, SIZE_OF_TEXT_FIELD_BORDER, NSMinXEdge);
    textRect = NSInsetRect(textRect, 1.0f, 0.0);
    
    // Draw the text
    NSMutableAttributedString *label = [[NSMutableAttributedString alloc] initWithAttributedString:[self attributedStringValue]];
    NSRange labelRange = NSMakeRange(0, [label length]);
    NSColor *highlightColor = [self highlightColorWithFrame:cellFrame inView:controlView];
    BOOL highlighted = [self isHighlighted];
    
    if (highlighted && [highlightColor isEqual:[NSColor alternateSelectedControlColor]]) {
        // add the alternate text color attribute.
        [label addAttribute:NSForegroundColorAttributeName value:[NSColor alternateSelectedControlTextColor] range:labelRange];
    }
    
    [label addAttribute:NSParagraphStyleAttributeName value:BDSKTextWithIconCellParagraphStyle range:labelRange];
    [label drawInRect:textRect];
    [label release];
    
    // Draw the image
    imageRect.size = imageSize;
    imageRect.origin.y += ceil((NSHeight(aRect) - imageSize.height) / 2.0);
    if ([controlView isFlipped])
        [[self icon] drawFlippedInRect:imageRect operation:NSCompositeSourceOver];
    else
        [[self icon] drawInRect:imageRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
}

- (BOOL)trackMouse:(NSEvent *)theEvent inRect:(NSRect)cellFrame ofView:(NSView *)controlView untilMouseUp:(BOOL)flag;
{
    return [super trackMouse:theEvent inRect:cellFrame ofView:controlView untilMouseUp:flag];
}

- (void)editWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject event:(NSEvent *)theEvent;
{
    _oaFlags.settingUpFieldEditor = YES;
    [super editWithFrame:aRect inView:controlView editor:textObj delegate:anObject event:theEvent];
    _oaFlags.settingUpFieldEditor = NO;
}

- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(int)selStart length:(int)selLength;
{
    _calculateDrawingRectsAndSizes;
    
    _oaFlags.settingUpFieldEditor = YES;
    [super selectWithFrame:textRect inView:controlView editor:textObj delegate:anObject start:selStart length:selLength];
    _oaFlags.settingUpFieldEditor = NO;
}

- (void)setObjectValue:(id <NSObject, NSCopying>)obj;
{
    if ([obj isKindOfClass:[NSString class]] || [obj isKindOfClass:[NSAttributedString class]]) {
        [super setObjectValue:obj];
        return;
    } else if ([obj isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dictionary = (NSDictionary *)obj;
        
        [super setObjectValue:[dictionary objectForKey:OATextWithIconCellStringKey]];
        [self setIcon:[dictionary objectForKey:OATextWithIconCellImageKey]];
    }
}

// API

- (NSImage *)icon;
{
    return icon;
}

- (void)setIcon:(NSImage *)anIcon;
{
    if (anIcon == icon)
        return;
    [icon release];
    icon = [anIcon retain];
}

- (NSCellImagePosition)imagePosition;
{
    return _oaFlags.imagePosition;
}

- (void)setImagePosition:(NSCellImagePosition)aPosition;
{
    _oaFlags.imagePosition = aPosition;
}

- (BOOL)drawsHighlight;
{
    return _oaFlags.drawsHighlight;
}

- (void)setDrawsHighlight:(BOOL)flag;
{
    _oaFlags.drawsHighlight = flag;
}

- (NSRect)textRectForFrame:(NSRect)aRect inView:(NSView *)controlView;
{
    _calculateDrawingRectsAndSizes;
    
    return textRect;
}

@end