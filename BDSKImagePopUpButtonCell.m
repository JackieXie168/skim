//
//  BDSKImagePopUpButtonCell.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 3/22/05.
//
/*
 This software is Copyright (c) 2005-2008
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

#import "BDSKImagePopUpButtonCell.h"
#import "BDSKImagePopUpButton.h"

@interface BDSKImagePopUpButtonCell (Private)

- (void)setButtonCell:(NSButtonCell *)buttonCell;
- (void)showMenuInView:(NSView *)controlView withEvent:(NSEvent *)event;
- (NSSize)iconDrawSize;

@end

@implementation BDSKImagePopUpButtonCell

// this used to be the designated intializer
- (id)initTextCell:(NSString *)stringValue pullsDown:(BOOL)pullsDown{
    self = [self initImageCell:nil];
    return self;
}

// this is now the designated intializer
- (id)initImageCell:(NSImage *)anImage{
    if (self = [super initTextCell:@"" pullsDown:NO]) {
		NSButtonCell *cell = [[NSButtonCell alloc] initTextCell: @""];
		[cell setBordered: NO];
		[cell setHighlightsBy: NSContentsCellMask];
		[cell setImagePosition: NSImageLeft];
        [self setButtonCell:cell];
        [cell release];
		
		iconSize = NSMakeSize(32.0, 32.0);
		showsMenuWhenIconClicked = NO;
		iconActionEnabled = YES;
		alwaysUsesFirstItemAsSelected = NO;
		refreshesMenu = NO;
        
        static NSImage *defaultArrowImage = nil;
        if (defaultArrowImage == nil) {
            defaultArrowImage = [[NSImage alloc] initWithSize:NSMakeSize(7.0, 5.0)];
            [defaultArrowImage lockFocus];
            NSBezierPath *path = [NSBezierPath bezierPath];
            [path moveToPoint:NSMakePoint(0.5, 5.0)];
            [path lineToPoint:NSMakePoint(6.5, 5.0)];
            [path lineToPoint:NSMakePoint(3.5, 0.0)];
            [path closePath];
            [[NSColor colorWithCalibratedWhite:0.0 alpha:0.75] setFill];
            [path fill];
            [defaultArrowImage unlockFocus];
        }
        
		[self setIconImage: anImage];	
		[self setArrowImage: defaultArrowImage];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)coder{
	if (self = [super initWithCoder:coder]) {
        [self setButtonCell:[coder decodeObjectForKey:@"buttonCell"]];
		
		iconSize = [coder decodeSizeForKey:@"iconSize"];
		showsMenuWhenIconClicked = [coder decodeBoolForKey:@"showsMenuWhenIconClicked"];
		iconActionEnabled = [coder decodeBoolForKey:@"iconActionEnabled"];
		alwaysUsesFirstItemAsSelected = [coder decodeBoolForKey:@"alwaysUsesFirstItemAsSelected"];
		refreshesMenu = [coder decodeBoolForKey:@"refreshesMenu"];
		
		[self setIconImage:[coder decodeObjectForKey:@"iconImage"]];
		[self setArrowImage:[coder decodeObjectForKey:@"arrowImage"]];
		
		// hack to always get regular controls in a toolbar customization palette, there should be a better way
		[self setControlSize:NSRegularControlSize];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder{
	[super encodeWithCoder:encoder];
	[encoder encodeObject:buttonCell forKey:@"buttonCell"];
	
	[encoder encodeSize:iconSize forKey:@"iconSize"];
	[encoder encodeBool:showsMenuWhenIconClicked forKey:@"showsMenuWhenIconClicked"];
	[encoder encodeBool:iconActionEnabled forKey:@"iconActionEnabled"];
	[encoder encodeBool:alwaysUsesFirstItemAsSelected forKey:@"alwaysUsesFirstItemAsSelected"];
	[encoder encodeBool:refreshesMenu forKey:@"refreshesMenu"];
	
	[encoder encodeObject:iconImage forKey:@"iconImage"];
	
	[encoder encodeObject:arrowImage forKey:@"arrowImage"];
}

- (void)dealloc{
    [self setButtonCell:nil]; // release the ivar and set to nil, or [super dealloc] causes a crash
    [iconImage release];
    [arrowImage release];
    [super dealloc];
}

#pragma mark Accessors

- (NSSize)iconSize{
    return iconSize;
}

- (void)setIconSize:(NSSize)aSize{
    iconSize = aSize;
	[buttonCell setImage:nil]; // invalidate the image
}

- (BOOL)iconActionEnabled {
    return iconActionEnabled;
}

- (void)setIconActionEnabled:(BOOL)flag {
	iconActionEnabled = flag;
}

- (BOOL)showsMenuWhenIconClicked{
    return showsMenuWhenIconClicked;
}


- (void)setShowsMenuWhenIconClicked:(BOOL)flag{
    showsMenuWhenIconClicked = flag;
}

- (NSImage *)iconImage{
    return iconImage;
}

- (void)setIconImage:(NSImage *)anImage{
    if (anImage != iconImage) {
        [iconImage release];
        iconImage = [anImage retain];
        [buttonCell setImage:nil]; // invalidate the image
    }
}

- (NSImage *)arrowImage{
    return arrowImage;
}

- (void)setArrowImage:(NSImage *)anImage{
    if (anImage != iconImage) {
        [arrowImage release];
        arrowImage = [anImage retain];
        [buttonCell setImage:nil]; // invalidate the image
    }
}

- (void)setAlternateImage:(NSImage *)anImage{
	[super setAlternateImage:anImage];
	[buttonCell setAlternateImage:nil]; // invalidate the image
	[buttonCell setImage:nil]; // invalidate the image
}


- (BOOL)alwaysUsesFirstItemAsSelected {
    return alwaysUsesFirstItemAsSelected;
}

- (void)setAlwaysUsesFirstItemAsSelected:(BOOL)flag {
    alwaysUsesFirstItemAsSelected = flag;
}

- (NSMenuItem *)selectedItem{
	if (alwaysUsesFirstItemAsSelected) {
		return (NSMenuItem *)[self itemAtIndex:0];
	} else {
		return (NSMenuItem *)[super selectedItem];
	}
}

- (BOOL)refreshesMenu {
    return refreshesMenu;
}

- (void)setRefreshesMenu:(BOOL)flag {
    if (refreshesMenu != flag) {
        refreshesMenu = flag;
    }
}

- (BOOL)isEnabled {
	return [buttonCell isEnabled];
}

- (void)setEnabled:(BOOL)flag {
	[buttonCell setEnabled:flag];
}

- (BOOL)showsFirstResponder{
	return [buttonCell showsFirstResponder];
}

- (void)setShowsFirstResponder:(BOOL)flag{
	[buttonCell setShowsFirstResponder:flag];
}

- (void)setUsesItemFromMenu:(BOOL)flag{
	[super setUsesItemFromMenu:flag];
	[buttonCell setImage:nil]; // invalidate the image
}

#pragma mark Handling mouse/keyboard events

- (BOOL) trackMouse: (NSEvent *) event
			 inRect: (NSRect) cellFrame
			 ofView: (NSView *) controlView
       untilMouseUp: (BOOL) untilMouseUp{
    BOOL trackingResult = YES;

    if ([event type] == NSKeyDown) {
		// Keyboard event
        NSString *characters = [event charactersIgnoringModifiers];
        unichar ch = [characters length] > 0 ? [characters characterAtIndex:0] : 0;
		
		if ([self showsMenuWhenIconClicked] == YES || ch == NSUpArrowFunctionKey || ch == NSDownArrowFunctionKey) {
			[self showMenuInView:controlView withEvent:event];
		} else if (ch == ' ') {
			[self performClick: controlView];
		}
    } else {
		// Mouse event
		NSPoint mouseLocation = [controlView convertPoint: [event locationInWindow]  fromView: nil];
		NSSize iconDrawSize = [self iconDrawSize];
		NSSize arrowSize = NSZeroSize;
		NSRect arrowRect;
		
		if ([self arrowImage] != nil) {
			arrowSize = [[self arrowImage] size];
		}
		
		arrowRect = NSMakeRect(cellFrame.origin.x + iconDrawSize.width + 1.0, cellFrame.origin.y,
								arrowSize.width, arrowSize.height);
		
		if ([controlView isFlipped]) {
			arrowRect.origin.y += iconDrawSize.height;
			arrowRect.origin.y -= arrowSize.height;
		}
		
/*		NSLog(@"mouseLocation: %@", NSStringFromPoint(mouseLocation));
		NSLog(@"isFlipped: %d", [controlView isFlipped]);
		NSLog(@"arrowRect: %@", NSStringFromRect(arrowRect));
*/		
		BOOL shouldSendAction = NO;

		
		if ([event type] == NSLeftMouseDown) {
			if (([self showsMenuWhenIconClicked] == YES && [self iconActionEnabled])
			    || [controlView mouse: mouseLocation inRect: arrowRect]) {
				[self showMenuInView:controlView withEvent:event];
			} else {
				// Here we use periodic events to get 
				// the menu to show up after a delay, but 
				// only if we didn't mouse-up first.
				// Mouse-up causes the action to be sent
				// Drag or waiting for the delay causes the menu to show.
				// The period is meaningless because we 
				// cancel after the first event every time.
				[NSEvent startPeriodicEventsAfterDelay:0.7
											withPeriod:1];
				
				NSEvent *nextEvent = [NSApp nextEventMatchingMask:(NSLeftMouseUpMask | NSPeriodicMask | NSLeftMouseDraggedMask)
														untilDate:[NSDate distantFuture]
														   inMode:NSEventTrackingRunLoopMode
														  dequeue:YES];
				[NSEvent stopPeriodicEvents];
				if ([nextEvent type] == NSLeftMouseUp) {
					// if we mouse-up inside the button, send the action.
					// note that because we show the menu on drags,
					// we don't need to check that we're still inside 
					// before we send the action.
					
					if ([self iconActionEnabled]) {
						shouldSendAction = YES;
					} else {
						[self showMenuInView:controlView withEvent:nextEvent];
					}
					
				} else if([nextEvent type] == NSLeftMouseDragged) {
                    // test option key to see if we should drag-copy or show the menu, since the drag-to-copy behavior is inconsistent, particularly in BibEditor (see bug #1519481)
					shouldSendAction = NO;
					if (([nextEvent modifierFlags] & NSAlternateKeyMask) > 0 &&
                        [controlView respondsToSelector:@selector(startDraggingWithEvent:)]){ 
                        if([(id)controlView startDraggingWithEvent:nextEvent] == NO)
                            [self showMenuInView:controlView withEvent:nextEvent];
                    } else {
                        [self showMenuInView:controlView withEvent:nextEvent];
                    }

				} else {
					// NSLog(@"periodic event %@", nextEvent);
					shouldSendAction = NO;
					
					// showMenu expects a mouseEvent, 
					// so we send it the original event:
					[self showMenuInView:controlView withEvent:event];
				}

			}
		} else {
			trackingResult = [buttonCell trackMouse: event
											  inRect: cellFrame
											  ofView: controlView
										untilMouseUp: [[buttonCell class] prefersTrackingUntilMouseUp]];  // NO for NSButton
			
			if (trackingResult == YES && [self iconActionEnabled]) {
				shouldSendAction = YES;
			}
		}
		if (shouldSendAction) {
			NSMenuItem *selectedItem = [self selectedItem];
			[NSEvent stopPeriodicEvents];
            [NSApp sendAction: [selectedItem action] to: [selectedItem target] from: selectedItem];
		}
    }
    
