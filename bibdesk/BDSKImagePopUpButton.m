//
//  BDSKImagePopUpButton.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 3/22/05.
//
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

#import "BDSKImagePopUpButton.h"
#import "NSBezierPath_BDSKExtensions.h"
#import <OmniAppKit/OAApplication.h>
#import "BDSKImageFadeAnimation.h"

@implementation BDSKImagePopUpButton

+ (Class)cellClass{
    return [BDSKImagePopUpButtonCell class];
}

- (id)initWithFrame:(NSRect)frameRect {
	if (self = [super initWithFrame:frameRect]) {
		highlight = NO;
		delegate = nil;
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)coder{
	if (self = [super initWithCoder:coder]) {
		highlight = NO;
		[self setDelegate:[coder decodeObjectForKey:@"delegate"]];
		
		if (![[self cell] isKindOfClass:[BDSKImagePopUpButtonCell class]]) {
			BDSKImagePopUpButtonCell *cell = [[[BDSKImagePopUpButtonCell alloc] init] autorelease];
			
			if ([self image] != nil) {
				[cell setIconImage:[self image]];
				[cell setIconSize:[[self image] size]];
			}
			if ([self menu] != nil) {
				if ([self pullsDown])	
					[[self menu] removeItemAtIndex:0];
				[cell setMenu:[self menu]];
			}
			[self setCell:cell];
		}
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder{
	[super encodeWithCoder:encoder];
	[encoder encodeConditionalObject:delegate forKey:@"delegate"];
}

- (void)dealloc{
    [animation setDelegate:nil];
    [animation stopAnimation];
    [animation release];
	[super dealloc];
}

#pragma mark Accessors

- (id)delegate {
    return delegate;
}

- (void)setDelegate:(id)newDelegate {
	delegate = newDelegate;
}

- (NSSize)iconSize{
    return [[self cell] iconSize];
}

- (void) setIconSize:(NSSize)iconSize{
    [[self cell] setIconSize:iconSize];
}

- (BOOL)showsMenuWhenIconClicked{
    return [[self cell] showsMenuWhenIconClicked];
}

- (void)setShowsMenuWhenIconClicked:(BOOL)showsMenuWhenIconClicked{
    [[self cell] setShowsMenuWhenIconClicked: showsMenuWhenIconClicked];
}

- (NSImage *)iconImage{
    return [[self cell] iconImage];
}

- (void)animationDidStop:(BDSKImageFadeAnimation *)anAnimation {
    [self setIconImage:[anAnimation finalImage]];
}

- (void)animationDidEnd:(BDSKImageFadeAnimation *)anAnimation {
    [self setIconImage:[anAnimation finalImage]];
}

- (void)imageAnimationDidUpdate:(BDSKImageFadeAnimation *)anAnimation {
    [self setIconImage:[anAnimation currentImage]];
}

- (void)fadeIconImageToImage:(NSImage *)newImage {
    
    if (nil == animation) {
        animation = [[BDSKImageFadeAnimation alloc] initWithDuration:1.0f animationCurve:NSAnimationEaseInOut];
        [animation setDelegate:self];
        [animation setAnimationBlockingMode:NSAnimationNonblocking];
    } else if ([animation isAnimating]) {
        [animation stopAnimation];
    }
    
    NSImage *iconImage = [self iconImage];
    
    if (nil != iconImage && nil != newImage) {
        [animation setTargetImage:newImage];
        [animation setStartingImage:iconImage];
        [animation startAnimation];
    } else {
        [self setIconImage:newImage];
    }
}

- (void)setIconImage:(NSImage *)iconImage{
    [[self cell] setIconImage: iconImage];
	[self setNeedsDisplay:YES];
}

- (NSImage *)arrowImage{
    return [[self cell] arrowImage];
}

- (void)setArrowImage:(NSImage *)arrowImage{
    [[self cell] setArrowImage: arrowImage];
}

- (BOOL)iconActionEnabled{
    return [[self cell] iconActionEnabled];
}

- (void)setIconActionEnabled:(BOOL)iconActionEnabled{
    [[self cell] setIconActionEnabled: iconActionEnabled];
}
- (BOOL)refreshesMenu{
    return [[self cell] refreshesMenu];
}

- (void)setRefreshesMenu:(BOOL)refreshesMenu{
    [[self cell] setRefreshesMenu:refreshesMenu];
}

- (NSMenu *)menuForCell:(id)cell{
	if ([self refreshesMenu] && 
		[delegate respondsToSelector:@selector(menuForImagePopUpButton:)]) {
		return [delegate menuForImagePopUpButton:self];
	} else {
		return [cell menu];
	}
}

#pragma mark Dragging source

- (unsigned int)draggingSourceOperationMaskForLocal:(BOOL)isLocal {
    return (isLocal) ? NSDragOperationEvery : NSDragOperationCopy;
}

- (BOOL)startDraggingWithEvent:(NSEvent *)theEvent {
	NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
	
	if ([delegate respondsToSelector:@selector(imagePopUpButton:writeDataToPasteboard:)] == NO ||
		[delegate imagePopUpButton:self writeDataToPasteboard:pboard] == NO) 
		return NO;
		
	NSImage *iconImage;
	NSSize size = [[self cell] iconSize];
	NSImage *dragImage = [[[NSImage alloc] initWithSize:size] autorelease];
	NSPoint mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	
	mouseLoc.x -= 0.5f * size.width;
	mouseLoc.y += 0.5f * size.height;
	
	if ([[self cell] usesItemFromMenu] == NO) {
		iconImage = [self iconImage];
	} else {
		iconImage = [[self selectedItem] image];
	}
	[dragImage lockFocus];
	[iconImage compositeToPoint:NSZeroPoint operation:NSCompositeCopy fraction:0.6];
	[dragImage unlockFocus];

	[self dragImage:dragImage at:mouseLoc offset:NSZeroSize event:theEvent pasteboard:pboard source:self slideBack:YES];
	
	return YES;
}

- (NSArray *)namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination {
	if ([delegate respondsToSelector:@selector(imagePopUpButton:namesOfPromisedFilesDroppedAtDestination:)])
		return [delegate imagePopUpButton:self namesOfPromisedFilesDroppedAtDestination:dropDestination];
	return nil;
}

- (void)draggedImage:(NSImage *)anImage endedAt:(NSPoint)aPoint operation:(NSDragOperation)operation{
	if ([delegate respondsToSelector:@selector(imagePopUpButton:cleanUpAfterDragOperation:)])
		[delegate imagePopUpButton:self cleanUpAfterDragOperation:operation];
    // flag changes during a drag are not forwarded to the application, so we fix that at the end of the drag
    [[NSNotificationCenter defaultCenter] postNotificationName:OAFlagsChangedNotification object:[NSApp currentEvent]];
}

#pragma mark Dragging destination

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    NSDragOperation dragOp = NSDragOperationNone;
    if ([delegate respondsToSelector:@selector(imagePopUpButton:receiveDrag:)] && 
        [delegate respondsToSelector:@selector(imagePopUpButton:canReceiveDrag:)]) {
        
        dragOp = [delegate imagePopUpButton:self canReceiveDrag:sender];
        if (dragOp != NSDragOperationNone) {	
            highlight = YES;
            [self setNeedsDisplay:YES];
        }
    }
    return dragOp;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender {
    highlight = NO;
	[self setNeedsDisplay:YES];
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender {
	highlight = NO;
	[self setNeedsDisplay:YES];
	return YES;
} 

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    if(delegate == nil) return NO;
    
    return [delegate imagePopUpButton:self receiveDrag:sender];
}

#pragma mark Drawing and Highlighting

-(void)drawRect:(NSRect)rect {
	[super drawRect:rect];
	
	if (highlight)  {
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
