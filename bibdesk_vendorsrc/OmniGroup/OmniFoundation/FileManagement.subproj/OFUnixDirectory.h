// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/FileManagement.subproj/OFUnixDirectory.h,v 1.11 2004/02/10 04:07:44 kc Exp $

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
