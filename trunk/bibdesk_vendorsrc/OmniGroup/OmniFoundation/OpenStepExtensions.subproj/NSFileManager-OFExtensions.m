// Copyright 1997-2006 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "NSFileManager-OFExtensions.h"

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>
#import <OmniBase/system.h>
#import "NSProcessInfo-OFExtensions.h"
#import "NSArray-OFExtensions.h"
#import "NSString-OFExtensions.h"
#import "NSString-OFPathExtensions.h"
#import "OFUtilities.h"

#import <sys/errno.h>
#import <sys/param.h>
#import <stdio.h>
#import <sys/mount.h>
#import <unistd.h>
#import <sys/types.h>
#import <sys/stat.h>
#import <sys/attr.h>
#import <fcntl.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSFileManager-OFExtensions.m 76838 2006-06-22 21:07:06Z wiml $")
@interface NSFileManager (OFPrivate)
- (int)filesystemStats:(struct statfs *)stats forPath:(NSString *)path;
- (NSString *)lockFilePathForPath:(NSString *)path;
@end

@implementation NSFileManager (OFExtensions)

static NSLock *tempFilenameLock;
static NSString *scratchDirectoryPath;
static NSLock *scratchDirectoryLock;
static int permissionsMask = 0022;

+ (void)didLoad;
{
    tempFilenameLock = [[NSLock alloc] init];
    scratchDirectoryPath = nil;
    scratchDirectoryLock = [[NSLock alloc] init];

    permissionsMask = umask(permissionsMask);
    umask(permissionsMask); // Restore the original value
}

- (NSString *)desktopDirectory;
{
    FSRef dirRef;
    OSErr err = FSFindFolder(kUserDomain, kDesktopFolderType, kCreateFolder, &dirRef);
    if (err != noErr) {
#ifdef DEBUG
        NSLog(@"FSFindFolder(kDesktopFolderType) -> %ld", err);
#endif
        [NSException raise:NSInvalidArgumentException format:@"Unable to find desktop directory"];
    }

    CFURLRef url;
    url = CFURLCreateFromFSRef(kCFAllocatorDefault, &dirRef);
    if (!url)
        [NSException raise:NSInvalidArgumentException format:@"Unable to create URL to desktop directory"];

    NSString *path = [[[(NSURL *)url path] copy] autorelease];
    [(id)url release];

    return path;
}

- (NSString *)documentDirectory;
{
    FSRef dirRef;
    OSErr err = FSFindFolder(kUserDomain, kDocumentsFolderType, kCreateFolder, &dirRef);
    if (err != noErr) {
#ifdef DEBUG
        NSLog(@"FSFindFolder(kDocumentsFolderType) -> %ld", err);
#endif
        [NSException raise:NSInvalidArgumentException format:@"Unable to find document directory"];
    }

    CFURLRef url;
    url = CFURLCreateFromFSRef(kCFAllocatorDefault, &dirRef);
    if (!url)
        [NSException raise:NSInvalidArgumentException format:@"Unable to create URL to document directory"];

    NSString *path = [[[(NSURL *)url path] copy] autorelease];
    [(id)url release];

    return path;
}

// Note that due to the permissions behavior of FSFindFolder, this shouldn't have the security problems that raw calls to -uniqueFilenameFromName: may have.
- (NSString *)temporaryPathForWritingToPath:(NSString *)path allowOriginalDirectory:(BOOL)allowOriginalDirectory;
/*" Returns a unique filename in the -temporaryDirectoryForFileSystemContainingPath: for the filesystem containing the given path.  The returned path is suitable for writing to and then replacing the input path using -replaceFileAtPath:withFileAtPath:handler:.  This means that the result should never be equal to the input path.  If no suitable temporary items folder is found and allowOriginalDirectory is NO, this will raise.  If allowOriginalDirectory is YES, on the other hand, this will return a file name in the same folder.  Note that passing YES for allowOriginalDirectory could potentially result in security implications of the form noted with -uniqueFilenameFromName:. "*/
{
    OBPRECONDITION(![NSString isEmptyString:path]);
    
    NSString *temporaryFilePath;
    NS_DURING {
        NSString *dir = [self temporaryDirectoryForFileSystemContainingPath:path];
        temporaryFilePath = [dir stringByAppendingPathComponent:[path lastPathComponent]];

        // Don't pass in paths that are already inside Temporary Items or you might get back the same path you passed in.
        OBASSERT(![temporaryFilePath isEqualToString:path]);

        temporaryFilePath = [self uniqueFilenameFromName:temporaryFilePath allowOriginal:NO create:YES];
    } NS_HANDLER {
        if (!allowOriginalDirectory)
            [localException raise];

        // Try to use the same directory.  Can't just call -uniqueFilenameFromName:path since we want a NEW file name (-uniqueFilenameFromName: would just return the input path and the caller expecting a path where it can put something temporarily, i.e., different from the input path).
        temporaryFilePath = [self uniqueFilenameFromName:path allowOriginal:NO create:YES];
    } NS_ENDHANDLER;

    OBPOSTCONDITION([self fileExistsAtPath:temporaryFilePath]);
    OBPOSTCONDITION(![path isEqualToString:temporaryFilePath]);
    return temporaryFilePath;
}

