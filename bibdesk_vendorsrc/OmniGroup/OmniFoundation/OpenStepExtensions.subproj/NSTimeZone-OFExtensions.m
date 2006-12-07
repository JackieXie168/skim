// Copyright 2000-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import <OmniFoundation/NSTimeZone-OFExtensions.h>

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSTimeZone-OFExtensions.m,v 1.6 2003/01/15 22:52:01 kc Exp $")

static NSMutableDictionary *timeZoneCache = nil;
static NSLock              *timeZoneCacheLock = nil;
static NSObject            *cachedNullKey = nil;
static id (*originalTimeZoneWithName)(id self, SEL _cmd, NSString *name) = NULL;


@implementation NSTimeZone (OFExtensions)

+ (void) performPosing;
{
    originalTimeZoneWithName = (void *)OBReplaceMethodImplementationWithSelector(*(Class *)self,  @selector(timeZoneWithName:), @selector(replacement_timeZoneWithName:));
}

+ (void) didLoad;
{
    timeZoneCache = [[NSMutableDictionary alloc] init];
    timeZoneCacheLock = [[NSLock alloc] init];
    cachedNullKey = [[NSObject alloc] init];
}

+ (id)replacement_timeZoneWithName:(NSString *)tzName;
{
    NSTimeZone *tz;
    
    [timeZoneCacheLock lock];
    
    tz = [timeZoneCache objectForKey: tzName];
    if (!tz) {
        tz = originalTimeZoneWithName(self, _cmd, tzName);
        if (tz)
            [timeZoneCache setObject: tz forKey: tzName];
        else
            [timeZoneCache setObject: cachedNullKey forKey: tzName];
    } else if ((id)tz == (id)cachedNullKey)
        tz = nil;

    [timeZoneCacheLock unlock];
    
    return tz;
}

@end
