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

static NSRect RectPlusScale (NSRect aRect, float scale)
{
	float maxX;
	float maxY;
	NSPoint origin;
	
	// Determine edges.
	maxX = ceilf(aRect.origin.x + aRect.size.width) + scale;
	maxY = ceilf(aRect.origin.y + aRect.size.height) + scale;
	origin.x = floorf(aRect.origin.x) - scale;
	origin.y = floorf(aRect.origin.y) - scale;
	
	return NSMakeRect(origin.x, origin.y, maxX - origin.x, maxY - origin.y);
}

static NSPanel *PDFHoverPanel = nil;
static PDFView *PDFHoverPDFView = nil;

@interface SKPDFView (Private)

- (NSRect)_hoverWindowRectFittingScreenFromRect:(NSRect)rect;
- (void)endAnnotationEdit;

@end

@implementation SKPDFView

- (id)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        toolMode = SKTextToolMode;
        [[self window] setAcceptsMouseMovedEvents:YES];
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

#pragma mark Drawing

- (void)drawPage:(PDFPage *)pdfPage {
	// Let PDFView do most of the hard work.
	[super drawPage: pdfPage];
	
    NSArray *allAnnotations = [pdfPage annotations];
    
    if (allAnnotations) {
        unsigned int i, count = [allAnnotations count];
        BOOL foundActive = NO;
        
        [self transformContextForPage:pdfPage];
        
        for (i = 0; i < count; i++)
        {
            PDFAnnotation *annotation;
            
            annotation = [allAnnotations objectAtIndex: i];
            if ([[annotation type] isEqualToString:@"FreeText"] || [[annotation type] isEqualToString:@"Text"] || [[annotation type] isEqualToString:@"Circle"]) {
                if (annotation == activeAnnotation) {
                    foundActive = YES;
                } else if ([[annotation type] isEqualToString:@"FreeText"]) {
                    NSRect bounds = [annotation bounds];
                    NSBezierPath *path = [NSBezierPath bezierPathWithRect:NSInsetRect(NSIntegralRect(bounds), 0.5, 0.5)];
                    [path setLineWidth:1.0];
                    [[NSColor grayColor] set];
                    [path stroke];
                }
            }
        }
        
        // Draw active annotation last so it is not "painted" over.
        if (foundActive) {
            NSRect bounds = [activeAnnotation bounds];
            NSBezierPath *path = [NSBezierPath bezierPathWithRect:NSInsetRect(NSIntegralRect(bounds), 0.5, 0.5)];
            [path setLineWidth:1.0];
            [[NSColor redColor] set];
            [path stroke];
            
            // Draw resize handle.
            if ([[activeAnnotation type] isEqualToString:@"Text"] == NO)
                NSRectFill(NSIntegralRect([self resizeThumbForRect:bounds rotation:[pdfPage rotation]]));
        }
    }
}

- (void)transformContextForPage:(PDFPage *)page
{
	NSAffineTransform *transform = [NSAffineTransform transform];
	NSRect boxRect = [page boundsForBox: [self displayBox]];
	
	[transform translateXBy:-boxRect.origin.x yBy:-boxRect.origin.y];
	[transform concat];
}

- (NSRect)resizeThumbForRect:(NSRect) rect rotation:(int)rotation
{
	NSRect thumb = rect;
    float size = 8.0;
    
    thumb.size = NSMakeSize(size, size);
	
	// Use rotation to determine thumb origin.
	switch (rotation) {
		case 0:
            thumb.origin.x += NSWidth(rect) - NSWidth(thumb);
            break;
		case 90:
            thumb.origin.x += NSWidth(rect) - NSWidth(thumb);
            thumb.origin.y += NSHeight(rect) - NSHeight(thumb);
            break;
		case 180:
            thumb.origin.y += NSHeight(rect) - NSHeight(thumb);
            break;
	}
	
	return thumb;
}

- (void)setNeedsDisplayForAnnotion:(PDFAnnotation *)annotation page:(PDFPage *)page {
    [self setNeedsDisplayInRect:RectPlusScale([self convertRect:[annotation bounds] fromPage:page], [self scaleFactor])];
}

