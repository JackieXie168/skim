// Copyright 2002-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import "OAColorProfile.h"
#import "NSColor-ColorSyncExtensions.h"
#import <Cocoa/Cocoa.h>
#import <OmniBase/rcsid.h>
#import <OmniBase/OBUtilities.h>
#import <OmniFoundation/OmniFoundation.h>
#import <OmniBase/assertions.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/ColorSync/OAColorProfile.m,v 1.5 2003/04/02 16:06:18 toon Exp $");

@interface OAColorProfile (Private)
+ (void)_deviceNotification:(NSNotification *)notification;
- initDefaultDocumentProfile;
- initDefaultProofProfile;
- initDefaultDisplayProfile;

- (NSString *)_getProfileName:(void *)aProfile;
- (void *)_anyProfile;
- (void)_updateConversionCacheForOutput:(OAColorProfile *)outputProfile;
@end

NSString *DefaultDocumentColorProfileDidChangeNotification = @"DefaultDocumentColorProfileDidChangeNotification";
NSString *ColorProofingDevicesDidChangeNotification = @"ColorProofingDevicesDidChangeNotification";

@implementation OAColorProfile

static BOOL resetProfileLists = YES;
static NSMutableDictionary *rgbProfileDictionary = nil;
static NSMutableDictionary *cmykProfileDictionary = nil;
static NSMutableDictionary *grayProfileDictionary = nil;
static BOOL resetDeviceList = YES;
static NSMutableDictionary *deviceProfileDictionary = nil;
static NSMutableDictionary *deviceNameDictionary = nil;
static OAColorProfile *currentColorProfile = nil;
static NSView *focusedViewForCurrentColorProfile = nil;

static OAColorProfile *lastInProfile = nil;
static OAColorProfile *lastOutProfile = nil;
static CMWorldRef rgbColorWorld = NULL;
static CMWorldRef cmykColorWorld = NULL;
static CMWorldRef grayColorWorld = NULL;

+ (void)initialize;
{
// The notification isn't available on 10.1
#ifdef kCMDeviceRegisteredNotification
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(_deviceNotification:) name:(NSString *)kCMDeviceRegisteredNotification object:nil];
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(_deviceNotification:) name:(NSString *)kCMDeviceUnregisteredNotification object:nil];
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(_deviceNotification:) name:(NSString *)kCMDefaultDeviceProfileNotification object:nil];
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(_deviceNotification:) name:(NSString *)kCMDeviceProfilesNotification object:nil];
#endif
}
        
+ (OAColorProfile *)defaultDocumentProfile;
{
    static OAColorProfile *colorProfile = nil;

    if (!colorProfile)
        colorProfile = [[self alloc] initDefaultDocumentProfile];
    return colorProfile;
}

+ (OAColorProfile *)defaultProofProfile;
{
    static OAColorProfile *colorProfile = nil;

    if (!colorProfile)
        colorProfile = [[self alloc] initDefaultProofProfile];
    return colorProfile;
}

+ (OAColorProfile *)defaultDisplayProfile;
{
    static OAColorProfile *colorProfile = nil;

    if (!colorProfile)
        colorProfile = [[self alloc] initDefaultDisplayProfile];
    return colorProfile;
}

+ (OAColorProfile *)workingCMYKProfile;
{
    OAColorProfile *result = [[self alloc] init];
    
    result->cmykProfile = [[self defaultDocumentProfile] _cmykProfile];
    CMCloneProfileRef((CMProfileRef)result->cmykProfile);
    return [result autorelease];
}

+ (OAColorProfile *)currentProfile;
{
    if (currentColorProfile != nil) {
        if ([NSView focusView] == focusedViewForCurrentColorProfile)
            return currentColorProfile;
        else
            currentColorProfile = nil;
    }
    return nil;
}

