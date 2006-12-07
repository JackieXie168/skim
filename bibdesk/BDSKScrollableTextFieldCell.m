//
//  BDSKScrollableTextFieldCell.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 16/8/05.
/*
 This software is Copyright (c) 2005,2006
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

#import "BDSKScrollableTextFieldCell.h"
#import "NSGeometry_BDSKExtensions.h"


@implementation BDSKScrollableTextFieldCell

#pragma mark Class methods: images

+ (NSImage *)scrollArrowImageForButton:(BDSKScrollButton)button highlighted:(BOOL)highlighted{
	static NSImage *scrollArrowLeftImage = nil;
	static NSImage *scrollArrowLeftPressedImage = nil;
	static NSImage *scrollArrowRightImage = nil;
	static NSImage *scrollArrowRightPressedImage = nil;
	
	if (scrollArrowLeftImage == nil)
		scrollArrowLeftImage = [[NSImage imageNamed:@"ScrollArrowLeft"] retain];
	if (scrollArrowLeftPressedImage == nil)
		scrollArrowLeftPressedImage = [[NSImage imageNamed:@"ScrollArrowLeft_Pressed"] retain];
	if (scrollArrowRightImage == nil)
		scrollArrowRightImage = [[NSImage imageNamed:@"ScrollArrowRight"] retain];
	if (scrollArrowRightPressedImage == nil)
		scrollArrowRightPressedImage = [[NSImage imageNamed:@"ScrollArrowRight_Pressed"] retain];
	
	if (button == BDSKScrollLeftButton) {
		if (highlighted)
			return scrollArrowLeftPressedImage;
		else
			return scrollArrowLeftImage;
	} else {
		if (highlighted)
			return scrollArrowRightPressedImage;
		else
			return scrollArrowRightImage;
	}
}

#pragma mark Init and dealloc

- (id)initTextCell:(NSString *)aString
{
	if (self = [super initTextCell:aString]) {
		scrollStep = 0;
		isLeftButtonHighlighted = NO;
		isRightButtonHighlighted = NO;
		isClipped = NO;
		
		[self stringHasChanged];
	}
	return self;
}

#pragma mark Actions and accessors

- (IBAction)scrollForward:(id)sender {
	if (scrollStep < maxScrollStep)
		scrollStep++;
}

- (IBAction)scrollBack:(id)sender {
	if (scrollStep > 0) 
		scrollStep--;
}

- (BOOL)isButtonHighlighted:(BDSKScrollButton)button {
    if (button == BDSKScrollLeftButton)
		return isLeftButtonHighlighted;
	else
		return isRightButtonHighlighted;
}

- (void)setButton:(BDSKScrollButton)button highlighted:(BOOL)highlighted {
    if (button == BDSKScrollLeftButton) {
		if (isLeftButtonHighlighted == highlighted) return;
        isLeftButtonHighlighted = highlighted;
		[[self controlView] setNeedsDisplay:YES];
    } else {
		if (isRightButtonHighlighted == highlighted) return;
        isRightButtonHighlighted = highlighted;
		[[self controlView] setNeedsDisplay:YES];
	}
}

#pragma mark Drawing related methods

- (NSRect)buttonRect:(BDSKScrollButton)button forBounds:(NSRect)theRect{
	NSRect buttonRect = NSZeroRect;
	
	if(isClipped){
		NSSize buttonSize = [[[self class] scrollArrowImageForButton:button highlighted:NO] size];
        buttonRect = BDSKCenterRect(theRect, buttonSize, NO);
        if (button == BDSKScrollLeftButton)
			buttonRect.origin.x = NSMaxX(theRect) - 2.0f * buttonSize.width;
		else
			buttonRect.origin.x = NSMaxX(theRect) - buttonSize.width;
	}
	return buttonRect;
}

- (NSRect)textRectForBounds:(NSRect)theRect{
	NSRect rect = [self drawingRectForBounds:theRect];
	
	return rect;
}

// override this to get the rect in which the text is drawn right
- (NSRect)drawingRectForBounds:(NSRect)theRect{
	NSRect rect = [super drawingRectForBounds:theRect];
    
	if(isClipped){
		NSSize buttonSize = [[[self class] scrollArrowImageForButton:BDSKScrollLeftButton highlighted:NO] size];
		rect.size.width -= NSMaxX(rect) - NSMaxX(theRect) + 2 * buttonSize.width;
	}
	
	return rect;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView{
	NSAttributedString *attrString = [self attributedStringValue];
	NSRect textRect = NSInsetRect([self textRectForBounds:cellFrame], 1.0, 0.0);
	NSPoint textOrigin = textRect.origin;
	
	if (isClipped) {
		if (scrollStep == maxScrollStep) 
			textOrigin.x -= [self stringWidth] - NSWidth(textRect);
		else
			textOrigin.x -= 0.5f * scrollStep * NSWidth(textRect);
	}
	
	// draw the (clipped) text
	
	[controlView lockFocus];
	NSRectClip(textRect);
	[attrString drawAtPoint:textOrigin];
    [controlView unlockFocus];
	
	if(!isClipped)
        return;
	
    // draw the buttons
	
	NSImage *leftButtonImage = [[self class] scrollArrowImageForButton:BDSKScrollLeftButton 
														   highlighted:[self isButtonHighlighted:BDSKScrollLeftButton]];
	NSImage *rightButtonImage = [[self class] scrollArrowImageForButton:BDSKScrollRightButton
															highlighted:[self isButtonHighlighted:BDSKScrollRightButton]];
	
	NSRect leftButtonRect = [self buttonRect:BDSKScrollLeftButton forBounds:cellFrame]; 
	NSRect rightButtonRect = [self buttonRect:BDSKScrollRightButton  forBounds:cellFrame]; 
	NSPoint leftPoint = leftButtonRect.origin;
	NSPoint rightPoint = rightButtonRect.origin;
	if([controlView isFlipped]){
		leftPoint.y += leftButtonRect.size.height;
		rightPoint.y += rightButtonRect.size.height;
    }
	
	[controlView lockFocus];
	[leftButtonImage compositeToPoint:leftPoint operation:NSCompositeSourceOver];
	[rightButtonImage compositeToPoint:rightPoint operation:NSCompositeSourceOver];
    [controlView unlockFocus];
}

#pragma mark String widths

- (float)stringWidth {
	return [[self attributedStringValue] size].width;
}

- (void)stringHasChanged {
	float stringWidth = [self stringWidth];
	NSRect cellFrame = [[self controlView] bounds];
    
    isClipped = NO;
	
    NSRect textRect = [self textRectForBounds:cellFrame];
	
	if (NSWidth(textRect) > 2.0 && stringWidth > NSWidth(textRect) - 2.0)
		isClipped = YES;
	else 
		isClipped = NO;

	textRect = NSInsetRect([self textRectForBounds:cellFrame], 1.0, 0.0);
	
	scrollStep = 0;
	maxScrollStep = ceil(2 * stringWidth / NSWidth(textRect)) - 2;
	if (maxScrollStep < 0 ) 
		maxScrollStep = 0;
}

@end
