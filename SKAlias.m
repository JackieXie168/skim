//
//  SKAlias.m
//  Skim
//
//  Created by Christiaan Hofman on 1/21/13.
/*
 This software is Copyright (c)2013-2014
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

@dynamic data, fileURL, fileURLNoUI;

+ (id)aliasWithData:(NSData *)data {
    return [[[self alloc] initWithData:data] autorelease];
}

+ (id)aliasWithURL:(NSURL *)fileURL {
    return [[[self alloc] initWithURL:fileURL] autorelease];
}

- (id)initWithData:(NSData *)data {
    self = [super init];
    if (self) {
        
        if (data == nil) {
            [self release];
            self = nil;
        } else {
            CFIndex len = CFDataGetLength((CFDataRef)data);
            Handle handle = NewHandle(len);
        
            if (handle != NULL && len > 0) {
                HLock(handle);
                memmove((void *)*handle, (const void *)CFDataGetBytePtr((CFDataRef)data), len);
                HUnlock(handle);
                
                aliasHandle = (AliasHandle)handle;
            } else {
                [self release];
                self = nil;
            }

        }
    }
    return self;
}

- (id)initWithURL:(NSURL *)fileURL {
    self = [super init];
    if (self) {
        FSRef fileRef;
        
        if (nil == fileURL ||
            false == CFURLGetFSRef((CFURLRef)fileURL, &fileRef) || 
            noErr != FSNewAlias(NULL, &fileRef, &aliasHandle)) {
            
            [self release];
            self = nil;
        }
    }
    return self;
}

- (void)dealloc {
    if (aliasHandle) DisposeHandle((Handle)aliasHandle);
    aliasHandle = NULL;
    [super dealloc];
}

- (NSData *)data {
    CFDataRef data = NULL;
    Handle handle = (Handle)aliasHandle;
    
    if (handle) {
        CFIndex len = GetHandleSize(handle);
        SInt8 handleState = HGetState(handle);
        
        HLock(handle);
        data = CFDataCreate(kCFAllocatorDefault, (const UInt8 *)*handle, len);
        HSetState(handle, handleState);
    }
    
    return [(NSData *)data autorelease];
}

- (NSURL *)fileURLWithMountFlags:(unsigned int)flags {
    CFURLRef fileURL = NULL;
    FSRef fileRef;
    Boolean wasChanged;
    
    if (aliasHandle && noErr == FSResolveAliasWithMountFlags(NULL, aliasHandle, &fileRef, &wasChanged, flags))
        fileURL = CFURLCreateFromFSRef(kCFAllocatorDefault, &fileRef);
    
    return [(NSURL *)fileURL autorelease];
}

- (NSURL *)fileURL {
    return [self fileURLWithMountFlags:0];
}

- (NSURL *)fileURLNoUI {
    return [self fileURLWithMountFlags:kResolveAliasFileNoUI];
}

@end
