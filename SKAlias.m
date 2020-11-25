//
//  SKAlias.m
//  Skim
//
//  Created by Christiaan Hofman on 1/21/13.
/*
 This software is Copyright (c)2013-2020
 Christiaan Hofman. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

 - Neither the name of Christiaan Hofman nor the names of any
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

#import "SKAlias.h"


@implementation SKAlias

@dynamic data, isBookmark, fileURL, fileURLNoUI;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
static inline AliasHandle createAliasHandleFromURL(NSURL *fileURL) {
    AliasHandle aliasHandle = NULL;
    FSRef fileRef;
    if (fileURL && CFURLGetFSRef((CFURLRef)fileURL, &fileRef))
        FSNewAlias(NULL, &fileRef, &aliasHandle);
    return aliasHandle;
}

static inline AliasHandle createAliasHandleFromData(NSData *data) {
    CFIndex len = CFDataGetLength((CFDataRef)data);
    Handle handle = NewHandle(len);
    if (handle != NULL && len > 0) {
        HLock(handle);
        memmove((void *)*handle, (const void *)CFDataGetBytePtr((CFDataRef)data), len);
        HUnlock(handle);
    }
    return (AliasHandle)handle;
}

static inline NSData *dataFromAliasHandle(AliasHandle aliasHandle) {
    CFDataRef data = NULL;
    Handle handle = (Handle)aliasHandle;
    CFIndex len = GetHandleSize(handle);
    SInt8 handleState = HGetState(handle);
    HLock(handle);
    data = CFDataCreate(kCFAllocatorDefault, (const UInt8 *)*handle, len);
    HSetState(handle, handleState);
    return [(NSData *)data autorelease];
}

static inline NSURL *fileURLFromAliasHandle(AliasHandle aliasHandle, NSUInteger mountFlags) {
    FSRef fileRef;
    Boolean wasChanged;
    if (noErr == FSResolveAliasWithMountFlags(NULL, aliasHandle, &fileRef, &wasChanged, mountFlags))
        return [(NSURL *)CFURLCreateFromFSRef(kCFAllocatorDefault, &fileRef) autorelease];
    return nil;
}

static inline void disposeAliasHandle(AliasHandle aliasHandle) {
    if (aliasHandle) DisposeHandle((Handle)aliasHandle);
}
#pragma clang diagnostic pop

- (id)initWithAliasData:(NSData *)aliasData {
    self = [super init];
    if (self) {
        if (aliasData)
            aliasHandle = createAliasHandleFromData(aliasData);
        if (aliasHandle) {
            data = [aliasData retain];
        } else {
            [self release];
            self = nil;
        }
    }
    return self;
}

- (id)initWithBookmarkData:(NSData *)bookmarkData {
    self = [super init];
    if (self) {
        if (bookmarkData) {
            data = [bookmarkData retain];
        } else {
            [self release];
            self = nil;
        }
    }
    return self;
}

- (id)initWithURL:(NSURL *)fileURL {
    self = [super init];
    if (self) {
        aliasHandle = createAliasHandleFromURL(fileURL);
        if (aliasHandle == nil) {
            [self release];
            self = nil;
        }
    }
    return self;
}

- (void)dealloc {
    disposeAliasHandle(aliasHandle);
    aliasHandle = NULL;
    SKDESTROY(data);
    [super dealloc];
}

- (NSData *)data {
    if (aliasHandle == NULL && data)
        // try to convert bookmark data to alias handle
        [self fileURLNoUI];
    if (aliasHandle)
        // we could return data if present when fileURLNoUI is nil
        return dataFromAliasHandle(aliasHandle) ?: data;
    else
        return data;
    return nil;
}

- (BOOL)isBookmark {
    return aliasHandle == nil && data != nil;
}

- (NSURL *)fileURLAllowingUI:(BOOL)allowUI {
    // we could cache the fileURL, but it would break when moving the file while we run
    NSURL *fileURL = nil;
    if (aliasHandle) {
        fileURL = fileURLFromAliasHandle(aliasHandle, allowUI ? 0 : kResolveAliasFileNoUI);
    } else if (data) {
        BOOL stale = NO;
        NSURLBookmarkResolutionOptions options = allowUI ? 0 : NSURLBookmarkResolutionWithoutUI | NSURLBookmarkResolutionWithoutMounting;
        NSURL *fileURL = [NSURL URLByResolvingBookmarkData:data options:options relativeToURL:nil bookmarkDataIsStale:&stale error:NULL];
        // convert back to alias handle
        if (fileURL) {
            AliasHandle handle = createAliasHandleFromURL(fileURL);
            if (handle) {
                aliasHandle = handle;
                [data release];
                data = nil;
            }
        }
    }
    return fileURL;
}

- (NSURL *)fileURL {
    return [self fileURLAllowingUI:NO];
}

- (NSURL *)fileURLNoUI {
    return [self fileURLAllowingUI:YES];
}

@end
