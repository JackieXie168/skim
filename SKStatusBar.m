//
//  SKStatusBar.m
//  Skim
//
//  Created by Christiaan Hofman on 7/8/07.
/*
 This software is Copyright (c) 2007-2014
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
#import "SKStringConstants.h"
#import "NSEvent_SKExtensions.h"

#define LEFT_MARGIN         5.0
#define RIGHT_MARGIN        15.0
#define SEPARATION          2.0
#define VERTICAL_OFFSET     0.0
#define PROGRESSBAR_WIDTH   100.0
#define ICON_HEIGHT_OFFSET  2.0


@interface SKStatusTextFieldCell : NSTextFieldCell {
    BOOL underlined;
}
@property (nonatomic, getter=isUnderlined) BOOL underlined;
@end

#pragma mark -

@implementation SKStatusBar

@synthesize animating, iconCell;
@dynamic isVisible, leftStringValue, rightStringValue, leftAction, leftTarget, rightAction, rightTarget, leftState, rightState, font, progressIndicator, progressIndicatorStyle;

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
        leftTrackingArea = nil;
        rightTrackingArea = nil;
        animating = NO;
    }
    return self;
}

- (void)dealloc {
	SKDESTROY(leftCell);
	SKDESTROY(rightCell);
	SKDESTROY(iconCell);
    SKDESTROY(leftTrackingArea);
    SKDESTROY(rightTrackingArea);
	[super dealloc];
}

- (id)initWithCoder:(NSCoder *)decoder {
	self = [super initWithCoder:decoder];
    if (self) {
        leftCell = [[decoder decodeObjectForKey:@"leftCell"] retain];
        rightCell = [[decoder decodeObjectForKey:@"rightCell"] retain];
        iconCell = [[decoder decodeObjectForKey:@"iconCell"] retain];
        progressIndicator = [[decoder decodeObjectForKey:@"progressIndicator"] retain];
        leftTrackingArea = nil;
        rightTrackingArea = nil;
        animating = NO;
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:leftCell forKey:@"leftCell"];
    [coder encodeObject:rightCell forKey:@"rightCell"];
    [coder encodeObject:iconCell forKey:@"iconCell"];
    [coder encodeObject:progressIndicator forKey:@"progressIndicator"];
}

- (void)getLeftFrame:(NSRectPointer)leftFrame rightFrame:(NSRectPointer)rightFrame {
    CGFloat leftWidth = [[leftCell stringValue] length] ? [leftCell cellSize].width : 0.0;
    CGFloat rightWidth = [[rightCell stringValue] length] ? [rightCell cellSize].width : 0.0;
    NSRect ignored, rect = [self bounds];
    CGFloat leftMargin = LEFT_MARGIN;
    CGFloat rightMargin = RIGHT_MARGIN;
    if (iconCell)
        leftMargin += NSHeight([self bounds]) - ICON_HEIGHT_OFFSET + SEPARATION;
    if (progressIndicator)
        rightMargin += NSWidth([progressIndicator frame]) + SEPARATION;
    rect = SKShrinkRect(SKShrinkRect(rect, leftMargin, NSMinXEdge), rightMargin, NSMaxXEdge);
    if (rightFrame != NULL)
        NSDivideRect(rect, rightFrame, &ignored, rightWidth, NSMaxXEdge);
    if (leftFrame != NULL)
        NSDivideRect(rect, leftFrame, &ignored, leftWidth, NSMinXEdge);
}

- (void)drawRect:(NSRect)rect {
    NSRect bounds = [self bounds];
    NSRect textRect, iconRect = NSZeroRect;
    CGFloat rightMargin = RIGHT_MARGIN;
    CGFloat iconHeight = NSHeight(bounds) - ICON_HEIGHT_OFFSET;
    
    if (progressIndicator)
        rightMargin += NSWidth([progressIndicator frame]) + SEPARATION;
    textRect = SKShrinkRect(SKShrinkRect(bounds, LEFT_MARGIN, NSMinXEdge), rightMargin, NSMaxXEdge);
    if (iconCell) {
        NSDivideRect(textRect, &iconRect, &textRect, iconHeight, NSMinXEdge);
        textRect = SKShrinkRect(textRect, SEPARATION, NSMaxXEdge);
    }
	
	if (textRect.size.width < 0.0)
		textRect.size.width = 0.0;
	
    CGFloat height = fmax([leftCell cellSize].height, [rightCell cellSize].height);
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

- (void)endAnimation:(NSNumber *)visible {
    if ([visible boolValue] == NO) {
        [[self window] setContentBorderThickness:0.0 forEdge:NSMinYEdge];
		[self removeFromSuperview];
    } else {
        // this fixes an AppKit bug, the window does not notice that its draggable areas change
        [[self window] setMovableByWindowBackground:YES];
        [[self window] setMovableByWindowBackground:NO];
    }
    animating = NO;
}

- (void)toggleBelowView:(NSView *)view animate:(BOOL)animate {
    if (animating)
        return;
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKDisableAnimationsKey])
        animate = NO;
    
	NSRect viewFrame = [view frame];
	NSView *contentView = [view superview];
	NSRect statusRect = [contentView bounds];
	CGFloat statusHeight = NSHeight([self frame]);
    BOOL visible = (nil == [self superview]);
    NSTimeInterval duration;
    
	statusRect.size.height = statusHeight;
	
	if (visible) {
        [[view window] setContentBorderThickness:statusHeight forEdge:NSMinYEdge];
		if ([contentView isFlipped])
			statusRect.origin.y = NSMaxY([contentView bounds]);
		else
            statusRect.origin.y -= statusHeight;
        [self setFrame:statusRect];
		[contentView addSubview:self positioned:NSWindowBelow relativeTo:nil];
        statusHeight = -statusHeight;
	} else if ([contentView isFlipped]) {
        statusRect.origin.y = NSMaxY([contentView bounds]) - statusHeight;
    }

    viewFrame.size.height += statusHeight;
    if ([contentView isFlipped]) {
        statusRect.origin.y += statusHeight;
    } else {
        viewFrame.origin.y -= statusHeight;
        statusRect.origin.y -= statusHeight;
    }
    if (animate) {
        animating = YES;
        [NSAnimationContext beginGrouping];
        duration = 0.5 * [[NSAnimationContext currentContext] duration];
        [[NSAnimationContext currentContext] setDuration:duration];
        [[view animator] setFrame:viewFrame];
        [[self animator] setFrame:statusRect];
        [NSAnimationContext endGrouping];
        [self performSelector:@selector(endAnimation:) withObject:[NSNumber numberWithBool:visible] afterDelay:duration];
    } else {
        [view setFrame:viewFrame];
        if (visible) {
            [self setFrame:statusRect];
        } else {
            [[self window] setContentBorderThickness:0.0 forEdge:NSMinYEdge];
            [self removeFromSuperview];
        }
    }
}

- (void)mouseDown:(NSEvent *)theEvent {
    NSPoint mouseLoc = [theEvent locationInView:self];
    NSRect leftRect, rightRect;
    [self getLeftFrame:&leftRect rightFrame:&rightRect];
    if (NSMouseInRect(mouseLoc, rightRect, [self isFlipped]) && [rightCell action]) {
        while ([theEvent type] != NSLeftMouseUp)
            theEvent = [[self window] nextEventMatchingMask: NSLeftMouseDraggedMask | NSLeftMouseUpMask];
        mouseLoc = [theEvent locationInView:self];
        if (NSMouseInRect(mouseLoc, rightRect, [self isFlipped])) {
            [rightCell setNextState];
            [NSApp sendAction:[rightCell action] to:[rightCell target] from:self];
        }
    } else if (NSMouseInRect(mouseLoc, leftRect, [self isFlipped]) && [leftCell action]) {
        while ([theEvent type] != NSLeftMouseUp)
            theEvent = [[self window] nextEventMatchingMask: NSLeftMouseDraggedMask | NSLeftMouseUpMask];
        mouseLoc = [theEvent locationInView:self];
        if (NSMouseInRect(mouseLoc, leftRect, [self isFlipped])) {
            [leftCell setNextState];
            [NSApp sendAction:[leftCell action] to:[leftCell target] from:self];
        }
    } else {
        [super mouseDown:theEvent];
    }
}

#pragma mark Text cell accessors

- (NSString *)leftStringValue {
	return [leftCell stringValue];
}

- (void)setLeftStringValue:(NSString *)aString {
	[leftCell setStringValue:aString];
	[self setNeedsDisplay:YES];
    [self updateTrackingAreas];
}

- (NSString *)rightStringValue {
	return [rightCell stringValue];
}

- (void)setRightStringValue:(NSString *)aString {
	[rightCell setStringValue:aString];
	[self setNeedsDisplay:YES];
    [self updateTrackingAreas];
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
    [self updateTrackingAreas];
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
    [self updateTrackingAreas];
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
    return [(NSCell *)leftCell state];
}

- (void)setLeftState:(NSInteger)newState {
    [(NSCell *)leftCell setState:newState];
}

- (NSInteger)rightState {
    return [(NSCell *)rightCell state];
}

- (void)setRightState:(NSInteger)newState {
    [(NSCell *)rightCell setState:newState];
}

- (void)setIconCell:(id)newIconCell {
    if (iconCell != newIconCell) {
        [iconCell release];
        iconCell = [newIconCell retain];
        [[self superview] setNeedsDisplayInRect:[self frame]];
        [self updateTrackingAreas];
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
		
		NSRect rect;
		NSSize size = [progressIndicator frame].size;
        if (size.width < 0.01) size.width = PROGRESSBAR_WIDTH;
        rect = SKSliceRect(SKShrinkRect([self bounds], RIGHT_MARGIN, NSMaxXEdge), size.width, NSMaxXEdge);
        rect.origin.y = floor(NSMidY(rect) - 0.5 * size.height) + VERTICAL_OFFSET;
        rect.size.height = size.height;
		[progressIndicator setFrame:rect];
		
        [self addSubview:progressIndicator];
		[progressIndicator release];
	}
	[[self superview] setNeedsDisplayInRect:[self frame]];
    [self updateTrackingAreas];
}

- (void)startAnimation:(id)sender {
	[progressIndicator startAnimation:sender];
}

- (void)stopAnimation:(id)sender {
	[progressIndicator stopAnimation:sender];
}

#pragma mark Tracking rects

- (void)updateTrackingAreas {
    [super updateTrackingAreas];
    if (leftTrackingArea) {
        [self removeTrackingArea:leftTrackingArea];
        SKDESTROY(leftTrackingArea);
    }
    if (rightTrackingArea) {
        [self removeTrackingArea:rightTrackingArea];
        SKDESTROY(rightTrackingArea);
    }
    NSRect leftRect, rightRect;
    [self getLeftFrame:&leftRect rightFrame:&rightRect];
    if ([self leftAction] != NULL) {
        leftTrackingArea = [[NSTrackingArea alloc] initWithRect:leftRect options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp owner:self userInfo:nil];
        [self addTrackingArea:leftTrackingArea];
    } else {
        [leftCell setUnderlined:NO];
    }
    if ([self rightAction] != NULL) {
        rightTrackingArea = [[NSTrackingArea alloc] initWithRect:rightRect options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp owner:self userInfo:nil];
        [self addTrackingArea:rightTrackingArea];
    } else {
        [rightCell setUnderlined:NO];
    }
}

- (void)mouseEntered:(NSEvent *)theEvent {
    if ([[theEvent trackingArea] isEqual:leftTrackingArea]) {
        [leftCell setUnderlined:YES];
        [self setNeedsDisplay:YES];
    } else if ([[theEvent trackingArea] isEqual:rightTrackingArea]) {
        [rightCell setUnderlined:YES];
        [self setNeedsDisplay:YES];
    }
}

- (void)mouseExited:(NSEvent *)theEvent {
    if ([[theEvent trackingArea] isEqual:leftTrackingArea]) {
        [leftCell setUnderlined:NO];
        [self setNeedsDisplay:YES];
    } else if ([[theEvent trackingArea] isEqual:rightTrackingArea]) {
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

@synthesize underlined;

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
