// Copyright 2001-2006 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OFPreference.h"

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

#import "OFEnumNameTable.h"
#import "NSUserDefaults-OFExtensions.h"
#import "OFNull.h"

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/OFPreference.m 79079 2006-09-07 22:35:32Z kc $");

//#define DEBUG_PREFERENCES

static NSUserDefaults *standardUserDefaults;
static NSMutableDictionary *preferencesByKey;
static NSLock *preferencesLock;
static NSSet *registeredKeysCache;
static NSObject *unset = nil;
static volatile unsigned registrationGeneration = 1;
static NSNotificationCenter *preferenceNotificationCenter = nil;

NSString *OFPreferenceDidChangeNotification = @"OFPreferenceDidChangeNotification";

@interface OFPreference (Private)
- (id) _initWithKey: (NSString * ) key;
- (void)_refresh;
@end

@interface OFEnumeratedPreference : OFPreference
{
    OFEnumNameTable *names;
}

- (id) _initWithKey: (NSString * ) key enumeration: (OFEnumNameTable *)enumeration;

@end

@implementation OFPreference

static id _retainedObjectValue(OFPreference *self, id *_value, NSString *key)
{
    id result = nil;

    @synchronized(self) {
        if (self->_generation != registrationGeneration)
            result = [unset retain];
        else
            result = [*_value retain];
    }
    
    if (result == unset) {
        [result release];
        [self _refresh];
        return _retainedObjectValue(self, _value, key); // gcc does tail-call optimization
    }

#ifdef DEBUG_PREFERENCES
    NSLog(@"OFPreference(0x%08x:%@) -> %@", self, key, result);
#endif

    return result;
}

static inline id _objectValue(OFPreference *self, id *_value, NSString *key, NSString *className)
{
    id result = [_retainedObjectValue(self, _value, key) autorelease];

    // We use a class name rather than a class to avoid calling +class when assertions are off
    OBASSERT(!result || [result isKindOfClass: NSClassFromString(className)]);

    return result;
}

static void _setValue(id self, id *_value, NSString *key, id value)
{
    @synchronized(self) {
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
            *_value = [unset retain];

#ifdef DEBUG_PREFERENCES
            NSLog(@"OFPreference(0x%08x:%@) <- nil (is now %@)", self, key, *_value);
#endif
        }
    }
    
    // Tell anyone who is interested that this default changed
    [preferenceNotificationCenter postNotificationName:OFPreferenceDidChangeNotification object:self];
}

+ (void) initialize;
{
    OBINITIALIZE;
    
    standardUserDefaults = [[NSUserDefaults standardUserDefaults] retain];
    [standardUserDefaults volatileDomainForName:NSRegistrationDomain]; // avoid a race condition
    preferencesByKey = [[NSMutableDictionary alloc] init];
    preferencesLock = [[NSLock alloc] init];
    unset = [[NSObject alloc] init];  // just getting a guaranteed-unique, retainable/releasable object
    
    preferenceNotificationCenter = [[NSNotificationCenter alloc] init];
}

+ (NSSet *)registeredKeys
{
    NSSet *result;

    [preferencesLock lock];

    if (registeredKeysCache == nil) {
        NSMutableSet *keys = [[NSMutableSet alloc] init];
        [keys addObjectsFromArray:[preferencesByKey allKeys]];
        [keys addObjectsFromArray:[[standardUserDefaults volatileDomainForName:NSRegistrationDomain] allKeys]];
        registeredKeysCache = [keys copy];
        [keys release];
    }

    result = [registeredKeysCache retain];

    [preferencesLock unlock];

    return [result autorelease];
}

+ (void)recacheRegisteredKeys
{
    [preferencesLock lock];
    [registeredKeysCache release];
    registeredKeysCache = nil;
    registrationGeneration ++;
    [preferencesLock unlock];
}

+ (void)addObserver:(id)anObserver selector:(SEL)aSelector forPreference:(OFPreference *)aPreference;
{
    [preferenceNotificationCenter addObserver:anObserver selector:aSelector name:OFPreferenceDidChangeNotification object:aPreference];
}

