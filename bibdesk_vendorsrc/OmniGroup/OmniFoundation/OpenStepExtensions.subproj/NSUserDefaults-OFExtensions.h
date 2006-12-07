// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSUserDefaults-OFExtensions.h 68913 2005-10-03 19:36:19Z kc $

// Don't try to read defaults in +didLoad, they might not be registered yet.  In +didLoad, register for OFControllerDidInitNotification, then read defaults when that's posted.

#import <Foundation/NSUserDefaults.h>

@class NSBundle, NSDictionary, NSString;

@interface NSUserDefaults (OFExtensions)
+ (void)registerItemName:(NSString *)itemName bundle:(NSBundle *)bundle description:(NSDictionary *)description;
- (void)autoSynchronize;
@end
