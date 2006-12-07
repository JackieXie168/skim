// Copyright 2000-2002 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header$

#import <OmniFoundation/OFObject.h>

@class NSArray, NSData; // Foundation
@class OAInternetConfigMapEntry;

typedef struct _OAInternetConfigInfo {
    BOOL valid;
    long creatorCode;
    NSString *applicationName;
} OAInternetConfigInfo;

@interface OAInternetConfig : OFObject
{
    void *internetConfigInstance;
    int permissionStatus;
}

+ (OAInternetConfig *)internetConfig;

// Returns the CFBundleSignature of the main bundle. This method isn't InternetConfig-specific, really...
+ (unsigned long)applicationSignature;

// Helper applications for URLs

- (OAInternetConfigInfo)getInfoForScheme:(NSString *)scheme;
- (NSString *)helperApplicationForScheme:(NSString *)scheme;
- (void)setApplicationCreatorCode:(long)applicationCreatorCode name:(NSString *)applicationName forScheme:(NSString *)scheme;
- (void)launchURL:(NSString *)urlString;

// Download folder

- (NSString *)downloadFolderPath;

// Mappings between type/creator codes and filename extensions

- (NSArray *)mapEntries;
- (OAInternetConfigMapEntry *)mapEntryForFilename:(NSString *)filename;
- (OAInternetConfigMapEntry *)mapEntryForTypeCode:(long)fileTypeCode creatorCode:(long)fileCreatorCode hintFilename:(NSString *)filename;

// User interface access (launches InternetConfig preferences editor)

- (void)editPreferencesFocusOnKey:(NSString *)key;

// Low-level access

- (void)beginReadOnlyAccess;
- (void)beginReadWriteAccess;
- (void)endAccess;

- (NSArray *)allPreferenceKeys;
- (NSData *)dataForPreferenceKey:(NSString *)preferenceKey;

// High level methods

- (void)launchMailTo:(NSString *)receiver carbonCopy:(NSString *)carbonCopy subject:(NSString *)subject body:(NSString *)body;
               
@end
