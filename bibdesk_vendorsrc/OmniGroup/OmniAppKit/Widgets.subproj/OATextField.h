// Copyright 1998-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OATextField.h,v 1.9 2004/02/10 04:07:38 kc Exp $

#import <AppKit/NSTextField.h>
#import <AppKit/NSNibDeclarations.h> // For IBOutlet

@interface OATextField : NSTextField
{
    IBOutlet NSTextField *label;
}

@end
