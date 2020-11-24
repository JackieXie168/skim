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

- (id)initWithAliasData:(NSData *)aliasData {
    self = [super init];
    if (self) {
        if (aliasData == nil) {
            [self release];
            self = nil;
        } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            CFIndex len = CFDataGetLength((CFDataRef)aliasData);
            Handle handle = NewHandle(len);
        
            if (handle != NULL && len > 0) {
                HLock(handle);
                memmove((void *)*handle, (const void *)CFDataGetBytePtr((CFDataRef)aliasData), len);
                HUnlock(handle);
#pragma clang diagnostic pop
                
                aliasHandle = (AliasHandle)handle;
                data = [aliasData retain];
            } else {
                [self release];
                self = nil;
            }
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
        FSRef fileRef;
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        if (nil == fileURL ||
            false == CFURLGetFSRef((CFURLRef)fileURL, &fileRef) || 
            noErr != FSNewAlias(NULL, &fileRef, &aliasHandle)) {
#pragma clang diagnostic pop
            
            [self release];
            self = nil;
        }
    }
    return self;
}

- (void)dealloc {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if (aliasHandle) DisposeHandle((Handle)aliasHandle);
#pragma clang diagnostic pop
    aliasHandle = NULL;
    SKDESTROY(data);
    [super dealloc];
}

- (NSData *)data {
    NSData *returnData = nil;
    if (aliasHandle) {
        // we could return data if present when fileURLNoUI is nil
        CFDataRef cfData = NULL;
        Handle handle = (Handle)aliasHandle;
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated-declarations"
        CFIndex len = GetHandleSize(handle);
        SInt8 handleState = HGetState(handle);
        HLock(handle);
        cfData = CFDataCreate(kCFAllocatorDefault, (const UInt8 *)*handle, len);
        HSetState(handle, handleState);
    #pragma clang diagnostic pop
        returnData = [(NSData *)data autorelease] ?: data;
    } else {
        returnData = data;
    }
    return returnData;
}

- (BOOL)isBookmark {
    return aliasHandle == nil && data != nil;
}

- (NSURL *)fileURLAllowingUI:(BOOL)allowUI {
    // we could cache the fileURL, but it would break when moving the file while we run
    if (aliasHandle) {
        unsigned long flags = allowUI ? 0 : kResolveAliasFileNoUI;
        CFURLRef fileURL = NULL;
        FSRef fileRef;
        Boolean wasChanged;
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated-declarations"
        if (aliasHandle && noErr == FSResolveAliasWithMountFlags(NULL, aliasHandle, &fileRef, &wasChanged, flags))
            fileURL = CFURLCreateFromFSRef(kCFAllocatorDefault, &fileRef);
    #pragma clang diagnostic pop
        // we could convert the aliasHandle to bookmark data here
        return [(NSURL *)fileURL autorelease];
    } else if (data) {
        NSURLBookmarkResolutionOptions options = allowUI ? 0 : NSURLBookmarkResolutionWithoutUI | NSURLBookmarkResolutionWithoutMounting;
        BOOL stale = NO;
        NSURL *fileURL = [NSURL URLByResolvingBookmarkData:data options:options relativeToURL:nil bookmarkDataIsStale:&stale error:NULL];
        // if stale we could update the bookmark data here
        return fileURL;
    }
    return nil;
}

- (NSURL *)fileURL {
    return [self fileURLAllowingUI:NO];
}

- (NSURL *)fileURLNoUI {
    return [self fileURLAllowingUI:YES];
}

@end
