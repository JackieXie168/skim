//
//  SKGradientView.m
//  Skim
//
//  Created by Adam Maxwell on 10/26/05.
/*
 This software is Copyright (c) 2005-2011
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

#import "SKGradientView.h"
#import "NSGeometry_SKExtensions.h"

#define BORDER_SIZE 1.0

@implementation SKGradientView

@synthesize contentView, minSize, edges, autoEdges;
@dynamic contentRect;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        minSize = NSZeroSize;
        edges = SKNoEdgeMask; // we start with no edge, so we can use this in IB without getting weird offsets
        autoEdges = NO;
        contentView = [[NSView alloc] initWithFrame:[self contentRect]];
		[super addSubview:contentView];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
	self = [super initWithCoder:decoder];
    if (self) {
		// this decodes only the reference, the actual view should already be decoded as a subview
        contentView = [[decoder decodeObjectForKey:@"contentView"] retain];
		minSize.width = [decoder decodeDoubleForKey:@"minSize.width"];
		minSize.height = [decoder decodeDoubleForKey:@"minSize.height"];
		edges = [decoder decodeIntegerForKey:@"edges"];
		autoEdges = [decoder decodeBoolForKey:@"autoEdges"];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    // this encodes only a reference, the actual contentView should already be encoded because it's a subview
    [coder encodeConditionalObject:contentView forKey:@"contentView"];
    [coder encodeDouble:minSize.width forKey:@"minSize.width"];
    [coder encodeDouble:minSize.height forKey:@"minSize.height"];
    [coder encodeInteger:edges forKey:@"edges"];
    [coder encodeBool:autoEdges forKey:@"autoEdges"];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    SKDESTROY(contentView);
	[super dealloc];
}

- (void)resizeSubviewsWithOldSize:(NSSize)size {
	[contentView setFrame:[self contentRect]];
}

- (void)resizeWithOldSuperviewSize:(NSSize)oldSize {
	[super resizeWithOldSuperviewSize:oldSize];
	[contentView setFrame:[self contentRect]];
}

- (void)addSubview:(NSView *)aView {
	[contentView addSubview:aView];
}

- (void)addSubview:(NSView *)aView positioned:(NSWindowOrderingMode)place relativeTo:(NSView *)otherView {
	[contentView addSubview:aView positioned:place relativeTo:otherView];
}

- (void)replaceSubview:(NSView *)aView with:(NSView *)newView {
	[contentView replaceSubview:aView with:newView];
}

- (void)drawRect:(NSRect)aRect
{        
	NSRect rect = [self bounds];
	NSRect edgeRect;
	NSInteger edge = 4;
	
    [NSGraphicsContext saveGraphicsState];
    
    [[NSColor colorWithDeviceWhite:0.55 alpha:1.0] set];
	while (--edge >= 0) {
		if ((edges & (1 << edge)) == 0)
			continue;
		NSDivideRect(rect, &edgeRect, &rect, BORDER_SIZE, edge);
		NSRectFill(edgeRect);
	}
    
    if ([[self window] styleMask] != NSBorderlessWindowMask) {
        BOOL keyOrMain = [[self window] isMainWindow] || [[self window] isKeyWindow];
        NSColor *lowerColor = [NSColor colorWithCalibratedWhite:keyOrMain ? 0.75 : 0.8 alpha:1.0];
        NSColor *upperColor = [NSColor colorWithCalibratedWhite:keyOrMain ? 0.9 : 0.95 alpha:1.0];
        NSGradient *gradient = [[[NSGradient alloc] initWithStartingColor:lowerColor endingColor:upperColor] autorelease];
        [gradient drawInRect:rect angle:90.0];
    }
    
    [NSGraphicsContext restoreGraphicsState];
}

- (void)handleKeyOrMainStateChangedNotification:(NSNotification *)note {
    [self setNeedsDisplay:YES];
}

- (void)viewWillMoveToWindow:(NSWindow *)newWindow {
    NSWindow *window = [self window];
    if ([window styleMask] != NSBorderlessWindowMask) {
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc removeObserver:self name:NSWindowDidBecomeMainNotification object:window];
        [nc removeObserver:self name:NSWindowDidResignMainNotification object:window];
        [nc removeObserver:self name:NSWindowDidBecomeKeyNotification object:window];
        [nc removeObserver:self name:NSWindowDidResignKeyNotification object:window];
    }
}

- (void)viewDidMoveToWindow {
    NSWindow *window = [self window];
    BOOL hasBorder = [window styleMask] != NSBorderlessWindowMask;
    if (hasBorder) {
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(handleKeyOrMainStateChangedNotification:) name:NSWindowDidBecomeMainNotification object:window];
        [nc addObserver:self selector:@selector(handleKeyOrMainStateChangedNotification:) name:NSWindowDidResignMainNotification object:window];
        [nc addObserver:self selector:@selector(handleKeyOrMainStateChangedNotification:) name:NSWindowDidBecomeKeyNotification object:window];
        [nc addObserver:self selector:@selector(handleKeyOrMainStateChangedNotification:) name:NSWindowDidResignKeyNotification object:window];
    }
    if (autoEdges)
        [self setEdges:hasBorder ? SKMinXEdgeMask | SKMaxXEdgeMask : SKNoEdgeMask];
}

// required in order for redisplay to work properly with the controls
- (BOOL)isOpaque{  return [[self window] styleMask] != NSBorderlessWindowMask; }

- (void)setContentView:(NSView *)aView {
	if (aView != contentView) {
		[contentView removeFromSuperview];
        [contentView release];
		[super addSubview:aView]; // replaceSubview:with: does not work, as it calls [self addSubview:]
		contentView = [aView retain];
		[contentView setFrame:[self contentRect]];
		[self setNeedsDisplay:YES];
	}
}

- (void)setEdges:(SKRectEdges)mask {
	if (mask != edges) {
		edges = mask;
		[contentView setFrame:[self contentRect]];
		[self setNeedsDisplay:YES];
	}
}

- (void)setAutoEdges:(BOOL)flag {
    autoEdges = flag;
    if (autoEdges)
        [self setEdges:[[self window] styleMask] != NSBorderlessWindowMask ? SKMinXEdgeMask | SKMaxXEdgeMask : SKNoEdgeMask];
}

- (NSRect)contentRect {
	NSRect rect = [self bounds];
	NSRect edgeRect;
	NSRectEdge edge = 4;
	while (edge-- > 0) {
		if (edges & (1 << edge))
			NSDivideRect(rect, &edgeRect, &rect, BORDER_SIZE, edge);
	}
	if (rect.size.width < minSize.width)
		rect.size.width = minSize.width;
	if (rect.size.height < minSize.height)
		rect.size.height = minSize.height;
	return rect;
}

@end
