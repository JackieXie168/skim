// Copyright 2002 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header$

#import <Foundation/NSFileManager.h>

// This implementation is dependent on AppleScript, which we don't have in Foundation

@interface NSFileManager (OAExtensions)
- (void)setComment:(NSString *)aComment forPath:(NSString *)path;
@end
