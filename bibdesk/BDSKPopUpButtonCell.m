//
//  BDSKPopUpButtonCell.m
//  Bibdesk
//
//  Created by Sven-S. Porst on Tue Aug 03 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "BDSKPopUpButtonCell.h"


@implementation BDSKPopUpButtonCell : NSPopUpButtonCell

- (id)initImageCell:(NSImage *)anImage
{
    self = [self initImageCell:anImage pullsDown:YES];
    return self;
}

- (id)initTextCell:(NSString *)stringValue pullsDown:(BOOL)pullDown
{
    self = [self initImageCell:nil pullsDown:YES];
    return self;
}

// designated initializer
- (id)initImageCell:(NSImage *)anImage pullsDown:(BOOL)pullDown
{
    if (self = [super initTextCell:@"" pullsDown:pullDown]) {
		// initialize the buttoncell
		buttonCell = [[NSButtonCell alloc] init];
		[buttonCell setBordered:NO];
		[buttonCell setHighlightsBy:NSContentsCellMask | NSPushInCellMask];
		[buttonCell setImagePosition:NSImageOnly];
		if (anImage != nil) {
			[buttonCell setImage:anImage];
		}
		
		[self setUsesItemFromMenu:NO];
    }
    return self;
}

- (void)dealloc
{
    [buttonCell release];
	buttonCell = nil;
    [super dealloc];
}

// set properties relevant for drawing in the buttoncell

- (void)setImage:(NSImage *)anImage
{
	// need to check this because dealloc might call it
	if (buttonCell != nil) 
		[buttonCell setImage:anImage];
}

- (void)setAlternateImage:(NSImage *)anImage
{
	if (buttonCell != nil) 
		[buttonCell setAlternateImage:anImage];
}

- (void)setBordered:(BOOL)flag
{
	[buttonCell setBordered:flag];
}

- (BOOL)isEnabled
{
	return [buttonCell isEnabled];
}

- (void)setEnabled:(BOOL)flag
{
	[buttonCell setEnabled:flag];
	[super setEnabled:flag];
}

- (BOOL)isOpaque
{
	return [buttonCell isOpaque];
}

- (BOOL)isTransparent
{
	return [buttonCell isTransparent];
}

- (void)setTransparent:(BOOL)flag
{
	[buttonCell setTransparent:flag];
	[super setTransparent:flag];
}

- (NSBezelStyle)bezelStyle
{
	return [buttonCell bezelStyle];
}

- (void)setBezelStyle:(NSBezelStyle)bezelStyle
{
	[buttonCell setBezelStyle:bezelStyle];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	// draw the buttoncell
	[buttonCell drawWithFrame:cellFrame inView:controlView];
}

- (void)highlight:(BOOL)flag withFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    // highlight the buttoncell and the popupbuttoncell
	[buttonCell highlight:flag withFrame:cellFrame inView:controlView];
    [super highlight:flag withFrame:cellFrame inView:controlView];
}

- (void)performClick:(id)sender
{
    // both perform click
	[buttonCell performClick:sender];
    [super performClick:sender];
}

@end
