// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSUserDefaults-OFExtensions.h,v 1.5 2003/01/15 22:52:01 kc Exp $

// Don't try to read defaults in +didLoad, they might not be registered yet.  In +didLoad, register for OFControllerDidInitNotification, then read defaults when that's posted.

#import <Foundation/NSUserDefaults.h>

@class NSBundle, NSDictionary, NSString;

@interface NSUserDefaults (OFExtensions)
+ (void)registerItemName:(NSString *)itemName bundle:(NSBundle *)bundle description:(NSDictionary *)description;
- (void)autoSynchronize;
@end
