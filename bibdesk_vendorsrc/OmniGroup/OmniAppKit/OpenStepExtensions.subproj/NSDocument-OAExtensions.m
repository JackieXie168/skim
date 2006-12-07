// Copyright 2003-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "NSDocument-OAExtensions.h"

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <OmniBase/rcsid.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSDocument-OAExtensions.m,v 1.7 2004/02/10 04:07:34 kc Exp $");

#define OmniAppKitBackupFourCharCode FOUR_CHAR_CODE('OABK')

@interface NSDocument (OAExtensions_Private)
- (OFResourceFork *)_resourceFork;
- (OFResourceFork *)_resourceForkForFilename:(NSString *)filename;
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

    OFResourceFork *newFork = [self _resourceFork];
    [newFork setData:contentData forResourceType:OmniAppKitBackupFourCharCode];
    [self deleteAllBackupsButMostRecentInResourceFork];
    [newFork release];
}

- (void)readFromBackupInResourceFork;
{
    if (![self fileName])
        return;

    OFResourceFork *newFork = [self _resourceFork];
    NSData *backupData = [newFork dataForResourceType:OmniAppKitBackupFourCharCode atIndex:0];
    NSFileWrapper *wrapper = [[[NSFileWrapper alloc] initWithSerializedRepresentation:backupData] autorelease];
    [newFork release];
    
    [self loadFileWrapperRepresentation:wrapper ofType:[self fileType]];
}

- (BOOL)hasBackupInResourceFork;
{
    return [self fileHasSuitableBackupInResourceFork:[self fileName]];
}

- (BOOL)fileHasSuitableBackupInResourceFork:(NSString *)filename;
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:filename]) {
        return NO;
    }
    
    OFResourceFork *newFork = [self _resourceForkForFilename:filename];

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

    int i = 0;
    for (i = 0; i < count; i++) {
        [newFork deleteResourceOfType:OmniAppKitBackupFourCharCode atIndex:i];
    }

    [newFork release];
}

- (void)deleteAllBackupsButMostRecentInResourceFork;
{
    OFResourceFork *newFork = [self _resourceFork];
    
    int count = [newFork countForResourceType:OmniAppKitBackupFourCharCode];

    int i = 0;
    for (i = 0; i < count - 1; i++) {
        [newFork deleteResourceOfType:OmniAppKitBackupFourCharCode atIndex:i];
    }

    [newFork release];
}

@end

@implementation NSDocument (OAExtensions_Private)

- (OFResourceFork *)_resourceFork;
{
    BOOL isDirectory = NO;

    if (![[NSFileManager defaultManager] fileExistsAtPath:[self fileName] isDirectory:&isDirectory])
        return nil;

    if (isDirectory) {
        NSString *insideWrapperFilename = [[self fileName] stringByAppendingPathComponent:@".OABK"];

        if (![[NSFileManager defaultManager] fileExistsAtPath:insideWrapperFilename])
            [[NSFileManager defaultManager] createFileAtPath:insideWrapperFilename contents:[NSData data] attributes:[[NSFileManager defaultManager] fileAttributesAtPath:[self fileName] traverseLink:YES]];

        return [self _resourceForkForFilename:insideWrapperFilename];
    } else {
        return [self _resourceForkForFilename:[self fileName]];
    }
}

- (OFResourceFork *)_resourceForkForFilename:(NSString *)filename;
{
    if (!filename)
        return nil;

    BOOL isDirectory = NO;

    if (![[NSFileManager defaultManager] fileExistsAtPath:[self fileName] isDirectory:&isDirectory])
        return nil;

    if (isDirectory) {
        NSString *insideWrapperFilename = [[self fileName] stringByAppendingPathComponent:@".OABK"];

        if (![[NSFileManager defaultManager] fileExistsAtPath:insideWrapperFilename])
            [[NSFileManager defaultManager] createFileAtPath:insideWrapperFilename contents:[NSData data] attributes:[[NSFileManager defaultManager] fileAttributesAtPath:[self fileName] traverseLink:YES]];

        return [[OFResourceFork alloc] initWithContentsOfFile:insideWrapperFilename forkType:OFResourceForkType createFork:YES];
    } else {
        return [[OFResourceFork alloc] initWithContentsOfFile:filename forkType:OFResourceForkType createFork:YES];
    }    
}

@end
