// Copyright 2001-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/CoreServicesExtensions/OFResource.h,v 1.5 2004/02/10 04:07:42 kc Exp $

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
