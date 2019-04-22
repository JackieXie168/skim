//
//  SKDownload.m
//  Skim
//
//  Created by Christiaan Hofman on 8/11/07.
/*
 This software is Copyright (c) 2007-2019
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
#import "NSString_SKExtensions.h"
#import "NSImage_SKExtensions.h"
#import "NSURL_SKExtensions.h"

#if !defined(MAC_OS_X_VERSION_10_9) || MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_9

#if __OBJC2__
#define NSURLSESSION_AVAILABLE    10_9
#else
#define NSURLSESSION_AVAILABLE    10_10
#endif

@class NSURLSessionTask;
@class NSURLSessionDownloadTask;

typedef NS_ENUM(NSInteger, NSURLSessionTaskState) {
    NSURLSessionTaskStateRunning = 0,
    NSURLSessionTaskStateSuspended = 1,
    NSURLSessionTaskStateCanceling = 2,
    NSURLSessionTaskStateCompleted = 3,
} NS_ENUM_AVAILABLE(NSURLSESSION_AVAILABLE, 7_0);

NS_CLASS_AVAILABLE(NSURLSESSION_AVAILABLE, 7_0)
@interface NSURLSessionTask : NSObject <NSCopying, NSProgressReporting>

@property (readonly) NSUInteger taskIdentifier;
@property (nullable, readonly, copy) NSURLRequest *originalRequest;
@property (nullable, readonly, copy) NSURLRequest *currentRequest;
@property (nullable, readonly, copy) NSURLResponse *response;

@property (readonly) int64_t countOfBytesReceived;
@property (readonly) int64_t countOfBytesSent;
@property (readonly) int64_t countOfBytesExpectedToSend;
@property (readonly) int64_t countOfBytesExpectedToReceive;

@property (nullable, copy) NSString *taskDescription;

- (void)cancel;

@property (readonly) NSURLSessionTaskState state;

@property (nullable, readonly, copy) NSError *error;

- (void)suspend;
- (void)resume;

@end

@interface NSURLSessionDownloadTask : NSURLSessionTask

- (void)cancelByProducingResumeData:(void (^)(NSData * _Nullable resumeData))completionHandler;

@end

#endif

NSString *SKDownloadFileNameKey = @"fileName";
NSString *SKDownloadFileURLKey = @"fileURL";
NSString *SKDownloadStatusKey = @"status";
NSString *SKDownloadProgressIndicatorKey = @"progressIndicator";

@interface SKDownload ()
@property (nonatomic) SKDownloadStatus status;
@property (nonatomic, retain) NSURL *fileURL;
@property (nonatomic, retain) NSImage *fileIcon;
@property (nonatomic) int64_t expectedContentLength, receivedContentLength;
- (void)handleApplicationWillTerminateNotification:(NSNotification *)notification;
@end


@implementation SKDownload

@synthesize URL, resumeData, fileURL, fileIcon, expectedContentLength, receivedContentLength, status;
@dynamic properties, fileName, statusDescription, info, hasExpectedContentLength, downloading, canCancel, canRemove, canResume, cancelImage, resumeImage, cancelToolTip, resumeToolTip, scriptingURL, scriptingStatus;

static NSSet *infoKeys = nil;

static BOOL usesSession = NO;

+ (void)initialize {
    SKINITIALIZE;
    infoKeys = [[NSSet alloc] initWithObjects:SKDownloadFileNameKey, SKDownloadStatusKey, nil];
    usesSession = Nil != NSClassFromString(@"NSURLSession");
}

+ (NSSet *)keyPathsForValuesAffectingFileName {
    return [NSSet setWithObjects:SKDownloadFileURLKey, nil];
}

+ (NSSet *)keyPathsForValuesAffectingDownloading {
    return [NSSet setWithObjects:SKDownloadStatusKey, nil];
}

+ (NSSet *)keyPathsForValuesAffectingStatusDescription {
    return [NSSet setWithObjects:SKDownloadStatusKey, nil];
}

+ (NSSet *)keyPathsForValuesAffectingHasExpectedContentLength {
    return [NSSet setWithObjects:@"expectedContentLength", nil];
}

+ (NSSet *)keyPathsForValuesAffectingCancelImage {
    return [NSSet setWithObjects:SKDownloadStatusKey, nil];
}

+ (NSSet *)keyPathsForValuesAffectingResumeImage {
    return [NSSet setWithObjects:SKDownloadStatusKey, nil];
}

+ (NSSet *)keyPathsForValuesAffectingCancelToolTip {
    return [NSSet setWithObjects:SKDownloadStatusKey, nil];
}

+ (NSSet *)keyPathsForValuesAffectingResumeToolTip {
    return [NSSet setWithObjects:SKDownloadStatusKey, nil];
}

+ (NSImage *)cancelImage {
    static NSImage *cancelImage = nil;
    if (cancelImage == nil) {
        cancelImage = [[NSImage imageWithSize:NSMakeSize(16.0, 16.0) drawingHandler:^(NSRect rect){
            [[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kToolbarDeleteIcon)] drawInRect:NSMakeRect(-2.0, -1.0, 20.0, 20.0) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
            return YES;
        }] retain];
    }
    return cancelImage;
}

+ (NSImage *)deleteImage {
    static NSImage *deleteImage = nil;
    if (deleteImage == nil) {
        deleteImage = [[NSImage imageWithSize:NSMakeSize(16.0, 16.0) drawingHandler:^(NSRect rect){
            if (RUNNING_AFTER(10_9)) {
                [[NSImage imageNamed:NSImageNameStopProgressFreestandingTemplate] drawInRect:NSInsetRect(rect, 1.0, 1.0) fromRect:NSZeroRect operation:NSCompositeDestinationAtop fraction:1.0];
            } else {
                [[NSColor lightGrayColor] setFill];
                [[NSBezierPath bezierPathWithRect:NSInsetRect(rect, 1.0, 1.0)] fill];
                [[NSImage imageNamed:NSImageNameStopProgressFreestandingTemplate] drawInRect:NSInsetRect(rect, 1.0, 1.0) fromRect:NSZeroRect operation:NSCompositeDestinationAtop fraction:1.0];
                [[NSGraphicsContext currentContext] setCompositingOperation:NSCompositeDestinationOver];
                [[NSColor whiteColor] setFill];
                [[NSBezierPath bezierPathWithOvalInRect:NSInsetRect(rect, 2.0, 2.0)] fill];
            }
            return YES;
        }] retain];
        if (RUNNING_AFTER(10_9))
            [deleteImage setTemplate:YES];
    }
    return deleteImage;
}

+ (NSImage *)resumeImage {
    static NSImage *resumeImage = nil;
    if (resumeImage == nil) {
        resumeImage = [[NSImage imageWithSize:NSMakeSize(16.0, 16.0) drawingHandler:^(NSRect rect){
            if (RUNNING_AFTER(10_9)) {
                [[NSImage imageNamed:NSImageNameRefreshFreestandingTemplate] drawInRect:NSInsetRect(rect, 1.0, 1.0) fromRect:NSZeroRect operation:NSCompositeDestinationAtop fraction:1.0];
            } else {
                [[NSColor lightGrayColor] setFill];
                [[NSBezierPath bezierPathWithRect:NSInsetRect(rect, 1.0, 1.0)] fill];
                [[NSImage imageNamed:NSImageNameRefreshFreestandingTemplate] drawInRect:NSInsetRect(rect, 1.0, 1.0) fromRect:NSZeroRect operation:NSCompositeDestinationAtop fraction:1.0];
                [[NSGraphicsContext currentContext] setCompositingOperation:NSCompositeDestinationOver];
                [[NSColor whiteColor] setFill];
                [[NSBezierPath bezierPathWithOvalInRect:NSInsetRect(rect, 2.0, 2.0)] fill];
            }
            return YES;
        }] retain];
        if (RUNNING_AFTER(10_9))
            [resumeImage setTemplate:YES];
    }
    return resumeImage;
}

- (id)initWithURL:(NSURL *)aURL {
    self = [super init];
    if (self) {
        URL = [aURL retain];
        downloadTask = nil;
        fileURL = nil;
        fileIcon = nil;
        expectedContentLength = NSURLResponseUnknownLength;
        receivedContentLength = 0;
        status = SKDownloadStatusUndefined;
        receivedResponse = NO;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationWillTerminateNotification:)
                                                     name:NSApplicationWillTerminateNotification object:NSApp];
    }
    return self;
}

- (id)initWithProperties:(NSDictionary *)properties {
    NSString *URLString = [properties objectForKey:@"URL"];
    self = [self initWithURL:URLString ? [NSURL URLWithString:URLString] : nil];
    if (self) {
        NSString *fileURLPath = [properties objectForKey:@"file"];
        downloadTask = nil;
        if (fileURLPath)
            fileURL = [[NSURL alloc] initFileURLWithPath:fileURLPath];
        fileIcon = fileURL ? [[[NSWorkspace sharedWorkspace] iconForFileType:[fileURL pathExtension]] retain] : nil;
        expectedContentLength = [[properties objectForKey:@"expectedContentLength"] longLongValue];
        receivedContentLength = [[properties objectForKey:@"receivedContentLength"] longLongValue];
        status = [[properties objectForKey:@"status"] integerValue];
        resumeData = nil;
        if ((usesSession ? fileURL == nil : [fileURL checkResourceIsReachableAndReturnError:NULL]))
            resumeData = [[properties objectForKey:@"resumeData"] retain];
    }
    return self;
}

- (id)init {
    return [self initWithURL:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if ([self canCancel])
        [downloadTask cancel];
    SKDESTROY(URL);
    SKDESTROY(downloadTask);
    SKDESTROY(fileURL);
    SKDESTROY(fileIcon);
    SKDESTROY(resumeData);
    [super dealloc];
}

- (void)handleApplicationWillTerminateNotification:(NSNotification *)notification {
    [self cancel];
}

#pragma mark Accessors

- (NSDictionary *)properties {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setValue:[[self URL] absoluteString] forKey:@"URL"];
    [dict setValue:[NSNumber numberWithInteger:status] forKey:@"status"];
    [dict setValue:[NSNumber numberWithLongLong:expectedContentLength] forKey:@"expectedContentLength"];
    [dict setValue:[NSNumber numberWithLongLong:receivedContentLength] forKey:@"receivedContentLength"];
    [dict setValue:[[self fileURL] path] forKey:@"file"];
    if ([self status] == SKDownloadStatusCanceled ||
        (usesSession && [self status] == SKDownloadStatusFailed))
            [dict setValue:resumeData forKey:@"resumeData"];
    return dict;
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

- (NSString *)statusDescription {
    switch ([self status]) {
        case SKDownloadStatusStarting:
            return [NSLocalizedString(@"Starting", @"Download status message") stringByAppendingEllipsis];
        case SKDownloadStatusDownloading:
            return [NSLocalizedString(@"Downloading", @"Download status message") stringByAppendingEllipsis];
        case SKDownloadStatusFinished:
            return NSLocalizedString(@"Finished", @"Download status message");
        case SKDownloadStatusFailed:
            return NSLocalizedString(@"Failed", @"Download status message");
        case SKDownloadStatusCanceled:
            return NSLocalizedString(@"Canceled", @"Download status message");
        default:
            return @"";
    }
}

- (BOOL)isDownloading {
    return [self status] == SKDownloadStatusDownloading;
}

- (BOOL)hasExpectedContentLength {
    return [self expectedContentLength] > 0;
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
    if (downloadTask || URL == nil) {
        NSBeep();
        return;
    }
    
    [self setExpectedContentLength:NSURLResponseUnknownLength];
    [self setReceivedContentLength:0];
    receivedResponse = NO;
    downloadTask = [[SKDownloadController sharedDownloadController] newDownloadTaskForDownload:self];
    [self setStatus:[downloadTask isKindOfClass:[NSURLDownload class]] ? SKDownloadStatusStarting : SKDownloadStatusDownloading];
}

- (void)cancel {
    if ([self canCancel]) {
        
        [[SKDownloadController sharedDownloadController] cancelDownloadTask:downloadTask forDownload:self];
        SKDESTROY(downloadTask);
        [self setStatus:SKDownloadStatusCanceled];
    }
}

- (void)resume {
    if ([self canResume]) {
        
        if (resumeData &&
            (usesSession || ([self status] == SKDownloadStatusCanceled && [[self fileURL] checkResourceIsReachableAndReturnError:NULL]))) {
            
            receivedResponse = NO;
            [downloadTask release];
            downloadTask = [[SKDownloadController sharedDownloadController] newDownloadTaskForDownload:self];
            SKDESTROY(resumeData);
            [self setStatus:SKDownloadStatusDownloading];
            
        } else {
            
            [self cleanup];
            [self setFileURL:nil];
            if (downloadTask) {
                [[SKDownloadController sharedDownloadController] removeDownloadTask:downloadTask];
                SKDESTROY(downloadTask);
            }
            [self start];
            
        }
    }
}

- (void)cleanup {
    [self cancel];
    if (fileURL)
        [[NSFileManager defaultManager] removeItemAtURL:[fileURL URLByDeletingLastPathComponent] error:NULL];
    SKDESTROY(resumeData);
}

- (void)moveToTrash {
    if ([self canRemove] && fileURL) {
        NSURL *folderURL = [fileURL URLByDeletingLastPathComponent];
        NSString *fileName = [fileURL lastPathComponent];
        NSInteger tag = 0;
        
        [[NSWorkspace sharedWorkspace] performFileOperation:NSWorkspaceRecycleOperation source:[folderURL path] destination:@"" files:[NSArray arrayWithObjects:fileName, nil] tag:&tag];
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

- (void)resume:(id)sender {
    if ([self canResume])
        [self resume];
}

- (void)cancelOrRemove:(id)sender {
    if ([self canCancel])
        [self cancel];
    else if ([self canRemove])
        [[SKDownloadController sharedDownloadController] removeObjectFromDownloads:self];
}

- (NSImage *)cancelImage {
    if ([self canCancel])
        return [[self class] cancelImage];
    else if ([self canRemove])
        return [[self class] deleteImage];
    else
        return nil;
}

- (NSImage *)resumeImage {
    if ([self canResume])
        return [[self class] resumeImage];
    else
        return nil;
}

- (NSString *)cancelToolTip {
    if ([self canCancel])
        return NSLocalizedString(@"Cancel download", @"Tool tip message");
    else if ([self canRemove])
        return NSLocalizedString(@"Remove download", @"Tool tip message");
    else
        return nil;
}

- (NSString *)resumeToolTip {
    if ([self canResume])
        return NSLocalizedString(@"Resume download", @"Tool tip message");
    else
        return nil;
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
    if ([[NSFileManager defaultManager] fileExistsAtPath:downloadDir isDirectory:&isDir] == NO || isDir == NO)
        downloadDir = [[[NSFileManager defaultManager] URLForDirectory:NSDownloadsDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:NULL] path];
    [download setDestination:[downloadDir stringByAppendingPathComponent:filename] allowOverwrite:YES];
}

- (void)download:(NSURLDownload *)download didCreateDestination:(NSString *)path {
    [self setFileURL:[NSURL fileURLWithPath:path]];
}

- (void)download:(NSURLDownload *)download didReceiveDataOfLength:(NSUInteger)length {
    if (expectedContentLength > 0) {
        [self setReceivedContentLength:[self receivedContentLength] + length];
    }
}

- (void)downloadDidFinish:(NSURLDownload *)download {
    SKDESTROY(downloadTask);
    [self setStatus:SKDownloadStatusFinished];
}

- (void)download:(NSURLDownload *)download didFailWithError:(NSError *)error {
    if (fileURL)
        [[NSFileManager defaultManager] removeItemAtURL:fileURL error:NULL];
    SKDESTROY(downloadTask);
    [self setFileURL:nil];
    [self setStatus:SKDownloadStatusFailed];
}

#pragma mark SKURLDownloadTaskDelegate

- (void)downloadTask:(NSURLSessionDownloadTask *)task didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    
    if ([task response] && receivedResponse == NO) {
        receivedResponse = YES;
        CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (CFStringRef)[[task response] MIMEType], kUTTypeData);
        if (UTI) {
            NSString *type = [[NSWorkspace sharedWorkspace] preferredFilenameExtensionForType:(NSString *)UTI];
            if (type)
                [self setFileIcon:[[NSWorkspace sharedWorkspace] iconForFileType:type]];
            CFRelease(UTI);
        }
    }
    
    if ([self expectedContentLength] < totalBytesExpectedToWrite)
        [self setExpectedContentLength:totalBytesExpectedToWrite];
    if (totalBytesExpectedToWrite > 0)
        [self setReceivedContentLength:totalBytesWritten];
}

- (void)downloadTask:(NSURLSessionDownloadTask *)task didFinishDownloadingToURL:(NSURL *)location {
    NSString *filename = [[task response] suggestedFilename] ?: [location lastPathComponent];
    NSString *downloadDir = [[[NSUserDefaults standardUserDefaults] stringForKey:SKDownloadsDirectoryKey] stringByExpandingTildeInPath];
    NSURL *downloadURL = nil;
    BOOL isDir;
    if ([[NSFileManager defaultManager] fileExistsAtPath:downloadDir isDirectory:&isDir] && isDir)
        downloadURL = [NSURL fileURLWithPath:downloadDir];
    else
        downloadURL = [[NSFileManager defaultManager] URLForDirectory:NSDownloadsDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:NULL];
    NSURL *destinationURL = [[downloadURL URLByAppendingPathComponent:filename] uniqueFileURL];
    NSError *error = nil;
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([[destinationURL URLByDeletingLastPathComponent] checkResourceIsReachableAndReturnError:NULL] == NO)
        [fm createDirectoryAtPath:[[destinationURL URLByDeletingLastPathComponent] path] withIntermediateDirectories:YES attributes:nil error:NULL];
    BOOL success = [fm moveItemAtURL:location toURL:destinationURL error:&error];
    [self setFileURL:success ? destinationURL : nil];
    SKDESTROY(downloadTask);
    [self setStatus:success ? SKDownloadStatusFinished : SKDownloadStatusFailed];
}

- (void)downloadTask:(NSURLSessionDownloadTask *)task didFailWithError:(NSError *)error {
    SKDESTROY(downloadTask);
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
