// Copyright 2002-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OAColorProfile.h"
#import "NSColor-ColorSyncExtensions.h"
#import <Cocoa/Cocoa.h>
#import <OmniBase/rcsid.h>
#import <OmniBase/OBUtilities.h>
#import <OmniFoundation/OmniFoundation.h>
#import <OmniBase/assertions.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniAppKit/ColorSync/OAColorProfile.m 68913 2005-10-03 19:36:19Z kc $");

@interface OAColorProfile (Private)
+ (void)_deviceNotification:(NSNotification *)notification;
- initDefaultDocumentProfile;
- initDefaultProofProfile;
- initDefaultDisplayProfile;

- (NSString *)_getProfileName:(void *)aProfile;
- (void *)_anyProfile;
- (void)_updateConversionCacheForOutput:(OAColorProfile *)outputProfile;
- (NSData *)_dataForRawProfile:(void *)rawProfile;
- (BOOL)_rawProfileIsBuiltIn:(void *)rawProfile;
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
    CMError err;
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
    
    err = CMOpenProfile(&cmProfile, &profileInfo->profileLoc);
    if (err != noErr)
        return 0;
    
    err = CMGetProfileHeader(cmProfile, &header);
    if (err != noErr) {
        CMCloseProfile(cmProfile);
        return 0;
    }
    
    profile = [[OAColorProfile alloc] init];
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
    OAColorProfile *match;

    [self _iterateAvailableProfiles];
    
    if (rgbName) {
        match = [rgbProfileDictionary objectForKey:rgbName];
        if (match) {
            profile->rgbProfile = match->rgbProfile;
            CMCloneProfileRef((CMProfileRef)profile->rgbProfile);
        }
    }
    if (cmykName) {
        match = [cmykProfileDictionary objectForKey:cmykName];
        if (match) {
            profile->cmykProfile = match->cmykProfile;
            CMCloneProfileRef((CMProfileRef)profile->cmykProfile);
        }
    }
    if (grayName) {
        match = [grayProfileDictionary objectForKey:grayName];
        if (match) {
            profile->grayProfile = match->grayProfile;
            CMCloneProfileRef((CMProfileRef)profile->grayProfile);
        }
    }
    return [profile autorelease];
}

+ (OAColorProfile *)colorProfileFromPropertyListRepresentation:(NSDictionary *)dict;
{
    OAColorProfile *colorProfile;
    OAColorProfile *match;
    NSData *data;
    NSString *name;
    CMProfileLocation profileLocation;
    
    [self _iterateAvailableProfiles];
    colorProfile = [[[self alloc] init] autorelease];
    
    data = [dict objectForKey:@"rgb"];
    if (data) {
        profileLocation.locType = cmBufferBasedProfile;
        profileLocation.u.bufferLoc.buffer = (void *)[data bytes];
        profileLocation.u.bufferLoc.size = [data length];
        CMOpenProfile((CMProfileRef *)&colorProfile->rgbProfile, &profileLocation);
    } else if ((name = [dict objectForKey:@"rgbName"])) {
        match = [rgbProfileDictionary objectForKey:name];
        if (match) {
            colorProfile->rgbProfile = match->rgbProfile;
            CMCloneProfileRef((CMProfileRef)colorProfile->rgbProfile);
        }
    }
    
    data = [dict objectForKey:@"cmyk"];
    if (data) {
        profileLocation.locType = cmBufferBasedProfile;
        profileLocation.u.bufferLoc.buffer = (void *)[data bytes];
        profileLocation.u.bufferLoc.size = [data length];
        CMOpenProfile((CMProfileRef *)&colorProfile->cmykProfile, &profileLocation);
    } else if ((name = [dict objectForKey:@"cmykName"])) {
        match = [cmykProfileDictionary objectForKey:name];
        if (match) {
            colorProfile->cmykProfile = match->cmykProfile;
            CMCloneProfileRef((CMProfileRef)colorProfile->cmykProfile);
        }
    }

    data = [dict objectForKey:@"gray"];
    if (data) {
        profileLocation.locType = cmBufferBasedProfile;
        profileLocation.u.bufferLoc.buffer = (void *)[data bytes];
        profileLocation.u.bufferLoc.size = [data length];
        CMOpenProfile((CMProfileRef *)&colorProfile->grayProfile, &profileLocation);
    } else if ((name = [dict objectForKey:@"grayName"])) {
        match = [grayProfileDictionary objectForKey:name];
        if (match) {
            colorProfile->grayProfile = match->grayProfile;
            CMCloneProfileRef((CMProfileRef)colorProfile->grayProfile);
        }
    }
    
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
    NSMutableDictionary *result = [NSMutableDictionary dictionary];

    if ([self _rawProfileIsBuiltIn:rgbProfile])
        [result setObject:[self _getProfileName:rgbProfile] forKey:@"rgbName"];
    else
        [result setObject:[self _dataForRawProfile:rgbProfile] forKey:@"rgb"];
    if ([self _rawProfileIsBuiltIn:cmykProfile])
        [result setObject:[self _getProfileName:cmykProfile] forKey:@"cmykName"];
    else
        [result setObject:[self _dataForRawProfile:cmykProfile] forKey:@"cmyk"];
    if ([self _rawProfileIsBuiltIn:grayProfile])
        [result setObject:[self _getProfileName:grayProfile] forKey:@"grayName"];
    else
        [result setObject:[self _dataForRawProfile:grayProfile] forKey:@"gray"];
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

- (NSData *)rgbData;
{
    return (rgbProfile == nil) ? nil : [self _dataForRawProfile:rgbProfile];
}
- (NSData *)cmykData;
{
    return (cmykProfile == nil) ? nil : [self _dataForRawProfile:cmykProfile];
}
- (NSData *)grayData;
{
    return (grayProfile == nil) ? nil : [self _dataForRawProfile:grayProfile];
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

// TODO: Assumes display profile is always RGB
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

- (NSData *)_dataForRawProfile:(void *)rawProfile;
{
    CMProfileRef targetRef;
    CMAppleProfileHeader header;
    CMProfileLocation profileLocation;
    NSMutableData *data;

    CMGetProfileHeader(rawProfile, &header);
    data = [[NSMutableData alloc] initWithLength:header.cm1.size];
    profileLocation.locType = cmBufferBasedProfile;
    profileLocation.u.bufferLoc.buffer = [data mutableBytes];
    profileLocation.u.bufferLoc.size = header.cm1.size;
    CMCopyProfile(&targetRef, &profileLocation, rawProfile);
    CMCloseProfile(targetRef);
    return [data autorelease];
}

- (BOOL)_rawProfileIsBuiltIn:(void *)rawProfile;
{
    CMProfileLocation profileLocation;

    CMGetProfileLocation(rawProfile, &profileLocation);
    if (profileLocation.locType == cmFileBasedProfile) {
        FSRef fsRef;
        CFURLRef url;
        CFStringRef string;
        BOOL result;
        
        FSpMakeFSRef(&profileLocation.u.fileLoc.spec, &fsRef);
        url = CFURLCreateFromFSRef(NULL, &fsRef);
        string = CFURLCopyPath(url);
        result = [(NSString *)string hasPrefix:@"/System/Library/ColorSync/Profiles"];
        CFRelease(url);
        CFRelease(string);
        return result;
    } else if (profileLocation.locType == cmPathBasedProfile) {
        return !strncmp(profileLocation.u.pathLoc.path, "/System/Library/ColorSync/Profiles/", 35);
    } else {
        return NO;
    }
}

@end
