//
//  BDSKHeaderPopUpButtonCell.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 10/23/05.
/*
 This software is Copyright (c) 2005,2006
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

#import "BDSKHeaderPopUpButtonCell.h"
#import "NSImage_SKExtensions.h"

@implementation BDSKHeaderPopUpButtonCell

- (id)initTextCell:(NSString *)aString {
	NSTableHeaderCell *aHeaderCell = [[NSTableHeaderCell allocWithZone:[self zone]] initTextCell:@""];
	if (self = [self initWithHeaderCell:aHeaderCell]) {
		[self setStringValue:aString];
        [headerCell setStringValue:aString];
	}
	[aHeaderCell release];
	return self;
}

- (id)initWithHeaderCell:(NSTableHeaderCell *)aHeaderCell {
	if ([super initTextCell:@"" pullsDown:NO]) {
		
		[self setArrowPosition:NSPopUpNoArrow];
		[self setBordered:NO];
		[self setEnabled:YES];
		[self setUsesItemFromMenu:YES];
		[self setRefusesFirstResponder:YES];
		
		// we could pass more properties
		[self setFont:[aHeaderCell font]];
		
		// we keep the headercell for drawing
		headerCell = [aHeaderCell retain];
		
		indicatorImage = nil;
	}
	return self;
}

// a copy is used to fill in empty space if the column do not fill the table. That better be an empty headerCell
- (id)copyWithZone:(NSZone *)aZone {
	return [headerCell copyWithZone:aZone];
}

- (void)dealloc {
	[headerCell release];
	[indicatorImage release];
	[super dealloc];
}

// we might pass more properties to the headercell
- (void)setFont:(NSFont *)font {
	[super setFont:font];
	[headerCell setFont:font];
}

- (NSSize)cellSize {
	NSSize size = [super cellSize];
	size.width -= 22.0 + 2 * [self controlSize];
	return size;
}

- (NSRect)sortIndicatorRectForBounds:(NSRect)aRect {
	NSRect indicatorRect = NSZeroRect;
	if (indicatorImage != nil) {
		NSSize indicatorSize = [indicatorImage size];
		NSDivideRect(aRect, &indicatorRect, &aRect, indicatorSize.width + 8.0, NSMaxXEdge);
	}
	return indicatorRect;
}

- (NSRect)popUpRectForBounds:(NSRect)aRect {
	NSRect popupRect = aRect;
	if (indicatorImage != nil) {
		NSSize indicatorSize = [indicatorImage size];
		NSDivideRect(aRect, &aRect, &popupRect, indicatorSize.width + 8.0, NSMaxXEdge);
	}
	return popupRect;
}

- (NSString *)title {
    if ([self usesItemFromMenu])
        return [super title];
    else
        return [headerCell title];
}

- (void)setTitle:(NSString *)title {
    if ([self usesItemFromMenu])
        [super setTitle:title];
    [headerCell setTitle:title];
}

NSRect BDSKCenterRect(NSRect rect, NSSize size, BOOL flipped)
{
    rect.origin.x += 0.5f * (NSWidth(rect) - size.width);
    rect.origin.y += 0.5f * (NSHeight(rect) - size.height);
    rect.origin.y = flipped ? ceilf(rect.origin.y)  : floorf(rect.origin.y);
    rect.size = size;
    return rect;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	// let the header cell do most of the drawing for usNSLog(@"%@ %@");
    if ([self usesItemFromMenu])
        [headerCell setStringValue:[self title]];
	[headerCell setState:[self isHighlighted]];
	[headerCell setHighlighted:[self isHighlighted]];
	[headerCell drawWithFrame:cellFrame inView:controlView];
	
	if (indicatorImage != nil) {
		NSSize indicatorSize = [indicatorImage size];
		NSRect indicatorRect, ignored;
		
		NSDivideRect(cellFrame, &ignored, &cellFrame, 4.0, NSMaxXEdge);
		NSDivideRect(cellFrame, &indicatorRect, &cellFrame, indicatorSize.width, NSMaxXEdge);
		NSDivideRect(cellFrame, &ignored, &cellFrame, 4.0, NSMaxXEdge);
		
        indicatorRect = BDSKCenterRect(indicatorRect, indicatorSize, [controlView isFlipped]);
		
        [indicatorImage drawFlipped:[controlView isFlipped] inRect:indicatorRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
	}
	
	// Two little arrows. We could also use some image here
	int controlSize = [self controlSize];
	float width = 5.0 - controlSize;
	float height = 4.0 - controlSize;
	float totalHeight = 3.0 + 2 * height;
	NSBezierPath *path = [NSBezierPath bezierPath];
	[path moveToPoint:NSMakePoint(NSMaxX(cellFrame) - 7.5 + controlSize, floorf(NSMidY(cellFrame) - 0.5f * totalHeight))];
	[path relativeLineToPoint:NSMakePoint(-0.5f * width, height)];
	[path relativeLineToPoint:NSMakePoint(width, 0.0)];
	[path closePath];
	[path relativeMoveToPoint:NSMakePoint(0.0, totalHeight)];
	[path relativeLineToPoint:NSMakePoint(-0.5f * width, -height)];
	[path relativeLineToPoint:NSMakePoint(width, 0.0)];
	[path closePath];
    
    [NSGraphicsContext saveGraphicsState];
	[[NSColor colorWithCalibratedWhite:0.0 alpha:0.85] set];
	[path fill];
    [NSGraphicsContext restoreGraphicsState];

}    

- (void)setIndicatorImage:(NSImage *)image {
	if (image != indicatorImage) {
		[indicatorImage release];
		indicatorImage = [image retain];
	}
}

- (NSImage *)indicatorImage {
	return indicatorImage;
}

- (BOOL)trackMouse:(NSEvent *)theEvent inRect:(NSRect)cellFrame ofView:(NSView *)controlView untilMouseUp:(BOOL)untilMouseUp {
	// fool super to get the right menu position
	cellFrame = [self popUpRectForBounds:cellFrame];
	cellFrame.origin.x -= 7.0;
	cellFrame.origin.y += 2.0;
	cellFrame.size.width += 7.0;
	return [super trackMouse:theEvent inRect:cellFrame ofView:controlView untilMouseUp:untilMouseUp];
}

@end
