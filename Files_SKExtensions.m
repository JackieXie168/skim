//
//  Files_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 8/18/07.
/*
 This software is Copyright (c) 2007-2009
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

#import "Files_SKExtensions.h"
#import <CoreFoundation/CoreFoundation.h>

BOOL SKFileIsInTrash(NSURL *fileURL) {
    NSCParameterAssert([fileURL isFileURL]);    
    FSRef fileRef;
    Boolean result = false;
    if (CFURLGetFSRef((CFURLRef)fileURL, &fileRef)) {
        FSDetermineIfRefIsEnclosedByFolder(0, kTrashFolderType, &fileRef, &result);
        if (result == false)
            FSDetermineIfRefIsEnclosedByFolder(0, kSystemTrashFolderType, &fileRef, &result);
    }
    return result;
}

static NSString *SKUniqueDirectory(NSString *basePath) {
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    NSString *tmpDirName = [(NSString *)CFUUIDCreateString(NULL, uuid) autorelease];
    CFRelease(uuid);
    
    BOOL success = YES;
    FSRef tmpRef;
    UniCharCount length = [tmpDirName length];
    UniChar *tmpName = (UniChar *)NSZoneMalloc(NULL, length * sizeof(UniChar));
    [tmpDirName getCharacters:tmpName];
    success = noErr == FSPathMakeRef((UInt8 *)[basePath fileSystemRepresentation], &tmpRef, NULL) &&
              noErr == FSCreateDirectoryUnicode(&tmpRef, length, tmpName, kFSCatInfoNone, NULL, NULL, NULL, NULL);
    NSZoneFree(NULL, tmpName);
    
    return success ? [basePath stringByAppendingPathComponent:tmpDirName] : nil;
}

NSString *SKChewableItemsDirectory() {
    // chewable items are automatically cleaned up at restart, and it's hidden from the user
    static NSString *chewableItemsDirectory = nil;
    if (chewableItemsDirectory == nil) {
        FSRef chewableRef;
        OSErr err = FSFindFolder(kUserDomain, kChewableItemsFolderType, TRUE, &chewableRef);
        
        CFAllocatorRef alloc = CFAllocatorGetDefault();
        CFURLRef chewableURL = NULL;
        if (noErr == err) {
            chewableURL = CFURLCreateFromFSRef(alloc, &chewableRef);
            
            CFStringRef baseName = CFStringCreateWithFileSystemRepresentation(alloc, "Skim");
            CFURLRef newURL = CFURLCreateCopyAppendingPathComponent(alloc, chewableURL, baseName, TRUE);
            FSRef newRef;
            
            if (chewableURL) CFRelease(chewableURL);
            
            assert(NULL != newURL);
            
            if (CFURLGetFSRef(newURL, &newRef) == false) {
                CFIndex nameLength = CFStringGetLength(baseName);
                UniChar *nameBuf = CFAllocatorAllocate(alloc, nameLength * sizeof(UniChar), 0);
                CFStringGetCharacters(baseName, CFRangeMake(0, nameLength), nameBuf);
                err = FSCreateDirectoryUnicode(&chewableRef, nameLength, nameBuf, kFSCatInfoNone, NULL, NULL, NULL, NULL);
                CFAllocatorDeallocate(alloc, nameBuf);
            }
            
            if (noErr == err)
                chewableItemsDirectory = (NSString *)CFURLCopyFileSystemPath(newURL, kCFURLPOSIXPathStyle);
            
            if (newURL) CFRelease(newURL);
            if (baseName) CFRelease(baseName);
            
            assert(nil != chewableItemsDirectory);
        }
    }
    return chewableItemsDirectory;
}

NSString *SKUniqueTemporaryDirectory() {
    return SKUniqueDirectory(NSTemporaryDirectory());
}

NSString *SKUniqueChewableItemsDirectory() {
    return SKUniqueDirectory(SKChewableItemsDirectory());
}