// Note that if this raises, a common course of action would be to put the temporary file in the same folder as the original file.  This has the same security problems as -uniqueFilenameFromName:, of course, so we don't want to do that by default.  The calling code should make this decision.
- (NSString *)temporaryDirectoryForFileSystemContainingPath:(NSString *)path;
/*" Returns the path to the 'Temporary Items' folder on the same filesystem as the given path.  Raises if there is an error (for example, iDisk doesn't have temporary folders).  The returned directory should be only readable by the calling user, so files written into this directory can be written with the desired final permissions without worrying about security (the expectation being that you'll soon call -exchangeFileAtPath:withFileAtPath:). "*/
{
    OSErr err;
    FSRef ref;

    // If an alternate temporary volume has been specified, use the 'Temporary Items' folder on that volume rather than on the same volume as the specified file
    NSString *stringValue = [[NSUserDefaults standardUserDefaults] stringForKey:@"OFTemporaryVolumeOverride"];
    if (![NSString isEmptyString:stringValue]) {
        path = [stringValue stringByStandardizingPath];
    }

    // The file in question might not exist yet.  This loop assumes that it will terminate due to '/' always being valid.
    NSString *attempt = path;
    while (YES) {
        CFURLRef url = (CFURLRef)[[[NSURL alloc] initFileURLWithPath:attempt] autorelease];
        if (CFURLGetFSRef((CFURLRef)url, &ref))
            break;
        attempt = [attempt stringByDeletingLastPathComponent];
    }

    FSCatalogInfo catalogInfo;
    err = FSGetCatalogInfo(&ref, kFSCatInfoVolume, &catalogInfo, NULL, NULL, NULL);
    if (err != noErr)
        [NSException raise:NSInvalidArgumentException format:@"Unable to get catalog info for '%@'", path];

    FSRef temporaryItemsRef;
    err = FSFindFolder(catalogInfo.volume, kTemporaryFolderType, kCreateFolder, &temporaryItemsRef);
    if (err != noErr)
        [NSException raise:NSInvalidArgumentException format:@"Unable to find temporary items directory for '%@'", path];

    CFURLRef temporaryItemsURL;
    temporaryItemsURL = CFURLCreateFromFSRef(kCFAllocatorDefault, &temporaryItemsRef);
    if (!temporaryItemsURL)
        [NSException raise:NSInvalidArgumentException format:@"Unable to create URL to temporary items directory for '%@'", path];

    NSString *temporaryItemsPath = [[[(NSURL *)temporaryItemsURL path] copy] autorelease];
    [(id)temporaryItemsURL release];

    return temporaryItemsPath;
}

// Create a unique temp filename from a template filename, given a range within the template filename which identifies where the unique portion of the filename is to lie.

- (NSString *)tempFilenameFromTemplate:(NSString *)inputString andRange:(NSRange)replaceRange;
{
    NSMutableString *tempFilename = nil;
    NSString *result;
    unsigned int tempFilenameNumber = 1;

    [tempFilenameLock lock];
    NS_DURING {
        do {
            [tempFilename release];
            tempFilename = [inputString mutableCopy];
            [tempFilename replaceCharactersInRange:replaceRange withString:[NSString stringWithFormat:@"%d", tempFilenameNumber++]];
        } while ([self fileExistsAtPath:tempFilename]);
    } NS_HANDLER {
        [tempFilenameLock unlock];
        [tempFilename release];
        [localException raise];
    } NS_ENDHANDLER;
    [tempFilenameLock unlock];

    result = [[tempFilename copy] autorelease]; // Make a nice immutable string
    [tempFilename release];
    return result;
}

// Create a unique temp filename from a template string, given a position within the template filename which identifies where the unique portion of the filename is to begin.

- (NSString *)tempFilenameFromTemplate:(NSString *)inputString
    andPosition:(int)position;
{
    NSRange replaceRange;

    replaceRange.location = position;
    replaceRange.length = 6;
    return [self tempFilenameFromTemplate:inputString andRange:replaceRange];
}

// Create a unique temp filename from a template string, given a substring within the template filename which is to be replaced by the unique portion of the filename.

- (NSString *)tempFilenameFromTemplate:(NSString *)inputString andSubstring:(NSString *)substring;
{
    NSRange replaceRange;

    replaceRange = [inputString rangeOfString:substring];
    return [self tempFilenameFromTemplate:inputString andRange:replaceRange];
}

// Create a unique temp filename from a template string which contains a substring of six hash marks which are to be replaced by the unique portion of the filename.

- (NSString *)tempFilenameFromHashesTemplate:(NSString *)inputString;
{
    return [self tempFilenameFromTemplate:inputString andSubstring:@"######"];
}

// Generate a unique filename based on a suggested name

// [WIML]: This function is kinda bogus and could represent a security problem. If we're opening+creating the file anyway (which some callers of this function depend on) we should return the opened fd instead of forcing the caller to re-open the file. We shouldn't create the file world-read, in case it's destined to hold sensitive info (there will be a window of opportunity before the file's permissions are reset). We're inefficiently testing for existence twice, once with lstat() and once with O_CREAT|O_EXCL. We should check into the algorithm used by e.g. mkstemp() or other secure scratch file functions and duplicate it.
#warning uniqueFilenameFromName: needs fixing
- (NSString *)uniqueFilenameFromName:(NSString *)filename;
{
    return [self  uniqueFilenameFromName:filename allowOriginal:YES create:YES];
}

