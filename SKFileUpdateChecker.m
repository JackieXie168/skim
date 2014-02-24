//
//  SKFileUpdateChecker.m
//  Skim
//
//  Created by Christiaan Hofman on 12/23/10.
/*
 This software is Copyright (c) 2010-2014
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
- (void)noteFileUpdated;
- (void)noteFileRemoved;
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
    @try { [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKey:SKAutoCheckFileUpdateKey]; }
    @catch (id) {}
    document = nil;
    [super dealloc];
}

- (void)stopCheckingFileUpdates {
    // remove file monitor and invalidate timer; maybe we've changed filesystems
    if (source) {
        dispatch_source_cancel(source);
        SKDISPATCHDESTROY(source);
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
        [self noteFileUpdated];
    }
}

- (void)checkFileUpdatesIfNeeded {
    NSString *fileName = [[document fileURL] path];
    if (fileName) {
        [self stopCheckingFileUpdates];
        if ([[NSUserDefaults standardUserDefaults] boolForKey:SKAutoCheckFileUpdateKey]) {
            
            // AFP, NFS, SMB etc. don't support kqueues, so we have to manually poll and compare mod dates
            if (isFileOnHFSVolume(fileName)) {
                int fd = open([fileName fileSystemRepresentation], O_EVTONLY);
                
                if (fd >= 0) {
                    dispatch_queue_t queue = dispatch_get_main_queue();
                    source = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE, fd, DISPATCH_VNODE_DELETE | DISPATCH_VNODE_RENAME | DISPATCH_VNODE_WRITE, queue);
                    
                    if (source) {
                        
                        dispatch_source_set_event_handler(source, ^{
                            unsigned long flags = dispatch_source_get_data(source);
                            if ((flags & (DISPATCH_VNODE_DELETE | DISPATCH_VNODE_RENAME)))
                                [self noteFileRemoved];
                            else if ((flags & DISPATCH_VNODE_WRITE))
                                [self noteFileUpdated];
                        });
                        
                        dispatch_source_set_cancel_handler(source, ^{ close(fd); });
                        
                        dispatch_resume(source);
                        
                    } else {
                        close(fd);
                    }
                }
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
            fucFlags.fileWasUpdated = NO;
        if (returnCode == NSAlertAlternateReturn)
            fucFlags.autoUpdate = YES;
        fucFlags.disableAutoReload = NO;
        if (fucFlags.fileWasUpdated)
            [self performSelector:@selector(fileUpdated) withObject:nil afterDelay:0.0];
    }
    fucFlags.isUpdatingFile = NO;
    fucFlags.fileWasUpdated = NO;
}

- (BOOL)canUpdateFromURL:(NSURL *)fileURL {
    NSString *extension = [fileURL pathExtension];
    BOOL isDVI = NO;
    if (extension) {
        NSWorkspace *ws = [NSWorkspace sharedWorkspace];
        NSString *theUTI = [ws typeOfFile:[[[fileURL URLByStandardizingPath] URLByResolvingSymlinksInPath] path] error:NULL];
        if ([extension isCaseInsensitiveEqual:@"pdfd"] || [ws type:theUTI conformsToType:@"net.sourceforge.skim-app.pdfd"]) {
            fileURL = [[NSFileManager defaultManager] bundledFileURLWithExtension:@"pdf" inPDFBundleAtURL:fileURL error:NULL];
            if (fileURL == nil)
                return NO;
        } else if ([extension isCaseInsensitiveEqual:@"dvi"] || [extension isCaseInsensitiveEqual:@"xdv"]) {
            isDVI = YES;
        }
    }
    
    NSFileHandle *fh = [NSFileHandle fileHandleForReadingFromURL:fileURL error:NULL];
    
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

- (void)handleWindowDidEndSheetNotification:(NSNotification *)notification {
    // This is only called to delay a file update handling
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidEndSheetNotification object:[notification object]];
    // Make sure we finish the sheet event first. E.g. the documentEdited status may need to be updated.
    [self performSelector:@selector(fileUpdated) withObject:nil afterDelay:0.0];
}

- (void)fileUpdated {
    NSURL *fileURL = [document fileURL];
    
    // should never happen
    if (fucFlags.isUpdatingFile)
        NSLog(@"*** already busy updating file %@", [fileURL path]);
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKAutoCheckFileUpdateKey] &&
        [fileURL checkResourceIsReachableAndReturnError:NULL]) {
        
        fucFlags.fileChangedOnDisk = YES;
        
        fucFlags.isUpdatingFile = YES;
        fucFlags.fileWasUpdated = NO;
        
        NSWindow *docWindow = [document windowForSheet];
        
        // check for attached sheet, since reloading the document while an alert is up looks a bit strange
        if ([docWindow attachedSheet]) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleWindowDidEndSheetNotification:) 
                                                         name:NSWindowDidEndSheetNotification object:docWindow];
        } else if ([self canUpdateFromURL:fileURL]) {
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
            fucFlags.fileWasUpdated = NO;
        }
    } else {
        fucFlags.isUpdatingFile = NO;
        fucFlags.fileWasUpdated = NO;
    }
}

- (void)noteFileUpdated {
    if (fucFlags.isUpdatingFile)
        fucFlags.fileWasUpdated = YES;
    else
        [self fileUpdated];
}

- (void)noteFileRemoved {
    [self stopCheckingFileUpdates];
    // If the file is moved, NSDocument will notice and will call setFileURL, where we start watching again
    fucFlags.fileChangedOnDisk = YES;
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
