// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OFIObjectSelector.h"

#import <Foundation/Foundation.h>
#import <objc/objc-class.h>
#import <OmniBase/OmniBase.h>

#import "OFMessageQueuePriorityProtocol.h"

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/Scheduling.subproj/OFIObjectSelector.m,v 1.16 2004/02/10 04:07:47 kc Exp $")

@implementation OFIObjectSelector

static Class myClass;

+ (void)initialize;
{
    OBINITIALIZE;
    myClass = self;
}

- initForObject:(id)anObject;
{
    OBRejectUnusedImplementation(self, _cmd);
    return nil;
}

- initForObject:(id)anObject selector:(SEL)aSelector;
{
    OBPRECONDITION([anObject respondsToSelector:aSelector]);

    [super initForObject:anObject];

    selector = aSelector;
    if ([anObject respondsToSelector:@selector(fixedPriorityForSelector:)])
        priorityLevel = [anObject fixedPriorityForSelector:aSelector];

    return self;
}

- (void)invoke;
{
    Method method;

    method = class_getInstanceMethod(((OFIObjectSelector *)object)->isa, selector);
    if (!method)
        [NSException raise:NSInvalidArgumentException format:@"%s(0x%x) does not respond to the selector %@", ((OFIObjectSelector *)object)->isa->name, (unsigned)object, NSStringFromSelector(selector)];

    method->method_imp(object, selector);
}

- (SEL)selector;
{
    return selector;
}

- (unsigned int)hash;
{
    return (unsigned int)object + (unsigned int)(void *)selector;
}

- (BOOL)isEqual:(id)anObject;
{
    OFIObjectSelector *otherObject;

    otherObject = anObject;
    if (otherObject == self)
	return YES;
    if (otherObject->isa != myClass)
	return NO;
    return object == otherObject->object && selector == otherObject->selector;
}

// Debugging

- (NSMutableDictionary *)debugDictionary;
{
    NSMutableDictionary *debugDictionary;

    debugDictionary = [super debugDictionary];
    if (object)
	[debugDictionary setObject:object forKey:@"object"];
    [debugDictionary setObject:NSStringFromSelector(selector) forKey:@"selector"];

    return debugDictionary;
}

- (NSString *)shortDescription;
{
    return [NSString stringWithFormat:@"-[%@ %@]", OBShortObjectDescription(object), NSStringFromSelector(selector)];
}

@end
