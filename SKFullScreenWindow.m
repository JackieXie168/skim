//
//  SKFullScreenWindow.m
//  Skim
//
//  Created by Christiaan Hofman on 2/16/07.
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

#import "SKFullScreenWindow.h"
#import "SKStringConstants.h"

#define DURATION 0.25

@implementation SKFullScreenWindow

- (id)initWithScreen:(NSScreen *)screen backgroundColor:(NSColor *)backgroundColor level:(NSInteger)level {
    NSRect screenFrame = [(screen ?: [NSScreen mainScreen]) frame];
    self = [self initWithContentRect:screenFrame styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
    if (self) {
        [self setBackgroundColor:backgroundColor];
        [self setLevel:level];
        [self setReleasedWhenClosed:NO];
        [self setExcludedFromWindowsMenu:YES];
        // appartently this is needed for secondary screens
        [self setFrame:screenFrame display:NO];
        if ([self respondsToSelector:@selector(setAnimationBehavior:)])
            [self setAnimationBehavior:NSWindowAnimationBehaviorNone];
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

- (void)fadeOutWithBlockingMode:(NSAnimationBlockingMode)blockingMode {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKDisableAnimationsKey]) {
        [self orderOut:nil];
    } else {
        NSDictionary *fadeOutDict = [[NSDictionary alloc] initWithObjectsAndKeys:self, NSViewAnimationTargetKey, NSViewAnimationFadeOutEffect, NSViewAnimationEffectKey, nil];
        animation = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObjects:fadeOutDict, nil]];
        [fadeOutDict release];
        
        [animation setAnimationBlockingMode:blockingMode];
        [animation setDuration:DURATION];
        [animation setDelegate:self];
        [animation startAnimation];
    }
}

- (void)fadeInWithBlockingMode:(NSAnimationBlockingMode)blockingMode {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKDisableAnimationsKey]) {
        [self orderFront:nil];
    } else {
        NSDictionary *fadeInDict = [[NSDictionary alloc] initWithObjectsAndKeys:self, NSViewAnimationTargetKey, NSViewAnimationFadeInEffect, NSViewAnimationEffectKey, nil];
        animation = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObjects:fadeInDict, nil]];
        [fadeInDict release];
        
        [self setAlphaValue:0.0];
        [super orderFront:nil];
        
        [animation setAnimationBlockingMode:blockingMode];
        [animation setDuration:DURATION];
        [animation setDelegate:self];
        [animation startAnimation];
    }
}

- (void)fadeOutBlocking {
    [self fadeOutWithBlockingMode:NSAnimationBlocking];
}

- (void)fadeOut {
    [self fadeOutWithBlockingMode:NSAnimationNonblockingThreaded];
}

- (void)fadeInBlocking {
    [self fadeInWithBlockingMode:NSAnimationBlocking];
}

- (void)fadeIn {
    [self fadeInWithBlockingMode:NSAnimationNonblockingThreaded];
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

@end

@implementation SKMainFullScreenWindow

- (id)initWithScreen:(NSScreen *)screen backgroundColor:(NSColor *)backgroundColor level:(NSInteger)level {
    self = [super initWithScreen:screen backgroundColor:backgroundColor level:level];
    if (self) {
        [self setDisplaysWhenScreenProfileChanges:YES];
        [self setAcceptsMouseMovedEvents:YES];
        [self setExcludedFromWindowsMenu:NO];
    }
    return self;
}

- (BOOL)canBecomeKeyWindow { return YES; }

- (BOOL)canBecomeMainWindow { return YES; }

- (void)sendEvent:(NSEvent *)theEvent {
    if ([theEvent type] == NSRightMouseDown || ([theEvent type] == NSLeftMouseDown && ([theEvent modifierFlags] & NSControlKeyMask))) {
        if ([[self windowController] respondsToSelector:@selector(handleRightMouseDown:)] && [[self windowController] handleRightMouseDown:theEvent])
            return;
    }
    [super sendEvent:theEvent];
}

- (void)cancelOperation:(id)sender {
    // for some reason this action method is not passed on to the window controller, so we do this ourselves
    if ([[self windowController] respondsToSelector:@selector(cancelOperation:)])
        [[self windowController] cancelOperation:self];
}

@end

