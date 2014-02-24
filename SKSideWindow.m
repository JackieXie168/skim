//
//  SKSideWindow.m
//  Skim
//
//  Created by Christiaan Hofman on 2/8/07.
/*
 This software is Copyright (c) 2007-2014
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
#import "NSBezierPath_SKExtensions.h"
#import "NSEvent_SKExtensions.h"
#import "SKStringConstants.h"
#import "NSGeometry_SKExtensions.h"

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

+ (CGFloat)requiredMargin {
    return hideWhenClosed == SKClosedSidePanelHide ? 0.0 : WINDOW_OFFSET + 1.0;
}

- (id)initWithMainController:(NSWindowController *)aController edge:(NSRectEdge)anEdge {
    NSScreen *screen = [[aController window] screen] ?: [NSScreen mainScreen];
    NSRect contentRect = NSInsetRect(SKSliceRect([screen frame], DEFAULT_WINDOW_WIDTH, anEdge), 0.0, WINDOW_INSET);
    
    self = [super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
    if (self) {
		[self setBackgroundColor:[NSColor clearColor]];
		[self setOpaque:NO];
		[self setHasShadow:YES];
        [self setDisplaysWhenScreenProfileChanges:YES];
        [self setReleasedWhenClosed:NO];
        if ([self respondsToSelector:@selector(setAnimationBehavior:)])
            [self setAnimationBehavior:NSWindowAnimationBehaviorNone];
        
        controller = aController;
        edge = anEdge;
        enabled = YES;
        
        timer = nil;
        
        NSView *contentView = [[[SKSideWindowContentView alloc] initWithFrame:NSZeroRect edge:edge] autorelease];
        [self setContentView:contentView];
        
        contentRect = SKShrinkRect(NSInsetRect([contentView bounds], 0.0, CONTENT_INSET), CONTENT_INSET, edge == NSMaxXEdge ? NSMinXEdge : NSMaxXEdge);
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

- (BOOL)canBecomeKeyWindow {
    return state == NSDrawerOpenState || state == NSDrawerOpeningState;
}

- (void)attachToWindow:(NSWindow *)window {
    NSRect frame;
    frame = SKSliceRect([[window screen] frame], WINDOW_OFFSET, edge);
    [self setFrame:NSInsetRect(frame, 0.0, WINDOW_INSET) display:NO];
    state = NSDrawerClosedState;
    if (hideWhenClosed != SKClosedSidePanelCollapse)
        [self setAlphaValue:0.0];
    [self setAcceptsMouseOver:YES];
    [self setLevel:[window level]];
    [self orderFront:nil];
    [window addChildWindow:self ordered:NSWindowAbove];
}

- (void)remove {
    [[self parentWindow] removeChildWindow:self];
    [self orderOut:nil];
}

- (void)animateToWidth:(CGFloat)width {
    NSRect screenFrame = [[[controller window] screen] frame];
    NSRect frame = [self frame];
    frame.size.width = width;
    frame.origin.x = edge == NSMaxXEdge ? NSMaxX(screenFrame) - width : NSMinX(screenFrame);
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKDisableAnimationsKey])
        [self setFrame:frame display:YES];
    else
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
            NSTimeInterval delay = [[NSUserDefaults standardUserDefaults] boolForKey:SKDisableAnimationsKey] ? 0.0 : [[NSAnimationContext currentContext] duration];
            [self performSelector:@selector(makeTransparent) withObject:nil afterDelay:delay];
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
    if ([theEvent firstCharacter] == 'p' && [theEvent deviceIndependentModifierFlags] == 0 && enabled == NO)
        [self cancelOperation:self];
    else
        [super keyDown:theEvent];
}

- (void)cancelOperation:(id)sender {
    // for some reason this action method is not passed on up the responder chain, so we do this ourselves
    if ([controller respondsToSelector:@selector(cancelOperation:)])
        [controller cancelOperation:self];
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
    self = [super initWithFrame:frameRect];
    if (self) {
        edge = anEdge;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
    if (self) {
        edge = [decoder decodeIntegerForKey:@"edge"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeInteger:edge forKey:@"edge"];
}

- (NSRect)resizeHandleRect {
    return SKSliceRect([self bounds], CONTENT_INSET, edge == NSMaxXEdge ? NSMinXEdge : NSMaxXEdge);
}

- (void)drawRect:(NSRect)aRect {
    NSRect topRect, bottomRect, rect = [self bounds];
    NSPoint startPoint, endPoint;
    NSShadow *shade = [[[NSShadow alloc] init] autorelease];
    
    topRect = SKSliceRect(rect, 2.0 * CORNER_RADIUS, NSMaxYEdge);
    bottomRect = SKSliceRect(rect, 2.0 * CORNER_RADIUS, NSMinYEdge);
    
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
    if (NSMouseInRect([theEvent locationInView:self], [self resizeHandleRect], [self isFlipped]))
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
