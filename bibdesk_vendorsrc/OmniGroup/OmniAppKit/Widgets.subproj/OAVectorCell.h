// Copyright 2003-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OAVectorCell.h,v 1.3 2004/02/10 04:07:38 kc Exp $

#import <AppKit/NSActionCell.h>

@interface OAVectorCell : NSActionCell
{
    NSImageCell *_imageCell; // used for drawing gray bezel
    BOOL         _isMultiple;
}

- (void)setIsMultiple:(BOOL)flag;
- (BOOL)isMultiple;

@end
