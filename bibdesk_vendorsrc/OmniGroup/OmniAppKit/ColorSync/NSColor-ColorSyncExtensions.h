// Copyright 2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/ColorSync/NSColor-ColorSyncExtensions.h,v 1.2 2003/04/08 20:44:53 kc Exp $

#import <AppKit/NSColor.h>

@class OAColorProfile;

@interface NSColor (ColorSyncExtensions)

- (NSColor *)convertFromProfile:(OAColorProfile *)inProfile toProfile:(OAColorProfile *)outProfile;

- (void)setCoreGraphicsRGBValues;
- (void)setCoreGraphicsCMYKValues;
- (void)setCoreGraphicsGrayValues;

@end
