// Copyright 1999-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import <OmniAppKit/OASplashPanelController.h>

#import <Foundation/Foundation.h>
#import <AppKit/NSPanel.h>
#import <AppKit/NSApplication.h>
#import <OmniBase/OmniBase.h>
#import <OmniFoundation/OmniFoundation.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OASplashPanelController.m,v 1.6 2003/01/15 22:51:32 kc Exp $")

@implementation OASplashPanelController

- init;
{
    [super init];

    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(applicationWillFinishLaunching:)
                                                 name: NSApplicationWillFinishLaunchingNotification
                                               object: nil];

    return self;
}

- (void) dealloc;
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    [super dealloc];
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification;
{
    // If this is in -init, OmniPDF crashes though OmniImage doesn't.  I guess some nibs just aren't ready to be loaded this early, while others are.
    [self showSplashPanel];
}

- (NSTimeInterval)minimumSplashPanelDisplayTime;
{
    return 3.0;
}

- (void)showSplashPanel;
{
    [splashPanel center];
    [splashPanel setLevel:NSFloatingWindowLevel];
    [splashPanel makeKeyAndOrderFront: nil];
    
    hideSplashPanelEvent = [[[OFScheduler mainScheduler] scheduleSelector:@selector(hideSplashPanel)
                                                                 onObject:self
                                                               withObject:nil
                                                                afterTime:[self minimumSplashPanelDisplayTime]] retain];
}

- (void)hideSplashPanel;
{
    [splashPanel orderOut:nil];
    [hideSplashPanelEvent release];
    hideSplashPanelEvent = nil;
}

@end
