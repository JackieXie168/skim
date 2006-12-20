//
//  SKPDFView.m


//  This code is licensed under a BSD license. Please see the file LICENSE for details.
//
//  Created by Michael McCracken on 12/6/06.
//  Copyright 2006 Michael O. McCracken. All rights reserved.
//

#import "SKPDFView.h"
#import "SKNavigationWindow.h"


@interface PDFAnnotation (SKPDFViewExtensions)
@end

@implementation PDFAnnotation (SKPDFViewExtensions)
- (PDFDestination *)destination{
    return [[[PDFDestination alloc] initWithPage:[self page] atPoint:[self bounds].origin] autorelease];
}
@end

@interface NSCursor (SKPDFViewExtensions)
+ (NSCursor *)zoomInCursor;
+ (NSCursor *)zoomOutCursor;
@end

@implementation NSCursor (SKPDFViewExtensions)

+ (NSCursor *)zoomInCursor {
    static NSCursor *zoomInCursor = nil;
    if (nil == zoomInCursor) {
        NSImage *cursorImage = [[[NSImage imageNamed:@"zoomInCursor"] copy] autorelease];
        zoomInCursor = [[NSCursor alloc] initWithImage:cursorImage hotSpot:NSMakePoint(6.0, 6.0)];
    }
    return zoomInCursor;
}

+ (NSCursor *)zoomOutCursor {
    static NSCursor *zoomOutCursor = nil;
    if (nil == zoomOutCursor) {
        NSImage *cursorImage = [[[NSImage imageNamed:@"zoomOutCursor"] copy] autorelease];
        zoomOutCursor = [[NSCursor alloc] initWithImage:cursorImage hotSpot:NSMakePoint(6.0, 6.0)];
    }
    return zoomOutCursor;
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

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self doAutohide:NO]; // invalidates and releases the timer
    [navWindow release];
    [super dealloc];
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
    switch (toolMode) {
        case SKMoveToolMode:
            [[NSCursor closedHandCursor] push];
            break;
        case SKTextToolMode:
            if ([theEvent modifierFlags] & NSCommandKeyMask)
                [self popUpWithEvent:theEvent];
            else
                [super mouseDown:theEvent];
            break;
        case SKMagnifyToolMode:
            [self magnifyWithEvent:theEvent];
            break;
        case SKPopUpToolMode:
            [self popUpWithEvent:theEvent];
            break;
        case SKAnnotateToolMode:
            [super mouseDown:theEvent];
            break;
    }
    
    // Window hides anyway on a mouse click, but we need to cancel the timer and set flags properly
    if (hasNavigation && [navWindow isVisible]) {
        [self doAutohide:NO];
        [navWindow hide];
    }
}

- (void)mouseUp:(NSEvent *)theEvent{
    if (toolMode == SKMoveToolMode) {
        [NSCursor pop];
    } else if (toolMode == SKAnnotateToolMode) {
        [self annotateWithEvent:theEvent];
    }
    [super mouseUp:theEvent];
}