//    NSLog(@"trackingResult: %d", trackingResult);
    
    return trackingResult;
}

- (void)performClick:(id)sender{
    [buttonCell performClick: sender];
    [super performClick: sender];
    if ([self iconActionEnabled]) {
        NSMenuItem *selectedItem = [self selectedItem];
        [NSApp sendAction: [selectedItem action] to: [selectedItem target] from: selectedItem];
    }
}


#pragma mark Drawing and highlighting

- (NSSize)cellSize {
	NSSize size = [self iconDrawSize];
	if ([self arrowImage]) {
		size.width += [[self arrowImage] size].width;
	}
	return size;
}

- (void)drawWithFrame:(NSRect)cellFrame  inView:(NSView *)controlView{
	if ([buttonCell image] == nil || [self usesItemFromMenu]) {
		// we need to redraw the image

		NSImage *image = [self usesItemFromMenu] ? [[self selectedItem] image] : [self iconImage];
				
		NSSize drawSize = [self iconDrawSize];
		NSRect iconRect = NSZeroRect;
		NSRect iconDrawRect = NSZeroRect;
		NSRect arrowRect = NSZeroRect;
		NSRect arrowDrawRect = NSZeroRect;
 		
		iconRect.size = [image size];
		iconDrawRect.size = drawSize;
		if (arrowImage) {
			arrowRect.size = arrowDrawRect.size = [arrowImage size];
			arrowDrawRect.origin = NSMakePoint(NSWidth(iconDrawRect), 1.0);
			drawSize.width += NSWidth(arrowRect);
		}
		
		NSImage *popUpImage = [[NSImage alloc] initWithSize: drawSize];
		
		[popUpImage lockFocus];
		if (image)
			[image drawInRect: iconDrawRect  fromRect: iconRect  operation: NSCompositeSourceOver  fraction: 1.0];
		if (arrowImage)
			[arrowImage drawInRect: arrowDrawRect  fromRect: arrowRect  operation: NSCompositeSourceOver  fraction: 1.0];
		[popUpImage unlockFocus];

		[buttonCell setImage: popUpImage];
		[popUpImage release];
		
		if ([self alternateImage]) {
			popUpImage = [[NSImage alloc] initWithSize: drawSize];
			
			[popUpImage lockFocus];
			[[self alternateImage] drawInRect: iconDrawRect  fromRect: iconRect  operation: NSCompositeSourceOver  fraction: 1.0];
			if (arrowImage)
				[arrowImage drawInRect: arrowDrawRect  fromRect: arrowRect  operation: NSCompositeSourceOver  fraction: 1.0];
			[popUpImage unlockFocus];
		
			[buttonCell setAlternateImage: popUpImage];
			[popUpImage release];
		}
    }
	//   NSLog(@"cellFrame: %@  selectedItem: %@", NSStringFromRect(cellFrame), [[self selectedItem] title]);
	
    [buttonCell drawWithFrame: cellFrame  inView: controlView];
}

