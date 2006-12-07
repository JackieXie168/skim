// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSMutableDictionary-OFExtensions.h 68913 2005-10-03 19:36:19Z kc $

#import <Foundation/NSDictionary.h>
#import <Foundation/NSGeometry.h> // For NSPoint, NSSize, and NSRect

@interface NSMutableDictionary (OFExtensions)
- (void)setObject:(id)anObject forKeys:(NSArray *)keys;

// These are nice for ease of use
- (void)setFloatValue:(float)value forKey:(NSString *)key;
- (void)setDoubleValue:(double)value forKey:(NSString *)key;
- (void)setIntValue:(int)value forKey:(NSString *)key;
- (void)setUnsignedIntValue:(unsigned int)value forKey:(NSString *)key;
- (void)setBoolValue:(BOOL)value forKey:(NSString *)key;
- (void)setPointValue:(NSPoint)value forKey:(NSString *)key;
- (void)setSizeValue:(NSSize)value forKey:(NSString *)key;
- (void)setRectValue:(NSRect)value forKey:(NSString *)key;

// Setting with default values
- (void)setObject:(id)object forKey:(NSString *)key defaultObject:(id)defaultObject;
- (void)setFloatValue:(float)value forKey:(NSString *)key defaultValue:(float)defaultValue;
- (void)setDoubleValue:(double)value forKey:(NSString *)key defaultValue:(double)defaultValue;
- (void)setIntValue:(int)value forKey:(NSString *)key defaultValue:(int)defaultValue;
- (void)setUnsignedIntValue:(unsigned int)value forKey:(NSString *)key defaultValue:(unsigned int)defaultValue;
- (void)setBoolValue:(BOOL)value forKey:(NSString *)key defaultValue:(BOOL)defaultValue;
- (void)setPointValue:(NSPoint)value forKey:(NSString *)key defaultValue:(NSPoint)defaultValue;
- (void)setSizeValue:(NSSize)value forKey:(NSString *)key defaultValue:(NSSize)defaultValue;
- (void)setRectValue:(NSRect)value forKey:(NSString *)key defaultValue:(NSRect)defaultValue;

@end
