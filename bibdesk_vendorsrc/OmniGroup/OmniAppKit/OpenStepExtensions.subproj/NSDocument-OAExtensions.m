// Copyright 2003-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "NSDocument-OAExtensions.h"

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <OmniBase/rcsid.h>
#import <OmniFoundation/OmniFoundation.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/SourceRelease_2005-10-03/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSDocument-OAExtensions.m 68913 2005-10-03 19:36:19Z kc $");

#define OmniAppKitBackupFourCharCode FOUR_CHAR_CODE('OABK')

@interface NSDocument (OAExtensions_Private)
- (OFResourceFork *)_resourceFork;
- (OFResourceFork *)_resourceForkCreateIfMissing:(BOOL)create;
@end

@implementation NSDocument (OAExtensions)

- (NSFileWrapper *)fileWrapperRepresentationOfType:(NSString *)type saveOperation:(NSSaveOperationType)saveOperationType;
/*" Methods that care about the save operation when building their file wrapper can subclass this.  OmniAppKit's NSDocument support for autosave calls this method, but currently no other code path does, so you still need to override -fileWrapperRepresentationOfType:.  This just gives the autosave support a way to inform the document that it is saving with a specific operation during autosave. "*/
{
    return [self fileWrapperRepresentationOfType:type];
}

- (void)writeToBackupInResourceFork;
{
    if (![self fileName])
        return;

    NSFileWrapper *wrapper = [self fileWrapperRepresentationOfType:[self fileType] saveOperation:NSSaveOperation];
    NSData *contentData = [wrapper serializedRepresentation];

    OFResourceFork *newFork = [self _resourceForkCreateIfMissing:YES];
    [newFork setData:contentData forResourceType:OmniAppKitBackupFourCharCode];
    // release newFork so that deleteAllBackups... can open it.
    [newFork release];
    [self deleteAllBackupsButMostRecentInResourceFork];
}

- (NSFileWrapper *)fileWrapperFromBackupInResourceFork;
{
    OBPRECONDITION([self fileName]);
    if (![self fileName])
        return NO;

    OFResourceFork *newFork = [self _resourceFork];
    // if we're maintaining our resource data correctly there are two possibilities:
    // - we have 2 backups because we crashed doing a backup.  So use the penultimate backup
    // - we have one backup because life is good.  Use the last backup
    // in either case, this means we want to load the backup at index 0.
    NSData *backupData = [newFork dataForResourceType:OmniAppKitBackupFourCharCode atIndex:0];
    NSFileWrapper *wrapper = [[[NSFileWrapper alloc] initWithSerializedRepresentation:backupData] autorelease];
    [newFork release];

    return wrapper;
}

- (BOOL)readFromBackupInResourceFork;
{
    NSFileWrapper *wrapper = [self fileWrapperFromBackupInResourceFork];
    return [self loadFileWrapperRepresentation:wrapper ofType:[self fileType]];
}

- (BOOL)hasBackupInResourceFork;
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:[self fileName]]) {
        return NO;
    }
    
    OFResourceFork *newFork = [self _resourceForkCreateIfMissing:NO];

    short count = [newFork countForResourceType:OmniAppKitBackupFourCharCode];

#if 0 && defined(DEBUG_corwin)
    NSLog(@"filename %@ has %d resources", filename, count);
#endif
    
    BOOL result = (count > 0);

    [newFork release];

    return result;
}

- (void)deleteAllBackupsInResourceFork;
{
    OFResourceFork *newFork = [self _resourceFork];

    int count = [newFork countForResourceType:OmniAppKitBackupFourCharCode];
    while (count-- > 0) {
        [newFork deleteResourceOfType:OmniAppKitBackupFourCharCode atIndex:count];
        OBASSERT([newFork countForResourceType:OmniAppKitBackupFourCharCode] == count);
    }

    [newFork release];
}

- (void)deleteAllBackupsButMostRecentInResourceFork;
{
    OFResourceFork *newFork = [self _resourceFork];
    
    int count = [newFork countForResourceType:OmniAppKitBackupFourCharCode];

    while (count-- > 1) {
        [newFork deleteResourceOfType:OmniAppKitBackupFourCharCode atIndex:count - 1];
        OBASSERT([newFork countForResourceType:OmniAppKitBackupFourCharCode] == count);
    }

    [newFork release];
}

@end

@implementation NSDocument (OAExtensions_Private)

- (OFResourceFork *)_resourceFork
{
    return [self _resourceForkCreateIfMissing:NO];
}

- (OFResourceFork *)_resourceForkCreateIfMissing:(BOOL)create;
{
    BOOL isDirectory = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *fileName = [self fileName];

    if (!fileName)
        return nil;

    if (![fileManager fileExistsAtPath:fileName isDirectory:&isDirectory])
        return nil;

    if (isDirectory) {
        NSString *insideWrapperFilename = [fileName stringByAppendingPathComponent:@".OABK"];

        if (![fileManager fileExistsAtPath:insideWrapperFilename]) {
            if (!create)
                return nil;
            
            if (![fileManager createFileAtPath:insideWrapperFilename contents:[NSData data] attributes:[fileManager fileAttributesAtPath:fileName traverseLink:YES]])
                [NSException raise:NSInvalidArgumentException format:@"Unable to create backup file at %@", fileName];
        }
        
        return [[OFResourceFork alloc] initWithContentsOfFile:insideWrapperFilename forkType:OFResourceForkType createFork:create];
    } else {
        return [[OFResourceFork alloc] initWithContentsOfFile:fileName forkType:OFResourceForkType createFork:create];
    }    
}

@end
