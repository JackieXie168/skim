// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/FileManagement.subproj/OFUnixFile.h 68913 2005-10-03 19:36:19Z kc $

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
