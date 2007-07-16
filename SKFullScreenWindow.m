//
//  SKFullScreenWindow.m
//  Skim
//
//  Created by Christiaan Hofman on 2/16/07.
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

#import "SKFullScreenWindow.h"
#import "SKMainWindowController.h"
#import "SKPDFHoverWindow.h"
#import "SKAnimationview.h"


@implementation SKFullScreenWindow

- (id)initWithScreen:(NSScreen *)screen {
    if (self = [self initWithContentRect:[screen frame] styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO screen:screen]) {
        [self setReleasedWhenClosed:NO];
        [self setDisplaysWhenScreenProfileChanges:YES];
        [self setAcceptsMouseMovedEvents:YES];
        [self setBackgroundColor:[NSColor blackColor]];
        [self setContentView:[[[SKAnimationView alloc] init] autorelease]];
    }
    return self;
}

- (BOOL)canBecomeKeyWindow { return YES; }

- (BOOL)canBecomeMainWindow { return YES; }

- (void)keyDown:(NSEvent *)theEvent {
    NSString *characters = [theEvent charactersIgnoringModifiers];
    unichar ch = [characters length] > 0 ? [characters characterAtIndex:0] : 0;
	unsigned modifierFlags = [theEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask;
    
    if (modifierFlags == 0) {
        SKMainWindowController *wc = (SKMainWindowController *)[self windowController];
        if (ch == 0x1B) {
            [wc exitFullScreen:self];
        } else {
            [super keyDown:theEvent];
        }
    } else {
        [super keyDown:theEvent];
    }
}

- (NSView *)mainView {
    return [[[self contentView] subviews] lastObject];
}

- (void)setMainView:(NSView *)view {
    [view setFrame:[[self contentView] bounds]];
    [[self contentView] addSubview:view];
}

- (void)sendEvent:(NSEvent *)theEvent {
    if ([theEvent type] == NSLeftMouseDown || [theEvent type] == NSRightMouseDown)
        [[SKPDFHoverWindow sharedHoverWindow] orderOut:nil];
    [super sendEvent:theEvent];
}

- (void)resignMainWindow {
    [[SKPDFHoverWindow sharedHoverWindow] orderOut:nil];
    [super resignMainWindow];
}

- (void)resignKeyWindow {
    [[SKPDFHoverWindow sharedHoverWindow] orderOut:nil];
    [super resignKeyWindow];
}

@end
