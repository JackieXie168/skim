// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/SourceRelease_2005-10-03/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSNumber-OFExtensions.h 68913 2005-10-03 19:36:19Z kc $

#import <Foundation/NSValue.h>

@interface NSNumber (OFExtensions)
- initWithString:(NSString *)aString;
@end

// This class exists due to Radar #3478597 where NaN numbers aren't correctly compared.  This returns something that is truly 'Not a Number' and thus the CF comparison works out better.  Of course, it really isn't a NSNumber, so care must be taken that it isn't used as one.
@interface OFNaN : NSObject
+ (OFNaN *)sharedNaN;
@end
