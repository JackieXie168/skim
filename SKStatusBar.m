//
//  SKStatusBar.m
//  Skim
//
//  Created by Christiaan Hofman on 8/7/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "SKStatusBar.h"
#import "NSBezierPath_CoreImageExtensions.h"

#define LEFT_MARGIN				5.0
#define RIGHT_MARGIN			15.0
#define MARGIN_BETWEEN_ITEMS	2.0


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
        rightCell = [[NSCell alloc] initTextCell:@""];
		[rightCell setFont:[NSFont labelFontOfSize:0]];
        [rightCell setAlignment:NSRightTextAlignment];
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
    
    [[NSBezierPath bezierPathWithRect:[self bounds]] fillPathVerticallyWithStartColor:[[self class] upperColor] endColor:[[self class] lowerColor]];
    
    NSDivideRect([self bounds], &ignored, &textRect, LEFT_MARGIN, NSMinXEdge);
    NSDivideRect(textRect, &ignored, &textRect, RIGHT_MARGIN, NSMaxXEdge);
	
	if (textRect.size.width < 0.0)
		textRect.size.width = 0.0;
	
    float height = fmax([leftCell cellSize].height, [rightCell cellSize].height);
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

@end
