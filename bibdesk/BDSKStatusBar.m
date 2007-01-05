//
//  BDSKStatusBar.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 3/11/05.
/*
 This software is Copyright (c) 2005,2006,2007
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
#import "NSGeometry_BDSKExtensions.h"
#import <OmniBase/assertions.h>
#import "CIImage_BDSKExtensions.h"

#define LEFT_MARGIN				5.0
#define RIGHT_MARGIN			15.0
#define MARGIN_BETWEEN_ITEMS	2.0


@implementation BDSKStatusBar

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
        textCell = [[NSCell alloc] initTextCell:@""];
		[textCell setFont:[NSFont labelFontOfSize:0]];
		
        iconCell = [[NSImageCell alloc] init];
		
		progressIndicator = nil;
		
		icons = [[NSMutableArray alloc] initWithCapacity:2];
		
		delegate = nil;
        
        textOffset = 0.0;

    }
    return self;
}

- (void)dealloc {
	[textCell release];
	[iconCell release];
	[icons release];
	[super dealloc];
}

- (CIColor *)upperColor
{
    return [[self class] upperColor];
}

- (CIColor *)lowerColor
{
    return [[self class] lowerColor];
}

- (void)drawRect:(NSRect)rect {
	NSRect textRect, ignored;
    float rightMargin = RIGHT_MARGIN;
	
	[super drawRect:rect];
    
    if (progressIndicator)
        rightMargin += NSWidth([progressIndicator frame]) + MARGIN_BETWEEN_ITEMS;
    NSDivideRect([self bounds], &ignored, &textRect, LEFT_MARGIN + textOffset, NSMinXEdge);
    NSDivideRect(textRect, &ignored, &textRect, rightMargin, NSMaxXEdge);
	
	NSEnumerator *dictEnum = [icons objectEnumerator];
	NSDictionary *dict;
	NSImage *icon;
	NSRect iconRect;
	NSSize size;
	
	while (dict = [dictEnum nextObject]) {
		icon = [dict objectForKey:@"icon"];
		size = [icon size];
        NSDivideRect(textRect, &iconRect, &textRect, size.width, NSMaxXEdge);
        NSDivideRect(textRect, &ignored, &textRect, MARGIN_BETWEEN_ITEMS, NSMaxXEdge);
        iconRect = BDSKCenterRectVertically(iconRect, size.height, [self isFlipped]);
		[iconCell setImage:icon];
		[iconCell drawWithFrame:iconRect inView:self];
	}
	
	if (textRect.size.width < 0.0)
		textRect.size.width = 0.0;
	size = [textCell cellSize];
    textRect = BDSKCenterRectVertically(textRect, size.height, [self isFlipped]);
	[textCell drawWithFrame:textRect inView:self];
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
	
	OBASSERT(contentView != nil);
	
	if ([self superview]) {
		OBASSERT([[self superview] isEqual:contentView]);
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

- (void)toggleInWindow:(NSWindow *)window offset:(float)offset {
	NSRect winFrame = [window frame];
	NSSize minSize = [window minSize];
	NSSize maxSize = [window maxSize];
	NSView *contentView = [window contentView];
	float shiftHeight = NSHeight([self frame]) + offset;
	BOOL autoresizes = [contentView autoresizesSubviews];
	NSEnumerator *viewEnum = [[contentView subviews] objectEnumerator];
	NSView *view;
	NSRect viewFrame;
	
	OBASSERT(contentView != nil);
	
	if ([self superview])
		shiftHeight = -shiftHeight;
	
	if ([contentView isFlipped] == NO) {
		while (view = [viewEnum nextObject]) {
			viewFrame = [view frame];
			viewFrame.origin.y += shiftHeight;
			[view setFrame:viewFrame];
		}
	}
	winFrame.size.height += shiftHeight;
	winFrame.origin.y -= shiftHeight;
	if (minSize.height > 0.0) minSize.height += shiftHeight;
	if (maxSize.height > 0.0) maxSize.height += shiftHeight;
	if (winFrame.size.height < 0.0) winFrame.size.height = 0.0;
	if (minSize.height < 0.0) minSize.height = 0.0;
	if (maxSize.height < 0.0) maxSize.height = 0.0;
	
	if ([self superview]) {
		[self removeFromSuperview];
	} else {
		NSRect statusRect = [contentView bounds];
		statusRect.size.height = NSHeight([self frame]);
		if ([contentView isFlipped] == YES)
			statusRect.origin.y = NSMaxY([contentView bounds]) - NSHeight(statusRect);
		[self setFrame:statusRect];
		[contentView addSubview:self positioned:NSWindowBelow relativeTo:nil];
	}
	
	[contentView setAutoresizesSubviews:NO];
	[window setFrame:winFrame display:YES];
	[contentView setAutoresizesSubviews:autoresizes];
	[window setMinSize:minSize];
	[window setMaxSize:maxSize];
}

#pragma mark Text cell accessors

- (NSString *)stringValue {
	return [textCell stringValue];
}

- (void)setStringValue:(NSString *)aString {
	[textCell setStringValue:aString];
	[self setNeedsDisplay:YES];
}

- (NSAttributedString *)attributedStringValue {
	return [textCell attributedStringValue];
}

- (void)setAttributedStringValue:(NSAttributedString *)object {
	[textCell setAttributedStringValue:object];
	[self setNeedsDisplay:YES];
}

- (NSFont *)font {
	return [textCell font];
}

- (void)setFont:(NSFont *)fontObject {
	[textCell setFont:fontObject];
	[self setNeedsDisplay:YES];
}

- (id)textCell {
	return textCell;
}

- (void)setTextCell:(NSCell *)aCell {
	if (aCell != textCell) {
		[textCell release];
		textCell = [aCell retain];
	}
}

- (float)textOffset {
    return textOffset;
}

- (void)setTextOffset:(float)offset {
    textOffset = offset;
    [self setNeedsDisplay:YES];
}

#pragma mark Icons

- (NSArray *)iconIdentifiers {
	NSMutableArray *IDs = [NSMutableArray arrayWithCapacity:[icons count]];
	NSEnumerator *dictEnum = [icons objectEnumerator];
	NSDictionary *dict;
	
	while (dict = [dictEnum nextObject]) {
		[IDs addObject:[dict objectForKey:@"identifier"]];
	}
	return IDs;
}

- (void)addIcon:(NSImage *)icon withIdentifier:(NSString *)identifier{
	[self addIcon:icon withIdentifier:identifier toolTip:nil];
}

- (void)addIcon:(NSImage *)icon withIdentifier:(NSString *)identifier toolTip:(NSString *)toolTip {
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:icon, @"icon", identifier, @"identifier", nil];
	if (toolTip != nil)
		[dict setObject:toolTip forKey:@"toolTip"];
	[icons addObject:dict];
	[self rebuildToolTips];
	[self setNeedsDisplay:YES];
}

- (void)removeIconWithIdentifier:(NSString *)identifier {
	unsigned i = [icons count];
	while (i--) {
		if ([[[icons objectAtIndex:i] objectForKey:@"identifier"] isEqualToString:identifier]) {
			[icons removeObjectAtIndex:i];
			[self rebuildToolTips];
			[self setNeedsDisplay:YES];
			break;
		}
	}
}

- (NSString *)view:(NSView *)view stringForToolTip:(NSToolTipTag)tag point:(NSPoint)point userData:(void *)userData {
	if ([delegate respondsToSelector:@selector(statusBar:toolTipForIdentifier:)])
		return [delegate statusBar:self toolTipForIdentifier:(NSString *)userData];
	
	NSEnumerator *dictEnum = [icons objectEnumerator];
	NSDictionary *dict;
	
	while (dict = [dictEnum nextObject]) {
		if ([[dict objectForKey:@"identifier"] isEqualToString:(NSString *)userData]) {
			return [dict objectForKey:@"toolTip"];
		}
	}
	return nil;
}

- (void)rebuildToolTips {
	NSRect ignored, rect;
    float rightMargin = RIGHT_MARGIN;
	
	if (progressIndicator != nil) 
		rightMargin += NSMinX([progressIndicator frame]) + MARGIN_BETWEEN_ITEMS;
	
    NSDivideRect([self bounds], &ignored, &rect, rightMargin, NSMaxXEdge);
    
	NSEnumerator *dictEnum = [icons objectEnumerator];
	NSDictionary *dict;
	NSRect iconRect;
    NSSize size;
	
	[self removeAllToolTips];
	
	while (dict = [dictEnum nextObject]) {
		size = [(NSImage *)[dict objectForKey:@"icon"] size];
        NSDivideRect(rect, &iconRect, &rect, size.width, NSMaxXEdge);
        NSDivideRect(rect, &ignored, &rect, MARGIN_BETWEEN_ITEMS, NSMaxXEdge);
        iconRect = BDSKCenterRectVertically(iconRect, size.height, [self isFlipped]);
		[self addToolTipRect:iconRect owner:self userData:[dict objectForKey:@"identifier"]];
	}
}

- (void)resetCursorRects {
	// CMH: I am not sure if this is the right place, but toolTip rects need to be reset when the view resizes
	[self rebuildToolTips];
}

- (id)delegate {
	return delegate;
}

- (void)setDelegate:(id)newDelegate {
	delegate = newDelegate;
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
		if ((int)[progressIndicator style] == style)
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
		[progressIndicator setIndeterminate:YES];
		[progressIndicator setDisplayedWhenStopped:NO];
		[progressIndicator sizeToFit];
		
		NSRect rect, ignored;
		NSSize size = [progressIndicator frame].size;
        NSDivideRect([self bounds], &ignored, &rect, RIGHT_MARGIN, NSMaxXEdge);
        NSDivideRect(rect, &rect, &ignored, size.width, NSMaxXEdge);
        rect = BDSKCenterRect(rect, size, [self isFlipped]);
		[progressIndicator setFrame:rect];
		
        [self addSubview:progressIndicator];
		[progressIndicator release];
	}
	[self rebuildToolTips];
	[[self superview] setNeedsDisplayInRect:[self frame]];
}

- (void)startAnimation:(id)sender {
	[progressIndicator startAnimation:sender];
}

- (void)stopAnimation:(id)sender {
	[progressIndicator stopAnimation:sender];
}

@end
