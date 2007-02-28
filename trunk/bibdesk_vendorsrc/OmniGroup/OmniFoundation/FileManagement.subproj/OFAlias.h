// Copyright 2004-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/FileManagement.subproj/OFAlias.h 66265 2005-07-29 04:07:59Z bungi $

#import <Foundation/NSObject.h>
#import <Carbon/Carbon.h>

@class NSData; 	// Foundation

@interface OFAlias : NSObject 
{
    AliasHandle _aliasHandle;
}

// API
- initWithPath:(NSString *)path;
- initWithData:(NSData *)data;

// returns nil if the alias doesn't resolve
- (NSString *)path;
- (NSString *)pathAllowingUserInterface:(BOOL)allowUserInterface missingVolume:(BOOL *)missingVolume;
- (NSData *)data;

@end
