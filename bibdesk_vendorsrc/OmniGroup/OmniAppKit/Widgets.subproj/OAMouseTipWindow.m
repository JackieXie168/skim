// Copyright 2002-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import "OAMouseTipWindow.h"

#import <AppKit/AppKit.h>
#import <OmniBase/rcsid.h>
#import "OAMouseTipView.h"

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OAMouseTipWindow.m,v 1.3 2003/02/21 19:57:23 kc Exp $");

@interface OAMouseTipWindow (Private)
@end

@implementation OAMouseTipWindow

static OAMouseTipWindow *mouseTipInstance = nil;
static OAMouseTipView *mouseTipView = nil;

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
    [self setOpaque:NO];
    mouseTipView = [[OAMouseTipView alloc] initWithFrame:NSMakeRect(0,0,100,20)];
    [[self contentView] addSubview:mouseTipView];
    [mouseTipView setAutoresizingMask:NSViewHeightSizable | NSViewWidthSizable];
    return self;
}

#define OFFSET_FROM_MOUSE_LOCATION 10.0
#define TEXT_X_INSET 7.0
#define TEXT_Y_INSET 3.0

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

+ (void)hideMouseTip;
{
    [mouseTipInstance orderOut:self];
}

@end

@implementation OAMouseTipWindow (Private)
@end
