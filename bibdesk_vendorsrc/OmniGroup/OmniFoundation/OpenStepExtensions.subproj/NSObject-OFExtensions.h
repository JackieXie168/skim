// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSObject-OFExtensions.h,v 1.18 2003/01/22 00:58:20 wiml Exp $

#import <Foundation/NSObject.h>
#import <OmniFoundation/FrameworkDefines.h>

@class NSArray, NSMutableArray, NSDictionary;
@class NSBundle, NSScriptObjectSpecifier;

@interface NSObject (OFExtensions)

+ (void)initializeAllClasses;
+ (Class)classImplementingSelector:(SEL)aSelector;

+ (NSBundle *)bundle;
- (NSBundle *)bundle;

@end

@interface NSObject (OFAppleScriptExtensions) 

+ (void)registerConversionFromRecord;
- (BOOL)ignoreAppleScriptValueForKey:(NSString *)key; // implement for keys to ignore for 'make' and record coercion
    // or implement -(BOOL)ignoreAppleScriptValueFor<KeyName>
- (NSDictionary *)appleScriptAsRecord;
- (void)appleScriptTakeAttributesFromRecord:(NSDictionary *)record;
- (NSString *)appleScriptMakeProperties;
- (NSString *)appleScriptMakeCommandAt:(NSString *)aLocationSpecifier;
- (NSString *)appleScriptMakeCommandAt:(NSString *)aLocationSpecifier withIndent:(int)indent;

- (NSScriptObjectSpecifier *)objectSpecifierByProperty:(NSString *)propertyKey inRelation:(NSString *)myLocation toContainer:(NSObject *)myContainer;

@end
