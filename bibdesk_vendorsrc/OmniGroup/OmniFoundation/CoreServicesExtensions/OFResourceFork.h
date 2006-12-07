// Copyright 2000-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/CoreServicesExtensions/OFResourceFork.h,v 1.6 2003/02/06 22:33:09 wiml Exp $

#import <OmniFoundation/OFObject.h>
#import <CoreServices/CoreServices.h>

@class NSArray, NSData, NSString;

typedef enum _OFForkType {
    OFDataForkType,
    OFResourceForkType
} OFForkType;

@interface OFResourceFork : OFObject
{
    NSString   *path;
    BOOL        refNumValid;
    SInt16      refNum;
}

// Parses a STR# resource into an array of strings. May raise an exception.
+ (NSArray *) stringsFromSTRResourceHandle: (Handle) resourceHandle;

// Creating an OFResourceFork from something on disk.
- initWithContentsOfFile: (NSString *) aPath forkType: (OFForkType) aForkType;  //D.I.
- initWithContentsOfFile: (NSString *) aPath;

- (NSString *) path;

// Extracts strings from the specified STR# resource.
- (NSArray *) stringsForResourceWithIdentifier: (ResID) resourceIdentifier;

- (short) countForResourceType: (ResType) resourceType;
- (NSData *) dataForResourceType: (ResType) resourceType atIndex: (short) index;

- (NSArray *)resourceTypes;
- (short)numberOfResourcesOfType:(NSString *)resourceType;
- (NSArray *)resourcesOfType:(NSString *)resourceType;

@end
