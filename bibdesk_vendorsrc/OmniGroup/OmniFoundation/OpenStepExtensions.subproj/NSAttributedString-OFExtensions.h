// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSAttributedString-OFExtensions.h,v 1.8 2003/01/15 22:51:58 kc Exp $

#import <Foundation/NSAttributedString.h>

@interface NSAttributedString (OFExtensions)

- initWithString:(NSString *)str attributeName:(NSString *)attributeName attributeValue:(id)attributeValue;
    // This can be used to initialize an attributed string when you only want to set one attribute:  this way, you don't have to build an NSDictionary of attributes yourself.

- (NSArray *)componentsSeparatedByString:(NSString *)aString;

@end
