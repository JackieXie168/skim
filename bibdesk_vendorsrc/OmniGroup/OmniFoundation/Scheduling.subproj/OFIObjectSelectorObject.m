// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OFIObjectSelectorObject.h"

#import <Foundation/Foundation.h>
#import <objc/objc-class.h>
#import <OmniBase/OmniBase.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/Scheduling.subproj/OFIObjectSelectorObject.m 68913 2005-10-03 19:36:19Z kc $")

@implementation OFIObjectSelectorObject;

static Class myClass;

+ (void)initialize;
{
    OBINITIALIZE;
    myClass = self;
}

- initForObject:(id)anObject selector:(SEL)aSelector withObject:(id)aWithObject;
{
    OBPRECONDITION([anObject respondsToSelector:aSelector]);
    
    [super initForObject:anObject selector:aSelector];

    withObject = [aWithObject retain];

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

    method = class_getInstanceMethod(((OFIObjectSelectorObject *)object)->isa, selector);
    if (!method)
        [NSException raise:NSInvalidArgumentException format:@"%s(0x%x) does not respond to the selector %@", ((OFIObjectSelectorObject *)object)->isa->name, (unsigned)object, NSStringFromSelector(selector)];
    
    method->method_imp(object, selector, withObject);
}

- (unsigned int)hash;
{
    return (unsigned int)object + (unsigned int)(void *)selector + (unsigned int)withObject;
}

- (BOOL)isEqual:(id)anObject;
{
    OFIObjectSelectorObject *otherObject;

    otherObject = anObject;
    if (otherObject == self)
	return YES;
    if (otherObject->isa != myClass)
	return NO;
    return object == otherObject->object &&
	   selector == otherObject->selector &&
	   withObject == otherObject->withObject;
}

- (NSMutableDictionary *)debugDictionary;
{
    NSMutableDictionary *debugDictionary;

    debugDictionary = [super debugDictionary];
    if (object)
	[debugDictionary setObject:OBShortObjectDescription(object) forKey:@"object"];
    [debugDictionary setObject:NSStringFromSelector(selector) forKey:@"selector"];
    if (withObject)
	[debugDictionary setObject:OBShortObjectDescription(withObject) forKey:@"withObject"];

    return debugDictionary;
}

- (NSString *)shortDescription;
{
    return [NSString stringWithFormat:@"-[%@ %@%@]", OBShortObjectDescription(object), NSStringFromSelector(selector), OBShortObjectDescription(withObject)];
}

@end
