//
//  SKDownload.m
//  Skim
//
//  Created by Christiaan Hofman on 8/11/07.
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

#import "SKDownload.h"
#import <ApplicationServices/ApplicationServices.h>
#import "Files_SKExtensions.h"
#import "SKRuntime.h"

NSString *SKDownloadFileNameKey = @"fileName";
NSString *SKDownloadStatusKey = @"status";
NSString *SKDownloadProgressIndicatorKey = @"progressIndicator";

@interface SKDownload (Private)
- (void)setStatus:(SKDownloadStatus)newStatus;
- (void)setFilePath:(NSString *)newFilePath;
- (void)setExpectedContentLength:(long long)newExpectedContentLength;
- (void)setReceivedContentLength:(long long)newReceivedContentLength;
- (void)handleApplicationWillTerminateNotification:(NSNotification *)notification;
@end


@implementation SKDownload

+ (NSArray *)infoKeys {
    return [NSArray arrayWithObjects:SKDownloadFileNameKey, SKDownloadStatusKey, SKDownloadProgressIndicatorKey, nil];
}

+ (void)initialize {
    NSArray *keys = [NSArray arrayWithObjects:@"filePath", nil];
    [self setKeys:keys triggerChangeNotificationsForDependentKey:@"fileName"];
    [self setKeys:keys triggerChangeNotificationsForDependentKey:@"fileIcon"];
    keys = [NSArray arrayWithObjects:SKDownloadStatusKey, nil];
    [self setKeys:keys triggerChangeNotificationsForDependentKey:@"canCancel"];
    [self setKeys:keys triggerChangeNotificationsForDependentKey:@"canRemove"];
    [self setKeys:keys triggerChangeNotificationsForDependentKey:@"canResume"];
    [self setKeys:[self infoKeys] triggerChangeNotificationsForDependentKey:@"info"];
    SKINITIALIZE;
}

- (id)initWithURL:(NSURL *)aURL delegate:(id)aDelegate {
    if (self = [super init]) {
        URL = [aURL retain];
        URLDownload = nil;
        filePath = nil;
        fileIcon = nil;
        expectedContentLength = NSURLResponseUnknownLength;
        receivedContentLength = 0;
        progressIndicator = nil;
        status = SKDownloadStatusUndefined;
        delegate = aDelegate;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationWillTerminateNotification:) 
                                                     name:NSApplicationWillTerminateNotification object:NSApp];
    }
    return self;
}

- (id)init {
    return [self initWithURL:nil delegate:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self cancel];
    [URL release];
    [URLDownload release];
    [filePath release];
    [fileIcon release];
    [progressIndicator release];
    [super dealloc];
}

- (void)handleApplicationWillTerminateNotification:(NSNotification *)notification {
    [self cancel];
}

- (void)resetProgressIndicator {
    if (expectedContentLength > 0) {
        [progressIndicator setIndeterminate:NO];
        [progressIndicator setMaxValue:(double)expectedContentLength];
    } else {
        [progressIndicator setIndeterminate:YES];
        [progressIndicator setMaxValue:1.0];
    }
}

#pragma mark Accessors

- (id)delegate {
    return delegate;
}

- (void)setDelegate:(id)newDelegate {
    delegate = newDelegate;
}

- (SKDownloadStatus)status {
    return status;
}

- (void)setStatus:(SKDownloadStatus)newStatus {
    if (status != newStatus) {
        if (newStatus == SKDownloadStatusDownloading) {
            [progressIndicator startAnimation:self];
        } else if (status == SKDownloadStatusDownloading) {
            [progressIndicator stopAnimation:self];
            [progressIndicator removeFromSuperview];
            [progressIndicator release];
            progressIndicator = nil;
        }
        status = newStatus;
    }
}

- (NSURL *)URL {
    return URL;
}

- (NSString *)filePath {
    return filePath;
}

- (void)setFilePath:(NSString *)newFilePath {
    if (filePath != newFilePath) {
        [filePath release];
        filePath = [newFilePath retain];
        
        if (fileIcon == nil && filePath) {
            fileIcon = [[[NSWorkspace sharedWorkspace] iconForFileType:[filePath pathExtension]] retain];
        }
    }
}

- (NSString *)fileName {
    return [([self filePath] ?: [[self URL] path]) lastPathComponent];
}

- (NSImage *)fileIcon {
    if (fileIcon == nil && URL)
        return [[NSWorkspace sharedWorkspace] iconForFileType:[[[self URL] path] pathExtension]];
    return fileIcon;
}

- (void)setFileIcon:(NSImage *)newFileIcon {
    if (fileIcon != newFileIcon) {
        [fileIcon release];
        fileIcon = [newFileIcon retain];
    }
}

- (long long)expectedContentLength {
    return expectedContentLength;
}

- (void)setExpectedContentLength:(long long)newExpectedContentLength {
    if (expectedContentLength != newExpectedContentLength) {
        expectedContentLength = newExpectedContentLength;
        [self resetProgressIndicator];
    }
}

- (long long)receivedContentLength {
    return receivedContentLength;
}

- (void)setReceivedContentLength:(long long)newReceivedContentLength {
    if (receivedContentLength != newReceivedContentLength) {
        receivedContentLength = newReceivedContentLength;
		[progressIndicator setDoubleValue:(double)receivedContentLength];
    }
}

- (NSURLDownload *)URLDownload {
    return URLDownload;
}