- (void)mouseDragged:(NSEvent *)event {
	if (toolMode == SKMoveToolMode) {
		[self dragWithEvent:event];	
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
                cursor = ([event modifierFlags] & NSShiftKeyMask) ? [NSCursor zoomOutCursor] : [NSCursor zoomInCursor];
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

    if (autohidesCursor || hasNavigation) {
        if (hasNavigation)
            [navWindow orderFront:self];
        [self doAutohide:YES];
    }
}

- (void)flagsChanged:(NSEvent *)event {
    [super flagsChanged:event];
    if (toolMode == SKMagnifyToolMode) {
        NSCursor *cursor = ([event modifierFlags] & NSShiftKeyMask) ? [NSCursor zoomOutCursor] : [NSCursor zoomInCursor];
        [cursor set];
    }
}

- (void)autohideTimerFired:(NSTimer *)aTimer {
    if (autohideTimer) {
        [autohideTimer invalidate];
        [autohideTimer release];
        autohideTimer = nil;
    }
    if (autohidesCursor)
        [NSCursor setHiddenUntilMouseMoves:YES];
    if (hasNavigation)
        [navWindow hide];
}

- (void)doAutohide:(BOOL)flag {
    if (autohideTimer) {
        [autohideTimer invalidate];
        [autohideTimer release];
        autohideTimer = nil;
    }
    if (flag)
        autohideTimer  = [[NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(autohideTimerFired:) userInfo:nil repeats:NO] retain];
}
   
- (void)setHasNavigation:(BOOL)hasNav autohidesCursor:(BOOL)hideCursor {
    hasNavigation = hasNav;
    autohidesCursor = hideCursor;
    
    if (hasNavigation) {
        if ([[self window] screen] != [navWindow screen]) {
            [navWindow release];
            navWindow = nil;
        }
        if (navWindow == nil) {
            navWindow = [[SKNavigationWindow alloc] initWithPDFView:self];
            [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(handleWindowWillCloseNotification:) 
                                                         name: NSWindowWillCloseNotification object: [self window]];
        }
    } else if ([navWindow isVisible]) {
        [navWindow orderOut:self];
    }
    [self doAutohide:autohidesCursor || hasNavigation];
}

- (void)handleWindowWillCloseNotification:(NSNotification *)notification {
    [navWindow orderOut:self];
}

- (void)popUpWithEvent:(NSEvent *)theEvent{
    
    SKMainWindowController* controller = [[self window] windowController];
    NSPoint windowMouseLoc = [theEvent locationInWindow];

    NSPoint viewMouseLoc = [self convertPoint:windowMouseLoc fromView:nil];
    PDFPage *page = [self pageForPoint:viewMouseLoc nearest:YES];

    NSPoint pageSpaceMouseLoc = [self convertPoint:viewMouseLoc toPage:page];  
    
    
    PDFDestination *dest = [[[PDFDestination alloc] initWithPage:page atPoint:pageSpaceMouseLoc] autorelease];
    
    if (([self areaOfInterestForMouse: theEvent] &  kPDFLinkArea) != 0) {
        PDFAnnotation *ann = [page annotationAtPoint:pageSpaceMouseLoc];
        if (ann != NULL){
            dest = [ann destination];
        }
    }    

    [controller showSubWindowAtPageNumber:[[self document] indexForPage:[dest page]] location:[dest point]];        
}

- (void)annotateWithEvent:(NSEvent *)theEvent {
    
    SKMainWindowController* controller = [[self window] windowController];
    NSPoint windowMouseLoc = [theEvent locationInWindow];

    NSPoint viewMouseLoc = [self convertPoint:windowMouseLoc fromView:nil];
    PDFPage *page = [self pageForPoint:viewMouseLoc nearest:YES];

    NSPoint pageSpaceMouseLoc = [self convertPoint:viewMouseLoc toPage:page];  
    
    
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

- (void)dragWithEvent:(NSEvent *)theEvent {
	NSPoint initialLocation = [theEvent locationInWindow];
	NSRect visibleRect = [[self documentView] visibleRect];
	BOOL keepGoing = YES;
	
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
				if ([self isFlipped])
					yDelta = -yDelta;
				
				newVisibleRect = NSOffsetRect (visibleRect, xDelta, yDelta);
				[[self documentView] scrollRectToVisible: newVisibleRect];
			}
				break;
				
			case NSLeftMouseUp:
				keepGoing = NO;
				break;
				
			default:
				/* Ignore any other kind of event. */
				break;
		} // end of switch (event type)
	} // end of mouse-tracking loop
}

#define MAG_RECT_1 NSMakeRect(-150.0, -100.0, 300.0, 200.0)
#define MAG_RECT_2 NSMakeRect(-300.0, -200.0, 600.0, 400.0)

