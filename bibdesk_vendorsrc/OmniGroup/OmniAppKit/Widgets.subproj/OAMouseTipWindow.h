// Copyright 2002-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OAMouseTipWindow.h,v 1.7 2004/02/11 22:37:53 toon Exp $

#import <AppKit/NSPanel.h>

typedef enum {
    MouseTip_TooltipStyle, MouseTip_ExposeStyle, MouseTip_DockStyle
} OAMouseTipStyle;

@interface OAMouseTipWindow : NSPanel
{
}

// API

+ (void)setStyle:(OAMouseTipStyle)aStyle;

+ (void)showMouseTipWithTitle:(NSString *)aTitle;
+ (void)showMouseTipWithTitle:(NSString *)aTitle activeRect:(NSRect)activeRect edge:(NSRectEdge)onEdge delay:(float)delay;
+ (void)showMouseTipWithAttributedTitle:(NSAttributedString *)aTitle activeRect:(NSRect)activeRect edge:(NSRectEdge)onEdge delay:(float)delay;
+ (void)hideMouseTip;

// A way to keep objects from hiding the tip if it is now being used by someone else 
// +hideMouseTipForOwner: does nothing if the owner doesn't match the last +setOwner call
+ (void)setOwner:(id)owner;
+ (void)hideMouseTipForOwner:(id)owner;

@end
