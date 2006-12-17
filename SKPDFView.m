//
//  SKPDFView.m


//  This code is licensed under a BSD license. Please see the file LICENSE for details.
//
//  Created by Michael McCracken on 12/6/06.
//  Copyright 2006 Michael O. McCracken. All rights reserved.
//

#import "SKPDFView.h"


@interface PDFAnnotation (SKPDFViewExtensions)
@end

@implementation PDFAnnotation (SKPDFViewExtensions)
- (PDFDestination *)destination{
    return [[[PDFDestination alloc] initWithPage:[self page] atPoint:[self bounds].origin] autorelease];
}
@end

@interface NSCursor (SKPDFViewExtensions)
+ (NSCursor *)magnifyCursor;
@end

@implementation NSCursor (SKPDFViewExtensions)

+ (NSCursor *)magnifyCursor {
    static NSCursor *cursor = nil;
    if (nil == cursor) {
        NSImage *cursorImage = [[[NSImage imageNamed:@"magnifyTool"] copy] autorelease];
        [cursorImage setSize:NSMakeSize(32, 32)];
        NSSize s = [cursorImage size];
        cursor = [[NSCursor alloc] initWithImage:cursorImage hotSpot:NSMakePoint(s.height/2, s.width/2)];
    }
    return cursor;
}

@end


@implementation SKPDFView

- (id)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        toolMode = SKTextToolMode;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
        toolMode = SKTextToolMode;
    }
    return self;
}

- (SKToolMode)toolMode {
    return toolMode;
}

- (void)setToolMode:(SKToolMode)newToolMode {
    toolMode = newToolMode;
	[[NSNotificationCenter defaultCenter] postNotificationName:@"SKPDFViewToolModeChangedNotification" object:self];
    // hack to make sure we update the cursor
    [[self window] makeFirstResponder:self];
}

- (void)mouseDown:(NSEvent *)theEvent{
	if (toolMode == SKMagnifyToolMode) {
        [self handleMagnifyRequest:theEvent];
	} else if (toolMode == SKPopUpToolMode) {
        [self handlePopUpRequest:theEvent];
	} else if (toolMode == SKAnnotateToolMode) {
        [self handleAnnotationRequest:theEvent];
    } else if (toolMode == SKTextToolMode) {
        if ([theEvent modifierFlags] & NSCommandKeyMask)
            [self handlePopUpRequest:theEvent];
        else
            [super mouseDown:theEvent];
    }
}

- (void)mouseDragged:(NSEvent *)event {
	if (toolMode == SKMoveToolMode) {
		[self scrollByDragging:event];	
        // ??? PDFView's delayed layout seems to reset the cursor to an arrow
        [self performSelector:@selector(mouseMoved:) withObject:event afterDelay:0];
	} else {
		[super mouseDragged:event];
	}
}

- (NSCursor *)cursorForMouseMovedEvent:(NSEvent *)event {
    NSCursor *cursor = nil;
    NSPoint p = [[self documentView] convertPoint:[event locationInWindow] fromView:nil];
    if (NSPointInRect(p, [[self documentView] visibleRect])) {
        switch (toolMode) {
            case SKMoveToolMode:
                cursor = [NSCursor openHandCursor];
                break;
            case SKMagnifyToolMode:
                cursor = [NSCursor magnifyCursor];
                break;
            case SKPopUpToolMode:
                cursor = [NSCursor crosshairCursor]; // !!! probably not the most appropriate
                break;
            default:
                cursor = [NSCursor arrowCursor];
        }
    } else {
        // we want this cursor for toolbar and other views, generally
        cursor = [NSCursor arrowCursor];
    }
    return cursor;
}

- (void)mouseMoved:(NSEvent *)event {
    // we receive this message whenever we are first responder, so check the location
    if (toolMode == SKTextToolMode) {
        [super mouseMoved:event];
    } else {
        [[self cursorForMouseMovedEvent:event] set];
    }
}

