//
//  SKDownload.m
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

#import "SKDownload.h"
#import <ApplicationServices/ApplicationServices.h>
#import "NSFileManager_SKExtensions.h"
#import "SKDownloadController.h"
#import "SKStringConstants.h"

NSString *SKDownloadFileNameKey = @"fileName";
NSString *SKDownloadStatusKey = @"status";
NSString *SKDownloadProgressIndicatorKey = @"progressIndicator";

#define SKFileURLKey  @"fileURL"
#define SKFileIconKey  @"fileIcon"
#define SKCanCancelKey @"canCancel"
#define SKCanRemoveKey @"canRemove"
#define SKCanResumeKey @"canResume"
#define SKInfoKey      @"info"

@interface SKDownload ()
@property (nonatomic) SKDownloadStatus status;
@property (nonatomic, retain) NSURL *fileURL;
@property (nonatomic, retain) NSImage *fileIcon;
@property (nonatomic) long long expectedContentLength, receivedContentLength;
- (void)handleApplicationWillTerminateNotification:(NSNotification *)notification;
@end


@implementation SKDownload

@synthesize URL, fileURL, fileIcon, expectedContentLength, receivedContentLength, status;
@dynamic fileName, info, canCancel, canRemove, canResume, scriptingURL, scriptingStatus;

static NSSet *keysAffectedByFileURL = nil;
static NSSet *keysAffectedByDownloadStatus = nil;
static NSSet *fileURLSet = nil;
static NSSet *downloadStatusSet = nil;
static NSSet *infoKeys = nil;

+ (void)initialize {
    SKINITIALIZE;
    keysAffectedByFileURL = [[NSSet alloc] initWithObjects:SKDownloadFileNameKey, SKFileIconKey, nil];
    keysAffectedByDownloadStatus = [[NSSet alloc] initWithObjects:SKCanCancelKey, SKCanRemoveKey, SKCanResumeKey, nil];
    fileURLSet = [[NSSet alloc] initWithObjects:SKFileURLKey, nil];
    downloadStatusSet = [[NSSet alloc] initWithObjects:SKDownloadStatusKey, nil];
    infoKeys = [[NSSet alloc] initWithObjects:SKDownloadFileNameKey, SKDownloadStatusKey, SKDownloadProgressIndicatorKey, nil];
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    NSSet *set = [super keyPathsForValuesAffectingValueForKey:key];
    if ([keysAffectedByFileURL containsObject:key])
        return [set count] > 0 ? [set setByAddingObjectsFromSet:fileURLSet] : fileURLSet;
    if ([keysAffectedByDownloadStatus containsObject:key])
        return [set count] > 0 ? [set setByAddingObjectsFromSet:downloadStatusSet] : downloadStatusSet;
    if ([SKInfoKey isEqualToString:key])
        return [set count] > 0 ? [set setByAddingObjectsFromSet:infoKeys] : infoKeys;
    return set;
}

- (id)initWithURL:(NSURL *)aURL {
    self = [super init];
    if (self) {
        URL = [aURL retain];
        URLDownload = nil;
        fileURL = nil;
        fileIcon = nil;
        expectedContentLength = NSURLResponseUnknownLength;
        receivedContentLength = 0;
        progressIndicator = nil;
        status = SKDownloadStatusUndefined;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationWillTerminateNotification:) 
                                                     name:NSApplicationWillTerminateNotification object:NSApp];
    }
    return self;
}

