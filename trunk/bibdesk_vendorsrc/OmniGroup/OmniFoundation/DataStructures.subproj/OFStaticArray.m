// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/OFStaticArray.h>

#import <objc/objc-class.h> // Import this before Foundation/Foundation.h to avoid compiler bug
#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/DataStructures.subproj/OFStaticArray.m 68913 2005-10-03 19:36:19Z kc $")


@interface OFStaticArray (Private)
- (void)deallocObjectsToCount:(unsigned int)newCount;
@end

@implementation OFStaticArray

static NSZone *OFStaticArrayZone;

+ (void)initialize;
{
    OBINITIALIZE;

    OFStaticArrayZone = NSCreateZone(0, NSPageSize(), YES);
}

#define DEFAULT_CAPACITY  10
#define DEFAULT_EXTENSION  1

- initWithClass:(Class)aClass capacity:(unsigned int)aCapacity extendBy:(unsigned int)extendBy debugEnabled: (BOOL) isDebugEnabled;
{
    if (![super init])
        return nil;

    objectClass = aClass;
    objectLength = aClass->instance_size;
    count = 0;
    extensionSize = extendBy;
    if (aCapacity < extensionSize)
        capacity = extensionSize;
    else
        capacity = aCapacity;
    debugEnabled = isDebugEnabled;
    mutableBytes = NSZoneMalloc(OFStaticArrayZone, capacity * objectLength);
    if (debugEnabled)
        fprintf(stderr, "OFStaticArray 0x%08x, objectLength = %d -- malloc %d bytes at 0x%08x\n", (unsigned int)self, objectLength, capacity * objectLength, (unsigned int)mutableBytes);
    return self;
}

- initWithClass:(Class)aClass capacity:(unsigned int)aCapacity extendBy:(unsigned int)extendBy;
{
    return [self initWithClass: aClass capacity: aCapacity extendBy: extendBy debugEnabled: NO];
}

- initWithClass:(Class)aClass capacity:(unsigned int)aCapacity;
{
    return [self initWithClass:aClass capacity:aCapacity extendBy:DEFAULT_EXTENSION];
}

- initWithClass:(Class)aClass;
{
    return [self initWithClass:aClass capacity:DEFAULT_CAPACITY extendBy:DEFAULT_EXTENSION];
}

- (void)dealloc
{
    [self deallocObjectsToCount:0];
    if (debugEnabled)
        fprintf(stderr, "OFStaticArray 0x%08x -- free 0x%08x\n", (unsigned int)self, (unsigned int)mutableBytes);
    NSZoneFree(OFStaticArrayZone, mutableBytes);
    [super dealloc];
}

- (unsigned int)capacity;
{
    return capacity;
}

- (void)setCapacity:(unsigned int)newCapacity;
{
    if (newCapacity < count)
        [self setCount:newCapacity];
    
    if (newCapacity > capacity) {
        if (!extensionSize)
            newCapacity = MAX(newCapacity, capacity * 2);
        else
            newCapacity = MAX(newCapacity, capacity + extensionSize);
        mutableBytes = NSZoneRealloc(OFStaticArrayZone, mutableBytes, newCapacity * objectLength);
        if (debugEnabled)
            fprintf(stderr, "OFStaticArray 0x%08x -- realloc to %d bytes at 0x%08x\n", (unsigned int)self, newCapacity * objectLength, (unsigned int)mutableBytes);
        memset(mutableBytes + capacity * objectLength, 0, (newCapacity - capacity) * objectLength);
        capacity = newCapacity;
    } 
}

- (unsigned int)extensionSize;
{
    return extensionSize;
}

- (void)setExtensionSize:(unsigned int)anAmount;
{
    extensionSize = anAmount;
}

- (unsigned int)count;
{
    return count;
}

- (void)setCount:(unsigned int)number;
{
    void *ptr;

    if (number < count) {
        [self deallocObjectsToCount:number];
    } else {
        if (number > capacity)
            [self setCapacity:number];
        ptr = mutableBytes + count * objectLength;
        while (count < number) {
            *(Class *)ptr = objectClass;
            ptr += objectLength;
            count++;
        }
    }
}

- (void)removeAllObjects;
{
    [self setCount:0];
}

- (void)removeObjectAtIndex:(unsigned int)index;
{
    void *targetObjectPointer;
    
    if (index >= count)
        [NSException raise:NSRangeException format:@"index (%d) is beyond count (%d)", index, count];

    targetObjectPointer = mutableBytes + objectLength * index;
    [(id)targetObjectPointer dealloc];
    
    if (index < count-1) {
        // Fill in the hole with the later objects in the array
        bcopy(targetObjectPointer + objectLength, targetObjectPointer, (count - index - 1) * objectLength);
    }
    
    count--;
}


- (id)newObject;
{
    void *ptr;

    if (count == capacity)
        [self setCapacity:capacity+1];

    ptr = mutableBytes + count++ * objectLength;
    *(Class *)ptr = objectClass;
    return (id)ptr;
}

- (id)objectAtIndex:(unsigned int)anIndex;
{
    if (anIndex >= count)
        [NSException raise:NSRangeException format:@"index (%d) is beyond count (%d)", anIndex, count];
    return (id)(mutableBytes + objectLength * anIndex);
}

- (id)lastObject;
{
    if (count == 0)
        [NSException raise:NSRangeException format:@"can't call lastObject on empty array"];
    return [self objectAtIndex:count-1];
}

- (void) setDebugEnabled: (BOOL) isDebugEnabled;
{
    debugEnabled = isDebugEnabled;
}

// Debugging

- (NSMutableDictionary *)debugDictionary;
{
    NSMutableDictionary *debugDictionary;
    NSMutableArray *objects;
    unsigned int index;

    objects = [[NSMutableArray alloc] initWithCapacity:count];
    for (index = 0; index < count; index++)
        [objects addObject:[self objectAtIndex:index]];

    debugDictionary = [super debugDictionary];
    [debugDictionary setObject:[NSString stringWithFormat:@"%d", count] forKey:@"count"];
    [debugDictionary setObject:[NSString stringWithFormat:@"%d", capacity] forKey:@"capacity"];
    [debugDictionary setObject:[NSString stringWithFormat:@"%d", extensionSize] forKey:@"extensionSize"];
    [debugDictionary setObject:objects forKey:@"objects"];
    return debugDictionary;
}

@end

@implementation OFStaticArray (Private)

- (void)deallocObjectsToCount:(unsigned int)newCount;
{
    int countDifference;
    void *ptr;

    countDifference = count - newCount;
    if (countDifference <= 0)
        return;
    
    ptr = mutableBytes + (count - 1) * objectLength;
    while (countDifference--) {
        [(id)ptr dealloc];
        ptr -= objectLength;
    }
    memset(mutableBytes + newCount * objectLength, 0, (count - newCount) * objectLength);
    // [data resetBytesInRange:NSMakeRange(newCount * objectLength, (count - newCount) * objectLength)];

    count = newCount;
}

@end
