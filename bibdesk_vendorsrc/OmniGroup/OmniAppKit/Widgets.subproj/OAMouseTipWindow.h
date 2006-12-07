// Copyright 2002-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OAMouseTipWindow.h,v 1.2 2003/02/21 19:57:23 kc Exp $

#import <AppKit/NSPanel.h>

@interface OAMouseTipWindow : NSPanel
{
}

// API

+ (void)showMouseTipWithTitle:(NSString *)aTitle;
+ (void)hideMouseTip;

@end
