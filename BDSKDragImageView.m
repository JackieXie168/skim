//
//  BDSKDragImageView.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 11/28/05.
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

#import "BDSKDragImageView.h"
#import "NSBezierPath_BDSKExtensions.h"

@implementation BDSKDragImageView

- (id)initWithFrame:(NSRect)frameRect {
	if (self = [super initWithFrame:frameRect]) {
		delegate = nil;
		highlight = NO;
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
	if (self = [super initWithCoder:decoder]) {
		delegate = nil;
		highlight = NO;
	}
	return self;
}

- (id)delegate {
    return delegate;
}

- (void)setDelegate:(id)newDelegate {
	delegate = newDelegate;
}

- (IBAction)show:(id)sender {
    NSImage *image = [self image];
    
    if (image == nil) {
        NSBeep();
        return;
    }
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *basePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"SkimNote"];
    NSString *path = [basePath stringByAppendingPathExtension:@"tiff"];
    int i = 0;
    
    while ([fm fileExistsAtPath:path])
        path = [[basePath stringByAppendingFormat:@"-%i", ++i] stringByAppendingPathExtension:@"tiff"];
    
    [[image TIFFRepresentation] writeToFile:path atomically:YES];
    [[NSWorkspace sharedWorkspace] openTempFile:path];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    SEL action = [menuItem action];
    if (action == @selector(cut:) || action == @selector(copy:) || action == @selector(delete:) || action == @selector(show:))
        return [self image] != nil;
    else if (action == @selector(paste:))
        return YES;
    else if ([[BDSKDragImageView superclass] instancesRespondToSelector:_cmd])
        [super validateMenuItem:menuItem];
    return YES;
}

- (NSMenu *)menuForEvent:(NSEvent *)theEvent {
    NSMenu *menu = [[[super menuForEvent:theEvent] copy] autorelease];
	int i = [menu numberOfItems];
    
    while (i-- > 0) {
		NSMenuItem *item = (NSMenuItem *)[menu itemAtIndex:i];
		if ([self validateMenuItem:item] == NO)
			[menu removeItem:item];
	}
    
    return [menu numberOfItems] ? menu : nil;
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender{
    NSDragOperation dragOp = NSDragOperationNone;
	if ([delegate respondsToSelector:@selector(dragImageView:validateDrop:)])
		dragOp = [delegate dragImageView:self validateDrop:sender];
	if (dragOp != NSDragOperationNone) {
		highlight = YES;
        [self setKeyboardFocusRingNeedsDisplayInRect:[self bounds]];
		[self setNeedsDisplay:YES];
	}
	return dragOp;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender{
    highlight = NO;
    [self setKeyboardFocusRingNeedsDisplayInRect:[self bounds]];
	[self setNeedsDisplay:YES];
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    highlight = NO;
    [self setKeyboardFocusRingNeedsDisplayInRect:[self bounds]];
	[self setNeedsDisplay:YES];
	if ([delegate respondsToSelector:@selector(dragImageView:acceptDrop:)])
		return [delegate dragImageView:self acceptDrop:sender];
	return NO;
}

- (void)mouseDown:(NSEvent *)theEvent {
    if ([theEvent clickCount] == 2) {
        [self show:self];
        return;
    }
    
    BOOL keepOn = YES;
    BOOL isInside = YES;
    NSPoint mouseLoc;
    while(keepOn){
        theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask];
        mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        isInside = [self mouse:mouseLoc inRect:[self bounds]];
        switch ([theEvent type]) {
            case NSLeftMouseDragged:
                if(isInside){
					NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
					
					if ([delegate respondsToSelector:@selector(dragImageView:writeDataToPasteboard:)] &&
						[delegate dragImageView:self writeDataToPasteboard:pboard]) {
                   
						NSImage *dragImage = nil;
                        NSPoint dragPoint = mouseLoc;
						if ([delegate respondsToSelector:@selector(dragImageForDragImageView:)]) {
							dragImage = [delegate dragImageForDragImageView:self];
                            NSSize imageSize = [dragImage size];
                            dragPoint.x -= floorf(0.5 * imageSize.width);
                            dragPoint.y -= floorf(0.5 * imageSize.height);
						}
                        if (dragImage == nil) {
                            NSRect rect = [self bounds];
                            
                            dragPoint = rect.origin;
                            rect.origin = NSZeroPoint;
                            
                            NSImage *image = [[NSImage alloc] initWithSize:rect.size];

                            [image lockFocus];
                            [[self cell] drawInteriorWithFrame:rect inView:self];
                            [image lockFocus];
                            
                            dragImage = [[[NSImage alloc] initWithSize:rect.size] autorelease];
                            [dragImage lockFocus];
                            [image compositeToPoint:NSZeroPoint operation:NSCompositeCopy fraction:0.7];
                            [dragImage unlockFocus];
                            [image release];
                        }
                        [self dragImage:dragImage at:dragPoint offset:NSZeroSize event:theEvent pasteboard:pboard source:self slideBack:YES]; 
                    }
					keepOn = NO;
                    break;
                }
            case NSLeftMouseUp:
                keepOn = NO;
                break;
            default:
                keepOn = NO;
                break;
        }
    }
}

- (NSArray *)namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination{
    if ([delegate respondsToSelector:@selector(dragImageView:namesOfPromisedFilesDroppedAtDestination:)])
		return [delegate dragImageView:self namesOfPromisedFilesDroppedAtDestination:dropDestination];
	return nil;
}    

- (unsigned int)draggingSourceOperationMaskForLocal:(BOOL)isLocal{ 
    return isLocal ? NSDragOperationNone : NSDragOperationCopy; 
}

- (void)drawRect:(NSRect)aRect {
	[super drawRect:aRect];
	
	if (highlight == NO) return;
	
	[[NSColor alternateSelectedControlColor] set];
	[NSBezierPath setDefaultLineWidth:2.0];
	[NSBezierPath strokeRoundRectInRect:NSInsetRect(aRect, 2.0, 2.0) radius:5.0];
}

@end
