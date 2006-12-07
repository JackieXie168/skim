// Copyright 2001-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/CoreServicesExtensions/OFResource.h,v 1.3 2003/01/15 22:51:52 kc Exp $

#import <OmniFoundation/OFObject.h>

@class OFResourceFork;

#import <CoreServices/CoreServices.h> // For Handle

@interface OFResource : OFObject
{
    OFResourceFork *resourceFork;
    Handle resourceHandle;
    
    short resourceID;
    NSString *type;
    NSString *name;
}

- (id)initInResourceFork:(OFResourceFork *)resFork withHandle:(Handle)resHandle;

// API

- (void)recacheInfo;
- (void)saveInfoToDisk;

- (Handle)resourceHandle;
- (void)setResourceHandle:(Handle)newHandle;

- (NSString *)name;
- (void)setName:(NSString *)newName;
- (short)resourceID;
- (void)setResourceID:(short)newResourceID;
- (NSString *)type;

- (unsigned long)size;

@end
