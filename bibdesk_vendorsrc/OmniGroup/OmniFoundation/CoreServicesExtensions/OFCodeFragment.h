// Copyright 2000-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/CoreServicesExtensions/OFCodeFragment.h 68913 2005-10-03 19:36:19Z kc $

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
