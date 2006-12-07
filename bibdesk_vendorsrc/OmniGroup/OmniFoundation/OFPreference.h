// Copyright 2001-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OFPreference.h,v 1.14 2004/02/10 04:07:41 kc Exp $

#import <Foundation/NSObject.h>
#import <OmniFoundation/OFSimpleLock.h>

@class OFEnumNameTable;
@class NSArray, NSDictionary, NSData, NSSet, NSString;

@interface OFPreference : NSObject
{
    NSString         *_key;
    OFSimpleLockType  _lock;
    unsigned          _generation;
    id                _value;
    id                _defaultValue;
}

// API

+ (OFPreference *) preferenceForKey: (NSString *) key;
+ (OFPreference *) preferenceForKey: (NSString *) key enumeration: (OFEnumNameTable *)enumeration;

+ (NSSet *)registeredKeys;
+ (void)recacheRegisteredKeys;

- (NSString *) key;
- (OFEnumNameTable *) enumeration;

- (id) defaultObjectValue;
- (BOOL) hasNonDefaultValue;
- (void) restoreDefaultValue;

- (id) objectValue;
- (NSString *) stringValue;
- (NSArray *) arrayValue;
- (NSDictionary *) dictionaryValue;
- (NSData *) dataValue;
- (int) integerValue;
- (unsigned int) unsignedIntValue;
- (float) floatValue;
- (BOOL) boolValue;
- (int) enumeratedValue;

- (void) setObjectValue: (id) value;
- (void) setStringValue: (NSString *) value;
- (void) setArrayValue: (NSArray *) value;
- (void) setDictionaryValue: (NSDictionary *) value;
- (void) setDataValue: (NSData *) value;
- (void) setIntegerValue: (int) value;
- (void) setFloatValue: (float) value;
- (void) setBoolValue: (BOOL) value;
- (void) setEnumeratedValue: (int) value;

@end

// This provides an API that is much like NSUserDefaults but goes through the thread-safe OFPreference layer
@interface OFPreferenceWrapper : NSObject
+ (OFPreferenceWrapper *)sharedPreferenceWrapper;

- (OFPreference *) preferenceForKey: (NSString *) key;

- (id)objectForKey:(NSString *)defaultName;
- (void)setObject:(id)value forKey:(NSString *)defaultName;
- (void)removeObjectForKey:(NSString *)defaultName;
- (NSString *)stringForKey:(NSString *)defaultName;
- (NSArray *)arrayForKey:(NSString *)defaultName;
- (NSDictionary *)dictionaryForKey:(NSString *)defaultName;
- (NSData *)dataForKey:(NSString *)defaultName;
- (NSArray *)stringArrayForKey:(NSString *)defaultName;
- (int)integerForKey:(NSString *)defaultName; 
- (float)floatForKey:(NSString *)defaultName; 
- (BOOL)boolForKey:(NSString *)defaultName;  
- (void)setInteger:(int)value forKey:(NSString *)defaultName;
- (void)setFloat:(float)value forKey:(NSString *)defaultName;
- (void)setBool:(BOOL)value forKey:(NSString *)defaultName;

- (BOOL)synchronize;
- (void)autoSynchronize;
@end

extern NSString *OFPreferenceDidChangeNotification;
