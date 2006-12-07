// Copyright 2002-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSFileManager-OAExtensions.h,v 1.6 2004/02/10 04:07:34 kc Exp $

#import <Foundation/NSFileManager.h>

@class NSImage;

@interface NSFileManager (OAExtensions)
- (void)setIconImage:(NSImage *)newImage forPath:(NSString *)path;
- (void)setComment:(NSString *)aComment forPath:(NSString *)path;
    // This implementation is dependent on AppleScript, which we don't have in Foundation
@end