- (void)handlePopUpRequest:(NSEvent *)theEvent{
    
    SKMainWindowController* controller = [[self window] windowController];
    NSPoint windowMouseLoc = [theEvent locationInWindow];

    NSPoint viewMouseLoc = [self convertPoint:windowMouseLoc 
                                     fromView:nil];
    PDFPage *page = [self pageForPoint:viewMouseLoc
                               nearest:YES];

    NSPoint pageSpaceMouseLoc = [self convertPoint:viewMouseLoc
                                            toPage:page];  
    
    
    PDFDestination *dest = [[[PDFDestination alloc] initWithPage:page
                                                         atPoint:pageSpaceMouseLoc] autorelease];
    
    if (([self areaOfInterestForMouse: theEvent] &  kPDFLinkArea) != 0) {
        PDFAnnotation *ann = [page annotationAtPoint:pageSpaceMouseLoc];
        if (ann != NULL){
            dest = [ann destination];
        }
    }    

    [controller showSubWindowAtPageNumber:[[self document] indexForPage:[dest page]]
                                 location:[dest point]];        
}

- (void)handleAnnotationRequest:(NSEvent *)theEvent {
    
    SKMainWindowController* controller = [[self window] windowController];
    NSPoint windowMouseLoc = [theEvent locationInWindow];

    NSPoint viewMouseLoc = [self convertPoint:windowMouseLoc 
                                     fromView:nil];
    PDFPage *page = [self pageForPoint:viewMouseLoc
                               nearest:YES];

    NSPoint pageSpaceMouseLoc = [self convertPoint:viewMouseLoc
                                            toPage:page];  
    
    
    PDFDestination *dest = [[[PDFDestination alloc] initWithPage:page
                                                         atPoint:pageSpaceMouseLoc] autorelease];
    
    if (([self areaOfInterestForMouse: theEvent] &  kPDFLinkArea) != 0) {
        PDFAnnotation *ann = [page annotationAtPoint:pageSpaceMouseLoc];
        if (ann != NULL){
            dest = [ann destination];
        }
    }    

    [controller createNewNoteAtPageNumber:[[self document] indexForPage:[dest page]]
                                 location:[dest point]];        
}

- (void)scrollByDragging:(NSEvent *)theEvent {
	NSPoint initialLocation = [theEvent locationInWindow];
	NSRect visibleRect = [[self documentView] visibleRect];
	BOOL keepGoing = YES;
	    
	[[NSCursor closedHandCursor] push];
	
	while (keepGoing) {
		theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask];
		switch ([theEvent type]) {
			case NSLeftMouseDragged:
            {
				NSPoint	newLocation;
				NSRect	newVisibleRect;
				float	xDelta, yDelta;
				
				newLocation = [theEvent locationInWindow];
				xDelta = initialLocation.x - newLocation.x;
				yDelta = initialLocation.y - newLocation.y;
				
				
				//	This was an amusing bug: without checking for flipped,
				//	you could drag up, and the document would sometimes move down!
				if ([self isFlipped])
					yDelta = -yDelta;
				
				newVisibleRect = NSOffsetRect (visibleRect, xDelta, yDelta);
				[[self documentView] scrollRectToVisible: newVisibleRect];
				//[super scrollRectToVisible: newVisibleRect];
			}
				break;
				
			case NSLeftMouseUp:
				keepGoing = NO;
				break;
				
			default:
				/* Ignore any other kind of event. */
				break;
		}								// end of switch (event type)
	}									// end of mouse-tracking loop
    
    [NSCursor pop];
}

