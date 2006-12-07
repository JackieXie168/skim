// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/Scheduling.subproj/OFImplementationHolder.h,v 1.11 2004/02/10 04:07:47 kc Exp $

#import <OmniFoundation/OFObject.h>

@class NSLock;

typedef void (*voidIMP)(id, SEL, ...); 

#import <OmniFoundation/OFSimpleLock.h>

@interface OFImplementationHolder : OFObject
{
    SEL selector;
    OFSimpleLockType lock;
    Class objectClass;
    voidIMP implementation;
}

- initWithSelector:(SEL)aSelector;

- (SEL)selector;

- (void)executeOnObject:(id)anObject;
- (void)executeOnObject:(id)anObject withObject:(id)withObject;
- (void)executeOnObject:(id)anObject withObject:(id)withObject withObject:(id)anotherObject;
- (id)returnObjectOnObject:(id)anObject withObject:(id)withObject;

@end

