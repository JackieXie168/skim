// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/FileManagement.subproj/OFUnixFile.h,v 1.9 2003/01/15 22:51:56 kc Exp $

#import <OmniFoundation/OFFile.h>

typedef enum {
    OFFILETYPE_DIRECTORY, OFFILETYPE_CHARACTER, OFFILETYPE_BLOCK, OFFILETYPE_REGULAR, OFFILETYPE_SOCKET
} OFFileType;

@interface OFUnixFile : OFFile
{
    BOOL hasInfo, symLink;
    OFFileType fileType;
    NSNumber *size;
    NSCalendarDate *lastChanged;
}

- (NSString *)shortcutDestination;
- (BOOL)copyToPath:(NSString *)destinationPath;

@end

#import <OmniFoundation/FrameworkDefines.h>

OmniFoundation_EXTERN NSString *OFUnixFileGenericFailureException;
