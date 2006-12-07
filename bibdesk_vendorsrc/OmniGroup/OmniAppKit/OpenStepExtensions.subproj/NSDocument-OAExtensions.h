// Copyright 2003-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSDocument-OAExtensions.h,v 1.4 2004/02/10 04:07:34 kc Exp $

#import <Foundation/NSObject.h>

@interface NSDocument (OAExtensions)

- (NSFileWrapper *)fileWrapperRepresentationOfType:(NSString *)type saveOperation:(NSSaveOperationType)saveOperationType;

- (void)writeToBackupInResourceFork;
- (void)readFromBackupInResourceFork;
- (BOOL)hasBackupInResourceFork;
- (BOOL)fileHasSuitableBackupInResourceFork:(NSString *)filename;
- (void)deleteAllBackupsInResourceFork;
- (void)deleteAllBackupsButMostRecentInResourceFork;

@end
