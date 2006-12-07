// Copyright 2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import "OAInspectorGroupAnimatedMergeController.h"

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <OmniBase/rcsid.h>

#import "OAInspectorGroupAnimatedMergeView.h"

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Inspector.subproj/OAInspectorGroupAnimatedMergeController.m,v 1.4 2003/04/01 01:49:29 toon Exp $");

@interface OAInspectorGroupAnimatedMergeController (Private)
@end

@implementation OAInspectorGroupAnimatedMergeController

static OAInspectorGroupAnimatedMergeController *sharedInspectorGroupAnimatedMergeController = nil;

+ (OAInspectorGroupAnimatedMergeController *)sharedInspectorGroupAnimatedMergeController;
{
    if (sharedInspectorGroupAnimatedMergeController != nil)
        return sharedInspectorGroupAnimatedMergeController;

    sharedInspectorGroupAnimatedMergeController = [[OAInspectorGroupAnimatedMergeController alloc] init];
    return sharedInspectorGroupAnimatedMergeController;
}

    // Init and dealloc

- init;
{
    if ([super init] == nil)
        return nil;

    return self;
}

- (void)dealloc; // not really gonna happen, but I try to be good.
{
    [throbTimer invalidate];
    [throbTimer release];
    [shadowWindow release];
    [animatedMergeView release];
    [super dealloc];
}


// API

#define FUZZ (32.0)

- (void)animateWithFirstGroupRect:(NSRect)newARect andSecondGroupRect:(NSRect)newBRect atLevel:(int)windowLevel;
{
    NSRect windowFrame;
    NSRect unionRect = NSUnionRect(newARect, newBRect);
    float distanceIfAIsAboveB = NSMinY(newARect) - NSMaxY(newBRect);
    float distanceIfBIsAboveA = NSMinY(newBRect) - NSMaxY(newARect);
    NSRect upperRect, lowerRect;

    if (ABS(distanceIfAIsAboveB) < ABS(distanceIfBIsAboveA)) {
        // the bottom edge of A wants to bond to the top edge of B
        windowFrame = NSMakeRect(NSMinX(unionRect), MIN(NSMaxY(newBRect), NSMinY(newARect)) - FUZZ, NSWidth(unionRect), ABS(distanceIfAIsAboveB) + 2 * FUZZ);
        upperRect = newARect; lowerRect = newBRect;
    } else {
        // the bottom edge of B wants to bond to the top edge of A
        windowFrame = NSMakeRect(NSMinX(unionRect), MIN(NSMaxY(newARect), NSMinY(newBRect)) - FUZZ, NSWidth(unionRect), ABS(distanceIfBIsAboveA) + 2 * FUZZ);
        upperRect = newBRect; lowerRect = newARect;
    }

    if (shadowWindow == nil) {
        shadowWindow = [[NSWindow alloc] initWithContentRect:windowFrame styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
        [shadowWindow setReleasedWhenClosed:NO];
        [shadowWindow setHasShadow:NO];
        [shadowWindow setOpaque:NO];

        animatedMergeView = [[OAInspectorGroupAnimatedMergeView alloc] initWithFrame:NSZeroRect];
        [shadowWindow setContentView:animatedMergeView];
    }

    [shadowWindow setLevel:windowLevel];
    [animatedMergeView setUpperGroupRect:upperRect lowerGroupRect:lowerRect windowFrame:windowFrame];
    [shadowWindow setFrame:windowFrame display:YES];

    if (![shadowWindow isVisible])
        [shadowWindow orderBack:nil];

    if (throbTimer == nil) {
        throbTimer = [[NSTimer timerWithTimeInterval:0.05 target:animatedMergeView selector:@selector(throbOnce:) userInfo:nil repeats:YES] retain];
        [[NSRunLoop currentRunLoop] addTimer:throbTimer forMode:NSEventTrackingRunLoopMode];
    }
}

- (void)closeWindow;
{
    [throbTimer invalidate];
    [throbTimer release];
    throbTimer = nil;
    [shadowWindow orderOut:nil];
}

@end

@implementation OAInspectorGroupAnimatedMergeController (NotificationsDelegatesDatasources)
@end

@implementation OAInspectorGroupAnimatedMergeController (Private)
@end
