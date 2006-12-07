// Copyright 2003-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/ColorSync/NSImage-ColorSyncExtensions.h,v 1.4 2004/02/10 04:07:32 kc Exp $

#import <AppKit/NSImage.h>

@class OAColorProfile;

@interface NSImage (ColorSyncExtensions)

- (BOOL)containsProfile;
- (void)convertFromProfile:(OAColorProfile *)inProfile toProfile:(OAColorProfile *)outProfile;

@end
