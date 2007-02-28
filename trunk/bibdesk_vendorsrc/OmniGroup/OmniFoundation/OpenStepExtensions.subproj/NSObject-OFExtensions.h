// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSObject-OFExtensions.h 68913 2005-10-03 19:36:19Z kc $

#import <Foundation/NSObject.h>
#import <OmniFoundation/FrameworkDefines.h>

@class NSArray, NSMutableArray, NSDictionary;
@class NSBundle, NSScriptObjectSpecifier;

@interface NSObject (OFExtensions)

+ (Class)classImplementingSelector:(SEL)aSelector;

+ (NSBundle *)bundle;
- (NSBundle *)bundle;

@end

@interface NSObject (OFAppleScriptExtensions) 

+ (void)registerConversionFromRecord;
+ (id)coerceRecord:(NSDictionary *)dictionary toClass:(Class)aClass;
+ (id)coerceObject:(id)object toRecordClass:(Class)aClass;


- (BOOL)ignoreAppleScriptValueForKey:(NSString *)key; // implement for keys to ignore for 'make' and record coercion
    // or implement -(BOOL)ignoreAppleScriptValueFor<KeyName>
- (NSDictionary *)appleScriptAsRecord;
- (void)appleScriptTakeAttributesFromRecord:(NSDictionary *)record;
- (NSString *)appleScriptMakeProperties;
- (NSString *)appleScriptMakeCommandAt:(NSString *)aLocationSpecifier;
- (NSString *)appleScriptMakeCommandAt:(NSString *)aLocationSpecifier withIndent:(int)indent;

- (NSScriptObjectSpecifier *)objectSpecifierByProperty:(NSString *)propertyKey inRelation:(NSString *)myLocation toContainer:(NSObject *)myContainer;

@end
