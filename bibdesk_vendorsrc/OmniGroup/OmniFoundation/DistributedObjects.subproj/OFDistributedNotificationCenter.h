// Copyright 1999-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/DistributedObjects.subproj/OFDistributedNotificationCenter.h,v 1.7 2004/02/10 04:07:44 kc Exp $

#import <Foundation/NSObject.h>

@class NSConnection, NSDictionary;

@interface OFDistributedNotificationCenter : NSObject
{
    id server;
}

+ (OFDistributedNotificationCenter *)defaultCenter;

- (void)addObserver:(id)observer selector:(SEL)selector name:(NSString *)name object:(NSString *)object;
- (void)postNotificationName:(NSString *)name object:(NSString *)object userInfo:(NSDictionary *)userInfo;
- (void)postNotificationName:(NSString *)aName object:(NSString *)anObject;
- (void)removeObserver:(id)observer name:(NSString *)aName object:(NSString *)anObject;
- (void)removeObserver:(id)observer;

@end
