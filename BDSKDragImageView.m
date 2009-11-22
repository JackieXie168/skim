//
//  BDSKDragImageView.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 11/28/05.
/*
 This software is Copyright (c) 2005-2009-2008
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

@implementation BDSKDragImageView

- (id <BDSKDragImageViewDelegate>)delegate {
    return delegate;
}

- (void)setDelegate:(id <BDSKDragImageViewDelegate>)newDelegate {
	delegate = newDelegate;
}

- (IBAction)show:(id)sender {
    NSImage *image = [self image];
    
    if ([self isEditable] == NO) {
        return;
    } else if (image == nil || [self isEditable] == NO) {
        NSBeep();
        return;
    }
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *basePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"SkimNote"];
    NSString *path = [basePath stringByAppendingPathExtension:@"tiff"];
    NSInteger i = 0;
    
    while ([fm fileExistsAtPath:path])
        path = [[basePath stringByAppendingFormat:@"-%ld", (long)++i] stringByAppendingPathExtension:@"tiff"];
    
    [[image TIFFRepresentation] writeToFile:path atomically:YES];
    [[NSWorkspace sharedWorkspace] openTempFile:path];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    SEL action = [menuItem action];
    if (action == @selector(cut:) || action == @selector(copy:) || action == @selector(delete:) || action == @selector(show:))
        return [self image] != nil && [self isEditable];
    else if (action == @selector(paste:))
        return [self isEditable];
    else if ([[BDSKDragImageView superclass] instancesRespondToSelector:_cmd])
        [super validateMenuItem:menuItem];
    return YES;
}

- (NSMenu *)menuForEvent:(NSEvent *)theEvent {
    NSMenu *menu = [[[super menuForEvent:theEvent] copy] autorelease];
	NSInteger i = [menu numberOfItems];
    
    while (i-- > 0) {
		NSMenuItem *item = (NSMenuItem *)[menu itemAtIndex:i];
		if ([self validateMenuItem:item] == NO)
			[menu removeItem:item];
	}
    
    return [menu numberOfItems] ? menu : nil;
}

- (void)mouseDown:(NSEvent *)theEvent {
    if ([self isEditable] == NO) {
        return;
    } else if ([theEvent clickCount] == 2) {
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
                   
                        NSRect rect = [self bounds];
                        NSPoint dragPoint = rect.origin;
                        rect.origin = NSZeroPoint;
                        
                        NSImage *image = [[NSImage alloc] initWithSize:rect.size];

                        [image lockFocus];
                        [[self cell] drawInteriorWithFrame:rect inView:self];
                        [image lockFocus];
                        
                        NSImage *dragImage = [[[NSImage alloc] initWithSize:rect.size] autorelease];
                        [dragImage lockFocus];
                        [image compositeToPoint:NSZeroPoint operation:NSCompositeCopy fraction:0.7];
                        [dragImage unlockFocus];
                        [image release];
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

- (NSUInteger)draggingSourceOperationMaskForLocal:(BOOL)isLocal{ 
    return isLocal || [self isEditable] == NO ? NSDragOperationNone : NSDragOperationCopy; 
}

@end
