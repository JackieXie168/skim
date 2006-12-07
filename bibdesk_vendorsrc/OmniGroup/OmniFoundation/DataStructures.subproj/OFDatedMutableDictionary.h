// Copyright 1998-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/DataStructures.subproj/OFDatedMutableDictionary.h,v 1.14 2004/02/10 04:07:43 kc Exp $

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
