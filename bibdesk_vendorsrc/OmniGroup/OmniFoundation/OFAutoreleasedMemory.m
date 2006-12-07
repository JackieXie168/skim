// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/OFAutoreleasedMemory.h>

#import <Foundation/Foundation.h>
#import <objc/objc-class.h>
#import <OmniBase/OmniBase.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OFAutoreleasedMemory.m,v 1.14 2004/02/10 04:07:40 kc Exp $")

static NSZone *defaultMallocZone = NULL;

@implementation OFAutoreleasedMemory

+ (void)initialize;
{
    OBINITIALIZE;
    defaultMallocZone = NSDefaultMallocZone();
}

+ (void *)mallocMemoryWithCapacity: (unsigned long) length;
{
    OFAutoreleasedMemory *memory;
    Class aClass;
    char *buffer;


    aClass = (Class)self;
    memory = (OFAutoreleasedMemory *)NSAllocateObject(aClass, length, defaultMallocZone);
    [memory autorelease];

    // This contortion is necessary for OpenStep/Solaris
    buffer = (char *)memory + aClass->instance_size;
    return (void *)buffer;
}

- (void)release;
{
    // Can't ever get more than one reference to an instance of this class
    NSDeallocateObject(self);
}

@end
