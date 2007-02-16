//
//  SKCollapsibleView.m
//  Skim
//
//  Created by Christiaan Hofman on 12/18/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "SKCollapsibleView.h"


@implementation SKCollapsibleView

- (id)initWithFrame:(NSRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		contentView = [[NSView alloc] initWithFrame:[self contentRect]];
		[super addSubview:contentView];
		[contentView release];
		collapseEdges = SKMinXEdgeMask | SKMinYEdgeMask;
		minSize = NSZeroSize;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
	if (self = [super initWithCoder:decoder]) {
		if ([[super subviews] count]) { // not sure if this works OK, but we're not using it now as IB calls initWithFrame
			[self setContentView:[[super subviews] objectAtIndex:0]];
		} else {
			contentView = [[NSView alloc] initWithFrame:[self contentRect]];
			[super addSubview:contentView];
			[contentView release];
		}
		collapseEdges = [decoder decodeIntForKey:@"collapseEdges"];
		minSize.width = [decoder decodeFloatForKey:@"minSize.width"];
		minSize.height = [decoder decodeFloatForKey:@"minSize.height"];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeInt:collapseEdges forKey:@"collapseEdges"];
  [coder encodeFloat:minSize.width forKey:@"minSize.width"];
  [coder encodeFloat:minSize.height forKey:@"minSize.height"];
  // NSView should handle encoding of contentView as it is a subview
}

- (id)contentView {
	return contentView;
}

- (void)setContentView:(NSView *)aView {
	if (aView != contentView) {
		[contentView removeFromSuperview];
		[super addSubview:aView]; // replaceSubview:with: does not work, as it calls [self addSubview:]
		contentView = aView;
		[contentView setFrame:[self contentRect]];
		[self setNeedsDisplay:YES];
	}
}

- (NSSize)minSize {
	return minSize;
}

- (void)setMinSize:(NSSize)size {
	minSize = size;
}

- (int)collapseEdges {
	return collapseEdges;
}

- (void)setCollapseEdges:(int)mask {
	if (mask != collapseEdges) {
		collapseEdges = mask;
		[contentView setFrame:[self contentRect]];
		[self setNeedsDisplay:YES];
	}
}

- (NSRect)contentRect {
	NSRect rect = [self bounds];
	if (rect.size.width < minSize.width) {
		if (collapseEdges & SKMinXEdgeMask)
			rect.origin.x -= minSize.width - NSWidth(rect);
		rect.size.width = minSize.width;
	}
	if (rect.size.height < minSize.height) {
		if (collapseEdges & SKMinYEdgeMask)
			rect.origin.y -= minSize.height - NSHeight(rect);
		rect.size.height = minSize.height;
	}
	return rect;
}

- (void)resizeSubviewsWithOldSize:(NSSize)size {
	[contentView setFrame:[self contentRect]];
}

- (void)resizeWithOldSuperviewSize:(NSSize)oldSize {
	[super resizeWithOldSuperviewSize:oldSize];
	[contentView setFrame:[self contentRect]];
}

- (void)addSubview:(NSView *)aView {
	NSRect frame = [aView frame];
	frame = [contentView convertRect:frame fromView:self];
	[aView setFrame:frame];
	[contentView addSubview:aView];
}

- (void)addSubview:(NSView *)aView positioned:(NSWindowOrderingMode)place relativeTo:(NSView *)otherView {
	NSRect frame = [aView frame];
	frame = [contentView convertRect:frame fromView:self];
	[aView setFrame:frame];
	[contentView addSubview:aView positioned:place relativeTo:otherView];
}

- (void)replaceSubview:(NSView *)aView with:(NSView *)newView {
	NSRect frame = [aView frame];
	frame = [contentView convertRect:frame fromView:self];
	[aView setFrame:frame];
	[contentView replaceSubview:aView with:newView];
}

@end