- (void)highlight:(BOOL)flag  withFrame:(NSRect)cellFrame  inView:(NSView *)controlView{
	[buttonCell highlight: flag  withFrame: cellFrame  inView: controlView];
	[super highlight: flag  withFrame: cellFrame  inView: controlView];
}

@end

@implementation BDSKImagePopUpButtonCell (Private)

- (void)setButtonCell:(NSButtonCell *)aCell{
    if(aCell != buttonCell){
        [buttonCell release];
        buttonCell = [aCell retain];
    }
}

- (void)showMenuInView:(NSView *)controlView withEvent:(NSEvent *)event{
	NSPoint newLoc = NSMakePoint(NSMinX([controlView bounds]), NSMaxY([controlView bounds]) + 4);
	newLoc = [controlView convertPoint:newLoc toView:nil];
    NSEventType evt = [event type];
    NSEvent *newEvent;
    
    switch(evt){
        case NSKeyDown:
            newEvent = [NSEvent keyEventWithType:evt
                                        location:newLoc
                                   modifierFlags:[event modifierFlags]
                                       timestamp:[event timestamp]
                                    windowNumber:[event windowNumber]
                                         context:[event context]
                                      characters:[event characters]
                     charactersIgnoringModifiers:[event charactersIgnoringModifiers]
                                       isARepeat:[event isARepeat]
                                         keyCode:[event keyCode]];
            break;
            
        default:
            newEvent = [NSEvent mouseEventWithType: [event type]
                                          location: newLoc
                                     modifierFlags: [event modifierFlags]
                                         timestamp: [event timestamp]
                                      windowNumber: [event windowNumber]
                                           context: [event context]
                                       eventNumber: [event eventNumber]
                                        clickCount: [event clickCount]
                                          pressure: [event pressure]];
    }
	
	if ([self refreshesMenu] && [controlView respondsToSelector:@selector(menuForCell:)]) {
		[self setMenu:[controlView performSelector:@selector(menuForCell:) withObject:self]];
	}
	[NSMenu popUpContextMenu: [self menu]  withEvent: newEvent  forView: controlView];
}

- (NSSize)iconDrawSize {
	NSSize size = [self iconSize];
	if ([self controlSize] != NSRegularControlSize) {
		// for small and mini controls we just scale the icon by 75% 
		size = NSMakeSize(size.width * 0.75, size.height * 0.75);
	}
	return size;
}

@end
