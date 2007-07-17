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
#define WINDOW_OFFSET           8.0
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
        contentRect.origin.x = NSMaxX(contentRect) - DEFAULT_WINDOW_WIDTH;
    contentRect.size.width = DEFAULT_WINDOW_WIDTH;
    contentRect = NSInsetRect(contentRect, 0.0, WINDOW_INSET);
    if (self = [super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask | NSUnifiedTitleAndToolbarWindowMask backing:NSBackingStoreBuffered defer:NO screen:screen]) {
        controller = aController;
        edge = anEdge;
        SKSideWindowContentView *contentView = [[[SKSideWindowContentView alloc] initWithFrame:[[self contentView] frame] edge:edge] autorelease];
        [self setContentView:contentView];
        [contentView trackMouseOvers];
		[self setBackgroundColor:[NSColor clearColor]];
		[self setOpaque:NO];
		[self setHasShadow:YES];
        [self setDisplaysWhenScreenProfileChanges:YES];
        [self setReleasedWhenClosed:NO];
        [self setHidesOnDeactivate:YES];
        [self setLevel:NSFloatingWindowLevel];
        [self moveToScreen:screen];
    }
    return self;
}

- (BOOL)canBecomeMainWindow { return NO; }

- (BOOL)canBecomeKeyWindow { return YES; }

- (void)moveToScreen:(NSScreen *)screen {
    NSRect screenFrame = [screen frame];
    NSRect frame = screenFrame;
    frame.size.width = WINDOW_OFFSET;
    if (edge == NSMaxXEdge)
        frame.origin.x = NSMaxX(screenFrame) - WINDOW_OFFSET;
    frame = NSInsetRect(frame, 0.0, WINDOW_INSET);
    [self setFrame:frame display:NO];
}

- (void)slideOut {
    if (state == NSDrawerOpenState || state == NSDrawerOpeningState) {
        state = NSDrawerClosingState;
        NSRect screenFrame = [[[controller window] screen] frame];
        NSRect endFrame, startFrame = [self frame];
        endFrame = startFrame;
        endFrame.size.width = WINDOW_OFFSET;
        endFrame.origin.x = edge == NSMaxXEdge ? NSMaxX(screenFrame) - WINDOW_OFFSET : NSMinX(screenFrame);
        NSDictionary *slideInDict = [NSDictionary dictionaryWithObjectsAndKeys:self, NSViewAnimationTargetKey, [NSValue valueWithRect:startFrame], NSViewAnimationStartFrameKey, [NSValue valueWithRect:endFrame], NSViewAnimationEndFrameKey, nil];
        NSViewAnimation *animation = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObjects:slideInDict, nil]];
        [animation setAnimationBlockingMode:NSAnimationBlocking];
        [animation setDuration:[self animationResizeTime:endFrame]];
        [animation startAnimation];
        [animation release];
        [[controller window] makeKeyAndOrderFront:self];
        state = NSDrawerClosedState;
    }
}

- (void)slideIn {
    if (state == NSDrawerClosedState || state == NSDrawerClosingState) {
        state = NSDrawerOpeningState;
        NSRect screenFrame = [[[controller window] screen] frame];
        NSRect endFrame, startFrame = [self frame];
        endFrame = startFrame;
        endFrame.size.width = NSWidth([[[self contentView] contentView] frame]) + CONTENT_INSET;
        endFrame.origin.x = edge == NSMaxXEdge ? NSMaxX(screenFrame) - NSWidth(endFrame) : NSMinX(screenFrame);
        NSDictionary *slideInDict = [NSDictionary dictionaryWithObjectsAndKeys:self, NSViewAnimationTargetKey, [NSValue valueWithRect:startFrame], NSViewAnimationStartFrameKey, [NSValue valueWithRect:endFrame], NSViewAnimationEndFrameKey, nil];
        NSViewAnimation *animation = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObjects:slideInDict, nil]];
        [animation setAnimationBlockingMode:NSAnimationBlocking];
        [animation setDuration:[self animationResizeTime:endFrame]];
        [animation startAnimation];
        [animation release];
        [self makeKeyAndOrderFront:nil];
        state = NSDrawerOpenState;
    }
}

- (NSView *)mainView {
    NSArray *subviews = [[self contentView] subviews];
    return [subviews count] ? [subviews objectAtIndex:0] : nil;
}

- (void)setMainView:(NSView *)newContentView {
    NSView *contentView = [[self contentView] contentView];
    [newContentView setFrame:[contentView bounds]];
    [newContentView retain];
    if ([[contentView subviews] count])
        [contentView replaceSubview:[[contentView subviews] objectAtIndex:0] with:newContentView];
    else
        [contentView addSubview:newContentView];
    [newContentView release];
    [self recalculateKeyViewLoop];
}

