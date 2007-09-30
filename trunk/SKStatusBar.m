//
//  SKStatusBar.m
//  Skim
//
//  Created by Christiaan Hofman on 7/8/07.
/*
 This software is Copyright (c) 2007
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

#import "SKStatusBar.h"
#import "NSBezierPath_CoreImageExtensions.h"

#define LEFT_MARGIN         5.0
#define RIGHT_MARGIN        15.0
#define SEPARATION          2.0
#define PROGRESSBAR_WIDTH   100.0

@implementation SKStatusBar

+ (CIColor *)lowerColor{
    static CIColor *lowerColor = nil;
    if (lowerColor == nil)
        lowerColor = [[CIColor alloc] initWithColor:[NSColor colorWithCalibratedWhite:0.75 alpha:1.0]];
    return lowerColor;
}

+ (CIColor *)upperColor{
    static CIColor *upperColor = nil;
    if (upperColor == nil)
        upperColor = [[CIColor alloc] initWithColor:[NSColor colorWithCalibratedWhite:0.9 alpha:1.0]];
    return upperColor;
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        leftCell = [[NSCell alloc] initTextCell:@""];
		[leftCell setFont:[NSFont labelFontOfSize:0]];
        [leftCell setAlignment:NSLeftTextAlignment];
        [leftCell setControlView:self];
        rightCell = [[NSActionCell alloc] initTextCell:@""];
		[rightCell setFont:[NSFont labelFontOfSize:0]];
        [rightCell setAlignment:NSRightTextAlignment];
        [rightCell setControlView:self];
		progressIndicator = nil;
    }
    return self;
}

- (void)dealloc {
	[leftCell release];
	[rightCell release];
	[super dealloc];
}

- (BOOL)isOpaque{  return YES; }

- (BOOL)isFlipped { return NO; }

- (void)drawRect:(NSRect)rect {
	NSRect textRect, ignored;
    float rightMargin = RIGHT_MARGIN;
    
    [[NSBezierPath bezierPathWithRect:[self bounds]] fillPathVerticallyWithStartColor:[[self class] upperColor] endColor:[[self class] lowerColor]];
    
    if (progressIndicator)
        rightMargin += NSWidth([progressIndicator frame]) + SEPARATION;
    NSDivideRect([self bounds], &ignored, &textRect, LEFT_MARGIN, NSMinXEdge);
    NSDivideRect(textRect, &ignored, &textRect, rightMargin, NSMaxXEdge);
	
	if (textRect.size.width < 0.0)
		textRect.size.width = 0.0;
	
    float height = fmaxf([leftCell cellSize].height, [rightCell cellSize].height);
    textRect.origin.y += 0.5f * (NSHeight(textRect) - height);
    textRect.origin.y = [self isFlipped] ? ceilf(NSMinY(textRect))  : floorf(NSMinY(textRect));
    textRect.size.height = height;
    
	[leftCell drawWithFrame:textRect inView:self];
	[rightCell drawWithFrame:textRect inView:self];
}

- (BOOL)isVisible {
	BOOL isVisible = ([self superview] != nil);
	if (isVisible && [self respondsToSelector:@selector(isHidden)])
		isVisible = ([self isHidden] == NO);
	return isVisible;
}

- (void)toggleBelowView:(NSView *)view offset:(float)offset {
	NSRect viewFrame = [view frame];
	NSView *contentView = [view superview];
	NSRect statusRect = [contentView bounds];
	float shiftHeight = NSHeight([self frame]) + offset;
	statusRect.size.height = NSHeight([self frame]);
	
	if ([self superview]) {
		viewFrame.size.height += shiftHeight;
		if ([contentView isFlipped] == NO)
			viewFrame.origin.y -= shiftHeight;
		[self removeFromSuperview];
	} else {
		viewFrame.size.height -= shiftHeight;
		if ([contentView isFlipped] == NO)
			viewFrame.origin.y += shiftHeight;
		else 
			statusRect.origin.y = NSMaxY([contentView bounds]) - NSHeight(statusRect);
		[self setFrame:statusRect];
		[contentView  addSubview:self positioned:NSWindowBelow relativeTo:nil];
	}
	[view setFrame:viewFrame];
	[contentView setNeedsDisplay:YES];
}

- (void)mouseDown:(NSEvent *)theEvent {
    if ([[rightCell stringValue] length]) {
        NSPoint mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        float width = [rightCell cellSize].width;
        NSRect ignored, rect = [self bounds];
        NSDivideRect([self bounds], &ignored, &rect, LEFT_MARGIN, NSMinXEdge);
        NSDivideRect(rect, &ignored, &rect, RIGHT_MARGIN, NSMaxXEdge);
        NSDivideRect(rect, &rect, &ignored, width, NSMaxXEdge);
        if (NSPointInRect(mouseLoc, rect)) {
            theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask];
            mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
            if (NSPointInRect(mouseLoc, rect)) {
                state = state == NSOnState ? NSOffState : NSOnState;
                [self sendAction:[rightCell action] to:[rightCell target]];
            }
        }
    }
}

#pragma mark Text cell accessors

- (NSString *)leftStringValue {
	return [leftCell stringValue];
}

- (void)setLeftStringValue:(NSString *)aString {
	[leftCell setStringValue:aString];
	[self setNeedsDisplay:YES];
}

- (NSAttributedString *)leftAttributedStringValue {
	return [leftCell attributedStringValue];
}

- (void)setLeftAttributedStringValue:(NSAttributedString *)object {
	[leftCell setAttributedStringValue:object];
	[self setNeedsDisplay:YES];
}

- (NSString *)rightStringValue {
	return [rightCell stringValue];
}

- (void)setRightStringValue:(NSString *)aString {
	[rightCell setStringValue:aString];
	[self setNeedsDisplay:YES];
}

- (NSAttributedString *)rightAttributedStringValue {
	return [rightCell attributedStringValue];
}

- (void)setRightAttributedStringValue:(NSAttributedString *)object {
	[rightCell setAttributedStringValue:object];
	[self setNeedsDisplay:YES];
}

- (NSFont *)font {
	return [leftCell font];
}

- (void)setFont:(NSFont *)fontObject {
	[leftCell setFont:fontObject];
	[rightCell setFont:fontObject];
	[self setNeedsDisplay:YES];
}

- (SEL)action {
    return [rightCell action];
}

- (void)setAction:(SEL)selector {
    [rightCell setAction:selector];
}

- (id)target {
    return [rightCell target];
}

- (void)setTarget:(id)newTarget {
    [rightCell setTarget:newTarget];
}

- (int)state {
    return state;
}

- (void)setState:(int)newState {
    if (state != newState) {
        state = newState;
    }
}

#pragma mark Progress indicator

- (NSProgressIndicator *)progressIndicator {
	return progressIndicator;
}

- (SKProgressIndicatorStyle)progressIndicatorStyle {
	if (progressIndicator == nil)
		return SKProgressIndicatorNone;
	else
		return [progressIndicator style];
}

- (void)setProgressIndicatorStyle:(SKProgressIndicatorStyle)style {
	if (style == SKProgressIndicatorNone) {
		if (progressIndicator == nil)
			return;
		[progressIndicator removeFromSuperview];
		progressIndicator = nil;
	} else {
		if (progressIndicator && (int)[progressIndicator style] == style)
			return;
		if(progressIndicator == nil) {
            progressIndicator = [[NSProgressIndicator alloc] init];
        } else {
            [progressIndicator retain];
            [progressIndicator removeFromSuperview];
		}
        [progressIndicator setAutoresizingMask:NSViewMinXMargin | NSViewMinYMargin | NSViewMaxYMargin];
		[progressIndicator setStyle:style];
		[progressIndicator setControlSize:NSSmallControlSize];
		[progressIndicator setIndeterminate:style == NSProgressIndicatorSpinningStyle];
		[progressIndicator setDisplayedWhenStopped:style == NSProgressIndicatorBarStyle];
        [progressIndicator setUsesThreadedAnimation:YES];
		[progressIndicator sizeToFit];
		
		NSRect rect, ignored;
		NSSize size = [progressIndicator frame].size;
        if (size.width < 0.01) size.width = PROGRESSBAR_WIDTH;
        NSDivideRect([self bounds], &ignored, &rect, RIGHT_MARGIN, NSMaxXEdge);
        NSDivideRect(rect, &rect, &ignored, size.width, NSMaxXEdge);
        rect.origin.y = floorf(NSMidY(rect) - 0.5 * size.height);
        rect.size.height = size.height;
		[progressIndicator setFrame:rect];
		
        [self addSubview:progressIndicator];
		[progressIndicator release];
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
