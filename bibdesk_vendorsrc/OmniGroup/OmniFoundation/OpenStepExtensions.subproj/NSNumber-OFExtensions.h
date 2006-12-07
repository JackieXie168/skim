// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSNumber-OFExtensions.h,v 1.11 2004/02/10 04:07:46 kc Exp $

#import <Foundation/NSValue.h>

@interface NSNumber (OFExtensions)
- initWithString:(NSString *)aString;
@end

// This class exists due to Radar #3478597 where NaN numbers aren't correctly compared.  This returns something that is truly 'Not a Number' and thus the CF comparison works out better.  Of course, it really isn't a NSNumber, so care must be taken that it isn't used as one.
@interface OFNaN : NSObject
+ (OFNaN *)sharedNaN;
@end