+ (void)removeObserver:(id)anObserver forPreference:(OFPreference *)aPreference;
{
    [preferenceNotificationCenter removeObserver:anObserver name:OFPreferenceDidChangeNotification object:aPreference];
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
    [_key release];
    [_value release];
    [_defaultValue release];
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
    return [self preferenceForKey:key enumeration:nil];
}

+ (OFPreference *) preferenceForKey: (NSString *) key enumeration: (OFEnumNameTable *)enumeration;
{
    OFPreference *preference;
    
    OBPRECONDITION(key);
    
    [preferencesLock lock];
    preference = [[preferencesByKey objectForKey: key] retain];
    if (!preference) {
        if (enumeration == nil) {
            preference = [[self alloc] _initWithKey: key];
        } else {
            preference = [[OFEnumeratedPreference alloc] _initWithKey: key enumeration: enumeration];
        }
        [preferencesByKey setObject: preference forKey: key];
    }
    [preferencesLock unlock];

    if (enumeration != nil) {
        // It's OK to pass in a nil value for the enumeration, if you know that the enumeration has already been set up
        OBPOSTCONDITION([[preference enumeration] isEqual: enumeration]);
    }
    
    return [preference autorelease];
}

- (NSString *) key;
{
    return _key;
}

- (OFEnumNameTable *) enumeration
{
    return nil;
}

- (id) defaultObjectValue;
{
    NSDictionary *registrationDictionary;
    id defaultValue;

    @synchronized(self) {
	if (_defaultValue != nil && _generation != registrationGeneration) {
	    [_defaultValue release];
	    _defaultValue = nil;
	}
	defaultValue = _defaultValue;
    }

    if (defaultValue != nil)
        return _defaultValue;

    registrationDictionary = [standardUserDefaults volatileDomainForName:NSRegistrationDomain];
    defaultValue = [registrationDictionary objectForKey:_key];

    @synchronized(self) {
	if (_defaultValue == nil)
	    _defaultValue = [defaultValue retain];
    }

    return defaultValue;
}

- (BOOL) hasNonDefaultValue;
{
    id value, defaultValue;

    value = [self objectValue];
    defaultValue = [self defaultObjectValue];
    
    return !OFISEQUAL(value, defaultValue);
}


- (void) restoreDefaultValue;
{
    _setValue(self, &_value, _key, nil);
}

- (id) objectValue;
{
    return _objectValue(self, &_value, _key, @"NSObject");
}

- (NSString *) stringValue;
{
    return [[self objectValue] description];
}

- (NSArray *) arrayValue;
{
    return _objectValue(self, &_value, _key, @"NSArray");
}

- (NSDictionary *) dictionaryValue;
{
    return _objectValue(self, &_value, _key, @"NSDictionary");
}

- (NSData *) dataValue;
{
    return _objectValue(self, &_value, _key, @"NSData");
}

- (int) integerValue;
{
    id number;
    int result;

    number = _retainedObjectValue(self, &_value, _key);
    OBASSERT(!number || [number isKindOfClass: [NSNumber class]] || [number isKindOfClass: [NSString class]]);
    if (number)
        result = [number intValue];
    else
        result = 0;
    [number release];
#ifdef DEBUG_PREFERENCES
    NSLog(@"OFPreference(0x%08x:%@) %s -> %d", self, _key, _cmd, result);
#endif
    
    return result;
}

- (unsigned int) unsignedIntValue;
{
    id number;
    unsigned int result;

    number = _retainedObjectValue(self, &_value, _key);
    OBASSERT(!number || [number isKindOfClass: [NSNumber class]] || [number isKindOfClass: [NSString class]]);
    if (number)
        result = [number unsignedIntValue];
    else
        result = 0;
    [number release];
#ifdef DEBUG_PREFERENCES
    NSLog(@"OFPreference(0x%08x:%@) %s -> %d", self, _key, _cmd, result);
#endif

    return result;
}

- (float) floatValue;
{
    id number;
    float result;

    number = _retainedObjectValue(self, &_value, _key);
    OBASSERT(!number || [number isKindOfClass: [NSNumber class]] || [number isKindOfClass: [NSString class]]);
    if (number)
        result = [number floatValue];
    else
        result = 0.0;
    [number release];
#ifdef DEBUG_PREFERENCES
    NSLog(@"OFPreference(0x%08x:%@) %s -> %f", self, _key, _cmd, result);
#endif

    return result;
}