- (void)handleMagnifyRequest:(NSEvent *)theEvent {
	NSPoint mouseLocWindow, mouseLocView, mouseLocDocumentView;
	NSRect oldBounds, newBounds, magRectWindow, magRectView;
	BOOL postNote, cursorVisible;
	float magWidth, magHeight, magOffsetX, magOffsetY;
	int originalLevel, currentLevel;
	float magScale; 	//0.4	// you may want to change this
	
	postNote = [[self documentView] postsBoundsChangedNotifications];
	[[self documentView] setPostsBoundsChangedNotifications: NO];
	
	oldBounds = [[self documentView] bounds];
	cursorVisible = YES;
	originalLevel = [theEvent clickCount] + 1;
	
	[[self window] discardCachedImage]; // make sure not use the cached image
	
	while (YES) {
		if ([theEvent type] == NSLeftMouseDragged || [theEvent type] == NSLeftMouseDown || [theEvent type] == NSFlagsChanged) {	            
			// set up the size and magScale
			if ([theEvent type] == NSLeftMouseDown || [theEvent type] == NSFlagsChanged) {	
				currentLevel = originalLevel + (([theEvent modifierFlags] & NSAlternateKeyMask)? 1 : 0);
				if (currentLevel <= 1) {
					magWidth = 150.0; magHeight = 100.0;
					magOffsetX = magWidth/2; magOffsetY = 0.5 * magHeight;
				} else if (currentLevel == 2) {
					magWidth = 380.0; magHeight = 250.0;
					magOffsetX = magWidth/2; magOffsetY = 0.5 * magHeight;
				} else { // currentLevel >= 3 // need to cache the image
					[[self window] restoreCachedImage];
					[[self window] cacheImageInRect:[self convertRect:[self visibleRect] toView: nil]];
				}
				if (([theEvent modifierFlags] & NSShiftKeyMask) == 0) {
					if ([theEvent modifierFlags] & NSCommandKeyMask)
						magScale = 0.25; 	// x4
					else if ([theEvent modifierFlags] & NSControlKeyMask)
						magScale = 0.66666; // x1.5
					else
						magScale = 0.4; 	// x2.5
				} else { // shrink the image with shift key -- can be very slow
					if ([theEvent modifierFlags] & NSCommandKeyMask)
						magScale = 4.0; 	// /4
					else if ([theEvent modifierFlags] & NSControlKeyMask)
						magScale = 1.5; 	// /1.5
					else
						magScale = 2.5; 	// /2.5
				}
			}
			// get Mouse location and check if it is with the view's rect
			
			if ([theEvent type] != NSFlagsChanged)
				mouseLocWindow = [theEvent locationInWindow];
			mouseLocView = [self convertPoint: mouseLocWindow fromView:nil];
			mouseLocDocumentView = [[self documentView] convertPoint:mouseLocWindow fromView:nil];
			// check if the mouse is in the rect
			
			if ([self mouse:mouseLocView inRect:[self visibleRect]]) {
				if (cursorVisible) {
					[NSCursor hide];
					cursorVisible = NO;
				}
				// define rect for magnification in window coordinate
				if (currentLevel >= 3) { 
					magRectWindow = [self convertRect:[self visibleRect] toView:nil];
				} else { // currentLevel <= 2
					magRectWindow = NSMakeRect(mouseLocWindow.x-magOffsetX, mouseLocWindow.y-magOffsetY, magWidth, magHeight);
					// restore the cached image in order to clear the rect
					[[self window] restoreCachedImage];
					[[self window] cacheImageInRect:  
						NSIntersectionRect(NSInsetRect(magRectWindow, -2.0, -2.0), [[self superview] convertRect:[[self superview] bounds] toView:nil])];
				}
				
				// resize bounds around mouseLocView
				newBounds = NSMakeRect(mouseLocDocumentView.x+magScale*(oldBounds.origin.x-mouseLocDocumentView.x), 
									   mouseLocDocumentView.y+magScale*(oldBounds.origin.y-mouseLocDocumentView.y),
									   magScale*(oldBounds.size.width), magScale*(oldBounds.size.height));
				
				[[self documentView] setBounds: newBounds];
				magRectView = NSInsetRect([self convertRect:magRectWindow fromView:nil], 1.0, 1.0);
				[self displayRect: magRectView]; // this flushes the buffer
												 // reset bounds
				[[self documentView] setBounds: oldBounds];
				
			}
			else { // mouse is not in the rect
				// show cursor 
				if (!cursorVisible) {
					[NSCursor unhide];
					cursorVisible = YES;
				}
				// restore the cached image in order to clear the rect
				[[self window] restoreCachedImage];
				// autoscroll
				if ([theEvent type] != NSFlagsChanged)
					[self autoscroll: theEvent];
				if (currentLevel >= 3)
					[[self window] cacheImageInRect:magRectWindow];
				else
					[[self window] discardCachedImage];
			}
		} else if ([theEvent type] == NSLeftMouseUp) {
			break;
		}
        theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask |
			NSLeftMouseDraggedMask | NSFlagsChangedMask];
	}
	
	[[self window] restoreCachedImage];
	[[self window] flushWindow];
	[NSCursor unhide];
	[[self documentView] setPostsBoundsChangedNotifications:postNote];
	[self flagsChanged:theEvent]; // update cursor
}

@end
