//
//  SKDragImageView.m
//  Skim
//
//  Created by Christiaan Hofman on 11/28/05.
/*
 This software is Copyright (c) 2005-2018
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

#import "SKDragImageView.h"
#import "NSMenu_SKExtensions.h"
#import "NSEvent_SKExtensions.h"
#import "NSView_SKExtensions.h"
#import "NSImage_SKExtensions.h"
#import "NSBitmapImageRep_SKExtensions.h"

@interface SKDragImageView (SKPrivate)
- (void)dragObject:(id<NSPasteboardWriting>)object withImage:(NSImage *)image fromFrame:(NSRect)frame forEvent:(NSEvent *)event;
@end

#if !DEPLOYMENT_BEFORE(10_7)
@interface SKDragImageView (SKLionExtensions) <NSDraggingSource>
@end
#endif

@implementation SKDragImageView

@synthesize delegate;

- (IBAction)show:(id)sender {
    if ([self isEditable] && [delegate respondsToSelector:@selector(showImageForDragImageView:)])
        [delegate showImageForDragImageView:self];
}

- (IBAction)togglePreviewPanel:(id)sender {
    if ([QLPreviewPanel sharedPreviewPanelExists] && [[QLPreviewPanel sharedPreviewPanel] isVisible])
        [[QLPreviewPanel sharedPreviewPanel] orderOut:nil];
    else
        [[QLPreviewPanel sharedPreviewPanel] makeKeyAndOrderFront:nil];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    SEL action = [menuItem action];
    if (action == @selector(cut:) || action == @selector(copy:) || action == @selector(delete:) || action == @selector(show:) || action == @selector(togglePreviewPanel:))
        return [self image] != nil && [self isEditable];
    else if (action == @selector(paste:))
        return [self isEditable];
    else if ([[SKDragImageView superclass] instancesRespondToSelector:_cmd])
        [super validateMenuItem:menuItem];
    return YES;
}

- (NSMenu *)menuForEvent:(NSEvent *)theEvent {
    NSMenu *menu = [self menu];
    if (menu == nil) {
        menu = [NSMenu menu];
        [menu addItemWithTitle:NSLocalizedString(@"Copy", @"Menu item title") action:@selector(copy:) target:self];
        [menu addItemWithTitle:NSLocalizedString(@"Paste", @"Menu item title") action:@selector(paste:) target:self];
        [menu addItemWithTitle:NSLocalizedString(@"Delete", @"Menu item title") action:@selector(delete:) target:self];
        [menu addItemWithTitle:NSLocalizedString(@"Show", @"Menu item title") action:@selector(show:) target:self];
        [menu addItemWithTitle:NSLocalizedString(@"Quick Look", @"Menu item title") action:@selector(togglePreviewPanel:) target:self];
        [self setMenu:menu];
    }
    menu = [[menu copy] autorelease];
	NSInteger i = [menu numberOfItems];
    
    while (i-- > 0) {
		NSMenuItem *item = (NSMenuItem *)[menu itemAtIndex:i];
		if ([self validateMenuItem:item] == NO)
			[menu removeItem:item];
	}
    
    return [menu numberOfItems] ? menu : nil;
}

- (void)keyDown:(NSEvent *)theEvent {
    if ([theEvent firstCharacter] == SKSpaceCharacter && [theEvent deviceIndependentModifierFlags] == 0) {
        [self togglePreviewPanel:nil];
    } else {
        [super keyDown:theEvent];
    }
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
        mouseLoc = [theEvent locationInView:self];
        isInside = [self mouse:mouseLoc inRect:[self bounds]];
        switch ([theEvent type]) {
            case NSLeftMouseDragged:
                if(isInside && [delegate respondsToSelector:@selector(draggedObjectForDragImageView:)]) {
                    id<NSPasteboardWriting> object = [delegate draggedObjectForDragImageView:self];
                    if (object) {
                        
                        NSRect bounds = [self bounds];
                        CGFloat scale = [self backingScale];
                        
                        NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithSize:bounds.size scale:scale drawingHandler:^(NSRect rect){
                            [[self cell] drawInteriorWithFrame:rect inView:self];
                        }];
                        
                        NSImage *dragImage = [NSImage bitmapImageWithSize:bounds.size scale:scale drawingHandler:^(NSRect rect){
                            [imageRep drawInRect:rect fromRect:rect operation:NSCompositeCopy fraction:0.7 respectFlipped:YES hints:nil];
                        }];
                        
                        [self dragObject:object withImage:dragImage fromFrame:bounds forEvent:theEvent];
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

#pragma mark NSDraggingSource protocol

#if DEPLOYMENT_BEFORE(10_7)

- (void)dragObject:(id<NSPasteboardWriting>)object withImage:(NSImage *)image fromFrame:(NSRect)frame forEvent:(NSEvent *)event {
    NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
    [pboard clearContents];
    [pboard writeObjects:[NSArray arrayWithObjects:object, nil]];
    
    NSPoint dragPoint = frame.origin;
    if ([self isFlipped])
        dragPoint.y += NSHeight(frame);
    
    [self dragImage:image at:dragPoint offset:NSZeroSize event:event pasteboard:pboard source:self slideBack:YES];
}

- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal{
    return isLocal || [self isEditable] == NO ? NSDragOperationNone : NSDragOperationCopy;
}

- (void)draggedImage:(NSImage *)anImage endedAt:(NSPoint)aPoint operation:(NSDragOperation)operation {
    [[NSPasteboard pasteboardWithName:NSDragPboard] clearContents];
}

#else

- (void)dragObject:(id<NSPasteboardWriting>)object withImage:(NSImage *)image fromFrame:(NSRect)frame forEvent:(NSEvent *)event {
    NSDraggingItem *dragItem = [[[NSDraggingItem alloc] initWithPasteboardWriter:object] autorelease];
    [dragItem setDraggingFrame:frame contents:image];
    [self beginDraggingSessionWithItems:[NSArray arrayWithObjects:dragItem, nil] event:event source:self];
}

- (NSDragOperation)draggingSession:(NSDraggingSession *)session sourceOperationMaskForDraggingContext:(NSDraggingContext)context {
    return context == NSDraggingContextWithinApplication || [self isEditable] == NO ? NSDragOperationNone : NSDragOperationCopy;
}

- (void)draggingSession:(NSDraggingSession *)session
           endedAtPoint:(NSPoint)screenPoint
              operation:(NSDragOperation)operation {
    [[session draggingPasteboard] clearContents];
}

#endif

@end
