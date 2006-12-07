// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/DataStructures.subproj/OFMultiValueDictionary.h,v 1.22 2004/02/10 04:07:43 kc Exp $

#import <OmniFoundation/OFObject.h>
#import <CoreFoundation/CFDictionary.h>

@class NSArray, NSEnumerator, NSMutableDictionary;

@interface OFMultiValueDictionary : OFObject <NSCoding, NSMutableCopying>
{
    CFMutableDictionaryRef dictionary;
    short dictionaryFlags;
}

- init;
- initWithCaseInsensitiveKeys: (BOOL) caseInsensitivity;
- initWithKeyCallBacks:(const CFDictionaryKeyCallBacks *)keyBehavior;  // D.I.

- (NSArray *)arrayForKey:(id)aKey;
- (id)firstObjectForKey:(id)aKey;
- (id)lastObjectForKey:(id)aKey;
- (void)addObject:(id)anObject forKey:(id)aKey;
- (void)addObjects:(NSArray *)moreObjects forKey:(id)aKey;
- (void)setObjects:(NSArray *)replacementObjects forKey:(id)aKey;
- (void)insertObject:(id)anObject forKey:(id)aKey atIndex:(unsigned int)anIndex;
- (BOOL)removeObject:(id)anObject forKey:(id)aKey;
- (BOOL)removeObjectIdenticalTo:(id)anObject forKey:(id)aKey;
- (NSEnumerator *)keyEnumerator;
- (NSArray *)allKeys;
- (NSArray *)allValues;

- (NSMutableDictionary *)dictionary;

@end
