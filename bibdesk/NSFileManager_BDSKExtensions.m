//
//  NSFileManager_BDSKExtensions.m
//  Bibdesk
//
//  Created by Adam Maxwell on 07/08/05.
//
/*
 This software is Copyright (c) 2005,2006
 Adam Maxwell. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 
 - Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 
 - Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in
 the documentation and/or other materials provided with the
 distribution.
 
 - Neither the name of Adam Maxwell nor the names of any
 contributors may be used to endorse or promote products derived
 from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "NSFileManager_BDSKExtensions.h"
#import "BibPrefController.h"
#import <OmniFoundation/OFResourceFork.h>

/* 
The WLDragMapHeaderStruct stuff was borrowed from CocoaTech Foundation, http://www.cocoatech.com (BSD licensed).  This is used for creating WebLoc files, which are a resource-only Finder clipping.  Apple provides no API for creating them, so apparently everyone just reverse-engineers the resource file format and creates them.  Since I have no desire to mess with ResEdit anymore, we're borrowing this code directly and using Omni's resource fork methods to create the file.  Note that you can check the contents of a resource fork in Terminal with `cat somefile/rsrc`, not that it's incredibly helpful. 
*/

#pragma options align=mac68k

typedef struct WLDragMapHeaderStruct
{
    long mapVersion;  // always 1
    long unused1;     // always 0
    long unused2;     // always 0
    short unused;
    short numEntries;   // number of repeating WLDragMapEntries
} WLDragMapHeaderStruct;

typedef struct WLDragMapEntryStruct
{
    OSType type;
    short unused;  // always 0
    ResID resID;   // always 128 or 256?
    long unused1;   // always 0
    long unused2;   // always 0
} WLDragMapEntryStruct;

#pragma options align=reset

@interface WLDragMapEntry : NSObject
{
    OSType _type;
    ResID _resID;
}

+ (id)entryWithType:(OSType)type resID:(int)resID;
+ (NSData*)dragDataWithEntries:(NSArray*)entries;

- (OSType)type;
- (ResID)resID;
- (NSData*)entryData;

@end


@interface OFResourceFork (BDSKExtensions)

// the setData:forResourceType: method apparently sets the wrong resID, so we use this method to override that
- (void)setData:(NSData *)contentData forResourceType:(ResType)resType resID:(short)resID;

@end


@implementation NSFileManager (BDSKExtensions)

- (NSString *)currentApplicationSupportPathForCurrentUser{
    
    static NSString *path = nil;
    
    if(path == nil){
        FSRef foundRef;
        OSStatus err = noErr;
        
        err = FSFindFolder(kUserDomain,  kApplicationSupportFolderType, kCreateFolder, &foundRef);
        if(err != noErr){
            NSLog(@"Error %d:  the system was unable to find your Application Support folder.", err);
            return nil;
        }
        
        CFURLRef url = CFURLCreateFromFSRef(kCFAllocatorDefault, &foundRef);
        
        if(url != nil){
            path = [(NSURL *)url path];
            CFRelease(url);
        }
        
        NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleExecutableKey];
        
        if(appName == nil)
            [NSException raise:NSObjectNotAvailableException format:NSLocalizedString(@"Unable to find CFBundleIdentifier for %@", @""), [NSApp description]];
        
        path = [[path stringByAppendingPathComponent:appName] copy];
        
        // the call to FSFindFolder creates the parent hierarchy, but not the directory we're looking for
        static BOOL dirExists = NO;
        if(dirExists == NO){
            BOOL pathIsDir;
            dirExists = [self fileExistsAtPath:path isDirectory:&pathIsDir];
            if(dirExists == NO || pathIsDir == NO)
                [self createDirectoryAtPath:path attributes:nil];
            // make sure it was created
            dirExists = [self fileExistsAtPath:path isDirectory:&pathIsDir];
            NSAssert1(dirExists && pathIsDir, @"Unable to create folder %@", path);
        }
    }
    
    return path;
}

- (NSString *)applicationSupportDirectory:(SInt16)domain{
    
    FSRef foundRef;
    OSStatus err = noErr;
    
    err = FSFindFolder(domain,
                       kApplicationSupportFolderType,
                       kCreateFolder,
                       &foundRef);
    NSAssert1( err == noErr, @"Error %d:  the system was unable to find your Application Support folder.", err);
    
    CFURLRef url = CFURLCreateFromFSRef(kCFAllocatorDefault, &foundRef);
    NSString *retStr = nil;
    
    if(url != nil){
        retStr = [(NSURL *)url path];
        CFRelease(url);
    }
    
    return retStr;
}

