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

#define WINDOW_WIDTH            300.0
#define WINDOW_OFFSET           2.0
#define CORNER_RADIUS           10.0
#define CONTENT_INSET           10.0
#define WINDOW_MIN_WIDTH        20.0
#define RESIZE_HANDLE_WIDTH     8.0
#define RESIZE_HANDLE_HEIGHT    20.0


@implementation SKSideWindow

- (id)initWithMainController:(SKMainWindowController *)aController {
    NSScreen *screen = [[aController window] screen];
    NSRect contentRect = [screen frame];
    contentRect.size.width = WINDOW_WIDTH;
    contentRect.origin.x -= WINDOW_WIDTH - WINDOW_OFFSET;
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
    NSRect screenFrame = [[self screen] frame];
    NSRect frame = [self frame];
    frame.origin.x = NSMinX(screenFrame) - NSWidth(frame) + WINDOW_OFFSET;
    [self setFrame:frame display:YES animate:YES];
    [[self parentWindow] makeKeyAndOrderFront:self];
}

- (void)slideIn {
    NSRect screenFrame = [[self screen] frame];
    NSRect frame = [self frame];
    frame.origin.x = NSMinX(screenFrame) - CONTENT_INSET;
    [self setFrame:frame display:YES animate:YES];
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

@end


@implementation SKSideWindowContentView

- (NSRect)resizeHandleRect {
    NSRect rect = [self bounds];
    return NSMakeRect(NSMaxX(rect) - 0.5 * (CONTENT_INSET + RESIZE_HANDLE_WIDTH), NSMidY(rect) - 0.5 * RESIZE_HANDLE_HEIGHT, RESIZE_HANDLE_WIDTH, RESIZE_HANDLE_HEIGHT);
}

// @@ FIXME: we might do some nicer drawing
- (void)drawRect:(NSRect)aRect {
    NSRect rect = [self bounds];
    [[NSColor windowBackgroundColor] set];
    [NSBezierPath fillRoundRectInRect:rect radius:CORNER_RADIUS];
    
    [[NSColor grayColor] set];
    rect = NSInsetRect([self resizeHandleRect], 0.5 * RESIZE_HANDLE_WIDTH - 1.0 , 0.0);
    rect.origin.x -= 2.0;
    NSRectFill(rect);
    rect.origin.x += 4.0;
    NSRectFill(rect);
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
    if (NSPointInRect(mouseLoc, resizeHandleRect))
        [self resizeWithEvent:theEvent];
    else
        [super mouseDown:theEvent];
}

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
