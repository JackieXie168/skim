//
//  SKFileUpdateChecker.m
//  Skim
//
//  Created by Christiaan Hofman on 12/23/10.
/*
 This software is Copyright (c) 2010-2012
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

#import "SKFileUpdateChecker.h"
#import "UKKQueue.h"
#import "SKStringConstants.h"
#import "NSDocument_SKExtensions.h"
#import "NSData_SKExtensions.h"
#import <SkimNotes/SkimNotes.h>
#import "NSUserDefaultsController_SKExtensions.h"
#import "NSString_SKExtensions.h"
#import "NSError_SKExtensions.h"

#define SKAutoReloadFileUpdateKey @"SKAutoReloadFileUpdate"

#define PATH_KEY @"path"

static char SKFileUpdateCheckerDefaultsObservationContext;

@interface SKFileUpdateChecker (SKPrivate)
- (void)fileUpdated;
- (void)handleFileUpdateNotification:(NSNotification *)notification;
- (void)handleFileMoveNotification:(NSNotification *)notification;
- (void)handleFileDeleteNotification:(NSNotification *)notification;
- (void)handleWindowDidEndSheetNotification:(NSNotification *)notification;
@end

@implementation SKFileUpdateChecker

@synthesize document;
@dynamic fileChangedOnDisk, isUpdatingFile;

- (id)initForDocument:(NSDocument *)aDocument {
    self = [super init];
    if (self) {
        document = aDocument;
        [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKey:SKAutoCheckFileUpdateKey context:&SKFileUpdateCheckerDefaultsObservationContext];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    @try { [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKey:SKAutoCheckFileUpdateKey]; }
    @catch (id) {}
    document = nil;
    [super dealloc];
}

- (void)stopCheckingFileUpdates {
    if (watchedFile) {
        // remove from kqueue and invalidate timer; maybe we've changed filesystems
        UKKQueue *kQueue = [UKKQueue sharedFileWatcher];
        [kQueue removePath:watchedFile];
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc removeObserver:self name:UKFileWatcherWriteNotification object:kQueue];
        [nc removeObserver:self name:UKFileWatcherRenameNotification object:kQueue];
        [nc removeObserver:self name:UKFileWatcherDeleteNotification object:kQueue];
        SKDESTROY(watchedFile);
    }
    if (fileUpdateTimer) {
        [fileUpdateTimer invalidate];
        fileUpdateTimer = nil;
    }
}

static BOOL isFileOnHFSVolume(NSString *fileName)
{
    FSRef fileRef;
    OSStatus err;
    err = FSPathMakeRef((const UInt8 *)[fileName fileSystemRepresentation], &fileRef, NULL);
    
    FSCatalogInfo fileInfo;
    if (noErr == err)
        err = FSGetCatalogInfo(&fileRef, kFSCatInfoVolume, &fileInfo, NULL, NULL, NULL);
    
    FSVolumeInfo volInfo;
    if (noErr == err)
        err = FSGetVolumeInfo(fileInfo.volume, 0, NULL, kFSVolInfoFSInfo, &volInfo, NULL, NULL);
    
    // HFS and HFS+ are documented to have zero for filesystemID; AFP at least is non-zero
    BOOL isHFSVolume = (noErr == err) ? (0 == volInfo.filesystemID) : NO;
    
    return isHFSVolume;
}

- (void)checkForFileModification:(NSTimer *)timer {
    NSDate *currentFileModifiedDate = [[[NSFileManager defaultManager] attributesOfItemAtPath:[[document fileURL] path] error:NULL] fileModificationDate];
    if (nil == lastModifiedDate) {
        lastModifiedDate = [currentFileModifiedDate copy];
    } else if ([lastModifiedDate compare:currentFileModifiedDate] == NSOrderedAscending) {
        // Always reset mod date to prevent repeating messages; note that the kqueue also notifies only once
        [lastModifiedDate release];
        lastModifiedDate = [currentFileModifiedDate copy];
        [self handleFileUpdateNotification:nil];
    }
}

- (void)checkFileUpdatesIfNeeded {
    NSString *fileName = [[document fileURL] path];
    if (fileName) {
        [self stopCheckingFileUpdates];
        if ([[NSUserDefaults standardUserDefaults] boolForKey:SKAutoCheckFileUpdateKey]) {
            
            // AFP, NFS, SMB etc. don't support kqueues, so we have to manually poll and compare mod dates
            if (isFileOnHFSVolume(fileName)) {
                watchedFile = [fileName retain];
                
                UKKQueue *kQueue = [UKKQueue sharedFileWatcher];
                [kQueue addPath:watchedFile];
                NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
                [nc addObserver:self selector:@selector(handleFileUpdateNotification:) name:UKFileWatcherWriteNotification object:kQueue];
                [nc addObserver:self selector:@selector(handleFileMoveNotification:) name:UKFileWatcherRenameNotification object:kQueue];
                [nc addObserver:self selector:@selector(handleFileDeleteNotification:) name:UKFileWatcherDeleteNotification object:kQueue];
            } else if (nil == fileUpdateTimer) {
                // Let the runloop retain the timer; timer retains us.  Use a fairly long delay since this is likely a network volume.
                fileUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:(double)2.0 target:self selector:@selector(checkForFileModification:) userInfo:nil repeats:YES];
            }
        }
    }
}

- (BOOL)revertDocument {
    NSError *error = nil;
    BOOL didRevert = [document revertToContentsOfURL:[document fileURL] ofType:[document fileType] error:&error];
    if (didRevert == NO && error != nil && [error isUserCancelledError] == NO)
        [document presentError:error modalForWindow:[document windowForSheet] delegate:nil didPresentSelector:NULL contextInfo:NULL];
    return didRevert;
}

- (void)fileUpdateAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    
    if (returnCode == NSAlertOtherReturn) {
        fucFlags.autoUpdate = NO;
        fucFlags.disableAutoReload = YES;
    } else {
        [[alert window] orderOut:nil];
        
        if ([self revertDocument])
            fucFlags.receivedFileUpdateNotification = NO;
        if (returnCode == NSAlertAlternateReturn)
            fucFlags.autoUpdate = YES;
        fucFlags.disableAutoReload = NO;
        if (fucFlags.receivedFileUpdateNotification)
            [self performSelector:@selector(fileUpdated) withObject:nil afterDelay:0.0];
    }
    fucFlags.isUpdatingFile = NO;
    fucFlags.receivedFileUpdateNotification = NO;
}

- (BOOL)canUpdateFromFile:(NSString *)fileName {
    NSString *extension = [fileName pathExtension];
    BOOL isDVI = NO;
    if (extension) {
        NSWorkspace *ws = [NSWorkspace sharedWorkspace];
        NSString *theUTI = [ws typeOfFile:[[fileName stringByStandardizingPath] stringByResolvingSymlinksInPath] error:NULL];
        if ([extension isCaseInsensitiveEqual:@"pdfd"] || [ws type:theUTI conformsToType:@"net.sourceforge.skim-app.pdfd"]) {
            fileName = [[NSFileManager defaultManager] bundledFileWithExtension:@"pdf" inPDFBundleAtPath:fileName error:NULL];
            if (fileName == nil)
                return NO;
        } else if ([extension isCaseInsensitiveEqual:@"dvi"] || [extension isCaseInsensitiveEqual:@"xdv"]) {
            isDVI = YES;
        }
    }
    
    NSFileHandle *fh = [NSFileHandle fileHandleForReadingAtPath:fileName];
    
    // read the last 1024 bytes of the file (or entire file); Adobe's spec says they allow %%EOF anywhere in that range
    unsigned long long fileEnd = [fh seekToEndOfFile];
    unsigned long long startPos = fileEnd < 1024 ? 0 : fileEnd - 1024;
    [fh seekToFileOffset:startPos];
    NSData *trailerData = [fh readDataToEndOfFile];
    NSRange range = NSMakeRange(0, [trailerData length]);
    NSData *pattern = [NSData dataWithBytes:"%%EOF" length:5];
    NSDataSearchOptions options = NSDataSearchBackwards;
    
    if (isDVI) {
        const char bytes[4] = {0xDF, 0xDF, 0xDF, 0xDF};
        pattern = [NSData dataWithBytes:bytes length:4];
        options |= NSDataSearchAnchored;
    }
    return NSNotFound != [trailerData rangeOfData:pattern options:options range:range].location;
}

- (void)fileUpdated {
    NSString *fileName = [[document fileURL] path];
    
    // should never happen
    if (fucFlags.isUpdatingFile)
        NSLog(@"*** already busy updating file %@", fileName);
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKAutoCheckFileUpdateKey] &&
        [[NSFileManager defaultManager] fileExistsAtPath:fileName]) {
        
        fucFlags.fileChangedOnDisk = YES;
        
        fucFlags.isUpdatingFile = YES;
        fucFlags.receivedFileUpdateNotification = NO;
        
        NSWindow *docWindow = [document windowForSheet];
        
        // check for attached sheet, since reloading the document while an alert is up looks a bit strange
        if ([docWindow attachedSheet]) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleWindowDidEndSheetNotification:) 
                                                         name:NSWindowDidEndSheetNotification object:docWindow];
        } else if ([self canUpdateFromFile:fileName]) {
            BOOL shouldAutoUpdate = fucFlags.autoUpdate || [[NSUserDefaults standardUserDefaults] boolForKey:SKAutoReloadFileUpdateKey];
            BOOL documentHasEdits = [document isDocumentEdited] || [[document notes] count] > 0;
            if (fucFlags.disableAutoReload == NO && shouldAutoUpdate && documentHasEdits == NO) {
                // tried queuing this with a delayed perform/cancel previous, but revert takes long enough that the cancel was never used
                [self fileUpdateAlertDidEnd:nil returnCode:NSAlertDefaultReturn contextInfo:NULL];
            } else {
                NSString *message;
                if (documentHasEdits)
                    message = NSLocalizedString(@"The PDF file has changed on disk. If you reload, your changes will be lost. Do you want to reload this document now?", @"Informative text in alert dialog");
                else 
                    message = NSLocalizedString(@"The PDF file has changed on disk. Do you want to reload this document now? Choosing Auto will reload this file automatically for future changes.", @"Informative text in alert dialog");
                
                NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"File Updated", @"Message in alert dialog") 
                                                 defaultButton:NSLocalizedString(@"Yes", @"Button title")
                                               alternateButton:NSLocalizedString(@"Auto", @"Button title")
                                                   otherButton:NSLocalizedString(@"No", @"Button title")
                                     informativeTextWithFormat:message];
                [alert beginSheetModalForWindow:docWindow
                                  modalDelegate:self
                                 didEndSelector:@selector(fileUpdateAlertDidEnd:returnCode:contextInfo:) 
                                    contextInfo:NULL];
            }
        } else {
            fucFlags.isUpdatingFile = NO;
            fucFlags.receivedFileUpdateNotification = NO;
        }
    } else {
        fucFlags.isUpdatingFile = NO;
        fucFlags.receivedFileUpdateNotification = NO;
    }
}

- (void)handleFileUpdateNotification:(NSNotification *)notification {
    NSString *path = [[notification userInfo] objectForKey:PATH_KEY];
    
    if ([watchedFile isEqualToString:path] || notification == nil) {
        // should never happen
        if (notification && [path isEqualToString:[[document fileURL] path]] == NO)
            NSLog(@"*** received change notice for %@", path);
        
        if (fucFlags.isUpdatingFile)
            fucFlags.receivedFileUpdateNotification = YES;
        else
            [self fileUpdated];
    }
}

- (void)handleFileMoveNotification:(NSNotification *)notification {
    if ([watchedFile isEqualToString:[[notification userInfo] objectForKey:PATH_KEY]])
        [self stopCheckingFileUpdates];
    // If the file is moved, NSDocument will notice and will call setFileURL, where we start watching again
    fucFlags.fileChangedOnDisk = YES;
}

- (void)handleFileDeleteNotification:(NSNotification *)notification {
    if ([watchedFile isEqualToString:[[notification userInfo] objectForKey:PATH_KEY]])
        [self stopCheckingFileUpdates];
    fucFlags.fileChangedOnDisk = YES;
}

- (void)handleWindowDidEndSheetNotification:(NSNotification *)notification {
    // This is only called to delay a file update handling
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidEndSheetNotification object:[notification object]];
    // Make sure we finish the sheet event first. E.g. the documentEdited status may need to be updated.
    [self performSelector:@selector(fileUpdated) withObject:nil afterDelay:0.0];
}


- (BOOL)fileChangedOnDisk {
    return fucFlags.fileChangedOnDisk;
}

- (BOOL)isUpdatingFile {
    return fucFlags.isUpdatingFile;
}

- (void)didUpdateFromURL:(NSURL *)fileURL {
    fucFlags.fileChangedOnDisk = NO;
    [lastModifiedDate release];
    lastModifiedDate = [[[[NSFileManager defaultManager] attributesOfItemAtPath:[fileURL path] error:NULL] fileModificationDate] retain];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == &SKFileUpdateCheckerDefaultsObservationContext)
        [self checkFileUpdatesIfNeeded];
    else
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

@end
