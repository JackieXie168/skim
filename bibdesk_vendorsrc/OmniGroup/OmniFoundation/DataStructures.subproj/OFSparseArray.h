// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/DataStructures.subproj/OFSparseArray.h,v 1.9 2003/01/15 22:51:55 kc Exp $

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