OSErr deviceListIterator(const CMDeviceInfo *deviceInfo, const NCMDeviceProfileInfo *profileInfo, void *refCon)
{
    CMProfileRef cmProfile;
    CMAppleProfileHeader header;
    OAColorProfile *profile;
    NSString *deviceName, *profileName;
    
    if (resetDeviceList) {
        [deviceProfileDictionary release];
        [deviceNameDictionary release];
        deviceProfileDictionary = [[NSMutableDictionary alloc] init];
        deviceNameDictionary = [[NSMutableDictionary alloc] init];
        resetDeviceList = NO;
    }
    
    if (deviceInfo->deviceClass != cmPrinterDeviceClass && deviceInfo->deviceClass != cmProofDeviceClass)
        return 0;
    
    profile = [[OAColorProfile alloc] init];
    CMOpenProfile(&cmProfile, &profileInfo->profileLoc);
    CMGetProfileHeader(cmProfile, &header);
    switch(header.cm2.dataColorSpace) {
        case cmRGBData:
            profile->rgbProfile = cmProfile;
            break;
        case cmCMYKData:
            profile->cmykProfile = cmProfile;
            break;
        case cmGrayData:
            profile->grayProfile = cmProfile;
            break;
        default:
            CMCloseProfile(cmProfile);
            [profile release];
            return 0;
    }
    
    if (deviceInfo->deviceName) {
        NSDictionary *nameDictionary = (NSDictionary *)*(deviceInfo->deviceName);
        NSArray *languages = [NSBundle preferredLocalizationsFromArray:[nameDictionary allKeys]];
        
        if ([languages count])
            deviceName = [nameDictionary objectForKey:[languages objectAtIndex:0]];
        else if ([nameDictionary count])
            deviceName = [[nameDictionary allValues] lastObject]; // any random language, if none match
        else
            deviceName = nil;
    } else
        deviceName = nil;
    
    profileName = [profile _getProfileName:cmProfile];
    if (deviceName != nil) {
        deviceName = [[deviceName componentsSeparatedByString:@"_"] componentsJoinedByString:@" "];
        if (![deviceName isEqualToString:profileName])
            profileName = [NSString stringWithFormat:@"%@: %@", deviceName, profileName];
    }    
    [deviceProfileDictionary setObject:profile forKey:profileName];
    if (deviceName)
        [deviceNameDictionary setObject:profile forKey:deviceName];
    [profile release];
    return 0;
}

+ (NSArray *)proofingDeviceProfileNames;
{
    static unsigned long seed = 0;
    
    resetDeviceList = YES;
    CMIterateDeviceProfiles(deviceListIterator, &seed, NULL, cmIterateCurrentDeviceProfiles, NULL);
    return [deviceProfileDictionary allKeys];
}

+ (OAColorProfile *)proofProfileForDeviceProfileName:(NSString *)deviceProfileName;
{
    return [[[deviceProfileDictionary objectForKey:deviceProfileName] copy] autorelease];
}

+ (OAColorProfile *)proofProfileForPrintInfo:(NSPrintInfo *)printInfo;
{
    NSPrinter *printer = [printInfo printer];
    OAColorProfile *result;
    
    if (!printer)
        return [self defaultProofProfile];

    result = [[[deviceNameDictionary objectForKey:[printer name]] copy] autorelease];
    if (!result)
        result = [self defaultProofProfile];
    return result;
}

OSErr nameListIterator(CMProfileIterateData *iterateData, void *refCon)
{
    NSString *name;
    OAColorProfile *profile;
    
    if (resetProfileLists) {
        [rgbProfileDictionary release];
        [cmykProfileDictionary release];
        [grayProfileDictionary release];
        rgbProfileDictionary = [[NSMutableDictionary alloc] init];
        cmykProfileDictionary = [[NSMutableDictionary alloc] init];
        grayProfileDictionary = [[NSMutableDictionary alloc] init];
        resetProfileLists = NO;
    }
       
    name = [NSString stringWithCharacters:iterateData->uniCodeName length:iterateData->uniCodeNameCount - 1]; // -1 because iterateData includes null on end
    profile = [[OAColorProfile alloc] init];

    switch(iterateData->header.dataColorSpace) {
        case cmRGBData:
            CMOpenProfile((CMProfileRef *)&profile->rgbProfile, &iterateData->location);
            [rgbProfileDictionary setObject:profile forKey:name];
            break;
        case cmCMYKData:
            CMOpenProfile((CMProfileRef *)&profile->cmykProfile, &iterateData->location);
            [cmykProfileDictionary setObject:profile forKey:name];
            break;
        case cmGrayData:
            CMOpenProfile((CMProfileRef *)&profile->grayProfile, &iterateData->location);
            [grayProfileDictionary setObject:profile forKey:name];
            break;
        default:
            break;
    }
    [profile release];
    return 0;
}

