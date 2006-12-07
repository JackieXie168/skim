// Copyright 2001-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import "NSToolbarItem-OAExtensions.h"

#import <Foundation/Foundation.h>
#import <OmniBase/rcsid.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSToolbarItem-OAExtensions.m,v 1.3 2003/01/15 22:51:39 kc Exp $");

@implementation NSToolbarItem (OAExtensions)

/*
These methods allow you to call the same labelling selectors on toolbar items as on menu items.  This can make menu validation/toolbar validation code simpler.
*/
- (NSString *) title;
{
    return [self label];
}

- (void) setTitle: (NSString *) title;
{
    [self setLabel: title];
}

@end
