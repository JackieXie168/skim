// Copyright 2000-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/CoreServicesExtensions/OFCodeFragment.h,v 1.3 2003/01/15 22:51:52 kc Exp $

#import <OmniFoundation/OFObject.h>

#import <CoreServices/CoreServices.h> // For CFragConnectionID, Ptr
#import <Foundation/NSMapTable.h>

#import <OmniFoundation/OFSimpleLock.h>
#import <OmniFoundation/OFBulkBlockPool.h>

@interface OFCodeFragment : OFObject
{
    NSString           *path;
    CFragConnectionID   connectionID;
    Ptr                 mainAddress;
    
    OFSimpleLockType    lock;
    OFBulkBlockPool     locked_functionBlockPool;
    NSMapTable         *locked_functionTable;
    NSArray            *locked_symbolNames;
}

- initWithContentsOfFile: (NSString *) aPath;

- (NSString *) path;

- (NSArray *) symbolNames;

- (void (*)()) mainAddress;
- (void (*)()) functionNamed: (NSString *) symbolName;
- (void (*)()) wrapperFunctionForCFMTVector: (void *) tvector;


@end
