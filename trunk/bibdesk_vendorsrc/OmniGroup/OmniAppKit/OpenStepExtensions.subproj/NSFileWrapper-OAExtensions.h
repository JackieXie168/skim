// Copyright 2006 The Omni Group.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSFileWrapper-OAExtensions.h 77393 2006-07-12 18:15:18Z wiml $

#import <AppKit/NSFileWrapper.h>

@interface NSFileWrapper (OAExtensions)
- (NSString *)fileType:(BOOL *)isHFSType;
- (BOOL)recursivelyWriteHFSAttributesToFile:(NSString *)file;
- (void)addFileWrapperMovingAsidePreviousWrapper:(NSFileWrapper *)wrapper;
@end