#pragma mark Accessors

- (SKToolMode)toolMode {
    return toolMode;
}

- (void)setToolMode:(SKToolMode)newToolMode {
    if (toolMode != newToolMode) {
        if (toolMode == SKAnnotateToolMode && activeAnnotation) {
            if (editAnnotation)
                [self endAnnotationEdit];
            [self setActiveAnnotation:nil];
        }
    
        toolMode = newToolMode;
        [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewToolModeChangedNotification object:self];
        // hack to make sure we update the cursor
        [[self window] makeFirstResponder:self];
    }
}

- (PDFAnnotation *)activeAnnotation {
	return activeAnnotation;
}

- (void)setActiveAnnotation:(PDFAnnotation *)newAnnotation {
	BOOL changed = newAnnotation != activeAnnotation;
	
	// Will need to redraw old active anotation.
	if (activeAnnotation != nil)
		[self setNeedsDisplayForAnnotion:activeAnnotation page:[activeAnnotation page]];
	
	// Assign.
	if (newAnnotation) {
		activeAnnotation = newAnnotation;
		activePage = [newAnnotation page];
		
		// Force redisplay.
		[self setNeedsDisplayForAnnotion:activeAnnotation page:activePage];
	} else {
		activeAnnotation = nil;
		activePage = nil;
	}
	
	if (changed)
		[[NSNotificationCenter defaultCenter] postNotificationName:@"SKPDFViewActiveAnnotationDidChange" object:self userInfo:nil];
}

#pragma mark Actions

- (void)delete:(id)sender
{
	if (activeAnnotation != nil) {
		PDFAnnotation *wasAnnotation = activeAnnotation;
        
        if (editAnnotation)
            [self endAnnotationEdit];
		[self setActiveAnnotation:nil];
		[[wasAnnotation page] removeAnnotation:wasAnnotation];
	}
}

#pragma mark Event Handling

- (void)keyDown:(NSEvent *)theEvent
{
	unichar character = [[theEvent charactersIgnoringModifiers] characterAtIndex: 0];
	
	if ((character == NSDeleteCharacter) || (character == NSDeleteFunctionKey))
		[self delete:self];
	else
		[super keyDown:theEvent];
}

- (void)mouseDown:(NSEvent *)theEvent{
    [self cleanupPDFHoverView];
    
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
            if ([[self document] isLocked])
                [super mouseDown:theEvent];
            else 
                [self selectAnnotationWithEvent:theEvent];
            break;
    }
}

- (void)mouseUp:(NSEvent *)theEvent{
    switch (toolMode) {
        case SKMoveToolMode:
            [NSCursor pop];
            break;
        case SKTextToolMode:
        case SKMagnifyToolMode:
        case SKPopUpToolMode:
            [super mouseUp:theEvent];
            break;
        case SKAnnotateToolMode:
            //[self annotateWithEvent:theEvent];
            dragging = NO;
            if (mouseDownInAnnotation)
                mouseDownInAnnotation = NO;
            else
                [super mouseUp:theEvent];
            break;
    }
}

