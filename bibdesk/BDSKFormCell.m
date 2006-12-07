//
//  BDSKFormCell.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 10/7/05.
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

#import "BDSKFormCell.h"
#import "BDSKForm.h"
#import "BDSKComplexString.h"
#import "NSImage+Toolbox.h"

static Class BDSKFormCellClass = Nil;

@implementation BDSKFormCell

+ (void)initialize{
    if(BDSKFormCellClass == Nil)
        BDSKFormCellClass = NSClassFromString(@"BDSKFormCell");
}

+ (NSImage *)arrowImage{
    static NSImage *arrowImage = nil;
    if(!arrowImage)
        arrowImage = [NSImage imageNamed:@"ArrowImage"];
	return arrowImage;
}

+ (NSImage *)arrowPressedImage{
    static NSImage *arrowPressedImage = nil;
    if(!arrowPressedImage)
        arrowPressedImage = [NSImage imageNamed:@"ArrowImage_Pressed"];
	return arrowPressedImage;
}

// designated initializer
- (id)initTextCell:(NSString *)aString{
	if(self = [super initTextCell:aString]){
		buttonHighlighted = NO;
	}
	return self;
}

- (BOOL)buttonHighlighted {
    return buttonHighlighted;
}

- (void)setButtonHighlighted:(BOOL)highlighted {
    if (buttonHighlighted != highlighted) {
        buttonHighlighted = highlighted;
		[[self controlView] setNeedsDisplay:YES];
    }
}

- (BOOL)hasArrowButton{
	id <BDSKFormDelegate>delegate = [[self controlView] delegate];
	return [delegate formCellHasArrowButton:self];
}

- (BOOL)hasFileIcon{
	id <BDSKFormDelegate>delegate = [[self controlView] delegate];
    return [delegate formCellHasFileIcon:self];
}

- (BDSKForm *)controlView{
    id controlView = [super controlView];
    OBPRECONDITION(controlView == nil || [controlView isKindOfClass:[BDSKForm class]]);
    return controlView;
}

# pragma mark Drawing methods

- (NSRect)buttonRectForBounds:(NSRect)theRect{
	NSRect buttonRect = NSZeroRect;
	
	if([self hasArrowButton] || [self hasFileIcon]){
		NSSize size = [self hasArrowButton] ? [[BDSKFormCellClass arrowImage] size] : NSMakeSize(16,16);
		buttonRect.size = size;
		buttonRect.origin.x = NSMaxX(theRect) - size.width - 3;
		buttonRect.origin.y = NSMinY(theRect) + ceil((NSHeight(theRect) - size.height) / 2);
	}
	return buttonRect;
}

- (NSRect)textRectForBounds:(NSRect)theRect{
	NSRect rect = [self drawingRectForBounds:theRect];
	int textOffset = [self titleWidth] + 4;
	
	rect.origin.x += textOffset;
	rect.size.width -= textOffset;
	
	return rect;
}

// override this to get the rect in which the text is drawn right
- (NSRect)drawingRectForBounds:(NSRect)theRect{
	NSRect rect = [super drawingRectForBounds:theRect];
    
	if([self hasArrowButton] || [self hasFileIcon]){
		NSSize size = [self hasArrowButton] ? [[BDSKFormCellClass arrowImage] size] : NSMakeSize(16,16);
		rect.size.width -= NSMaxX(rect) - NSMaxX(theRect) + size.width + 4;
	}
	
	return rect;
}

// this method is actually called by NSMatrix
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView{    
    
    if(!NSIntersectsRect(cellFrame, [controlView visibleRect]))
        return;
    
    [super drawWithFrame:cellFrame inView:controlView];

    // get the correct arrow image from the class
	NSImage *buttonImage;
    NSRect buttonRect = [self buttonRectForBounds:cellFrame]; 

    if([self hasArrowButton]){
        if(buttonHighlighted)
            buttonImage = [BDSKFormCellClass arrowPressedImage];
        else
            buttonImage = [BDSKFormCellClass arrowImage];
    } else if([self hasFileIcon]){
        NSURL *fileURL = [[NSURL alloc] initWithString:[self stringValue]];
        if([fileURL isFileURL]){
            // copy so we don't change the cached image
            buttonImage = [[[NSImage imageForFile:[fileURL path]] copy] autorelease];
            [buttonImage setSize:buttonRect.size];
        } else {
            static NSImage *internetImage = nil;
            if(internetImage == nil){
                internetImage = [[NSImage genericInternetLocationImage] copy];
                [internetImage setSize:buttonRect.size];
            }
            buttonImage = internetImage;
        }
        [fileURL release];
        if(buttonHighlighted)
            buttonImage = [buttonImage highlightedImage];
    } else {
        return;
    }
    
	NSPoint thePoint = buttonRect.origin;
	if([controlView isFlipped])
		[buttonImage setFlipped:YES];
    	
    NSRect iconRect = {NSZeroPoint, buttonRect.size};
	[controlView lockFocus];
    [buttonImage drawAtPoint:thePoint fromRect:iconRect operation:NSCompositeSourceOver fraction:1.0];
    [controlView unlockFocus];
}

#pragma mark Delegate methods

// handles tabbing into a cell to display the macro editor
- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(int)selStart length:(int)selLength{
	BOOL shouldEdit = [(id <BDSKFormDelegate>)[(BDSKForm *)controlView delegate] control:(BDSKForm*)controlView textShouldStartEditing:textObj];

    if(shouldEdit)
        [super selectWithFrame:aRect inView:controlView editor:textObj delegate:anObject start:selStart length:selLength];
}

// handles mouse clicks to display the macro editor
- (void)editWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject event:(NSEvent *)theEvent{
	BOOL shouldEdit = [(id <BDSKFormDelegate>)[(BDSKForm *)controlView delegate] control:(BDSKForm*)controlView textShouldStartEditing:textObj];

	if(shouldEdit)
		[super editWithFrame:aRect inView:controlView editor:textObj delegate:anObject event:theEvent];
}

@end