+ (void)_iterateAvailableProfiles;
{
    static unsigned long seed = 0;
    
    resetProfileLists = YES;
    CMIterateColorSyncFolder (nameListIterator, &seed, NULL, NULL);
}

+ (NSArray *)rgbProfileNames;
{
    [self _iterateAvailableProfiles];
    return [rgbProfileDictionary allKeys];
}

+ (NSArray *)cmykProfileNames;
{
    [self _iterateAvailableProfiles];
    return [cmykProfileDictionary allKeys];
}

+ (NSArray *)grayProfileNames;
{
    [self _iterateAvailableProfiles];
    return [grayProfileDictionary allKeys];
}

+ (OAColorProfile *)colorProfileWithRGBNamed:(NSString *)rgbName cmykNamed:(NSString *)cmykName grayNamed:(NSString *)grayName;
{
    OAColorProfile *profile = [[OAColorProfile alloc] init];

    if (rgbName) {
        profile->rgbProfile = ((OAColorProfile *)[rgbProfileDictionary objectForKey:rgbName])->rgbProfile;
        CMCloneProfileRef((CMProfileRef)profile->rgbProfile);
    }
    if (cmykName) {
        profile->cmykProfile = ((OAColorProfile *)[cmykProfileDictionary objectForKey:cmykName])->cmykProfile;
        CMCloneProfileRef((CMProfileRef)profile->cmykProfile);
    }
    if (grayName) {
        profile->grayProfile = ((OAColorProfile *)[grayProfileDictionary objectForKey:grayName])->grayProfile;
        CMCloneProfileRef((CMProfileRef)profile->grayProfile);
    }
    return [profile autorelease];
}

+ (OAColorProfile *)colorProfileFromPropertyListRepresentation:(NSDictionary *)dict;
{
    OAColorProfile *colorProfile;
    NSData *data;
    CMProfileLocation profileLocation;
    
    colorProfile = [[[self alloc] init] autorelease];
    
    data = [dict objectForKey:@"rgb"];
    profileLocation.locType = cmBufferBasedProfile;
    profileLocation.u.bufferLoc.buffer = (void *)[data bytes];
    profileLocation.u.bufferLoc.size = [data length];
    CMOpenProfile((CMProfileRef *)&colorProfile->rgbProfile, &profileLocation);
    
    data = [dict objectForKey:@"cmyk"];
    profileLocation.locType = cmBufferBasedProfile;
    profileLocation.u.bufferLoc.buffer = (void *)[data bytes];
    profileLocation.u.bufferLoc.size = [data length];
    CMOpenProfile((CMProfileRef *)&colorProfile->cmykProfile, &profileLocation);

    data = [dict objectForKey:@"gray"];
    profileLocation.locType = cmBufferBasedProfile;
    profileLocation.u.bufferLoc.buffer = (void *)[data bytes];
    profileLocation.u.bufferLoc.size = [data length];
    CMOpenProfile((CMProfileRef *)&colorProfile->grayProfile, &profileLocation);
    
    return colorProfile;
}

- (void)dealloc;
{
    if (currentColorProfile == self)
        currentColorProfile = nil;
    if (lastInProfile == self)
        lastInProfile = nil;
    if (lastOutProfile == self)
        lastOutProfile = nil;
    
    if (rgbProfile) 
        CMCloseProfile(rgbProfile);
    if (cmykProfile)
        CMCloseProfile(cmykProfile);
    if (grayProfile)
        CMCloseProfile(grayProfile);
    [super dealloc];
}

- (id)copyWithZone:(NSZone *)zone;
{
    if (isMutable) {
        OAColorProfile *result = [[OAColorProfile alloc] init];
        
        if (rgbProfile) {
            result->rgbProfile = rgbProfile;
            CMCloneProfileRef((CMProfileRef)rgbProfile);
        }
        if (cmykProfile) {
            result->cmykProfile = cmykProfile;
            CMCloneProfileRef((CMProfileRef)cmykProfile);
        }
        if (grayProfile) {
            result->grayProfile = grayProfile;
            CMCloneProfileRef((CMProfileRef)grayProfile);
        }
        return result;
    } else
        return [self retain];
}

