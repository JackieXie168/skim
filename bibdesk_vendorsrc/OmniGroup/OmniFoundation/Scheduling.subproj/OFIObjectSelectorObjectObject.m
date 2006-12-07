// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OFIObjectSelectorObjectObject.h"

#import <Foundation/Foundation.h>
#import <objc/objc-class.h>
#import <OmniBase/OmniBase.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/Scheduling.subproj/OFIObjectSelectorObjectObject.m,v 1.16 2004/02/10 04:07:47 kc Exp $")

@implementation OFIObjectSelectorObjectObject;

static Class myClass;

+ (void)initialize;
{
    OBINITIALIZE;
    myClass = self;
}

- initForObject:(id)targetObject selector:(SEL)aSelector withObject:(id)anObject1 withObject:(id)anObject2;
{
    OBPRECONDITION([targetObject respondsToSelector:aSelector]);

    [super initForObject:targetObject selector:aSelector];

    object1 = [anObject1 retain];
    object2 = [anObject2 retain];

    return self;
}

- (void)dealloc;
{
    [object1 release];
    [object2 release];
    [super dealloc];
}

- (void)invoke;
{
    Method method;

    method = class_getInstanceMethod(((OFIObjectSelectorObjectObject *) object)->isa, selector);
    if (!method)
        [NSException raise:NSInvalidArgumentException format:@"%s(0x%x) does not respond to the selector %@", ((OFIObjectSelectorObjectObject *)object)->isa->name, (unsigned)object, NSStringFromSelector(selector)];

    method->method_imp(object, selector, object1, object2);
}

- (unsigned int)hash;
{
    return (unsigned int)object + (unsigned int)(void *)selector + (unsigned int)object1 + (unsigned int)object2;
}

- (BOOL)isEqual:(id)anObject;
{
    OFIObjectSelectorObjectObject *otherObject;

    otherObject = anObject;
    if (otherObject->isa != myClass)
	return NO;
    return object == otherObject->object && selector == otherObject->selector && object1 == otherObject->object1 && object2 == otherObject->object2;
}

- (NSMutableDictionary *)debugDictionary;
{
    NSMutableDictionary *debugDictionary;

    debugDictionary = [super debugDictionary];
    if (object)
	[debugDictionary setObject:object forKey:@"object"];
    [debugDictionary setObject:NSStringFromSelector(selector) forKey:@"selector"];
    if (object1)
        [debugDictionary setObject:object1 forKey:@"object1"];
    if (object2)
        [debugDictionary setObject:object2 forKey:@"object2"];

    return debugDictionary;
}

- (NSString *)shortDescription;
{
    return [NSString stringWithFormat:@"-[%@ %@(%@,%@)]", OBShortObjectDescription(object), NSStringFromSelector(selector), OBShortObjectDescription(object1), OBShortObjectDescription(object2)];
}

@end