- (void)mouseDragged:(NSEvent *)theEvent {
    switch (toolMode) {
        case SKMoveToolMode:
            [self dragWithEvent:theEvent];	
            // ??? PDFView's delayed layout seems to reset the cursor to an arrow
            [self performSelector:@selector(mouseMoved:) withObject:theEvent afterDelay:0];
            break;
        case SKTextToolMode:
        case SKMagnifyToolMode:
        case SKPopUpToolMode:
            [super mouseDragged:theEvent];
            break;
        case SKAnnotateToolMode:
            if (mouseDownInAnnotation)
                [self dragAnnotationWithEvent:theEvent];
            else
                [super mouseDragged:theEvent];
            break;
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

- (PDFDestination *)destinationForEvent:(NSEvent *)theEvent isLink:(BOOL *)isLink {
    NSPoint windowMouseLoc = [theEvent locationInWindow];
    
    NSPoint viewMouseLoc = [self convertPoint:windowMouseLoc fromView:nil];
    PDFPage *page = [self pageForPoint:viewMouseLoc nearest:YES];
    NSPoint pageSpaceMouseLoc = [self convertPoint:viewMouseLoc toPage:page];  
    PDFDestination *dest = [[[PDFDestination alloc] initWithPage:page atPoint:pageSpaceMouseLoc] autorelease];
    BOOL link = NO;
    
    if (([self areaOfInterestForMouse: theEvent] &  kPDFLinkArea) != 0) {
        link = YES;
        PDFAnnotation *ann = [page annotationAtPoint:pageSpaceMouseLoc];
        if (ann != NULL && [[ann destination] page]){
            dest = [ann destination];
        }
    }
    
    if (isLink) *isLink = link;
    return dest;
}

- (void)mouseMoved:(NSEvent *)event {
    
    // we receive this message whenever we are first responder, so check the location
    if (toolMode == SKTextToolMode) {
        [super mouseMoved:event];
    } else {
        [[self cursorForMouseMovedEvent:event] set];
    }
    
    [self showHoverViewWithEvent:event];
    
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


- (void)showHoverViewWithEvent:(NSEvent *)theEvent{
    BOOL isLink = NO;
    PDFDestination *dest = [self destinationForEvent:theEvent isLink:&isLink];
    
    if (isLink) {
        [self showPDFHoverWindowWithDestination:dest atPoint:[theEvent locationInWindow]];
    }else{
        [self cleanupPDFHoverView];
    }
}


- (void)showPDFHoverWindowWithDestination:(PDFDestination *)dest atPoint:(NSPoint)point{

    NSPoint locationInScreenCoordinates = [[self window] convertBaseToScreen:point];
    NSRect contentRect = NSMakeRect(locationInScreenCoordinates.x,
                                    locationInScreenCoordinates.y + 15,
                                    // FIXME: magic number 15 ought to be calculated from the line height of the current line?
                                    400, 50);
    
    contentRect = [self _hoverWindowRectFittingScreenFromRect:contentRect];
    
    if(!PDFHoverPanel){
        PDFHoverPanel = [[NSPanel alloc] initWithContentRect:contentRect
                                                   styleMask:NSBorderlessWindowMask
                                                     backing:NSBackingStoreBuffered
                                                       defer:NO];
        	                [PDFHoverPanel setHidesOnDeactivate:NO];
        	                //[PDFHoverPanel setIgnoresMouseEvents:YES];
        	                [PDFHoverPanel setBackgroundColor:[NSColor whiteColor]];
        	                [PDFHoverPanel setHasShadow:YES];
                            [PDFHoverPanel setLevel:NSStatusWindowLevel];
                            [PDFHoverPanel orderFrontRegardless];
    }
    
    if(!PDFHoverPDFView){
        PDFHoverPDFView = [[PDFView alloc] initWithFrame:NSMakeRect(0,0, 400, 50)];
        [[PDFHoverPanel contentView] addSubview:PDFHoverPDFView];
    }
    
    [PDFHoverPDFView setDocument:[self document]];
    
    NSScrollView *scrollView = [[PDFHoverPDFView documentView] enclosingScrollView];
    [scrollView setHasVerticalScroller:NO];
    [scrollView setHasHorizontalScroller:NO];
    
    [PDFHoverPDFView performSelector:@selector(goToDestination:)
                          withObject:dest
                          afterDelay:0.01];

}


- (void)cleanupPDFHoverView{
    if(PDFHoverPanel){
        [PDFHoverPanel orderOut:self];
        [PDFHoverPanel release]; 
    }
    PDFHoverPanel = nil;
    if(PDFHoverPDFView) [PDFHoverPDFView release]; PDFHoverPDFView = nil;
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
        [navWindow setLevel:[[self window] level]];
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
    PDFDestination *dest = [self destinationForEvent:theEvent isLink:NULL];
    
    [controller showSubWindowAtPageNumber:[[self document] indexForPage:[dest page]] location:[dest point]];        
}

- (void)annotateWithEvent:(NSEvent *)theEvent {
    SKMainWindowController* controller = [[self window] windowController];
    PDFDestination *dest = [self destinationForEvent:theEvent isLink:NULL];

    [controller createNewNoteAtPageNumber:[[self document] indexForPage:[dest page]] location:[dest point]];        
}

- (void)selectAnnotationWithEvent:(NSEvent *)theEvent {
    PDFAnnotation *newActiveAnnotation = NULL;
    PDFAnnotation *wasActiveAnnotation;
    NSArray *annotations;
    int numAnnotations, i;
    NSPoint pagePoint;
    BOOL changed;
    
    // Mouse in display view coordinates.
    mouseDownLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    
    // Page we're on.
    activePage = [self pageForPoint:mouseDownLoc nearest:YES];
    
    // Get mouse in "page space".
    pagePoint = [self convertPoint:mouseDownLoc toPage:activePage];
    
    // Hit test for annotation.
    annotations = [activePage annotations];
    numAnnotations = [annotations count];
    
    for (i = 0; i < numAnnotations; i++) {
        NSRect annotationBounds;
        
        // Hit test annotation.
        annotationBounds = [[annotations objectAtIndex:i] bounds];
        if (NSPointInRect(pagePoint, annotationBounds)) {
            PDFAnnotation *annotationHit = [annotations objectAtIndex:i];
            if ([[annotationHit type] isEqualToString:@"FreeText"] || [[annotationHit type] isEqualToString:@"Text"] || [[annotationHit type] isEqualToString:@"Circle"]) {
                // We count this one.
                newActiveAnnotation = annotationHit;
                
                // Remember click point relative to annotation origin.
                clickDelta.x = pagePoint.x - annotationBounds.origin.x;
                clickDelta.y = pagePoint.y - annotationBounds.origin.y;
                break;
            }
        }
    }
    
    // Flag indicating if activeAnnotation will change. 
    changed = (activeAnnotation != newActiveAnnotation);
    
    // Deselect old annotation when appropriate.
    if (activeAnnotation && changed)
		[self setNeedsDisplayForAnnotion:activeAnnotation page:[activeAnnotation page]];
    
    if (changed) {
        if (editAnnotation)
            [self endAnnotationEdit];
        
        // Assign.
        wasActiveAnnotation = activeAnnotation;
        activeAnnotation = (PDFAnnotationFreeText *)newActiveAnnotation;
        
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:2];
        if (wasActiveAnnotation)
            [userInfo setObject:wasActiveAnnotation forKey:@"wasActiveAnnotation"];
        if (activeAnnotation)
            [userInfo setObject:activeAnnotation forKey:@"activeAnnotation"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SKPDFViewActiveAnnotationDidChange" object:self userInfo:userInfo];
    }
    
    if (activeAnnotation == nil) {
        [super mouseDown:theEvent];
    } else if ([theEvent clickCount] == 2 && ([[activeAnnotation type] isEqualToString:@"FreeText"] || [[activeAnnotation type] isEqualToString:@"Text"])) {
        // probably we should use the note window for Text annotations
        NSRect editBounds = [activeAnnotation bounds];
        if ([[activeAnnotation type] isEqualToString:@"Text"]) {
            NSRect pageBounds = [[activeAnnotation page] boundsForBox:[self displayBox]];
            editBounds = NSInsetRect(editBounds, -120.0, -120.0);
            if (NSMaxX(editBounds) > NSMaxX(pageBounds))
                editBounds.origin.x = NSMaxX(pageBounds) - NSWidth(editBounds);
            if (NSMinX(editBounds) < NSMinX(pageBounds))
                editBounds.origin.x = NSMinX(pageBounds);
            if (NSMaxY(editBounds) > NSMaxY(pageBounds))
                editBounds.origin.y = NSMaxY(pageBounds) - NSHeight(editBounds);
            if (NSMinY(editBounds) < NSMinY(pageBounds))
                editBounds.origin.y = NSMinY(pageBounds);
        }
        editAnnotation = [[[PDFAnnotationTextWidget alloc] initWithBounds:editBounds] autorelease];
        [editAnnotation setStringValue:[activeAnnotation contents]];
        if ([activeAnnotation respondsToSelector:@selector(font)])
            [editAnnotation setFont:[(PDFAnnotationFreeText *)activeAnnotation font]];
        [editAnnotation setColor:[activeAnnotation color]];
        [[activeAnnotation page] addAnnotation:editAnnotation];
        
        // Start editing
        [super mouseDown:theEvent];
        
    } else { 
        // Old (current) annotation location.
        wasBounds = [activeAnnotation bounds];
        
        // Force redisplay.
		[self setNeedsDisplayForAnnotion:activeAnnotation page:activePage];
        mouseDownInAnnotation = YES;
        
        // Hit-test for resize box.
        resizing = [[activeAnnotation type] isEqualToString:@"Text"] == NO && NSPointInRect(pagePoint, [self resizeThumbForRect:wasBounds rotation:[activePage rotation]]);
    }
}

- (void)dragAnnotationWithEvent:(NSEvent *)theEvent {
    NSRect newBounds;
    NSRect currentBounds = [activeAnnotation bounds];
    NSRect dirtyRect;
    NSPoint mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    NSPoint endPt = [self convertPoint:mouseLoc toPage:activePage];
    
    if (resizing) {
        NSPoint startPoint = [self convertPoint:mouseDownLoc toPage:activePage];
        NSPoint relPoint = NSMakePoint(endPt.x - startPoint.x, endPt.y - startPoint.y);
        newBounds = wasBounds;
        
        // Resize the annotation.
        switch ([activePage rotation]) {
            case 0:
                newBounds.origin.y += relPoint.y;
                newBounds.size.width += relPoint.x;
                newBounds.size.height -= relPoint.y;
                break;
            case 90:
                newBounds.size.width += relPoint.x;
                newBounds.size.height += relPoint.y;
                break;
            case 180:
                newBounds.origin.x += relPoint.x;
                newBounds.size.width -= relPoint.x;
                newBounds.size.height += relPoint.y;
                break;
            case 270:
                newBounds.origin.x += relPoint.x;
                newBounds.origin.y += relPoint.y;
                newBounds.size.width -= relPoint.x;
                newBounds.size.height -= relPoint.y;
                break;
        }
        
        // Keep integer.
        newBounds = NSIntegralRect(newBounds);
    } else {
        // Move annotation.
        // Hit test, is mouse still within page bounds?
        if (NSPointInRect([self convertPoint:mouseLoc toPage:activePage], [activePage boundsForBox:[self displayBox]])) {
            // Calculate new bounds for annotation.
            newBounds = currentBounds;
            newBounds.origin.x = roundf(endPt.x - clickDelta.x);
            newBounds.origin.y = roundf(endPt.y - clickDelta.y);
        } else {
            // Snap back to initial location.
            newBounds = wasBounds;
        }
    }
    
    // Change annotation's location.
    [activeAnnotation setBounds:newBounds];
    
    // Force redraw.
    dirtyRect = NSUnionRect(currentBounds, newBounds);
    [self setNeedsDisplayInRect:RectPlusScale([self convertRect:dirtyRect fromPage:activePage], [self scaleFactor])];
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
    NSScrollView *scrollView = [[self documentView] enclosingScrollView];
    NSView *documentView = [scrollView documentView];
    NSView *clipView = [scrollView contentView];
	NSRect originalBounds = [documentView bounds];
    NSRect visibleRect = [clipView convertRect:[clipView visibleRect] toView: nil];
    NSRect magBounds, magRect, outlineRect;
	float magScale = 1.0;
    BOOL mouseInside = NO;
	int currentLevel = 0;
    int originalLevel = [theEvent clickCount]; // this should be at least 1
	BOOL postNotification = [documentView postsBoundsChangedNotifications];
    NSBezierPath *path;
    
	[documentView setPostsBoundsChangedNotifications: NO];
	
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
            magScale = (modifierFlags & NSCommandKeyMask) ? 4.0 : (modifierFlags & NSControlKeyMask) ? 1.5 : 2.5;
            if ((modifierFlags & NSShiftKeyMask) == 0)
                magScale = 1.0 / magScale;
            [self flagsChanged:theEvent]; // update the cursor
        }
        
        // get Mouse location and check if it is with the view's rect
        if ([theEvent type] == NSLeftMouseDragged)
            mouseLoc = [theEvent locationInWindow];
        
        if ([self mouse:mouseLoc inRect:visibleRect]) {
            if (mouseInside == NO) {
                mouseInside = YES;
                [NSCursor hide];
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
                [[self window] cacheImageInRect:NSIntersectionRect(NSInsetRect(magRect, -2.0, -2.0), visibleRect)];
            }
            
            // resize bounds around mouseLoc
            magBounds.origin = [documentView convertPoint:mouseLoc fromView:nil];
            magBounds = NSMakeRect(magBounds.origin.x + magScale * (originalBounds.origin.x - magBounds.origin.x), 
                                   magBounds.origin.y + magScale * (originalBounds.origin.y - magBounds.origin.y), 
                                   magScale * NSWidth(originalBounds), magScale * NSHeight(originalBounds));
            
            [documentView setBounds:magBounds];
            [self displayRect:[self convertRect:NSInsetRect(magRect, 1.0, 1.0) fromView:nil]]; // this flushes the buffer
            [documentView setBounds:originalBounds];
            
            [clipView lockFocus];
            [[NSGraphicsContext currentContext] saveGraphicsState];
            outlineRect = NSInsetRect([clipView convertRect:magRect fromView:nil], 0.5, 0.5);
            path = [NSBezierPath bezierPathWithRect:outlineRect];
            [path setLineWidth:1.0];
            [[NSColor blackColor] set];
            [path stroke];
            [[NSGraphicsContext currentContext] restoreGraphicsState];
            [clipView unlockFocus];
			[[self window] flushWindow];
            
        } else { // mouse is not in the rect
            // show cursor 
            if (mouseInside == YES) {
                mouseInside = NO;
                [NSCursor unhide];
                // restore the cached image in order to clear the rect
                [[self window] restoreCachedImage];
                [[self window] flushWindowIfNeeded];
            }
            if ([theEvent type] == NSLeftMouseDragged)
                [documentView autoscroll:theEvent];
            if (currentLevel > 2)
                [[self window] cacheImageInRect:visibleRect];
            else
                [[self window] discardCachedImage];
        }
        theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSFlagsChangedMask];
	}
	
	[[self window] restoreCachedImage];
	[[self window] flushWindow];
	[NSCursor unhide];
	[documentView setPostsBoundsChangedNotifications:postNotification];
	[self flagsChanged:theEvent]; // update cursor
}

