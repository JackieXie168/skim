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

static NSString *SKDownloadsWindowFrameAutosaveName = @"SKDownloadsWindow";

@implementation SKDownloadController

+ (id)sharedDownloadController {
    static SKDownloadController *sharedDownloadController = nil;
    if (sharedDownloadController == nil)
        sharedDownloadController = [[self alloc] init];
    return sharedDownloadController;
}

- (id)init {
    if (self = [super init]) {
        downloads = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc {
    [downloads release];
    [super dealloc];
}

- (NSString *)windowNibName { return @"DownloadsWindow"; }

- (void)reloadTableView {
    NSView *view;
    while (view = [[tableView subviews] lastObject])
        [view removeFromSuperview];
    [tableView reloadData];
}

- (void)updateButtons {
    BOOL enable = NO;
    NSEnumerator *downloadEnum = [downloads objectEnumerator];
    SKDownload *download;
    while (download = [downloadEnum nextObject]) {
        if ([download canCancel] == NO) {
            enable = YES;
            break;
        }
    }
    [clearButton setEnabled:enable];
}

- (void)windowDidLoad {
    [self setWindowFrameAutosaveName:SKDownloadsWindowFrameAutosaveName];
    [self updateButtons];
    
    SKTypeSelectHelper *typeSelectHelper = [[[SKTypeSelectHelper alloc] init] autorelease];
    [typeSelectHelper setDataSource:self];
    [tableView setTypeSelectHelper:typeSelectHelper];
    
    [tableView registerForDraggedTypes:[NSArray arrayWithObjects:NSURLPboardType, SKWeblocFilePboardType, NSStringPboardType, nil]];
}

- (void)addDownloadForURL:(NSURL *)aURL {
    if (aURL) {
        SKDownload *download = [[[SKDownload alloc] initWithURL:aURL delegate:self] autorelease];
        int row = [downloads count];
        [downloads addObject:download];
        [self reloadTableView];
        [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
        [tableView scrollRowToVisible:row];
    }
}

#pragma mark Actions

- (IBAction)clearDownloads:(id)sender {
    int index = [downloads count];
    
    if (index) {
        while (index-- > 0) {
            SKDownload *download = [downloads objectAtIndex:index];
            if ([download status] != SKDownloadStatusDownloading)
                [downloads removeObjectAtIndex:index];
        }
        [self reloadTableView];
        [self updateButtons];
    }
}

- (IBAction)cancelDownload:(id)sender {
    SKDownload *download = [sender respondsToSelector:@selector(representedObject)] ? [sender representedObject] : nil;
    
    if (download == nil) {
        int row = [tableView clickedRow];
        if (row != -1)
            download = [downloads objectAtIndex:row];
    }
    if (download && [download status] == SKDownloadStatusDownloading) {
        [download cancelDownload];
    }
}

- (IBAction)resumeDownload:(id)sender {
    SKDownload *download = [sender respondsToSelector:@selector(representedObject)] ? [sender representedObject] : nil;
    
    if (download == nil) {
        int row = [tableView clickedRow];
        if (row != -1)
            download = [downloads objectAtIndex:row];
    }
    if (download && [download status] == SKDownloadStatusCanceled) {
        [download resumeDownload];
        [self reloadTableView];
        [self updateButtons];
    }
}

- (IBAction)removeDownload:(id)sender {
    SKDownload *download = [sender respondsToSelector:@selector(representedObject)] ? [sender representedObject] : nil;
    
    if (download == nil) {
        int row = [tableView clickedRow];
        if (row != -1)
            download = [downloads objectAtIndex:row];
    }
    
    if (download) {
        [download cancelDownload];
        [downloads removeObject:download];
        [self reloadTableView];
        [self updateButtons];
    }
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
        return;
    }
    
    NSURL *fileURL = [NSURL fileURLWithPath:[download filePath]];
    NSError *error;
    if (nil == [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:fileURL display:YES error:&error])
        [NSApp presentError:error];
}

- (void)revealDownloadedFile:(id)sender {
    SKDownload *download = [sender representedObject];
    
    if (download && [download status] != SKDownloadStatusFinished) {
        NSBeep();
        return;
    }
    
    [[NSWorkspace sharedWorkspace] selectFile:[download filePath] inFileViewerRootedAtPath:nil];
}

- (void)trashDownloadedFile:(id)sender {
    SKDownload *download = [sender representedObject];
    
    if (download && [download status] != SKDownloadStatusFinished) {
        NSBeep();
        return;
    }
    
    NSString *filePath = [download filePath];
    NSString *folderPath = [filePath stringByDeletingLastPathComponent];
    NSString *fileName = [filePath lastPathComponent];
    int tag = 0;
    
    [[NSWorkspace sharedWorkspace] performFileOperation:NSWorkspaceRecycleOperation source:folderPath destination:nil files:[NSArray arrayWithObjects:fileName, nil] tag:&tag];
}

#pragma mark SKDownloadDelegate

- (void)downloadDidStart:(SKDownload *)download {
    [self reloadTableView];
    [self updateButtons];
}

- (void)downloadDidUpdate:(SKDownload *)download {
    [tableView reloadData];
    [self updateButtons];
}

- (void)downloadDidEnd:(SKDownload *)download {
    if ([download status] == SKDownloadStatusFinished) {
        NSURL *URL = [NSURL fileURLWithPath:[download filePath]];
        NSError *error = nil;
        id document = [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:URL display:YES error:&error];
        if (document == nil)
            [NSApp presentError:error];
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:SKAutoRemoveFinishedDownloadsKey]) {
            [download cancelDownload];
            [downloads removeObject:download];
            // for the document to note that the file has been deleted
            [document setFileURL:[NSURL fileURLWithPath:[download filePath]]];
            if ([downloads count] == 0 && [[NSUserDefaults standardUserDefaults] boolForKey:SKAutoCloseDownloadsWindowKey])
                [[self window] close];
        }
    }
    
    [self reloadTableView];
    [self updateButtons];
}

