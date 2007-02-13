//
//  SKSideWindow.m
//  Skim
//
//  Created by Christiaan Hofman on 8/2/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "SKSideWindow.h"
#import "SKMainWindowController.h"
#import "NSBezierPath_BDSKExtensions.h"

#define DEFAULT_WINDOW_WIDTH    300.0
#define WINDOW_INSET            1.0
#define WINDOW_OFFSET           2.0
#define CORNER_RADIUS           8.0
#define CONTENT_INSET           8.0
#define WINDOW_MIN_WIDTH        14.0
#define RESIZE_HANDLE_WIDTH     8.0
#define RESIZE_HANDLE_HEIGHT    20.0


@implementation SKSideWindow

- (id)initWithMainController:(SKMainWindowController *)aController {
    return [self initWithMainController:aController edge:NSMinXEdge];
}

- (id)initWithMainController:(SKMainWindowController *)aController edge:(NSRectEdge)anEdge {
    NSScreen *screen = [[aController window] screen];
    NSRect contentRect = [screen frame];
    if (anEdge == NSMaxXEdge)
        contentRect.origin.x = NSMaxX(contentRect) - WINDOW_OFFSET;
    else
        contentRect.origin.x -= DEFAULT_WINDOW_WIDTH - WINDOW_OFFSET;
    contentRect.size.width = DEFAULT_WINDOW_WIDTH;
    contentRect = NSInsetRect(contentRect, 0.0, WINDOW_INSET);
    if (self = [super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask | NSUnifiedTitleAndToolbarWindowMask backing:NSBackingStoreBuffered defer:NO screen:screen]) {
        controller = aController;
        edge = anEdge;
        SKSideWindowContentView *contentView = [[[SKSideWindowContentView alloc] init] autorelease];
        [self setContentView:contentView];
        [contentView trackMouseOvers];
		[self setBackgroundColor:[NSColor clearColor]];
		[self setOpaque:NO];
		[self setHasShadow:YES];
        [self setDisplaysWhenScreenProfileChanges:YES];
        [self setReleasedWhenClosed:NO];
        [self setLevel:NSFloatingWindowLevel];
    }
    return self;
}

- (BOOL)canBecomeMainWindow { return NO; }

- (BOOL)canBecomeKeyWindow { return YES; }

- (void)moveToScreen:(NSScreen *)screen {
    NSRect screenFrame = [screen frame];
    NSRect frame = [self frame];
    frame.size.height = NSHeight(screenFrame);
    frame.origin.x = edge == NSMaxXEdge ? NSMaxX(screenFrame) - WINDOW_OFFSET : NSMinX(screenFrame) - NSWidth(frame) + WINDOW_OFFSET;
    frame = NSInsetRect(frame, 0.0, WINDOW_INSET);
    [self setFrame:frame display:NO];
}

- (void)slideOut {
    if (state == NSDrawerOpenState || state == NSDrawerOpeningState) {
        state = NSDrawerClosingState;
        NSRect screenFrame = [[self screen] frame];
        NSRect frame = [self frame];
        frame.origin.x = edge == NSMaxXEdge ? NSMaxX(screenFrame) - WINDOW_OFFSET : NSMinX(screenFrame) - NSWidth(frame) + WINDOW_OFFSET;
        [self setFrame:frame display:YES animate:YES];
        [[controller window] makeKeyAndOrderFront:self];
        state = NSDrawerClosedState;
    }
}

- (void)slideIn {
    if (state == NSDrawerClosedState || state == NSDrawerClosingState) {
        state = NSDrawerOpeningState;
        NSRect screenFrame = [[self screen] frame];
        NSRect frame = [self frame];
        frame.origin.x = edge == NSMaxXEdge ? NSMaxX(screenFrame) - NSWidth(frame) + CONTENT_INSET : NSMinX(screenFrame) - CONTENT_INSET;
        [self setFrame:frame display:YES animate:YES];
        state = NSDrawerOpenState;
    }
}

- (NSView *)mainView {
    NSArray *subviews = [[self contentView] subviews];
    return [subviews count] ? [subviews objectAtIndex:0] : nil;
}

- (void)setMainView:(NSView *)newContentView {
    NSArray *subviews = [[super contentView] subviews];
    NSRect contentRect = NSInsetRect([[self contentView] bounds], CONTENT_INSET, CONTENT_INSET);
    [newContentView setFrame:contentRect];
    if ([subviews count])
        [[self contentView] replaceSubview:[subviews objectAtIndex:0] with:newContentView];
    else
        [[self contentView] addSubview:newContentView];
}

- (NSRectEdge)edge {
    return edge;
}

