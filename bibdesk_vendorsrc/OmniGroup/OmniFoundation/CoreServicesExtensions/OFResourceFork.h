// Copyright 2000-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/CoreServicesExtensions/OFResourceFork.h 68913 2005-10-03 19:36:19Z kc $

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
- initWithContentsOfFile: (NSString *) aPath forkType: (OFForkType) aForkType createFork:(BOOL)shouldCreateFork;
- initWithContentsOfFile: (NSString *) aPath forkType: (OFForkType) aForkType;  //D.I.
- initWithContentsOfFile: (NSString *) aPath;

- (NSString *) path;

// Extracts strings from the specified STR# resource.
- (NSArray *) stringsForResourceWithIdentifier: (ResID) resourceIdentifier;

- (short) countForResourceType: (ResType) resourceType;
- (NSData *) dataForResourceType: (ResType) resourceType atIndex: (short) index;
- (void)deleteResourceOfType:(ResType)resType atIndex:(short)index;
- (void)setData:(NSData *)contentData forResourceType:(ResType)resType;

- (NSArray *)resourceTypes;
- (short)numberOfResourcesOfType:(NSString *)resourceType;
- (NSArray *)resourcesOfType:(NSString *)resourceType;

@end