// If 'create' is NO, the returned path will not exist.  This could allow another thread/process to steal the filename.
- (NSString *)uniqueFilenameFromName:(NSString *)filename allowOriginal:(BOOL)allowOriginal create:(BOOL)create;
{
    NSString *directory;
    NSString *name;
    NSString *nameWithHashes;
    int testFD;
    NSRange periodRange;
    int tries = 0;

    NSString *originalFilename = filename;
    do {
        const char *fsRep = NULL;
        int errorNumber;
        
        if (!allowOriginal && [filename isEqualToString:originalFilename]) {
            // Fake a 'this file exists' condition
            testFD = -1;
            errorNumber = EEXIST;
        } else {
            fsRep = [self fileSystemRepresentationWithPath:filename];
            testFD = open(fsRep, O_EXCL | O_WRONLY | O_CREAT | O_TRUNC, 0666);
            errorNumber = errno;
        }
        
        if (testFD != -1) {
            close(testFD);
            if (!create)
                unlink(fsRep);
            return filename;
        }
        if (errorNumber != EEXIST)
            return nil;
        directory = [filename stringByDeletingLastPathComponent];
        name = [filename lastPathComponent];
        periodRange = [name rangeOfString:@"."];
        if (periodRange.length != 0) {
            nameWithHashes = [NSString stringWithFormat:@"%@-######.%@", [name substringToIndex:periodRange.location], [name substringFromIndex:periodRange.location + 1]];
        } else {
            nameWithHashes = [NSString stringWithFormat:@"%@-######", name];
        }

        filename = [self tempFilenameFromHashesTemplate:[directory stringByAppendingPathComponent:nameWithHashes]];
    } while (++tries < 10);

    return nil;
}

