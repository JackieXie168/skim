// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSMutableDictionary-OFExtensions.h,v 1.8 2003/01/15 22:52:00 kc Exp $

#import <Foundation/NSDictionary.h>

@interface NSMutableDictionary (OFExtensions)
- (void)setObject:(id)anObject forKeys:(NSArray *)keys;

// These are nice for ease of use
- (void)setFloatValue:(float)value forKey:(NSString *)key;
- (void)setDoubleValue:(double)value forKey:(NSString *)key;
- (void)setIntValue:(int)value forKey:(NSString *)key;
- (void)setBoolValue:(BOOL)value forKey:(NSString *)key;

// Setting with defaults
- (void)setObject:(id)object forKey:(id)key defaultObject:(id)defaultObject;
- (void)setFloatValue:(float)value forKey:(id)key defaultValue:(float)defaultValue;
- (void)setDoubleValue:(double)value forKey:(id)key defaultValue:(double)defaultValue;
- (void)setIntValue:(int)value forKey:(id)key defaultValue:(int)defaultValue;
- (void)setBoolValue:(BOOL)value forKey:(id)key defaultValue:(BOOL)defaultValue;

@end
