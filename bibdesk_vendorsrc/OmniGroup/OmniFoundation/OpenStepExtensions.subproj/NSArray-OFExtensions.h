// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSArray-OFExtensions.h,v 1.31 2004/02/10 04:07:45 kc Exp $

#import <Foundation/NSArray.h>

#import <OmniFoundation/OFDictionaryInitialization.h>

@class NSDecimalNumber, OFMultiValueDictionary;

@interface NSArray (OFExtensions)

- (id)anyObject;
    // Returns any object from the array.

- (NSArray *)elementsAsInstancesOfClass:(Class)aClass withContext:(id)context;

#ifndef WINNT
- (id)randomObject;
    // Returns a random object from the array.
#endif

// These are safe to use on mixed-content arrays.
// The first two call -indexOfString:options:range: with default values.
- (int)indexOfString:(NSString *)aString;
- (int)indexOfString:(NSString *)aString options:(unsigned int)someOptions;
- (int)indexOfString:(NSString *)aString options:(unsigned int)someOptions 	range:(NSRange)aRange;
- (NSString *)componentsJoinedByComma;
- (NSString *)componentsJoinedByCommaAndAnd;
    // (x) -> "x"; (x, y) -> "x and y";  (x, y, z) -> "x, y, and z", and so on

- (unsigned)indexOfObject: (id) anObject inArraySortedUsingSelector: (SEL) selector;
- (BOOL) isSortedUsingSelector:(SEL)selector;
- (BOOL) isSortedUsingFunction:(int (*)(id, id, void *))comparator context:(void *)context;

- (void)makeObjectsPerformSelector:(SEL)selector withObject:(id)arg1 withObject:(id)arg2;

- (NSDecimalNumber *)decimalNumberSumForSelector:(SEL)aSelector;
- (NSArray *)numberedArrayDescribedBySelector:(SEL)aSelector;
- (NSArray *)objectsDescribedByIndexesString:(NSString *)indexesString;
- (NSArray *)arrayByRemovingObject:(id)anObject;
- (NSArray *)arrayByRemovingObjectIdenticalTo:(id)anObject;
- (OFMultiValueDictionary *)groupBySelector:(SEL)aSelector;
- (OFMultiValueDictionary *)groupBySelector:(SEL)aSelector withObject:(id)anObject;
- (NSDictionary *)indexBySelector:(SEL)aSelector;
- (NSArray *)arrayByPerformingSelector:(SEL)aSelector;
- (NSArray *)arrayByPerformingSelector:(SEL)aSelector withObject:(id)anObject;

- (NSArray *)objectsSatisfyingCondition:(SEL)aSelector;
- (NSArray *)objectsSatisfyingCondition:(SEL)aSelector withObject:(id)anObject;
// Returns an array of objects that return true when tested by aSelector.

- (id)deepMutableCopy;

- (NSArray *)reversedArray;

- (NSArray *)deepCopyWithReplacementFunction:(id (*)(id, void *))funct context:(void *)context;

- (BOOL)isIdenticalToArray:(NSArray *)otherArray;

- (BOOL)containsObjectsInOrder:(NSArray *)orderedObjects;
- (BOOL)containsObjectIdenticalTo:anObject;

@end
