// Copyright 2001-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OFPreference.h,v 1.6 2003/03/10 01:06:37 neo Exp $

#import <Foundation/NSObject.h>
#import <OmniFoundation/OFSimpleLock.h>

@class NSString, NSArray, NSDictionary, NSData;

@interface OFPreference : NSObject
{
    NSString         *_key;
    OFSimpleLockType  _lock;
    id                _value;
}

// API

+ (OFPreference *) preferenceForKey: (NSString *) key;

- (NSString *) key;

- (BOOL) hasNonDefaultValue;
- (void) restoreDefaultValue;

- (id) objectValue;
- (NSString *) stringValue;
- (NSArray *) arrayValue;
- (NSDictionary *) dictionaryValue;
- (NSData *) dataValue;
- (int) integerValue;
- (float) floatValue;
- (BOOL) boolValue;

- (void) setObjectValue: (id) value;
- (void) setStringValue: (NSString *) value;
- (void) setArrayValue: (NSArray *) value;
- (void) setDictionaryValue: (NSDictionary *) value;
- (void) setDataValue: (NSData *) value;
- (void) setIntegerValue: (int) value;
- (void) setFloatValue: (float) value;
- (void) setBoolValue: (BOOL) value;

@end

// This provides an API that is much like NSUserDefaults but goes through the thread-safe OFPreference layer
@interface OFPreferenceWrapper : NSObject
+ (OFPreferenceWrapper *)sharedPreferenceWrapper;

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
