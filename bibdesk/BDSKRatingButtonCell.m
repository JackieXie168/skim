//
//  BDSKRatingButtonCell.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 8/9/05.
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

#import "BDSKRatingButtonCell.h"

#define OUTER_SIZE			12
#define INNER_SIZE			8
#define SMALL_INNER_SIZE	2


@implementation BDSKRatingButtonCell

// designated initializer
- (id)initWithMaxRating:(unsigned int)aRating {
	if (self = [super initTextCell:@""]) {
		rating = 0;
		maxRating = aRating;
	}
	return self;
}

// super's designated initializer
- (id)initTextCell:(NSString *)aString {
	self = [self initWithMaxRating:5];
	return self;
}

- (id)initWithCoder:(NSCoder *)coder {
	if (self = [super initWithCoder:coder]) {
		rating = 0;
		maxRating = 5;
	}
	return self;
}

- (unsigned int)rating {
    return rating;
}

- (void)setRating:(unsigned int)newRating {
	if (newRating > maxRating)
		newRating = maxRating;
	if (newRating < 0)
		newRating = 0;
	rating = newRating;
}

- (unsigned int)maxRating {
    return maxRating;
}

- (void)setMaxRating:(unsigned int)newRating {
    maxRating = newRating;
}

- (void)setObjectValue:(id)object {
	[self setRating:[object intValue]];
}

- (id)objectValue {
	return [NSNumber numberWithInt:rating];
}

- (int)intValue {
	return rating;
}

- (void)setIntValue:(int)anInt {
	[self setRating:anInt];
}

- (BOOL)trackMouse:(NSEvent *)theEvent inRect:(NSRect)cellFrame ofView:(NSView *)controlView untilMouseUp:(BOOL)untilMouseUp {
	BOOL keepOn = YES;
	NSPoint mouseLoc = [controlView convertPoint:[theEvent locationInWindow] fromView:nil];
	float border = ([self isBordered] ? 1 : 0);
	float margin = 0;
	float offset;
	int newRating;
	
	switch ([self alignment]) {
		case NSCenterTextAlignment:
			margin = (cellFrame.size.width - [self cellSize].width) / 2;
			break;
		case NSRightTextAlignment:
			margin = cellFrame.size.width - [self cellSize].width - border;
			break;
		default:
			break;
	}
	if (margin < border)
		margin = border;
	
	offset = mouseLoc.x - cellFrame.origin.x - margin;
	newRating = (offset < 2) ? 0 : ceil(offset / OUTER_SIZE);
	if (newRating > maxRating)
		newRating = maxRating;
	if (rating != newRating) {
		rating = newRating;
		[controlView setNeedsDisplayInRect:cellFrame];
	}
	
	while (keepOn) {
		theEvent = [[controlView window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask];
		mouseLoc = [controlView convertPoint:[theEvent locationInWindow] fromView:nil];
		offset = mouseLoc.x - cellFrame.origin.x - margin;
		if (offset < border)
			offset = border;
		switch ([theEvent type]) {
			case NSLeftMouseUp:
				keepOn = NO;
			case NSLeftMouseDragged:
				newRating = (offset < 2) ? 0 : ceil(offset / OUTER_SIZE);
				if (newRating > maxRating)
					newRating = maxRating;
				if (rating != newRating) {
					rating = newRating;
					[controlView setNeedsDisplayInRect:cellFrame];
				}
				if (keepOn == NO && [self target] && [self action])
					[[self target] performSelector:[self action] withObject:controlView];
				break;
			default:
				break;
		}
	}
	return YES;
}

- (NSSize)cellSize {
	return NSMakeSize(OUTER_SIZE * maxRating, OUTER_SIZE);
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	float margin = (cellFrame.size.width - [self cellSize].width) / 2;
	float border = ([self isBordered] ? 1 : 0);
	
	switch ([self alignment]) {
		case NSCenterTextAlignment:
			margin = (cellFrame.size.width - [self cellSize].width) / 2;
			break;
		case NSRightTextAlignment:
			margin = cellFrame.size.width - [self cellSize].width - border;
			break;
		default:
			break;
	}
	if (margin < border)
		margin = border;
	
	NSRect rect = NSMakeRect(cellFrame.origin.x + margin + (OUTER_SIZE - INNER_SIZE) / 2, cellFrame.origin.y + (cellFrame.size.height - INNER_SIZE) / 2, INNER_SIZE, INNER_SIZE);
	NSColor *color = [NSColor grayColor];
	BOOL selected = NO;
	int i = 0;
	
	if ([controlView isKindOfClass:[NSTableView class]]) {
		NSTableView *tv = (NSTableView *)controlView;
		if ([[tv window] isKeyWindow] && [[tv window] firstResponder] == tv && [tv isRowSelected:[tv rowAtPoint:cellFrame.origin]]) {
			color = [NSColor whiteColor];
			selected = YES;
		}
	}
	
	[NSGraphicsContext saveGraphicsState];
	
	if ([self isBordered]) {
		[[NSColor controlBackgroundColor] setFill];
		NSRectFill(cellFrame);
		[[NSColor lightGrayColor] setStroke];
		NSRect innerRect = NSInsetRect(cellFrame, 0.5, 0.5);
		[NSBezierPath setDefaultLineWidth:1.0];
		[NSBezierPath strokeRect:innerRect];
		NSRectClip(NSInsetRect(cellFrame, 2, 2));
	}
	
	[color setFill];
	
	while (i++ < rating) {
		[[NSBezierPath bezierPathWithOvalInRect:rect] fill];
		rect.origin.x += OUTER_SIZE;
	}
	
	if ((selected || [self isBordered]) && rating < maxRating) {
		rect.size = NSMakeSize(SMALL_INNER_SIZE, SMALL_INNER_SIZE);
		rect.origin.x += (INNER_SIZE - SMALL_INNER_SIZE) / 2;
		rect.origin.y += (INNER_SIZE - SMALL_INNER_SIZE) / 2;
		[[NSColor lightGrayColor] setFill];
		while (i++ <= maxRating) {
			[[NSBezierPath bezierPathWithOvalInRect:rect] fill];
			rect.origin.x += OUTER_SIZE;
		}
	}
	
	[NSGraphicsContext restoreGraphicsState];
}

@end
