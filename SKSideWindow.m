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
#define WINDOW_OFFSET           2.0
#define CORNER_RADIUS           7.0
#define CONTENT_INSET           7.0
#define WINDOW_MIN_WIDTH        14.0
#define RESIZE_HANDLE_WIDTH     7.0
#define RESIZE_HANDLE_HEIGHT    20.0


@implementation SKSideWindow

- (id)initWithMainController:(SKMainWindowController *)aController {
    NSScreen *screen = [[aController window] screen];
    NSRect contentRect = [screen frame];
    contentRect.size.width = DEFAULT_WINDOW_WIDTH;
    contentRect.origin.x -= DEFAULT_WINDOW_WIDTH - WINDOW_OFFSET;
    if (self = [super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO screen:screen]) {
        controller = aController;
        SKSideWindowContentView *contentView = [[[SKSideWindowContentView alloc] init] autorelease];
        [self setContentView:contentView];
        [contentView trackMouseOvers];
		[self setBackgroundColor:[NSColor clearColor]];
		[self setOpaque:NO];
		[self setHasShadow:YES];
        [self setDisplaysWhenScreenProfileChanges:YES];
        [self setReleasedWhenClosed:NO];
        [self setLevel:[[aController window] level]];
    }
    return self;
}

- (BOOL)canBecomeMainWindow { return NO; }

- (BOOL)canBecomeKeyWindow { return YES; }

- (void)moveToScreen:(NSScreen *)screen {
    NSRect screenFrame = [screen frame];
    NSRect frame = [self frame];
    frame.size.height = NSHeight(screenFrame);
    frame.origin.x = NSMinX(screenFrame) - NSWidth(frame) + WINDOW_OFFSET;
    [self setFrame:frame display:NO];
}

- (void)orderOut:(id)sender {
    [[self parentWindow] removeChildWindow:self];
    [super orderOut:sender];
}

- (void)slideOut {
    state = NSDrawerClosingState;
    NSRect screenFrame = [[self screen] frame];
    NSRect frame = [self frame];
    frame.origin.x = NSMinX(screenFrame) - NSWidth(frame) + WINDOW_OFFSET;
    [self setFrame:frame display:YES animate:YES];
    [[self parentWindow] makeKeyAndOrderFront:self];
    state = NSDrawerClosedState;
}

- (void)slideIn {
    state = NSDrawerOpeningState;
    NSRect screenFrame = [[self screen] frame];
    NSRect frame = [self frame];
    frame.origin.x = NSMinX(screenFrame) - CONTENT_INSET;
    [self setFrame:frame display:YES animate:YES];
    state = NSDrawerOpenState;
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

- (int)state {
    return state;
}

@end


@implementation SKSideWindowContentView

- (NSRect)resizeHandleRect {
    NSRect rect = [self bounds];
    return NSMakeRect(NSMaxX(rect) - 0.5 * (CONTENT_INSET + RESIZE_HANDLE_WIDTH), NSMidY(rect) - 0.5 * RESIZE_HANDLE_HEIGHT, RESIZE_HANDLE_WIDTH, RESIZE_HANDLE_HEIGHT);
}

// @@ FIXME: we might do some nicer drawing
- (void)drawRect:(NSRect)aRect {
    NSRect rect = [self bounds];
    NSPoint startPoint, endPoint;
    
    [NSGraphicsContext saveGraphicsState];
    
    [[NSColor colorWithDeviceWhite:0.12549 alpha:1.0] set];
    [NSBezierPath fillRoundRectInRect:rect radius:CORNER_RADIUS];
    
    rect = [self resizeHandleRect];
    startPoint = NSMakePoint(floorf(NSMidX(rect)) - 0.5, NSMinY(rect));
    endPoint = NSMakePoint(startPoint.x, NSMaxY(rect));
    [NSBezierPath setDefaultLineWidth:1.0];
    [[NSColor colorWithDeviceWhite:0.3 alpha:1.0] set];
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
		theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSMouseEnteredMask | NSMouseExitedMask];
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
    [(SKSideWindow *)[self window] slideIn];
}

- (void)mouseExited:(NSEvent *)theEvent {
    [(SKSideWindow *)[self window] slideOut];
}

@end
