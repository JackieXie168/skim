// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/DataStructures.subproj/OFMultiValueDictionary.h 66170 2005-07-28 17:40:10Z kc $

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
- (void)addObjects:(NSArray *)manyObjects keyedBySelector:(SEL)aSelector;
- (void)setObjects:(NSArray *)replacementObjects forKey:(id)aKey;
- (void)insertObject:(id)anObject forKey:(id)aKey atIndex:(unsigned int)anIndex;
- (BOOL)removeObject:(id)anObject forKey:(id)aKey;
- (BOOL)removeObjectIdenticalTo:(id)anObject forKey:(id)aKey;
- (void)removeAllObjects;
- (NSEnumerator *)keyEnumerator;
- (NSArray *)allKeys;
- (NSArray *)allValues;

- (NSMutableDictionary *)dictionary;

@end
