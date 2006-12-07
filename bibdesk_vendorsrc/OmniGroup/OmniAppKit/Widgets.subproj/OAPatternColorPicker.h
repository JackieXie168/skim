// Copyright 2003-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OAPatternColorPicker.h,v 1.3 2004/02/10 04:07:37 kc Exp $

#import <AppKit/NSColorPicker.h>

@interface OAPatternColorPicker : NSColorPicker <NSColorPickingCustom>
{
    IBOutlet NSView      *view;
    IBOutlet NSImageView *imageView;
}

- (IBAction)imageChanged:(id)sender;

@end
