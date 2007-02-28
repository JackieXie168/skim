// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/FileManagement.subproj/OFUnixDirectory.h 68913 2005-10-03 19:36:19Z kc $

#import <OmniFoundation/OFDirectory.h>

@interface OFUnixDirectory : OFDirectory
{
    NSMutableArray *files;
}

- (void)scanDirectory;
- (BOOL)copyToPath:(NSString *)destinationPath;

@end

#import <OmniFoundation/FrameworkDefines.h>

OmniFoundation_EXTERN NSString *OFUnixDirectoryCannotReadDirectoryException;
