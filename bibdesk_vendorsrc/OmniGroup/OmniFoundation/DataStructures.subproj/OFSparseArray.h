// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/DataStructures.subproj/OFSparseArray.h,v 1.11 2004/02/10 04:07:43 kc Exp $

#import <OmniFoundation/OFObject.h>

@class NSArray, NSMutableArray;

@interface OFSparseArray : OFObject
{
    NSMutableArray *values;
    unsigned int valuesLength;
    id defaultValue;
}

- initWithCapacity:(unsigned int)aCapacity;
- (unsigned int)count;
- (id)objectAtIndex:(unsigned int)anIndex;
- (void)setObject:(id)anObject atIndex:(unsigned int)anIndex;
- (void)setDefaultValue:(id)aDefaultValue;
- (NSArray *)valuesArray;

@end
