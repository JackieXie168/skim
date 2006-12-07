// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OFIObjectSelectorInt.h"

#import <Foundation/Foundation.h>
#import <objc/objc-class.h>
#import <OmniBase/OmniBase.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/Scheduling.subproj/OFIObjectSelectorInt.m 68913 2005-10-03 19:36:19Z kc $")

@implementation OFIObjectSelectorInt;

static Class myClass;

+ (void)initialize;
{
    OBINITIALIZE;
    myClass = self;
}

- initForObject:(id)anObject selector:(SEL)aSelector withInt:(int)anInt;
{
    OBPRECONDITION([anObject respondsToSelector:aSelector]);

    [super initForObject:anObject selector:aSelector];

    theInt = anInt;

    return self;
}

- (void)invoke;
{
    Method method;

    method = class_getInstanceMethod(((OFIObjectSelectorInt *)object)->isa, selector);
    if (!method)
        [NSException raise:NSInvalidArgumentException format:@"%s(0x%x) does not respond to the selector %@", ((OFIObjectSelectorInt *)object)->isa->name, (unsigned)object, NSStringFromSelector(selector)];

    method->method_imp(object, selector, theInt);
}

- (unsigned int)hash;
{
    return (unsigned int)object + (unsigned int)(void *)selector + (unsigned int)theInt;
}

- (BOOL)isEqual:(id)anObject;
{
    OFIObjectSelectorInt *otherObject;

    otherObject = anObject;
    if (otherObject->isa != myClass)
	return NO;
    return object == otherObject->object && selector == otherObject->selector && theInt == otherObject->theInt;
}

- (NSMutableDictionary *)debugDictionary;
{
    NSMutableDictionary *debugDictionary;

    debugDictionary = [super debugDictionary];
    if (object)
	[debugDictionary setObject:object forKey:@"object"];
    [debugDictionary setObject:NSStringFromSelector(selector) forKey:@"selector"];
    [debugDictionary setObject:[NSNumber numberWithInt:theInt] forKey:@"theInt"];

    return debugDictionary;
}

- (NSString *)shortDescription;
{
    return [NSString stringWithFormat:@"-[%@ %@%d]", OBShortObjectDescription(object), NSStringFromSelector(selector), theInt];
}

@end
