//
//  SKSideWindow.m
//  Skim
//
//  Created by Christiaan Hofman on 8/2/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "SKSideWindow.h"
#import "SKMainWindowController.h"
#import "NSBezierPath_BDSKExtensions.h"

#define WINDOW_WIDTH 300.0
#define WINDOW_OFFSET 298.0
#define CORNER_RADIUS 10.0
#define CONTENT_INSET 10.0

@implementation SKSideWindow

- (id)initWithMainController:(SKMainWindowController *)aController {
    NSScreen *screen = [[aController window] screen];
    NSRect contentRect = [screen frame];
    contentRect.size.width = WINDOW_WIDTH;
    contentRect.origin.x -= WINDOW_OFFSET;
    if (self = [super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO screen:screen]) {
        controller = aController;
        [self setContentView:[[[SKSideWindowContentView alloc] init] autorelease]];
        [[self contentView] addTrackingRect:[[self contentView] bounds] owner:self userData:nil assumeInside:NO];
		[self setBackgroundColor:[NSColor clearColor]];
		[self setOpaque:NO];
		[self setHasShadow:YES];
        [self setDisplaysWhenScreenProfileChanges:YES];
        [self setReleasedWhenClosed:NO];
        [self setLevel:[[aController window] level]];
    }
    return self;
}

- (BOOL)canBecomeMainWindow { return NO; }

- (BOOL)canBecomeKeyWindow { return YES; }

- (void)moveToScreen:(NSScreen *)screen {
    NSRect winFrame = [screen frame];
    winFrame.size.width = WINDOW_WIDTH;
    winFrame.origin.x -= WINDOW_OFFSET;
    [self setFrame:winFrame display:NO];
}

- (void)orderOut:(id)sender {
    [[self parentWindow] removeChildWindow:self];
    [super orderOut:sender];
}

- (void)mouseEntered:(NSEvent *)theEvent {
    NSRect frame = [[self screen] frame];
    frame.size.width = WINDOW_WIDTH;
    frame.origin.x -= CONTENT_INSET;
    [self setFrame:frame display:YES animate:YES];
}

- (void)mouseExited:(NSEvent *)theEvent {
    NSRect frame = [[self screen] frame];
    frame.size.width = WINDOW_WIDTH;
    frame.origin.x -= WINDOW_OFFSET;
    [self setFrame:frame display:YES animate:YES];
    [[self parentWindow] makeKeyAndOrderFront:self];
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

@end


@implementation SKSideWindowContentView

// @@ FIXME: we might do some nicer drawing
- (void)drawRect:(NSRect)aRect {
    NSRect rect = [self bounds];
    [[NSColor windowBackgroundColor] set];
    [NSBezierPath fillRoundRectInRect:rect radius:CORNER_RADIUS];
}

@end
