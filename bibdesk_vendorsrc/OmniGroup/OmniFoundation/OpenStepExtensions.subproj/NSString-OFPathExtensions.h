// Copyright 1999-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSString-OFPathExtensions.h,v 1.7 2003/01/27 05:51:16 rick Exp $

#import <Foundation/NSString.h>

@interface NSString (OFPathExtensions)

- (NSString *) fileSystemSafeNonLossyPathComponent;
    // When called on a path component, this returns a new path component that can be safely stored in any relevant filesystem.  This eliminates special chararacters by encoding them in a recoverable fashion.  This does NOT eliminate case issues.  That is, it is still not safe to store two files with differing cases.
- (NSString *) decodedFileSystemSafeNonLossyPathComponent;
    // Returns the original string used to generate this string via -fileSystemSafeNonLossyPathComponent.

- (NSString *) prettyPathString;
    // Reformats a path as 'lastComponent emdash stringByByRemovingLastPathComponent.

+ (NSString *)pathSeparator;
    // Whatever character constitutes the platform-specific path separator used by NSString's path utilities. Unless your on another planet or something, this should return @"/". Thanks to this method, the methods below should be mostly system-independent. Not that we're running on Windows anytime soon...
+ (NSString *)commonRootPathOfFilename:(NSString *)filename andFilename:(NSString *)otherFilename;
    // Given absolute file paths like "/applications/omniweb/screenshots/index.html" and "/applications/omniweb/faq/content.html", returns a the common ancestor of both paths, "/applications/omniweb/". Returns nil if the paths have no common root (well, other than the root of the filesystem).
- (NSString *)relativePathToFilename:(NSString *)otherFilename;
    // Given absolute file paths like "/applications/omniweb/screenshots/index.html" and "/applications/omniweb/faq/content.html", returns a relative path, "../../faq/content.html". If no relative path is possible (i.e. the paths have no common root), returns otherFilename.

@end
