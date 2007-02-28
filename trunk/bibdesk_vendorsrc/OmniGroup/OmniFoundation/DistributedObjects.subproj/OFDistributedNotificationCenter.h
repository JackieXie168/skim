// Copyright 1999-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/DistributedObjects.subproj/OFDistributedNotificationCenter.h 68913 2005-10-03 19:36:19Z kc $

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
