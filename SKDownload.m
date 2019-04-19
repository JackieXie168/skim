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

NSString *SKDownloadFileNameKey = @"fileName";
NSString *SKDownloadFileURLKey = @"fileURL";
NSString *SKDownloadStatusKey = @"status";
NSString *SKDownloadProgressIndicatorKey = @"progressIndicator";

@interface SKDownload ()
@property (nonatomic) SKDownloadStatus status;
@property (nonatomic, retain) NSURL *fileURL;
@property (nonatomic, retain) NSImage *fileIcon;
@property (nonatomic) long long expectedContentLength, receivedContentLength;
- (void)handleApplicationWillTerminateNotification:(NSNotification *)notification;
@end


@implementation SKDownload

@synthesize URL, fileURL, fileIcon, expectedContentLength, receivedContentLength, status;
@dynamic properties, fileName, statusDescription, info, hasExpectedContentLength, downloading, canCancel, canRemove, canResume, cancelImage, resumeImage, scriptingURL, scriptingStatus;

static NSSet *infoKeys = nil;

+ (void)initialize {
    SKINITIALIZE;
    infoKeys = [[NSSet alloc] initWithObjects:SKDownloadFileNameKey, SKDownloadStatusKey, SKDownloadProgressIndicatorKey, nil];
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

+ (NSSet *)keyPathsForValuesAffectingCancelImageDescription {
    return [NSSet setWithObjects:SKDownloadStatusKey, nil];
}

+ (NSSet *)keyPathsForValuesAffectingResumeImageDescription {
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
        URLDownload = nil;
        fileURL = nil;
        fileIcon = nil;
        expectedContentLength = NSURLResponseUnknownLength;
        receivedContentLength = 0;
        status = SKDownloadStatusUndefined;
        
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
        URLDownload = nil;
        if (fileURLPath)
            fileURL = [[NSURL alloc] initFileURLWithPath:fileURLPath];
        fileIcon = fileURL ? [[[NSWorkspace sharedWorkspace] iconForFileType:[fileURL pathExtension]] retain] : nil;
        expectedContentLength = [[properties objectForKey:@"expectedContentLength"] longLongValue];
        receivedContentLength = [[properties objectForKey:@"receivedContentLength"] longLongValue];
        status = [[properties objectForKey:@"status"] integerValue];
        resumeData = nil;
        if ([fileURL checkResourceIsReachableAndReturnError:NULL])
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
        [URLDownload cancel];
    SKDESTROY(URL);
    SKDESTROY(URLDownload);
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
    if ([self status] == SKDownloadStatusCanceled)
        [dict setValue:resumeData ?: [URLDownload resumeData] forKey:@"resumeData"];
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
        [resumeData release];
        resumeData = [[URLDownload resumeData] retain];
        SKDESTROY(URLDownload);
        [self setStatus:SKDownloadStatusCanceled];
    }
}

- (void)resume {
    if ([self canResume]) {
        
        if ([self status] == SKDownloadStatusCanceled && resumeData &&
            [[self fileURL] checkResourceIsReachableAndReturnError:NULL]) {
            
            [URLDownload release];
            URLDownload = [[NSURLDownload alloc] initWithResumeData:resumeData delegate:self path:[[self fileURL] path]];
            [URLDownload setDeletesFileUponFailure:NO];
            SKDESTROY(resumeData);
            [self setStatus:SKDownloadStatusDownloading];
            
        } else {
            
            [self cleanup];
            [self setFileURL:nil];
            SKDESTROY(URLDownload);
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
    }
}

- (void)downloadDidFinish:(NSURLDownload *)theDownload {
    SKDESTROY(URLDownload);
    [self setStatus:SKDownloadStatusFinished];
}

- (void)download:(NSURLDownload *)download didFailWithError:(NSError *)error {
    if (fileURL)
        [[NSFileManager defaultManager] removeItemAtURL:fileURL error:NULL];
    SKDESTROY(URLDownload);
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
