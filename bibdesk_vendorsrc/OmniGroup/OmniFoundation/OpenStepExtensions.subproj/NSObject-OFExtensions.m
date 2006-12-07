// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import <OmniFoundation/NSObject-OFExtensions.h>
#import "NSString-OFExtensions.h"
#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSObject-OFExtensions.m,v 1.41 2003/03/26 21:19:19 toon Exp $")

// These methods were introduced in 10.2.  We test to make sure the target responds before sending them, but we want to declare them as well so we won't get warnings on 10.1

@interface NSScriptObjectSpecifier (JaguarAPI)
- (id)initWithContainerClassDescription:(NSScriptClassDescription *)classDesc containerSpecifier:(NSScriptObjectSpecifier *)container key:(NSString *)property uniqueID:(id)uniqueID;
- (id)initWithContainerClassDescription:(NSScriptClassDescription *)classDesc containerSpecifier:(NSScriptObjectSpecifier *)container key:(NSString *)property name:(NSString *)name;
@end

@implementation NSObject (OFExtensions)

// +initializeAllClasses is necessary because class_initialize() isn't thread safe.  That is, a given +initialize can be called simultaneously in several threads, which not only confuses it, but can also confuse the runtime.

+ (void)didLoad;
{
    NSString *processName;

    // Call +initializeAllClasses when the app is about to go multithreaded.  This gives IB fits, so don't do it in common utility applications.
    processName = [[NSProcessInfo processInfo] processName];
    if (![processName isEqualToString:@"InterfaceBuilder"] && ![processName isEqualToString:@"EOModeler"])
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(initializeAllClasses) name:NSWillBecomeMultiThreadedNotification object:nil];
}


#define SKIP_CLASS_NAMED(aName) \
do { \
    Class aClass; \
 \
    aClass = NSClassFromString(aName); \
    if (aClass != nil) \
        NSHashInsertKnownAbsent(skipClasssesHashTable, aClass); \
} while (0)

+ (void)initializeAllClasses;
{
    static NSHashTable *skipClasssesHashTable = NULL;
    int classCount = 0, newClassCount;
    Class *classes = NULL;
    Method initializeMethod;
    SEL initializeSelector = @selector(initialize);

    OMNI_POOL_START {

        if (skipClasssesHashTable == NULL) {
            skipClasssesHashTable = NSCreateHashTable(NSNonOwnedPointerHashCallBacks, 20);
            // Skip some classes we never want to initialize
            SKIP_CLASS_NAMED(@"HTMLCheckBoxInspector");
            SKIP_CLASS_NAMED(@"HTMLPageToolbarController");
            SKIP_CLASS_NAMED(@"NMSScriptedClass");
            SKIP_CLASS_NAMED(@"NSDataLinkManager");
            SKIP_CLASS_NAMED(@"NSInvocationBuilder");
            SKIP_CLASS_NAMED(@"NSMovieView");
            SKIP_CLASS_NAMED(@"NSSimpleNumberFormatter");
            SKIP_CLASS_NAMED(@"NSTabView");
            SKIP_CLASS_NAMED(@"OFForwardObject");
            SKIP_CLASS_NAMED(@"OFRetainableObject");
        }

        // Get the class list
        newClassCount = objc_getClassList(NULL, 0);
        while (classCount < newClassCount) {
            classCount = newClassCount;
            classes = realloc(classes, sizeof(Class) * classCount);
            newClassCount = objc_getClassList(classes, classCount);
        }
        // Now, use the class list; if NULL, there are no classes.  (And that would happen how?  Oh well, might as well code this safely...)
        if (classes != NULL) {
            unsigned int classIndex;
            
            // Loop over the gathered classes
            for (classIndex = 0; classIndex < classCount; classIndex++) {
                Class aClass;
                NSString *className;

                aClass = classes[classIndex];
                className = NSStringFromClass(aClass);
                if (CLS_GETINFO(aClass->isa, CLS_INITIALIZED) || NSHashGet(skipClasssesHashTable, aClass))
                    continue;
                if ([className hasPrefix:@"NSZombie"]) {
                    // Hangs in GDB under Mac OS X DP3.
                    SKIP_CLASS_NAMED(className);
                    continue;
                }
                initializeMethod = class_getClassMethod(aClass, initializeSelector);
                if (initializeMethod) {
                    NS_DURING {
                        // NSLog(@"Initializing class: %s", aClass->name);
                        [aClass class];
                    } NS_HANDLER {
                        fprintf(stderr, "Exception raised by +[%s class]: %s\n", aClass->name, [[localException reason] UTF8String]);
                    } NS_ENDHANDLER;
                }
            }
        }

        // Free the class list
        free(classes);

    } OMNI_POOL_END;
}

