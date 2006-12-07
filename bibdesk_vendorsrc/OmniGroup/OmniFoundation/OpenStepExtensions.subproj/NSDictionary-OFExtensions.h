// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSDictionary-OFExtensions.h,v 1.17 2004/02/10 04:07:45 kc Exp $

#import <Foundation/NSDictionary.h>

#import <OmniFoundation/OFDictionaryInitialization.h>
#import <OmniFoundation/FrameworkDefines.h>

OmniFoundation_EXTERN NSString *OmniDictionaryElementNameKey;

@interface NSDictionary (OFExtensions)

- (NSDictionary *)dictionaryWithObject:anObj forKey:(NSString *)key;

- (id)anyObject;
- (NSDictionary *)elementsAsInstancesOfClass:(Class)aClass withContext:(id)context;
- (NSString *)keyForObjectEqualTo:(id)anObj;

// ObjC doesn't return 0.0 if you send a message returning float or double to a nil
- (float)floatForKey:(NSString *)key defaultValue:(float)defaultValue;
- (float)floatForKey:(NSString *)key;
- (double)doubleForKey:(NSString *)key defaultValue:(double)defaultValue;
- (double)doubleForKey:(NSString *)key;

// Returns YES iff the value is YES, Y, yes, y, or 1.
- (BOOL)boolForKey:(NSString *)key defaultValue:(BOOL)defaultValue;
- (BOOL)boolForKey:(NSString *)key;

// Just to make life easier
- (int)intForKey:(NSString *)key defaultValue:(int)defaultValue;
- (int)intForKey:(NSString *)key;

// This seems more convenient than having to write your own if statement a zillion times
- (id)objectForKey:(NSString *)key defaultObject:(id)defaultObject;

- (id)deepMutableCopy;

- (NSDictionary *)deepCopyWithReplacementFunction:(id (*)(id, void *))funct context:(void *)context;

- (NSArray *) copyKeys;

@end
