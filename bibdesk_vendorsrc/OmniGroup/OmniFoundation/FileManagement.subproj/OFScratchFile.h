// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/FileManagement.subproj/OFScratchFile.h,v 1.10 2004/02/10 04:07:44 kc Exp $

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