#pragma mark NSTableViewDataSource

- (int)numberOfRowsInTableView:(NSTableView *)tv {
    return [downloads count];
}

- (id)tableView:(NSTableView *)tv objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row {
    NSString *identifier = [tableColumn identifier];
    SKDownload *download = [downloads objectAtIndex:row];
    
    if ([identifier isEqualToString:@"progress"]) {
        return [download fileName];
    } else if ([identifier isEqualToString:@"icon"]) {
        return [download fileIcon];
    }
    return nil;
}

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
    SKDownload *download = [downloads objectAtIndex:row];
    
    if ([identifier isEqualToString:@"progress"]) {
        if ([cell respondsToSelector:@selector(setProgressIndicator:)])
            [(SKProgressCell *)cell setProgressIndicator:[download progressIndicator]];
        if ([cell respondsToSelector:@selector(setStatus:)])
            [(SKProgressCell *)cell setStatus:[download status]];
    } else if ([identifier isEqualToString:@"cancel"]) {
        if ([download canCancel]) {
            [cell setImage:[NSImage imageNamed:@"Cancel"]];
            [cell setAction:@selector(cancelDownload:)];
            [cell setTarget:self];
        } else {
            [cell setImage:[NSImage imageNamed:@"Delete"]];
            [cell setAction:@selector(removeDownload:)];
            [cell setTarget:self];
        }
    } else if ([identifier isEqualToString:@"resume"]) {
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
    if ([[tableColumn identifier] isEqualToString:@"cancel"]) {
        if ([[downloads objectAtIndex:row] canCancel])
            toolTip = NSLocalizedString(@"Cancel download", @"Tool tip message");
        else
            toolTip = NSLocalizedString(@"Remove download", @"Tool tip message");
    } else if ([[tableColumn identifier] isEqualToString:@"resume"]) {
        if ([[downloads objectAtIndex:row] canResume])
            toolTip = NSLocalizedString(@"Resume download", @"Tool tip message");
    }
    return toolTip;
}

- (void)tableView:(NSTableView *)aTableView deleteRowsWithIndexes:(NSIndexSet *)rowIndexes {
    unsigned int row = [rowIndexes firstIndex];
    SKDownload *download = [downloads objectAtIndex:row];
    
    if ([download canCancel]) {
        [download cancelDownload];
    } else {
        [download cancelDownload];
        [downloads removeObjectAtIndex:row];
        [self reloadTableView];
        [self updateButtons];
    }
}

- (BOOL)tableView:(NSTableView *)aTableView canDeleteRowsWithIndexes:(NSIndexSet *)rowIndexes {
    return YES;
}

- (NSMenu *)tableView:(NSTableView *)aTableView menuForTableColumn:(NSTableColumn *)tableColumn row:(int)row {
    NSMenu *menu = [[[NSMenu allocWithZone:[NSMenu menuZone]] init] autorelease];
    NSMenuItem *menuItem;
    SKDownload *download = [downloads objectAtIndex:row];
    
    [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    
    if ([download canCancel]) {
        menuItem = [menu addItemWithTitle:NSLocalizedString(@"Cancel", @"Menu item title") action:@selector(cancelDownload:) keyEquivalent:@""];
        [menuItem setTarget:self];
        [menuItem setRepresentedObject:download];
    } else {
        menuItem = [menu addItemWithTitle:NSLocalizedString(@"Remove", @"Menu item title") action:@selector(removeDownload:) keyEquivalent:@""];
        [menuItem setTarget:self];
        [menuItem setRepresentedObject:download];
    }
    if ([download canResume]) {
        menuItem = [menu addItemWithTitle:NSLocalizedString(@"Resume", @"Menu item title") action:@selector(resumeDownload:) keyEquivalent:@""];
        [menuItem setTarget:self];
        [menuItem setRepresentedObject:download];
    }
    if ([download status] == SKDownloadStatusFinished) {
        menuItem = [menu addItemWithTitle:[NSLocalizedString(@"Open", @"Menu item title") stringByAppendingEllipsis] action:@selector(openDownloadedFile:) keyEquivalent:@""];
        [menuItem setTarget:self];
        [menuItem setRepresentedObject:download];
        
        menuItem = [menu addItemWithTitle:[NSLocalizedString(@"Reveal", @"Menu item title") stringByAppendingEllipsis] action:@selector(revealDownloadedFile:) keyEquivalent:@""];
        [menuItem setTarget:self];
        [menuItem setRepresentedObject:download];
        
        menuItem = [menu addItemWithTitle:NSLocalizedString(@"Move to Trash", @"Menu item title") action:@selector(trashDownloadedFile:) keyEquivalent:@""];
        [menuItem setTarget:self];
        [menuItem setRepresentedObject:download];
    }
    
    return menu;
}

#pragma mark SKTypeSelectHelper datasource protocol

- (NSArray *)typeSelectHelperSelectionItems:(SKTypeSelectHelper *)typeSelectHelper {
    return [downloads valueForKey:@"fileName"];
}

- (unsigned int)typeSelectHelperCurrentlySelectedIndex:(SKTypeSelectHelper *)typeSelectHelper {
    return [[tableView selectedRowIndexes] lastIndex];
}

- (void)typeSelectHelper:(SKTypeSelectHelper *)typeSelectHelper selectItemAtIndex:(unsigned int)itemIndex {
    [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:itemIndex] byExtendingSelection:NO];
    [tableView scrollRowToVisible:itemIndex];
}

@end
