// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSUserDefaults-OFExtensions.h,v 1.7 2004/02/10 04:07:46 kc Exp $

// Don't try to read defaults in +didLoad, they might not be registered yet.  In +didLoad, register for OFControllerDidInitNotification, then read defaults when that's posted.

#import <Foundation/NSUserDefaults.h>

@class NSBundle, NSDictionary, NSString;

@interface NSUserDefaults (OFExtensions)
+ (void)registerItemName:(NSString *)itemName bundle:(NSBundle *)bundle description:(NSDictionary *)description;
- (void)autoSynchronize;
@end
