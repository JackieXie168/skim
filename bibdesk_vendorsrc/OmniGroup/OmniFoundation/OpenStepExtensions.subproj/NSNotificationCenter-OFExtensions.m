// Copyright 1998-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/NSNotificationCenter-OFExtensions.h>

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

#import "OFObject-Queue.h"

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSNotificationCenter-OFExtensions.m,v 1.13 2004/02/10 04:07:46 kc Exp $")

@implementation NSNotificationCenter (OFExtensions)

- (void)addObserver:(id)observer selector:(SEL)aSelector name:(NSString *)aName objects:(NSArray *)objects;
{
    unsigned int objectIndex;

    objectIndex = [objects count];
    while (objectIndex--)
        [self addObserver:observer selector:aSelector name:aName object:[objects objectAtIndex:objectIndex]];
}

- (void)removeObserver:(id)observer name:(NSString *)aName objects:(NSArray *)objects;
{
    unsigned int objectIndex;

    objectIndex = [objects count];
    while (objectIndex--)
        [self removeObserver:observer name:aName object:[objects objectAtIndex:objectIndex]];
}

- (void)mainThreadPostNotificationName:(NSString *)aName object:(id)anObject;
    // Asynchronously post a notification in the main thread
{
    [self mainThreadPerformSelector:@selector(postNotificationName:object:) withObject:aName withObject:anObject];
}

- (void)mainThreadPostNotificationName:(NSString *)aName object:(id)anObject userInfo:(NSDictionary *)aUserInfo;
    // Asynchronously post a notification in the main thread
{
    [self mainThreadPerformSelector:@selector(postNotificationName:object:userInfo:) withObject:aName withObject:anObject withObject:aUserInfo];
}

@end

#if 0 && defined(OMNI_ASSERTIONS_ON)

#import "NSThread-OFExtensions.h" // For ASSERT_MAIN_THREAD_OPS_OK()

@interface OFThreadCheckingNotificationCenter : NSNotificationCenter
@end

@implementation OFThreadCheckingNotificationCenter

+ (void)performPosing;
{
    // don't use +poseAsClass: since that would force +initialize early (and +performPosing gets called w/o forcing it via OBPostLoader).
    class_poseAs((Class)self, ((Class)self)->super_class);

#warning Thread checking enabled for NSNotificationCenter methods.  This should be disabled in production code.
//    NSLog(@"Thread checking enabled for NSView methods.  This should be disabled in production code.  Ignore this message if you're an end user.  Everything is fine.  We're all fine here.  How about you?");
}

- (void)postNotification:(NSNotification *)notification;
{
    OMNI_POOL_START {
        if (self != [isa defaultCenter] && ![NSThread mainThreadOpsOK])
            NSLog(@"-[%@ postNotification:%@ (object=%@, userInfo=%@)] called from background thread", OBShortObjectDescription(self), [notification name], OBShortObjectDescription([notification object]), [[notification userInfo] allKeys]);
    } OMNI_POOL_END;
    [super postNotification:notification];
}

- (void)postNotificationName:(NSString *)aName object:(id)anObject;
{
    OMNI_POOL_START {
        if (self != [isa defaultCenter] && ![NSThread mainThreadOpsOK])
            NSLog(@"-[%@ postNotificationName:%@ object:%@] called from background thread", OBShortObjectDescription(self), aName, OBShortObjectDescription(anObject));
    } OMNI_POOL_END;
    [super postNotificationName:aName object:anObject];
}

- (void)postNotificationName:(NSString *)aName object:(id)anObject userInfo:(NSDictionary *)aUserInfo;
{
    OMNI_POOL_START {
        if (self != [isa defaultCenter] && ![NSThread mainThreadOpsOK])
            NSLog(@"-[%@ postNotificationName:%@ object:%@ userInfo:%@] called from background thread", OBShortObjectDescription(self), aName, OBShortObjectDescription(anObject), [aUserInfo allKeys]);
    } OMNI_POOL_END;
    [super postNotificationName:aName object:anObject userInfo:aUserInfo];
}

@end

#endif
