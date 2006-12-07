// Copyright 2000-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import "OFWeakRetainConcreteImplementation.h"

#import <Foundation/Foundation.h>
#import <objc/objc-class.h>
#import <OmniBase/OmniBase.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OFWeakRetainConcreteImplementation.m,v 1.10 2003/01/15 22:51:51 kc Exp $")


@implementation NSObject (OFWeakRetain)

- (id)weakRetain;
{
    [self retain];
    [(id <OFWeakRetain>)self incrementWeakRetainCount];
    return self;
}

- (void)weakRelease;
{
    [(id <OFWeakRetain>)self decrementWeakRetainCount];
    [self release];
}

- (id)weakAutorelease;
{
    [(id <OFWeakRetain>)self decrementWeakRetainCount];
    return [self autorelease];
}

static NSMutableSet *warnedClasses = nil;

- (void)incrementWeakRetainCount;
    // Not thread-safe, but this is debugging code
{
    if (warnedClasses == nil)
        warnedClasses = [[NSMutableSet alloc] init];

    if (![warnedClasses containsObject:isa]) {
        [warnedClasses addObject:isa];
        NSLog(@"%@ does not implement the OFWeakRetain protocol", NSStringFromClass(isa));
    }
}

- (void)decrementWeakRetainCount;
{
}

+ (void)incrementWeakRetainCount;
{
}

+ (void)decrementWeakRetainCount;
{
}

@end
