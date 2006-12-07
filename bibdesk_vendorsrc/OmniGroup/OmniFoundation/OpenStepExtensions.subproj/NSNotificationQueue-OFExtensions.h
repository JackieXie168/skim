// Copyright 1998-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSNotificationQueue-OFExtensions.h,v 1.8 2003/01/15 22:52:00 kc Exp $

#import <Foundation/NSNotificationQueue.h>

@class NSDictionary;

@interface NSNotificationQueue (OFExtensions)

+ (void)enqueueNotificationInMainThread:(NSNotification *)aNote
                           postingStyle:(NSPostingStyle)aStyle;

- (void) enqueueNotificationName: (NSString *) name
                          object: (id) object
                    postingStyle: (NSPostingStyle) postingStyle;

- (void) enqueueNotificationName: (NSString *) name
                          object: (id) object
                        userInfo: (NSDictionary *) userInfo
                    postingStyle: (NSPostingStyle) aStyle;

- (void) enqueueNotificationName: (NSString *) name
                          object: (id) object
                        userInfo: (NSDictionary *) userInfo
                    postingStyle: (NSPostingStyle) aStyle
                    coalesceMask: (unsigned) coalesceMask
                        forModes: (NSArray *) modes;

- (void) dequeueNotificationsMatching: (NSString *) name
                               object: (id) object
                         coalesceMask: (unsigned) coalesceMask;

- (void) firePendingNotifications;

@end
