//
//  SKDownload.h
//  Skim
//
//  Created by Christiaan Hofman on 8/11/07.
/*
 This software is Copyright (c) 2007-2014
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

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>

// these are the keys used for the info
extern NSString *SKDownloadFileNameKey;
extern NSString *SKDownloadStatusKey;
extern NSString *SKDownloadProgressIndicatorKey;

enum {
    SKDownloadStatusUndefined,
    SKDownloadStatusStarting,
    SKDownloadStatusDownloading,
    SKDownloadStatusFinished,
    SKDownloadStatusFailed,
    SKDownloadStatusCanceled
};
typedef NSInteger SKDownloadStatus;

@interface SKDownload : NSObject <NSURLDownloadDelegate, QLPreviewItem> {
    NSURL *URL;
    NSURLDownload *URLDownload;
    long long expectedContentLength;
    long long receivedContentLength;
    NSURL *fileURL;
    NSImage *fileIcon;
    NSProgressIndicator *progressIndicator;
    SKDownloadStatus status;
}

@property (nonatomic, readonly) SKDownloadStatus status;

@property (nonatomic, readonly) NSURL *URL;

@property (nonatomic, readonly) NSString *fileName;
@property (nonatomic, readonly, retain) NSURL *fileURL;
@property (nonatomic, readonly, retain) NSImage *fileIcon;
@property (nonatomic, readonly) long long expectedContentLength, receivedContentLength;

@property (nonatomic, readonly) NSProgressIndicator *progressIndicator;

@property (nonatomic, readonly) NSDictionary *info;

@property (nonatomic, readonly) BOOL canCancel, canRemove, canResume;

@property (nonatomic, readonly) NSString *scriptingURL;
@property (nonatomic) SKDownloadStatus scriptingStatus;

- (id)initWithURL:(NSURL *)aURL;

- (void)start;
- (void)cancel;
- (void)resume;
- (void)cleanup;
- (void)moveToTrash;

- (void)removeProgressIndicatorFromSuperview;

@end
