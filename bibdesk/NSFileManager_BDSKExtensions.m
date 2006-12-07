//
//  NSFileManager_BDSKExtensions.m
//  Bibdesk
//
//  Created by Adam Maxwell on 07/08/05.
//
/*
 This software is Copyright (c) 2005
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


@implementation NSFileManager (BDSKExtensions)

- (NSString *)currentApplicationSupportPathForCurrentUser{
    
    NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleExecutableKey];
    
    if(appName == nil)
        [NSException raise:NSObjectNotAvailableException format:NSLocalizedString(@"Unable to find CFBundleIdentifier for %@", @""), [NSApp description]];
    
    NSString *path = nil;
    FSRef foundRef;
    OSStatus err = noErr;
    
    err = FSFindFolder(kUserDomain,
                       kApplicationSupportFolderType,
                       kCreateFolder,
                       &foundRef);
    if(err != noErr){
        NSLog(@"Error %d:  the system was unable to find your Application Support folder.", err);
        return nil;
    }
    
    CFURLRef url = CFURLCreateFromFSRef(kCFAllocatorDefault, &foundRef);
    
    if(url != nil){
        path = [(NSURL *)url path];
        CFRelease(url);
    }
    
    return [path stringByAppendingPathComponent:appName];
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

- (NSString *)spotlightCacheFolderPathByCreating:(NSError **)anError{

#ifndef NOSPOTLIGHT        
    NSString *basePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"Metadata"];
    NSAssert(basePath != nil, @"nil cache base path");
    
    volatile BOOL dirExists = YES;
    
    NS_DURING{
        if(![self fileExistsAtPath:basePath])
            dirExists = [self createDirectoryAtPath:basePath attributes:nil];
    }
    NS_HANDLER{
        NSLog(@"%@: caught %@: %@", NSStringFromSelector(_cmd), [localException name], [localException reason]);
    }
    NS_ENDHANDLER
    
    if(!dirExists){
        *anError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteUnknownError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:basePath, NSFilePathErrorKey, NSLocalizedString(@"Unable to create the cache directory.", @""), NSLocalizedDescriptionKey]];
        return nil;
    }
    
    NSString *cachePath = [basePath stringByAppendingPathComponent:[[NSBundle mainBundle] bundleIdentifier]];
    volatile BOOL mdExists = YES;
    
    NS_DURING{
        if(![self fileExistsAtPath:cachePath])
            mdExists = [self createDirectoryAtPath:cachePath attributes:nil];
    }
    NS_HANDLER{
        NSLog(@"%@: caught %@: %@", NSStringFromSelector(_cmd), [localException name], [localException reason]);
    }
    NS_ENDHANDLER
    
    if(!mdExists){
        *anError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteUnknownError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:cachePath, NSFilePathErrorKey, NSLocalizedString(@"Unable to create the cache directory.", @""), NSLocalizedDescriptionKey]];
        return nil;
    }
    
    return cachePath;
#endif
    
}

- (BOOL)removeSpotlightCacheFolder{
    
    if(![self spotlightCacheFolderExists])
        return NO;
    
    NSError *error = nil;
    NSString *path = [self spotlightCacheFolderPathByCreating:&error];
    if(error != nil)
        return NO;
    
    volatile BOOL removed;
    
    NS_DURING{
        removed = [self removeFileAtPath:path handler:nil];
    }
    NS_HANDLER{
        removed = NO;
        NSLog(@"%@: caught %@: %@", NSStringFromSelector(_cmd), [localException name], [localException reason]);
    }
    NS_ENDHANDLER
    
    return removed;
}

- (BOOL)spotlightCacheFolderExists{

#ifndef NOSPOTLIGHT        
    NSString *path = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"Metadata"];
    NSAssert(path != nil, @"nil caches path");
    path = [path stringByAppendingPathComponent:[[NSBundle mainBundle] bundleIdentifier]];
    
    return [self fileExistsAtPath:path];
#endif
}

- (BOOL)removeSpotlightCacheForItemNamed:(NSString *)itemName{

    NSString *fileName = [itemName stringByAppendingString:@".bdskcache"];
    NSError *error = nil;
    
    fileName = [[self spotlightCacheFolderPathByCreating:&error] stringByAppendingPathComponent:fileName];

    volatile BOOL removed;
    
    NS_DURING{
        removed = [self removeFileAtPath:fileName handler:nil];
    }
    NS_HANDLER{
        removed = NO;
        NSLog(@"%@: caught %@: %@", NSStringFromSelector(_cmd), [localException name], [localException reason]);
    }
    NS_ENDHANDLER
    
    return removed;
}


@end
