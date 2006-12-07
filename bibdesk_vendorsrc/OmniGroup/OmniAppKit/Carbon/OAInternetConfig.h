// Copyright 2000-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Carbon/OAInternetConfig.h,v 1.17 2004/02/10 04:07:31 kc Exp $

#import <OmniFoundation/OFObject.h>

@class NSArray, NSData; // Foundation
@class OAInternetConfigMapEntry;

@interface OAInternetConfig : OFObject
{
    void *internetConfigInstance;
    int permissionStatus;
}

+ (OAInternetConfig *)internetConfig;

// Returns the CFBundleSignature of the main bundle. This method isn't InternetConfig-specific, really...
+ (unsigned long)applicationSignature;

// Extracts the user's iTools account name from InternetConfig.
- (NSString *)iToolsAccountName;

// Helper applications for URLs

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

/* returns an array of NSStrings enumerating the keys available via InternetConfig */
- (NSArray *)allPreferenceKeys;
/* returns key data, nil if key not found, or raises an exception */
- (NSData *)dataForPreferenceKey:(NSString *)preferenceKey;

// High level methods

- (void)launchMailTo:(NSString *)receiver carbonCopy:(NSString *)carbonCopy subject:(NSString *)subject body:(NSString *)body;
- (void)launchMailTo:(NSString *)receiver carbonCopy:(NSString *)carbonCopy blindCarbonCopy:(NSString *)blindCarbonCopy subject:(NSString *)subject body:(NSString *)body;

- (BOOL)launchMailTo:(NSString *)receiver carbonCopy:(NSString *)carbonCopy blindCarbonCopy:(NSString *)blindCarbonCopy subject:(NSString *)subject body:(NSString *)body attachments:(NSArray *)attachmentFilenames;

@end
