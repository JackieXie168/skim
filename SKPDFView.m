//
//  SKPDFView.m


//  This code is licensed under a BSD license. Please see the file LICENSE for details.
//
//  Created by Michael McCracken on 12/6/06.
//  Copyright 2006 Michael O. McCracken. All rights reserved.
//

#import "SKPDFView.h"
#import "SKNavigationWindow.h"

NSString *SKPDFViewToolModeChangedNotification = @"SKPDFViewToolModeChangedNotification";

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
	[[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewToolModeChangedNotification object:self];
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
            //[self popUpWithEvent:theEvent];
            [self selectWithEvent:theEvent];
            break;
        case SKAnnotateToolMode:
            [super mouseDown:theEvent];
            break;
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
    
    // in presentation mode only show the navigation window only by moving the mouse to the bottom edge
    BOOL shouldShowNavWindow = hasNavigation && (autohidesCursor == NO || [event locationInWindow].y < 5.0);
    if (autohidesCursor || shouldShowNavWindow) {
        if (shouldShowNavWindow && [navWindow isVisible] == NO) {
            [[self window] addChildWindow:navWindow ordered:NSWindowAbove];
            [navWindow orderFront:self];
        }
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
    if (NSPointInRect([NSEvent mouseLocation], [navWindow frame]))
        return;
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
        if (navWindow == nil) {
            navWindow = [[SKNavigationWindow alloc] initWithPDFView:self];
            [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(handleWindowWillCloseNotification:) 
                                                         name: NSWindowWillCloseNotification object: [self window]];
        } else if ([[self window] screen] != [navWindow screen]) {
            [navWindow moveToScreen:[[self window] screen]];
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
        if (ann != NULL && [[ann destination] page]){
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
            
            // draw marquee
            if (selRectTimer)
                [self updateMarquee:nil];
            
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
	[self cleanupMarquee:NO];
	[self recacheMarquee]; 
}

#define SIZE_WINDOW_H_OFFSET	75
#define SIZE_WINDOW_V_OFFSET	-10
#define SIZE_WINDOW_WIDTH		70
#define SIZE_WINDOW_HEIGHT		20
#define SIZE_WINDOW_DRAW_X		5
#define SIZE_WINDOW_DRAW_Y		3
#define SIZE_WINDOW_HAS_SHADOW	NO

- (void)selectWithEvent:(NSEvent *)theEvent {
    NSPoint mouseLoc, startPoint, currentPoint;
	NSRect bounds, selRectWindow, selRectSuper;
	NSBezierPath *path = [NSBezierPath bezierPath];
	BOOL startFromCenter = NO;
	static int phase = 0;
	float xmin, xmax, ymin, ymax, pattern[] = {3,3};
	
	[path setLineWidth: 0.01];
	mouseLoc = [theEvent locationInWindow];
	startPoint = [[self documentView] convertPoint:mouseLoc fromView:nil];
	[NSEvent startPeriodicEventsAfterDelay:0.0 withPeriod: 0.2];
	[self cleanupMarquee:YES];
	[[self window] discardCachedImage];
	
#ifndef DO_NOT_SHOW_SELECTION_SIZE
	// create a small window displaying the size of selection
	NSRect aRect;
	aRect.origin = [[self window] convertBaseToScreen: mouseLoc];
	aRect.origin.x -= SIZE_WINDOW_H_OFFSET;
	aRect.origin.y += SIZE_WINDOW_V_OFFSET;
	aRect.size = NSMakeSize(SIZE_WINDOW_WIDTH, SIZE_WINDOW_HEIGHT);
	NSPanel *sizeWindow = [[NSPanel alloc] initWithContentRect: aRect 
													 styleMask: NSBorderlessWindowMask | NSUtilityWindowMask 
													   backing: NSBackingStoreBuffered //NSBackingStoreRetained 
														 defer: NO];
	[sizeWindow setOpaque: NO];
	[sizeWindow setHasShadow: SIZE_WINDOW_HAS_SHADOW];
	[sizeWindow orderFront: nil];
	[sizeWindow setFloatingPanel: YES];
#endif
	
	while ([theEvent type] != NSLeftMouseUp) {
        // restore the cached image in order to clear the rect
        [[self window] restoreCachedImage];
        [[self window] flushWindow];
        // get Mouse location and check if it is with the view's rect
        if ([theEvent type] == NSLeftMouseDragged || [theEvent type] == NSLeftMouseDown) {
            mouseLoc = [theEvent locationInWindow];
            // scroll if the mouse is out of visibleRect
            [[self documentView] autoscroll: theEvent];
        }
        // calculate the rect to select
        currentPoint = [[self documentView] convertPoint: mouseLoc fromView:nil];
        selectedRect.size = NSMakeSize(abs(currentPoint.x - startPoint.x), abs(currentPoint.y - startPoint.y));
        if ([theEvent modifierFlags] & NSShiftKeyMask) {
            if (NSWidth(selectedRect) > NSHeight(selectedRect))
                selectedRect.size.height = NSWidth(selectedRect);
            else
                selectedRect.size.width = NSHeight(selectedRect);
        }
        if (currentPoint.x < startPoint.x || startFromCenter)
            selectedRect.origin.x = startPoint.x - NSWidth(selectedRect);
        else
            selectedRect.origin.x = startPoint.x;
        if (currentPoint.y < startPoint.y || startFromCenter)
            selectedRect.origin.y = startPoint.y - NSHeight(selectedRect);
        else
            selectedRect.origin.y = startPoint.y;
        if (startFromCenter) {
            selectedRect.size.width *= 2;
            selectedRect.size.height *= 2;
        }
        // calculate the intersection of selectedRect with bounds 
        // -- we do not want to use NSIntersectionRect 
        // because even if it's empty, we want information on origin and edges
        // in our case, the only way the intersection can be empty is that 
        // one of the edges has length zero.  
        bounds = [[self documentView] bounds];
        xmin = fmax(NSMinX(selectedRect), NSMinX(bounds));
        xmax = fmin(NSMaxX(selectedRect), NSMaxX(bounds));
        ymin = fmax(NSMinY(selectedRect), NSMinY(bounds));
        ymax = fmin(NSMaxY(selectedRect), NSMaxY(bounds));
        selectedRect = NSMakeRect(xmin, ymin, xmax - xmin, ymax - ymin);
        // do not use selectedRect = NSIntersectionRect(selectedRect, [self bounds]);
        selRectWindow = [[self documentView] convertRect: selectedRect toView: nil];
        // cache the window image
        [[self window] cacheImageInRect:NSInsetRect(selRectWindow, -2.0, -2.0)];
        // draw rect frame
        [path removeAllPoints]; // reuse path
                                // in order to draw a clear frame we draw an adjusted rect in clip view
        selRectSuper = [self convertRect:selRectWindow fromView: nil];
        if (NO == NSIsEmptyRect(selRectSuper)) {	// shift the coordinated by a half integer
            selRectSuper = NSInsetRect(NSIntegralRect(selRectSuper), 0.5, 0.5);
            [path appendBezierPathWithRect: selRectSuper];
        } else { // if width or height is zero, we cannot use NSIntegralRect, which returns zero rect, so draw a path by hand
            selRectSuper.origin.x = floor(NSMinX(selRectSuper)) + 0.5;
            selRectSuper.origin.y = floor(NSMinY(selRectSuper)) + 0.5;
            [path appendBezierPathWithPoints: &(selRectSuper.origin) count: 1];
            selRectSuper.origin.x += floor(NSWidth(selRectSuper));
            selRectSuper.origin.y += floor(NSHeight(selRectSuper));
            [path appendBezierPathWithPoints: &(selRectSuper.origin) count: 1];
        }
        [self lockFocus];
        [[NSGraphicsContext currentContext] setShouldAntialias: NO];
        [[NSColor whiteColor] set];
        [path stroke];
        [path setLineDash: pattern count: 2 phase: phase];
        [[NSColor blackColor] set];
        [path stroke];
        phase = (phase + 1) % 6;
        [self unlockFocus];
        // display the image drawn in the buffer
        [[self window] flushWindow];
        
#ifndef DO_NOT_SHOW_SELECTION_SIZE
        
        // update the size window
        // first compute where to show the window
        NSRect contentRect = [[[self window] contentView] bounds];
        xmin = fmax(NSMinX(selRectWindow), NSMinX(contentRect));
        ymin = fmax(NSMinY(selRectWindow), NSMinY(contentRect));
        ymax = fmin(NSMaxY(selRectWindow), NSMaxY(contentRect));
        NSPoint aPoint = NSMakePoint(xmin, 0.5 * (ymin + ymax));
        aPoint = [[self window] convertBaseToScreen: aPoint];
        aPoint.x -= SIZE_WINDOW_H_OFFSET;
        aPoint.y += SIZE_WINDOW_V_OFFSET;
        [sizeWindow setFrameOrigin: aPoint]; // set the position
                                             // do the drawing
        NSString *sizeString = [NSString stringWithFormat: @"%d x %d", (int)floor(NSWidth(selRectWindow)), (int)floor(NSHeight(selRectWindow))];
        NSView *sizeView = [sizeWindow contentView];
        [sizeView lockFocus];
        [[NSColor colorWithCalibratedRed:1.0 green:1.0 blue:0.5 alpha:0.8] set];//change color?
        NSRectFill([sizeView bounds]);
        [sizeString drawAtPoint: NSMakePoint(SIZE_WINDOW_DRAW_X, SIZE_WINDOW_DRAW_Y) withAttributes: [NSDictionary dictionary]];
        [[NSGraphicsContext currentContext] flushGraphics];
        [sizeView unlockFocus];
            
#endif
        
        theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSFlagsChangedMask | NSPeriodicMask];
	}
	
	[NSEvent stopPeriodicEvents];
	if (NSWidth(selectedRect) > 3.0 && NSHeight(selectedRect) > 3.0) {
		selRectTimer = [NSTimer scheduledTimerWithTimeInterval: 0.2 target:self 
													  selector:@selector(updateMarquee:) userInfo:nil repeats:YES];
		oldVisibleRect = [[self documentView] visibleRect];
	} else {
		selRectTimer = nil;
		[[self window] restoreCachedImage];
		[[self window] flushWindow];
		[[self window] discardCachedImage];
	}
	[self flagsChanged: theEvent]; // update cursor
#ifndef DO_NOT_SHOW_SELECTION_SIZE
	[sizeWindow close];
#endif
}

// updates the frame of selected rectangle
- (void)updateMarquee:(NSTimer *)timer {
	static int phase = 0;
	float pattern[2] = {3,3};
	NSView *clipView;
	NSRect selRectSuper, clipBounds;
	NSBezierPath *path;
	
	if ([[self window] isMainWindow] == NO)
        return;
	
    clipView = [[self documentView] superview];
    clipBounds = [clipView bounds];
    selRectSuper = [[self documentView] convertRect:selectedRect toView: clipView];
    selRectSuper = NSInsetRect(NSIntegralRect(selRectSuper), 0.5, 0.5);
    // if the eddges are slightly off the clip view, adjust them.
    if (fabs(NSMinX(clipBounds) - NSMinX(selRectSuper) - 0.5) < 0.5) {
        selRectSuper.origin.x += 1.0;
        selRectSuper.size.width -= 1.0;
    } else if (fabs(NSMaxX(clipBounds) - NSMaxX(selRectSuper) + 0.5) < 0.5) {
        selRectSuper.size.width -= 1.0;
    }
    if (fabs(NSMinY(clipBounds) - NSMinY(selRectSuper) - 0.5) < 0.5) {
        selRectSuper.origin.y += 1.0;
        selRectSuper.size.height -= 1.0;
    } else if (fabs(NSMaxY(clipBounds) - NSMaxY(selRectSuper) + 0.5) < 0.5) {
        selRectSuper.size.height -= 1.0;
    }
    // create a bezier path and draw
    [clipView lockFocus];
    [[NSGraphicsContext currentContext] setShouldAntialias: NO];
    path = [NSBezierPath bezierPathWithRect: selRectSuper];
    [path setLineWidth: 0.01];
    [[NSColor whiteColor] set];
    [path stroke];
    [path setLineDash: pattern count: 2 phase: phase];
    [[NSColor blackColor] set];
    [path stroke];
    [clipView unlockFocus];
    if (timer)
        [[self window] flushWindow];
    phase = (phase + 1) % 6;
}

// erases the frame of selected rectangle and cleans up the cached image
- (void)cleanupMarquee:(BOOL)terminate {
	if (selRectTimer == nil) 
        return;
    
    NSRect tempRect, visRect = [[self documentView] visibleRect];
    if (NSEqualRects(visRect, oldVisibleRect)) {
        [[self window] restoreCachedImage];
        [[self window] flushWindow];
    } else { // the view was moved--do not use the cached image
        [[self window] discardCachedImage];
        tempRect =  [self convertRect: NSInsetRect(NSIntegralRect([[self documentView] convertRect: selectedRect toView: nil]), -2.0, -2.0) 
                             fromView: nil];
        [self displayRect: tempRect];
    }
    oldVisibleRect.size.width = 0.0; // do not use this cache again
    if (terminate) {
        [selRectTimer invalidate]; // this will release the timer
        selRectTimer = nil;
	}
}

// recache the image around selected rectangle for quicker response
- (void)recacheMarquee
{
	if (selRectTimer == nil)
        return;
    [[self window] cacheImageInRect: NSInsetRect([[self documentView] convertRect: selectedRect toView: nil], -2.0, -2.0)];
    oldVisibleRect = [self visibleRect];
}

@end
