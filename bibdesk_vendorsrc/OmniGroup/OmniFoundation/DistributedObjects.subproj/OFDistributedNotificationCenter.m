// Copyright 1999-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import "OFDistributedNotificationCenter.h"

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/DistributedObjects.subproj/OFDistributedNotificationCenter.m,v 1.5 2003/01/15 22:51:56 kc Exp $")

#ifdef WIN32
#import <process.h>
#import <winsock.h>
#import <io.h>
#import <winbase.h>
#endif

@implementation OFDistributedNotificationCenter

static OFDistributedNotificationCenter *defaultCenter;

+ (OFDistributedNotificationCenter *)defaultCenter;
{
    if (!defaultCenter)
        defaultCenter = [[self alloc] init];
    return defaultCenter;
}

- init;
{
    [super init];
    server = [[NSConnection rootProxyForConnectionWithRegisteredName:@"OFDistributedNotificationCenter" host:@"localhost"] retain];
    return self;
}

- (void)addObserver:(id)observer selector:(SEL)selector name:(NSString *)name object:(NSString *)object;
{
    [server addObserver:observer selector:selector name:name object:object];
}

- (void)postNotificationName:(NSString *)name object:(NSString *)object userInfo:(NSDictionary *)userInfo;
{
    [self postNotificationName:name object:object];
}

- (void)postNotificationName:(NSString *)aName object:(NSString *)anObject;
{
    [server postNotificationName:aName object:anObject];
}

- (void)removeObserver:(id)observer name:(NSString *)aName object:(NSString *)anObject;
{
    [server removeObserver:observer name:aName object:anObject];
}

- (void)removeObserver:(id)observer;
{
    [server removeObserver:observer];
}

@end
