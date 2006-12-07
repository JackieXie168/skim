// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniAppKit/OABrowserCell.h>

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>
#import <OmniFoundation/OmniFoundation.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OABrowserCell.m,v 1.12 2004/02/10 04:07:37 kc Exp $")

@implementation OABrowserCell

- (void) dealloc;
{
    [userInfo release];
    [super dealloc];
}

- (NSDictionary *) userInfo;
{
    return userInfo;
}

- (void)setUserInfo: (NSDictionary *) newInfo;
{
    if (userInfo != newInfo) {
	[userInfo release];
	userInfo = [newInfo copy];
    }
}

@end
