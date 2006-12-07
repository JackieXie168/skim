// Copyright 2002-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OAMouseTipView.h,v 1.7 2004/02/11 22:37:53 toon Exp $

#import <AppKit/NSView.h>
#import "OAMouseTipWindow.h"

@class NSString, NSDictionary;

@interface OAMouseTipView : NSView
{
    OAMouseTipStyle style;
    NSAttributedString *title;
}

// API

- (void)setStyle:(OAMouseTipStyle)aStyle;
- (void)setTitle:(NSString *)aTitle;
- (void)setAttributedTitle:(NSAttributedString *)aTitle;
- (NSDictionary *)textAttributes;

@end
