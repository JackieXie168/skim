//
//  BDSKDragTextField.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 1/14/07.
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

#import "BDSKDragTextField.h"
#import "NSBezierPath_BDSKExtensions.h"


@implementation BDSKDragTextField

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender{
    NSDragOperation dragOp = NSDragOperationNone;
	if ([[self delegate] respondsToSelector:@selector(dragTextField:validateDrop:)])
		dragOp = [[self delegate] dragTextField:self validateDrop:sender];
	if (dragOp != NSDragOperationNone) {
		highlight = YES;
		[self setNeedsDisplay:YES];
	}
	return dragOp;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender{
    highlight = NO;
	[self setNeedsDisplay:YES];
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    highlight = NO;
	[self setNeedsDisplay:YES];
	if ([[self delegate] respondsToSelector:@selector(dragTextField:acceptDrop:)])
		return [[self delegate] dragTextField:self acceptDrop:sender];
	return NO;
}

- (void)drawRect:(NSRect)aRect {
	[super drawRect:aRect];
	
	if (highlight) {
        NSColor *highlightColor = [NSColor alternateSelectedControlColor];
        float lineWidth = 2.0;
        
        NSRect highlightRect = NSInsetRect([self bounds], 0.5f * lineWidth, 0.5f * lineWidth);
        
        NSBezierPath *path = [NSBezierPath bezierPathWithRoundRectInRect:highlightRect radius:4.0];
        
        [path setLineWidth:lineWidth];
        
        [NSGraphicsContext saveGraphicsState];
        
        [[highlightColor colorWithAlphaComponent:0.2] set];
        [path fill];
        
        [[highlightColor colorWithAlphaComponent:0.8] set];
        [path stroke];
        
        [NSGraphicsContext restoreGraphicsState];
	}
}

@end
