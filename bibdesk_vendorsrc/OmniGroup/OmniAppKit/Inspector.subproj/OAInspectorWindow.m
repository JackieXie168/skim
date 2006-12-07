// Copyright 2002-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import "OAInspectorWindow.h"

#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>
#import <OmniBase/rcsid.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Inspector.subproj/OAInspectorWindow.m,v 1.18 2003/02/25 07:11:51 wjs Exp $");

@interface OAInspectorWindow (Private)
@end

@implementation OAInspectorWindow

- (id)initWithContentRect:(NSRect)contentRect styleMask:(unsigned int)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag;
{
    if (![super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag])
        return nil;
    [self setHasShadow:YES];
    [self useOptimizedDrawing:YES];
    [self setLevel:NSFloatingWindowLevel];
    return self;
}


// NSResponder subclass

- (void)keyDown:(NSEvent *)anEvent {
    NSWindow *mainWindow = [[NSApplication sharedApplication] mainWindow];
    if (mainWindow)
        [[mainWindow firstResponder] keyDown:anEvent];
    else
        [super keyDown:anEvent];
}

- (void)keyUp:(NSEvent *)anEvent {
    NSWindow *mainWindow = [[NSApplication sharedApplication] mainWindow];
    if (mainWindow)
        [[mainWindow firstResponder] keyUp:anEvent];
    else
        [super keyUp:anEvent];
}

/*
 - (NSResponder *)nextResponder;
{
    NSWindow *mainWindow = [[NSApplication sharedApplication] mainWindow];
    if (mainWindow != nil)
        return [mainWindow firstResponder];
    else
        return [super nextResponder];
}
*/

// NSWindow subclass

- (BOOL)canBecomeKeyWindow;
{
    return YES;
}

- (BOOL)_hasActiveControls; // private Apple method
{
    return YES;
}

- (NSTimeInterval)animationResizeTime:(NSRect)newFrame;
{
    return [super animationResizeTime:newFrame] * 0.33;
}

- (void)setFrame:(NSRect)newFrame display:(BOOL)display animate:(BOOL)animate;
{
    NSRect currentFrame = [self frame];
    
    if (currentFrame.size.height != newFrame.size.height || currentFrame.size.width != newFrame.size.width)
        newFrame = [[self delegate] windowWillResizeFromFrame:currentFrame toFrame:newFrame];
    [super setFrame:newFrame display:display animate:animate];
}

@end

@implementation OAInspectorWindow (Private)
@end
