//
//  SKDownloadController.m
//  Skim
//
//  Created by Christiaan Hofman on 8/11/07.
/*
 This software is Copyright (c) 2007-2008
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

#import "SKDownloadController.h"
#import "SKDownload.h"
#import "SKProgressCell.h"
#import "NSURL_SKExtensions.h"
#import "SKStringConstants.h"
#import "SKTableView.h"
#import "SKTypeSelectHelper.h"
#import "NSString_SKExtensions.h"
#import "NSMenu_SKExtensions.h"

static NSString *SKDownloadsWindowFrameAutosaveName = @"SKDownloadsWindow";

static NSString *SKDownloadControllerDownloadsKey = @"downloads";

static NSString *SKDownloadsWindowCancelColumnIdentifier = @"cancel";
static NSString *SKDownloadsWindowResumeColumnIdentifier = @"resume";

@implementation SKDownloadController

static SKDownloadController *sharedDownloadController = nil;

+ (id)sharedDownloadController {
    return sharedDownloadController ?: [[self alloc] init];
}

+ (id)allocWithZone:(NSZone *)zone {
    return sharedDownloadController ?: [super allocWithZone:zone];
}

- (id)init {
    if (sharedDownloadController == nil && (sharedDownloadController = self = [super initWithWindowNibName:@"DownloadsWindow"])) {
        downloads = [[NSMutableArray alloc] init];
    }
    return sharedDownloadController;
}

- (void)dealloc {
    [downloads release];
    [super dealloc];
}

- (id)retain { return self; }

- (id)autorelease { return self; }

- (void)release {}

- (unsigned)retainCount { return UINT_MAX; }

- (void)updateClearButton {
    [clearButton setEnabled:[downloads count] > 0 && [[downloads valueForKeyPath:@"@min.canCancel"] boolValue] == NO];
}

- (void)windowDidLoad {
    [self setWindowFrameAutosaveName:SKDownloadsWindowFrameAutosaveName];
    
    [self updateClearButton];
    
    SKTypeSelectHelper *typeSelectHelper = [[[SKTypeSelectHelper alloc] init] autorelease];
    [typeSelectHelper setDataSource:self];
    [tableView setTypeSelectHelper:typeSelectHelper];
    
    [tableView registerForDraggedTypes:[NSArray arrayWithObjects:NSURLPboardType, SKWeblocFilePboardType, NSStringPboardType, nil]];
}

- (void)addDownloadForURL:(NSURL *)aURL {
    if (aURL) {
        SKDownload *download = [[[SKDownload alloc] initWithURL:aURL delegate:self] autorelease];
        int row = [self countOfDownloads];
        [[self mutableArrayValueForKey:SKDownloadControllerDownloadsKey] addObject:download];
        [download start];
        [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
        [tableView scrollRowToVisible:row];
    }
}

#pragma mark Accessors

- (NSArray *)downloads {
    return [[downloads copy] autorelease];
}

- (unsigned int)countOfDownloads {
    return [downloads count];
}

- (SKDownload *)objectInDownloadsAtIndex:(unsigned int)anIndex {
    return [downloads objectAtIndex:anIndex];
}

- (void)insertObject:(SKDownload *)download inDownloadsAtIndex:(unsigned int)anIndex {
    [downloads insertObject:download atIndex:anIndex];
    [downloads makeObjectsPerformSelector:@selector(removeProgressIndicatorFromSuperview)];
    [tableView reloadData];
}

- (void)removeObjectFromDownloadsAtIndex:(unsigned int)anIndex {
    SKDownload *download = [downloads objectAtIndex:anIndex];
    [download setDelegate:nil];
    [download cancel];
    [downloads removeObjectAtIndex:anIndex];
    [downloads makeObjectsPerformSelector:@selector(removeProgressIndicatorFromSuperview)];
    [tableView reloadData];
}

#pragma mark Actions

- (IBAction)clearDownloads:(id)sender {
    int i = [self countOfDownloads];
    
    while (i-- > 0) {
        SKDownload *download = [self objectInDownloadsAtIndex:i];
        if ([download status] != SKDownloadStatusDownloading)
            [self removeObjectFromDownloadsAtIndex:i];
    }
}

- (IBAction)cancelDownload:(id)sender {
    SKDownload *download = [sender respondsToSelector:@selector(representedObject)] ? [sender representedObject] : nil;
    
    if (download == nil) {
        int row = [tableView clickedRow];
        if (row != -1)
            download = [self objectInDownloadsAtIndex:row];
    }
    if (download && [download status] == SKDownloadStatusDownloading)
        [download cancel];
}

- (IBAction)resumeDownload:(id)sender {
    SKDownload *download = [sender respondsToSelector:@selector(representedObject)] ? [sender representedObject] : nil;
    
    if (download == nil) {
        int row = [tableView clickedRow];
        if (row != -1)
            download = [self objectInDownloadsAtIndex:row];
    }
    if (download && [download status] == SKDownloadStatusCanceled)
        [download resume];
}

- (IBAction)removeDownload:(id)sender {
    SKDownload *download = [sender respondsToSelector:@selector(representedObject)] ? [sender representedObject] : nil;
    
    if (download == nil) {
        int row = [tableView clickedRow];
        if (row != -1)
            download = [self objectInDownloadsAtIndex:row];
    }
    
    if (download)
        [[self mutableArrayValueForKey:SKDownloadControllerDownloadsKey] removeObject:download];
}

- (IBAction)paste:(id)sender {
    NSPasteboard *pboard = [NSPasteboard generalPasteboard];
    NSURL *theURL = [NSURL URLFromPasteboardAnyType:pboard];
    
    if ([theURL isFileURL])
        [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:theURL display:YES error:NULL];
    else if (theURL)
        [self addDownloadForURL:theURL];
}

- (IBAction)showDownloadPreferences:(id)sender {
    [NSApp beginSheet:preferencesSheet modalForWindow:[self window] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
}

- (IBAction)dismissDownloadsPreferences:(id)sender {
    [NSApp endSheet:preferencesSheet returnCode:[sender tag]];
    [preferencesSheet orderOut:self];
}

- (void)openDownloadedFile:(id)sender {
    SKDownload *download = [sender representedObject];
    
    if (download && [download status] != SKDownloadStatusFinished) {
        NSBeep();
    } else {
        NSURL *fileURL = [NSURL fileURLWithPath:[download filePath]];
        NSError *error;
        if (nil == [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:fileURL display:YES error:&error])
            [NSApp presentError:error];
    }
}

- (void)revealDownloadedFile:(id)sender {
    SKDownload *download = [sender representedObject];
    
    if (download && [download status] != SKDownloadStatusFinished) {
        NSBeep();
    } else {
        [[NSWorkspace sharedWorkspace] selectFile:[download filePath] inFileViewerRootedAtPath:nil];
    }
}

- (void)trashDownloadedFile:(id)sender {
    SKDownload *download = [sender representedObject];
    
    if (download && [download status] != SKDownloadStatusFinished) {
        NSBeep();
    } else {
        NSString *filePath = [download filePath];
        NSString *folderPath = [filePath stringByDeletingLastPathComponent];
        NSString *fileName = [filePath lastPathComponent];
        int tag = 0;
        
        [[NSWorkspace sharedWorkspace] performFileOperation:NSWorkspaceRecycleOperation source:folderPath destination:nil files:[NSArray arrayWithObjects:fileName, nil] tag:&tag];
    }
}

#pragma mark SKDownloadDelegate

- (void)downloadDidUpdate:(SKDownload *)download {
    unsigned int row = [downloads indexOfObject:download];
    if (row != NSNotFound)
        [tableView setNeedsDisplayInRect:[tableView rectOfRow:row]];
    [self updateClearButton];
}

- (void)downloadDidStart:(SKDownload *)download {
    [self downloadDidUpdate:download];
}

- (void)downloadDidEnd:(SKDownload *)download {
    if ([download status] == SKDownloadStatusFinished) {
        NSURL *URL = [NSURL fileURLWithPath:[download filePath]];
        NSError *error = nil;
        id document = [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:URL display:YES error:&error];
        if (document == nil)
            [NSApp presentError:error];
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:SKAutoRemoveFinishedDownloadsKey]) {
            [[download retain] autorelease];
            [[self mutableArrayValueForKey:SKDownloadControllerDownloadsKey] removeObject:download];
            // for the document to note that the file has been deleted
            [document setFileURL:[NSURL fileURLWithPath:[download filePath]]];
            if ([self countOfDownloads] == 0 && [[NSUserDefaults standardUserDefaults] boolForKey:SKAutoCloseDownloadsWindowKey])
                [[self window] close];
        } else {
            [self downloadDidUpdate:download];
        }
    } else {
        [self downloadDidUpdate:download];
    }
}

#pragma mark NSTableViewDataSource

- (int)numberOfRowsInTableView:(NSTableView *)tv { return 0; }

- (id)tableView:(NSTableView *)tv objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row { return nil; }

- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op {
    NSPasteboard *pboard = [info draggingPasteboard];
    NSString *type = [pboard availableTypeFromArray:[NSArray arrayWithObjects:NSURLPboardType, SKWeblocFilePboardType, NSStringPboardType, nil]];
    
    if (type) {
        [tv setDropRow:-1 dropOperation:NSTableViewDropOn];
        return NSDragOperationEvery;
    }
    return NSDragOperationNone;
}
       
- (BOOL)tableView:(NSTableView*)tv acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)op {
    NSPasteboard *pboard = [info draggingPasteboard];
    NSURL *theURL = [NSURL URLFromPasteboardAnyType:pboard];
    
    if ([theURL isFileURL]) {
        if ([[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:theURL display:YES error:NULL])
            return YES;
    } else if (theURL) {
        [self addDownloadForURL:theURL];
        return YES;
    }
    return NO;
}

#pragma mark NSTableViewDelegate

- (void)tableView:(NSTableView *)tv willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row {
    NSString *identifier = [tableColumn identifier];
    SKDownload *download = [self objectInDownloadsAtIndex:row];
    
    if ([identifier isEqualToString:SKDownloadsWindowCancelColumnIdentifier]) {
        if ([download canCancel]) {
            [cell setImage:[NSImage imageNamed:@"Cancel"]];
            [cell setAction:@selector(cancelDownload:)];
            [cell setTarget:self];
        } else {
            [cell setImage:[NSImage imageNamed:@"Delete"]];
            [cell setAction:@selector(removeDownload:)];
            [cell setTarget:self];
        }
    } else if ([identifier isEqualToString:SKDownloadsWindowResumeColumnIdentifier]) {
        if ([download canResume]) {
            [cell setImage:[NSImage imageNamed:@"Resume"]];
            [cell setAction:@selector(resumeDownload:)];
            [cell setTarget:self];
        } else {
            [cell setImage:nil];
            [cell setAction:NULL];
            [cell setTarget:nil];
        }
    }
}

- (NSString *)tableView:(NSTableView *)aTableView toolTipForCell:(NSCell *)cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)tableColumn row:(int)row mouseLocation:(NSPoint)mouseLocation {
    NSString *toolTip = nil;
    if ([[tableColumn identifier] isEqualToString:SKDownloadsWindowCancelColumnIdentifier]) {
        if ([[self objectInDownloadsAtIndex:row] canCancel])
            toolTip = NSLocalizedString(@"Cancel download", @"Tool tip message");
        else
            toolTip = NSLocalizedString(@"Remove download", @"Tool tip message");
    } else if ([[tableColumn identifier] isEqualToString:SKDownloadsWindowResumeColumnIdentifier]) {
        if ([[self objectInDownloadsAtIndex:row] canResume])
            toolTip = NSLocalizedString(@"Resume download", @"Tool tip message");
    }
    return toolTip;
}

- (void)tableView:(NSTableView *)aTableView deleteRowsWithIndexes:(NSIndexSet *)rowIndexes {
    unsigned int row = [rowIndexes firstIndex];
    SKDownload *download = [self objectInDownloadsAtIndex:row];
    
    if ([download canCancel])
        [download cancel];
    else
        [self removeObjectFromDownloadsAtIndex:row];
}

- (BOOL)tableView:(NSTableView *)aTableView canDeleteRowsWithIndexes:(NSIndexSet *)rowIndexes {
    return YES;
}

- (NSMenu *)tableView:(NSTableView *)aTableView menuForTableColumn:(NSTableColumn *)tableColumn row:(int)row {
    NSMenu *menu = [[[NSMenu allocWithZone:[NSMenu menuZone]] init] autorelease];
    NSMenuItem *menuItem;
    SKDownload *download = [self objectInDownloadsAtIndex:row];
    
    [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    
    if ([download canCancel]) {
        menuItem = [menu addItemWithTitle:NSLocalizedString(@"Cancel", @"Menu item title") action:@selector(cancelDownload:) target:self];
        [menuItem setRepresentedObject:download];
    } else {
        menuItem = [menu addItemWithTitle:NSLocalizedString(@"Remove", @"Menu item title") action:@selector(removeDownload:) target:self];
        [menuItem setRepresentedObject:download];
    }
    if ([download canResume]) {
        menuItem = [menu addItemWithTitle:NSLocalizedString(@"Resume", @"Menu item title") action:@selector(resumeDownload:) target:self];
        [menuItem setRepresentedObject:download];
    }
    if ([download status] == SKDownloadStatusFinished) {
        menuItem = [menu addItemWithTitle:[NSLocalizedString(@"Open", @"Menu item title") stringByAppendingEllipsis] action:@selector(openDownloadedFile:) target:self];
        [menuItem setRepresentedObject:download];
        
        menuItem = [menu addItemWithTitle:[NSLocalizedString(@"Reveal", @"Menu item title") stringByAppendingEllipsis] action:@selector(revealDownloadedFile:) target:self];
        [menuItem setRepresentedObject:download];
        
        menuItem = [menu addItemWithTitle:NSLocalizedString(@"Move to Trash", @"Menu item title") action:@selector(trashDownloadedFile:) target:self];
        [menuItem setRepresentedObject:download];
    }
    
    return menu;
}

#pragma mark SKTypeSelectHelper datasource protocol

- (NSArray *)typeSelectHelperSelectionItems:(SKTypeSelectHelper *)typeSelectHelper {
    return [downloads valueForKey:SKDownloadFileNameKey];
}

- (unsigned int)typeSelectHelperCurrentlySelectedIndex:(SKTypeSelectHelper *)typeSelectHelper {
    return [[tableView selectedRowIndexes] lastIndex];
}

- (void)typeSelectHelper:(SKTypeSelectHelper *)typeSelectHelper selectItemAtIndex:(unsigned int)itemIndex {
    [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:itemIndex] byExtendingSelection:NO];
    [tableView scrollRowToVisible:itemIndex];
}

@end
