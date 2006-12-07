// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSTextField-OAExtensions.h,v 1.12 2004/02/10 04:07:34 kc Exp $

#import <AppKit/NSTextField.h>

@interface NSTextField (OAExtensions)
- (void)setStringValueAllowingNil: (NSString *) aString;
- (void)appendString:(NSString *)aString;

- (void)changeColorAsIfEnabledStateWas:(BOOL)newEnabled;
@end
