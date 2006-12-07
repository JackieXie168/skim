// Copyright 2002-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OASwitcherBarButtonCell.h,v 1.3 2004/02/10 04:07:38 kc Exp $

#import <AppKit/NSButtonCell.h>

typedef enum _OASwitcherBarCellLocation {
    OASwitcherBarLeft = 0,
    OASwitcherBarMiddle = 1,
    OASwitcherBarRight = 2
} OASwitcherBarCellLocation;
    
@interface OASwitcherBarButtonCell : NSButtonCell
{
    OASwitcherBarCellLocation cellLocation;
}

- (void)setCellLocation:(OASwitcherBarCellLocation)location;

@end
