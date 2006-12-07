// Copyright 2003-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/SourceRelease_2005-10-03/OmniGroup/Frameworks/OmniFoundation/DataStructures.subproj/OFPoint.h 68913 2005-10-03 19:36:19Z kc $

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
