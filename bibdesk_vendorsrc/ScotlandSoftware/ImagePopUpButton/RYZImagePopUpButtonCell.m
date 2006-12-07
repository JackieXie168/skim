#import "RYZImagePopUpButtonCell.h"
#import "RYZImagePopUpButton.h"

@interface RYZImagePopUpButtonCell (Private)
- (void)setButtonCell:(NSButtonCell *)buttonCell;
@end

@implementation RYZImagePopUpButtonCell

// -----------------------------------------
//	Initialization and termination
// -----------------------------------------

// this used to be the designated intializer
- (id)initTextCell:(NSString *)stringValue pullsDown:(BOOL)pullsDown
{
    self = [self initImageCell:nil];
    return self;
}

// this is now the designated intializer
- (id)initImageCell:(NSImage *)anImage
{
    if (self = [super initTextCell:@"" pullsDown:NO]) {
		NSButtonCell *buttonCell = [[NSButtonCell alloc] initTextCell: @""];
		[buttonCell setBordered: NO];
		[buttonCell setHighlightsBy: NSContentsCellMask];
		[buttonCell setImagePosition: NSImageLeft];
        [self setButtonCell:buttonCell];
        [buttonCell release];
		
		RYZ_iconSize = NSMakeSize(32.0, 32.0);
		RYZ_showsMenuWhenIconClicked = NO;
		RYZ_iconActionEnabled = YES;
		RYZ_alwaysUsesFirstItemAsSelected = NO;
		RYZ_refreshesMenu = NO;

		[self setIconImage: anImage];	
		[self setArrowImage: nil];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
	if (self = [super initWithCoder:coder]) {
        [self setButtonCell:[coder decodeObjectForKey:@"buttonCell"]];
		
		RYZ_iconSize = [coder decodeSizeForKey:@"iconSize"];
		RYZ_showsMenuWhenIconClicked = [coder decodeBoolForKey:@"showsMenuWhenIconClicked"];
		RYZ_iconActionEnabled = [coder decodeBoolForKey:@"iconActionEnabled"];
		RYZ_alwaysUsesFirstItemAsSelected = [coder decodeBoolForKey:@"alwaysUsesFirstItemAsSelected"];
		RYZ_refreshesMenu = [coder decodeBoolForKey:@"refreshesMenu"];
		
		[self setIconImage:[coder decodeObjectForKey:@"iconImage"]];
		[self setArrowImage:[coder decodeObjectForKey:@"arrowImage"]];
		
		// hack to always get regular controls in a toolbar customization palette, there should be a better way
		[self setControlSize:NSRegularControlSize];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
	[super encodeWithCoder:encoder];
	[encoder encodeObject:RYZ_buttonCell forKey:@"buttonCell"];
	
	[encoder encodeSize:RYZ_iconSize forKey:@"iconSize"];
	[encoder encodeBool:RYZ_showsMenuWhenIconClicked forKey:@"showsMenuWhenIconClicked"];
	[encoder encodeBool:RYZ_iconActionEnabled forKey:@"iconActionEnabled"];
	[encoder encodeBool:RYZ_alwaysUsesFirstItemAsSelected forKey:@"alwaysUsesFirstItemAsSelected"];
	[encoder encodeBool:RYZ_refreshesMenu forKey:@"refreshesMenu"];
	
	[encoder encodeObject:RYZ_iconImage forKey:@"iconImage"];
	
	[encoder encodeObject:RYZ_arrowImage forKey:@"arrowImage"];
}

- (void)dealloc
{
    [self setButtonCell:nil]; // release the ivar and set to nil, or [super dealloc] causes a crash
    [RYZ_iconImage release];
    [RYZ_arrowImage release];
    [super dealloc];
}


// --------------------------------------------
//	Getting and setting the icon size
// --------------------------------------------

- (NSSize)iconSize
{
    return RYZ_iconSize;
}


- (void)setIconSize:(NSSize)iconSize
{
    RYZ_iconSize = iconSize;
	[RYZ_buttonCell setImage:nil]; // invalidate the image
}

- (BOOL)iconActionEnabled 
{
    return RYZ_iconActionEnabled;
}

- (void)setIconActionEnabled:(BOOL)newIconActionEnabled 
{
	RYZ_iconActionEnabled = newIconActionEnabled;
}


// ---------------------------------------------------------------------------------
//	Getting and setting whether the menu is shown when the icon is clicked
// ---------------------------------------------------------------------------------

- (BOOL)showsMenuWhenIconClicked
{
    return RYZ_showsMenuWhenIconClicked;
}


- (void)setShowsMenuWhenIconClicked: (BOOL) showsMenuWhenIconClicked
{
    RYZ_showsMenuWhenIconClicked = showsMenuWhenIconClicked;
}


// ---------------------------------------------
//      Getting and setting the icon image
// ---------------------------------------------

- (NSImage *)iconImage
{
    return RYZ_iconImage;
}


- (void)setIconImage:(NSImage *)iconImage
{
    [iconImage retain];
    [RYZ_iconImage release];
    RYZ_iconImage = iconImage;
	[RYZ_buttonCell setImage:nil]; // invalidate the image
}


// ----------------------------------------------
//      Getting and setting the arrow image
// ----------------------------------------------

- (NSImage *)arrowImage
{
    return RYZ_arrowImage;
}


- (void)setArrowImage:(NSImage *)arrowImage
{
    [arrowImage retain];
    [RYZ_arrowImage release];
    RYZ_arrowImage = arrowImage;
	[RYZ_buttonCell setImage:nil]; // invalidate the image
}

- (void)setAlternateImage:(NSImage *)alternateImage
{
	[super setAlternateImage:alternateImage];
	[RYZ_buttonCell setAlternateImage:nil]; // invalidate the image
	[RYZ_buttonCell setImage:nil]; // invalidate the image
}


- (BOOL)alwaysUsesFirstItemAsSelected {
    return RYZ_alwaysUsesFirstItemAsSelected;
}

- (void)setAlwaysUsesFirstItemAsSelected:(BOOL)newAlwaysUsesFirstItemAsSelected {
        RYZ_alwaysUsesFirstItemAsSelected = newAlwaysUsesFirstItemAsSelected;
}

- (NSMenuItem *)selectedItem
{
	if (RYZ_alwaysUsesFirstItemAsSelected) {
		return (NSMenuItem *)[self itemAtIndex:0];
	} else {
		return (NSMenuItem *)[super selectedItem];
	}
}

- (BOOL)refreshesMenu 
{
    return RYZ_refreshesMenu;
}

- (void)setRefreshesMenu:(BOOL)newRefreshesMenu 
{
    if (RYZ_refreshesMenu != newRefreshesMenu) {
        RYZ_refreshesMenu = newRefreshesMenu;
    }
}

- (BOOL)isEnabled 
{
	return [RYZ_buttonCell isEnabled];
}

- (void)setEnabled:(BOOL)flag 
{
	[RYZ_buttonCell setEnabled:flag];
}

- (BOOL)showsFirstResponder
{
	return [RYZ_buttonCell showsFirstResponder];
}

- (void)setShowsFirstResponder:(BOOL)flag
{
	[RYZ_buttonCell setShowsFirstResponder:flag];
}

- (void)setUsesItemFromMenu:(BOOL)flag
{
	[super setUsesItemFromMenu:flag];
	[RYZ_buttonCell setImage:nil]; // invalidate the image
}

// -----------------------------------------
//	Handling mouse/keyboard events
// -----------------------------------------

- (BOOL) trackMouse: (NSEvent *) event
			 inRect: (NSRect) cellFrame
			 ofView: (NSView *) controlView
       untilMouseUp: (BOOL) untilMouseUp
{
    BOOL trackingResult = YES;

    if ([event type] == NSKeyDown) {
		// Keyboard event
		unichar upAndDownArrowCharacters[2];
		upAndDownArrowCharacters[0] = NSUpArrowFunctionKey;
		upAndDownArrowCharacters[1] = NSDownArrowFunctionKey;
		NSString *upAndDownArrowString = [NSString stringWithCharacters: upAndDownArrowCharacters  length: 2];
		NSCharacterSet *upAndDownArrowCharacterSet = [NSCharacterSet characterSetWithCharactersInString: upAndDownArrowString];
		
		if ([self showsMenuWhenIconClicked] == YES ||
			[[event characters] rangeOfCharacterFromSet: upAndDownArrowCharacterSet].location != NSNotFound) {
			[self showMenuInView:controlView withEvent:event];
		} else if ([[event characters] rangeOfString: @" "].location != NSNotFound) {
			[self performClick: controlView];
		}
    } else {
		// Mouse event
		NSPoint mouseLocation = [controlView convertPoint: [event locationInWindow]  fromView: nil];
		NSSize iconSize = [self iconDrawSize];
		NSSize arrowSize = NSZeroSize;
		NSRect arrowRect;
		
		if ([self arrowImage] != nil) {
			arrowSize = [[self arrowImage] size];
		}
		
		arrowRect = NSMakeRect(cellFrame.origin.x + iconSize.width + 1.0, cellFrame.origin.y,
								arrowSize.width, arrowSize.height);
		
		if ([controlView isFlipped]) {
			arrowRect.origin.y += iconSize.height;
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
					// NSLog(@"drag event %@" , nextEvent);
					shouldSendAction = NO;
					if ([controlView respondsToSelector:@selector(startDraggingWithEvent:)] == NO ||
						[controlView performSelector:@selector(startDraggingWithEvent:) withObject:nextEvent] == NO)
						[self showMenuInView:controlView withEvent:nextEvent];

				} else {
					// NSLog(@"periodic event %@", nextEvent);
					shouldSendAction = NO;
					
					// showMenu expects a mouseEvent, 
					// so we send it the original event:
					[self showMenuInView:controlView withEvent:event];
				}

			}
		} else {
			trackingResult = [RYZ_buttonCell trackMouse: event
											  inRect: cellFrame
											  ofView: controlView
										untilMouseUp: [[RYZ_buttonCell class] prefersTrackingUntilMouseUp]];  // NO for NSButton
			
			if (trackingResult == YES && [self iconActionEnabled]) {
				shouldSendAction = YES;
			}
		}
		if (shouldSendAction) {
			NSMenuItem *selectedItem = [self selectedItem];
			[NSEvent stopPeriodicEvents];
			[[NSApplication sharedApplication] sendAction: [selectedItem action]  
													   to: [selectedItem target]
													 from: selectedItem];
			
		}
    }
    
//    NSLog(@"trackingResult: %d", trackingResult);
    
    return trackingResult;
}