- (NSProgressIndicator *)progressIndicator {
    if (progressIndicator == nil && [self status] == SKDownloadStatusDownloading) {
        progressIndicator = [[NSProgressIndicator alloc] init];
        [progressIndicator setStyle:NSProgressIndicatorBarStyle];
        [progressIndicator setControlSize:NSSmallControlSize];
        [progressIndicator setUsesThreadedAnimation:YES];
        [progressIndicator sizeToFit];
        [self resetProgressIndicator];
        [progressIndicator setDoubleValue:(double)receivedContentLength];
        [progressIndicator startAnimation:self];
    }
    return progressIndicator;
}

- (NSDictionary *)info {
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    NSEnumerator *keyEnum = [[[self class] infoKeys] objectEnumerator];
    NSString *key;
    while (key = [keyEnum nextObject])
        [info setValue:[self valueForKey:key] forKey:key];
    return info;
}

- (void)removeProgressIndicatorFromSuperview {
    [progressIndicator removeFromSuperview];
}

#pragma mark Actions

- (void)start {
    if (URLDownload || URL == nil) {
        NSBeep();
        return;
    }
    
    [self setExpectedContentLength:NSURLResponseUnknownLength];
    [self setReceivedContentLength:0];
    URLDownload = [[NSURLDownload alloc] initWithRequest:[NSURLRequest requestWithURL:URL] delegate:self];
    [URLDownload setDeletesFileUponFailure:NO];
    [self setStatus:SKDownloadStatusStarting];
    if ([delegate respondsToSelector:@selector(downloadDidStart:)])
        [delegate downloadDidStart:self];
}

- (void)cancel {
    if ([self canCancel]) {
        
        [URLDownload cancel];
        [self setStatus:SKDownloadStatusCanceled];
        if ([delegate respondsToSelector:@selector(downloadDidEnd:)])
            [delegate downloadDidEnd:self];
    }
}

- (void)resume {
    if ([self canResume]) {
        
        NSData *resumeData = nil;
        if ([self status] == SKDownloadStatusCanceled) 
            resumeData = [[[URLDownload resumeData] retain] autorelease];
        
        if (resumeData) {
            
            [URLDownload release];
            URLDownload = [[NSURLDownload alloc] initWithResumeData:resumeData delegate:self path:[self filePath]];
            [URLDownload setDeletesFileUponFailure:NO];
            [self setStatus:SKDownloadStatusDownloading];
            if ([delegate respondsToSelector:@selector(downloadDidStart:)])
                [delegate downloadDidStart:self];
            
        } else {
            
            [self cleanup];
            [self setFilePath:nil];
            [URLDownload release];
            URLDownload = nil;
            [self start];
            
        }
    }
}

- (void)cleanup {
    [self cancel];
    if (filePath)
        [[NSFileManager defaultManager] removeFileAtPath:[filePath stringByDeletingLastPathComponent] handler:nil];
}

- (BOOL)canCancel {
    return [self status] == SKDownloadStatusStarting || [self status] == SKDownloadStatusDownloading;
}

- (BOOL)canRemove {
    return [self status] == SKDownloadStatusFinished || [self status] == SKDownloadStatusFailed || [self status] == SKDownloadStatusCanceled;
}

- (BOOL)canResume {
    return ([self status] == SKDownloadStatusCanceled || [self status] == SKDownloadStatusFailed) && [self URL];
}

#pragma mark NSURLDownloadDelegate protocol

- (void)downloadDidBegin:(NSURLDownload *)download{
    [self setStatus:SKDownloadStatusDownloading];
    if ([delegate respondsToSelector:@selector(downloadDidBeginDownloading:)])
        [delegate downloadDidBeginDownloading:self];
}

- (void)download:(NSURLDownload *)download didReceiveResponse:(NSURLResponse *)response {
    [self setExpectedContentLength:[response expectedContentLength]];
    
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (CFStringRef)[response MIMEType], kUTTypeData);
    if (UTI) {
        CFStringRef type = UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassFilenameExtension);
        if (type) {
            [self setFileIcon:[[NSWorkspace sharedWorkspace] iconForFileType:(NSString *)type]];
            CFRelease(type);
        }
        CFRelease(UTI);
    }
    
    if ([delegate respondsToSelector:@selector(downloadDidUpdate:)])
        [delegate downloadDidUpdate:self];
}

- (void)download:(NSURLDownload *)download decideDestinationWithSuggestedFilename:(NSString *)filename {
    [URLDownload setDestination:[SKDownloadDirectory() stringByAppendingPathComponent:filename] allowOverwrite:NO];
}

- (void)download:(NSURLDownload *)download didCreateDestination:(NSString *)path {
    [self setFilePath:path];
    if ([delegate respondsToSelector:@selector(downloadDidUpdate:)])
        [delegate downloadDidUpdate:self];
}

- (void)download:(NSURLDownload *)download didReceiveDataOfLength:(NSUInteger)length {
    if (expectedContentLength > 0) {
        receivedContentLength += length;
		[progressIndicator setDoubleValue:(double)receivedContentLength];
        if ([delegate respondsToSelector:@selector(downloadDidUpdate:)])
            [delegate downloadDidUpdate:self];
    }
}

- (void)downloadDidFinish:(NSURLDownload *)theDownload {
    if (expectedContentLength > 0)
		[progressIndicator setDoubleValue:(double)expectedContentLength];
    [self setStatus:SKDownloadStatusFinished];
    if ([delegate respondsToSelector:@selector(downloadDidEnd:)])
        [delegate downloadDidEnd:self];
}

- (void)download:(NSURLDownload *)download didFailWithError:(NSError *)error {
    [self setStatus:SKDownloadStatusFailed];
    if (filePath)
        [[NSFileManager defaultManager] removeFileAtPath:filePath handler:nil];
    [self setFilePath:nil];
    if ([delegate respondsToSelector:@selector(downloadDidEnd:)])
        [delegate downloadDidEnd:self];
}

@end
