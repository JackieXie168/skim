// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OFStringScanner.h,v 1.28 2004/02/10 04:07:41 kc Exp $

#import <OmniFoundation/OFCharacterScanner.h>

@interface OFStringScanner : OFCharacterScanner
{
    NSString *targetString;
}

- initWithString:(NSString *)aString;
    // Scan the specified string.  Retains string for efficiency, so don't change it.

@end

