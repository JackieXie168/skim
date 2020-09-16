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
#import "SKReflectionView.h"
#import "NSGeometry_SKExtensions.h"
#import "NSColor_SKExtensions.h"
#import "NSView_SKExtensions.h"

#define SKDisableSearchBarBlurringKey @"SKDisableSearchBarBlurring"

#define BORDER_SIZE 1.0

static CGFloat oldDefaultGrays[5] = {0.75, 0.9,  0.8, 0.95,  0.55};
static CGFloat defaultGrays[5] = {0.85, 0.9,  0.9, 0.95,  0.75};

@implementation SKGradientView

@synthesize contentView, backgroundView, backgroundColors, alternateBackgroundColors, edgeColor, minSize, maxSize, edges, clipEdges, drawsBackground;
@dynamic contentRect, interiorRect;

- (id)initWithFrame:(NSRect)frame {
    wantsSubviews = YES;
    self = [super initWithFrame:frame];
    if (self) {
        minSize = NSZeroSize;
        maxSize = NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX);
        edges = SKNoEdgeMask; // we start with no edge, so we can use this in IB without getting weird offsets
		clipEdges = SKMaxXEdgeMask | SKMaxYEdgeMask;
        drawsBackground = YES;
        if (RUNNING_AFTER(10_13)) {
            NSView *view = [NSView visualEffectViewWithMaterial:SKVisualEffectMaterialHeaderView active:NO blendInWindow:YES];
            if ([[NSUserDefaults standardUserDefaults] boolForKey:SKDisableSearchBarBlurringKey]) {
                backgroundView = [view retain];
            } else {
                backgroundView = [[SKReflectionView alloc] initWithFrame:[self interiorRect]];
                [view setFrame:[backgroundView bounds]];
                [view setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
                [backgroundView addSubview:view];
            }
            [super addSubview:backgroundView];
        }
        contentView = [[NSView alloc] initWithFrame:[self contentRect]];
        [super addSubview:contentView];
        wantsSubviews = NO;
        if (RUNNING_AFTER(10_13)) {
            backgroundColors = nil;
            alternateBackgroundColors = nil;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"
            edgeColor = [[NSColor separatorColor] retain];
#pragma clang diagnostic pop
        } else if (RUNNING_BEFORE(10_10)) {
            backgroundColors = [[NSArray alloc] initWithObjects:[NSColor colorWithCalibratedWhite:oldDefaultGrays[0] alpha:1.0], [NSColor colorWithCalibratedWhite:oldDefaultGrays[1] alpha:1.0], nil];
            alternateBackgroundColors = [[NSArray alloc] initWithObjects:[NSColor colorWithCalibratedWhite:oldDefaultGrays[2] alpha:1.0], [NSColor colorWithCalibratedWhite:oldDefaultGrays[3] alpha:1.0], nil];
            edgeColor = [[NSColor colorWithCalibratedWhite:oldDefaultGrays[4] alpha:1.0] retain];
        } else {
            backgroundColors = [[NSArray alloc] initWithObjects:[NSColor colorWithCalibratedWhite:defaultGrays[0] alpha:1.0], [NSColor colorWithCalibratedWhite:defaultGrays[1] alpha:1.0], nil];
            alternateBackgroundColors = [[NSArray alloc] initWithObjects:[NSColor colorWithCalibratedWhite:defaultGrays[2] alpha:1.0], [NSColor colorWithCalibratedWhite:defaultGrays[3] alpha:1.0], nil];
            edgeColor = [[NSColor colorWithCalibratedWhite:defaultGrays[4] alpha:1.0] retain];
        }
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    wantsSubviews = YES;
	self = [super initWithCoder:decoder];
    if (self) {
		// this decodes only the reference, the actual view should already be decoded as a subview
        contentView = [[decoder decodeObjectForKey:@"contentView"] retain];
        backgroundView = [[decoder decodeObjectForKey:@"backgroundView"] retain];
        backgroundColors = [[decoder decodeObjectForKey:@"backgroundColors"] retain];
        alternateBackgroundColors = [[decoder decodeObjectForKey:@"alternateBackgroundColors"] retain];
        edgeColor = [[decoder decodeObjectForKey:@"edgeColor"] retain];
		minSize.width = [decoder decodeDoubleForKey:@"minSize.width"];
		minSize.height = [decoder decodeDoubleForKey:@"minSize.height"];
		maxSize.width = [decoder decodeDoubleForKey:@"maxSize.width"];
		maxSize.height = [decoder decodeDoubleForKey:@"maxSize.height"];
		edges = [decoder decodeIntegerForKey:@"edges"];
		clipEdges = [decoder decodeIntegerForKey:@"clipEdges"];
		drawsBackground = [decoder decodeBoolForKey:@"drawsBackground"];
        wantsSubviews = NO;
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    // this encodes only a reference, the actual contentView should already be encoded because it's a subview
    [coder encodeConditionalObject:contentView forKey:@"contentView"];
    [coder encodeConditionalObject:backgroundView forKey:@"backgroundView"];
    [coder encodeObject:backgroundColors forKey:@"backgroundColors"];
    [coder encodeObject:alternateBackgroundColors forKey:@"alternateBackgroundColors"];
    [coder encodeDouble:minSize.width forKey:@"minSize.width"];
    [coder encodeDouble:minSize.height forKey:@"minSize.height"];
    [coder encodeDouble:maxSize.width forKey:@"maxSize.width"];
    [coder encodeDouble:maxSize.height forKey:@"maxSize.height"];
    [coder encodeInteger:edges forKey:@"edges"];
    [coder encodeInteger:clipEdges forKey:@"clipEdges"];
    [coder encodeBool:drawsBackground forKey:@"drawsBackground"];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    SKDESTROY(contentView);
    SKDESTROY(backgroundView);
    SKDESTROY(backgroundColors);
    SKDESTROY(alternateBackgroundColors);
    SKDESTROY(edgeColor);
	[super dealloc];
}

- (void)resizeSubviewsWithOldSize:(NSSize)size {
    [backgroundView setFrame:[self interiorRect]];
    [contentView setFrame:[self contentRect]];
}

- (void)addSubview:(NSView *)aView {
    if (wantsSubviews)
        [super addSubview:aView];
    else
        [contentView addSubview:aView];
}

- (void)addSubview:(NSView *)aView positioned:(NSWindowOrderingMode)place relativeTo:(NSView *)otherView {
    if (wantsSubviews)
        [super addSubview:aView positioned:place relativeTo:otherView];
    else
        [contentView addSubview:aView positioned:place relativeTo:otherView];
}

- (void)replaceSubview:(NSView *)aView with:(NSView *)newView {
    if (wantsSubviews)
        [super replaceSubview:aView with:newView];
    else
        [contentView replaceSubview:aView with:newView];

}

- (void)drawRect:(NSRect)aRect
{        
	if ([self drawsBackground] == NO)
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
        [NSBezierPath fillRect:edgeRect];
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

- (void)startObservingWindow:(NSWindow *)window {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(handleKeyOrMainStateChangedNotification:) name:NSWindowDidBecomeMainNotification object:window];
    [nc addObserver:self selector:@selector(handleKeyOrMainStateChangedNotification:) name:NSWindowDidResignMainNotification object:window];
    [nc addObserver:self selector:@selector(handleKeyOrMainStateChangedNotification:) name:NSWindowDidBecomeKeyNotification object:window];
    [nc addObserver:self selector:@selector(handleKeyOrMainStateChangedNotification:) name:NSWindowDidResignKeyNotification object:window];
}

- (void)stopObservingWindow:(NSWindow *)window {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:NSWindowDidBecomeMainNotification object:window];
    [nc removeObserver:self name:NSWindowDidResignMainNotification object:window];
    [nc removeObserver:self name:NSWindowDidBecomeKeyNotification object:window];
    [nc removeObserver:self name:NSWindowDidResignKeyNotification object:window];
}

- (void)viewWillMoveToWindow:(NSWindow *)newWindow {
    if (drawsBackground && alternateBackgroundColors) {
        NSWindow *oldWindow = [self window];
        if (oldWindow)
            [self stopObservingWindow:oldWindow];
        if (newWindow)
            [self startObservingWindow:newWindow];
    }
    [super viewWillMoveToWindow:newWindow];
}

// required in order for redisplay to work properly with the controls
- (BOOL)isOpaque{ return [self drawsBackground] && [self backgroundColors]; }

- (void)setContentView:(NSView *)aView {
    if (aView != contentView) {
        [aView setFrame:[contentView frame]];
        wantsSubviews = YES;
        [super replaceSubview:contentView with:aView];
        wantsSubviews = NO;
        [contentView release];
        contentView = [aView retain];
    }
}

- (void)setBackgroundView:(NSView *)aView {
    if (aView != backgroundView) {
        [backgroundView removeFromSuperview];
        [backgroundView release];
        backgroundView = [aView retain];
        if (aView) {
            [aView setFrame:[self interiorRect]];
            wantsSubviews = YES;
            [super addSubview:aView positioned:NSWindowBelow relativeTo:nil];
            wantsSubviews = NO;
            [aView setHidden:[self drawsBackground] == NO];
        }
    }
}

- (void)setEdges:(SKRectEdges)mask {
	if (mask != edges) {
		edges = mask;
        [backgroundView setFrame:[self interiorRect]];
        [contentView setFrame:[self contentRect]];
		[self setNeedsDisplay:YES];
	}
}

- (void)setDrawsBackground:(BOOL)flag {
    if (flag != drawsBackground) {
        if ([self window] && alternateBackgroundColors) {
            if (drawsBackground)
                [self stopObservingWindow:[self window]];
            else
                [self startObservingWindow:[self window]];
        }
        drawsBackground = flag;
        [backgroundView setHidden:drawsBackground == NO];
    }
}

- (void)setAlternateBackgroundColors:(NSArray *)colors {
    if (colors != alternateBackgroundColors) {
        if ([self window] && drawsBackground) {
            if (alternateBackgroundColors && colors == nil)
                [self stopObservingWindow:[self window]];
            else if (alternateBackgroundColors == nil && colors)
                [self startObservingWindow:[self window]];
        }
        [alternateBackgroundColors release];
        alternateBackgroundColors = [colors copy];
    }
}

- (NSRect)interiorRect {
    NSRect rect = [self bounds];
    NSRect edgeRect;
    NSRectEdge edge = 4;
    while (edge-- > 0) {
        if (edges & (1 << edge))
            NSDivideRect(rect, &edgeRect, &rect, BORDER_SIZE, edge);
    }
    return rect;
}

- (NSRect)contentRect {
	NSRect rect = [self interiorRect];
	if (NSWidth(rect) < minSize.width) {
        if ((clipEdges & SKMinXEdgeMask)) {
            if ((clipEdges & SKMaxXEdgeMask))
                rect.origin.x -= floor(0.5 * (minSize.width - NSWidth(rect)));
            else
                rect.origin.x -= minSize.width - NSWidth(rect);
        }
		rect.size.width = minSize.width;
	}
	else if (NSWidth(rect) > maxSize.width) {
        if ((clipEdges & SKMinXEdgeMask)) {
            if ((clipEdges & SKMaxXEdgeMask))
                rect.origin.x -= floor(0.5 * (maxSize.width - NSWidth(rect)));
            else
                rect.origin.x -= maxSize.width - NSWidth(rect);
        }
		rect.size.width = maxSize.width;
	}
    if (NSHeight(rect) < minSize.height) {
        if ((clipEdges & SKMinYEdgeMask)) {
            if ((clipEdges & SKMinYEdgeMask))
                rect.origin.y -= floor(0.5 * (minSize.height - NSHeight(rect)));
            else
                rect.origin.y -= minSize.height - NSHeight(rect);
        }
		rect.size.height = minSize.height;
    }
    else if (NSHeight(rect) > maxSize.height) {
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

- (void)reflectView:(NSView *)view {
    if ([backgroundView respondsToSelector:@selector(setReflectedScrollView:)])
        [(SKReflectionView *)backgroundView setReflectedScrollView:[view subviewOfClass:[NSScrollView class]]];
}

@end