- (int)state {
    return state;
}

@end


@implementation SKSideWindowContentView

- (NSRect)resizeHandleRect {
    NSRect rect, ignored;
    NSDivideRect([self bounds], &rect, &ignored, CONTENT_INSET, [(SKSideWindow *)[self window] edge] == NSMaxXEdge ? NSMinXEdge : NSMaxXEdge);
    return rect;
}

- (void)drawRect:(NSRect)aRect {
    NSRect ignored, topRect, bottomRect, rect = [self bounds];
    NSPoint startPoint, endPoint;
    
    NSDivideRect(rect, &topRect, &ignored, 2.0 * CORNER_RADIUS, NSMaxYEdge);
    NSDivideRect(rect, &bottomRect, &ignored, 2.0 * CORNER_RADIUS, NSMinYEdge);
    
    [NSGraphicsContext saveGraphicsState];
    
    [[NSColor colorWithDeviceWhite:0.9 alpha:1.0] set];
    [NSBezierPath fillRoundRectInRect:topRect radius:CORNER_RADIUS];
    [[NSColor colorWithDeviceWhite:0.4 alpha:1.0] set];
    [NSBezierPath fillRoundRectInRect:bottomRect radius:CORNER_RADIUS];
    [[NSColor colorWithDeviceWhite:0.8 alpha:1.0] set];
    [NSBezierPath fillRoundRectInRect:NSInsetRect(rect, 0.0, 1.5) radius:CORNER_RADIUS];
    
    rect = [self resizeHandleRect];
    startPoint = NSMakePoint(NSMidX(rect) - 1.5, NSMidY(rect) - 10.0);
    endPoint = NSMakePoint(startPoint.x, startPoint.y + 20.0);
    [NSBezierPath setDefaultLineWidth:1.0];
    [[NSColor colorWithDeviceWhite:0.5 alpha:1.0] set];
    [NSBezierPath strokeLineFromPoint:startPoint toPoint:endPoint];
    startPoint.x += 2.0;
    endPoint.x += 2.0;
    [NSBezierPath strokeLineFromPoint:startPoint toPoint:endPoint];
    [[NSColor colorWithDeviceWhite:0.9 alpha:1.0] set];
    startPoint.x -= 1.0;
    endPoint.x -= 1.0;
    [NSBezierPath strokeLineFromPoint:startPoint toPoint:endPoint];
    startPoint.x += 2.0;
    endPoint.x += 2.0;
    [NSBezierPath strokeLineFromPoint:startPoint toPoint:endPoint];
    
    [NSGraphicsContext restoreGraphicsState];
}

- (void)resizeWithEvent:(NSEvent *)theEvent {
	NSPoint initialLocation = [theEvent locationInWindow];
	NSRect initialFrame = [[self window] frame];
	BOOL keepGoing = YES;
	
    [self removeTrackingRect:trackingRect];
    
	while (keepGoing) {
		theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask];
		switch ([theEvent type]) {
			case NSLeftMouseDragged:
            {
				NSPoint	newLocation = [theEvent locationInWindow];
                NSRect newFrame = initialFrame;
                
                newFrame.size.width += newLocation.x - initialLocation.x;
                if (NSWidth(newFrame) < WINDOW_MIN_WIDTH)
                    newFrame.size.width = WINDOW_MIN_WIDTH;
                
                [[self window] setFrame:newFrame display:YES];
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
    
    [self trackMouseOvers];
}

- (void)mouseDown:(NSEvent *)theEvent {
	NSPoint mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    NSRect resizeHandleRect = [self resizeHandleRect];
    if (NSPointInRect(mouseLoc, resizeHandleRect) && [(SKSideWindow *)[self window] state] == NSDrawerOpenState)
        [self resizeWithEvent:theEvent];
    else
        [super mouseDown:theEvent];
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent { return YES; }

-(void)resetCursorRects{
    [self discardCursorRects];
    [self addCursorRect:[self resizeHandleRect] cursor:[NSCursor resizeLeftRightCursor]];
}

- (void)trackMouseOvers {
    trackingRect = [self addTrackingRect:[self bounds] owner:self userData:NULL assumeInside:NO];
}

- (void)mouseEntered:(NSEvent *)theEvent {
    if (NSPointInRect([NSEvent mouseLocation], [[self window] frame]))
        [(SKSideWindow *)[self window] slideIn];
}

- (void)mouseExited:(NSEvent *)theEvent {
    //if (NSPointInRect([NSEvent mouseLocation], [[self window] frame]) == NO)
        [(SKSideWindow *)[self window] slideOut];
}

@end
