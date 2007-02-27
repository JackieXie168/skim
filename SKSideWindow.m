//
//  SKSideWindow.m
//  Skim
//
//  Created by Christiaan Hofman on 2/8/07.
/*
 This software is Copyright (c) 2007
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
        NSRect screenFrame = [[[controller window] screen] frame];
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
        NSRect screenFrame = [[[controller window] screen] frame];
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

- (void)dealloc {
    [timer invalidate];
    [timer release];
    timer = nil;
    [super dealloc];
}

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

- (void)mouseExited:(NSEvent *)theEvent {
    if (timer) {
        [timer invalidate];
        [timer release];
        timer = nil;
    }
    //if (NSPointInRect([NSEvent mouseLocation], [[self window] frame]) == NO)
    [(SKSideWindow *)[self window] slideOut];
}

- (void)slideInWithTimer:(NSTimer *)aTimer {
    [timer invalidate];
    [timer release];
    timer = nil;
    [(SKSideWindow *)[self window] slideIn];
}

- (void)mouseEntered:(NSEvent *)theEvent {
    if (NSPointInRect([NSEvent mouseLocation], [[self window] frame])) {
        if (timer == nil)
            timer = [[NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(slideInWithTimer:) userInfo:NULL repeats:NO] retain];
    } else if (timer) {
        [timer invalidate];
        [timer release];
        timer = nil;
    }
}

@end