static BOOL implementsInstanceMethod(struct objc_class *class, SEL aSelector)
{
    struct objc_method_list *methodList;
    int methodIndex;

    /* Check only this class, NOT any superclasses. */

#if defined(OBJC_NEXT_METHOD_LIST)
    void *iterator = 0;
    while ((methodList = class_nextMethodList(class, &iterator))) {
#else
    for (methodList = class->methods; methodList; methodList = methodList->method_next) {
#endif
        for (methodIndex = 0; methodIndex < methodList->method_count; methodIndex++) {
            if (methodList->method_list[methodIndex].method_name == aSelector)
                return YES;
        }
    }
    return NO;
}

+ (Class)classImplementingSelector:(SEL)aSelector;
{
    Class aClass = self;

    while (aClass) {
        if (implementsInstanceMethod(aClass, aSelector))
            return aClass;
        aClass = aClass->super_class;
    }

    return Nil;
}

+ (NSBundle *)bundle;
{
    return [NSBundle bundleForClass:self];
}

- (NSBundle *)bundle;
{
    return [isa bundle];
}

@end

@implementation NSObject (OFASExtensions) 

+ (id)coerceRecord:(NSDictionary *)dictionary toClass:(Class)aClass
{
    id result = [[aClass alloc] init];

    [result appleScriptTakeAttributesFromRecord:dictionary];
    return result;
}

+ (id)coerceObject:(id)object toRecordClass:(Class)aClass;
{
    return [object appleScriptAsRecord];
}

+ (void)registerConversionFromRecord;
{
    NSScriptCoercionHandler *handler = [NSScriptCoercionHandler sharedCoercionHandler];
    [handler registerCoercer:self selector:@selector(coerceObject:toRecordClass:) toConvertFromClass:self toClass:[NSDictionary class]];
    [handler registerCoercer:self selector:@selector(coerceRecord:toClass:) toConvertFromClass:[NSDictionary class] toClass:self];
}

- (BOOL)ignoreAppleScriptValueForClassID;
{
    return YES;
}

- (BOOL)ignoreAppleScriptValueForKey:(NSString *)key;
{
    static NSMutableDictionary *keyToIgnoreSelectorMapping = nil;
    NSString *selectorName;
    SEL selector;
    
    selector = [[keyToIgnoreSelectorMapping objectForKey:key] pointerValue];
    if (!selector) {
        if (!keyToIgnoreSelectorMapping)
            keyToIgnoreSelectorMapping = [[NSMutableDictionary alloc] init];
            
        selectorName = [NSString stringWithFormat:@"ignoreAppleScriptValueFor%@%@", [[key substringToIndex:1] uppercaseString], [key substringFromIndex:1]];
        selector = NSSelectorFromString(selectorName);
        [keyToIgnoreSelectorMapping setObject:[NSValue valueWithPointer:selector] forKey:key];
    }

    if ([self respondsToSelector:selector])
        return (BOOL)(int)[self performSelector:selector];
    else
        return NO;
}

- (NSDictionary *)appleScriptAsRecord;
{
    NSMutableDictionary *record;
    NSEnumerator *enumerator;
    NSScriptClassDescription *classDescription;
    NSString *key;
    
    record = [NSMutableDictionary dictionary];
    classDescription = (NSScriptClassDescription *)[self classDescription];
    enumerator = [[classDescription attributeKeys] objectEnumerator];
    while ((key = [enumerator nextObject])) {
        if ([self ignoreAppleScriptValueForKey:key])
            continue;
            
        [record setObject:[self valueForKey:key] forKey:[NSNumber numberWithUnsignedLong:[classDescription appleEventCodeForKey:key]]];        
    }
    return record;
}

- (void)appleScriptTakeAttributesFromRecord:(NSDictionary *)record;
{
    NSEnumerator *enumerator;
    NSNumber *eventCode;
    NSScriptClassDescription *classDescription;
    NSString *key;
    
    classDescription = (NSScriptClassDescription *)[self classDescription];
    enumerator = [record keyEnumerator];
    while ((eventCode = [enumerator nextObject])) {
        key = [classDescription keyWithAppleEventCode:[eventCode unsignedLongValue]];
        if (!key || [classDescription isReadOnlyKey:key])
            continue;
        
        [self replaceValueAtIndex:0 inPropertyWithKey:key withValue:[self coerceValue:[record objectForKey:eventCode] forKey:key]];
    }
}


- (NSDictionary *)_appleScriptTerminologyForSuite:(NSString *)suiteName;
{
    static NSMutableDictionary *cachedTerminology = nil;
    NSDictionary *result;
    
    if (!cachedTerminology)
        cachedTerminology = [[NSMutableDictionary alloc] init];
        
    if (!(result = [cachedTerminology objectForKey:suiteName])) {
        NSString *path;
        NSBundle *bundle;
        
        bundle = [[NSScriptSuiteRegistry sharedScriptSuiteRegistry] bundleForSuite:suiteName];
        path = [bundle pathForResource:suiteName ofType:@"scriptTerminology"];
        if (!path)
            return nil;
        result = [[NSDictionary alloc] initWithContentsOfFile:path];
        [cachedTerminology setObject:result forKey:suiteName];
        [result release];
    }
    return [result objectForKey:@"Classes"];
}


- (NSDictionary *)_mappingForEnumeration:(NSString *)typeName;
{
    static NSMutableDictionary *cachedEnumerations = nil;
    NSMutableDictionary *mapping;
    NSScriptClassDescription *classDescription;
    NSString *path;
    NSBundle *bundle;
    NSDictionary *suiteInfo, *typeInfo;
    NSString *type;
    NSEnumerator *enumerator, *codeEnumerator;

    if (!cachedEnumerations)
        cachedEnumerations = [[NSMutableDictionary alloc] init];
    if ((mapping = [cachedEnumerations objectForKey:typeName]))
        return mapping;
    
    classDescription = (NSScriptClassDescription *)[self classDescription];
    bundle = [[NSScriptSuiteRegistry sharedScriptSuiteRegistry] bundleForSuite:[classDescription suiteName]];
    path = [bundle pathForResource:[classDescription suiteName] ofType:@"scriptSuite"];
    if (!path)
        return nil;
    suiteInfo = [NSDictionary dictionaryWithContentsOfFile:path];
    suiteInfo = [suiteInfo objectForKey:@"Enumerations"];
    enumerator = [suiteInfo keyEnumerator];
    while ((type = [enumerator nextObject])) {
        NSString *code, *value;
        
        typeInfo = [[suiteInfo objectForKey:type] objectForKey:@"Enumerators"];
        mapping = [[NSMutableDictionary alloc] init];
        codeEnumerator = [typeInfo keyEnumerator];
        while ((value = [codeEnumerator nextObject])) {
            code = [typeInfo objectForKey:value];
            [mapping setObject:value forKey:[NSNumber numberWithLong:[code fourCharCodeValue]]];
        }
        [cachedEnumerations setObject:mapping forKey:type];
        [mapping release];
    }
    return [cachedEnumerations objectForKey:typeName];
}

- (NSDictionary *)_attributeNameForKey:(NSString *)key;
{
    NSDictionary *terminology;
    NSScriptClassDescription *classDescription, *test;

    classDescription = (NSScriptClassDescription *)[self classDescription];
    while (1) {
        test = [classDescription superclassDescription];
        if (![test appleEventCodeForKey:key])
            break;
        classDescription = test;
    }

    terminology = [self _appleScriptTerminologyForSuite:[classDescription suiteName]];
    return [[[[terminology objectForKey:[classDescription className]] objectForKey:@"Attributes"] objectForKey:key] objectForKey:@"Name"];
}

- (id)appleScriptBlankInit;
{
    return [self init];
}

- (NSDictionary *)_defaultValuesDictionary;
{
    static NSMutableDictionary *cachedDefaultValues = nil;
    NSMutableDictionary *result;
    NSScriptClassDescription *classDescription;
    
    classDescription = (NSScriptClassDescription *)[self classDescription];

    if (!(result = [cachedDefaultValues objectForKey:[classDescription className]])) {
        NSEnumerator *enumerator;
        id blankObject, value;
        NSString *key;
        
        blankObject = [[NSClassFromString([classDescription className]) alloc] appleScriptBlankInit];
        result = [[NSMutableDictionary alloc] init];
        enumerator = [[classDescription attributeKeys] objectEnumerator];
        while ((key = [enumerator nextObject])) {
            if ([classDescription isReadOnlyKey:key])
                continue;
            value = [blankObject valueForKey:key];
            if (value)
                [result setObject:value forKey:key];
        }
        if (!cachedDefaultValues)
            cachedDefaultValues = [[NSMutableDictionary alloc] init];
        [cachedDefaultValues setObject:result forKey:[classDescription className]];
        [result release];
        [blankObject release];
    }
    return result;
}

- (NSString *)stringValueForValue:(id)value ofKey:(NSString *)key;
{
    NSString *type, *enumerationValue;
    NSArray *arrayValue;
    NSScriptCoercionHandler *coercer;

    if ([value isKindOfClass:[NSString class]])
        return [NSString stringWithFormat:@"\"%@\"", value];

    if ([value isKindOfClass:[NSNumber class]]) {
        type = [(NSScriptClassDescription *)[self classDescription] typeForKey:key];
        if ([type hasPrefix:@"NSNumber<"]) {
            type = [type substringFromIndex:9];
            type = [type substringToIndex:[type length] - 1];
            if ([type isEqualToString:@"Bool"]) {
                return [value boolValue] ? @"true" : @"false";
            } else if ((enumerationValue = [[self _mappingForEnumeration:type] objectForKey:value])) {
                return enumerationValue;
            }
        }
        return value;
    }

    if ([value isKindOfClass:[NSArray class]]) {
        NSMutableArray *parts;
        int index, count;
        
        parts = [NSMutableArray array];
        count = [value count];
        for (index = 0; index < count; index++)
            [parts addObject:[self stringValueForValue:[value objectAtIndex:index] ofKey:key]];
        return [NSString stringWithFormat:@"{%@}", [parts componentsJoinedByString:@", "]];
    }

    coercer = [NSScriptCoercionHandler sharedCoercionHandler];
    arrayValue = [coercer coerceValue:value toClass:[NSArray class]];
    if ([arrayValue isKindOfClass:[NSArray class]])
        return [NSString stringWithFormat:@"{%@}", [arrayValue componentsJoinedByString:@", "]];
    else
        return [value appleScriptMakeProperties];
}

- (NSString *)appleScriptMakeProperties;
{
    NSMutableString *result;
    NSEnumerator *enumerator;
    NSScriptClassDescription *classDescription;
    NSString *key;
    NSDictionary *defaultValues;
    BOOL noComma = YES;
    id value;
    
    classDescription = (NSScriptClassDescription *)[self classDescription];
    if (classDescription == nil) // this isn't one of our data-bearing objects, it's a junk object like "scriptingProperties", which is an extra CFDictionary added to every object's list of keys on 10.2
        return nil;
    
    defaultValues = [self _defaultValuesDictionary];
    enumerator = [[classDescription attributeKeys] objectEnumerator];
    result = [NSMutableString string];
    while ((key = [enumerator nextObject])) {
        if ([classDescription isReadOnlyKey:key] || [self ignoreAppleScriptValueForKey:key])
            continue;
            
        value = [self valueForKey:key];
        if (!value || [[defaultValues objectForKey:key] isEqual:value])
            continue;
        value = [self stringValueForValue:value ofKey:key];            
        if (!value)
            continue;
        
        if (noComma)
            noComma = NO;
        else
            [result appendString:@", "];
        [result appendFormat:@"%@: %@", [self _attributeNameForKey:key], value];
    }
    return [NSString stringWithFormat:@"{%@}", result];
}

- (NSString *)appleScriptMakeCommandAt:(NSString *)aLocationSpecifier;
{
    NSScriptClassDescription *classDescription;
    NSDictionary *terminology;
    NSString *properties;
    
    properties = [self appleScriptMakeProperties];
    if (properties == nil)
        return @"";
    
    classDescription = (NSScriptClassDescription *)[self classDescription];
    terminology = [[self _appleScriptTerminologyForSuite:[classDescription suiteName]] objectForKey:[classDescription className]];
    if ([properties isEqualToString:@"{}"])
        return [NSString stringWithFormat:@"make new %@ at %@\r", [terminology objectForKey:@"Name"], aLocationSpecifier];
    else
        return [NSString stringWithFormat:@"make new %@ at %@ with properties %@\r", [terminology objectForKey:@"Name"], aLocationSpecifier, properties];
}

- (NSString *)appleScriptMakeCommandAt:(NSString *)aLocationSpecifier withIndent:(int)indent;
{
    if (!indent)
        return [self appleScriptMakeCommandAt:aLocationSpecifier];
    else
        return [NSString stringWithFormat:@"%@%@", [@"\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t" substringToIndex:indent], [self appleScriptMakeCommandAt:aLocationSpecifier]];
}


- (NSScriptObjectSpecifier *)objectSpecifierByProperty:(NSString *)propertyKey inRelation:(NSString *)myLocation toContainer:(NSObject *)myContainer
{
    NSScriptObjectSpecifier *specifier, *containerSpecifier;
    NSScriptClassDescription *myClassDescription, *containerClassDescription;
    id myUniqueID;

    myClassDescription = (id)[NSScriptClassDescription classDescriptionForClass:[self class]];
    containerClassDescription = (id)[NSScriptClassDescription classDescriptionForClass:[myContainer class]];
    containerSpecifier = [myContainer objectSpecifier];
    myUniqueID = [self valueForKey:propertyKey];
    specifier = nil;

#define NSFoundationVersionNumberWithWorkingIDSpecifier 462 // TODO: Check whether earlier versions are also OK; this is from 10.2.3

    // 10.2 Foundation has classes for dealing with special reference forms. They existed under 10.1, but were undocumented and had different behavior, so we will only use them under 10.2.
    if (NSFoundationVersionNumber >= NSFoundationVersionNumberWithWorkingIDSpecifier) {
        FourCharCode propertyKeyCode = [myClassDescription appleEventCodeForKey:propertyKey];

        if (propertyKeyCode == pID) {
            Class byIdSpecifier = NSClassFromString(@"NSUniqueIDSpecifier");
            if (byIdSpecifier != Nil && [byIdSpecifier instancesRespondToSelector:@selector(initWithContainerClassDescription:containerSpecifier:key:uniqueID:)]) {
                specifier = [[byIdSpecifier alloc] initWithContainerClassDescription:containerClassDescription containerSpecifier:containerSpecifier key:myLocation uniqueID:myUniqueID];
                [specifier autorelease];
            }
        } else if (propertyKeyCode == pName) {
            Class byNameSpecifier = NSClassFromString(@"NSNameSpecifier");
            if (byNameSpecifier != Nil && [byNameSpecifier instancesRespondToSelector:@selector(initWithContainerClassDescription:containerSpecifier:key:name:)]) {
                // We're on OS 10.2.x or greater, so we can use the special unique-ID reference form
                specifier = [[byNameSpecifier alloc] initWithContainerClassDescription:containerClassDescription containerSpecifier:containerSpecifier key:myLocation name:myUniqueID];
                [specifier autorelease];
            }
        }
        // Pre-10.2, we need to use a specifier of the form "the first object whose attr is foo" even if attr is the name or id attribute; we'll fall through to the general case for that.
    }

    if (specifier == nil)
    {
        NSScriptWhoseTest *whoseIdIsMe;
        NSScriptObjectSpecifier *idOf;
        NSWhoseSpecifier *whose;

        idOf = [[NSPropertySpecifier alloc] initWithContainerClassDescription:myClassDescription containerSpecifier:nil key:propertyKey];
        whoseIdIsMe = [[NSSpecifierTest alloc] initWithObjectSpecifier:idOf comparisonOperator:NSEqualToComparison testObject:myUniqueID];
        whose = [[NSWhoseSpecifier alloc] initWithContainerClassDescription:containerClassDescription containerSpecifier:containerSpecifier key:myLocation test:whoseIdIsMe];
        [whose setStartSubelementIdentifier:NSRandomSubelement];
        [idOf release];
        [whoseIdIsMe release];

        specifier = [whose autorelease];
    }

    // NSLog(@"uniqueIDSpecifier(id=[%@] prop=[%@] container=[%@]) --> %@", myUniqueID, myLocation, myContainer, specifier);

    return specifier;
}

@end
