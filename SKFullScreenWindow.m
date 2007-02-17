//
//  SKFullScreenWindow.m
//  Skim
//
//  Created by Christiaan Hofman on 2/16/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "SKFullScreenWindow.h"
#import "SKMainWindowController.h"


@implementation SKFullScreenWindow

- (id)initWithScreen:(NSScreen *)screen {
    if (self = [self initWithContentRect:[screen frame] styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO screen:screen]) {
        [self setReleasedWhenClosed:NO];
        [self setDisplaysWhenScreenProfileChanges:YES];
        [self setAcceptsMouseMovedEvents:YES];
        [self setBackgroundColor:[NSColor blackColor]];
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
        } else if (ch == '1' && [wc isPresentation]) {
            [wc displaySinglePages:self];
        } else if (ch == '2' && [wc isPresentation]) {
            [wc displayFacingPages:self];
        } else {
            [super keyDown:theEvent];
        }
    } else {
        [super keyDown:theEvent];
    }
}

- (NSView *)mainView {
    return [[self contentView] lastObject];
}

- (void)setMainView:(NSView *)view {
    [view setFrame:[[self contentView] bounds]];
    [[self contentView] addSubview:view];
}

@end
