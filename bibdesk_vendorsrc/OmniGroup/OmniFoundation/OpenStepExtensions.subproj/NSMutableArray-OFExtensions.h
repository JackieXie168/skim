// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSMutableArray-OFExtensions.h,v 1.9 2003/02/20 05:30:51 wiml Exp $

#import <Foundation/NSArray.h>

@class NSSet;

@interface NSMutableArray (OFExtensions)

- (void)insertObjectsFromArray:(NSArray *)anArray atIndex:(unsigned)anIndex;
- (void)removeIdenticalObjectsFromArray:(NSArray *)removeArray;

- (void)addObjectsFromSet:(NSSet *)aSet;

// Maintaining sorted arrays
- (void)insertObject:(id)anObject inArraySortedUsingSelector:(SEL)selector;
- (void)removeObject:(id)anObject fromArraySortedUsingSelector:(SEL)selector;

// Sorting on an object's attribute
- (void)sortOnAttribute:(SEL)fetchAttributeSelector usingSelector:(SEL)comparisonSelector;

@end
