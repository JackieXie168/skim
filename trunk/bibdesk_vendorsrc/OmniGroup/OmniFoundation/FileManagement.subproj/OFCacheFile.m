// Copyright 2003-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OFCacheFile.h"

#import <Foundation/Foundation.h>
#import <OmniBase/rcsid.h>
#import <OmniBase/OmniBase.h>
#import <OmniFoundation/NSData-OFExtensions.h>
#import <OmniFoundation/NSFileManager-OFExtensions.h>
#import <OmniFoundation/NSString-OFExtensions.h>
#import <unistd.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/FileManagement.subproj/OFCacheFile.m 66170 2005-07-28 17:40:10Z kc $");


@implementation OFCacheFile

+ (OFCacheFile *)cacheFileNamed:(NSString *)aName;
{
    return [self cacheFileNamed:aName inDirectory:nil];
}

+ (OFCacheFile *)cacheFileNamed:(NSString *)aName inDirectory:(NSString *)cacheFileDirectory;
{
    OFCacheFile *cacheFile;

    OBPRECONDITION(![NSString isEmptyString:aName]);
    OBPRECONDITION(cacheFileDirectory == nil || [cacheFileDirectory isAbsolutePath]);

    if (![aName isAbsolutePath]) {
        if (cacheFileDirectory == nil)
            cacheFileDirectory = [self applicationCacheDirectory];

        aName = [cacheFileDirectory stringByAppendingPathComponent:aName];
    }

    [[NSFileManager defaultManager] createPathToFile:aName attributes:nil];

    // TODO: Unique instances of OFCacheFile.
    cacheFile = [[self alloc] initWithPath:aName];
    return [cacheFile autorelease];
}

+ (NSString *)userCacheDirectory;
    // e.g., ~/Library/Caches
{
    static NSString *userCacheDirectory = nil;

    if (userCacheDirectory == nil) {
        FSRef foundFolder;
        OSErr err;
        NSString *result = nil;
        
        err = FSFindFolder(kUserDomain, kCachedDataFolderType, TRUE, &foundFolder);
        if (err == noErr) {
            UInt32 pathSize = PATH_MAX * 2;  // generous max path len
            char *buf = alloca(pathSize);
    
            err = FSRefMakePath(&foundFolder, (unsigned char *)buf, pathSize);
            if (err == noErr) {
                result = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:buf length:strlen(buf)];
            }
        }
    
        // Fall back to mostly-hard-coded value.
        if (result == nil)
            result = [@"~/Library/Caches" stringByExpandingTildeInPath];
    
        userCacheDirectory = [result retain];
    }

    OBPOSTCONDITION(userCacheDirectory != nil);
    return userCacheDirectory;
}

+ (NSString *)applicationCacheDirectory;
    // e.g., ~/Library/Caches/com.omnigroup.OmniWeb
{
    // Get the (non-localized) name of the application.
    NSString *applicationIdentifier;

    applicationIdentifier = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleIdentifierKey];
    if (applicationIdentifier == nil)
        applicationIdentifier = [[NSProcessInfo processInfo] processName];

    return [[self userCacheDirectory] stringByAppendingPathComponent:applicationIdentifier];
}


// Init and dealloc

- initWithPath:(NSString *)myPath;
{
    if ([super init] == nil)
        return nil;

    filename = [myPath copy];
    contentData = nil;
    flags.contentDataIsValid = 0;
    flags.contentDataIsDirty = 0;

    return self;
}

- (void)dealloc;
{
    OBASSERT(!flags.contentDataIsDirty);

    [contentData release];
    [filename release];
    
    [super dealloc];
}


// API

- (NSString *)filename;
{
    return filename;
}

- (NSData *)contentData;
{
    if (!flags.contentDataIsValid) {
        OBASSERT(!flags.contentDataIsDirty);
        
        [contentData release];
        contentData = [[NSData alloc] initWithContentsOfMappedFile:filename];
        flags.contentDataIsValid = YES;
    }

    return contentData;
}

- (void)setContentData:(NSData *)newData;
{
    if (contentData == newData)
        return;
    
    if (contentData != nil && [contentData isEqual:newData])
        return;
        
    [contentData release];
    contentData = [newData retain];

    flags.contentDataIsValid = 1;
    flags.contentDataIsDirty = 1;
}

- (id)propertyList;
{
    return [[self contentData] propertyList];
}

- (void)setPropertyList:(id)newPlist;
{
    CFDataRef plistData;
    
    if (newPlist == nil) {
        [self setContentData:nil];
        return;
    }
    
    // TODO: Old-style or new-style plists? Old-style are more compact and more readable, but can't contain some types (e.g. dates) and can have problems with non-ASCII characters if not used properly. So for now we use the XML format.

    plistData = CFPropertyListCreateXMLData(kCFAllocatorDefault, newPlist);
    OBASSERT(plistData != NULL);
    [self setContentData:(NSData *)plistData];
    CFRelease(plistData);
}

- (void)writeIfNecessary;
{
    if (flags.contentDataIsDirty) {
        BOOL ok;

        if (contentData != nil) {
            ok = [contentData writeToFile:filename atomically:NO createDirectories:YES];
        } else {
            
            // contentData is nil --> delete the cache file.
            // use unlink() to avoid deleting a directory by accident.
            if (unlink([filename fileSystemRepresentation]) == 0) {
                ok = YES;
            } else {
                if (errno == ENOENT || errno == ENOTDIR)
                    ok = YES;
                else
                    ok = NO;
            }
        }

        if (ok) {
            flags.contentDataIsDirty = NO;
            flags.contentDataIsValid = YES;
        }
    }
}

@end

