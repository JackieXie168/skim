// Copyright 2002-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import "OAInspectorResizer.h"

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <OmniBase/OmniBase.h>
#import <OmniFoundation/OmniFoundation.h>

#import "NSImage-OAExtensions.h"

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Inspector.subproj/OAInspectorResizer.m,v 1.2 2003/02/12 22:00:56 kc Exp $")

@implementation OAInspectorResizer

static NSImage *resizerImage = nil;

+ (void)initialize;
{
    OBINITIALIZE;

    resizerImage = [[NSImage imageNamed:@"WindowResize" inBundle:[self bundle]] retain]; 
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent;
{
    return YES;
}

- (void)drawRect:(NSRect)rect;
{
    [resizerImage compositeToPoint:_bounds.origin operation:NSCompositeSourceOver fraction:1.0];
}

- (void)mouseDown:(NSEvent *)event;
{
    NSWindow *window = [self window];
    NSRect windowFrame = [window frame];
    NSPoint topLeft = NSMakePoint(NSMinX(windowFrame), NSMaxY(windowFrame));
    NSSize startingSize = windowFrame.size;
    NSPoint startingMouse = [window convertBaseToScreen:[event locationInWindow]];
    
    while (1) {
        NSPoint point, change;
        
        event = [NSApp nextEventMatchingMask:NSLeftMouseDraggedMask|NSLeftMouseUpMask untilDate:[NSDate distantFuture] inMode:NSEventTrackingRunLoopMode dequeue:NO];

        if ([event type] == NSLeftMouseUp)
            break;
           
        [NSApp nextEventMatchingMask:NSLeftMouseDraggedMask untilDate:[NSDate distantFuture] inMode:NSEventTrackingRunLoopMode dequeue:YES];
        point = [window convertBaseToScreen:[event locationInWindow]];
        change.x = startingMouse.x - point.x;
        change.y = startingMouse.y - point.y;
        windowFrame.size.height = startingSize.height + change.y;
        windowFrame.size.width = startingSize.width - change.x;
        windowFrame.origin.y = topLeft.y - windowFrame.size.height;
        [window setFrame:windowFrame display:YES animate:NO];
    }
}

@end
