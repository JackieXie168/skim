// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSSplitView-OAExtensions.h,v 1.10 2004/02/10 04:07:34 kc Exp $

#import <AppKit/NSSplitView.h>

@interface NSSplitView (OAExtensions)
- (float)fraction;
- (void)setFraction:(float)newFract;
- (int)topPixels;
- (void)setTopPixels:(int)newTop;
- (int)bottomPixels;
- (void)setBottomPixels:(int)newBottom;
@end
