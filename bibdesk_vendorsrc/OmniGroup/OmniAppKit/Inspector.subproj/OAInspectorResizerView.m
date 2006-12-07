// Copyright 2002-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import "OAInspectorResizerView.h"

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <OmniBase/OmniBase.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Inspector.subproj/OAInspectorResizerView.m,v 1.6 2003/01/15 22:51:34 kc Exp $")

@interface NSCursor (privateMethods)
+ (NSCursor *)_verticalResizeCursor;
@end

@implementation OAInspectorResizerView

- (id)initWithFrame:(NSRect)frame;
{
    [super initWithFrame:frame];
    minimumHeight = 0.0;
    return self;
}

- (void)setEnabled:(BOOL)yn;
{
    // ignore -- don't allow disabling
}

- (void)setViewToResize:(NSView *)aView;
{
    viewToResize = aView;
}

- (void)setMinimumHeight:(float)aHeight;
{
    minimumHeight = aHeight;
}

- (void)drawRect:(NSRect)rect 
{
    [super drawDividerInRect:_bounds];
}

- (void)mouseDown:(NSEvent *)event;
{
    float startingY, currentY;
    NSSize originalSize, size;
    
    if (!viewToResize) 
        viewToResize = [self superview];
    if (!minimumHeight)
        minimumHeight = [viewToResize frame].size.height;
    
    originalSize = [viewToResize frame].size;
    size = originalSize;
    startingY = [[self window] convertBaseToScreen:[event locationInWindow]].y;
    isResizing = YES;
    [self setNeedsDisplay:YES];
    
    while (1) {
        event = [NSApp nextEventMatchingMask:NSLeftMouseDraggedMask|NSLeftMouseUpMask untilDate:[NSDate distantFuture] inMode:NSEventTrackingRunLoopMode dequeue:NO];
        
        if ([event type] == NSLeftMouseUp)
            break;
           
        [NSApp nextEventMatchingMask:NSLeftMouseDraggedMask untilDate:[NSDate distantFuture] inMode:NSEventTrackingRunLoopMode dequeue:YES];
        currentY = [[self window] convertBaseToScreen:[event locationInWindow]].y;
        size.height = MAX(originalSize.height + (startingY - currentY), minimumHeight);
        [viewToResize setFrameSize:size];
    }
    isResizing = NO;
    [self setNeedsDisplay:YES];
}

- (void)resetCursorRects;
{
    [self addCursorRect:_bounds cursor:[NSCursor _verticalResizeCursor]];
}

@end
