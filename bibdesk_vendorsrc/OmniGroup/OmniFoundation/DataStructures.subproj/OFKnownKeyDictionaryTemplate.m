// Copyright 1998-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/OFKnownKeyDictionaryTemplate.h>

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/DataStructures.subproj/OFKnownKeyDictionaryTemplate.m,v 1.12 2004/02/10 04:07:43 kc Exp $")

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
    OBINITIALIZE;

    uniqueTable = [[NSMutableDictionary alloc] init];
}

+ (OFKnownKeyDictionaryTemplate *) templateWithKeys: (NSArray *) keys;
{
    OFKnownKeyDictionaryTemplate *template;

    [lock lock];
    NS_DURING {
        if (!(template = [uniqueTable objectForKey: keys])) {
            template = (OFKnownKeyDictionaryTemplate *)NSAllocateObject(self, sizeof(NSObject *) * [keys count], NULL);
            template = [template _initWithKeys: keys];
            [uniqueTable setObject: template forKey: keys];
            [template release];
        }
    } NS_HANDLER {
        template = nil;
        [lock unlock];
        [localException raise];
    } NS_ENDHANDLER;
    [lock unlock];
    
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
