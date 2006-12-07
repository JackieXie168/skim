// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import <OmniFoundation/NSDictionary-OFExtensions.h>

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

#import <OmniFoundation/NSArray-OFExtensions.h>
#import <OmniFoundation/NSString-OFExtensions.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSDictionary-OFExtensions.m,v 1.17 2003/01/15 22:51:59 kc Exp $")

NSString *OmniDictionaryElementNameKey = @"__omniDictionaryElementNameKey";

@implementation NSDictionary (OFExtensions)

- (id)anyObject;
{
    return [[self allValues] anyObject];
}

/*" Returns an object which is a shallow copy of the receiver except that the given key now maps to anObj. "*/
- (NSDictionary *)dictionaryWithObject:anObj forKey:key
{
    unsigned int keyCount, keyIndex;
    NSArray *newKeys;
    NSMutableArray *newValues;
    BOOL didReplace;

    keyCount = [self count];
    
    if (keyCount == 0 ||
        (keyCount == 1 && [self objectForKey:key] != nil))
        return [NSDictionary dictionaryWithObject:anObj forKey:key];

    if ([self objectForKey:key] == anObj)
        return [NSDictionary dictionaryWithDictionary:self];

    newKeys = [self allKeys];
    newValues = [[NSMutableArray alloc] initWithCapacity:keyCount+1];
    didReplace = NO;
    for(keyIndex = 0; keyIndex < keyCount; keyIndex ++) {
        id aKey = [newKeys objectAtIndex:keyIndex];

        if ([aKey isEqual:key]) {
            [newValues addObject:anObj];
            didReplace = YES;
        } else
            [newValues addObject:[self objectForKey:aKey]];
    }

    if (!didReplace) {
        newKeys = [newKeys arrayByAddingObject:key];
        [newValues addObject:anObj];
    }

    return [NSDictionary dictionaryWithObjects:newValues forKeys:newKeys];
}

- (NSDictionary *)elementsAsInstancesOfClass:(Class)aClass withContext:(id)context;
{
    NSMutableDictionary *dict;
    NSAutoreleasePool *pool;
    NSEnumerator *elementEnum;
    NSString *elementName;

    // Keep this out of the pool since we're returning it
    dict = [NSMutableDictionary dictionary];

    pool = [[NSAutoreleasePool alloc] init];
    elementEnum = [self keyEnumerator];
    while ((elementName = [elementEnum nextObject])) {
	id instance;
	NSMutableDictionary *element;

	element = [[NSMutableDictionary alloc] initWithDictionary:[self objectForKey:elementName]];
	[element setObject:elementName forKey:OmniDictionaryElementNameKey];

	instance = [[aClass alloc] initWithDictionary:element context:context];
	[element release];

	[dict setObject:instance forKey:elementName];
    }
    [pool release];

    return dict;
}

- (NSString *)keyForObjectEqualTo:(id)anObject;
{
    NSEnumerator *keyEnumerator;
    NSString *aKey;

    keyEnumerator = [self keyEnumerator];
    while ((aKey = [keyEnumerator nextObject]))
        if ([[self objectForKey:aKey] isEqual:anObject])
	    return aKey;
    return nil;
}

- (float)floatForKey:(NSString *)key defaultValue:(float)defaultValue;
{
    id value;

    value = [self objectForKey:key];
    if (value)
        return [value floatValue];
    return defaultValue;
}

- (float)floatForKey:(NSString *)key;
{
    return [self floatForKey:key defaultValue:0.0];
}

- (double)doubleForKey:(NSString *)key defaultValue:(double)defaultValue;
{
    id value;

    value = [self objectForKey:key];
    if (value)
        return [value doubleValue];
    return defaultValue;
}

- (double)doubleForKey:(NSString *)key;
{
    return [self doubleForKey:key defaultValue:0.0];
}

- (BOOL)boolForKey:(NSString *)key defaultValue:(BOOL)defaultValue;
{
    id value;

    value = [self objectForKey:key];
    if (!value)
        return defaultValue;

    if (![value isKindOfClass:[NSString class]]) {
        if ([value isKindOfClass:[NSNumber class]])
            return [value boolValue];
        // Should maybe raise an error here?
        return NO;
    }

    return [value boolValue];
}

- (BOOL)boolForKey:(NSString *)key;
{
    return [self boolForKey:key defaultValue:NO];
}

- (int)intForKey:(NSString *)key defaultValue:(int)defaultValue;
{
    id value;

    value = [self objectForKey:key];
    if (!value)
        return defaultValue;
    return [value intValue];
}

- (int)intForKey:(NSString *)key;
{
    return [self intForKey:key defaultValue:0];
}

- (id)objectForKey:(NSString *)key defaultObject:(id)defaultObject;
{
    id value;

    value = [self objectForKey:key];
    if (value)
        return value;
    return defaultObject;
}

- (NSMutableDictionary *)deepMutableCopy;
{
    NSMutableDictionary *newDictionary;
    NSEnumerator *keyEnumerator;
    id anObject;
    id aKey;

    newDictionary = [self mutableCopy];
    // Run through the new dictionary and replace any objects that respond to -deepMutableCopy or -mutableCopy with copies.
    keyEnumerator = [newDictionary keyEnumerator];
    while ((aKey = [keyEnumerator nextObject])) {
        anObject = [newDictionary objectForKey:aKey];
        if ([anObject respondsToSelector:@selector(deepMutableCopy)]) {
            anObject = [anObject deepMutableCopy];
            [newDictionary setObject:anObject forKey:aKey];
            [anObject release];
        } else if ([anObject respondsToSelector:@selector(mutableCopy)]) {
            anObject = [anObject mutableCopy];
            [newDictionary setObject:anObject forKey:aKey];
            [anObject release];
        }
    }

    return newDictionary;
}

- (NSDictionary *)deepCopyWithReplacementFunction:(id (*)(id, void *))funct context:(void *)context;
{
    NSMutableArray *objects;
    NSArray *keys;
    int pairCount, pairIndex;
    BOOL changed;
    NSDictionary *result;
    
    keys = [self allKeys];
    pairCount = [keys count];
    OBASSERT(pairCount == [self count]);
    objects = [[NSMutableArray alloc] initWithCapacity:pairCount];

    changed = NO;
    for(pairIndex = 0; pairIndex < pairCount; pairIndex ++) {
        NSString *key = [keys objectAtIndex:pairIndex];
        id object = [self objectForKey:key];
        id newObject;
        
        // Note we don't perform substitution on keys. Maybe we should? What should we do about the key collisions that could result?
        
        newObject = [((*funct)(object, context)) retain];
        if (!newObject) {
            // The cast, below, is needed to make the compiler shut up, but it's incorrect --- object may be of any class that implements this method.
            if ([object respondsToSelector:_cmd])
                newObject = [[(NSDictionary *)object deepCopyWithReplacementFunction:funct context:context] retain];
            else
                newObject = [object copy];
        }
        if (newObject != object)
            changed = YES;
        [objects addObject:newObject];
        [newObject release];
    }
    
    OBPOSTCONDITION([objects count] == [keys count]);
    
    if (changed) {
        result = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
    } else {
        // TODO: optimize the case where we're immutable
        result = [NSDictionary dictionaryWithDictionary:self];
    }
    
    [objects release];
    
    OBPOSTCONDITION([result count] == [self count]);
    
    return result;
}

@end


@implementation NSDictionary (OFDeprecatedExtensions)

- (id)valueForKey:(NSString *)key defaultValue:(id)defaultValue;
{
    return [self objectForKey:key defaultObject:defaultValue];
}

@end
