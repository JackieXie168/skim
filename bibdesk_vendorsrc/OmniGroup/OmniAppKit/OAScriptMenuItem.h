// Copyright 2002-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OAScriptMenuItem.h,v 1.4 2003/01/15 22:51:31 kc Exp $

#import <AppKit/NSMenuItem.h>

@class NSDate, NSArray;

@interface OAScriptMenuItem : NSMenuItem
{
    NSArray *cachedScripts;
    NSDate *cachedScriptsDate;
}

@end