- (NSString *)uniqueFilePath:(NSString *)path createDirectory:(BOOL)create{
	NSString *basePath = [path stringByDeletingPathExtension];
    NSString *extension = [path pathExtension];
	int i = 0;
	
	if(![extension isEqualToString:@""])
		extension = [@"." stringByAppendingString:extension];
	
	while([self fileExistsAtPath:path])
		path = [NSString stringWithFormat:@"%@-%i%@", basePath, ++i, extension];
	
	if(create)
		[self createDirectoryAtPath:path attributes:nil];
	
	return path;
}

- (NSString *)spotlightCacheFolderPathByCreating:(NSError **)anError{

    NSString *cachePath = nil;
    
    @synchronized(self){
        NSString *basePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"Metadata"];
        NSAssert(basePath != nil, @"nil cache base path");
        
        volatile BOOL dirExists = YES;
        
        @try{
            if(![self fileExistsAtPath:basePath])
                dirExists = [self createDirectoryAtPath:basePath attributes:nil];
        }
        @catch(NSException *localException){
            NSLog(@"%@: caught %@: %@", NSStringFromSelector(_cmd), [localException name], [localException reason]);
        }
        
        if(!dirExists){
            if(anError != nil)
                *anError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteUnknownError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:basePath, NSFilePathErrorKey, NSLocalizedString(@"Unable to create the cache directory.", @""), NSLocalizedDescriptionKey, nil]];
            return nil;
        }
        
        cachePath = [basePath stringByAppendingPathComponent:[[NSBundle mainBundle] bundleIdentifier]];
        volatile BOOL mdExists = YES;
        
        @try{
            if(![self fileExistsAtPath:cachePath])
                mdExists = [self createDirectoryAtPath:cachePath attributes:nil];
        }
        @catch(NSException *localException){
            NSLog(@"%@: caught %@: %@", NSStringFromSelector(_cmd), [localException name], [localException reason]);
        }
        
        if(!mdExists){
            if(anError != nil)
                *anError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteUnknownError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:cachePath, NSFilePathErrorKey, NSLocalizedString(@"Unable to create the cache directory.", @""), NSLocalizedDescriptionKey, nil]];
            return nil;
        }
        
    }
    return cachePath;
}

- (BOOL)removeSpotlightCacheFolder{
    
    volatile BOOL removed;

    @synchronized(self){
        if(![self spotlightCacheFolderExists])
            return NO;
        
        NSError *error = nil;
        NSString *path = [self spotlightCacheFolderPathByCreating:&error];
        if(error != nil)
            return NO;
                
        @try{
            removed = [self removeFileAtPath:path handler:nil];
        }
        @catch(NSException *localException){
            removed = NO;
            NSLog(@"%@: caught %@: %@", NSStringFromSelector(_cmd), [localException name], [localException reason]);
        }
    }
    return removed;

}

- (BOOL)spotlightCacheFolderExists{
    
    volatile BOOL status;
    
    @synchronized(self){
        NSString *path = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"Metadata"];
        NSAssert(path != nil, @"nil caches path");
        path = [path stringByAppendingPathComponent:[[NSBundle mainBundle] bundleIdentifier]];
        status = [self fileExistsAtPath:path];
    }
    return status;
}

- (BOOL)removeSpotlightCacheForItemsNamed:(NSArray *)itemNames{
	NSEnumerator *nameEnum = [itemNames objectEnumerator];
	NSString *name;
	BOOL removed = YES;
	
	while (name = [nameEnum nextObject])
		removed = removed && [self removeSpotlightCacheForItemNamed:name];
	return removed;
}

- (BOOL)removeSpotlightCacheForItemNamed:(NSString *)itemName{

    volatile BOOL removed;
    
    @synchronized(self){
        NSString *fileName = [itemName stringByAppendingPathExtension:@"bdskcache"];
        NSError *error = nil;
        
        fileName = [[self spotlightCacheFolderPathByCreating:&error] stringByAppendingPathComponent:fileName];
        
        @try{
            removed = [self removeFileAtPath:fileName handler:nil];
        }
        @catch(NSException *localException){
            removed = NO;
            NSLog(@"%@: caught %@: %@", NSStringFromSelector(_cmd), [localException name], [localException reason]);
        }
        
    }
    return removed;

}

