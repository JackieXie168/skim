// Copyright 2003-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OACompositeColorProfile.h"
#import "OAColorProfile.h"
#import "NSColor-ColorSyncExtensions.h"
#import <AppKit/AppKit.h>
#import <OmniBase/rcsid.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniAppKit/ColorSync/OACompositeColorProfile.m 68913 2005-10-03 19:36:19Z kc $");

@interface OACompositeColorProfile (Private)
@end

@implementation OACompositeColorProfile

// Init and dealloc

- initWithProfiles:(NSArray *)someProfiles;
{
    [super init];
    profiles = [someProfiles retain];
    return self;
}

- (void)dealloc;
{
    [profiles release];
    [super dealloc];
}

- (NSString *)description;
{
    return [profiles description];
}

// API

- (BOOL)_hasRGBSpace;
{
    return [[profiles objectAtIndex:0] _hasRGBSpace];
}

- (BOOL)_hasCMYKSpace;
{
    return [[profiles objectAtIndex:0] _hasCMYKSpace];
}

- (BOOL)_hasGraySpace;
{
    return [[profiles objectAtIndex:0] _hasGraySpace];
}

- (CMWorldRef)_colorWorldForOutput:(OAColorProfile *)aProfile componentSelector:(SEL)componentSelector;
{
    CMWorldRef result;
    int index, count = [profiles count];
    CMConcatProfileSet *profileSet = alloca(sizeof(CMConcatProfileSet) + sizeof(CMProfileRef) * (count + 1));
    
    profileSet->keyIndex = 0;
    profileSet->count = count + 1;
    for (index = 0; index < count; index++) {
        profileSet->profileSet[index] = (CMProfileRef)[[profiles objectAtIndex:index] performSelector:componentSelector];
    }
    profileSet->profileSet[count] = (CMProfileRef)[aProfile performSelector:componentSelector];
    CWConcatColorWorld(&result, profileSet);
    return result;
}

- (void *)_rgbConversionWorldForOutput:(OAColorProfile *)aProfile;
{
    CMWorldRef *colorWorld = (CMWorldRef *)[self _cachedRGBColorWorldForOutput:aProfile];

    if (!*colorWorld)  
        *colorWorld = [self _colorWorldForOutput:aProfile componentSelector:@selector(_rgbProfile)];
    return *colorWorld;
}

- (void *)_cmykConversionWorldForOutput:(OAColorProfile *)aProfile;
{
    CMWorldRef *colorWorld = (CMWorldRef *)[self _cachedCMYKColorWorldForOutput:aProfile];

    if (!*colorWorld)  
        *colorWorld = [self _colorWorldForOutput:aProfile componentSelector:@selector(_cmykProfile)];
    return *colorWorld;
}

- (void *)_grayConversionWorldForOutput:(OAColorProfile *)aProfile;
{
    CMWorldRef *colorWorld = (CMWorldRef *)[self _cachedGrayColorWorldForOutput:aProfile];

    if (!*colorWorld)  
        *colorWorld = [self _colorWorldForOutput:aProfile componentSelector:@selector(_grayProfile)];
    return *colorWorld;
}

@end

@implementation OACompositeColorProfile (Private)
@end
