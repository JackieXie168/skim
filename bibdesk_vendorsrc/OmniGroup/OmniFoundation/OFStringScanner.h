// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OFStringScanner.h,v 1.26 2003/01/15 22:51:50 kc Exp $

#import <OmniFoundation/OFCharacterScanner.h>

@interface OFStringScanner : OFCharacterScanner
{
    NSString *targetString;
}

- initWithString:(NSString *)aString;
    // Scan the specified string.  Retains string for efficiency, so don't change it.

@end

