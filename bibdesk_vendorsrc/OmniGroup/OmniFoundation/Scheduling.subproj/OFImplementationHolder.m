// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import <OmniFoundation/OFImplementationHolder.h>

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/Scheduling.subproj/OFImplementationHolder.m,v 1.9 2003/01/15 22:52:03 kc Exp $")

@implementation OFImplementationHolder

- initWithSelector:(SEL)aSelector;
{
    OFSimpleLockInit(&lock);
    selector = aSelector;
    return self;
}

- (void)dealloc;
{
    OFSimpleLockFree(&lock);
    [super dealloc];
}

- (SEL)selector;
{
    return selector;
}

static inline voidIMP
getImplementationForClass(OFImplementationHolder *self, Class newClass)
{
    voidIMP localImplementation;
    
    OFSimpleLock(&self->lock);
    if (!self->implementation || newClass != self->objectClass) {
	localImplementation = self->implementation = (voidIMP)[newClass instanceMethodForSelector:self->selector];
        self->objectClass = newClass;
    } else
	localImplementation = self->implementation;
    OFSimpleUnlock(&self->lock);
    return localImplementation;
}

- (void)executeOnObject:(id)anObject;
{
    voidIMP localImplementation;
    
    localImplementation = getImplementationForClass(self, *((Class *)anObject));
    localImplementation(anObject, selector);
}

- (void)executeOnObject:(id)anObject withObject:(id)withObject;
{
    voidIMP localImplementation;
    
    localImplementation = getImplementationForClass(self, *((Class *) anObject));
    localImplementation(anObject, selector, withObject);
}

- (void)executeOnObject:(id)anObject withObject:(id)withObject
             withObject:(id)anotherObject;
{
    voidIMP localImplementation;
    
    localImplementation = getImplementationForClass(self, *((Class *) anObject));
    localImplementation(anObject, selector, withObject, anotherObject);
}

- (id)returnObjectOnObject:(id)anObject withObject:(id)withObject;
{
    IMP localImplementation;
    
    localImplementation = (IMP)getImplementationForClass(self, *((Class *) anObject));
    return localImplementation(anObject, selector, withObject);
}

@end
