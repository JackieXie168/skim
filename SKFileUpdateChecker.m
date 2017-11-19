//
//  SKFileUpdateChecker.m
//  Skim
//
//  Created by Christiaan Hofman on 12/23/10.
/*
 This software is Copyright (c) 2010-2017
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

#define PATH_KEY @"path"

static char SKFileUpdateCheckerObservationContext;

static BOOL isURLOnHFSVolume(NSURL *fileURL);
static BOOL canUpdateFromURL(NSURL *fileURL);

@interface SKFileUpdateChecker (SKPrivate)
- (void)fileUpdated;
- (void)noteFileUpdated;
- (void)noteFileMoved;
- (void)noteFileRemoved;
@end

@implementation SKFileUpdateChecker

@dynamic enabled, fileChangedOnDisk, isUpdatingFile;

- (id)initForDocument:(NSDocument *)aDocument {
    self = [super init];
    if (self) {
        document = aDocument;
        // hidden pref to always auto update without first asking the user
        memset(&fucFlags, 0, sizeof(fucFlags));
        fucFlags.autoUpdate = [[NSUserDefaults standardUserDefaults] boolForKey:SKAutoReloadFileUpdateKey];
        [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKey:SKAutoCheckFileUpdateKey context:&SKFileUpdateCheckerObservationContext];
        [document addObserver:self forKeyPath:@"fileURL" options:0 context:&SKFileUpdateCheckerObservationContext];
    }
    return self;
}

- (void)dealloc {
    @try { [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKey:SKAutoCheckFileUpdateKey]; }
    @catch (id) {}
    document = nil;
    [super dealloc];
}

- (void)terminate {
    [self stop];
    @try { [document removeObserver:self forKeyPath:@"fileURL"]; }
    @catch (id) {}
    document = nil;
}

- (void)stop {
    // remove file monitor and invalidate timer; maybe we've changed filesystems
    if (source) {
        dispatch_source_cancel(source);
        SKDISPATCHDESTROY(source);
    }
    if (fileUpdateTimer) {
        [fileUpdateTimer invalidate];
        SKDESTROY(fileUpdateTimer);
    }
    fucFlags.fileWasMoved = NO;
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

- (void)checkForFileReplacement:(NSTimer *)timer {
    if ([[document fileURL] checkResourceIsReachableAndReturnError:NULL]) {
        // the deleted file was replaced at the old path, restart the file updating for the replacement file and note the update
        [self reset];
        [self noteFileUpdated];
    }
}

- (void)startTimerWithSelector:(SEL)aSelector {
    fileUpdateTimer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:0.1] interval:2.0 target:self selector:aSelector userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:fileUpdateTimer forMode:NSDefaultRunLoopMode];
}

- (void)reset {
    [self stop];
    NSURL *fileURL = [document fileURL];
    if (fileURL) {
        if (fucFlags.enabled && [[NSUserDefaults standardUserDefaults] boolForKey:SKAutoCheckFileUpdateKey]) {
            
            // AFP, NFS, SMB etc. don't support kqueues, so we have to manually poll and compare mod dates
            if (isURLOnHFSVolume(fileURL)) {
                int fd = open([[fileURL path] fileSystemRepresentation], O_EVTONLY);
                
                if (fd >= 0) {
                    dispatch_queue_t queue = dispatch_get_main_queue();
                    source = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE, fd, DISPATCH_VNODE_DELETE | DISPATCH_VNODE_RENAME | DISPATCH_VNODE_WRITE, queue);
                    
                    if (source) {
                        
                        dispatch_source_set_event_handler(source, ^{
                            unsigned long flags = dispatch_source_get_data(source);
                            if ((flags & DISPATCH_VNODE_DELETE))
                                [self noteFileRemoved];
                            else if ((flags & DISPATCH_VNODE_RENAME))
                                [self noteFileMoved];
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
                // Use a fairly long delay since this is likely a network volume.
                [self startTimerWithSelector:@selector(checkForFileModification:)];
            }
        }
    }
}

- (void)fileUpdateAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    
    if (returnCode == NSAlertSecondButtonReturn) {
        // if we don't reload now, we should not do it automatically next
        fucFlags.autoUpdate = NO;
    } else {
        // should we reset autoUpdate to YES on NSAlertFirstButtonReturn when SKAutoReloadFileUpdateKey is set?
        if (returnCode == NSAlertThirdButtonReturn)
            fucFlags.autoUpdate = YES;
        
        [[alert window] orderOut:nil];
        NSError *error = nil;
        BOOL didRevert = [document revertToContentsOfURL:[document fileURL] ofType:[document fileType] error:&error];
        if (didRevert == NO && error != nil && [error isUserCancelledError] == NO)
            [document presentError:error modalForWindow:[document windowForSheet] delegate:nil didPresentSelector:NULL contextInfo:NULL];
        
        if (didRevert == NO && fucFlags.fileWasUpdated)
            [self performSelector:@selector(fileUpdated) withObject:nil afterDelay:0.0];
    }
    fucFlags.isUpdatingFile = NO;
    fucFlags.fileWasUpdated = NO;
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
    
    if (fucFlags.enabled &&
        [[NSUserDefaults standardUserDefaults] boolForKey:SKAutoCheckFileUpdateKey] &&
        [fileURL checkResourceIsReachableAndReturnError:NULL]) {
        
        fucFlags.fileChangedOnDisk = YES;
        
        fucFlags.isUpdatingFile = YES;
        fucFlags.fileWasUpdated = NO;
        
        NSWindow *docWindow = [document windowForSheet];
        
        // check for attached sheet, since reloading the document while an alert is up looks a bit strange
        if ([docWindow attachedSheet]) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleWindowDidEndSheetNotification:) 
                                                         name:NSWindowDidEndSheetNotification object:docWindow];
        } else if (canUpdateFromURL(fileURL)) {
            BOOL documentHasEdits = [document isDocumentEdited] || [[document notes] count] > 0;
            if (fucFlags.autoUpdate && documentHasEdits == NO) {
                // tried queuing this with a delayed perform/cancel previous, but revert takes long enough that the cancel was never used
                [self fileUpdateAlertDidEnd:nil returnCode:NSAlertFirstButtonReturn contextInfo:NULL];
            } else {
                NSString *message;
                if (documentHasEdits)
                    message = NSLocalizedString(@"The PDF file has changed on disk. If you reload, your changes will be lost. Do you want to reload this document now?", @"Informative text in alert dialog");
                else if (fucFlags.autoUpdate)
                    message = NSLocalizedString(@"The PDF file has changed on disk. Do you want to reload this document now?", @"Informative text in alert dialog");
                else
                    message = NSLocalizedString(@"The PDF file has changed on disk. Do you want to reload this document now? Choosing Auto will reload this file automatically for future changes.", @"Informative text in alert dialog");
                
                NSAlert *alert = [[[NSAlert alloc] init] autorelease];
                [alert setMessageText:NSLocalizedString(@"File Updated", @"Message in alert dialog")];
                [alert setInformativeText:message];
                [alert addButtonWithTitle:NSLocalizedString(@"Yes", @"Button title")];
                [alert addButtonWithTitle:NSLocalizedString(@"No", @"Button title")];
                if (fucFlags.autoUpdate == NO)
                    [alert addButtonWithTitle:NSLocalizedString(@"Auto", @"Button title")];
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
    if (fucFlags.fileWasMoved == NO) {
        if (fucFlags.isUpdatingFile)
            fucFlags.fileWasUpdated = YES;
        else
            [self fileUpdated];
    }
}

- (void)noteFileMoved {
    // If the file is moved, NSDocument will notice and will call setFileURL, where we start watching again
    // unless the file is deleted before NSDocument notices, in which case we can treat this as just deleting the file
    // but as long as neither happens we will ignore updates, as we cannot know which file NSDocument will think it has
    fucFlags.fileChangedOnDisk = YES;
    fucFlags.fileWasMoved = YES;
}

- (void)noteFileRemoved {
    [self stop];
    fucFlags.fileChangedOnDisk = YES;
    // poll the (old) path to see whether the deleted file will be replaced
    [self startTimerWithSelector:@selector(checkForFileReplacement:)];
}

- (void)setEnabled:(BOOL)flag {
    if (fucFlags.enabled != flag) {
        fucFlags.enabled = flag;
        [self reset];
    }
}

- (BOOL)isEnabled {
    return fucFlags.enabled;
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
    if (context == &SKFileUpdateCheckerObservationContext)
        [self reset];
    else
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

@end


static BOOL isURLOnHFSVolume(NSURL *fileURL) {
    BOOL isHFSVolume = NO;
    FSRef fileRef;
    
    if (CFURLGetFSRef((CFURLRef)fileURL, &fileRef)) {
        OSStatus err;
        FSCatalogInfo fileInfo;
        err = FSGetCatalogInfo(&fileRef, kFSCatInfoVolume, &fileInfo, NULL, NULL, NULL);
    
        FSVolumeInfo volInfo;
        if (noErr == err) {
            err = FSGetVolumeInfo(fileInfo.volume, 0, NULL, kFSVolInfoFSInfo, &volInfo, NULL, NULL);
            
            if (noErr == err)
                // HFS and HFS+ are documented to have zero for filesystemID; AFP at least is non-zero
                isHFSVolume = (0 == volInfo.filesystemID);
        }
    }
    return isHFSVolume;
}

static BOOL canUpdateFromURL(NSURL *fileURL) {
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
