//
//  SKSideWindow.m
//  Skim
//
//  Created by Christiaan Hofman on 2/8/07.
/*
 This software is Copyright (c) 2007-2010
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
#import "NSBezierPath_SKExtensions.h"
#import "NSEvent_SKExtensions.h"

#define DEFAULT_WINDOW_WIDTH    300.0
#define WINDOW_INSET            1.0
#define CORNER_RADIUS           8.0
#define CONTENT_INSET           8.0
#define WINDOW_MIN_WIDTH        14.0
#define RESIZE_HANDLE_WIDTH     8.0
#define RESIZE_HANDLE_HEIGHT    20.0

static CGFloat WINDOW_OFFSET = 8.0;

#define SKHideClosedFullScreenSidePanelsKey @"SKHideClosedFullScreenSidePanels"

enum { SKClosedSidePanelCollapse, SKClosedSidePanelAutoHide, SKClosedSidePanelHide };

@implementation SKSideWindow

@synthesize edge, state, enabled, acceptsMouseOver;
@dynamic mainView;

static NSUInteger hideWhenClosed = SKClosedSidePanelCollapse;

+ (void)initialize {
    SKINITIALIZE;
    
    hideWhenClosed = [[NSUserDefaults standardUserDefaults] integerForKey:SKHideClosedFullScreenSidePanelsKey];
    
    if (hideWhenClosed == SKClosedSidePanelHide)
        WINDOW_OFFSET = 0.0;
}

+ (BOOL)isAutoHideEnabled {
    return hideWhenClosed != SKClosedSidePanelHide;
}

- (id)initWithMainController:(SKMainWindowController *)aController edge:(NSRectEdge)anEdge {
    NSScreen *screen = [[aController window] screen] ?: [NSScreen mainScreen];
    NSRect contentRect, ignored;
    NSDivideRect([screen frame], &contentRect, &ignored, DEFAULT_WINDOW_WIDTH, anEdge);
    contentRect = NSInsetRect(contentRect, 0.0, WINDOW_INSET);
    
    if (self = [super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO screen:screen]) {
		[self setBackgroundColor:[NSColor clearColor]];
		[self setOpaque:NO];
		[self setHasShadow:YES];
        [self setDisplaysWhenScreenProfileChanges:YES];
        [self setReleasedWhenClosed:NO];
        [self setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
        
        controller = aController;
        edge = anEdge;
        enabled = YES;
        
        NSView *contentView = [[[SKSideWindowContentView alloc] initWithFrame:NSZeroRect edge:edge] autorelease];
        [self setContentView:contentView];
        
        NSDivideRect(NSInsetRect([contentView bounds], 0.0, CONTENT_INSET), &ignored, &contentRect, CONTENT_INSET, edge == NSMaxXEdge ? NSMinXEdge : NSMaxXEdge);
        mainContentView = [[[NSView alloc] initWithFrame:contentRect] autorelease];
        [mainContentView setAutoresizingMask:(edge == NSMaxXEdge ? NSViewMaxXMargin : NSViewMinXMargin) | NSViewHeightSizable];
        [contentView addSubview:mainContentView];
        
        if (hideWhenClosed != SKClosedSidePanelHide) {
            trackingArea = [[NSTrackingArea alloc] initWithRect:[contentView bounds] options:NSTrackingMouseEnteredAndExited | NSTrackingInVisibleRect | NSTrackingActiveInActiveApp owner:self userInfo:nil];
            [contentView addTrackingArea:trackingArea];
        }
    }
    return self;
}

- (void)dealloc {
    [timer invalidate];
    SKDESTROY(timer);
    SKDESTROY(trackingArea);
    [super dealloc];
}

- (BOOL)canBecomeMainWindow { return NO; }

- (BOOL)canBecomeKeyWindow { return YES; }

- (void)attachToWindow:(NSWindow *)window onScreen:(NSScreen *)screen {
    NSRect frame, ignored;
    NSDivideRect([screen frame], &frame, &ignored, WINDOW_OFFSET, edge);
    [self setFrame:NSInsetRect(frame, 0.0, WINDOW_INSET) display:NO];
    state = NSDrawerClosedState;
    if (hideWhenClosed != SKClosedSidePanelCollapse)
        [self setAlphaValue:0.0];
    [self setAcceptsMouseOver:YES];
    [self setLevel:[window level]];
    [self orderFront:nil];
    [window addChildWindow:self ordered:NSWindowAbove];
}

- (void)orderOut:(id)sender {
    [[self parentWindow] removeChildWindow:self];
    [super orderOut:sender];
}

- (void)animateToWidth:(CGFloat)width {
    NSRect screenFrame = [[[controller window] screen] frame];
    NSRect frame = [self frame];
    frame.size.width = width;
    frame.origin.x = edge == NSMaxXEdge ? NSMaxX(screenFrame) - width : NSMinX(screenFrame);
    [[self animator] setFrame:frame display:YES];
}

- (void)makeTransparent {
    [self setAlphaValue:0.0];
}

- (void)slideOut {
    if (state == NSDrawerOpenState || state == NSDrawerOpeningState) {
        state = NSDrawerClosingState;
        [self animateToWidth:WINDOW_OFFSET];
        if ([self isKeyWindow])
            [[controller window] makeKeyAndOrderFront:self];
        state = NSDrawerClosedState;
        if (hideWhenClosed != SKClosedSidePanelCollapse) {
            [self performSelector:@selector(makeTransparent) withObject:nil afterDelay:[[NSAnimationContext currentContext] duration]];
        }
    }
}

- (void)slideIn {
    if (state == NSDrawerClosedState || state == NSDrawerClosingState) {
        if ([self alphaValue] < 0.1)
            [self setAlphaValue:1.0];
        state = NSDrawerOpeningState;
        [self animateToWidth:NSWidth([mainContentView frame]) + CONTENT_INSET];
        if ([[controller window] isKeyWindow])
            [self makeKeyAndOrderFront:nil];
        else
            [self orderFront:nil];
        state = NSDrawerOpenState;
    }
}

- (NSView *)mainView {
    NSArray *subviews = [mainContentView subviews];
    return [subviews count] ? [subviews objectAtIndex:0] : nil;
}

- (void)setMainView:(NSView *)newContentView {
    [newContentView setFrame:[mainContentView bounds]];
    [newContentView retain];
    if ([[mainContentView subviews] count])
        [mainContentView replaceSubview:[[mainContentView subviews] objectAtIndex:0] with:newContentView];
    else
        [mainContentView addSubview:newContentView];
    [newContentView release];
    [self recalculateKeyViewLoop];
}

- (void)expand {
    [self setAcceptsMouseOver:NO];
    [self slideIn];
}

- (void)collapse {
    [self slideOut];
    [self setAcceptsMouseOver:YES];
}

- (BOOL)acceptsMouseOver {
    return acceptsMouseOver && hideWhenClosed != SKClosedSidePanelHide;
}

- (void)setAcceptsMouseOver:(BOOL)flag {
    if (acceptsMouseOver != flag) {
        acceptsMouseOver = flag;
        if (timer) {
            [timer invalidate];
            SKDESTROY(timer);
        }
    }
}

- (void)keyDown:(NSEvent *)theEvent {
    unichar ch = [theEvent firstCharacter];
	NSUInteger modifierFlags = [theEvent deviceIndependentModifierFlags];
    
    if (ch == SKEscapeCharacter && modifierFlags == 0) {
        if (state == NSDrawerOpenState || state == NSDrawerOpeningState)
            [controller closeSideWindow:self];
        else
            [controller exitFullScreen:self];
    } else if (ch == 'p' && modifierFlags == 0 && [controller isPresentation]) {
        [controller closeSideWindow:self];
    } else {
        [super keyDown:theEvent];
    }
}

- (NSResponder *)nextResponder {
    return controller;
}

- (void)mouseExited:(NSEvent *)theEvent {
    if ([[theEvent trackingArea] isEqual:trackingArea] == NO) {
        [super mouseExited:theEvent];
    } else if (acceptsMouseOver && resizing == NO) {
        if (timer) {
            [timer invalidate];
            SKDESTROY(timer);
        }
        //if (NSPointInRect([NSEvent mouseLocation], [[self window] frame]) == NO)
        [self slideOut];
    }
}

- (void)slideInWithTimer:(NSTimer *)aTimer {
    [timer invalidate];
    SKDESTROY(timer);
    [self slideIn];
}

- (void)mouseEntered:(NSEvent *)theEvent {
    if ([[theEvent trackingArea] isEqual:trackingArea] == NO) {
        [super mouseEntered:theEvent];
    } else if (acceptsMouseOver && resizing == NO) {
        if (NSPointInRect([NSEvent mouseLocation], [self frame])) {
            if (timer == nil)
                timer = [[NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(slideInWithTimer:) userInfo:NULL repeats:NO] retain];
        } else if (timer) {
            [timer invalidate];
            SKDESTROY(timer);
        }
    }
}

- (void)resizeWithEvent:(NSEvent *)theEvent {
    if (state != NSDrawerOpenState)
        return;
    
    if (enabled && [theEvent clickCount] == 2) {
        [self collapse];
        return;
	}
    
    NSPoint initialLocation = [self convertBaseToScreen:[theEvent locationInWindow]];
	NSRect initialFrame = [self frame];
	BOOL keepGoing = YES;
	
    resizing = YES;
    [mainContentView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    
	while (keepGoing) {
		theEvent = [self nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask];
		switch ([theEvent type]) {
			case NSLeftMouseDragged:
            {
				NSPoint	newLocation = [self convertBaseToScreen:[theEvent locationInWindow]];
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
                [self setFrame:newFrame display:YES];
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
    
    [mainContentView setAutoresizingMask:(edge == NSMaxXEdge ? NSViewMaxXMargin : NSViewMinXMargin) | NSViewHeightSizable];
    resizing = NO;
}

@end


@implementation SKSideWindowContentView

- (id)initWithFrame:(NSRect)frameRect edge:(NSRectEdge)anEdge {
    if (self = [super initWithFrame:frameRect]) {
        edge = anEdge;
    }
    return self;
}

- (NSRect)resizeHandleRect {
    NSRect rect, ignored;
    NSDivideRect([self bounds], &rect, &ignored, CONTENT_INSET, edge == NSMaxXEdge ? NSMinXEdge : NSMaxXEdge);
    return rect;
}

- (void)drawRect:(NSRect)aRect {
    NSRect ignored, topRect, bottomRect, rect = [self bounds];
    NSPoint startPoint, endPoint;
    NSShadow *shade = [[[NSShadow alloc] init] autorelease];
    
    NSDivideRect(rect, &topRect, &ignored, 2.0 * CORNER_RADIUS, NSMaxYEdge);
    NSDivideRect(rect, &bottomRect, &ignored, 2.0 * CORNER_RADIUS, NSMinYEdge);
    
    [NSGraphicsContext saveGraphicsState];
    
    if (edge == NSMinXEdge) {
        [[NSColor colorWithCalibratedWhite:0.9 alpha:1.0] set];
        [[NSBezierPath bezierPathWithRightRoundedRect:topRect radius:CORNER_RADIUS] fill];
        [[NSColor colorWithCalibratedWhite:0.4 alpha:1.0] set];
        [[NSBezierPath bezierPathWithRightRoundedRect:bottomRect radius:CORNER_RADIUS] fill];
        [[NSColor colorWithCalibratedWhite:0.8 alpha:1.0] set];
        [[NSBezierPath bezierPathWithRightRoundedRect:NSInsetRect(rect, 0.0, 1.5) radius:CORNER_RADIUS] fill];
    } else {
        [[NSColor colorWithCalibratedWhite:0.9 alpha:1.0] set];
        [[NSBezierPath bezierPathWithLeftRoundedRect:topRect radius:CORNER_RADIUS] fill];
        [[NSColor colorWithCalibratedWhite:0.4 alpha:1.0] set];
        [[NSBezierPath bezierPathWithLeftRoundedRect:bottomRect radius:CORNER_RADIUS] fill];
        [[NSColor colorWithCalibratedWhite:0.8 alpha:1.0] set];
        [[NSBezierPath bezierPathWithLeftRoundedRect:NSInsetRect(rect, 0.0, 1.5) radius:CORNER_RADIUS] fill];
    }
    
    [shade setShadowBlurRadius:0.0];
    [shade setShadowOffset:NSMakeSize(1.0, 0.0)];
    [shade setShadowColor:[NSColor colorWithCalibratedWhite:0.9 alpha:1.0]];
    rect = [self resizeHandleRect];
    startPoint = NSMakePoint(NSMidX(rect) - 1.5, NSMidY(rect) - 10.0);
    endPoint = NSMakePoint(startPoint.x, startPoint.y + 20.0);
    [NSBezierPath setDefaultLineWidth:1.0];
    [[NSColor colorWithCalibratedWhite:0.5 alpha:1.0] set];
    [shade set];
    [NSBezierPath strokeLineFromPoint:startPoint toPoint:endPoint];
    startPoint.x += 2.0;
    endPoint.x += 2.0;
    [NSBezierPath strokeLineFromPoint:startPoint toPoint:endPoint];
    
    [NSGraphicsContext restoreGraphicsState];
}

- (void)mouseDown:(NSEvent *)theEvent {
    if (NSMouseInRect([self convertPoint:[theEvent locationInWindow] fromView:nil], [self resizeHandleRect], [self isFlipped]))
        [(SKSideWindow *)[self window] resizeWithEvent:theEvent];
    else
        [super mouseDown:theEvent];
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent { return YES; }

// we should be able to do this through tracking areas, but that does not work very well
- (void)resetCursorRects {
    [self discardCursorRects];
    [self addCursorRect:[self resizeHandleRect] cursor:[NSCursor resizeLeftRightCursor]];
}

@end
