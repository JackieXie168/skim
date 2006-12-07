// Copyright 1999-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/DistributedObjects.subproj/OFDistributedNotificationCenter.h,v 1.5 2003/01/15 22:51:56 kc Exp $

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
