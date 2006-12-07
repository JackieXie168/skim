// Copyright 2002-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OASwitcherBarMatrix.h,v 1.4 2004/02/10 22:06:20 wiml Exp $

#import <AppKit/NSMatrix.h>

@interface OASwitcherBarMatrix : NSMatrix
{
    struct {
        unsigned int registeredForKeyNotifications: 1;
    } switcherBarFlags;
}

// Implements a control like the view switcher toolbar item or the "Import/Oraganize/Edit/etc." bar in iPhoto. Looks best if you keep it to a single row.

@end
