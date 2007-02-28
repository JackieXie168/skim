// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/DataStructures.subproj/OFNull.h 68913 2005-10-03 19:36:19Z kc $

#import <OmniFoundation/OFObject.h>
#import <OmniFoundation/FrameworkDefines.h>

#define OFNOTNULL(ptr)   ((ptr) != nil && ![ptr isNull])
#define OFISNULL(ptr)    ((ptr) == nil || [ptr isNull])
#define OFISEQUAL(a, b)    ((OFISNULL(a) && OFISNULL(b)) || [(a) isEqual: (b)])
#define OFNOTEQUAL(a, b)   (!OFISEQUAL(a, b))

@interface OFNull : OFObject
+ (id)nullObject;
+ (NSString *)nullStringObject;
@end

@interface OFObject (Null)
- (BOOL)isNull;
@end

#import <Foundation/NSObject.h>

@interface NSObject (Null)
- (BOOL)isNull;
@end

OmniFoundation_EXTERN NSString *OFNullStringObject;