- (NSMutableDictionary *)propertyListRepresentation;
{
    NSMutableDictionary *result;
    CMProfileRef targetRef;
    CMAppleProfileHeader header;
    CMProfileLocation profileLocation;
    NSMutableData *data;
    
    result = [NSMutableDictionary dictionary];

    CMGetProfileHeader(rgbProfile, &header);
    data = [[NSMutableData alloc] initWithLength:header.cm1.size];
    profileLocation.locType = cmBufferBasedProfile;
    profileLocation.u.bufferLoc.buffer = [data mutableBytes];
    profileLocation.u.bufferLoc.size = header.cm1.size;
    CMCopyProfile(&targetRef, &profileLocation, rgbProfile);
    CMCloseProfile(targetRef);
    [result setObject:data forKey:@"rgb"];
    [data release];
    
    CMGetProfileHeader(cmykProfile, &header);
    data = [[NSMutableData alloc] initWithLength:header.cm1.size];
    profileLocation.locType = cmBufferBasedProfile;
    profileLocation.u.bufferLoc.buffer = [data mutableBytes];
    profileLocation.u.bufferLoc.size = header.cm1.size;
    CMCopyProfile(&targetRef, &profileLocation, cmykProfile);
    CMCloseProfile(targetRef);
    [result setObject:data forKey:@"cmyk"];
    [data release];
     
    CMGetProfileHeader(grayProfile, &header);
    data = [[NSMutableData alloc] initWithLength:header.cm1.size];
    profileLocation.locType = cmBufferBasedProfile;
    profileLocation.u.bufferLoc.buffer = [data mutableBytes];
    profileLocation.u.bufferLoc.size = header.cm1.size;
    CMCopyProfile(&targetRef, &profileLocation, grayProfile);
    CMCloseProfile(targetRef);
    [result setObject:data forKey:@"gray"];
    [data release];
    
    return result;
}

- (void)set;
{
    currentColorProfile = self;
    focusedViewForCurrentColorProfile = [NSView focusView];
}

- (void)unset;
{
    currentColorProfile = nil;
}

- (BOOL)isEqualToProfile:(OAColorProfile *)otherProfile;
{
    // UNDONE: should probably be using profile identifiers here instead of names
    if (rgbProfile != [otherProfile _rgbProfile] && ![[self rgbName] isEqualToString:[otherProfile rgbName]])
        return NO;
    if (cmykProfile != [otherProfile _cmykProfile] &&  ![[self cmykName] isEqualToString:[otherProfile cmykName]])
        return NO;
    return grayProfile == [otherProfile _grayProfile] || [[self grayName] isEqualToString:[otherProfile grayName]];
}

- (NSString *)rgbName;
{
    return rgbProfile ? [self _getProfileName:rgbProfile] : @"-";
}

- (NSString *)cmykName;
{
    return cmykProfile ? [self _getProfileName:cmykProfile] : @"-";
}

- (NSString *)grayName;
{
    return grayProfile ? [self _getProfileName:grayProfile] : @"-";
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"%@/%@/%@", [self rgbName], [self cmykName], [self grayName]];
}

// For use by NSColor only

- (BOOL)_hasRGBSpace;
{
    return rgbProfile != NULL;
}

- (BOOL)_hasCMYKSpace;
{
    return cmykProfile != NULL;
}

- (BOOL)_hasGraySpace;
{
    return grayProfile != NULL;
}

#warning Assumes display profile is always RGB


- (void)_setRGBColor:(NSColor *)aColor;
{
    static CGColorSpaceRef deviceRGBColorSpace = NULL;
    CGContextRef contextRef = [[NSGraphicsContext currentContext] graphicsPort];
    OAColorProfile *destination = [NSGraphicsContext currentContextDrawingToScreen] ? [OAColorProfile defaultDisplayProfile] : [OAColorProfile defaultDocumentProfile];
    NSColor *newColor = [aColor convertFromProfile:self toProfile:destination];
    
    if (!deviceRGBColorSpace) {
        deviceRGBColorSpace = CGColorSpaceCreateDeviceRGB();
        CGColorSpaceRetain(deviceRGBColorSpace);
    }
    CGContextSetFillColorSpace(contextRef, deviceRGBColorSpace);
    CGContextSetStrokeColorSpace(contextRef, deviceRGBColorSpace);
    [newColor setCoreGraphicsRGBValues];
}

