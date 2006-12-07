// Copyright 1998-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OASecureTextField.h,v 1.8 2003/01/15 22:51:45 kc Exp $

#import <AppKit/NSSecureTextField.h>

// This class was used to work around some critical bugs in earlier implementations of NSSecureTextField.  We'll probably get rid of it soon, since Apple has fixed those bugs for Mac OS X.

@interface OASecureTextField : NSSecureTextField
{
}

@end
