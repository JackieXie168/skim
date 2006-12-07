// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/FileManagement.subproj/OFScratchFile.h,v 1.8 2003/01/15 22:51:56 kc Exp $

#import <OmniFoundation/OFObject.h>

@class NSData, NSMutableArray;
@class OFDataCursor;

@interface OFScratchFile : OFObject
{
    NSString                   *filename;
    NSData                     *contentData;
    NSString                   *contentString;
    NSMutableArray             *retainedObjects;
}

+ (OFScratchFile *)scratchFileNamed:(NSString *)aName;
+ (OFScratchFile *)scratchDirectoryNamed:(NSString *)aName;

- initWithFilename:(NSString *)aFilename;
- (NSString *)filename;
- (NSData *)contentData;
- (NSString *)contentString;
- (OFDataCursor *)contentDataCursor;

- (void)retainObject:anObject;

@end
