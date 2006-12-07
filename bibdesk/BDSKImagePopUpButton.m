//
//  BDSKImagePopUpButton.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 3/22/05.
//
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

#import "BDSKImagePopUpButton.h"
#import "NSBezierPath_BDSKExtensions.h"

@implementation BDSKImagePopUpButton

+ (Class)cellClass{
    return [BDSKImagePopUpButtonCell class];
}

- (id)initWithFrame:(NSRect)frameRect {
	if (self = [super initWithFrame:frameRect]) {
		currentTimer = nil;
		highlight = NO;
		delegate = nil;
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)coder{
	if (self = [super initWithCoder:coder]) {
		currentTimer = nil;
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
	[currentTimer invalidate];
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

- (void)fadeIconImageToImage:(NSImage *)iconImage;{
	// first make sure we stop a previous timer
	if(currentTimer){
		[currentTimer invalidate];
		currentTimer = nil;
    }
	
    if([self iconImage] == nil || iconImage == nil){
        [self setIconImage:iconImage];
        return;
    }
	
	NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithFloat:0], @"time", iconImage, @"newImage", [self iconImage], @"oldImage", nil];
    currentTimer = [NSTimer scheduledTimerWithTimeInterval:0.03  target:self selector:@selector(timerFired:)  userInfo:userInfo  repeats:YES];
}

- (void)timerFired:(NSTimer *)timer;{
    
    NSImage *newImage = [[timer userInfo] objectForKey:@"newImage"];
    float time = [[[timer userInfo] objectForKey:@"time"] floatValue];
	
    time += 0.1;
	
    if(time >= M_PI_2){
        [self setIconImage:newImage];
		if(![timer isEqual:currentTimer]){
			[timer invalidate]; // this should never happen
		}else if(currentTimer){
			[currentTimer invalidate];
			currentTimer = nil;
		}
        return;
    }
    
    NSNumber *timeNumber = [[NSNumber alloc] initWithFloat:time];
	[[timer userInfo] setObject:timeNumber forKey:@"time"];
    [timeNumber release];

    // original image we started with
    NSImage *oldImage = [[timer userInfo] objectForKey:@"oldImage"];
    
    // we need a clear image to draw into, or else the shadows get superimposed
    NSImage *image = [[NSImage alloc] initWithSize:[self iconSize]];
    
    [image lockFocus];
    [oldImage dissolveToPoint:NSZeroPoint fraction:cos(time)]; // decreasing amount of old image
    [newImage dissolveToPoint:NSZeroPoint fraction:sin(time)]; // increasing amount of new image
    [image unlockFocus];
    [self setIconImage:image];
    [image release];
}

- (void)setIconImage:(NSImage *)iconImage{
    [[self cell] setIconImage: iconImage];
	[self setNeedsDisplay:YES];
}

- (NSImage *)arrowImage{
    return [[self cell] arrowImage];
	[self setNeedsDisplay:YES];
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
    return NSDragOperationCopy;
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
	
	mouseLoc.x -= size.width / 2;
	mouseLoc.y += size.height / 2;
	
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
		return [delegate imagePopUpButton:self cleanUpAfterDragOperation:operation];
}

#pragma mark Dragging destination

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    NSDragOperation sourceDragMask = [sender draggingSourceOperationMask];
	
    if (delegate &&
	 	(sourceDragMask & NSDragOperationCopy) && 
        [delegate respondsToSelector:@selector(imagePopUpButton:receiveDrag:)] && 
        [delegate respondsToSelector:@selector(imagePopUpButton:canReceiveDrag:)] && 
        [delegate imagePopUpButton:self canReceiveDrag:sender]) {
		
		highlight = YES;
        [self setNeedsDisplay:YES];
		return NSDragOperationCopy;
    }
    return NSDragOperationNone;
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
        
        NSRect highlightRect = NSInsetRect([self bounds], lineWidth/2.0, lineWidth/2.0);
        
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
