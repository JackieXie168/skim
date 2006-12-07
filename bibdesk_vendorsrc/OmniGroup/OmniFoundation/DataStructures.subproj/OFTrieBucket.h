// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/DataStructures.subproj/OFTrieBucket.h,v 1.9 2003/01/15 22:51:55 kc Exp $

#import <OmniBase/OBObject.h>

#import <Foundation/NSString.h> // For unichar

@interface OFTrieBucket : OBObject
{
@public
    unichar *lowerCharacters;
    unichar *upperCharacters;
}

- (void)setRemainingLower:(unichar *)lower upper:(unichar *)upper length:(int)aLength;

@end
