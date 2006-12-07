// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniBase/NSObject-OBObjectCompatibility.h,v 1.12 2004/02/10 04:07:39 kc Exp $

#import <Foundation/NSObject.h>

@class NSMutableDictionary;

@interface NSObject (OBObjectCompatibility)

- (NSMutableDictionary *)debugDictionary;
    // See also: - debugDictionary (OBObject)

- (NSString *)shortDescription;
    // See also: - shortDescription (OBObject)

@end
