// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/DataStructures.subproj/OFTrieBucket.h 68913 2005-10-03 19:36:19Z kc $

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
