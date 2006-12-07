// Copyright 2002-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import "OFEnumNameTable.h"

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

#import "CFDictionary-OFExtensions.h"

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/DataStructures.subproj/OFEnumNameTable.m,v 1.3 2003/01/15 22:51:53 kc Exp $");

/*"
This class is intended for use in a bi-directional mapping between an integer enumeration and string representations for the elements of the enumeration.  This is useful, for example, when converting data structures to and from an external representation.  Instead of encoding internal enumeration values as integers, they can be encoded as string names.  This makes it easier to interpret the external representation and easier to rearrange the private enumeration values without impact to existing external representations in files, defaults property lists, databases, etc.

The implementation does not currently assume anything about the range of the enumeration values.  It would simplify the implementation if we could assume that there was a small set of values, starting at zero and all contiguous.  This is the default for enumerations in C, but certainly isn't required.
"*/
@implementation OFEnumNameTable

// Init and dealloc

- init;
{
    OBRequestConcreteImplementation(isa, _cmd);
    [self release];
    return nil;
}

- initWithDefaultEnumValue: (int) defaultEnumValue;
{
    _defaultEnumValue = defaultEnumValue;
    _enumToName = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &OFIntegerDictionaryKeyCallbacks, &OFNSObjectDictionaryValueCallbacks);
    _nameToEnum = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &OFNSObjectDictionaryKeyCallbacks, &OFIntegerDictionaryValueCallbacks);
    
    return self;
}

- (void)dealloc;
{
    CFRelease(_enumToName);
    CFRelease(_nameToEnum);
    [super dealloc];
}


// API

- (int) defaultEnumValue;
{
    return _defaultEnumValue;
}

- (void) setName: (NSString *) enumName forEnumValue: (int) enumValue;
{
    OBPRECONDITION(enumName);
    OBPRECONDITION(!CFDictionaryContainsKey(_enumToName, (const void *)enumValue));
    OBPRECONDITION(!CFDictionaryContainsKey(_nameToEnum, (const void *)enumName));
    CFDictionarySetValue(_enumToName, (const void *)enumValue, (const void *)enumName);
    CFDictionarySetValue(_nameToEnum, (const void *)enumName, (const void *)enumValue);
}

- (NSString *) nameForEnum: (int) enumValue;
{
    NSString *name = nil;
    
    if (!CFDictionaryGetValueIfPresent(_enumToName, (const void *)enumValue, (const void **)&name)) {
        // Since the enumeration values are internal, we expect that we know all of them and all are registered.
        [NSException raise: NSInvalidArgumentException format: @"Attempted to get name for unregistered enum value %d", enumValue];
    }
    OBASSERT(name);
    return name;
}

- (int) enumForName: (NSString *) name;
{
    int enumValue;

    if (!name)
        // Don't require the name -- the external representation might not encode default values
        return _defaultEnumValue;
    
    if (!CFDictionaryGetValueIfPresent(_nameToEnum, (const void *)name, (const void **)&enumValue)) {
        // some unknown name -- the external representation might have been mucked up somehow
        return _defaultEnumValue;
    }
    return enumValue;
}

@end
