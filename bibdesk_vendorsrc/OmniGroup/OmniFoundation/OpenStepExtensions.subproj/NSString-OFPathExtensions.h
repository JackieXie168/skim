// Copyright 1999-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/SourceRelease_2005-10-03/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSString-OFPathExtensions.h 68913 2005-10-03 19:36:19Z kc $

#import <Foundation/NSString.h>

@interface NSString (OFPathExtensions)

- (NSString *) prettyPathString;
    // Reformats a path as 'lastComponent emdash stringByByRemovingLastPathComponent.

+ (NSString *)pathSeparator;
    // Whatever character constitutes the platform-specific path separator used by NSString's path utilities. Unless your on another planet or something, this should return @"/". Thanks to this method, the methods below should be mostly system-independent. Not that we're running on Windows anytime soon...
+ (NSString *)commonRootPathOfFilename:(NSString *)filename andFilename:(NSString *)otherFilename;
    // Given absolute file paths like "/applications/omniweb/screenshots/index.html" and "/applications/omniweb/faq/content.html", returns a the common ancestor of both paths, "/applications/omniweb/". Returns nil if the paths have no common root (well, other than the root of the filesystem).
- (NSString *)relativePathToFilename:(NSString *)otherFilename;
    // Given absolute file paths like "/applications/omniweb/screenshots/index.html" and "/applications/omniweb/faq/content.html", returns a relative path, "../../faq/content.html". If no relative path is possible (i.e. the paths have no common root), returns otherFilename.

@end
