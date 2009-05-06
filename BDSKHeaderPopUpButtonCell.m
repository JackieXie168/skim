//
//  BDSKHeaderPopUpButtonCell.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 10/23/05.
/*
 This software is Copyright (c) 2005-2009-2008
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
#import "NSGeometry_SKExtensions.h"

@implementation BDSKHeaderPopUpButtonCell

- (id)initTextCell:(NSString *)stringValue pullsDown:(BOOL)pullDown {
	if ([super initTextCell:@"" pullsDown:NO]) {
		
		[self setArrowPosition:NSPopUpNoArrow];
		[self setBordered:NO];
		[self setEnabled:YES];
		[self setUsesItemFromMenu:YES];
		[self setRefusesFirstResponder:YES];
		
		// we keep the headercell for drawing
		headerCell = [[NSTableHeaderCell allocWithZone:[self zone]] initTextCell:@""];
		
        // we could pass more properties
		[headerCell setFont:[self font]];
	}
	return self;
}

- (id)copyWithZone:(NSZone *)aZone {
	BDSKHeaderPopUpButtonCell *copy = [super copyWithZone:aZone];
    copy->headerCell = [headerCell copyWithZone:aZone];
    return copy;
}

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
        headerCell = [[decoder decodeObjectForKey:@"headerCell"] retain];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:headerCell forKey:@"headerCell"];
}

- (void)dealloc {
	[headerCell release];
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

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	// let the header cell do most of the drawing for usNSLog(@"%@ %@");
    if ([self usesItemFromMenu])
        [headerCell setStringValue:[self title]];
	[headerCell setState:[self isHighlighted]];
	[headerCell setHighlighted:[self isHighlighted]];
	[headerCell drawWithFrame:cellFrame inView:controlView];
	
	// Two little arrows. We could also use some image here
	NSInteger controlSize = [self controlSize];
	CGFloat width = 5.0 - controlSize;
	CGFloat height = 4.0 - controlSize;
	CGFloat totalHeight = 3.0 + 2 * height;
	NSBezierPath *path = [NSBezierPath bezierPath];
	[path moveToPoint:NSMakePoint(NSMaxX(cellFrame) - 7.5 + controlSize, SKFloor(NSMidY(cellFrame) - 0.5f * totalHeight))];
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

    if ([[controlView window] isKeyWindow] && [[controlView window] firstResponder] == controlView) {
		[NSGraphicsContext saveGraphicsState];
		NSSetFocusRingStyle(NSFocusRingOnly);
        [NSBezierPath fillRect:cellFrame];
		[NSGraphicsContext restoreGraphicsState];
    }
}    

- (BOOL)trackMouse:(NSEvent *)theEvent inRect:(NSRect)cellFrame ofView:(NSView *)controlView untilMouseUp:(BOOL)untilMouseUp {
	// fool super to get the right menu position
	cellFrame.origin.x -= 7.0;
	cellFrame.origin.y += 2.0;
	cellFrame.size.width += 7.0;
	return [super trackMouse:theEvent inRect:cellFrame ofView:controlView untilMouseUp:untilMouseUp];
}

@end
