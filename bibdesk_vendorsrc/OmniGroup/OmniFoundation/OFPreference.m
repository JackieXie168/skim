// Copyright 2001-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import "OFPreference.h"

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

#import "NSUserDefaults-OFExtensions.h"
#import "OFNull.h"

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OFPreference.m,v 1.10 2003/03/10 01:06:38 neo Exp $");

//#define DEBUG_PREFERENCES

static NSUserDefaults *standardUserDefaults;
static NSMutableDictionary *preferencesByKey;
static NSLock *preferencesLock;

DEFINE_NSSTRING(OFPreferenceDidChangeNotification);

static id _objectValue(id self, id *_value, OFSimpleLockType *lock, NSString *key, NSString *className)
{
    NSException *raisedException = nil;
    id result = nil;
    
    OFSimpleLock(lock);
    NS_DURING {
        result = [*_value retain];
#ifdef DEBUG_PREFERENCES
        NSLog(@"OFPreference(0x%08x:%@) -> %@", self, key, result);
#endif
    } NS_HANDLER {
        raisedException = localException;
    } NS_ENDHANDLER;
    OFSimpleUnlock(lock);
    
    [raisedException raise];

    // We use a class name rather than a class to avoid calling +class when assertions are off
    OBASSERT(!result || [result isKindOfClass: NSClassFromString(className)]);
    
    return [result autorelease];
}

static void _setValue(id self, id *_value, OFSimpleLockType *lock, NSString *key, id value)
{
    NSException *raisedException = nil;
    
    OFSimpleLock(lock);
    NS_DURING {
        if (value) {
            [value retain];
            [*_value release];
            *_value = value;
    
            [standardUserDefaults setObject: value forKey: key];
#ifdef DEBUG_PREFERENCES
            NSLog(@"OFPreference(0x%08x:%@) <- %@", self, key, *_value);
#endif
        } else {
            [standardUserDefaults removeObjectForKey: key];
            
            // Get the new value exposed by removing this from the user default domain
            [*_value release];
            *_value = [[standardUserDefaults objectForKey: key] retain];

#ifdef DEBUG_PREFERENCES
            NSLog(@"OFPreference(0x%08x:%@) <- nil (is now %@)", self, key, *_value);
#endif
        }
    } NS_HANDLER {
        raisedException = localException;
    } NS_ENDHANDLER;
    OFSimpleUnlock(lock);
    
    [raisedException raise];
    
    // Tell anyone who is interested that this default changed
    [[NSNotificationCenter defaultCenter] postNotificationName:OFPreferenceDidChangeNotification object:self];
}


@interface OFPreference (Private)
- (id) _initWithKey: (NSString * ) key;
@end

@implementation OFPreference

+ (void) initialize;
{
    OBINITIALIZE;
    
    standardUserDefaults = [[NSUserDefaults standardUserDefaults] retain];
    preferencesByKey = [[NSMutableDictionary alloc] init];
    preferencesLock = [[NSLock alloc] init];
}

/*
  Init/dealloc/ref counting
  Right now OFPreference instances are shared and never go away.  The rest of the class shouldn't assume this, though, in case we decide to change this approach.
*/

- init;
{
    // OFPreference instances must be uniqued, so you should always go through +preferenceForKey:
    OBRejectUnusedImplementation(self, _cmd);
    [self release];
    return nil;
}

- (id) retain;
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

- (void)dealloc;
{
    OBPRECONDITION(NO);
    OFSimpleLockFree(&_lock);
    [_key release];
    [_value release];
    [super dealloc];
}

// Subclass methods

- (unsigned) hash;
{
    return [_key hash];
}

- (BOOL) isEqual: (id) otherPreference;
{
    return [_key isEqual: [otherPreference key]];
}

// API

+ (OFPreference *) preferenceForKey: (NSString *) key;
{
    OFPreference *preference;
    
    OBPRECONDITION(key);
    
    [preferencesLock lock];
    preference = [[preferencesByKey objectForKey: key] retain];
    if (!preference) {
        preference = [[self alloc] _initWithKey: key];
        [preferencesByKey setObject: preference forKey: key];
    }
    [preferencesLock unlock];
    
    return [preference autorelease];
}

- (NSString *) key;
{
    return _key;
}

- (BOOL) hasNonDefaultValue;
{
    NSDictionary *registrationDictionary;
    id value, registrationValue;

    value = [self objectValue];
    registrationDictionary = [standardUserDefaults volatileDomainForName:NSRegistrationDomain];
    registrationValue = [registrationDictionary objectForKey:_key];

    return !OFISEQUAL(value, registrationValue);
}


- (void) restoreDefaultValue;
{
    _setValue(self, &_value, &_lock, _key, nil);
}

- (id) objectValue;
{
    return _objectValue(self, &_value, &_lock, _key, @"NSObject");
}

- (NSString *) stringValue;
{
    return [[self objectValue] description];
}

- (NSArray *) arrayValue;
{
    return _objectValue(self, &_value, &_lock, _key, @"NSArray");
}

- (NSDictionary *) dictionaryValue;
{
    return _objectValue(self, &_value, &_lock, _key, @"NSDictionary");
}

- (NSData *) dataValue;
{
    return _objectValue(self, &_value, &_lock, _key, @"NSData");
}

- (int) integerValue;
{
    int result;
    
    OFSimpleLock(&_lock);
    OBASSERT(!_value || [_value isKindOfClass: [NSNumber class]]);
    result = [_value intValue];
#ifdef DEBUG_PREFERENCES
    NSLog(@"OFPreference(0x%08x:%@) -> %d", self, _key, result);
#endif
    OFSimpleUnlock(&_lock);
    
    return result;
}

