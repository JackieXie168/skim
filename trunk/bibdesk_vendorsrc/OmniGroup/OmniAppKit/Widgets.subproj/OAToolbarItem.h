// Copyright 2001-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OAToolbarItem.h 68913 2005-10-03 19:36:19Z kc $

#import <AppKit/NSToolbarItem.h>

@interface OAToolbarItem : NSToolbarItem
{
    NSImage *_optionKeyImage;
    NSString *_optionKeyLabel;
    NSString *_optionKeyToolTip;
    SEL _optionKeyAction;
    
    id _delegate;
    BOOL inOptionKeyState;
}

- (id)delegate;
- (void)setDelegate:(id)delegate;
    // Right now, the only thing we're doing with our delegate is using it as a validator; AppKit's auto-validation scheme can be useful for changing more attributes than just enabled/disabled, but it currently only works for items that have a target and action, which many custom toolbar items don't.

- (NSImage *)optionKeyImage;
- (void)setOptionKeyImage:(NSImage *)image;
- (NSString *)optionKeyLabel;
- (void)setOptionKeyLabel:(NSString *)label;
- (NSString *)optionKeyToolTip;
- (void)setOptionKeyToolTip:(NSString *)toolTip;
    // Show an alternate image, label, and tooltop if the user holds the option/alternate key.

- (SEL)optionKeyAction;
- (void)setOptionKeyAction:(SEL)action;
    // And perform an alternate action when clicked in the option-key-down state
@end
