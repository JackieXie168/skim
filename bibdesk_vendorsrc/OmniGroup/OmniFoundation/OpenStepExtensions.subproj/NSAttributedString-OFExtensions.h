// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSAttributedString-OFExtensions.h,v 1.12 2004/02/10 04:07:45 kc Exp $

#import <Foundation/NSAttributedString.h>

@interface NSAttributedString (OFExtensions)

- initWithString:(NSString *)str attributeName:(NSString *)attributeName attributeValue:(id)attributeValue;
    // This can be used to initialize an attributed string when you only want to set one attribute:  this way, you don't have to build an NSDictionary of attributes yourself.

- (NSArray *)componentsSeparatedByString:(NSString *)aString;

@end


@interface NSMutableAttributedString (OFExtensions)
- (void)appendString:(NSString *)string attributes:(NSDictionary *)attributes;
- (void)appendString:(NSString *)string;
@end
