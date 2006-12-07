// Copyright 2002-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import "OADynamicInspectorMenuItem.h"

#import <Foundation/Foundation.h>
#import <OmniBase/rcsid.h>
#import "OAInspectorGroup.h"

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Inspector.subproj/OADynamicInspectorMenuItem.m,v 1.2 2003/01/15 22:51:33 kc Exp $");

@interface OADynamicInspectorMenuItem (Private)
@end

@implementation OADynamicInspectorMenuItem

- (void)awakeFromNib;
{
    [OAInspectorGroup setDynamicMenuPlaceholder:self];
}

@end

@implementation OADynamicInspectorMenuItem (Private)
@end
