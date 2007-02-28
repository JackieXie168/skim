// Copyright 2003-2006 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/DataStructures.subproj/OFPoint.h 79079 2006-09-07 22:35:32Z kc $

#import <Foundation/NSObject.h>
#import <Foundation/NSGeometry.h>

@interface OFPoint : NSObject <NSCopying, NSCoding>
{
    NSPoint _value;
}

+ (OFPoint *)pointWithPoint:(NSPoint)point;

- initWithPoint:(NSPoint)point;
- initWithString:(NSString *)string;

- (NSPoint)point;

@end

// Value transformer
#if MAC_OS_X_VERSION_10_3 <= MAC_OS_X_VERSION_MAX_ALLOWED
extern NSString *OFPointToPropertyListTransformerName;
#endif
