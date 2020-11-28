//
//  SKTopBarView.m
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

#import "SKTopBarView.h"
#import "SKReflectionView.h"
#import "NSGeometry_SKExtensions.h"
#import "NSColor_SKExtensions.h"
#import "NSView_SKExtensions.h"

#define SKDisableSearchBarBlurringKey @"SKDisableSearchBarBlurring"

#define SEPARATOR_WIDTH 1.0

@implementation SKTopBarView

@synthesize contentView, backgroundColors, alternateBackgroundColors, separatorColor, minSize, maxSize, overflowEdge, hasSeparator, drawsBackground;
@dynamic contentRect, interiorRect;

- (id)initWithFrame:(NSRect)frame {
    wantsSubviews = YES;
    self = [super initWithFrame:frame];
    if (self) {
        minSize = NSZeroSize;
        maxSize = NSMakeSize(FLT_MAX, FLT_MAX);
        hasSeparator = NO; // we start with no separator, so we can use this in IB without getting weird offsets
		overflowEdge = NSMaxXEdge;
        drawsBackground = YES;
        if (RUNNING_AFTER(10_13)) {
            backgroundColors = nil;
            alternateBackgroundColors = nil;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"
            separatorColor = [[NSColor separatorColor] retain];
#pragma clang diagnostic pop
            NSVisualEffectView *view = [[NSVisualEffectView alloc] init];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"
            [view setMaterial:NSVisualEffectMaterialHeaderView];
#pragma clang diagnostic pop
            [view setBlendingMode:NSVisualEffectBlendingModeWithinWindow];
            if ([[NSUserDefaults standardUserDefaults] boolForKey:SKDisableSearchBarBlurringKey]) {
                backgroundView = [view retain];
            } else {
                backgroundView = [[SKReflectionView alloc] init];
                [view setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
                [backgroundView addSubview:view];
            }
            [backgroundView setFrame:[self interiorRect]];
            [super addSubview:backgroundView];
        } else {
            static CGFloat defaultGrays[5] = {0.85, 0.9,  0.9, 0.95,  0.75};
            backgroundColors = [[NSArray alloc] initWithObjects:[NSColor colorWithCalibratedWhite:defaultGrays[0] alpha:1.0], [NSColor colorWithCalibratedWhite:defaultGrays[1] alpha:1.0], nil];
            alternateBackgroundColors = [[NSArray alloc] initWithObjects:[NSColor colorWithCalibratedWhite:defaultGrays[2] alpha:1.0], [NSColor colorWithCalibratedWhite:defaultGrays[3] alpha:1.0], nil];
            separatorColor = [[NSColor colorWithCalibratedWhite:defaultGrays[4] alpha:1.0] retain];
        }
        contentView = [[NSView alloc] initWithFrame:[self contentRect]];
        [super addSubview:contentView];
        wantsSubviews = NO;
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
        separatorColor = [[decoder decodeObjectForKey:@"separatorColor"] retain];
		minSize.width = [decoder decodeDoubleForKey:@"minSize.width"];
		minSize.height = [decoder decodeDoubleForKey:@"minSize.height"];
		maxSize.width = [decoder decodeDoubleForKey:@"maxSize.width"];
		maxSize.height = [decoder decodeDoubleForKey:@"maxSize.height"];
		overflowEdge = [decoder decodeIntegerForKey:@"overflowEdge"];
        hasSeparator = [decoder decodeBoolForKey:@"hasSeparator"];
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
    [coder encodeInteger:overflowEdge forKey:@"overflowEdge"];
    [coder encodeBool:hasSeparator forKey:@"hasSeparator"];
    [coder encodeBool:drawsBackground forKey:@"drawsBackground"];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    SKDESTROY(contentView);
    SKDESTROY(backgroundView);
    SKDESTROY(backgroundColors);
    SKDESTROY(alternateBackgroundColors);
    SKDESTROY(separatorColor);
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
	
    [NSGraphicsContext saveGraphicsState];
    
    if (hasSeparator) {
        NSRect edgeRect;
		NSDivideRect(rect, &edgeRect, &rect, SEPARATOR_WIDTH, NSMinYEdge);
        [[self separatorColor] setFill];
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

- (void)setHasSeparator:(BOOL)flag {
	if (flag != hasSeparator) {
		hasSeparator = flag;
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
        [self setNeedsDisplay:YES];
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
    if (hasSeparator)
        rect = SKShrinkRect(rect, SEPARATOR_WIDTH, NSMinYEdge);
    return rect;
}

- (NSRect)contentRect {
	NSRect rect = [self interiorRect];
	if (NSWidth(rect) < minSize.width) {
        if (overflowEdge == NSMinXEdge)
            rect.origin.x -= minSize.width - NSWidth(rect);
		rect.size.width = minSize.width;
	}
	else if (NSWidth(rect) > maxSize.width) {
        if (overflowEdge == NSMinXEdge)
                rect.origin.x -= maxSize.width - NSWidth(rect);
		rect.size.width = maxSize.width;
	}
    if (NSHeight(rect) < minSize.height) {
		rect.size.height = minSize.height;
    }
    else if (NSHeight(rect) > maxSize.height) {
		rect.size.height = maxSize.height;
    }
	return rect;
}

- (void)reflectView:(NSView *)view animate:(BOOL)animate {
    if ([backgroundView respondsToSelector:@selector(setReflectedScrollView:)] == NO)
        return;
    NSScrollView *scrollView = [view descendantOfClass:[NSScrollView class]];
    if (scrollView == [(SKReflectionView *)backgroundView reflectedScrollView])
        return;
    if (animate == NO || [self drawsBackground] == NO) {
        [(SKReflectionView *)backgroundView setReflectedScrollView:scrollView];
    } else {
        SKReflectionView *bgView = [NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:backgroundView]];
        [bgView setReflectedScrollView:scrollView];
        wantsSubviews = YES;
        [[self animator] replaceSubview:backgroundView with:bgView];
        wantsSubviews = NO;
        [backgroundView release];
        backgroundView = [bgView retain];
    }
}

@end