- (BOOL) boolValue;
{
    id number;
    BOOL result;

    number = _retainedObjectValue(self, &_value, _key);
    OBASSERT(!number || [number isKindOfClass: [NSNumber class]] || [number isKindOfClass: [NSString class]]);
    if (number)
        result = [number boolValue];
    else
        result = NO;
    [number release];
#ifdef DEBUG_PREFERENCES
    NSLog(@"OFPreference(0x%08x:%@) %s -> %s", self, _key, _cmd, result ? "YES" : "NO");
#endif

    return result;
}

- (int) enumeratedValue
{
    [NSException raise:NSInvalidArgumentException format:@"-%s called on non-enumerated %@ (%@)", _cmd, [self shortDescription], _key];
    return INT_MIN; // unreached; and unlikely to be a valid enumeration value
}

- (void) setObjectValue: (id) value;
{
    _setValue(self, &_value, _key, value);
}

- (void) setStringValue: (NSString *) value;
{
    OBPRECONDITION(!value || [value isKindOfClass: [NSString class]]);
    _setValue(self, &_value, _key, value);
}

- (void) setArrayValue: (NSArray *) value;
{
    OBPRECONDITION(!value || [value isKindOfClass: [NSArray class]]);
    _setValue(self, &_value, _key, value);
}

- (void) setDictionaryValue: (NSDictionary *) value;
{
    OBPRECONDITION(!value || [value isKindOfClass: [NSDictionary class]]);
    _setValue(self, &_value, _key, value);
}

- (void) setDataValue: (NSData *) value;
{
    OBPRECONDITION(!value || [value isKindOfClass: [NSData class]]);
    _setValue(self, &_value, _key, value);
}

- (void) setIntegerValue: (int) value;
{
    NSNumber *number = [[NSNumber alloc] initWithInt: value];
    _setValue(self, &_value, _key, number);
    [number release];
}

- (void) setUnsignedIntegerValue: (int) value;
{
    NSNumber *number = [[NSNumber alloc] initWithUnsignedInt: value];
    _setValue(self, &_value, _key, number);
    [number release];
}

- (void) setFloatValue: (float) value;
{
    NSNumber *number = [[NSNumber alloc] initWithFloat: value];
    _setValue(self, &_value, _key, number);
    [number release];
}

- (void) setBoolValue: (BOOL) value;
{
    NSNumber *number = [[NSNumber alloc] initWithBool: value];
    _setValue(self, &_value, _key, number);
    [number release];
}

- (void) setEnumeratedValue: (int) value;
{
    [NSException raise:NSInvalidArgumentException format:@"-%s called on non-enumerated %@ (%@)", _cmd, [self shortDescription], _key];
}

@end


@implementation OFPreference (Private)

- (id) _initWithKey: (NSString * ) key;
{
    OBPRECONDITION(key != nil);

    _key = [key copy];
    _generation = 0;
    _value = [unset retain];
    
    return self;
}

- (void)_refresh
{
    unsigned newGeneration;
    id newValue;

    [preferencesLock lock];

#ifdef DEBUG
    if (![_key hasPrefix:@"SiteSpecific:"] && ![[standardUserDefaults volatileDomainForName:NSRegistrationDomain] objectForKey:_key]) {
        NSLog(@"OFPreference: No default value is registered for '%@'", _key);
        OBPRECONDITION([[standardUserDefaults volatileDomainForName:NSRegistrationDomain] objectForKey:_key]);
    }
#endif

    newGeneration = registrationGeneration;
    newValue = [[standardUserDefaults objectForKey: _key] retain];
    [preferencesLock unlock];

#ifdef DEBUG_PREFERENCES
    NSLog(@"OFPreference(0x%08x:%@) faulting in value %@ generation %u", self, _key, newValue, newGeneration);
#endif

    @synchronized(self) {
	if (_value == unset) {
	    [_value release];
	    _value = newValue;
	} else {
	    [newValue release];
	}
	if (_generation != newGeneration) {
	    [_defaultValue release];
	    _defaultValue = nil;
	    _generation = newGeneration;
	}
    }
}

