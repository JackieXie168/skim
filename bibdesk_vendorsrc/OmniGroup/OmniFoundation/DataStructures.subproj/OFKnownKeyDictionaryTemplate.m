// Copyright 1998-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import <OmniFoundation/OFKnownKeyDictionaryTemplate.h>

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/DataStructures.subproj/OFKnownKeyDictionaryTemplate.m,v 1.8 2003/01/15 22:51:54 kc Exp $")

static NSLock              *lock = nil;
static NSMutableDictionary *uniqueTable = nil;

@interface OFKnownKeyDictionaryTemplate (PrivateAPI)
- _initWithKeys: (NSArray *) keys;
@end

@implementation OFKnownKeyDictionaryTemplate

+ (void) becomingMultiThreaded;
{
    lock = [[NSLock alloc] init];
}

+ (void) initialize;
{
    static BOOL initialized = NO;

    if (initialized)
        return;
    initialized = YES;

    uniqueTable = [[NSMutableDictionary alloc] init];
}

+ (OFKnownKeyDictionaryTemplate *) templateWithKeys: (NSArray *) keys;
{
    OFKnownKeyDictionaryTemplate *template;

    if (!(template = [uniqueTable objectForKey: keys])) {
        template = (OFKnownKeyDictionaryTemplate *)NSAllocateObject(self, sizeof(NSObject *) * [keys count], NULL);
        template = [template _initWithKeys: keys];
        [uniqueTable setObject: template forKey: keys];
        [template release];
    }

    return template;
}

- (NSArray *) keys;
{
    return _keyArray;
}

- (id) retain
{
    return self;
}

- (id) autorelease;
{
    return self;
}

- (void) release;
{
}

@end

@implementation OFKnownKeyDictionaryTemplate (PrivateAPI)

- _initWithKeys: (NSArray *) keys;
{
    unsigned int keyIndex;
    
    _keyArray = [keys copy];
    _keyCount = [keys count];
    for (keyIndex = 0; keyIndex < _keyCount; keyIndex++)
        _keys[keyIndex] = [[keys objectAtIndex: keyIndex] copy];
    return self;
}

@end
