//
//  NSFileManager_BDSKExtensions.h
//  Bibdesk
//
//  Created by Adam Maxwell on 07/08/05.
//
/*
 This software is Copyright (c) 2005,2006,2007
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

#import <Cocoa/Cocoa.h>


@interface NSFileManager (BDSKExtensions)

- (NSString *)currentApplicationSupportPathForCurrentUser;
- (NSString *)applicationSupportDirectory:(SInt16)domain;
- (NSString *)applicationsDirectory;
- (NSURL *)downloadFolderURL;

- (BOOL)copyFileFromResourcesToApplicationSupport:(NSString *)fileName overwrite:(BOOL)overwrite;

/*!
    @method     createWeblocFileAtPath:withURL:
    @abstract   Creates a webloc resource file at the destination path, for a given target URL.  This method is thread safe.
    @discussion (comprehensive description)
    @param      fullPath (description)
    @param      destURL (description)
    @result     (description)
*/
- (BOOL)createWeblocFileAtPath:(NSString *)fullPath withURL:(NSURL *)destURL;

/*!
    @method     createWeblocFilesInBackgroundThread:
    @abstract   Creates a batch of webloc files from a dictionary in a background thread; keys are destination path names, and values are NSURL objects.  This method is creates its own autorelease pool.
    @discussion (comprehensive description)
    @param      fullPathDict (description)
*/
- (void)createWeblocFilesInBackgroundThread:(NSDictionary *)fullPathDict;
- (void)copyFilesInBackgroundThread:(NSDictionary *)fullPathDict;

- (NSString *)uniqueFilePath:(NSString *)path createDirectory:(BOOL)create;

// for spotlight stuff; thread safe
- (BOOL)spotlightCacheFolderExists;
- (BOOL)removeSpotlightCacheFolder;
- (NSString *)spotlightCacheFolderPathByCreating:(NSError **)anError;
- (BOOL)removeSpotlightCacheFilesForCiteKeys:(NSArray *)itemNames;
- (BOOL)removeSpotlightCacheFileForCiteKey:(NSString *)citeKey;
- (NSString *)spotlightCacheFilePathWithCiteKey:(NSString *)citeKey;

//
// Thread safe API
//

// Finder comments
- (BOOL)setComment:(NSString *)comment forURL:(NSURL *)fileURL;
- (NSString *)commentForURL:(NSURL *)fileURL;

- (BOOL)createDirectoryAtPathWithNoAttributes:(NSString *)path;
- (BOOL)objectExistsAtFileURL:(NSURL *)fileURL;
- (BOOL)deleteObjectAtFileURL:(NSURL *)fileURL error:(NSError **)error;
- (BOOL)copyObjectAtURL:(NSURL *)srcURL toDirectoryAtURL:(NSURL *)dstURL error:(NSError **)error;

@end
