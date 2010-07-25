//
//  SKFullScreenWindow.m
//  Skim
//
//  Created by Christiaan Hofman on 2/16/07.
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

#import "SKFullScreenWindow.h"
#import "SKMainWindowController.h"
#import "SKMainWindowController_Actions.h"
#import "NSEvent_SKExtensions.h"
#import "SKStringConstants.h"


@implementation SKFullScreenWindow

@dynamic mainView;

- (id)initWithScreen:(NSScreen *)screen {
    if (screen == nil)
        screen = [NSScreen mainScreen];
    NSRect screenFrame = [screen frame];
    if (self = [self initWithContentRect:screenFrame styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO]) {
        [self setBackgroundColor:[NSColor blackColor]];
        [self setReleasedWhenClosed:NO];
        [self setExcludedFromWindowsMenu:YES];
        // appartently this is needed for secondary screens
        [self setFrame:screenFrame display:NO];
    }
    return self;
}

- (void)stopAnimation {
    [animation stopAnimation];
    SKDESTROY(animation);
}

- (void)dealloc {
    [self stopAnimation];
    [super dealloc];
}

- (BOOL)canBecomeKeyWindow { return NO; }

- (BOOL)canBecomeMainWindow { return NO; }

- (void)orderFront:(id)sender {
    [self stopAnimation];
    [self setAlphaValue:1.0];
    [super orderFront:sender];
}

- (void)makeKeyAndOrderFront:(id)sender {
    [self stopAnimation];
    [self setAlphaValue:1.0];
    [super makeKeyAndOrderFront:sender];
}

- (void)orderOut:(id)sender {
    [self stopAnimation];
    [super orderOut:sender];
    [self setAlphaValue:1.0];
}

- (void)fadeOutBlocking:(BOOL)block {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKDisableAnimationsKey]) {
        [self orderOut:nil];
    } else {
        NSDictionary *fadeOutDict = [[NSDictionary alloc] initWithObjectsAndKeys:self, NSViewAnimationTargetKey, NSViewAnimationFadeOutEffect, NSViewAnimationEffectKey, nil];
        animation = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObjects:fadeOutDict, nil]];
        [fadeOutDict release];
        
        [animation setAnimationBlockingMode:block ? NSAnimationBlocking : NSAnimationNonblockingThreaded];
        [animation setAnimationCurve:block ? NSAnimationEaseIn : NSAnimationEaseInOut];
        [animation setDuration:0.5];
        [animation setDelegate:self];
        [animation startAnimation];
    }
}

- (void)fadeInBlocking:(BOOL)block {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKDisableAnimationsKey]) {
        [self orderFront:nil];
    } else {
        NSDictionary *fadeInDict = [[NSDictionary alloc] initWithObjectsAndKeys:self, NSViewAnimationTargetKey, NSViewAnimationFadeInEffect, NSViewAnimationEffectKey, nil];
        animation = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObjects:fadeInDict, nil]];
        [fadeInDict release];
        
        [self setAlphaValue:0.0];
        [super orderFront:nil];
        
        [animation setAnimationBlockingMode:block ? NSAnimationBlocking : NSAnimationNonblockingThreaded];
        [animation setAnimationCurve:block ? NSAnimationEaseIn : NSAnimationEaseInOut];
        [animation setDuration:0.5];
        [animation setDelegate:self];
        [animation startAnimation];
    }
}

- (void)fadeOutBlocking {
    [self fadeOutBlocking:YES];
}

- (void)fadeOut {
    [self fadeOutBlocking:NO];
}

- (void)fadeInBlocking {
    [self fadeInBlocking:YES];
}

- (void)fadeIn {
    [self fadeInBlocking:NO];
}

- (void)animationDidEnd:(NSAnimation *)anAnimation {
    BOOL isFadeOut = [[[[animation viewAnimations] lastObject] objectForKey:NSViewAnimationEffectKey] isEqual:NSViewAnimationFadeOutEffect];
    SKDESTROY(animation);
    if (isFadeOut)
        [self orderOut:nil];
    [self setAlphaValue:1.0];
}

- (void)animationDidStop:(NSAnimation *)anAnimation {
    SKDESTROY(animation);
    [self orderOut:nil];
    [self setAlphaValue:1.0];
}

- (NSView *)mainView {
    return [[[self contentView] subviews] lastObject];
}

- (void)setMainView:(NSView *)view {
    [view setFrame:[[self contentView] bounds]];
    [[self contentView] addSubview:view];
}

@end

@implementation SKMainFullScreenWindow

- (id)initWithScreen:(NSScreen *)screen canBecomeMain:(BOOL)flag {
    if (self = [super initWithScreen:screen]) {
        [self setDisplaysWhenScreenProfileChanges:YES];
        [self setAcceptsMouseMovedEvents:YES];
        [self setExcludedFromWindowsMenu:NO];
    }
    return self;
}

- (BOOL)canBecomeKeyWindow { return YES; }

- (BOOL)canBecomeMainWindow { return YES; }

- (void)sendEvent:(NSEvent *)theEvent {
    if ([theEvent type] == NSLeftMouseDown || [theEvent type] == NSRightMouseDown) {
        SKMainWindowController *wc = (SKMainWindowController *)[self windowController];
        if ([wc interactionMode] == SKPresentationMode && ([theEvent type] == NSRightMouseDown || ([theEvent modifierFlags] & NSControlKeyMask))) {
            [wc doGoToPreviousPage:self];
            return;
        }
    }
    [super sendEvent:theEvent];
}

- (void)keyDown:(NSEvent *)theEvent {
    unichar ch = [theEvent firstCharacter];
	NSUInteger modifierFlags = [theEvent deviceIndependentModifierFlags];
    
    if (modifierFlags == 0 && ch == SKEscapeCharacter) {
        [(SKMainWindowController *)[self windowController] exitFullScreen:self];
        return;
    }
    [super keyDown:theEvent];
}

@end

