//
//  BDSKEdgeView.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 1/11/05.
/*
 This software is Copyright (c) 2005-2008
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

#import "BDSKEdgeView.h"

#define BORDER_SIZE 1.0

@implementation BDSKEdgeView

- (id)initWithFrame:(NSRect)frame {
    if (self = [super initWithFrame:frame]) {
       NSColor *color = [NSColor colorWithCalibratedWhite:0.75 alpha:1.0];
	   edgeColors = [[NSMutableArray alloc] initWithObjects:color, color, color, color, nil];
	   edges = BDSKNoEdgeMask; // we start with no edge, so we can use this in IB without getting weird offsets
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
	if (self = [super initWithCoder:decoder]) {
		edgeColors = [[decoder decodeObjectForKey:@"edgeColors"] retain];
		edges = [decoder decodeIntForKey:@"edges"];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeObject:edgeColors forKey:@"edgeColors"];
  [coder encodeInt:edges forKey:@"edges"];
  // NSView should handle encoding of contentView as it is a subview
}

- (void)dealloc {
	[edgeColors release];
	[super dealloc];
}

- (void)drawRect:(NSRect)aRect {
	NSRect rect = [self bounds];
	NSRect edgeRect;
	int edge = 4;
	
	while (--edge >= 0) {
		if ((edges & (1 << edge)) == 0)
			continue;
		NSDivideRect(rect, &edgeRect, &rect, BORDER_SIZE, edge);
		[[edgeColors objectAtIndex:edge] set];
		NSRectFill(edgeRect);
	}
}

- (int)edges {
	return edges;
}

- (void)setEdges:(int)mask {
	if (mask != edges) {
		edges = mask;
		[contentView setFrame:[self contentRect]];
		[self setNeedsDisplay:YES];
	}
}

- (NSArray *)edgeColors {
	return edgeColors;
}

- (void)setEdgeColors:(NSArray *)colors {
	if (colors != edgeColors) {
		[edgeColors release];
		edgeColors = [colors retain];
		[self setNeedsDisplay:YES];
	}
}

- (void)setEdgeColor:(NSColor *)aColor {
	int count = 4;
	[edgeColors removeAllObjects];
	while (count--) 
		[edgeColors addObject:aColor];
	[self setNeedsDisplay:YES];
}

- (NSColor *)colorForEdge:(NSRectEdge)edge {
	return [edgeColors objectAtIndex:edge];
}

- (void)setColor:(NSColor *)aColor forEdge:(NSRectEdge)edge {
	if ([edgeColors objectAtIndex:edge] != aColor) {
		[edgeColors replaceObjectAtIndex:edge withObject:aColor];
		[self setNeedsDisplay:YES];
	}
}

- (NSRect)contentRect {
	NSRect rect = [self bounds];
	NSRect edgeRect;
	int edge = 4;
	
	while (--edge >= 0) {
		if (edges & (1 << edge))
			NSDivideRect(rect, &edgeRect, &rect, BORDER_SIZE, edge);
	}
	if (rect.size.width < 0.0)
		rect.size.width = 0.0;
	if (rect.size.height < 0.0)
		rect.size.height = 0.0;
	return rect;
}

- (void)adjustSubviews {
	NSEnumerator *viewEnum = [[contentView subviews] objectEnumerator];
	NSView *view;
	NSRect contentRect;
	NSRect frame;
	
	[contentView setFrame:[self contentRect]];
	contentRect = [contentView bounds];
	 
	while (view = [viewEnum nextObject]) {
		frame = [view frame];
		if (NSContainsRect(contentRect, frame)) 
			continue;
		if (NSMinX(frame) > NSMaxX(contentRect)) { 
			frame.origin.x = NSMaxX(contentRect);
			frame.size.width = 0.0;
		} else if (NSMaxX(frame) < NSMinX(contentRect)) {
			frame.origin.x = NSMinX(contentRect);
			frame.size.width = 0.0;
		}
		if (NSMinY(frame) > NSMaxY(contentRect)) { 
			frame.origin.y = NSMaxY(contentRect);
			frame.size.height = 0.0;
		} else if (NSMaxY(frame) < NSMinY(contentRect)) {
			frame.origin.y = NSMinY(contentRect);
			frame.size.height = 0.0;
		}
		frame = NSIntersectionRect(frame, contentRect);
		[view setFrame:frame];
	}
}

@end
