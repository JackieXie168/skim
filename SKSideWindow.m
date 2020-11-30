//
//  SKSideWindow.m
//  Skim
//
//  Created by Christiaan Hofman on 2/8/07.
/*
 This software is Copyright (c) 2007-2020
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
#import "NSEvent_SKExtensions.h"
#import "SKStringConstants.h"
#import "NSGeometry_SKExtensions.h"
#import "NSShadow_SKExtensions.h"
#import "NSColor_SKExtensions.h"
#import "NSGraphics_SKExtensions.h"

#define DEFAULT_WINDOW_WIDTH    300.0
#define DEFAULT_WINDOW_HEIGHT   400.0
#define WINDOW_INSET            1.0
#define CORNER_RADIUS           8.0
#define CONTENT_INSET           8.0
#define WINDOW_MIN_WIDTH        14.0
#define RESIZE_HANDLE_WIDTH     8.0
#define RESIZE_HANDLE_HEIGHT    20.0

static CGFloat WINDOW_OFFSET = 8.0;

@implementation SKSideWindow

- (void)contentViewFrameChanged:(NSNotification *)notification {
    NSVisualEffectView *contentView = (NSVisualEffectView *)[self contentView];
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:SKShrinkRect([contentView bounds], -CORNER_RADIUS, NSMinXEdge) xRadius:CORNER_RADIUS yRadius:CORNER_RADIUS];
    NSImage *mask = [[NSImage alloc] initWithSize:[contentView bounds].size];
    [mask lockFocus];
    [[NSColor blackColor] set];
    [path fill];
    [mask unlockFocus];
    [mask setTemplate:YES];
    [contentView setMaskImage:mask];
}

- (id)initWithView:(NSView *)view {
    self = [super initWithContentRect:NSMakeRect(0.0, 0.0, DEFAULT_WINDOW_WIDTH, DEFAULT_WINDOW_HEIGHT) styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
    if (self) {
		[self setBackgroundColor:[NSColor clearColor]];
		[self setOpaque:NO];
		[self setHasShadow:YES];
        [self setDisplaysWhenScreenProfileChanges:YES];
        [self setReleasedWhenClosed:NO];
        [self setAlphaValue:RUNNING_AFTER(10_13) ? 1.0 : 0.95];
        [self setAnimationBehavior:NSWindowAnimationBehaviorNone];
        
        NSView *backgroundView = [[[SKSideWindowContentView alloc] init] autorelease];
        
        if (RUNNING_AFTER(10_13)) {
            NSVisualEffectView *contentView = [[NSVisualEffectView alloc] init];
            [contentView setMaterial:RUNNING_BEFORE(10_11) ? NSVisualEffectMaterialAppearanceBased : NSVisualEffectMaterialSidebar];
            [self setContentView:contentView];
            [backgroundView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
            [backgroundView setFrame:[contentView bounds]];
            [contentView addSubview:backgroundView];
            [contentView release];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contentViewFrameChanged:) name:NSViewFrameDidChangeNotification object:contentView];
            [self contentViewFrameChanged:nil];
            SKSetHasDarkAppearance(self);
        } else {
            [self setContentView:backgroundView];
        }
        
        NSRect contentRect = SKShrinkRect(NSInsetRect([backgroundView bounds], 0.0, CONTENT_INSET), CONTENT_INSET, NSMaxXEdge);
        mainContentView = [[[NSView alloc] initWithFrame:contentRect] autorelease];
        [mainContentView setAutoresizingMask:NSViewMinXMargin | NSViewHeightSizable];
        [backgroundView addSubview:mainContentView];
        [view setFrame:[mainContentView bounds]];
        [mainContentView addSubview:view];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (BOOL)canBecomeMainWindow { return NO; }

- (BOOL)canBecomeKeyWindow { return YES; }

- (void)attachToWindow:(NSWindow *)window {
    NSRect frame;
    NSRect screenFrame = [[window screen] frame];
    frame = SKSliceRect(screenFrame, WINDOW_OFFSET, NSMinXEdge);
    [self setFrame:NSInsetRect(frame, 0.0, WINDOW_INSET) display:NO];
    [self setLevel:[window level]];
    [self orderFront:nil];
    [window addChildWindow:self ordered:NSWindowAbove];
    
    frame.size.width = NSWidth([mainContentView frame]) + CONTENT_INSET;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKDisableAnimationsKey]) {
        [self setFrame:frame display:YES];
        if ([window isKeyWindow])
            [self makeKeyAndOrderFront:nil];
        else
            [self orderFront:nil];
    } else {
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context){
                [[self animator] setFrame:frame display:YES];
            }
            completionHandler:^{
                if ([window isKeyWindow])
                    [self makeKeyAndOrderFront:nil];
                else
                    [self orderFront:nil];
            }];
    }
}

- (void)remove {
    [[self parentWindow] removeChildWindow:self];
    [self orderOut:nil];
}

- (void)keyDown:(NSEvent *)theEvent {
    if ([theEvent firstCharacter] == 't' && [theEvent deviceIndependentModifierFlags] == 0)
        [self cancelOperation:self];
    else
        [super keyDown:theEvent];
}

- (void)cancelOperation:(id)sender {
    // for some reason this action method is not passed on up the responder chain, so we do this ourselves
    if ([[self nextResponder] respondsToSelector:@selector(cancelOperation:)])
        [[self nextResponder] cancelOperation:self];
}
    
- (NSResponder *)nextResponder {
    return [[self parentWindow] windowController];
}

- (void)resizeWithEvent:(NSEvent *)theEvent {
    NSPoint initialLocation = [theEvent locationOnScreen];
	NSRect initialFrame = [self frame];
	BOOL keepGoing = YES;
	
    resizing = YES;
    [mainContentView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    
	while (keepGoing) {
		theEvent = [self nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSMouseEnteredMask | NSMouseExitedMask];
		switch ([theEvent type]) {
			case NSLeftMouseDragged:
            {
				NSPoint	newLocation = [theEvent locationOnScreen];
                NSRect newFrame = initialFrame;
                newFrame.size.width += newLocation.x - initialLocation.x;
                if (NSWidth(newFrame) < WINDOW_MIN_WIDTH)
                    newFrame.size.width = WINDOW_MIN_WIDTH;
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
    
    [mainContentView setAutoresizingMask:NSViewMinXMargin | NSViewHeightSizable];
    resizing = NO;
}

@end


@implementation SKSideWindowContentView

- (NSRect)resizeHandleRect {
    return SKSliceRect([self bounds], CONTENT_INSET, NSMaxXEdge);
}

- (void)drawRect:(NSRect)aRect {
    NSRect rect = [self bounds];
    NSRect topRect = SKSliceRect(rect, CORNER_RADIUS, NSMaxYEdge);
    NSRect bottomRect = SKSliceRect(rect, CORNER_RADIUS, NSMinYEdge);
    NSSize offset = NSZeroSize;
    NSPoint startPoint, endPoint;
    NSBezierPath *path = [NSBezierPath bezierPathWithRect:rect];
    NSColor *backgroundColor = [NSColor windowBackgroundColor];
    CGFloat gray = [[[NSColor secondarySelectedControlColor] colorUsingColorSpaceName:NSDeviceWhiteColorSpace] whiteComponent];
    NSColor *topShadeColor = [NSColor colorWithDeviceWhite:1.0 alpha:0.5];
    NSColor *bottomShadeColor = [NSColor colorWithDeviceWhite:0.0 alpha:0.5];
    NSColor *handleColor = [NSColor colorWithDeviceWhite:fmax(0.0, gray - 0.3) alpha:1.0];
    NSColor *handleShadeColor = [NSColor colorWithDeviceWhite:fmin(1.0, gray + 0.1) alpha:1.0];

    [NSGraphicsContext saveGraphicsState];
    
    [path addClip];
    rect = SKShrinkRect(rect, -CORNER_RADIUS, NSMinXEdge);
    [[NSBezierPath bezierPathWithRoundedRect:rect xRadius:CORNER_RADIUS yRadius:CORNER_RADIUS] addClip];
    if ([[self window] contentView] == self) {
        [backgroundColor set];
        [path fill];
    }
    
    offset.width = NSWidth(rect) + 6.0;
    rect.origin.x -= offset.width;
    path = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(rect, -2.0, 0.0) xRadius:CORNER_RADIUS + 2.0 yRadius:CORNER_RADIUS];
    [path appendBezierPathWithRect:NSInsetRect(rect, -4.0 , -2.0)];
    [path setWindingRule:NSEvenOddWindingRule];
    
    [NSGraphicsContext saveGraphicsState];
    [[NSBezierPath bezierPathWithRect:topRect] addClip];
    [NSShadow setShadowWithColor:topShadeColor  blurRadius:2.0 offset:offset];
    [path fill];
    [NSGraphicsContext restoreGraphicsState];
    
    [NSGraphicsContext saveGraphicsState];
    [[NSBezierPath bezierPathWithRect:bottomRect] addClip];
    [NSShadow setShadowWithColor:bottomShadeColor blurRadius:2.0 offset:offset];
    [path fill];
    [NSGraphicsContext restoreGraphicsState];
    
    rect = [self resizeHandleRect];
    startPoint = NSMakePoint(NSMidX(rect) - 1.5, NSMidY(rect) - 10.0);
    endPoint = NSMakePoint(startPoint.x, startPoint.y + 20.0);
    offset.width = 1.0;
    [NSBezierPath setDefaultLineWidth:1.0];
    [handleColor set];
    [NSShadow setShadowWithColor:handleShadeColor blurRadius:0.0 offset:offset];
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
