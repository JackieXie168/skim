//
//  SKDownloadController.h
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

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import "SKWindowController.h"
#import "SKTableView.h"
#import "NSTouchBar_SKForwardDeclarations.h"


@class SKDownload, NSURLSession;

@interface SKDownloadController : SKWindowController <SKTableViewDelegate, NSTableViewDataSource, NSToolbarDelegate, QLPreviewPanelDelegate, QLPreviewPanelDataSource, NSTouchBarDelegate> {
    SKTableView *tableView;
    NSButton *clearButton;
    NSButton *tbClearButton;
    NSButton *resumeButton;
    NSButton *cancelButton;
    NSButton *removeButton;
    NSMutableArray *downloads;
    NSURLSession *session;
    NSMapTable *delegates;
    NSMutableDictionary *touchBarItems;
}

@property (nonatomic, retain) IBOutlet SKTableView *tableView;
@property (nonatomic, retain) IBOutlet NSButton *clearButton;

+ (id)sharedDownloadController;

- (SKDownload *)addDownloadForURL:(NSURL *)aURL;

- (void)removeObjectFromDownloads:(SKDownload *)download;

- (IBAction)showDownloadPreferences:(id)sender;
- (IBAction)clearDownloads:(id)sender;

- (IBAction)moveToTrash:(id)sender;

- (NSArray *)downloads;
- (NSUInteger)countOfDownloads;
- (SKDownload *)objectInDownloadsAtIndex:(NSUInteger)anIndex;
- (void)insertObject:(SKDownload *)download inDownloadsAtIndex:(NSUInteger)anIndex;
- (void)removeObjectFromDownloadsAtIndex:(NSUInteger)anIndex;

// these notify and animate, so should be used to add/remove downloads
- (void)addObjectToDownloads:(SKDownload *)download;
- (void)removeObjectFromDownloads:(SKDownload *)download;
- (void)removeObjectsFromDownloadsAtIndexes:(NSIndexSet *)indexes;

- (void)setupToolbar;

- (id)newDownloadTaskForDownload:(SKDownload *)download;
- (void)cancelDownloadTask:(id)task forDownload:(SKDownload *)download;
- (void)removeDownloadTask:(id)task;

@end

@class NSURLSessionDownloadTask;

@protocol SKURLDownloadTaskDelegate <NSObject>

@optional

- (void)downloadTask:(NSURLSessionDownloadTask *)task didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite;
- (void)downloadTask:(NSURLSessionDownloadTask *)task didFinishDownloadingToURL:(NSURL *)location;
- (void)downloadTask:(NSURLSessionDownloadTask *)task didFailWithError:(NSError *)error;

@end
