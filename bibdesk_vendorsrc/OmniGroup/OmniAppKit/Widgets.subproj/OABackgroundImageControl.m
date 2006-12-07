// Copyright 2003-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OABackgroundImageControl.h"

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <OmniBase/OmniBase.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OABackgroundImageControl.m,v 1.3 2004/02/10 04:07:36 kc Exp $");

@interface OABackgroundImageControl (Private)
- (void)_rebuildBackgroundImage;
- (void)_drawBackgroundImage;
@end

@implementation OABackgroundImageControl

// Init and dealloc

- (void)dealloc;
{
    [backgroundImage release];
    
    [super dealloc];
}

// NSView subclass

- (void)setFrameSize:(NSSize)newFrameSize;
{
    [super setFrameSize:newFrameSize];
    [self rebuildBackgroundImage];
}

- (void)drawRect:(NSRect)rect;
{    
    if (!backgroundImageControlFlags.backgroundIsValid)
        [self _rebuildBackgroundImage];
        
    // Draw background
    [self _drawBackgroundImage];
    
    // Draw foreground
    [self drawForegroundRect:rect];
    
    // Draw the focus ring when a subview of this view is the first responder and the window is key
    if (!backgroundImageControlFlags.doNotDrawFocusRing) {
        NSWindow *window;
        id firstResponder;
        
        window = [self window];
        firstResponder = [window firstResponder];
        if ([firstResponder isKindOfClass:[NSView class]] && [firstResponder isDescendantOf:self] && [window isKeyWindow]) {
            NSSetFocusRingStyle(NSFocusRingOnly);
            [self _drawBackgroundImage];
        }
        [self setKeyboardFocusRingNeedsDisplayInRect:[self bounds]];
    }
    
    [super drawRect:rect];
}


// API

- (void)rebuildBackgroundImage;
{
    backgroundImageControlFlags.backgroundIsValid = NO;
    [self setNeedsDisplay:YES];
}

- (BOOL)drawsFocusRing;
{
    return backgroundImageControlFlags.doNotDrawFocusRing;
}

- (void)setDrawsFocusRing:(BOOL)flag;
{
    backgroundImageControlFlags.doNotDrawFocusRing = flag;
}

// Subclasses only

- (void)drawBackgroundImageForBounds:(NSRect)bounds;
{
    OBRequestConcreteImplementation(self, _cmd);
}

- (void)drawForegroundRect:(NSRect)bounds;
{
    // Don't request a concrete implementation here, because subclasses might not want to draw anything on top of the background image
}

@end

@implementation OABackgroundImageControl (NotificationsDelegatesDatasources)
@end

@implementation OABackgroundImageControl (Private)

- (void)_rebuildBackgroundImage;
{
    NSRect bounds;
    
    OBASSERT(!backgroundImageControlFlags.backgroundIsValid);
    
    bounds = [self bounds];
    
    // Only reallocate the background image if it's nil or if it's a different size than the view
    if (backgroundImage == nil || !NSEqualSizes([backgroundImage size], bounds.size)) {
        [backgroundImage release];
        backgroundImage = [[NSImage alloc] initWithSize:bounds.size];
    }
    
    [backgroundImage lockFocus];
    [self drawBackgroundImageForBounds:bounds];
    [backgroundImage unlockFocus];
    
    backgroundImageControlFlags.backgroundIsValid = YES;
}

- (void)_drawBackgroundImage;
{
    [backgroundImage compositeToPoint:NSMakePoint(0, 0) operation:NSCompositeSourceOver];
}

@end
