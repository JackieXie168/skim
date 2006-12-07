//
//  BDSKGroupCell.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 26/10/05.
/*
 This software is Copyright (c) 2005
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

#import "BDSKGroupCell.h"

#import <OmniBase/rcsid.h>
#import "NSBezierPath_BDSKExtensions.h"
#import <OmniBase/OBUtilities.h>

#define TEXT_VERTICAL_OFFSET (-1.0)
#define FLIP_VERTICAL_OFFSET (-9.0)
#define BORDER_BETWEEN_EDGE_AND_IMAGE (2.0)
#define BORDER_BETWEEN_EDGE_AND_COUNT (1.0)
#define BORDER_BETWEEN_IMAGE_AND_TEXT (3.0)
#define BORDER_BETWEEN_COUNT_AND_TEXT (1.0)
#define SIZE_OF_TEXT_FIELD_BORDER (1.0)

static NSMutableParagraphStyle *BDSKGroupCellParagraphStyle = nil;
NSString *BDSKGroupCellStringKey = @"string";
NSString *BDSKGroupCellImageKey = @"image";
NSString *BDSKGroupCellCountKey = @"count";

@interface BDSKGroupCell (Private)
- (void)recacheCountFont;
@end

@implementation BDSKGroupCell

+ (void)initialize;
{
    OBINITIALIZE;
    
    BDSKGroupCellParagraphStyle = [[NSMutableParagraphStyle alloc] init];
    [BDSKGroupCellParagraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
}

- (id)init {
    if (self = [super init]) {
		count = [[NSNumber alloc] initWithInt:0];
		[self setDrawsHighlight:NO];
        [self recacheCountFont];
    }
    return self;
}

// NSCoding

- (id)initWithCoder:(NSCoder *)coder {
	if (self = [super initWithCoder:coder]) {
		// we need to do these two because OATextWithIconCell does in subclass NSCoding, so super uses the one from NSTextFieldCell
		_oaFlags.drawsHighlight = [coder decodeIntForKey:@"drawsHighlight"];
		icon = [[coder decodeObjectForKey:@"image"] retain];
		count = [[coder decodeObjectForKey:@"count"] retain];
		[self setImagePosition:NSImageLeft];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
	[super encodeWithCoder:encoder];
	[encoder encodeInt:_oaFlags.drawsHighlight forKey:@"drawsHighlight"];
	[encoder encodeObject:icon forKey:@"image"];
	[encoder encodeObject:count forKey:@"count"];
}

// NSCopying

- (id)copyWithZone:(NSZone *)zone {
    BDSKGroupCell *copy = [super copyWithZone:zone];
    
    copy->count = [count retain];
    
    return copy;
}

- (void)dealloc {
	[count release];
	[super dealloc];
}

- (NSNumber *)count {
	return count;
}

- (void)setCount:(NSNumber *)newCount {
	if(newCount != count){
		[count release];
		count = [newCount retain];
	}
}

- (void)setFont:(NSFont *)font {
    [super setFont:font];
    [self recacheCountFont];
}

- (void)setObjectValue:(id <NSObject, NSCopying>)obj {
    if ([obj isKindOfClass:[NSString class]] || [obj isKindOfClass:[NSAttributedString class]]) {
        [super setObjectValue:obj];
    } else if ([obj isKindOfClass:[NSNumber class]]) {
		[self setCount:(NSNumber *)obj];
    } else if ([obj isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dictionary = (NSDictionary *)obj;
        
        [super setObjectValue:[dictionary objectForKey:BDSKGroupCellStringKey]];
        [self setIcon:[dictionary objectForKey:BDSKGroupCellImageKey]];
        [self setCount:[dictionary objectForKey:BDSKGroupCellCountKey]];
    }
}

- (int)intValue {
	return [count intValue];
}

- (void)setIntValue:(int)value {
	[self setCount:[NSNumber numberWithInt:value]];
}

- (float)floatValue {
	return [count floatValue];
}

- (void)setFloatValue:(float)value {
	[self setCount:[NSNumber numberWithFloat:value]];
}

- (double)doubleValue {
	return [count doubleValue];
}

- (void)setDoubleValue:(double)value {
	[self setCount:[NSNumber numberWithDouble:value]];
} 

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    // support only NSImageLeft
    NSMutableAttributedString *label = [[NSMutableAttributedString alloc] initWithAttributedString:[self attributedStringValue]];
	NSDictionary *attrs = [label attributesAtIndex:0 effectiveRange:NULL];
    NSMutableAttributedString *countString = [[NSMutableAttributedString alloc] initWithString:[count stringValue] attributes:attrs];
    
    NSRange countRange = NSMakeRange(0, [countString length]);
    [countString addAttribute:NSFontAttributeName value:countFont range:countRange];
    
    static NSNumber *kerning = nil;
    if(kerning == nil)
        kerning = [[NSNumber alloc] initWithFloat:-1.0];
    [countString addAttribute:NSKernAttributeName value:kerning range:countRange];
	
    NSSize imageSize = NSMakeSize(NSHeight(cellFrame) - 1, NSHeight(cellFrame) - 1);
    NSSize textSize = [label size];
    NSSize countSize = [countString size];
	float countSep = floor(countSize.height/2);
	countSize.height = 2 * countSep;
    
	NSRect aRect = cellFrame, ignored;
    if (imageSize.width > 0)
        NSDivideRect(aRect, &ignored, &aRect, BORDER_BETWEEN_EDGE_AND_IMAGE, NSMinXEdge);
    
    NSRect imageRect, textRect, countRect;
    NSDivideRect(aRect, &imageRect, &textRect, imageSize.width, NSMinXEdge);
    
    if (imageSize.width > 0)
        NSDivideRect(textRect, &ignored, &textRect, BORDER_BETWEEN_IMAGE_AND_TEXT, NSMinXEdge);

    NSDivideRect(textRect, &ignored, &textRect, BORDER_BETWEEN_EDGE_AND_COUNT + countSep, NSMaxXEdge);
    NSDivideRect(textRect, &countRect, &textRect, countSize.width, NSMaxXEdge);
    NSDivideRect(textRect, &ignored, &textRect, BORDER_BETWEEN_COUNT_AND_TEXT + countSep, NSMaxXEdge);
    
	// I am not sure about these, copied from OATextWithIconCell
    NSDivideRect(textRect, &ignored, &textRect, SIZE_OF_TEXT_FIELD_BORDER, NSMinXEdge);
    textRect = NSInsetRect(textRect, 1.0, 0.0);
    	
	NSColor *highlightColor = [self highlightColorWithFrame:cellFrame inView:controlView];
	BOOL highlighted = [self isHighlighted];
	NSColor *bgColor = [NSColor disabledControlTextColor];
    NSRange labelRange = NSMakeRange(0, [label length]);
		
	if (highlighted) {
		// add the alternate text color attribute.
		if ([highlightColor isEqual:[NSColor alternateSelectedControlColor]])
			[label addAttribute:NSForegroundColorAttributeName value:[NSColor alternateSelectedControlTextColor] range:labelRange];
		[countString addAttribute:NSForegroundColorAttributeName value:[NSColor disabledControlTextColor] range:countRange];
		bgColor = [[NSColor alternateSelectedControlTextColor] colorWithAlphaComponent:0.8];
	} else {
		[countString addAttribute:NSForegroundColorAttributeName value:[NSColor alternateSelectedControlTextColor] range:countRange];
		bgColor = [bgColor colorWithAlphaComponent:0.7];
	}

    // Draw the text
    [label addAttribute:NSParagraphStyleAttributeName value:BDSKGroupCellParagraphStyle range:labelRange];
    [label drawInRect:textRect];
    [label release];
	
    // Draw the count
    [bgColor set];
	NSRect bgRect = NSInsetRect(countRect, 0.5, 0.5);
	bgRect.origin.y += 0.5;
    [NSBezierPath fillHorizontalOvalAroundRect:bgRect];
    [countString addAttribute:NSParagraphStyleAttributeName value:BDSKGroupCellParagraphStyle range:countRange];
    [countString drawInRect:countRect];
    [countString release];
    
    // Draw the image
    imageRect.size = imageSize;
    imageRect.origin.y += ceil((NSHeight(aRect) - imageSize.height) / 2.0);
    if ([controlView isFlipped])
        [[self icon] drawFlippedInRect:imageRect operation:NSCompositeSourceOver];
    else
        [[self icon] drawInRect:imageRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
}

@end

@implementation BDSKGroupCell (Private)

- (void)recacheCountFont {
    
    // autorelease in case the font manager returns a different instance
    NSFont *font = [[[self font] copy] autorelease];
    OBPRECONDITION(font);     
    
    font = [[NSFontManager sharedFontManager] convertFont:font toHaveTrait:NSBoldFontMask];
    font = [[NSFontManager sharedFontManager] convertFont:font toSize:([font pointSize] - 1)];
    
    [countFont autorelease];
    countFont = [font retain];
}


@end
