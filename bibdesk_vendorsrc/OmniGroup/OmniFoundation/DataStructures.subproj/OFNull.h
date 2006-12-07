// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/DataStructures.subproj/OFNull.h,v 1.15 2004/02/10 04:07:43 kc Exp $

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