@end

@implementation OFEnumeratedPreference

- (id) _initWithKey: (NSString * ) key enumeration: (OFEnumNameTable *)enumeration;
{
    self = [super _initWithKey:key];
    names = [enumeration retain];
    return self;
}

// no -dealloc: we are never deallocated

- (OFEnumNameTable *) enumeration
{
    return names;
}

- (id) defaultObjectValue
{
    id defaultValue = [super defaultObjectValue];
    if (defaultValue == nil)
        return [names nameForEnum:[names defaultEnumValue]];
    else
        return defaultValue;
}

#define BAD_TYPE_IMPL(x) { [NSException raise:NSInvalidArgumentException format:@"-%s called on enumerated %@ (%@)", _cmd, [self shortDescription], _key]; x; }

- (NSString *) stringValue;            BAD_TYPE_IMPL(return nil)
- (NSArray *) arrayValue;              BAD_TYPE_IMPL(return nil)
- (NSDictionary *) dictionaryValue;    BAD_TYPE_IMPL(return nil)
- (NSData *) dataValue;                BAD_TYPE_IMPL(return nil)
- (int) integerValue;                  BAD_TYPE_IMPL(return 0)
- (unsigned int) unsignedIntValue;     BAD_TYPE_IMPL(return 0)
- (float) floatValue;                  BAD_TYPE_IMPL(return 0)
- (BOOL) boolValue;                    BAD_TYPE_IMPL(return NO)

- (int) enumeratedValue;
{
    return [names enumForName:[super stringValue]];
}

- (void) setStringValue: (NSString *) value;            BAD_TYPE_IMPL(;)
- (void) setArrayValue: (NSArray *) value;              BAD_TYPE_IMPL(;)
- (void) setDictionaryValue: (NSDictionary *) value;    BAD_TYPE_IMPL(;)
- (void) setDataValue: (NSData *) value;                BAD_TYPE_IMPL(;)
- (void) setIntegerValue: (int) value;                  BAD_TYPE_IMPL(;)
- (void) setFloatValue: (float) value;                  BAD_TYPE_IMPL(;)
- (void) setBoolValue: (BOOL) value;                    BAD_TYPE_IMPL(;)

- (void) setEnumeratedValue: (int) value;
{
    [self setObjectValue:[names nameForEnum:value]];
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

- (OFPreference *) preferenceForKey: (NSString *) key;
{
    return [OFPreference preferenceForKey:key];
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
    OBASSERT_NOT_REACHED("OFPreference instance is never deallocated");
	
	// Squelch the warning that 10.4 emits.
	return;
	[super dealloc];
}

- (id)objectForKey:(NSString *)defaultName;
{
    return [[OFPreference preferenceForKey: defaultName] objectValue];
}

- (void)setObject:(id)value forKey:(NSString *)defaultName;
{
    [[OFPreference preferenceForKey: defaultName] setObjectValue: value];
}

- (id)valueForKey:(NSString *)aKey;
{
    return [[OFPreference preferenceForKey: aKey] objectValue];
}

- (void)setValue:(id)value forKey:(NSString *)aKey;
{
    [[OFPreference preferenceForKey: aKey] setObjectValue: value];
}

- (void)removeObjectForKey:(NSString *)defaultName;
{
    [[OFPreference preferenceForKey: defaultName] restoreDefaultValue];
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
    [[OFPreference preferenceForKey: defaultName] setIntegerValue: value];
}

- (void)setFloat:(float)value forKey:(NSString *)defaultName;
{
    [[OFPreference preferenceForKey: defaultName] setFloatValue: value];
}

- (void)setBool:(BOOL)value forKey:(NSString *)defaultName;
{
    [[OFPreference preferenceForKey: defaultName] setBoolValue: value];
}

- (BOOL)synchronize;
{
    return [standardUserDefaults synchronize];
}

- (void)autoSynchronize;
{
    [standardUserDefaults autoSynchronize];
}

- (NSDictionary *)volatileDomainForName:(NSString *)name;
{
    return [[NSUserDefaults standardUserDefaults] volatileDomainForName:name];
}

@end

