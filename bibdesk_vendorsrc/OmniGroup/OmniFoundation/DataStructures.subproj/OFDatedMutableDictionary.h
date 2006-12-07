// Copyright 1998-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/DataStructures.subproj/OFDatedMutableDictionary.h,v 1.12 2003/01/31 18:06:46 andrew Exp $

#import <OmniFoundation/OFObject.h>

@class NSArray, NSDate;

@interface OFDatedMutableDictionary : OFObject
{
    NSMutableDictionary *_dictionary;
}

- (id)init;
- (void)dealloc;

- (void)setObject:(id)anObject forKey:(NSString *)aKey;
- (id)objectForKey:(NSString *)aKey;
- (void)removeObjectForKey:(NSString *)aKey;
- (NSDate *)lastAccessForKey:(NSString *)aKey;

- (NSArray *)objectsOlderThanDate:(NSDate *)aDate;
- (void)removeObjectsOlderThanDate:(NSDate *)aDate;

// Debugging

- (NSMutableDictionary *)debugDictionary;

@end
