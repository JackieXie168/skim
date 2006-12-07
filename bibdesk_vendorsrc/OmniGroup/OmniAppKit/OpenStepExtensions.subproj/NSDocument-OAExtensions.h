// Copyright 2003-2006 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSDocument-OAExtensions.h 79079 2006-09-07 22:35:32Z kc $

#import <AppKit/NSDocument.h>

@interface NSDocument (OAExtensions)

#if defined(MAC_OS_X_VERSION_10_4) && MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_4
- (NSFileWrapper *)fileWrapperOfType:(NSString *)typeName saveOperation:(NSSaveOperationType)saveOperationType error:(NSError **)outError;
#else
- (NSFileWrapper *)fileWrapperRepresentationOfType:(NSString *)type saveOperation:(NSSaveOperationType)saveOperationType;
#endif

- (void)writeToBackupInResourceFork;
- (NSFileWrapper *)fileWrapperFromBackupInResourceFork;
- (BOOL)readFromBackupInResourceFork;
- (BOOL)hasBackupInResourceFork;
- (void)deleteAllBackupsInResourceFork;
- (void)deleteAllBackupsButMostRecentInResourceFork;

@end
