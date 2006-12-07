//
//  BDSKStatusBar.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 3/11/05.
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

#import "BDSKStatusBar.h"
#import <OmniBase/assertions.h>

#define LEFT_MARGIN						5.0
#define RIGHT_MARGIN					15.0
#define MARGIN_BETWEEN_TEXT_AND_SPINNER	2.0


@implementation BDSKStatusBar

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        cell = [[NSCell alloc] initTextCell:@""];
		[cell setFont:[NSFont labelFontOfSize:0]];
		
		progressIndicator = nil;
		
        [self setUpperColor:[NSColor colorWithCalibratedWhite:0.75 alpha:1.0]];
        [self setLowerColor:[NSColor colorWithCalibratedWhite:0.9 alpha:1.0]];
    }
    return self;
}

- (void)dealloc {
	[cell release];
	[super dealloc];
}

- (void)drawRect:(NSRect)rect {
	NSRect textRect = [self bounds];
	NSSize size = [cell cellSize];
	
	[super drawRect:rect];
	
	textRect.origin.x += LEFT_MARGIN;
	if (progressIndicator == nil) 
		textRect.size.width = NSWidth(textRect) - LEFT_MARGIN - RIGHT_MARGIN;
	else
		textRect.size.width = NSMinX([progressIndicator frame]) - LEFT_MARGIN - MARGIN_BETWEEN_TEXT_AND_SPINNER;
	if (textRect.size.width < 0.0)
		textRect.size.width = 0.0;
	textRect.origin.y += floor((NSHeight(textRect) - size.height) / 2.0);
	textRect.size.height = size.height;
	[cell drawWithFrame:textRect inView:self];
}

- (BOOL)isVisible {
	BOOL isVisible = ([self superview] != nil);
	if (isVisible && [self respondsToSelector:@selector(isHidden)])
		isVisible = ([self isHidden] == NO);
	return isVisible;
}

- (void)toggleBelowView:(NSView *)view offset:(float)offset {
	NSRect viewFrame = [view frame];
	NSView *contentView = [[view window] contentView];
	NSRect statusRect = [contentView frame];
	float shiftHeight = NSHeight([self frame]) + offset;
	statusRect.size.height = NSHeight([self frame]);
	
	OBASSERT(contentView != nil);
	
	if ([self superview]) {
		viewFrame.size.height += shiftHeight;
		viewFrame.origin.y -= shiftHeight;
		[self removeFromSuperview];
	} else {
		viewFrame.size.height -= shiftHeight;
		viewFrame.origin.y += shiftHeight;
		[self setFrame:statusRect];
		[contentView  addSubview:self positioned:NSWindowBelow relativeTo:nil];
	}
	[view setFrame:viewFrame];
	[contentView setNeedsDisplayInRect:statusRect];
}

- (void)toggleInWindow:(NSWindow *)window offset:(float)offset {
	NSRect winFrame = [window frame];
	NSSize minSize = [window minSize];
	NSSize maxSize = [window maxSize];
	NSView *contentView = [window contentView];
	NSRect statusRect = [contentView frame];
	float shiftHeight = NSHeight([self frame]) + offset;
	statusRect.size.height = NSHeight([self frame]);
	
	OBASSERT(contentView != nil);
	
	if ([self superview]) {
		winFrame.size.height -= shiftHeight;
		winFrame.origin.y += shiftHeight;
		if (minSize.height != 0.0) minSize.height -= shiftHeight;
		if (maxSize.height != 0.0) maxSize.height -= shiftHeight;
		if (winFrame.size.height < 0.0) winFrame.size.height = 0.0;
		if (minSize.height < 0.0) minSize.height = 0.0;
		if (maxSize.height < 0.0) maxSize.height = 0.0;
		[self removeFromSuperview];
	} else {
		winFrame.size.height += shiftHeight;
		winFrame.origin.y -= shiftHeight;
		if (minSize.height != 0.0) minSize.height += shiftHeight;
		if (maxSize.height != 0.0) maxSize.height += shiftHeight;
		[self setFrame:statusRect];
		[contentView  addSubview:self positioned:NSWindowBelow relativeTo:nil];
	}
	[window setFrame:winFrame display:YES];
	[window setMinSize:minSize];
	[window setMaxSize:maxSize];
}

#pragma mark Text cell accessors

- (NSString *)stringValue {
	return [cell stringValue];
}

- (void)setStringValue:(NSString *)aString {
	[cell setStringValue:aString];
	[self setNeedsDisplay:YES];
}

- (NSAttributedString *)attributedStringValue {
	return [cell attributedStringValue];
}

- (void)setAttributedStringValue:(NSAttributedString *)object {
	[cell setAttributedStringValue:object];
	[self setNeedsDisplay:YES];
}

- (NSFont *)font {
	return [cell font];
}

- (void)setFont:(NSFont *)fontObject {
	[cell setFont:fontObject];
	[self setNeedsDisplay:YES];
}

- (id)cell {
	return cell;
}

- (void)setCell:(NSCell *)aCell {
	if (aCell != cell) {
		[cell release];
		cell = [aCell retain];
	}
}

#pragma mark Progress indicator

- (NSProgressIndicator *)progressIndicator {
	return progressIndicator;
}

- (BDSKProgressIndicatorStyle)progressIndicatorStyle {
	if (progressIndicator == nil)
		return BDSKProgressIndicatorNone;
	else
		return [progressIndicator style];
}

- (void)setProgressIndicatorStyle:(BDSKProgressIndicatorStyle)style {
	if (style == BDSKProgressIndicatorNone) {
		if (progressIndicator == nil)
			return;
		[progressIndicator removeFromSuperview];
		progressIndicator = nil;
	} else {
		if ([progressIndicator style] == style)
			return;
		progressIndicator = [[NSProgressIndicator alloc] init];
		[progressIndicator setAutoresizingMask:NSViewMinXMargin | NSViewMinYMargin | NSViewMaxYMargin];
		[progressIndicator setStyle:style];
		[progressIndicator setControlSize:NSSmallControlSize];
		[progressIndicator setIndeterminate:YES];
		[progressIndicator setDisplayedWhenStopped:NO];
		[progressIndicator sizeToFit];
		[self addSubview:progressIndicator];
		[progressIndicator release];
		
		NSRect rect = [self bounds];
		NSSize size = [progressIndicator frame].size;
		rect.origin.x = NSMaxX(rect) - RIGHT_MARGIN - size.width;
		rect.origin.y = floor(NSMidY(rect) - size.height/2.0);
		rect.size = size;
		[progressIndicator setFrame:rect];
	}
	[[self superview] setNeedsDisplayInRect:[self frame]];
}

- (void)startAnimation:(id)sender {
	[progressIndicator startAnimation:sender];
}

- (void)stopAnimation:(id)sender {
	[progressIndicator stopAnimation:sender];
}

@end
