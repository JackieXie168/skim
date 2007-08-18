//
//  Files_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 8/18/07.
/*
 This software is Copyright (c) 2007
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
#import <Carbon/Carbon.h>


BOOL SKFileIsInTrash(NSURL *fileURL) {
    NSCParameterAssert([fileURL isFileURL]);    
    FSRef parentRef;
    CFURLRef parentURL = CFURLCreateCopyDeletingLastPathComponent(CFGetAllocator((CFURLRef)fileURL), (CFURLRef)fileURL);
    [(id)parentURL autorelease];
    if (CFURLGetFSRef(parentURL, &parentRef)) {
        OSStatus err;
        FSRef fsRef;
        err = FSFindFolder(kUserDomain, kTrashFolderType, TRUE, &fsRef);
        if (noErr == err && noErr == FSCompareFSRefs(&fsRef, &parentRef))
            return YES;
        
        err = FSFindFolder(kOnAppropriateDisk, kSystemTrashFolderType, TRUE, &fsRef);
        if (noErr == err && noErr == FSCompareFSRefs(&fsRef, &parentRef))
            return YES;
    }
    return NO;
}

BOOL SKFileExistsAtPath(NSString *path) {
    FSRef fileRef;
    
    if (path && noErr == FSPathMakeRef((UInt8 *)[path fileSystemRepresentation], &fileRef, NULL))
        return YES;
    else
        return NO;
}

NSDate *SKFileModificationDateAtPath(NSString *path) {
    FSRef fileRef;
    FSCatalogInfo info;
    CFAbsoluteTime absoluteTime;
    
    if (CFURLGetFSRef((CFURLRef)[NSURL fileURLWithPath:path], &fileRef) &&
        noErr == FSGetCatalogInfo(&fileRef, kFSCatInfoContentMod, &info, NULL, NULL, NULL) &&
        noErr == UCConvertUTCDateTimeToCFAbsoluteTime(&info.contentModDate, &absoluteTime))
        return [NSDate dateWithTimeIntervalSinceReferenceDate:(NSTimeInterval)absoluteTime];
    else
        return nil;
}

NSString *SKTemporaryDirectoryCreating(BOOL create) {
    NSString *baseTmpDir = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSBundle mainBundle] bundleIdentifier]];
    NSString *tmpDir = baseTmpDir;
    NSString *tmpDirName;
    int i = 0;
    BOOL success = YES;
    
    while (SKFileExistsAtPath(tmpDir))
        tmpDir = [baseTmpDir stringByAppendingFormat:@"-%i", ++i];
    
    tmpDirName = [tmpDir lastPathComponent];
    if (success && create) {
        FSRef tmpRef;
        success = noErr == FSPathMakeRef((UInt8 *)[NSTemporaryDirectory() fileSystemRepresentation], &tmpRef, NULL) &&
                  noErr == FSCreateDirectoryUnicode(&tmpRef, [tmpDirName length], (const UniChar *)[tmpDirName cStringUsingEncoding:NSUnicodeStringEncoding], kFSCatInfoNone, NULL, NULL, NULL, NULL);
    }
    
    return success ? tmpDir : nil;
}