- (id)init {
    return [self initWithURL:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self cancel];
    SKDESTROY(URL);
    SKDESTROY(URLDownload);
    SKDESTROY(fileURL);
    SKDESTROY(fileIcon);
    SKDESTROY(progressIndicator);
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

- (void)removeProgressIndicatorFromSuperview {
    [progressIndicator removeFromSuperview];
}

#pragma mark Accessors

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

- (NSString *)fileName {
    NSString *fileName = nil;
    [fileURL getResourceValue:&fileName forKey:NSURLLocalizedNameKey error:NULL];
    if (fileName == nil) {
        if ([[URL path] length] > 1) {
            fileName = [[URL path] lastPathComponent];
        } else {
            fileName = [URL host];
            if (fileName == nil)
                fileName = [[[URL resourceSpecifier] lastPathComponent] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        }
    }
    return fileName;
}

- (void)setFileURL:(NSURL *)newFileURL {
    if (fileURL != newFileURL) {
        [fileURL release];
        fileURL = [newFileURL retain];
        
        if (fileIcon == nil && fileURL) {
            fileIcon = [[[NSWorkspace sharedWorkspace] iconForFileType:[fileURL pathExtension]] retain];
        }
    }
}

- (NSImage *)fileIcon {
    if (fileIcon == nil && URL)
        return [[NSWorkspace sharedWorkspace] iconForFileType:[[[self URL] path] pathExtension]];
    return fileIcon;
}

- (void)setExpectedContentLength:(long long)newExpectedContentLength {
    if (expectedContentLength != newExpectedContentLength) {
        expectedContentLength = newExpectedContentLength;
        [self resetProgressIndicator];
    }
}

- (void)setReceivedContentLength:(long long)newReceivedContentLength {
    if (receivedContentLength != newReceivedContentLength) {
        receivedContentLength = newReceivedContentLength;
		[progressIndicator setDoubleValue:(double)receivedContentLength];
    }
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
    for (NSString *key in infoKeys)
        [info setValue:[self valueForKey:key] forKey:key];
    return info;
}

- (id)objectSpecifier {
    NSUInteger idx = [[[SKDownloadController sharedDownloadController] downloads] indexOfObjectIdenticalTo:self];
    if (idx != NSNotFound) {
        NSScriptClassDescription *containerClassDescription = [NSScriptClassDescription classDescriptionForClass:[NSApp class]];
        return [[[NSIndexSpecifier allocWithZone:[self zone]] initWithContainerClassDescription:containerClassDescription containerSpecifier:nil key:@"downloads" index:idx] autorelease];
    } else {
        return nil;
    }
}

- (NSString *)scriptingURL {
    return [[self URL] absoluteString];
}

- (SKDownloadStatus)scriptingStatus {
    return [self status];
}

- (void)setScriptingStatus:(SKDownloadStatus)newStatus {
    if (newStatus != status) {
        if (newStatus == SKDownloadStatusCanceled && [self canCancel])
            [self cancel];
        else if ((newStatus == SKDownloadStatusStarting || newStatus == SKDownloadStatusDownloading) && [self canResume])
            [self resume];
    }
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
}

- (void)cancel {
    if ([self canCancel]) {
        
        [URLDownload cancel];
        [self setStatus:SKDownloadStatusCanceled];
    }
}

- (void)resume {
    if ([self canResume]) {
        
        NSData *resumeData = nil;
        if ([self status] == SKDownloadStatusCanceled) 
            resumeData = [[[URLDownload resumeData] retain] autorelease];
        
        if (resumeData) {
            
            [URLDownload release];
            URLDownload = [[NSURLDownload alloc] initWithResumeData:resumeData delegate:self path:[[self fileURL] path]];
            [URLDownload setDeletesFileUponFailure:NO];
            [self setStatus:SKDownloadStatusDownloading];
            
        } else {
            
            [self cleanup];
            [self setFileURL:nil];
            [URLDownload release];
            URLDownload = nil;
            [self start];
            
        }
    }
}

- (void)cleanup {
    [self cancel];
    if (fileURL)
        [[NSFileManager defaultManager] removeItemAtURL:[fileURL URLByDeletingLastPathComponent] error:NULL];
}

- (void)moveToTrash {
    if ([self canRemove] && fileURL) {
        NSURL *folderURL = [fileURL URLByDeletingLastPathComponent];
        NSString *fileName = [fileURL lastPathComponent];
        NSInteger tag = 0;
        
        [[NSWorkspace sharedWorkspace] performFileOperation:NSWorkspaceRecycleOperation source:[folderURL path] destination:nil files:[NSArray arrayWithObjects:fileName, nil] tag:&tag];
    }
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
}

- (void)download:(NSURLDownload *)download didReceiveResponse:(NSURLResponse *)response {
    [self setExpectedContentLength:[response expectedContentLength]];
    
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (CFStringRef)[response MIMEType], kUTTypeData);
    if (UTI) {
        NSString *type = [[NSWorkspace sharedWorkspace] preferredFilenameExtensionForType:(NSString *)UTI];
        if (type)
            [self setFileIcon:[[NSWorkspace sharedWorkspace] iconForFileType:type]];
        CFRelease(UTI);
    }
}

- (void)download:(NSURLDownload *)download decideDestinationWithSuggestedFilename:(NSString *)filename {
    NSString *downloadDir = [[[NSUserDefaults standardUserDefaults] stringForKey:SKDownloadsDirectoryKey] stringByExpandingTildeInPath];
    BOOL isDir;
    if ([[NSFileManager defaultManager] fileExistsAtPath:downloadDir isDirectory:&isDir] && isDir)
        [URLDownload setDestination:[downloadDir stringByAppendingPathComponent:filename] allowOverwrite:NO];
}

- (void)download:(NSURLDownload *)download didCreateDestination:(NSString *)path {
    [self setFileURL:[NSURL fileURLWithPath:path]];
}

- (void)download:(NSURLDownload *)download didReceiveDataOfLength:(NSUInteger)length {
    if (expectedContentLength > 0) {
        receivedContentLength += length;
		[progressIndicator setDoubleValue:(double)receivedContentLength];
    }
}

- (void)downloadDidFinish:(NSURLDownload *)theDownload {
    if (expectedContentLength > 0)
		[progressIndicator setDoubleValue:(double)expectedContentLength];
    [self setStatus:SKDownloadStatusFinished];
}

- (void)download:(NSURLDownload *)download didFailWithError:(NSError *)error {
    if (fileURL)
        [[NSFileManager defaultManager] removeItemAtURL:fileURL error:NULL];
    [self setFileURL:nil];
    [self setStatus:SKDownloadStatusFailed];
}

#pragma mark Quick Look Panel Support

- (NSURL *)previewItemURL {
    return [self fileURL];
}

- (NSString *)previewItemTitle {
    return [[self URL] absoluteString];
}

@end
