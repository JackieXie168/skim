// Copyright 2003-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OFIObjectSelectorObjectInt.h"

#import <Foundation/Foundation.h>
#import <objc/objc-class.h>
#import <OmniBase/OmniBase.h>
#import <OmniFoundation/NSMutableDictionary-OFExtensions.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/Scheduling.subproj/OFIObjectSelectorObjectInt.m 68913 2005-10-03 19:36:19Z kc $")

@implementation OFIObjectSelectorObjectInt

- initForObject:(id)targetObject selector:(SEL)aSelector withObject:(id)anObject withInt:(int)anInt;
{
    OBPRECONDITION([targetObject respondsToSelector:aSelector]);

    [super initForObject:targetObject selector:aSelector];

    withObject = [anObject retain];
    theInt = anInt;

    return self;
}

- (void)dealloc;
{
    [withObject release];
    [super dealloc];
}

- (void)invoke;
{
    Method method;

    method = class_getInstanceMethod(((OFIObjectSelectorObjectInt *) object)->isa, selector);
    if (!method)
        [NSException raise:NSInvalidArgumentException format:@"%s(0x%x) does not respond to the selector %@", ((OFIObjectSelectorObjectInt *)object)->isa->name, (unsigned)object, NSStringFromSelector(selector)];

    method->method_imp(object, selector, withObject, theInt);
}

- (unsigned int)hash;
{
    return (unsigned int)object + (unsigned int)(void *)selector + (unsigned int)withObject + (unsigned int)theInt;
}

- (BOOL)isEqual:(id)anObject;
{
    OFIObjectSelectorObjectInt *otherObject;

    otherObject = anObject;
    if (otherObject->isa != isa)
        return NO;
    return object == otherObject->object && selector == otherObject->selector && withObject == otherObject->withObject && theInt == otherObject->theInt;
}

- (NSMutableDictionary *)debugDictionary;
{
    NSMutableDictionary *debugDictionary;

    debugDictionary = [super debugDictionary];
    if (object)
        [debugDictionary setObject:object forKey:@"object"];
    [debugDictionary setObject:NSStringFromSelector(selector) forKey:@"selector"];
    if (withObject)
        [debugDictionary setObject:withObject forKey:@"withObject"];
    [debugDictionary setIntValue:theInt forKey:@"theInt"];

    return debugDictionary;
}

- (NSString *)shortDescription;
{
    return [NSString stringWithFormat:@"-[%@ %@(%@,%d)]", OBShortObjectDescription(object), NSStringFromSelector(selector), OBShortObjectDescription(withObject), theInt];
}

@end
