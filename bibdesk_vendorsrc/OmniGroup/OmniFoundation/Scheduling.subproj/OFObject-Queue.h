// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/Scheduling.subproj/OFObject-Queue.h,v 1.10 2003/01/15 22:52:03 kc Exp $

#import <Foundation/NSObject.h>

@protocol OFObjectQueue

+ (void)queueSelectorOnce:(SEL)aSelector;
- (void)queueSelector:(SEL)aSelector;
- (void)queueSelectorOnce:(SEL)aSelector;
- (void)queueSelector:(SEL)aSelector withObject:(id)anObject;
- (void)queueSelectorOnce:(SEL)aSelector withObject:(id)anObject;
- (void)queueSelector:(SEL)aSelector withObject:(id)object1 withObject:(id)object2;
- (void)queueSelectorOnce:(SEL)aSelector withObject:(id)object1 withObject:(id)object2;
- (void)queueSelector:(SEL)aSelector withObject:(id)object1 withObject:(id)object2 withObject:(id)object3;
- (void)queueSelector:(SEL)aSelector withBool:(BOOL)aBool;
- (void)queueSelector:(SEL)aSelector withInt:(int)anInt;
- (void)queueSelector:(SEL)aSelector withInt:(int)anInt withInt:(int)anotherInt;

+ (void)mainThreadPerformSelectorOnce:(SEL)aSelector;
- (void)mainThreadPerformSelector:(SEL)aSelector;
- (void)mainThreadPerformSelectorOnce:(SEL)aSelector;
- (void)mainThreadPerformSelector:(SEL)aSelector withObject:(id)anObject;
- (void)mainThreadPerformSelectorOnce:(SEL)aSelector withObject:(id)anObject;
- (void)mainThreadPerformSelector:(SEL)aSelector withObject:(id)object1 withObject:(id)object2;
- (void)mainThreadPerformSelector:(SEL)aSelector withObject:(id)object1 withObject:(id)object2 withObject:(id)object3;
- (void)mainThreadPerformSelector:(SEL)aSelector withBool:(BOOL)aBool;
- (void)mainThreadPerformSelector:(SEL)aSelector withInt:(int)anInt;
- (void)mainThreadPerformSelector:(SEL)aSelector withInt:(int)anInt withInt:(int)anInt2;

- (void)invokeSelector:(SEL)aSelector withObject:(id)object1 withObject:(id)object2 withObject:(id)object3;

@end

@interface NSObject (Queue) <OFObjectQueue>
@end
