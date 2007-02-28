// Copyright 1997-2006 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSDictionary-OFExtensions.h 79079 2006-09-07 22:35:32Z kc $

#import <Foundation/NSDictionary.h>

#import <OmniFoundation/OFDictionaryInitialization.h>
#import <Foundation/NSGeometry.h> // For NSPoint, NSSize, and NSRect

@class NSAppleEventDescriptor;

@interface NSDictionary (OFExtensions)

+ (NSDictionary *)dictionaryWithUserRecord:(NSAppleEventDescriptor *)descriptor;
- (NSAppleEventDescriptor *)userRecordValue;

- (NSDictionary *)dictionaryWithObject:(id)anObj forKey:(NSString *)key;
- (NSDictionary *)dictionaryByAddingObjectsFromDictionary:(NSDictionary *)otherDictionary;

- (id)anyObject;
- (NSDictionary *)elementsAsInstancesOfClass:(Class)aClass withContext:(id)context;
- (NSString *)keyForObjectEqualTo:(id)anObj;

// ObjC methods to nil have undefined results for non-id values (though ints happen to currently work)
- (float)floatForKey:(NSString *)key defaultValue:(float)defaultValue;
- (float)floatForKey:(NSString *)key;
- (double)doubleForKey:(NSString *)key defaultValue:(double)defaultValue;
- (double)doubleForKey:(NSString *)key;

- (NSPoint)pointForKey:(NSString *)key defaultValue:(NSPoint)defaultValue;
- (NSPoint)pointForKey:(NSString *)key;
- (NSSize)sizeForKey:(NSString *)key defaultValue:(NSSize)defaultValue;
- (NSSize)sizeForKey:(NSString *)key;
- (NSRect)rectForKey:(NSString *)key defaultValue:(NSRect)defaultValue;
- (NSRect)rectForKey:(NSString *)key;

// Returns YES iff the value is YES, Y, yes, y, or 1.
- (BOOL)boolForKey:(NSString *)key defaultValue:(BOOL)defaultValue;
- (BOOL)boolForKey:(NSString *)key;

// Just to make life easier
- (int)intForKey:(NSString *)key defaultValue:(int)defaultValue;
- (int)intForKey:(NSString *)key;
- (unsigned int)unsignedIntForKey:(NSString *)key defaultValue:(unsigned int)defaultValue;
- (unsigned int)unsignedIntForKey:(NSString *)key;

- (unsigned long long int)unsignedLongLongForKey:(NSString *)key defaultValue:(unsigned long long int)defaultValue;
- (unsigned long long int)unsignedLongLongForKey:(NSString *)key;

- (void)makeValuesPerformSelector:(SEL)sel withObject:(id)object;
- (void)makeValuesPerformSelector:(SEL)sel;

    // This seems more convenient than having to write your own if statement a zillion times
- (id)objectForKey:(NSString *)key defaultObject:(id)defaultObject;

- (id)deepMutableCopy;

- (NSDictionary *)deepCopyWithReplacementFunction:(id (*)(id, void *))funct context:(void *)context;

- (NSArray *) copyKeys;

@end

#import <OmniFoundation/FrameworkDefines.h>

OmniFoundation_EXTERN NSString *OmniDictionaryElementNameKey;