- (void)showMenuInView:(NSView *)controlView withEvent:(NSEvent *)event
{
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


- (void)performClick:(id)sender
{
    [RYZ_buttonCell performClick: sender];
    [super performClick: sender];
}


// -----------------------------------
//	Drawing and highlighting
// -----------------------------------

- (NSSize)iconDrawSize {
	NSSize size = [self iconSize];
	if ([self controlSize] != NSRegularControlSize) {
		// for small and mini controls we just scale the icon by 75% 
		size = NSMakeSize(size.width * 0.75, size.height * 0.75);
	}
	return size;
}

- (NSSize)cellSize {
	NSSize size = [self iconDrawSize];
	if ([self arrowImage]) {
		size.width += [[self arrowImage] size].width;
	}
	return size;
}

- (void)drawWithFrame:(NSRect)cellFrame  inView:(NSView *)controlView
{
	if ([RYZ_buttonCell image] == nil || [self usesItemFromMenu]) {
		// we need to redraw the image

		NSImage *iconImage;
		
		if ([self usesItemFromMenu] == NO) {
			iconImage = [self iconImage];
		} else {
			iconImage = [[[[self selectedItem] image] copy] autorelease];
		}
		
		[iconImage setSize: [self iconSize]];
		
		NSSize drawSize = [self iconDrawSize];
		NSRect iconRect = NSZeroRect;
		NSRect iconDrawRect = NSZeroRect;
		NSRect arrowRect = NSZeroRect;
		NSRect arrowDrawRect = NSZeroRect;
		NSImage *arrowImage = [self arrowImage];
		
		iconRect.size = [self iconSize];
		iconDrawRect.size = drawSize;
		if (arrowImage) {
			arrowRect.size = arrowDrawRect.size = [arrowImage size];
			arrowDrawRect.origin = NSMakePoint(NSWidth(iconDrawRect), 1.0);
			drawSize.width += NSWidth(arrowRect);
		}
		
		NSImage *popUpImage = [[NSImage alloc] initWithSize: drawSize];
		
		[popUpImage lockFocus];
		if (iconImage)
			[iconImage drawInRect: iconDrawRect  fromRect: iconRect  operation: NSCompositeSourceOver  fraction: 1.0];
		if (arrowImage)
			[arrowImage drawInRect: arrowDrawRect  fromRect: arrowRect  operation: NSCompositeSourceOver  fraction: 1.0];
		[popUpImage unlockFocus];

		[RYZ_buttonCell setImage: popUpImage];
		[popUpImage release];
		
		if ([self alternateImage]) {
			popUpImage = [[NSImage alloc] initWithSize: drawSize];
			
			[popUpImage lockFocus];
			[[self alternateImage] drawInRect: iconDrawRect  fromRect: iconRect  operation: NSCompositeSourceOver  fraction: 1.0];
			if (arrowImage)
				[arrowImage drawInRect: arrowDrawRect  fromRect: arrowRect  operation: NSCompositeSourceOver  fraction: 1.0];
			[popUpImage unlockFocus];
		
			[RYZ_buttonCell setAlternateImage: popUpImage];
			[popUpImage release];
		}
    }
	//   NSLog(@"cellFrame: %@  selectedItem: %@", NSStringFromRect(cellFrame), [[self selectedItem] title]);
	
    [RYZ_buttonCell drawWithFrame: cellFrame  inView: controlView];
}

- (void)highlight:(BOOL)flag  withFrame:(NSRect)cellFrame  inView:(NSView *)controlView
{
	[RYZ_buttonCell highlight: flag  withFrame: cellFrame  inView: controlView];
	[super highlight: flag  withFrame: cellFrame  inView: controlView];
}

@end

@implementation RYZImagePopUpButtonCell (Private)

- (void)setButtonCell:(NSButtonCell *)buttonCell;
{
    if(RYZ_buttonCell != buttonCell){
        [RYZ_buttonCell release];
        RYZ_buttonCell = [buttonCell retain];
    }
}

@end