- (void)magnifyWithEvent:(NSEvent *)theEvent {
	NSPoint mouseLoc = [theEvent locationInWindow];
	NSRect originalBounds = [[self documentView] bounds];
    NSRect visibleRect = [self convertRect:[self visibleRect] toView: nil];
    NSRect magBounds, magRect;
	float magScale;
    BOOL cursorVisible = YES;
	int currentLevel, originalLevel = [theEvent clickCount]; // this should be at least 1
	BOOL postNote = [[self documentView] postsBoundsChangedNotifications];
    
	[[self documentView] setPostsBoundsChangedNotifications: NO];
	
	[[self window] discardCachedImage]; // make sure not to use the cached image
	
	while ([theEvent type] != NSLeftMouseUp) {
        
        // set up the currentLevel and magScale
        if ([theEvent type] == NSLeftMouseDown || [theEvent type] == NSFlagsChanged) {	
            unsigned modifierFlags = [theEvent modifierFlags];
            currentLevel = originalLevel + ((modifierFlags & NSAlternateKeyMask) ? 1 : 0);
            if (currentLevel > 2) {
                [[self window] restoreCachedImage];
                [[self window] cacheImageInRect:visibleRect];
            }
            if (modifierFlags & NSCommandKeyMask)
                magScale = 4.0;
            else if (modifierFlags & NSControlKeyMask)
                magScale = 1.5;
            else
                magScale = 2.5; 
            // shrink the image with shift key -- can be very slow
            if ((modifierFlags & NSShiftKeyMask) == 0)
                magScale = 1.0 / magScale;
            [self flagsChanged:theEvent]; // update the cursor
        }
        
        // get Mouse location and check if it is with the view's rect
        if ([theEvent type] == NSLeftMouseDragged)
            mouseLoc = [theEvent locationInWindow];
        
        if ([self mouse:mouseLoc inRect:visibleRect]) {
            if (cursorVisible) {
                [NSCursor hide];
                cursorVisible = NO;
            }
            // define rect for magnification in window coordinate
            if (currentLevel > 2) { 
                magRect = visibleRect;
            } else {
                magRect = currentLevel == 2 ? MAG_RECT_2 : MAG_RECT_1;
                magRect.origin.x += mouseLoc.x;
                magRect.origin.y += mouseLoc.y;
                // restore the cached image in order to clear the rect
                [[self window] restoreCachedImage];
                [[self window] cacheImageInRect:  
                    NSIntersectionRect(NSInsetRect(magRect, -2.0, -2.0), [[self superview] convertRect:[[self superview] bounds] toView:nil])];
            }
            
            // resize bounds around mouseLoc
            magBounds.origin = [[self documentView] convertPoint:mouseLoc fromView:nil];
            magBounds = NSMakeRect(magBounds.origin.x + magScale * (originalBounds.origin.x - magBounds.origin.x), 
                                   magBounds.origin.y + magScale * (originalBounds.origin.y - magBounds.origin.y), 
                                   magScale * NSWidth(originalBounds), magScale * NSHeight(originalBounds));
            
            [[self documentView] setBounds: magBounds];
            [self displayRect: NSInsetRect([self convertRect:magRect fromView:nil], 1.0, 1.0)]; // this flushes the buffer
            [[self documentView] setBounds: originalBounds];
            
        } else { // mouse is not in the rect
            // show cursor 
            if (cursorVisible == NO) {
                [NSCursor unhide];
                cursorVisible = YES;
            }
            // restore the cached image in order to clear the rect
            [[self window] restoreCachedImage];
            // autoscroll
            if ([theEvent type] == NSLeftMouseDragged)
                [[self documentView] autoscroll: theEvent];
            if (currentLevel >= 3)
                [[self window] cacheImageInRect:magRect];
            else
                [[self window] discardCachedImage];
        }
        theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSFlagsChangedMask];
	}
	
	[[self window] restoreCachedImage];
	[[self window] flushWindow];
	[NSCursor unhide];
	[[self documentView] setPostsBoundsChangedNotifications:postNote];
	[self flagsChanged:theEvent]; // update cursor
}

@end