- (void)_setCMYKColor:(NSColor *)aColor;
{
    static CGColorSpaceRef deviceCMYKColorSpace = NULL;
    CGContextRef contextRef;
    NSColor *newColor;

    if ([NSGraphicsContext currentContextDrawingToScreen]) {
        [self _setRGBColor:aColor];
        return;
    }
 
    if (!deviceCMYKColorSpace) {
        deviceCMYKColorSpace = CGColorSpaceCreateDeviceCMYK();
        CGColorSpaceRetain(deviceCMYKColorSpace);
    }
    contextRef = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextSetFillColorSpace(contextRef, deviceCMYKColorSpace);
    CGContextSetStrokeColorSpace(contextRef, deviceCMYKColorSpace);
    newColor = [aColor convertFromProfile:self toProfile:[OAColorProfile defaultDocumentProfile]];
    [newColor setCoreGraphicsCMYKValues];
}

- (void)_setGrayColor:(NSColor *)aColor;
{
    static CGColorSpaceRef deviceGrayColorSpace = NULL;
    CGContextRef contextRef;
    NSColor *newColor;

    if ([NSGraphicsContext currentContextDrawingToScreen]) {
        [self _setRGBColor:aColor];
        return;
    }
    
    if (!deviceGrayColorSpace) {
        deviceGrayColorSpace = CGColorSpaceCreateDeviceGray();
        CGColorSpaceRetain(deviceGrayColorSpace);
    }
    contextRef = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextSetFillColorSpace(contextRef, deviceGrayColorSpace);
    CGContextSetStrokeColorSpace(contextRef, deviceGrayColorSpace);
    newColor = [aColor convertFromProfile:self toProfile:[OAColorProfile defaultDocumentProfile]];
    [newColor setCoreGraphicsGrayValues];
}

- (void **)_cachedRGBColorWorldForOutput:(OAColorProfile *)aProfile;
{
    [self _updateConversionCacheForOutput:aProfile];
    return (void **)&rgbColorWorld;
}

- (void **)_cachedCMYKColorWorldForOutput:(OAColorProfile *)aProfile;
{
    [self _updateConversionCacheForOutput:aProfile];
    return (void **)&cmykColorWorld;
}

- (void **)_cachedGrayColorWorldForOutput:(OAColorProfile *)aProfile;
{
    [self _updateConversionCacheForOutput:aProfile];
    return (void **)&grayColorWorld;
}

- (void *)_rgbProfile;
{
    return rgbProfile ? rgbProfile : [self _anyProfile];
}

- (void *)_cmykProfile;
{
    return cmykProfile ? cmykProfile : [self _anyProfile];
}

- (void *)_grayProfile;
{
    return grayProfile ? grayProfile : [self _anyProfile];
}

- (void *)_rgbConversionWorldForOutput:(OAColorProfile *)aProfile;
{
    [self _updateConversionCacheForOutput:aProfile];
    
    if (!rgbColorWorld) {
        if (rgbProfile == aProfile->rgbProfile || !rgbProfile)
            return NULL;
        NCWNewColorWorld(&rgbColorWorld, rgbProfile, [aProfile _rgbProfile]);
    }
    return rgbColorWorld;
}

- (void *)_cmykConversionWorldForOutput:(OAColorProfile *)aProfile;
{
    [self _updateConversionCacheForOutput:aProfile];
    
    if (!cmykColorWorld) {
        if (cmykProfile == aProfile->cmykProfile || !cmykProfile)
            return NULL;
        NCWNewColorWorld(&cmykColorWorld, cmykProfile, [aProfile _cmykProfile]);
    }
    return cmykColorWorld;
}

- (void *)_grayConversionWorldForOutput:(OAColorProfile *)aProfile;
{
    [self _updateConversionCacheForOutput:aProfile];
    
    if (!grayColorWorld) {
        if (grayProfile == aProfile->grayProfile || !grayProfile)
            return NULL;
        NCWNewColorWorld(&grayColorWorld, grayProfile, [aProfile _grayProfile]);
    }
    return grayColorWorld;
}

@end

@implementation OAColorProfile (Private)

+ (void)_forwardDeviceNotification;
{
    [[NSNotificationCenter defaultCenter] postNotificationName:ColorProofingDevicesDidChangeNotification object:nil]; 
}

