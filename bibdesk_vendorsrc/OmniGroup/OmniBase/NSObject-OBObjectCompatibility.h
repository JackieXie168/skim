// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniBase/NSObject-OBObjectCompatibility.h,v 1.10 2003/01/15 22:51:47 kc Exp $

#import <Foundation/NSObject.h>

@class NSMutableDictionary;

@interface NSObject (OBObjectCompatibility)

- (NSMutableDictionary *)debugDictionary;
    // See also: - debugDictionary (OBObject)

- (NSString *)shortDescription;
    // See also: - shortDescription (OBObject)

@end
