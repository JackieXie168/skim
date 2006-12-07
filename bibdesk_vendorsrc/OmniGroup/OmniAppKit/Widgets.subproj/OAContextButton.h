// Copyright 2003-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OAContextButton.h,v 1.9 2004/02/10 04:07:37 kc Exp $

#import <AppKit/NSButton.h>
#import <AppKit/NSNibDeclarations.h>

@class NSMenu;

@interface OAContextButton : NSButton
{
    id delegate;
}

+ (NSImage *)actionImage;
+ (NSImage *)miniActionImage;

- (BOOL)validate;

@end

@interface NSObject (OAContextButtonDelegate)
- (NSMenu *)menuForContextButton:(OAContextButton *)contextButton;
- (NSView *)targetViewForContextButton:(OAContextButton *)contextButton;
@end
