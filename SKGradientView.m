//
//  SKGradientView.m
//  Skim
//
//  Created by Adam Maxwell on 10/26/05.
/*
 This software is Copyright (c) 2005-2020
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
#import "NSColor_SKExtensions.h"

#define BORDER_SIZE 1.0

// @@ Dark mode

static CGFloat oldDefaultGrays[5] = {0.75, 0.9,  0.8, 0.95,  0.55};
static CGFloat defaultGrays[10] = {0.85, 0.9,  0.9, 0.95,  0.75,   0.2, 0.25,  0.15, 0.15,  0.05};

@implementation SKGradientView

@synthesize contentView, backgroundColors, alternateBackgroundColors, edgeColor, minSize, maxSize, edges, clipEdges, autoTransparent;
@dynamic contentRect;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        minSize = NSZeroSize;
        maxSize = NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX);
        edges = SKNoEdgeMask; // we start with no edge, so we can use this in IB without getting weird offsets
		clipEdges = SKMaxXEdgeMask | SKMaxYEdgeMask;
        autoTransparent = NO;
        contentView = [[NSView alloc] initWithFrame:[self contentRect]];
		[super addSubview:contentView];
        if (RUNNING_BEFORE(10_10)) {
            backgroundColors = [[NSArray alloc] initWithObjects:[NSColor colorWithCalibratedWhite:oldDefaultGrays[0] alpha:1.0], [NSColor colorWithCalibratedWhite:oldDefaultGrays[1] alpha:1.0], nil];
            alternateBackgroundColors = [[NSArray alloc] initWithObjects:[NSColor colorWithCalibratedWhite:oldDefaultGrays[2] alpha:1.0], [NSColor colorWithCalibratedWhite:oldDefaultGrays[3] alpha:1.0], nil];
            edgeColor = [[NSColor colorWithDeviceWhite:oldDefaultGrays[4] alpha:1.0] retain];
        } else {
            backgroundColors = [[NSArray alloc] initWithObjects:[NSColor colorWithCalibratedAquaWhite:defaultGrays[0] alpha:1.0 darkAquaWhite:defaultGrays[5] alpha:1.0], [NSColor colorWithCalibratedAquaWhite:defaultGrays[1] alpha:1.0 darkAquaWhite:defaultGrays[6] alpha:1.0], nil];
            alternateBackgroundColors = [[NSArray alloc] initWithObjects:[NSColor colorWithCalibratedAquaWhite:defaultGrays[2] alpha:1.0 darkAquaWhite:defaultGrays[7] alpha:1.0], [NSColor colorWithCalibratedAquaWhite:defaultGrays[3] alpha:1.0 darkAquaWhite:defaultGrays[8] alpha:1.0], nil];
            edgeColor = [[NSColor colorWithCalibratedAquaWhite:defaultGrays[4] alpha:1.0 darkAquaWhite:defaultGrays[9] alpha:1.0] retain];
        }
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
	self = [super initWithCoder:decoder];
    if (self) {
		// this decodes only the reference, the actual view should already be decoded as a subview
        contentView = [[decoder decodeObjectForKey:@"contentView"] retain];
        backgroundColors = [[decoder decodeObjectForKey:@"backgroundColors"] retain];
        alternateBackgroundColors = [[decoder decodeObjectForKey:@"alternateBackgroundColors"] retain];
        edgeColor = [[decoder decodeObjectForKey:@"edgeColor"] retain];
		minSize.width = [decoder decodeDoubleForKey:@"minSize.width"];
		minSize.height = [decoder decodeDoubleForKey:@"minSize.height"];
		maxSize.width = [decoder decodeDoubleForKey:@"maxSize.width"];
		maxSize.height = [decoder decodeDoubleForKey:@"maxSize.height"];
		edges = [decoder decodeIntegerForKey:@"edges"];
		clipEdges = [decoder decodeIntegerForKey:@"clipEdges"];
		autoTransparent = [decoder decodeBoolForKey:@"autoTransparent"];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    // this encodes only a reference, the actual contentView should already be encoded because it's a subview
    [coder encodeConditionalObject:contentView forKey:@"contentView"];
    [coder encodeObject:backgroundColors forKey:@"backgroundColors"];
    [coder encodeObject:alternateBackgroundColors forKey:@"alternateBackgroundColors"];
    [coder encodeDouble:minSize.width forKey:@"minSize.width"];
    [coder encodeDouble:minSize.height forKey:@"minSize.height"];
    [coder encodeDouble:maxSize.width forKey:@"maxSize.width"];
    [coder encodeDouble:maxSize.height forKey:@"maxSize.height"];
    [coder encodeInteger:edges forKey:@"edges"];
    [coder encodeInteger:clipEdges forKey:@"clipEdges"];
    [coder encodeBool:autoTransparent forKey:@"autoTransparent"];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    SKDESTROY(contentView);
    SKDESTROY(backgroundColors);
    SKDESTROY(alternateBackgroundColors);
    SKDESTROY(edgeColor);
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
	if (autoTransparent && [[self window] styleMask] == NSBorderlessWindowMask)
        return;
    
    NSRect rect = [self bounds];
	NSRect edgeRect;
	NSInteger edge = 4;
	
    [NSGraphicsContext saveGraphicsState];
    
    [[self edgeColor] set];
	while (--edge >= 0) {
		if ((edges & (1 << edge)) == 0)
			continue;
		NSDivideRect(rect, &edgeRect, &rect, BORDER_SIZE, edge);
		NSRectFill(edgeRect);
	}
    
    NSArray *colors = backgroundColors;
    if (alternateBackgroundColors && [[self window] isMainWindow] == NO && [[self window] isKeyWindow] == NO)
        colors = alternateBackgroundColors;
    
    if ([colors count] > 1) {
        NSGradient *aGradient = [[NSGradient alloc] initWithColors:colors];
        [aGradient drawInRect:rect angle:90.0];
        [aGradient release];
    } else if ([colors count] == 1) {
        [[colors firstObject] setFill];
        [NSBezierPath fillRect:rect];
    }
    
    [NSGraphicsContext restoreGraphicsState];
}

- (void)handleKeyOrMainStateChangedNotification:(NSNotification *)note {
    [self setNeedsDisplay:YES];
}

- (void)viewWillMoveToWindow:(NSWindow *)newWindow {
    NSWindow *oldWindow = [self window];
    if (oldWindow) {
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc removeObserver:self name:NSWindowDidBecomeMainNotification object:oldWindow];
        [nc removeObserver:self name:NSWindowDidResignMainNotification object:oldWindow];
        [nc removeObserver:self name:NSWindowDidBecomeKeyNotification object:oldWindow];
        [nc removeObserver:self name:NSWindowDidResignKeyNotification object:oldWindow];
    }
    if (newWindow) {
        BOOL hasBorder = [newWindow styleMask] != NSBorderlessWindowMask;
        if (hasBorder) {
            NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
            [nc addObserver:self selector:@selector(handleKeyOrMainStateChangedNotification:) name:NSWindowDidBecomeMainNotification object:newWindow];
            [nc addObserver:self selector:@selector(handleKeyOrMainStateChangedNotification:) name:NSWindowDidResignMainNotification object:newWindow];
            [nc addObserver:self selector:@selector(handleKeyOrMainStateChangedNotification:) name:NSWindowDidBecomeKeyNotification object:newWindow];
            [nc addObserver:self selector:@selector(handleKeyOrMainStateChangedNotification:) name:NSWindowDidResignKeyNotification object:newWindow];
        }
        if (autoTransparent)
            [self setEdges:hasBorder ? SKMinXEdgeMask | SKMaxXEdgeMask : SKNoEdgeMask];
    }
    [super viewWillMoveToWindow:newWindow];
}

// required in order for redisplay to work properly with the controls
- (BOOL)isOpaque{ return autoTransparent && [[self window] styleMask] != NSBorderlessWindowMask; }

- (void)setContentView:(NSView *)aView {
	if (aView != contentView) {
        NSArray *subviews = [[contentView subviews] copy];
        [aView setFrame:[contentView frame]];
        for (NSView *view in subviews)
            [aView addSubview:view];
        [subviews release];
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

- (void)setAutoTransparent:(BOOL)flag {
    if (flag != autoTransparent) {
        autoTransparent = flag;
        if (autoTransparent)
            [self setEdges:[[self window] styleMask] != NSBorderlessWindowMask ? SKMinXEdgeMask | SKMaxXEdgeMask : SKNoEdgeMask];
        [self setNeedsDisplay:YES];
    }
}

- (NSRect)contentRect {
	NSRect rect = [self bounds];
	NSRect edgeRect;
	NSRectEdge edge = 4;
	while (edge-- > 0) {
		if (edges & (1 << edge))
			NSDivideRect(rect, &edgeRect, &rect, BORDER_SIZE, edge);
	}
	if (rect.size.width < minSize.width) {
        if ((clipEdges & SKMinXEdgeMask)) {
            if ((clipEdges & SKMaxXEdgeMask))
                rect.origin.x -= floor(0.5 * (minSize.width - NSWidth(rect)));
            else
                rect.origin.x -= minSize.width - NSWidth(rect);
        }
		rect.size.width = minSize.width;
	}
	else if (rect.size.width > maxSize.width) {
        if ((clipEdges & SKMinXEdgeMask)) {
            if ((clipEdges & SKMaxXEdgeMask))
                rect.origin.x -= floor(0.5 * (maxSize.width - NSWidth(rect)));
            else
                rect.origin.x -= maxSize.width - NSWidth(rect);
        }
		rect.size.width = maxSize.width;
	}
    if (rect.size.height < minSize.height) {
        if ((clipEdges & SKMinYEdgeMask)) {
            if ((clipEdges & SKMinYEdgeMask))
                rect.origin.y -= floor(0.5 * (minSize.height - NSHeight(rect)));
            else
                rect.origin.y -= minSize.height - NSHeight(rect);
        }
		rect.size.height = minSize.height;
    }
    else if (rect.size.height > maxSize.height) {
        if ((clipEdges & SKMinYEdgeMask)) {
            if ((clipEdges & SKMinYEdgeMask))
                rect.origin.y -= floor(0.5 * (maxSize.height - NSHeight(rect)));
            else
                rect.origin.y -= maxSize.height - NSHeight(rect);
        }
		rect.size.height = maxSize.height;
    }
	return rect;
}

@end
