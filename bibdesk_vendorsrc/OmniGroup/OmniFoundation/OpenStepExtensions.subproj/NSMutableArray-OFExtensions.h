// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSMutableArray-OFExtensions.h,v 1.12 2004/02/10 04:07:45 kc Exp $

#import <Foundation/NSArray.h>

@class NSSet;

@interface NSMutableArray (OFExtensions)

- (void)insertObjectsFromArray:(NSArray *)anArray atIndex:(unsigned)anIndex;
- (void)removeIdenticalObjectsFromArray:(NSArray *)removeArray;

- (void)addObjectsFromSet:(NSSet *)aSet;

- (void)replaceObjectsInRange:(NSRange)replacementRange byApplyingSelector:(SEL)selector;

// Maintaining sorted arrays
- (void)insertObject:(id)anObject inArraySortedUsingSelector:(SEL)selector;
- (void)removeObject:(id)anObject fromArraySortedUsingSelector:(SEL)selector;

// Sorting on an object's attribute
- (void)sortOnAttribute:(SEL)fetchAttributeSelector usingSelector:(SEL)comparisonSelector;

@end