- (NSString *)scratchDirectoryPath;
{
    NSUserDefaults *defaults;
    NSString *defaultsScratchDirectoryPath;
    NSString *workingScratchDirectoryPath;
    NSMutableDictionary *attributes;

    [scratchDirectoryLock lock];

    if (scratchDirectoryPath) {
        if ([self fileExistsAtPath:scratchDirectoryPath] /* TODO: isDir? */ ) {
            [scratchDirectoryLock unlock];
            return scratchDirectoryPath;
        } else {
            [scratchDirectoryPath release];
            scratchDirectoryPath = nil;
        }
    }

    defaults = [NSUserDefaults standardUserDefaults];

    defaultsScratchDirectoryPath = [defaults stringForKey:@"OFScratchDirectory"];
    if ([defaultsScratchDirectoryPath isEqualToString:@"NSTemporaryDirectory"]) {
        defaultsScratchDirectoryPath = NSTemporaryDirectory();
    } else {
        defaultsScratchDirectoryPath = [defaultsScratchDirectoryPath stringByExpandingTildeInPath];
    }
    [self createDirectoryAtPath:defaultsScratchDirectoryPath attributes:nil];
    attributes = [[NSMutableDictionary alloc] initWithCapacity:1];
    [attributes setObject:[NSNumber numberWithInt:0777] forKey:NSFilePosixPermissions];
    [self changeFileAttributes:attributes atPath:defaultsScratchDirectoryPath];
    [attributes release];

    workingScratchDirectoryPath = [defaultsScratchDirectoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@-%@-######", [[NSProcessInfo processInfo] processName], NSUserName()]];
    workingScratchDirectoryPath = [self tempFilenameFromHashesTemplate:workingScratchDirectoryPath];
    [workingScratchDirectoryPath retain];

    [self createDirectoryAtPath:workingScratchDirectoryPath attributes:nil];
    attributes = [[NSMutableDictionary alloc] initWithCapacity:1];
    [attributes setObject:[NSNumber numberWithInt:0700] forKey:NSFilePosixPermissions];
    [self changeFileAttributes:attributes atPath:defaultsScratchDirectoryPath];
    [attributes release];
    scratchDirectoryPath = workingScratchDirectoryPath;

    [scratchDirectoryLock unlock];
    return scratchDirectoryPath;
}

- (NSString *)scratchFilenameNamed:(NSString *)aName;
{
    if (!aName || [aName length] == 0)
	aName = @"scratch";
    return [self uniqueFilenameFromName:[[self scratchDirectoryPath] stringByAppendingPathComponent:aName]];
}

- (void)removeScratchDirectory;
{
    if (!scratchDirectoryPath)
	return;
    [self removeFileAtPath:scratchDirectoryPath handler:nil];
    [scratchDirectoryPath release];
    scratchDirectoryPath = nil;
}

- (void)touchFile:(NSString *)filePath;
{
    NSMutableDictionary *attributes;

    attributes = [[NSMutableDictionary alloc] initWithCapacity:1];
    [attributes setObject:[NSDate date] forKey:NSFileModificationDate];
    [self changeFileAttributes:attributes atPath:filePath];
    [attributes release];
}


- (BOOL)directoryExistsAtPath:(NSString *)path traverseLink:(BOOL)traverseLink;
{
    NSDictionary *attributes;

    attributes = [self fileAttributesAtPath:path traverseLink:traverseLink];
    return [[attributes objectForKey:NSFileType] isEqualToString:NSFileTypeDirectory];
}

- (BOOL)directoryExistsAtPath:(NSString *)path;
{
    return [self directoryExistsAtPath:path traverseLink:NO];
}

- (void)createPathToFile:(NSString *)path attributes:(NSDictionary *)attributes;
    // Creates any directories needed to be able to create a file at the specified path.  Raises an exception on failure.
{
    NSArray *pathComponents;
    unsigned int dirCount;
    NSString *finalDirectory;

    pathComponents = [path pathComponents];
    dirCount = [pathComponents count] - 1;
    // Short-circuit if the final directory already exists
    finalDirectory = [NSString pathWithComponents:[pathComponents subarrayWithRange:NSMakeRange(0, dirCount)]];
    [self createPath:finalDirectory attributes:attributes];
}

- (void)createPath:(NSString *)path attributes:(NSDictionary *)attributes;
    // Creates any directories needed to be able to create a file at the specified path.  Raises an exception on failure.
{
    NSArray *pathComponents;
    unsigned int dirIndex, dirCount;
    unsigned int startingIndex;

    pathComponents = [path pathComponents];
    dirCount = [pathComponents count];
    // Short-circuit if the final directory already exists
    path = [NSString pathWithComponents:[pathComponents subarrayWithRange:NSMakeRange(0, dirCount)]];

    if ([self directoryExistsAtPath:path traverseLink:YES])
        return;

    startingIndex = 0;
    
    for (dirIndex = startingIndex; dirIndex < dirCount; dirIndex++) {
        NSString *partialPath;
        BOOL fileExists;

        partialPath = [NSString pathWithComponents:[pathComponents subarrayWithRange:NSMakeRange(0, dirIndex + 1)]];

        // Don't use the 'fileExistsAtPath:isDirectory:' version since it doesn't traverse symlinks
        fileExists = [self fileExistsAtPath:partialPath];
        if (!fileExists) {
            if (![self createDirectoryAtPath:partialPath attributes:attributes]) {
                [NSException raise:NSGenericException format:@"Unable to create a directory at path: %@", partialPath];
            }
        } else {
            NSDictionary *attributes;

            attributes = [self fileAttributesAtPath:partialPath traverseLink:YES];
            if (![[attributes objectForKey:NSFileType] isEqualToString: NSFileTypeDirectory]) {
                [NSException raise:NSGenericException format:@"Unable to write to path \"%@\" because \"%@\" is not a directory",
                    path, partialPath];
            }
        }
    }
}

- (NSString *)existingPortionOfPath:(NSString *)path;
{
    NSArray *pathComponents;
    unsigned int goodComponentsCount, componentCount;
    unsigned int startingIndex;

    pathComponents = [path pathComponents];
    componentCount = [pathComponents count];
    startingIndex  = 0;
    
    for (goodComponentsCount = startingIndex; goodComponentsCount < componentCount; goodComponentsCount++) {
        NSString *testPath;

        testPath = [NSString pathWithComponents:[pathComponents subarrayWithRange:NSMakeRange(0, goodComponentsCount + 1)]];
        if (goodComponentsCount < componentCount - 1) {
            // For the leading components, test to see if a directory exists at that path
            if (![self directoryExistsAtPath:testPath traverseLink:YES])
                break;
        } else {
            // For the final component, test to see if any sort of file exists at that path
            if (![self fileExistsAtPath:testPath])
                break;
        }
    }
    if (goodComponentsCount == 0) {
        return @"";
    } else if (goodComponentsCount == componentCount) {
        return path;
    } else if (goodComponentsCount == 1) {
        // Returns @"/" on UNIX, and (hopefully) @"C:\" on Windows
        return [pathComponents objectAtIndex:0];
    } else {
        // Append a trailing slash to the existing directory
        return [[NSString pathWithComponents:[pathComponents subarrayWithRange:NSMakeRange(0, goodComponentsCount)]] stringByAppendingString:@"/"];
    }
}

// The NSData method -writeToFile:atomically: doesn't take an attribute dictionary.
// This means that you could write the file w/o setting the attributes, which might
// be a security hole if the file gets left in the default attribute state.  This method
// gets the attributes right on the first pass and then gets the name right, potentially
// leaving turds in the filesystem.
- (BOOL)atomicallyCreateFileAtPath:(NSString *)path contents:(NSData *)data attributes:(NSDictionary *)attr;
{
    NSString *tmpPath;
    int rc;
    
    // Create a temporary file in the same directory
    tmpPath = [self tempFilenameFromHashesTemplate: [NSString stringWithFormat: @"%@-tmp-######", path]];
    
    if (![self createFileAtPath: tmpPath contents: data attributes: attr])
        return NO;
        
    // -movePath:toPath:handler: is documented to copy the original file rather than renaming it.
    // It is also documented to fail if the destination exists.  So, we will use our trusty Unix
    // APIs.
    rc = rename([tmpPath UTF8String], [path UTF8String]);
    return rc == 0;
}

- (NSArray *) directoryContentsAtPath: (NSString *) path havingExtension: (NSString *) extension;
{
    NSArray *children;
    unsigned int childIndex, childCount;
    NSMutableArray *filteredChildren;
    
    if (!(children = [self directoryContentsAtPath: path])) {
        // Return nil in exactly the cases that -directoryContentsAtPath: does (rather than returning and empty array).
        return nil;
    }
    
    childCount = [children count];
    filteredChildren = [NSMutableArray arrayWithCapacity: childCount];
    
    for (childIndex = 0; childIndex < childCount; childIndex++) {
        NSString *child;
        
        child = [children objectAtIndex: childIndex];
        if ([[child pathExtension] isEqualToString: extension])
            [filteredChildren addObject: child];
    }
    
    return filteredChildren;
}

// File locking

- (NSDictionary *)lockFileAtPath:(NSString *)path overridingExistingLock:(BOOL)override;
{
    NSString *lockFilePath;
    NSMutableDictionary *lockDictionary;
    id value;
    
    lockFilePath = [self lockFilePathForPath:path];
    if (override == NO && [self fileExistsAtPath:lockFilePath]) {
        // Someone else already has the lock. Report the owner.
        NSDictionary *dict;
        
        dict = [NSDictionary dictionaryWithContentsOfFile:lockFilePath];
        if (!dict) {
            // Couldn't parse the lock file for some reason.
            dict = [NSDictionary dictionary];
        } else {
            // If we're on the same host, we can check if the locking process is gone. In that case, we can safely override the lock.
            if ([OFUniqueMachineIdentifier() isEqualToString:[dict objectForKey:@"hostIdentifier"]] || [OFHostName() isEqualToString:[dict objectForKey:@"hostName"]]) {
                int processNumber;
            
                processNumber = [[dict objectForKey:@"processNumber"] intValue];
                if (processNumber > 0) {
                    if (kill(processNumber, 0) == -1 && OMNI_ERRNO() == ESRCH) {
                        dict = nil;  // And go on to override
                    }
                }
            }
        }
        
        if (dict)
            return dict;
    }

    lockDictionary = [NSMutableDictionary dictionaryWithCapacity:4];
    if ((value = OFUniqueMachineIdentifier()))
        [lockDictionary setObject:value forKey:@"hostIdentifier"];
    if ((value = OFHostName()))
        [lockDictionary setObject:value forKey:@"hostName"];
    if ((value = NSUserName()))
        [lockDictionary setObject:value forKey:@"userName"];
    if ((value = [[NSProcessInfo processInfo] processNumber]))
        [lockDictionary setObject:value forKey:@"processNumber"];

    [self createPathToFile:lockFilePath attributes:nil];
    if ([lockDictionary writeToFile:lockFilePath atomically:YES] == NO) {
        // We failed to write the lock for some reason.
        [NSException raise:NSGenericException format:@"Error locking file at %@: %s", path, [NSString stringWithCString:strerror(OMNI_ERRNO())]];
    }

    // Success!
    return nil;
}


- (void)unlockFileAtPath:(NSString *)path;
{
    NSString *lockFilePath;
    NSDictionary *lockDictionary;
    
    lockFilePath = [self lockFilePathForPath:path];
    if ([self fileExistsAtPath:lockFilePath] == NO) {
        [NSException raise:NSInternalInconsistencyException format:@"Error unlocking file at %@: lock file %@ does not exist", path, lockFilePath];
    }

    lockDictionary = [NSDictionary dictionaryWithContentsOfFile:lockFilePath];
    if (!lockDictionary) {
        [NSException raise:NSInternalInconsistencyException format:@"Error unlocking file at %@: couldn't read lock file %@", path, lockFilePath];
    }

    if (! ([[lockDictionary objectForKey:@"hostName"] isEqualToString:OFHostName()] && [[lockDictionary objectForKey:@"userName"] isEqualToString:NSUserName()] && [[lockDictionary objectForKey:@"processNumber"] intValue] == [[[NSProcessInfo processInfo] processNumber] intValue])) {
        [NSException raise:NSInternalInconsistencyException format:@"Error unlocking file at %@: lock file doesn't match current process", path];
    }

    if ([self removeFileAtPath:lockFilePath handler:nil] == NO) {
        [NSException raise:NSGenericException format:@"Error unlocking file at %@: lock file couldn't be removed", path];
    }
}

- (void)replaceFileAtPath:(NSString *)originalFile withFileAtPath:(NSString *)newFile handler:(id)handler;
/*" Replaces the orginal file with the new file, possibly using underlying filesystem features to do so atomically.  Raises if the operation fails. "*/
{
    NSURL *originalURL = [[[NSURL alloc] initFileURLWithPath:originalFile] autorelease];
    NSURL *newURL = [[[NSURL alloc] initFileURLWithPath:newFile] autorelease];

    // Try FSExchangeObjects.  Under 10.2 this will only work if both files are on the same filesystem and both are files (not folders).  We could check for these conditions up front, but they might fix/extend FSExchangeObjects, so we'll just try it.
    FSRef originalRef, newRef;
    if (!CFURLGetFSRef((CFURLRef)originalURL, &originalRef))
        [NSException raise:NSInvalidArgumentException format:@"Unable to get file reference for '%@'", originalFile];
    if (!CFURLGetFSRef((CFURLRef)newURL, &newRef))
        [NSException raise:NSInvalidArgumentException format:@"Unable to get file reference for '%@'", newFile];

    OSErr err = FSExchangeObjects(&originalRef, &newRef);
    if (err == noErr) {
        // Delete the original file which is now at the new file path.
        if (![self removeFileAtPath:newFile handler:handler]) {
            // We assume that failing to remove the temporary file is not a fatal error and don't raise.
            NSLog(@"Unable to remove '%@'", newFile);
        }
        return;
    }

    // Do a file renaming dance instead.
    {
        // Move the new file to the same directory as the original file.  If the files are on different filesystems, this may involve copying.  We do this before renaming the original to ensure that the destination filesystem has enough room for the new file.
        originalFile = [originalFile stringByStandardizingPath];
        NSString *originalDir = [originalFile stringByDeletingLastPathComponent];
        NSString *temporaryPath = [self uniqueFilenameFromName:[originalDir stringByAppendingPathComponent:[newFile lastPathComponent]] allowOriginal:NO create:NO];
        
        if (![self movePath:newFile toPath:temporaryPath handler:handler])
            [NSException raise:NSInvalidArgumentException format:@"Unable to move '%@' to '%@'", newFile, temporaryPath];
        
        // Move the original file aside (in the same directory)
        NSString *originalAside = [self uniqueFilenameFromName:originalFile allowOriginal:NO create:NO];
        if (![self movePath:originalFile toPath:originalAside handler:handler])
            [NSException raise:NSInvalidArgumentException format:@"Unable to move '%@' to '%@'", originalFile, originalAside];

        // Move the temp to the original
        if (![self movePath:temporaryPath toPath:originalFile handler:handler]) {
            // Move the original back, hopefully.  This still leaves the temporary file in the original's directory.  Don't really want to move it back (might be across filesystems and might be big).  Maybe we should delete it?
            [self movePath:originalAside toPath:originalFile handler:handler];
            [NSException raise:NSInvalidArgumentException format:@"Unable to move '%@' to '%@'", temporaryPath, originalFile];
        }

        // Finally, delete the old original (which has successfully been replaced)
        if (![self removeFileAtPath:originalAside handler:handler]) {
            // We assume failure isn't fatal
            NSLog(@"Unable to remove '%@'", originalAside);
        }
    }
}

//

- (NSNumber *)posixPermissionsForMode:(unsigned int)mode;
{
    return [NSNumber numberWithUnsignedLong:mode & (~permissionsMask)];
}

- (NSNumber *)defaultFilePermissions;
{
    return [self posixPermissionsForMode:0666];
}

- (NSNumber *)defaultDirectoryPermissions;
{
    return [self posixPermissionsForMode:0777];
}

- (unsigned long long)sizeOfFileAtPath:(NSString *)path;
{
    NSDictionary *attributes;

    attributes = [self fileSystemAttributesAtPath: path];
    if (!attributes)
        [NSException raise: NSInvalidArgumentException
                    format: @"Cannot get attributes for file at path '%@'", path];

    return [attributes fileSize];
}

//

- (NSString *)networkMountPointForPath:(NSString *)path returnMountSource:(NSString **)mountSource;
{
    struct statfs stats;

    if ([self filesystemStats:&stats forPath:path] == -1)
        return nil;

    if (strcmp(stats.f_fstypename, "nfs") != 0)
        return nil;

    if (mountSource)
        *mountSource = [self stringWithFileSystemRepresentation:stats.f_mntfromname length:strlen(stats.f_mntfromname)];
    
    return [self stringWithFileSystemRepresentation:stats.f_mntonname length:strlen(stats.f_mntonname)];
}

- (NSString *)fileSystemTypeForPath:(NSString *)path;
{
    struct statfs stats;

    if ([[NSFileManager defaultManager] filesystemStats:&stats forPath:path] == -1)
        return nil; // Apparently the file doesn't exist
    return [NSString stringWithCString:stats.f_fstypename];
}

typedef struct {
     long type;
     long creator;
     short flags;
     short locationV;
     short locationH;
     short fldr;
     short iconID;
     short unused[3];
     char script;
     char xFlags;
     short comment;
     long putAway;
} OFFinderInfo;

- (int)getType:(unsigned long *)typeCode andCreator:(unsigned long *)creatorCode forPath:(NSString *)path;
{
    struct attrlist attributeList;
    struct {
        long ssize;
        OFFinderInfo finderInfo;
    } attributeBuffer;
    int errorCode;

    attributeList.bitmapcount = ATTR_BIT_MAP_COUNT;
    attributeList.reserved = 0;
    attributeList.commonattr = ATTR_CMN_FNDRINFO;
    attributeList.volattr = attributeList.dirattr = attributeList.fileattr = attributeList.forkattr = 0;
    memset(&attributeBuffer, 0, sizeof(attributeBuffer));

    errorCode = getattrlist([self fileSystemRepresentationWithPath:path], &attributeList, &attributeBuffer, sizeof(attributeBuffer), 0);
    if (errorCode == -1) {
        switch (errno) {
            case EOPNOTSUPP: {
                BOOL isDirectory;
                NSString *ufsResourceForkPath;
                unsigned long aTypeCode, aCreatorCode;
                
                ufsResourceForkPath = [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:[@"._" stringByAppendingString:[path lastPathComponent]]];
                if ([self fileExistsAtPath:ufsResourceForkPath isDirectory:&isDirectory] == YES && isDirectory == NO) {
                    NSData *resourceFork;
                    const unsigned int offsetOfTypeInResourceFork = 50;
                    
                    resourceFork = [NSData dataWithContentsOfMappedFile:ufsResourceForkPath];
                    if ([resourceFork length] < offsetOfTypeInResourceFork + sizeof(unsigned long) + sizeof(unsigned long))
                        return errorCode;
                    
                    [resourceFork getBytes:&aTypeCode range:NSMakeRange(offsetOfTypeInResourceFork, sizeof(aTypeCode))];
                    [resourceFork getBytes:&aCreatorCode range:NSMakeRange(offsetOfTypeInResourceFork + sizeof(aTypeCode), sizeof(aCreatorCode))];
                    *typeCode = NSSwapBigLongToHost(aTypeCode);
                    *creatorCode = NSSwapBigLongToHost(aCreatorCode);
                    return 0;
                } else {
                    *typeCode = 0; // We could use the Mac APIs, or just read the "._" file.
                    *creatorCode = 0;
                }
            }
            default:
                return errorCode;
        }
    } else {
        *typeCode = attributeBuffer.finderInfo.type;
        *creatorCode = attributeBuffer.finderInfo.creator;
    }

    return errorCode;
}

- (int)setType:(unsigned long)typeCode andCreator:(unsigned long)creatorCode forPath:(NSString *)path;
{
     struct attrlist attributeList;
     struct {
         long ssize;
         OFFinderInfo finderInfo;
     } attributeBuffer;
     int errorCode;

     attributeList.bitmapcount = ATTR_BIT_MAP_COUNT;
     attributeList.reserved = 0;
     attributeList.commonattr = ATTR_CMN_FNDRINFO;
     attributeList.volattr = attributeList.dirattr = attributeList.fileattr = attributeList.forkattr = 0;
     memset(&attributeBuffer, 0, sizeof(attributeBuffer));

     getattrlist([self fileSystemRepresentationWithPath:path], &attributeList, &attributeBuffer, sizeof(attributeBuffer), 0);

     attributeBuffer.finderInfo.type = typeCode;
     attributeBuffer.finderInfo.creator = creatorCode;

     errorCode = setattrlist([self fileSystemRepresentationWithPath:path], &attributeList, &attributeBuffer.finderInfo, sizeof(OFFinderInfo), 0);
     if (errorCode == 0)
         return 0;

     if (errno == EOPNOTSUPP) {
#define MAGIC_HFS_FILE_LENGTH 82
         unsigned char magicHFSFileContents[MAGIC_HFS_FILE_LENGTH] = {
             0x00, 0x05, 0x16, 0x07, 0x00, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
             0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x09, 0x00, 0x00,
             0x00, 0x32, 0x00, 0x00, 0x00, 0x20, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x52, 0x00, 0x00,
             0x00, 0x00, 't', 'y', 'p', 'e', 'c', 'r', 'e', 'a', 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
             0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
             0x00, 0x00};
         unsigned int offsetWhereOSTypesAreStored = 50;
         NSData *data;
         NSString *magicHFSFilePath;

         *((int *)(&magicHFSFileContents[offsetWhereOSTypesAreStored])) = typeCode;
         *((int *)(&magicHFSFileContents[offsetWhereOSTypesAreStored + 4])) = creatorCode;
         data = [NSData dataWithBytes:magicHFSFileContents length:MAGIC_HFS_FILE_LENGTH];
         magicHFSFilePath = [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:[@"._" stringByAppendingString:[path lastPathComponent]]];

         if ([self createFileAtPath:magicHFSFilePath contents:data attributes:[self fileAttributesAtPath:path traverseLink:NO]])
             return 0;
         else
             return errorCode;
     }
     return errorCode;
}

- (NSString *)resolveAliasAtPath:(NSString *)path
{
    FSRef ref;
    OSErr err;
    char *buffer;
    UInt32 bufferSize;
    Boolean isFolder, wasAliased;

    if ([NSString isEmptyString:path])
        return nil;
    
    err = FSPathMakeRef((const unsigned char *)[path fileSystemRepresentation], &ref, NULL);
    if (err != noErr)
        return nil;

    err = FSResolveAliasFile(&ref, TRUE, &isFolder, &wasAliased);
    /* if it's a regular file and not an alias, FSResolveAliasFile() will return noErr and set wasAliased to false */
    if (err != noErr)
        return nil;
    if (!wasAliased)
        return path;

    buffer = malloc(bufferSize = (PATH_MAX * 4));
    err = FSRefMakePath(&ref, (unsigned char *)buffer, bufferSize);
    if (err == noErr) {
        path = [NSString stringWithUTF8String:buffer];
    } else {
        path = nil;
    }
    free(buffer);

    return path;
}

- (NSString *)resolveAliasesInPath:(NSString *)originalPath
{
    FSRef ref, originalRefOfPath;
    OSErr err;
    char *buffer;
    UInt32 bufferSize;
    Boolean isFolder, wasAliased;
    NSMutableArray *strippedComponents;
    NSString *path;

    if ([NSString isEmptyString:originalPath])
        return nil;
    
    path = [originalPath stringByStandardizingPath]; // maybe use stringByExpandingTildeInPath instead?
    strippedComponents = [[NSMutableArray alloc] init];
    [strippedComponents autorelease];

    /* First convert the path into an FSRef. If necessary, strip components from the end of the pathname until we reach a resolvable path. */
    for(;;) {
        bzero(&ref, sizeof(ref));
        err = FSPathMakeRef((const unsigned char *)[path fileSystemRepresentation], &ref, &isFolder);
        if (err == noErr)
            break;  // We've resolved the first portion of the path to an FSRef.
        else if (err == fnfErr || err == nsvErr || err == dirNFErr) {  // Not found --- try walking up the tree.
            NSString *stripped;

            stripped = [path lastPathComponent];
            if ([NSString isEmptyString:stripped])
                return nil;

            [strippedComponents addObject:stripped];
            path = [path stringByDeletingLastPathComponent];
        } else
            return nil;  // Some other error; return nil.
    }
    /* Stash a copy of the FSRef we got from 'path'. In the common case, we'll be converting this very same FSRef back into a path, in which case we can just re-use the original path. */
    bcopy(&ref, &originalRefOfPath, sizeof(FSRef));

    /* Repeatedly resolve aliases and add stripped path components until done. */
    for(;;) {
        
        /* Resolve any aliases. */
        /* TODO: Verify that we don't need to repeatedly call FSResolveAliasFile(). We're passing TRUE for resolveAliasChains, which suggests that the call will continue resolving aliases until it reaches a non-alias, but that parameter's meaning is not actually documented in the Apple File Manager API docs. However, I can't seem to get the finder to *create* an alias to an alias in the first place, so this probably isn't much of a problem.
        (Why not simply call FSResolveAliasFile() repeatedly since I don't know if it's necessary? Because it can be a fairly time-consuming call if the volume is e.g. a remote WebDAVFS volume.) */
        err = FSResolveAliasFile(&ref, TRUE, &isFolder, &wasAliased);
        /* if it's a regular file and not an alias, FSResolveAliasFile() will return noErr and set wasAliased to false */
        if (err != noErr)
            return nil;

        /* Append one stripped path component. */
        if ([strippedComponents count] > 0) {
            UniChar *componentName;
            UniCharCount componentNameLength;
            NSString *nextComponent;
            FSRef newRef;
            
            if (!isFolder) {
                // Whoa --- we've arrived at a non-folder. Can't continue.
                // (A volume root is considered a folder, as you'd expect.)
                return nil;
            }
            
            nextComponent = [strippedComponents lastObject];
            componentNameLength = [nextComponent length];
            componentName = malloc(componentNameLength * sizeof(UniChar));
            OBASSERT(sizeof(UniChar) == sizeof(unichar));
            [nextComponent getCharacters:componentName];
            bzero(&newRef, sizeof(newRef));
            err = FSMakeFSRefUnicode(&ref, componentNameLength, componentName, kTextEncodingUnknown, &newRef);
            free(componentName);

            if (err == fnfErr) {
                /* The current ref is a directory, but it doesn't contain anything with the name of the next component. Quit walking the filesystem and append the unresolved components to the name of the directory. */
                break;
            } else if (err != noErr) {
                /* Some other error. Give up. */
                return nil;
            }

            bcopy(&newRef, &ref, sizeof(ref));
            [strippedComponents removeLastObject];
        } else {
            /* If we don't have any path components to re-resolve, we're done. */
            break;
        }
    }

    if (FSCompareFSRefs(&originalRefOfPath, &ref) != noErr) {
        /* Convert our FSRef back into a path. */
        /* PATH_MAX*4 is a generous guess as to the largest path we can expect. CoreFoundation appears to just use PATH_MAX, so I'm pretty confident this is big enough. */
        buffer = malloc(bufferSize = (PATH_MAX * 4));
        err = FSRefMakePath(&ref, (unsigned char *)buffer, bufferSize);
        if (err == noErr) {
            path = [NSString stringWithUTF8String:buffer];
        } else {
            path = nil;
        }
        free(buffer);
    }

    /* Append any unresolvable path components to the resolved directory. */
    while ([strippedComponents count] > 0) {
        path = [path stringByAppendingPathComponent:[strippedComponents lastObject]];
        [strippedComponents removeLastObject];
    }

    return path;
}

- (BOOL)fileIsStationeryPad:(NSString *)filename;
{
    const char *posixPath;
    FSRef myFSRef;
    FSCatalogInfo catalogInfo;
    
    posixPath = [filename fileSystemRepresentation];
    if (posixPath == NULL)
        return NO; // Protect FSPathMakeRef() from crashing
    if (FSPathMakeRef((UInt8 *)posixPath, &myFSRef, NULL))
        return NO;
    if (FSGetCatalogInfo(&myFSRef, kFSCatInfoFinderInfo, &catalogInfo, NULL, NULL, NULL) != noErr)
        return NO;
    return (((FileInfo *)(&catalogInfo.finderInfo))->finderFlags & kIsStationery) != 0;
}

- (BOOL)path:(NSString *)otherPath isAncestorOfPath:(NSString *)thisPath relativePath:(NSString **)relativeResult
{
    NSArray *commonComponents, *myContinuation, *parentContinuation;
    
    myContinuation = nil;
    parentContinuation = nil;
    commonComponents = OFCommonRootPathComponents(thisPath, otherPath, &myContinuation, &parentContinuation);
    
    if (commonComponents != nil && [parentContinuation count] == 0) {
        if (relativeResult)
            *relativeResult = [NSString pathWithComponents:myContinuation];
        return YES;
    }
        
    NSString *lastParentComponent = [otherPath lastPathComponent];
    NSDictionary *lastParentComponentStat = nil;
    NSArray *myComponents = [thisPath pathComponents];
    unsigned componentIndex, componentCount = [myComponents count];
    
    componentIndex = componentCount;
    while(componentIndex--) {
        if ([lastParentComponent caseInsensitiveCompare:[myComponents objectAtIndex:componentIndex]] == NSOrderedSame) {
            if (lastParentComponentStat == nil) {
                lastParentComponentStat = [self fileAttributesAtPath:otherPath traverseLink:YES];
                if (!lastParentComponentStat) {
                    // Can't stat the putative parent --- so there's no way we're a subdirectory of it.
                    return NO;
                }
            }
            
            NSString *thisPartialPath = [NSString pathWithComponents:[myComponents subarrayWithRange:(NSRange){0, componentIndex+1}]];
            NSDictionary *thisPartialPathStat = [self fileAttributesAtPath:thisPartialPath traverseLink:YES];
            // Compare the file stats. In particular, we're comparing the filesystem number and inode number: we're checking to see if they're the same file.
            if ([lastParentComponentStat isEqual:thisPartialPathStat]) {
                if (relativeResult) {
                    *relativeResult = (componentIndex == componentCount-1 && [[lastParentComponentStat fileType] isEqualToString:NSFileTypeDirectory]) ? @"." : [NSString pathWithComponents:[myComponents subarrayWithRange:(NSRange){componentIndex+1, componentCount-componentIndex-1}]]; 
                }
                return YES;
            }
        }
    }
    
    return NO;
}

@end

@implementation NSFileManager (OFPrivate)

- (int)filesystemStats:(struct statfs *)stats forPath:(NSString *)path;
{
    if ([[[self fileAttributesAtPath:path traverseLink:NO] fileType] isEqualToString:NSFileTypeSymbolicLink])
        // BUG: statfs() will return stats on the file we link to, not the link itself.  We want stats on the link itself, but there is no lstatfs().  As a mostly-correct hackaround, I get the stats on the link's parent directory. This will fail if you NFS-mount a link as the source from a remote machine -- it'll report that the link isn't network mounted, because its local parent dir isn't.  Hopefully, this isn't real common.
        return statfs([self fileSystemRepresentationWithPath:[path stringByDeletingLastPathComponent]], stats);
    else
        return statfs([self fileSystemRepresentationWithPath:path], stats);
}

- (NSString *)lockFilePathForPath:(NSString *)path;
{
    return [[path stringByStandardizingPath] stringByAppendingString:@".lock"];
    // This could be a problem if the resulting filename is too long for the filesystem. Alternatively, we could create a lock filename as a fixed-length hash of the real filename.
}

@end
