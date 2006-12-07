// Copyright 2000-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSFontManager-OAExtensions.h,v 1.5 2003/01/15 22:51:37 kc Exp $

#import <AppKit/NSFontManager.h>

@interface NSFontManager (OAExtensions)
- (NSFont *)closestFontWithFamily:(NSString *)family traits:(NSFontTraitMask)traits size:(float)size;
@end
