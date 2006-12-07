// Copyright 2003-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/ColorSync/NSColor-ColorSyncExtensions.h,v 1.4 2004/02/10 04:07:32 kc Exp $

#import <AppKit/NSColor.h>

@class OAColorProfile;

@interface NSColor (ColorSyncExtensions)

- (NSColor *)convertFromProfile:(OAColorProfile *)inProfile toProfile:(OAColorProfile *)outProfile;

- (void)setCoreGraphicsRGBValues;
- (void)setCoreGraphicsCMYKValues;
- (void)setCoreGraphicsGrayValues;

@end
