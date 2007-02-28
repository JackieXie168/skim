// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSMutableArray-OFExtensions.h 69639 2005-10-26 22:27:07Z wiml $

#import <Foundation/NSArray.h>

@class NSSet;

@interface NSMutableArray (OFExtensions)

- (void)insertObjectsFromArray:(NSArray *)anArray atIndex:(unsigned)anIndex;
- (void)removeIdenticalObjectsFromArray:(NSArray *)removeArray;

- (void)addObjectsFromSet:(NSSet *)aSet;

- (void)replaceObjectsInRange:(NSRange)replacementRange byApplyingSelector:(SEL)selector;

- (void)reverse;

- (void)sortBasedOnOrderInArray:(NSArray *)ordering identical:(BOOL)usePointerEquality unknownAtFront:(BOOL)putUnknownObjectsAtFront;

// Maintaining sorted arrays
- (void)insertObject:(id)anObject inArraySortedUsingSelector:(SEL)selector;
- (void)insertObject:(id)anObject inArraySortedUsingFunction:(int (*)(id, id, void *))compare context:(void *)context;
- (void)removeObjectIdenticalTo:(id)anObject fromArraySortedUsingSelector:(SEL)selector;
- (void)removeObjectIdenticalTo:(id)anObject fromArraySortedUsingFunction:(int (*)(id, id, void *))compare context:(void *)context;

// Sorting on an object's attribute
- (void)sortOnAttribute:(SEL)fetchAttributeSelector usingSelector:(SEL)comparisonSelector;

@end
