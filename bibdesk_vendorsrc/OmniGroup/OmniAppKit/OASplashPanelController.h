// Copyright 1999-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OASplashPanelController.h,v 1.5 2003/01/15 22:51:32 kc Exp $

#import <OmniFoundation/OFObject.h>
#import <AppKit/NSNibDeclarations.h>
#import <Foundation/NSDate.h>

@class NSPanel;
@class OFScheduledEvent;

@interface OASplashPanelController : OFObject
{
    IBOutlet NSPanel *splashPanel;

    OFScheduledEvent *hideSplashPanelEvent;
}

- (NSTimeInterval) minimumSplashPanelDisplayTime;

- (void)showSplashPanel;
- (void)hideSplashPanel;

@end
