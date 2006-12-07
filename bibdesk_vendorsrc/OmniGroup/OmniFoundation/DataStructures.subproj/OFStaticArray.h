// Copyright 1998-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/DataStructures.subproj/OFStaticArray.h 68913 2005-10-03 19:36:19Z kc $

#import <OmniFoundation/OFObject.h>

// An array of OFStaticObjects of a particular class, with efficient allocation and deallocation

@class NSMutableData;

@interface OFStaticArray : OFObject
{
    Class objectClass;
    unsigned int objectLength;
    unsigned int count;
    unsigned int capacity;
    unsigned int extensionSize;
    void *mutableBytes;
    BOOL debugEnabled;
}

- initWithClass:(Class)aClass capacity:(unsigned int)aCapacity extendBy:(unsigned int)extendBy debugEnabled: (BOOL) isDebugEnabled;
- initWithClass:(Class)aClass capacity:(unsigned int)aCapacity extendBy:(unsigned int)extendBy;
- initWithClass:(Class)aClass capacity:(unsigned int)aCapacity;
- initWithClass:(Class)aClass;

- (unsigned int)capacity;
- (void)setCapacity:(unsigned int)aCapacity;

- (unsigned int)extensionSize;
- (void)setExtensionSize:(unsigned int)anAmount;

- (unsigned int)count;
- (void)setCount:(unsigned int)number;
- (void)removeAllObjects;
- (void)removeObjectAtIndex:(unsigned int)index;

- (id)newObject;
- (id)objectAtIndex:(unsigned int)anIndex;
- (id)lastObject;

- (void) setDebugEnabled: (BOOL) isDebugEnabled;

@end