- (float) floatValue;
{
    float result;
    
    OFSimpleLock(&_lock);
    OBASSERT(!_value || [_value isKindOfClass: [NSNumber class]]);
    if (_value)
        result = [_value floatValue];
    else
        result = 0.0;
#ifdef DEBUG_PREFERENCES
    NSLog(@"OFPreference(0x%08x:%@) -> %f", self, _key, result);
#endif
    OFSimpleUnlock(&_lock);
    
    return result;
}

- (BOOL) boolValue;
{
    BOOL result;
    
    OFSimpleLock(&_lock);
    OBASSERT(!_value || [_value isKindOfClass: [NSNumber class]]);
    result = [_value boolValue];
#ifdef DEBUG_PREFERENCES
    NSLog(@"OFPreference(0x%08x:%@) -> %s", self, _key, result ? "YES" : "NO");
#endif
    OFSimpleUnlock(&_lock);
    
    return result;
}

- (void) setObjectValue: (id) value;
{
    _setValue(self, &_value, &_lock, _key, value);
}

- (void) setStringValue: (NSString *) value;
{
    OBPRECONDITION(!value || [value isKindOfClass: [NSString class]]);
    _setValue(self, &_value, &_lock, _key, value);
}

- (void) setArrayValue: (NSArray *) value;
{
    OBPRECONDITION(!value || [value isKindOfClass: [NSArray class]]);
    _setValue(self, &_value, &_lock, _key, value);
}

- (void) setDictionaryValue: (NSDictionary *) value;
{
    OBPRECONDITION(!value || [value isKindOfClass: [NSDictionary class]]);
    _setValue(self, &_value, &_lock, _key, value);
}

- (void) setDataValue: (NSData *) value;
{
    OBPRECONDITION(!value || [value isKindOfClass: [NSData class]]);
    _setValue(self, &_value, &_lock, _key, value);
}

- (void) setIntegerValue: (int) value;
{
    NSNumber *number = [[NSNumber alloc] initWithInt: value];
    _setValue(self, &_value, &_lock, _key, number);
    [number release];
}

- (void) setFloatValue: (float) value;
{
    NSNumber *number = [[NSNumber alloc] initWithFloat: value];
    _setValue(self, &_value, &_lock, _key, number);
    [number release];
}

- (void) setBoolValue: (BOOL) value;
{
    NSNumber *number = [[NSNumber alloc] initWithBool: value];
    _setValue(self, &_value, &_lock, _key, number);
    [number release];
}

@end


@implementation OFPreference (Private)

- (id) _initWithKey: (NSString * ) key;
{
    OBPRECONDITION(key);

    _key = [key copy];
    OFSimpleLockInit(&_lock);
    _value = [[standardUserDefaults objectForKey: key] retain];
    
#ifdef DEBUG_PREFERENCES
    NSLog(@"OFPreference(0x%08x:%@) init %@", self, key, _value);
#endif

    return self;
}

@end



@implementation OFPreferenceWrapper : NSObject
+ (OFPreferenceWrapper *) sharedPreferenceWrapper;
{
    static OFPreferenceWrapper *sharedPreferenceWrapper = nil;
    
    if (!sharedPreferenceWrapper)
        sharedPreferenceWrapper = [[self alloc] init];
    return sharedPreferenceWrapper;
}

- (id) retain;
{
    return self;
}

- (void) release;
{
}

- (id) autorelease;
{
    return self;
}

- (void) dealloc;
{
    OBASSERT_NOT_REACHED(OFPreference instance is never deallocated);
}

- (id)objectForKey:(NSString *)defaultName;
{
    return [[OFPreference preferenceForKey: defaultName] objectValue];
}

- (void)setObject:(id)value forKey:(NSString *)defaultName;
{
    return [[OFPreference preferenceForKey: defaultName] setObjectValue: value];
}

- (void)removeObjectForKey:(NSString *)defaultName;
{
    return [[OFPreference preferenceForKey: defaultName] restoreDefaultValue];
}

- (NSString *)stringForKey:(NSString *)defaultName;
{
    return [[OFPreference preferenceForKey: defaultName] stringValue];
}

- (NSArray *)arrayForKey:(NSString *)defaultName;
{
    return [[OFPreference preferenceForKey: defaultName] arrayValue];
}

- (NSDictionary *)dictionaryForKey:(NSString *)defaultName;
{
    return [[OFPreference preferenceForKey: defaultName] dictionaryValue];
}

- (NSData *)dataForKey:(NSString *)defaultName;
{
    return [[OFPreference preferenceForKey: defaultName] dataValue];
}

- (NSArray *)stringArrayForKey:(NSString *)defaultName;
{
    return [[OFPreference preferenceForKey: defaultName] arrayValue];
}

- (int)integerForKey:(NSString *)defaultName;
{
    return [[OFPreference preferenceForKey: defaultName] integerValue];
}

- (float)floatForKey:(NSString *)defaultName; 
{
    return [[OFPreference preferenceForKey: defaultName] floatValue];
}

- (BOOL)boolForKey:(NSString *)defaultName;  
{
    return [[OFPreference preferenceForKey: defaultName] boolValue];
}

- (void)setInteger:(int)value forKey:(NSString *)defaultName;
{
    return [[OFPreference preferenceForKey: defaultName] setIntegerValue: value];
}

- (void)setFloat:(float)value forKey:(NSString *)defaultName;
{
    return [[OFPreference preferenceForKey: defaultName] setFloatValue: value];
}

- (void)setBool:(BOOL)value forKey:(NSString *)defaultName;
{
    return [[OFPreference preferenceForKey: defaultName] setBoolValue: value];
}

- (BOOL)synchronize;
{
    return [standardUserDefaults synchronize];
}

- (void)autoSynchronize;
{
    [standardUserDefaults autoSynchronize];
}

@end