- (NSRectEdge)edge {
    return edge;
}

- (int)state {
    return state;
}

- (void)showSideWindow {
    [[self contentView] showWindow];
    [self makeKeyAndOrderFront:nil];
}

- (void)hideSideWindow {
    [[self contentView] hideWindow];
}

- (void)keyDown:(NSEvent *)theEvent {
    NSString *characters = [theEvent charactersIgnoringModifiers];
    unichar ch = [characters length] > 0 ? [characters characterAtIndex:0] : 0;
	unsigned modifierFlags = [theEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask;
    
    if (modifierFlags == 0) {
        if (ch == 0x1B) {
            [controller exitFullScreen:self];
        } else {
            [super keyDown:theEvent];
        }
    } else {
        [super keyDown:theEvent];
    }
}

@end


@implementation SKSideWindowContentView

- (id)initWithFrame:(NSRect)frameRect edge:(NSRectEdge)anEdge {
    if (self = [super initWithFrame:frameRect]) {
        NSRect ignored, contentRect = NSInsetRect(frameRect, 0.0, CONTENT_INSET);
        NSDivideRect(contentRect, &ignored, &contentRect, CONTENT_INSET, anEdge == NSMaxXEdge ? NSMinXEdge : NSMaxXEdge);
        contentView = [[[NSView alloc] initWithFrame:contentRect] autorelease];
        [contentView setAutoresizingMask:(anEdge == NSMaxXEdge ? NSViewMaxXMargin : NSViewMinXMargin) | NSViewHeightSizable];
        [self addSubview:contentView];
        edge = anEdge;
    }
    return self;
}

- (void)dealloc {
    [timer invalidate];
    [timer release];
    timer = nil;
    [super dealloc];
}

- (NSRect)resizeHandleRect {
    NSRect rect, ignored;
    NSDivideRect([self bounds], &rect, &ignored, CONTENT_INSET, edge == NSMaxXEdge ? NSMinXEdge : NSMaxXEdge);
    return rect;
}

- (void)drawRect:(NSRect)aRect {
    NSRect ignored, topRect, bottomRect, rect;
    NSPoint startPoint, endPoint;
    
    NSDivideRect([self bounds], &ignored, &rect, -CONTENT_INSET, edge);
    NSDivideRect(rect, &topRect, &ignored, 2.0 * CORNER_RADIUS, NSMaxYEdge);
    NSDivideRect(rect, &bottomRect, &ignored, 2.0 * CORNER_RADIUS, NSMinYEdge);
    
    [NSGraphicsContext saveGraphicsState];
    
    [[NSColor colorWithCalibratedWhite:0.9 alpha:1.0] set];
    [NSBezierPath fillRoundRectInRect:topRect radius:CORNER_RADIUS];
    [[NSColor colorWithCalibratedWhite:0.4 alpha:1.0] set];
    [NSBezierPath fillRoundRectInRect:bottomRect radius:CORNER_RADIUS];
    [[NSColor colorWithCalibratedWhite:0.8 alpha:1.0] set];
    [NSBezierPath fillRoundRectInRect:NSInsetRect(rect, 0.0, 1.5) radius:CORNER_RADIUS];
    
    rect = [self resizeHandleRect];
    startPoint = NSMakePoint(NSMidX(rect) - 1.5, NSMidY(rect) - 10.0);
    endPoint = NSMakePoint(startPoint.x, startPoint.y + 20.0);
    [NSBezierPath setDefaultLineWidth:1.0];
    [[NSColor colorWithCalibratedWhite:0.5 alpha:1.0] set];
    [NSBezierPath strokeLineFromPoint:startPoint toPoint:endPoint];
    startPoint.x += 2.0;
    endPoint.x += 2.0;
    [NSBezierPath strokeLineFromPoint:startPoint toPoint:endPoint];
    [[NSColor colorWithCalibratedWhite:0.9 alpha:1.0] set];
    startPoint.x -= 1.0;
    endPoint.x -= 1.0;
    [NSBezierPath strokeLineFromPoint:startPoint toPoint:endPoint];
    startPoint.x += 2.0;
    endPoint.x += 2.0;
    [NSBezierPath strokeLineFromPoint:startPoint toPoint:endPoint];
    
    [NSGraphicsContext restoreGraphicsState];
}

- (id)contentView {
    return contentView;
}

- (void)setContentView:(NSView *)newContentView {
    contentView = newContentView;
}

- (void)setFrame:(NSRect)frame {
    [super setFrame:frame];
    if (resizing)
        return;
    if ([self window] && trackingRect)
        [self removeTrackingRect:trackingRect];
    trackingRect = [self addTrackingRect:[self bounds] owner:self userData:NULL assumeInside:NO];
}

- (void)setFrameSize:(NSSize)size {
    [super setFrameSize:size];
    if (resizing)
        return;
    if ([self window] && trackingRect)
        [self removeTrackingRect:trackingRect];
    trackingRect = [self addTrackingRect:[self bounds] owner:self userData:NULL assumeInside:NO];
}
 
- (void)setBounds:(NSRect)bounds {
    [super setBounds:bounds];
    if (resizing)
        return;
    if ([self window] && trackingRect)
        [self removeTrackingRect:trackingRect];
    trackingRect = [self addTrackingRect:[self bounds] owner:self userData:NULL assumeInside:NO];
}
 
- (void)setBoundsSize:(NSSize)size {
    [super setBoundsSize:size];
    if (resizing)
        return;
    if ([self window] && trackingRect)
        [self removeTrackingRect:trackingRect];
    trackingRect = [self addTrackingRect:[self bounds] owner:self userData:NULL assumeInside:NO];
}

- (void)viewWillMoveToWindow:(NSWindow *)newWindow {
    if ([self window] && trackingRect)
        [self removeTrackingRect:trackingRect];
}

- (void)viewDidMoveToWindow {
    if ([self window] && trackingRect)
        [self removeTrackingRect:trackingRect];
    trackingRect = [self addTrackingRect:[self bounds] owner:self userData:NULL assumeInside:NO];
}

- (void)resizeWithEvent:(NSEvent *)theEvent {
	NSPoint initialLocation = [[self window] convertBaseToScreen:[theEvent locationInWindow]];
	NSRect initialFrame = [[self window] frame];
	BOOL keepGoing = YES;
	
    [self removeTrackingRect:trackingRect];
    trackingRect = 0;
    resizing = YES;
    [contentView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    
	while (keepGoing) {
		theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask];
		switch ([theEvent type]) {
			case NSLeftMouseDragged:
            {
				NSPoint	newLocation = [[self window] convertBaseToScreen:[theEvent locationInWindow]];
                NSRect newFrame = initialFrame;
                
                if (edge == NSMaxXEdge) {
                    newFrame.size.width -= newLocation.x - initialLocation.x;
                    if (NSWidth(newFrame) < WINDOW_MIN_WIDTH)
                        newFrame.size.width = WINDOW_MIN_WIDTH;
                    newFrame.origin.x = NSMaxX(initialFrame) - NSWidth(newFrame);
                } else {
                    newFrame.size.width += newLocation.x - initialLocation.x;
                    if (NSWidth(newFrame) < WINDOW_MIN_WIDTH)
                        newFrame.size.width = WINDOW_MIN_WIDTH;
                }
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
    
    [contentView setAutoresizingMask:(edge == NSMaxXEdge ? NSViewMaxXMargin : NSViewMinXMargin) | NSViewHeightSizable];
    [self trackMouseOvers];
    resizing = NO;
}

- (void)mouseDown:(NSEvent *)theEvent {
	NSPoint mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    NSRect resizeHandleRect = [self resizeHandleRect];
    if (NSPointInRect(mouseLoc, resizeHandleRect) && [(SKSideWindow *)[self window] state] == NSDrawerOpenState) {
        if ([theEvent clickCount] == 2)
            [self hideWindow];
        else
            [self resizeWithEvent:theEvent];
    } else
        [super mouseDown:theEvent];
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent { return YES; }

-(void)resetCursorRects{
    [self discardCursorRects];
    [self addCursorRect:[self resizeHandleRect] cursor:[NSCursor resizeLeftRightCursor]];
}

- (void)trackMouseOvers {
    if ([self window] && trackingRect)
        [self removeTrackingRect:trackingRect];
    trackingRect = [self addTrackingRect:[self bounds] owner:self userData:NULL assumeInside:NO];
}

- (void)mouseExited:(NSEvent *)theEvent {
    if (isStatic)
        return;
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
    if (isStatic)
        return;
    if (NSPointInRect([NSEvent mouseLocation], [[self window] frame])) {
        if (timer == nil)
            timer = [[NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(slideInWithTimer:) userInfo:NULL repeats:NO] retain];
    } else if (timer) {
        [timer invalidate];
        [timer release];
        timer = nil;
    }
}

- (void)showWindow {
    isStatic = YES;
    if (timer) {
        [timer invalidate];
        [timer release];
        timer = nil;
    }
    [(SKSideWindow *)[self window] slideIn];
}

- (void)hideWindow {
    isStatic = NO;
    if (timer) {
        [timer invalidate];
        [timer release];
        timer = nil;
    }
    [(SKSideWindow *)[self window] slideOut];
}

@end
