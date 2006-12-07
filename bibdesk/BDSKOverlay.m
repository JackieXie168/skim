//
//  BDSKOverlay.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 9/8/05.
//
/*
 This software is Copyright (c) 2005,2006
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

#import "BDSKOverlay.h"
#import <OmniAppKit/NSToolbar-OAExtensions.h>

@implementation BDSKOverlay

// designated initializer of NSWindow
- (id)initWithContentRect:(NSRect)contentRect 
                styleMask:(unsigned int)aStyle
                  backing:(NSBackingStoreType)bufferingType 
                    defer:(BOOL)flag {
	
	if (self = [super initWithContentRect:contentRect 
								styleMask:NSBorderlessWindowMask
								  backing:bufferingType
									defer:flag]) {
		parentView = nil;
		// we are transparent and ignore mouse events
		[self setBackgroundColor:[NSColor clearColor]];
		[self setOpaque:NO];
		[self setAlphaValue:.999];
		[self setIgnoresMouseEvents:YES];
	}
	return self;
}

- (void)dealloc {
	[self remove];
	[super dealloc];
}

- (void)parentViewFrameChanged:(NSNotification *)notification {
	NSRect viewRect = [parentView convertRect:[parentView bounds] toView:nil];
	NSPoint windowOrigin = [[parentView window] frame].origin;
	
	viewRect.origin.x += windowOrigin.x;
	viewRect.origin.y += windowOrigin.y;
	
	[self setFrame:viewRect display:YES];
}

- (void)parentWindowWillClose:(NSNotification *)notification {
	[self orderOut:nil];
}

- (void)overlayView:(NSView *)aView {
	if ([aView window] == nil)
		return; // we don't support overlay if the view is not in a window
	if (parentView)
		[self remove]; // first remove from the old parentView
	
	parentView = [aView retain];
    
    NSWindow *parentWindow = [parentView window];
	
	// if the parent is a floating panel, we also should be. Otherwise we won't get on top.
	[self setFloatingPanel:([parentWindow isKindOfClass:[NSPanel class]] && [(NSPanel *)parentWindow isFloatingPanel])];
    [self setHidesOnDeactivate:[parentWindow hidesOnDeactivate]];
    [self setLevel:[parentWindow level]];
	[parentWindow addChildWindow:self ordered:NSWindowAbove];
	
	// resize ourselves to cover the view, and observe future frame changes
	[self parentViewFrameChanged:nil];
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		   selector:@selector(parentViewFrameChanged:)
			   name:NSViewFrameDidChangeNotification
			 object:parentView];
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		   selector:@selector(parentWindowWillClose:)
			   name:NSWindowWillCloseNotification
			 object:parentWindow];
	
	if ([parentWindow isVisible])
		[self orderFront:nil];
}

- (void)remove {
	if (parentView == nil)
		return;
	
	// stop observing our old parentView
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[[self parentWindow] removeChildWindow:self];
	// we were on top, so it needs to redisplay
	
	[parentView setNeedsDisplay:YES];
	[parentView release];
	parentView = nil;
	
	[self orderOut:nil];
}

@end

//
// This is identical to the NSPanel version, except that it accounts for a toolbar in the height calculation, and won't hide when the application is in the background.
//

@implementation BDSKOverlayWindow

// designated initializer of NSWindow
- (id)initWithContentRect:(NSRect)contentRect 
                styleMask:(unsigned int)aStyle
                  backing:(NSBackingStoreType)bufferingType 
                    defer:(BOOL)flag {
	
	if (self = [super initWithContentRect:contentRect 
								styleMask:NSBorderlessWindowMask
								  backing:bufferingType
									defer:flag]) {
		parentView = nil;
		// we are transparent and ignore mouse events
		[self setBackgroundColor:[NSColor clearColor]];
		[self setOpaque:NO];
		[self setAlphaValue:.999];
		[self setIgnoresMouseEvents:YES];
	}
	return self;
}

- (void)dealloc {
	[self remove];
	[super dealloc];
}

- (void)parentViewFrameChanged:(NSNotification *)notification {
	NSWindow *parentWindow = [parentView window];
    NSRect viewRect = [parentWindow contentRectForFrameRect:[parentWindow frame]];
	[self setFrame:viewRect display:YES];
}

- (void)parentWindowWillClose:(NSNotification *)notification {
	[self orderOut:nil];
}

- (void)orderFront:(id)sender{
    [super orderFront:sender];
    [self parentViewFrameChanged:nil];
}

- (void)overlayView:(NSView *)aView {
	if ([aView window] == nil)
		return; // we don't support overlay if the view is not in a window
	if (parentView)
		[self remove]; // first remove from the old parentView
	
	parentView = [aView retain];
    
    NSWindow *parentWindow = [parentView window];
	
    [self setLevel:[parentWindow level]];
	[parentWindow addChildWindow:self ordered:NSWindowAbove];
	
	// resize ourselves to cover the view, and observe future frame changes
	[self parentViewFrameChanged:nil];
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		   selector:@selector(parentViewFrameChanged:)
			   name:NSViewFrameDidChangeNotification
			 object:parentView];
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		   selector:@selector(parentWindowWillClose:)
			   name:NSWindowWillCloseNotification
			 object:parentWindow];
	
	if ([parentWindow isVisible])
		[self orderFront:nil];
}

- (void)remove {
	if (parentView == nil)
		return;
	
	// stop observing our old parentView
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[[self parentWindow] removeChildWindow:self];
	// we were on top, so it needs to redisplay
	
	[parentView setNeedsDisplay:YES];
	[parentView release];
	parentView = nil;
	
	[self orderOut:nil];
}
@end

