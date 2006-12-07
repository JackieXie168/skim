// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/DataStructures.subproj/OFMultiValueDictionary.h,v 1.16 2003/01/15 22:51:54 kc Exp $

#import <OmniFoundation/OFObject.h>

@class NSArray;

@interface OFMultiValueDictionary : OFObject <NSMutableCopying>
{
    NSMutableDictionary *dictionary;
}

- initWithCaseInsensitiveKeys: (BOOL) caseInsensitivity;

- (NSArray *)arrayForKey:(NSString *)aKey;
- (id)firstObjectForKey:(NSString *)aKey;
- (id)lastObjectForKey:(NSString *)aKey;
- (void)addObject:(id)anObject forKey:(NSString *)aKey;
- (void)addObjects:(NSArray *)moreObjects forKey:(NSString *)aKey;
- (void)removeObject:(id)anObject forKey:(NSString *)aKey;
- (NSEnumerator *)keyEnumerator;
- (NSArray *)allKeys;
- (NSArray *)allValues;

- (NSMutableDictionary *)dictionary;

@end