@end

@implementation SKPDFView (Private)

- (NSRect)_hoverWindowRectFittingScreenFromRect:(NSRect)rect{
    
    NSRect screenRect;
    screenRect = [[NSScreen mainScreen] visibleFrame];
    NSPoint hoverWindowOrigin = rect.origin;
    
    if (rect.origin.x > 
        (screenRect.origin.x + screenRect.size.width - rect.size.width)) {
        hoverWindowOrigin.x = rect.origin.x - 2 - rect.size.width;
    } else {
        hoverWindowOrigin.x = rect.origin.x;
    }
    
    if (rect.origin.y > (screenRect.origin.y + screenRect.size.height - rect.size.height)) {
        hoverWindowOrigin.y = screenRect.origin.y + screenRect.size.height - rect.size.height;
    } else {
        hoverWindowOrigin.y = rect.origin.y + 2;
    }
    
    if (hoverWindowOrigin.y < 0) hoverWindowOrigin.y = 0;
    
    return NSMakeRect(hoverWindowOrigin.x, hoverWindowOrigin.y,
                      rect.size.width, rect.size.height);
}

- (void)endAnnotationEdit {
    if (editAnnotation) {
        [activeAnnotation setContents:[editAnnotation stringValue]];
        [[editAnnotation page] removeAnnotation:editAnnotation];
        editAnnotation = nil;
    }
}

@end
