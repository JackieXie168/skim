// Copyright 1998-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/OFZone.h>

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>
#import <OmniBase/system.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/OFZone.m 68913 2005-10-03 19:36:19Z kc $")


@interface OFZone (Private)
+ zoneForNSZone:(NSZone *)aZone ownsZone:(BOOL)shouldOwnZone;
- _initWithNSZone:(NSZone *)aZone ownsZone:(BOOL)shouldOwnZone;
    // Designated initializer. Assumes zoneMapLock is held.
- (void)recycle;
@end

@implementation OFZone

static NSMapTable *zoneMap = NULL;
static pthread_mutex_t zoneMapLock;

static unsigned int OFZoneSize = 0;
static unsigned int OFZoneGranularity = 0;

// #define DEBUG_ZONES
// #define NO_ZONES

#ifdef NO_ZONES
#define NSCreateZone(a,b,c) NSDefaultMallocZone()
#endif

+ (void)initialize
{
    OBINITIALIZE;

    zoneMap = NSCreateMapTable(NSNonOwnedPointerMapKeyCallBacks, NSNonOwnedPointerMapValueCallBacks, 10);
    pthread_mutex_init(&zoneMapLock, NULL);
    OFZoneSize = NSPageSize() * 4;
    OFZoneGranularity = NSPageSize() * 2;
}

+ (OFZone *)zoneForNSZone:(NSZone *)aZone;
{
    return [self zoneForNSZone:aZone ownsZone:NO];
}

+ (OFZone *)zoneForObject:(id <NSObject>)anObject;
/*" Returns an OFZone representing the zone in which anObject is allocated. "*/
{
    return [self zoneForNSZone:[anObject zone] ownsZone:NO];
}    

+ (OFZone *)defaultZone;
/*" Returns an OFZone representing the default allocation zone. "*/
{
    return [self zoneForNSZone:NSDefaultMallocZone() ownsZone:NO];
}

+ (OFZone *)newZone;
/*" Returns a newly created OFZone representing a newly created allocation zone. When the OFZone is deallocated, the allocation zone will be recycled. "*/
{
    return [self zoneForNSZone:NSCreateZone(OFZoneSize, OFZoneGranularity, YES) ownsZone:YES];
}

// Init and dealloc

- init;
{
    // See -_initWithNSZone:ownsZone:.
    [NSException raise:NSInvalidArgumentException format:@"%@ does not respond to the %s selector", NSStringFromClass(isa), _cmd];
    return nil; // Not reached
}

- (void)dealloc;
{
    [self recycle];
    [super dealloc];
}

- (void)release;
{
    // This is needed to avoid occasional disaster.  One thread might call -release, and be about to call -dealloc when another thread hops in and grabs this zone out of the map table, retaining and returning it.  The original thread then blithely continues with -dealloc, and when the second thread continues it has a pointer to a deallocated object.
    // In fact, we've crashed in exactly this way in -[OWSGMLProcessor initWithPipeline:]:  when we went to allocate openTags out of the zone's nsZone, we got:
    // *** Selector 'nsZone' sent to dealloced instance 0x17034d0 of class OFZone.

    pthread_mutex_lock(&zoneMapLock);
    [super release];
    pthread_mutex_unlock(&zoneMapLock);
}

- (NSZone *)nsZone
{
    return zone;
}

- (void)setName:(NSString *)newName
{
    NSSetZoneName(zone, newName);
}

- (NSString *)name
{
    return NSZoneName(zone);
}

@end

@implementation OFZone (Private)

+ zoneForNSZone:(NSZone *)aZone ownsZone:(BOOL)shouldOwnZone;
/*" Returns an OFZone representing aZone, creating one if necessary.
If aZone was not initially created by OFZone, it will not be recycled when the OFZone is deallocated. "*/
{
    OFZone *returnZone;

    if (!aZone)
        return nil;

    pthread_mutex_lock(&zoneMapLock);

    returnZone = NSMapGet(zoneMap, aZone);
    if (returnZone)
        [returnZone retain];
    else
        returnZone = [[self allocWithZone:aZone] _initWithNSZone:aZone ownsZone:shouldOwnZone];

    pthread_mutex_unlock(&zoneMapLock);

    return [returnZone autorelease];
}

/* Designated initializer. Assumes zoneMapLock is held. */
- _initWithNSZone:(NSZone *)aZone ownsZone:(BOOL)shouldOwnZone;
{
    if ([super init] == nil)
        return nil;

    zone = aZone;
    ownsZone = shouldOwnZone;
//    NSLog(@"Before: %@ thread=%@", NSAllMapTableValues(zoneMap), [NSThread currentThread]);
    NSMapInsertKnownAbsent(zoneMap, aZone, self);
//    NSLog(@"After: %@ thread=%@", NSAllMapTableValues(zoneMap), [NSThread currentThread]);
#ifdef DEBUG_ZONES
    NSLog(@"OFZone 0x%x created, thread=%@", (unsigned)zone, [NSThread currentThread]);
#endif

    return self;
}

- (void)recycle;
{
    // PRECONDITION: We are only called by -dealloc, which is only called by -release, so we already have the zone map locked.
    OBPRECONDITION(zone != NULL);

#ifdef DEBUG_ZONES
    NSLog(@"OFZone 0x%x (%@) recycled", (unsigned)zone, [self name]);
#endif

    NSMapRemove(zoneMap, zone);
    if (ownsZone) {
#ifndef NO_ZONES
        NSRecycleZone(zone);
#endif
    }
    zone = NULL;
}

@end

