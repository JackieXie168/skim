//
//  SKStatusBar.m
//  Skim
//
//  Created by Christiaan Hofman on 7/8/07.
/*
 This software is Copyright (c) 2007-2009
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
#import "NSGeometry_SKExtensions.h"

#define LEFT_MARGIN         5.0
#define RIGHT_MARGIN        15.0
#define SEPARATION          2.0
#define VERTICAL_OFFSET     1.0
#define PROGRESSBAR_WIDTH   100.0
#define ICON_HEIGHT_OFFSET  2.0


@interface SKStatusTextFieldCell : NSTextFieldCell {
    BOOL underlined;
}
- (BOOL)isUnderlined;
- (void)setUnderlined:(BOOL)flag;
@end

#pragma mark -

@implementation SKStatusBar

+ (NSColor *)lowerColor{
    static NSColor *lowerColor = nil;
    if (lowerColor == nil)
        lowerColor = [[NSColor colorWithCalibratedWhite:0.75 alpha:1.0] retain];
    return lowerColor;
}

+ (NSColor *)upperColor{
    static NSColor *upperColor = nil;
    if (upperColor == nil)
        upperColor = [[NSColor colorWithCalibratedWhite:0.9 alpha:1.0] retain];
    return upperColor;
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        leftCell = [[SKStatusTextFieldCell alloc] initTextCell:@""];
		[leftCell setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
        [leftCell setAlignment:NSLeftTextAlignment];
        [leftCell setControlView:self];
        [leftCell setBackgroundStyle:NSBackgroundStyleRaised];
        rightCell = [[SKStatusTextFieldCell alloc] initTextCell:@""];
		[rightCell setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
        [rightCell setAlignment:NSRightTextAlignment];
        [rightCell setControlView:self];
        [rightCell setBackgroundStyle:NSBackgroundStyleRaised];
        iconCell = nil;
		progressIndicator = nil;
        leftTrackingRectTag = 0;
        rightTrackingRectTag = 0;
    }
    return self;
}

- (void)dealloc {
	[leftCell release];
	[rightCell release];
	[iconCell release];
	[super dealloc];
}

- (BOOL)isOpaque{  return YES; }

- (BOOL)isFlipped { return NO; }

- (void)getLeftFrame:(NSRect *)leftFrame rightFrame:(NSRect *)rightFrame {
    CGFloat leftWidth = [[leftCell stringValue] length] ? [leftCell cellSize].width : 0.0;
    CGFloat rightWidth = [[rightCell stringValue] length] ? [rightCell cellSize].width : 0.0;
    NSRect ignored, rect = [self bounds];
    CGFloat leftMargin = LEFT_MARGIN;
    CGFloat rightMargin = RIGHT_MARGIN;
    if (iconCell)
        leftMargin += NSHeight([self bounds]) - ICON_HEIGHT_OFFSET + SEPARATION;
    if (progressIndicator)
        rightMargin += NSWidth([progressIndicator frame]) + SEPARATION;
    NSDivideRect(rect, &ignored, &rect, leftMargin, NSMinXEdge);
    NSDivideRect(rect, &ignored, &rect, rightMargin, NSMaxXEdge);
    if (rightFrame != NULL)
        NSDivideRect(rect, rightFrame, &ignored, rightWidth, NSMaxXEdge);
    if (leftFrame != NULL)
        NSDivideRect(rect, leftFrame, &ignored, leftWidth, NSMinXEdge);
}

- (void)drawRect:(NSRect)rect {
    NSRect bounds = [self bounds];
    NSGradient *gradient = [[[NSGradient alloc] initWithStartingColor:[[self class] lowerColor] endingColor:[[self class] upperColor]] autorelease];
    
    [gradient drawInRect:bounds angle:90.0];
    
    NSRect textRect, iconRect, ignored;
    CGFloat rightMargin = RIGHT_MARGIN;
    CGFloat iconHeight = NSHeight(bounds) - ICON_HEIGHT_OFFSET;
    
    if (progressIndicator)
        rightMargin += NSWidth([progressIndicator frame]) + SEPARATION;
    NSDivideRect(bounds, &ignored, &textRect, LEFT_MARGIN, NSMinXEdge);
    NSDivideRect(textRect, &ignored, &textRect, rightMargin, NSMaxXEdge);
    if (iconCell) {
        NSDivideRect(textRect, &iconRect, &textRect, iconHeight, NSMinXEdge);
        NSDivideRect(textRect, &ignored, &textRect, SEPARATION, NSMaxXEdge);
    }
	
	if (textRect.size.width < 0.0)
		textRect.size.width = 0.0;
	
    CGFloat height = SKMax([leftCell cellSize].height, [rightCell cellSize].height);
    textRect = SKCenterRectVertically(textRect, height, NO);
    textRect.origin.y += VERTICAL_OFFSET;
    
	[leftCell drawWithFrame:textRect inView:self];
	[rightCell drawWithFrame:textRect inView:self];
    
    if (iconCell) {
        iconRect = SKCenterRectVertically(iconRect, iconHeight, NO);
        iconRect.origin.y += VERTICAL_OFFSET;
        [iconCell drawWithFrame:iconRect inView:self];
    }
}

- (BOOL)isVisible {
	return [self superview] && [self isHidden] == NO;
}

- (void)toggleBelowView:(NSView *)view offset:(CGFloat)offset {
	NSRect viewFrame = [view frame];
	NSView *contentView = [view superview];
	NSRect statusRect = [contentView bounds];
	CGFloat shiftHeight = NSHeight([self frame]) + offset;
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
    NSPoint mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    NSRect leftRect, rightRect;
    [self getLeftFrame:&leftRect rightFrame:&rightRect];
    if (NSMouseInRect(mouseLoc, rightRect, [self isFlipped])) {
        while ([theEvent type] != NSLeftMouseUp)
            theEvent = [[self window] nextEventMatchingMask: NSLeftMouseDraggedMask | NSLeftMouseUpMask];
        mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        if (NSMouseInRect(mouseLoc, rightRect, [self isFlipped]))
            [rightCell performClick:self];
    } else if (NSMouseInRect(mouseLoc, leftRect, [self isFlipped])) {
        while ([theEvent type] != NSLeftMouseUp)
            theEvent = [[self window] nextEventMatchingMask: NSLeftMouseDraggedMask | NSLeftMouseUpMask];
        mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        if (NSMouseInRect(mouseLoc, leftRect, [self isFlipped]))
            [leftCell performClick:self];
    }
}

#pragma mark Text cell accessors

- (NSString *)leftStringValue {
	return [leftCell stringValue];
}

- (void)setLeftStringValue:(NSString *)aString {
	[leftCell setStringValue:aString];
	[self setNeedsDisplay:YES];
    [self resetCursorRects];
}

- (NSAttributedString *)leftAttributedStringValue {
	return [leftCell attributedStringValue];
}

- (void)setLeftAttributedStringValue:(NSAttributedString *)object {
	[leftCell setAttributedStringValue:object];
	[self setNeedsDisplay:YES];
    [self resetCursorRects];
}

- (NSString *)rightStringValue {
	return [rightCell stringValue];
}

- (void)setRightStringValue:(NSString *)aString {
	[rightCell setStringValue:aString];
	[self setNeedsDisplay:YES];
    [self resetCursorRects];
}

- (NSAttributedString *)rightAttributedStringValue {
	return [rightCell attributedStringValue];
}

- (void)setRightAttributedStringValue:(NSAttributedString *)object {
	[rightCell setAttributedStringValue:object];
	[self setNeedsDisplay:YES];
    [self resetCursorRects];
}

- (NSFont *)font {
	return [leftCell font];
}

- (void)setFont:(NSFont *)fontObject {
	[leftCell setFont:fontObject];
	[rightCell setFont:fontObject];
	[self setNeedsDisplay:YES];
}

- (SEL)leftAction {
    return [leftCell action];
}

- (void)setLeftAction:(SEL)selector {
    [leftCell setAction:selector];
    [self resetCursorRects];
}

- (id)leftTarget {
    return [leftCell target];
}

- (void)setLeftTarget:(id)newTarget {
    [leftCell setTarget:newTarget];
}

- (SEL)rightAction {
    return [rightCell action];
}

- (void)setRightAction:(SEL)selector {
    [rightCell setAction:selector];
    [self resetCursorRects];
}

- (id)rightTarget {
    return [rightCell target];
}

- (void)setRightTarget:(id)newTarget {
    [rightCell setTarget:newTarget];
}

- (SEL)action {
    return [self rightAction];
}

- (void)setAction:(SEL)selector {
    [self setRightAction:selector];
}

- (id)target {
    return [self rightTarget];
}

- (void)setTarget:(id)newTarget {
    [self setRightTarget:newTarget];
}

- (NSInteger)leftState {
    return [leftCell state];
}

- (void)setLeftState:(NSInteger)newState {
    [leftCell setState:newState];
}

- (NSInteger)rightState {
    return [rightCell state];
}

- (void)setRightState:(NSInteger)newState {
    [rightCell setState:newState];
}

- (NSInteger)state {
    return [self rightState];
}

- (void)setState:(NSInteger)newState {
    [self setRightState:newState];
}

- (id)iconCell {
    return iconCell;
}

- (void)setIconCell:(id)newIconCell {
    if (iconCell != newIconCell) {
        [iconCell release];
        iconCell = [newIconCell retain];
        [[self superview] setNeedsDisplayInRect:[self frame]];
        [self resetCursorRects];
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
		if (progressIndicator && (NSInteger)[progressIndicator style] == style)
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
        rect.origin.y = SKFloor(NSMidY(rect) - 0.5 * size.height) + VERTICAL_OFFSET;
        rect.size.height = size.height;
		[progressIndicator setFrame:rect];
		
        [self addSubview:progressIndicator];
		[progressIndicator release];
	}
	[[self superview] setNeedsDisplayInRect:[self frame]];
    [self resetCursorRects];
}

- (void)startAnimation:(id)sender {
	[progressIndicator startAnimation:sender];
}

- (void)stopAnimation:(id)sender {
	[progressIndicator stopAnimation:sender];
}

#pragma mark Tracking rects

- (void)resetCursorRects {
    [super resetCursorRects];
    if (leftTrackingRectTag != 0)
        [self removeTrackingRect:leftTrackingRectTag];
    if (rightTrackingRectTag != 0)
        [self removeTrackingRect:rightTrackingRectTag];
    NSRect leftRect, rightRect;
    [self getLeftFrame:&leftRect rightFrame:&rightRect];
    if ([self leftAction] != NULL)
        leftTrackingRectTag = [self addTrackingRect:leftRect owner:self userData:nil assumeInside:NO];
    else
        [leftCell setUnderlined:NO];
    if ([self rightAction] != NULL)
        rightTrackingRectTag = [self addTrackingRect:rightRect owner:self userData:nil assumeInside:NO];
    else
        [rightCell setUnderlined:NO];
}

- (void)mouseEntered:(NSEvent *)theEvent {
    if ([theEvent trackingNumber] == leftTrackingRectTag) {
        [leftCell setUnderlined:YES];
        [self setNeedsDisplay:YES];
    } else if ([theEvent trackingNumber] == rightTrackingRectTag) {
        [rightCell setUnderlined:YES];
        [self setNeedsDisplay:YES];
    }
}

- (void)mouseExited:(NSEvent *)theEvent {
    if ([theEvent trackingNumber] == leftTrackingRectTag) {
        [leftCell setUnderlined:NO];
        [self setNeedsDisplay:YES];
    } else if ([theEvent trackingNumber] == rightTrackingRectTag) {
        [rightCell setUnderlined:NO];
        [self setNeedsDisplay:YES];
    }
}

#pragma mark Accessibility

- (NSArray *)accessibilityAttributeNames {
    return [[super accessibilityAttributeNames] arrayByAddingObject:NSAccessibilityChildrenAttribute];
}

- (id)accessibilityAttributeValue:(NSString *)attribute {
    if ([attribute isEqualToString:NSAccessibilityRoleAttribute]) {
        return NSAccessibilityGroupRole;
    } else if ([attribute isEqualToString:NSAccessibilityRoleDescriptionAttribute]) {
        return NSAccessibilityRoleDescription(NSAccessibilityGroupRole, nil);
    } else if ([attribute isEqualToString:NSAccessibilityChildrenAttribute]) {
        NSMutableArray *children = [NSMutableArray arrayWithObjects:leftCell, rightCell, nil];
        if (iconCell)
            [children addObject:iconCell];
        if (progressIndicator)
            [children addObject:progressIndicator];
        return NSAccessibilityUnignoredChildren(children);
    }
    return [super accessibilityAttributeValue:attribute];
}

- (id)accessibilityHitTest:(NSPoint)point {
    NSPoint localPoint = [self convertPoint:[[self window] convertScreenToBase:point] fromView:nil];
    NSRect leftRect, rightRect;
    [self getLeftFrame:&leftRect rightFrame:&rightRect];
    if (NSMouseInRect(localPoint, rightRect, [self isFlipped]))
        return NSAccessibilityUnignoredAncestor(rightCell);
    else
        return NSAccessibilityUnignoredAncestor(leftCell);
}

- (id)accessibilityFocusedUIElement {
    if ([NSApp accessibilityFocusedUIElement] == rightCell)
        return NSAccessibilityUnignoredAncestor(rightCell);
    else if (progressIndicator && [NSApp accessibilityFocusedUIElement] == progressIndicator)
        return NSAccessibilityUnignoredAncestor(progressIndicator);
    else
        return NSAccessibilityUnignoredAncestor(leftCell);
}

- (BOOL)accessibilityIsIgnored {
    return NO;
}

@end

#pragma mark -

@implementation SKStatusTextFieldCell

- (BOOL)isUnderlined {
    return underlined;
}

- (void)setUnderlined:(BOOL)flag {
    underlined = flag;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    if ([self isUnderlined]) {
        NSAttributedString *attrString = [[self attributedStringValue] copy];
        NSMutableAttributedString *mutAttrString = [attrString mutableCopy];
        [mutAttrString addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInteger:NSUnderlineStyleSingle] range:NSMakeRange(0, [mutAttrString length])];
        [self setAttributedStringValue:mutAttrString];
        [mutAttrString release];
        [super drawInteriorWithFrame:cellFrame inView:controlView];
        [self setAttributedStringValue:attrString];
        [attrString release];
    } else {
        [super drawInteriorWithFrame:cellFrame inView:controlView];
    }
}

@end