- (BOOL)createWeblocFileAtPath:(NSString *)fullPath withURL:(NSURL *)destURL;
{
    @synchronized(self){

        volatile BOOL success = YES;
        
        @try{
            // create an empty file, since weblocs are just a resource
            success = [self createFileAtPath:fullPath contents:nil attributes:nil];
        }
        @catch(NSException *localException){
            NSLog(@"%@: caught %@: %@", NSStringFromSelector(_cmd), [localException name], [localException reason]);
            success = NO;
        }
            
        // in case it failed without raising an exception...
        if(!success) return NO;
        
        OFResourceFork *resourceFork = [[OFResourceFork alloc] initWithContentsOfFile:fullPath forkType:OFResourceForkType createFork:YES];

        NSString *urlString = [destURL absoluteString];
        NSData *data = [NSData dataWithBytes:[urlString UTF8String] length:strlen([urlString UTF8String])];
        NSMutableArray *entries = [[NSMutableArray alloc] initWithCapacity:2];

        // write out the same data for text and url resources
        [resourceFork setData:data forResourceType:'TEXT' resID:256];
        [resourceFork setData:data forResourceType:'url ' resID:256];

        [entries addObject:[WLDragMapEntry entryWithType:'TEXT' resID:256]];
        [entries addObject:[WLDragMapEntry entryWithType:'url ' resID:256]];

        // add the drag map entry resources, since we get a corrupt file without them
        [resourceFork setData:[WLDragMapEntry dragDataWithEntries:entries] forResourceType:'drag' resID:128];
        [entries release];
        [resourceFork release];
        
    }
    return YES;
}

- (void)createWeblocFiles:(NSDictionary *)fullPathDict{
    
    @synchronized(self){
        
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        @try {    
            NSString *path;
            NSEnumerator *pathEnum = [fullPathDict keyEnumerator];
            
            while(path = [pathEnum nextObject])
                [self createWeblocFileAtPath:path withURL:[fullPathDict objectForKey:path]];
        }
        @catch(NSException *localException) {
            NSLog(@"%@: discarding %@: %@", NSStringFromSelector(_cmd), [localException name], [localException reason]);
        }
        
        @finally {
            [pool release];
        }
    }
}

- (void)copyFilesInPathDictionary:(NSDictionary *)fullPathDict{
    @synchronized(self){
        
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        @try {    
            NSString *originalPath;
            NSEnumerator *pathEnum = [fullPathDict keyEnumerator];
            
            while(originalPath = [pathEnum nextObject])
                if([self copyPath:originalPath toPath:[fullPathDict valueForKey:originalPath] handler:nil] == NO)
                    NSLog(@"Unable to copy %@ to %@", originalPath, [fullPathDict valueForKey:originalPath]);
        }
        @catch(NSException *localException) {
            NSLog(@"%@: discarding %@: %@", NSStringFromSelector(_cmd), [localException name], [localException reason]);
        }
        
        @finally {
            [pool release];
        }
    }
}

- (void)copyFilesInBackgroundThread:(NSDictionary *)fullPathDict{
    [NSThread detachNewThreadSelector:@selector(copyFilesInPathDictionary:) toTarget:self withObject:fullPathDict];
}

- (void)createWeblocFilesInBackgroundThread:(NSDictionary *)fullPathDict{
    [NSThread detachNewThreadSelector:@selector(createWeblocFiles:) toTarget:self withObject:fullPathDict];
}


@end

@implementation WLDragMapEntry

- (id)initWithType:(OSType)type resID:(int)resID;
{
    self = [super init];
    
    _type = type;
    _resID = resID;
    
    return self;
}

+ (id)entryWithType:(OSType)type resID:(int)resID;
{
    WLDragMapEntry* result = [[WLDragMapEntry alloc] initWithType:type resID:resID];
    
    return [result autorelease];
}

- (OSType)type;
{
    return _type;
}

- (ResID)resID;
{
    return _resID;
}

- (NSData*)entryData;
{
    WLDragMapEntryStruct result;
    
    // zero the structure
    memset(&result, 0, sizeof(result));
    
    result.type = _type;
    result.resID = _resID;
    
    return [NSData dataWithBytes:&result length:sizeof(result)];
}

+ (NSData*)dragDataWithEntries:(NSArray*)entries;
{
    NSMutableData *result;
    WLDragMapHeaderStruct header;
    NSEnumerator *enumerator = [entries objectEnumerator];
    WLDragMapEntry *entry;
    
    // zero the structure
    memset(&header, 0, sizeof(WLDragMapHeaderStruct));
    
    header.mapVersion = 1;
    header.numEntries = [entries count];
    
    result = [NSMutableData dataWithBytes:&header length:sizeof(WLDragMapHeaderStruct)];
    
    while (entry = [enumerator nextObject])
        [result appendData:[entry entryData]];
    
    return result;
}

@end

@implementation OFResourceFork (BDSKExtensions)

- (void)setData:(NSData *)contentData forResourceType:(ResType)resType resID:(short)resID;
{
    SInt16 oldCurRsrcMap;
    
    oldCurRsrcMap = CurResFile();
    UseResFile(refNum);
    
    const void *data = [contentData bytes];
    Handle dataHandle;
    PtrToHand(data, &dataHandle, [contentData length]);
    Str255 dst;
    CopyCStringToPascal("OFResourceForkData", dst);
    AddResource(dataHandle, resType, resID, dst);
    
    UpdateResFile(refNum);
    UseResFile(oldCurRsrcMap);
}

@end