+ (void)_deviceNotification:(NSNotification *)notification;
{
    [self queueSelectorOnce:@selector(_forwardDeviceNotification)];
}

- (NSString *)_getProfileName:(void *)aProfile;
{
    CFStringRef string = nil;
    CMError error;
    
    error = CMCopyProfileLocalizedString((CMProfileRef)aProfile, cmProfileDescriptionTag, 0, 0, &string);
    if (error != noErr) {
        error = CMCopyProfileLocalizedString((CMProfileRef)aProfile, cmProfileDescriptionMLTag, 0,0, &string);
        if (error != noErr) {
            Str255 pName;
            ScriptCode code;
            
            CMGetScriptProfileDescription((CMProfileRef)aProfile, pName, &code);
            string = CFStringCreateWithPascalString(0, pName, code);
        }
    }
    return (NSString *)string;
}

- (void)colorProfileDidChange:(NSNotification *)notification;
{
    lastInProfile = nil;
    lastOutProfile = nil;

    CMCloseProfile(rgbProfile);
    CMCloseProfile(cmykProfile);
    CMCloseProfile(grayProfile);
    CMGetDefaultProfileBySpace(cmRGBData, (CMProfileRef *)&rgbProfile);
    CMGetDefaultProfileBySpace(cmCMYKData, (CMProfileRef *)&cmykProfile);
    CMGetDefaultProfileBySpace(cmGrayData, (CMProfileRef *)&grayProfile);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:DefaultDocumentColorProfileDidChangeNotification object:nil]; 
}

- initDefaultDocumentProfile;
{
    [super init];
    
    CMGetDefaultProfileBySpace(cmRGBData, (CMProfileRef *)&rgbProfile);
    CMGetDefaultProfileBySpace(cmCMYKData, (CMProfileRef *)&cmykProfile);
    CMGetDefaultProfileBySpace(cmGrayData, (CMProfileRef *)&grayProfile);

// The notification isn't available on 10.1
#ifdef kCMPrefsChangedNotification
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(colorProfileDidChange:) name:(NSString *)kCMPrefsChangedNotification object:nil];
#endif

    isMutable = YES;
    return self;
}

- initDefaultProofProfile;
{
    CMProfileRef profile;
    CMAppleProfileHeader header;
    
    [super init];
    CMGetDefaultProfileByUse(cmProofUse, &profile);
    CMGetProfileHeader(profile, &header);
    switch(header.cm2.dataColorSpace) {
        case cmRGBData:
            rgbProfile = profile;
            break;
        case cmCMYKData:
            cmykProfile = profile;
            break;
        case cmGrayData:
            grayProfile = profile;
            break;
        default:
            [self release];
            return nil;
    }
    isMutable = YES;
    return self;
}

- initDefaultDisplayProfile;
{
    CMProfileRef profile;
    CMAppleProfileHeader header;
    
    [super init];
    CMGetDefaultProfileByUse(cmDisplayUse, &profile);
    CMGetProfileHeader(profile, &header);
    switch(header.cm2.dataColorSpace) {
        case cmRGBData:
            rgbProfile = profile;
            break;
        case cmCMYKData:
            cmykProfile = profile;
            break;
        case cmGrayData:
            grayProfile = profile;
            break;
        default:
            [self release];
            return nil;
    }
    isMutable = YES;
    return self;
}

- (void)_updateConversionCacheForOutput:(OAColorProfile *)aProfile;
{
    if (self != lastInProfile || aProfile != lastOutProfile) {
        if (rgbColorWorld != NULL) {
            CWDisposeColorWorld(rgbColorWorld);
            rgbColorWorld = NULL;
        }
        if (cmykColorWorld != NULL) {
            CWDisposeColorWorld(cmykColorWorld);
            cmykColorWorld = NULL;
        }
        if (grayColorWorld != NULL) {
            CWDisposeColorWorld(grayColorWorld);
            grayColorWorld = NULL;
        }
        lastInProfile = self;
        lastOutProfile = aProfile;
    }
}

- (void *)_anyProfile;
{
    if (rgbProfile)
        return rgbProfile;
    else if (cmykProfile)
        return cmykProfile;
    else 
        return grayProfile;
}

@end
