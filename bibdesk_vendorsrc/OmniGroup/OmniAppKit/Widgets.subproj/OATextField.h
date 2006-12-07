// Copyright 1998-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OATextField.h,v 1.7 2003/01/15 22:51:45 kc Exp $

#import <AppKit/NSTextField.h>
#import <AppKit/NSNibDeclarations.h> // For IBOutlet

@interface OATextField : NSTextField
{
    IBOutlet NSTextField *label;
}

@end
