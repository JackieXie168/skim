// Copyright 2002-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OAMouseTipWindow.h"

#import <AppKit/AppKit.h>
#import <OmniBase/rcsid.h>
#import "OAMouseTipView.h"

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OAMouseTipWindow.m,v 1.9 2004/02/11 22:37:53 toon Exp $");

@interface OAMouseTipWindow (Private)
@end

@implementation OAMouseTipWindow

static OAMouseTipWindow *mouseTipInstance = nil;
static OAMouseTipView *mouseTipView = nil;
static OAMouseTipStyle currentStyle = MouseTip_TooltipStyle;
static NSTimer *waitTimer = nil;

+ (void)initialize;
{
    if (!mouseTipInstance)
        mouseTipInstance = [[self alloc] init];
}

- (id)init;
{
    [super initWithContentRect:NSMakeRect(0.0, 0.0, 100.0, 20.0) styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
    [self setHasShadow:YES];
    [self useOptimizedDrawing:YES];
    [self setFloatingPanel:YES];
    [self setIgnoresMouseEvents:YES];
    [self setOpaque:NO];
    mouseTipView = [[OAMouseTipView alloc] initWithFrame:NSMakeRect(0,0,100,20)];
    [[self contentView] addSubview:mouseTipView];
    [mouseTipView setAutoresizingMask:NSViewHeightSizable | NSViewWidthSizable];
    return self;
}

#define OFFSET_FROM_MOUSE_LOCATION 10.0
#define TEXT_X_INSET 7.0
#define TEXT_Y_INSET 3.0
#define DISTANCE_FROM_ACTIVE_RECT 1.0

+ (void)setStyle:(OAMouseTipStyle)aStyle;
{
    currentStyle = aStyle;
    [mouseTipView setStyle:aStyle];
}

+ (void)showMouseTipWithTitle:(NSString *)aTitle;
{
    NSRect rect;
    
    rect.origin = [NSEvent mouseLocation];
    rect.origin.x += OFFSET_FROM_MOUSE_LOCATION + TEXT_X_INSET;
    rect.origin.y += OFFSET_FROM_MOUSE_LOCATION + TEXT_Y_INSET;
    rect.size = [aTitle sizeWithAttributes:[mouseTipView textAttributes]];
    rect = NSInsetRect(rect, -TEXT_X_INSET, -TEXT_Y_INSET);    
    [mouseTipView setTitle:aTitle];
    [mouseTipInstance setFrame:rect display:YES animate:NO];
    if (![mouseTipInstance isVisible])
        [mouseTipInstance orderFront:self];
}

+ (NSRect)_adjustRectToFitScreen:(NSRect)aFrame;
{
    NSPoint midPoint = NSMakePoint(NSMidX(aFrame), NSMidY(aFrame));
    NSArray *screens = [NSScreen screens];
    NSScreen *screen = nil;
    NSRect screenRect;
    int index = [screens count];
    
    while (index--) {
        screen = [screens objectAtIndex:index];
        screenRect = [screen visibleFrame];
        if (NSPointInRect(midPoint, screenRect))
            break;
    }
    
    if (NSHeight(aFrame) > NSHeight(screenRect))
        aFrame.origin.y = floor(NSMaxY(screenRect) - NSHeight(aFrame));
    else if (NSMaxY(aFrame) > NSMaxY(screenRect))
        aFrame.origin.y = floor(NSMaxY(screenRect) - NSHeight(aFrame));
    else if (NSMinY(aFrame) < NSMinY(screenRect))
        aFrame.origin.y = ceil(NSMinY(screenRect));
                            
    if (NSMaxX(aFrame) > NSMaxX(screenRect))
        aFrame.origin.x = floor(NSMaxX(screenRect) - NSWidth(aFrame));
    if (NSMinX(aFrame) < NSMinX(screenRect))
        aFrame.origin.x = ceil(NSMinX(screenRect));
    
    return aFrame;
}

static id nonretainedOwner;

+ (void)_timerFired;
{
//    NSLog(@"timer fired: %@", nonretainedOwner);
    waitTimer = nil;
    [mouseTipInstance orderFront:self];
}

+ (void)showMouseTipWithTitle:(NSString *)aTitle activeRect:(NSRect)activeRect edge:(NSRectEdge)onEdge delay:(float)delay;
{
    NSAttributedString *title = [[NSAttributedString alloc] initWithString:aTitle attributes:[mouseTipView textAttributes]];
    
    [self showMouseTipWithAttributedTitle:title activeRect:activeRect edge:onEdge delay:delay];
    [title release];
}

+ (void)showMouseTipWithAttributedTitle:(NSAttributedString *)aTitle activeRect:(NSRect)activeRect edge:(NSRectEdge)onEdge delay:(float)delay;
{
    NSRect rect;
    
    if (waitTimer != nil) {
        [waitTimer invalidate];
        waitTimer = nil;
    } 
    
    if (delay > 0.0) {
        if ([mouseTipInstance isVisible])
            [mouseTipInstance orderOut:self];
        waitTimer = [NSTimer scheduledTimerWithTimeInterval:delay target:self selector:@selector(_timerFired) userInfo:nil repeats:NO]; 
    }

    rect.size = [aTitle size];
    
    switch (onEdge) {
        case NSMinXEdge:
            rect.origin.x = NSMinX(activeRect) - NSWidth(rect) - TEXT_X_INSET - DISTANCE_FROM_ACTIVE_RECT;
            rect.origin.y = NSMidY(activeRect) - floor(NSHeight(rect)/2.0);
            break;
        case NSMinYEdge:
            rect.origin.x = NSMidX(activeRect) - floor(NSWidth(rect)/2.0);
            rect.origin.y = NSMinY(activeRect) - NSHeight(rect) - DISTANCE_FROM_ACTIVE_RECT - TEXT_Y_INSET;
            break;
        case NSMaxXEdge:
            rect.origin.x = NSMaxX(activeRect) + TEXT_X_INSET + DISTANCE_FROM_ACTIVE_RECT;
            rect.origin.y = NSMidY(activeRect) - floor(NSHeight(rect)/2.0);
            break;
        case NSMaxYEdge:
            rect.origin.x = NSMidX(activeRect) - floor(NSWidth(rect)/2.0);
            rect.origin.y = NSMaxY(activeRect) + DISTANCE_FROM_ACTIVE_RECT + TEXT_Y_INSET;
            break;
    }
    rect = NSInsetRect(rect, -TEXT_X_INSET, -TEXT_Y_INSET);    
   // rect = [self _adjustRectToFitScreen:rect];
    [mouseTipView setAttributedTitle:aTitle];
    [mouseTipInstance setFrame:rect display:YES animate:NO];
    
    if (delay <= 0.0)
        [mouseTipInstance orderFront:self];
}

+ (void)hideMouseTip;
{
    [mouseTipInstance orderOut:self];
}

+ (void)setOwner:(id)owner;
{
    nonretainedOwner = owner;
}

+ (void)hideMouseTipForOwner:(id)owner;
{
    if (nonretainedOwner == owner) {
        if (waitTimer != nil) {
            //NSLog(@"hiding tip - cancel timer: %@", nonretainedOwner);
            [waitTimer invalidate];
            waitTimer = nil;
        } else {
           // NSLog(@"hiding tip: %@", nonretainedOwner);
       }
        nonretainedOwner = nil;
        [mouseTipInstance orderOut:self];
    } else {
        // NSLog(@"hide ignored - not owner %@ != %@", nonretainedOwner, owner);
    }
}

@end

@implementation OAMouseTipWindow (Private)
@end
