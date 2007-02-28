// Copyright 2002-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSFileManager-OAExtensions.h 68913 2005-10-03 19:36:19Z kc $

#import <Foundation/NSFileManager.h>

@class NSImage;

@interface NSFileManager (OAExtensions)
- (void)setIconImage:(NSImage *)newImage forPath:(NSString *)path;
- (void)setComment:(NSString *)aComment forPath:(NSString *)path;
    // This implementation is dependent on AppleScript, which we don't have in Foundation
- (void)updateForFileAtPath:(NSString *)path;
    // This implementation is dependent on AppleScript, which we don't have in Foundation
@end
