// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSScrollView-OAExtensions.h,v 1.14 2004/02/10 04:07:34 kc Exp $

#import <AppKit/NSScrollView.h>
#import <AppKit/NSImageCell.h>	// for NSImageAlignment


@interface NSScrollView (OAExtensions)

- (void)freeGStates; /* Frees the clip view's gstate also */

- (NSImageAlignment)documentViewAlignment;
- (void)setDocumentViewAlignment:(NSImageAlignment)value;

@end
