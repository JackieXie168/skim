// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/NSMutableDictionary-OFExtensions.h>

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSMutableDictionary-OFExtensions.m,v 1.14 2004/02/10 04:07:45 kc Exp $")

@implementation NSMutableDictionary (OFExtensions)

- (void)setObject:(id)anObject forKeys:(NSArray *)keys;
{
    unsigned int keyCount;

    keyCount = [keys count];
    while (keyCount--)
	[self setObject:anObject forKey:[keys objectAtIndex:keyCount]];
}


- (void)setFloatValue:(float)value forKey:(id)key;
{
    NSNumber *number;

    number = [[NSNumber alloc] initWithFloat:value];
    // Rhapsody BUG: We have to insert the NSNumber's description here (rather than the NSNumber itself) because negative NSNumbers do NOT write out with quotes around them, so if you read in the plist later you'll get a crash (Rhapsody doesn't like unquoted '-' in plists).  Bug report filed.
    [self setObject:[number description] forKey:key];
    [number release];
}

- (void)setDoubleValue:(double)value forKey:(id)key;
{
    NSNumber *number;

    number = [[NSNumber alloc] initWithDouble:value];
    // Rhapsody BUG: We have to insert the NSNumber's description here (rather than the NSNumber itself) because negative NSNumbers do NOT write out with quotes around them, so if you read in the plist later you'll get a crash (Rhapsody doesn't like unquoted '-' in plists).  Bug report filed.
    [self setObject:[number description] forKey:key];
    [number release];
}

- (void)setIntValue:(int)value forKey:(id)key;
{
    NSNumber *number;

    number = [[NSNumber alloc] initWithInt:value];
    // Rhapsody BUG: We have to insert the NSNumber's description here (rather than the NSNumber itself) because negative NSNumbers do NOT write out with quotes around them, so if you read in the plist later you'll get a crash (Rhapsody doesn't like unquoted '-' in plists).  Bug report filed.
    [self setObject:[number description] forKey:key];
    [number release];
}

- (void)setBoolValue:(BOOL)value forKey:(id)key;
{
    NSString *string;

    string = value ? @"YES" : @"NO"; // We use "YES" and "NO" rather than "y" and "n" because some -boolForKey: implementations only look for YES and NO.
    [self setObject:string forKey:key];
}


// Set values with defaults

- (void)setObject:(id)object forKey:(id)key defaultObject:(id)defaultObject;
{
    if (!object || [object isEqual:defaultObject]) {
        [self removeObjectForKey:key];
        return;
    }

    [self setObject:object forKey:key];
}

- (void)setFloatValue:(float)value forKey:(id)key defaultValue:(float)defaultValue;
{
    if (value == defaultValue) {
        [self removeObjectForKey:key];
        return;
    }

    [self setFloatValue:value forKey:key];
}

- (void)setDoubleValue:(double)value forKey:(id)key defaultValue:(double)defaultValue;
{
    if (value == defaultValue) {
        [self removeObjectForKey:key];
        return;
    }

    [self setDoubleValue:value forKey:key];
}

- (void)setIntValue:(int)value forKey:(id)key defaultValue:(int)defaultValue;
{
    if (value == defaultValue) {
        [self removeObjectForKey:key];
        return;
    }

    [self setIntValue:value forKey:key];
}

- (void)setBoolValue:(BOOL)value forKey:(id)key defaultValue:(BOOL)defaultValue;
{
    if (value == defaultValue) {
        [self removeObjectForKey:key];
        return;
    }

    [self setBoolValue:value forKey:key];
}

@end
