// Copyright 2003-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Inspector.subproj/OAInspectionSet.h,v 1.3 2004/02/10 04:07:32 kc Exp $

#import <OmniFoundation/OFObject.h>

@interface OAInspectionSet : OFObject
{
    NSMutableSet *_objects;
}

- (void)addObject:(id)object;
- (void)addObjectsFromArray:(NSArray *)objects;
- (void)removeObject:(id)object;
- (BOOL)containsObject:(id)object;

- (NSArray *)allObjects;
- (NSArray *)objectsOfClass:(Class)cls;
- (void)removeObjectsOfClass:(Class)cls;

@end
