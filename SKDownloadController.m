//
//  SKDownloadController.m
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

#import "SKDownloadController.h"
#import "SKDownload.h"
#import "SKProgressCell.h"
#import "NSURL_SKExtensions.h"
#import "SKStringConstants.h"
#import "SKTableView.h"
#import "SKTypeSelectHelper.h"
#import "NSString_SKExtensions.h"
#import "NSMenu_SKExtensions.h"
#import "NSGeometry_SKExtensions.h"
#import "NSWindowController_SKExtensions.h"
#import "SKDownloadPreferenceController.h"
#import "NSError_SKExtensions.h"
#import "NSEvent_SKExtensions.h"
#import "NSFileManager_SKExtensions.h"

#define PROGRESS_COLUMN 1
#define RESUME_COLUMN   2
#define CANCEL_COLUMN   3

#define RESUME_COLUMNID @"resume"
#define CANCEL_COLUMNID @"cancel"

#define SKDownloadsWindowFrameAutosaveName @"SKDownloadsWindow"

#define DOWNLOADS_KEY @"downloads"

static char SKDownloadPropertiesObservationContext;

@interface SKDownloadController (SKPrivate)
- (void)startObservingDownloads:(NSArray *)newDownloads;
- (void)endObservingDownloads:(NSArray *)oldDownloads;
@end

@implementation SKDownloadController

@synthesize arrayController, tableView, clearButton, prefButton;

static SKDownloadController *sharedDownloadController = nil;

+ (id)sharedDownloadController {
    if (sharedDownloadController == nil)
        sharedDownloadController = [[self alloc] init];
    return sharedDownloadController;
}

- (id)init {
    if (sharedDownloadController) NSLog(@"Attempt to allocate second instance of %@", [self class]);
    self = [super initWithWindowNibName:@"DownloadsWindow"];
    if (self) {
        downloads = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc {
    [self endObservingDownloads:downloads];
    SKDESTROY(downloads);
    SKDESTROY(arrayController);
    SKDESTROY(tableView);
    SKDESTROY(clearButton);
    SKDESTROY(prefButton);
    [super dealloc];
}

- (void)windowDidLoad {
    [[prefButton cell] accessibilitySetOverrideValue:NSLocalizedString(@"Download preferences", @"Tool tip message") forAttribute:NSAccessibilityDescriptionAttribute];
    
    [clearButton sizeToFit];
    
    [self setWindowFrameAutosaveName:SKDownloadsWindowFrameAutosaveName];
    
    [[self window] setAutorecalculatesContentBorderThickness:NO forEdge:NSMinYEdge];
    [[self window] setContentBorderThickness:24.0 forEdge:NSMinYEdge];
    
    [tableView setTypeSelectHelper:[SKTypeSelectHelper typeSelectHelper]];
    
    [tableView registerForDraggedTypes:[NSArray arrayWithObjects:(NSString *)kUTTypeURL, (NSString *)kUTTypeFileURL, NSURLPboardType, NSFilenamesPboardType, NSPasteboardTypeString, nil]];
    
    [tableView setSupportsQuickLook:YES];
}

- (SKDownload *)addDownloadForURL:(NSURL *)aURL showWindow:(BOOL)flag {
    SKDownload *download = nil;
    if (aURL) {
        download = [[[SKDownload alloc] initWithURL:aURL] autorelease];
        NSInteger row = [self countOfDownloads];
        [[self mutableArrayValueForKey:DOWNLOADS_KEY] addObject:download];
        if (flag)
            [self showWindow:nil];
        [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
        [tableView scrollRowToVisible:row];
    }
    return download;
}

- (SKDownload *)addDownloadForURL:(NSURL *)aURL {
    return [self addDownloadForURL:aURL showWindow:[[NSUserDefaults standardUserDefaults] boolForKey:SKAutoOpenDownloadsWindowKey]];
}

- (BOOL)pasteFromPasteboard:(NSPasteboard *)pboard {
    BOOL success = NO;
    NSArray *theURLs = [NSURL readURLsFromPasteboard:pboard];
    for (NSURL *theURL in theURLs) {
        if ([theURL isFileURL]) {
            if ([[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:theURL display:YES error:NULL])
                success = YES;
        } else {
            [self addDownloadForURL:theURL showWindow:NO];
            success = YES;
        }
    }
    return success;
}

- (void)openDownload:(SKDownload *)download {
    if ([download status] == SKDownloadStatusFinished) {
        NSURL *URL = [download fileURL];
        NSString *fragment = [[download URL] fragment];
        if ([fragment length] > 0)
            URL = [NSURL URLWithString:[[URL absoluteString] stringByAppendingFormat:@"#%@", fragment]];
        
        NSError *error = nil;
        id document = [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:URL display:YES error:&error];
        if (document == nil && [error isUserCancelledError] == NO)
            [self presentError:error];
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:SKAutoRemoveFinishedDownloadsKey]) {
            [[download retain] autorelease];
            [[self mutableArrayValueForKey:DOWNLOADS_KEY] removeObject:download];
            // for the document to note that the file has been deleted
            [document setFileURL:[download fileURL]];
            if ([self countOfDownloads] == 0 && [[NSUserDefaults standardUserDefaults] boolForKey:SKAutoCloseDownloadsWindowKey])
                [[self window] close];
        }
    }
}

#pragma mark Images

+ (NSImage *)cancelImage {
    static NSImage *cancelImage = nil;
    if (cancelImage == nil) {    
        cancelImage = [[NSImage alloc] initWithSize:NSMakeSize(16.0, 16.0)];
        [cancelImage lockFocus];
        [[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kToolbarDeleteIcon)] drawInRect:NSMakeRect(-2.0, -1.0, 20.0, 20.0) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
        [cancelImage unlockFocus];
    }
    return cancelImage;
}

+ (NSImage *)deleteImage {
    static NSImage *deleteImage = nil;
    if (deleteImage == nil) {
        NSImage *tmpImage = [[NSImage alloc] initWithSize:NSMakeSize(16.0, 16.0)];
        [tmpImage lockFocus];
        [[NSImage imageNamed:NSImageNameStopProgressFreestandingTemplate] drawInRect:NSMakeRect(1.0, 1.0, 14.0, 14.0) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
        [[NSColor lightGrayColor] setFill];
        NSRectFillUsingOperation(NSMakeRect(0.0, 0.0, 16.0, 16.0), NSCompositeSourceAtop);
        [tmpImage unlockFocus];
        deleteImage = [[NSImage alloc] initWithSize:NSMakeSize(16.0, 16.0)];
        [deleteImage lockFocus];
        [[NSColor whiteColor] setFill];
        [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(2.0, 2.0, 12.0, 12.0)] fill];
        [tmpImage drawInRect:NSMakeRect(0.0, 0.0, 16.0, 16.0) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
        [tmpImage release];
        [deleteImage unlockFocus];
    }
    return deleteImage;
}

+ (NSImage *)resumeImage {
    static NSImage *resumeImage = nil;
    if (resumeImage == nil) {
        NSImage *tmpImage = [[NSImage alloc] initWithSize:NSMakeSize(16.0, 16.0)];
        [tmpImage lockFocus];
        [[NSImage imageNamed:NSImageNameRefreshFreestandingTemplate] drawInRect:NSMakeRect(1.0, 1.0, 14.0, 14.0) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
        [[NSColor orangeColor] setFill];
        NSRectFillUsingOperation(NSMakeRect(0.0, 0.0, 16.0, 16.0), NSCompositeSourceAtop);
        [tmpImage unlockFocus];
        resumeImage = [[NSImage alloc] initWithSize:NSMakeSize(16.0, 16.0)];
        [resumeImage lockFocus];
        [[NSColor whiteColor] setFill];
        [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(2.0, 2.0, 12.0, 12.0)] fill];
        [tmpImage drawInRect:NSMakeRect(0.0, 0.0, 16.0, 16.0) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
        [tmpImage release];
        [resumeImage unlockFocus];
    }
    return resumeImage;
}

#pragma mark Accessors

- (NSArray *)downloads {
    return [[downloads copy] autorelease];
}

- (NSUInteger)countOfDownloads {
    return [downloads count];
}

- (SKDownload *)objectInDownloadsAtIndex:(NSUInteger)anIndex {
    return [downloads objectAtIndex:anIndex];
}

- (void)insertObject:(SKDownload *)download inDownloadsAtIndex:(NSUInteger)anIndex {
    [downloads insertObject:download atIndex:anIndex];
    [self startObservingDownloads:[NSArray arrayWithObject:download]];
    [download start];
    [downloads makeObjectsPerformSelector:@selector(removeProgressIndicatorFromSuperview)];
    [tableView setNeedsDisplayInRect:[tableView rectOfRow:PROGRESS_COLUMN]];
}

- (void)removeObjectFromDownloadsAtIndex:(NSUInteger)anIndex {
    SKDownload *download = [downloads objectAtIndex:anIndex];
    [self endObservingDownloads:[NSArray arrayWithObject:download]];
    [download cancel];
    [downloads removeObjectAtIndex:anIndex];
    [downloads makeObjectsPerformSelector:@selector(removeProgressIndicatorFromSuperview)];
    [tableView setNeedsDisplayInRect:[tableView rectOfRow:PROGRESS_COLUMN]];
}

#pragma mark Actions

- (IBAction)showDownloadPreferences:(id)sender {
    SKDownloadPreferenceController *prefController = [[[SKDownloadPreferenceController alloc] init] autorelease];
    [prefController beginSheetModalForWindow:[self window] completionHandler:NULL];
}

- (IBAction)clearDownloads:(id)sender {
    NSInteger i = [self countOfDownloads];
    
    while (i-- > 0) {
        SKDownload *download = [self objectInDownloadsAtIndex:i];
        if ([download canRemove])
            [self removeObjectFromDownloadsAtIndex:i];
    }
}

- (IBAction)moveToTrash:(id)sender {
    SKDownload *download = nil;
    NSInteger row = [tableView selectedRow];
    if (row != -1)
        download = [self objectInDownloadsAtIndex:row];
    if ([download canRemove]) {
        if ([download status] == SKDownloadStatusFinished)
            [download moveToTrash];
        [[self mutableArrayValueForKey:DOWNLOADS_KEY] removeObject:download];
    } else {
        NSBeep();
    }
}

- (void)cancelDownload:(id)sender {
    SKDownload *download = [sender respondsToSelector:@selector(representedObject)] ? [sender representedObject] : nil;
    
    if (download == nil) {
        NSInteger row = [tableView clickedRow];
        if (row != -1)
            download = [self objectInDownloadsAtIndex:row];
    }
    if (download && [download canCancel])
        [download cancel];
}

- (void)resumeDownload:(id)sender {
    SKDownload *download = [sender respondsToSelector:@selector(representedObject)] ? [sender representedObject] : nil;
    
    if (download == nil) {
        NSInteger row = [tableView clickedRow];
        if (row != -1)
            download = [self objectInDownloadsAtIndex:row];
    }
    if (download && [download canResume])
        [download resume];
}

- (void)removeDownload:(id)sender {
    SKDownload *download = [sender respondsToSelector:@selector(representedObject)] ? [sender representedObject] : nil;
    
    if (download == nil) {
        NSInteger row = [tableView clickedRow];
        if (row != -1) {
            download = [self objectInDownloadsAtIndex:row];
            if ([NSEvent standardModifierFlags] & NSAlternateKeyMask)
                [download moveToTrash];
        }
    }
    
    if (download)
        [[self mutableArrayValueForKey:DOWNLOADS_KEY] removeObject:download];
}

- (void)openDownloadedFile:(id)sender {
    SKDownload *download = [sender representedObject];
    
    if (download && [download status] != SKDownloadStatusFinished) {
        NSBeep();
    } else {
        NSError *error = nil;
        if (nil == [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:[download fileURL] display:YES error:&error] && [error isUserCancelledError] == NO)
            [self presentError:error];
    }
}

- (void)previewDownloadedFile:(id)sender {
    SKDownload *download = [sender representedObject];
    
    if (download && [download status] != SKDownloadStatusFinished) {
        NSBeep();
    } else if ([QLPreviewPanel sharedPreviewPanelExists] && [[QLPreviewPanel sharedPreviewPanel] isVisible]) {
        [[QLPreviewPanel sharedPreviewPanel] orderOut:nil];
    } else {
        NSUInteger row = [downloads indexOfObject:download];
        if (row != NSNotFound)
            [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
        [[QLPreviewPanel sharedPreviewPanel] makeKeyAndOrderFront:nil];
    }
}

- (void)revealDownloadedFile:(id)sender {
    SKDownload *download = [sender representedObject];
    
    if (download && [download status] != SKDownloadStatusFinished) {
        NSBeep();
    } else {
        [[NSWorkspace sharedWorkspace] selectFile:[[download fileURL] path] inFileViewerRootedAtPath:nil];
    }
}

- (void)trashDownloadedFile:(id)sender {
    SKDownload *download = [sender representedObject];
    
    if (download && [download status] != SKDownloadStatusFinished)
        NSBeep();
    else
        [download moveToTrash];
}

#pragma mark Menu validation

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    if ([menuItem action] == @selector(moveToTrash:)) {
        NSInteger row = [tableView selectedRow];
        return (row != -1 && [[self objectInDownloadsAtIndex:row] canRemove]);
    }
    return YES;
}

#pragma mark NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tv { return 0; }

- (id)tableView:(NSTableView *)tv objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row { return nil; }

- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)op {
    NSPasteboard *pboard = [info draggingPasteboard];
    if ([NSURL canReadURLFromPasteboard:pboard]) {
        [tv setDropRow:-1 dropOperation:NSTableViewDropOn];
        return NSDragOperationEvery;
    }
    return NSDragOperationNone;
}
       
- (BOOL)tableView:(NSTableView*)tv acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)op {
    return [self pasteFromPasteboard:[info draggingPasteboard]];
}

#pragma mark NSTableViewDelegate

- (void)tableView:(NSTableView *)tv willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSString *identifier = [tableColumn identifier];
    SKDownload *download = [self objectInDownloadsAtIndex:row];
    
    if ([identifier isEqualToString:CANCEL_COLUMNID]) {
        if ([download canCancel]) {
            [cell setImage:[[self class] cancelImage]];
            [cell setAction:@selector(cancelDownload:)];
            [cell setTarget:self];
        } else if ([download canRemove]) {
            [cell setImage:[[self class] deleteImage]];
            [cell setAction:@selector(removeDownload:)];
            [cell setTarget:self];
        } else {
            [cell setImage:nil];
            [cell setAction:NULL];
            [cell setTarget:nil];
        }
    } else if ([identifier isEqualToString:RESUME_COLUMNID]) {
        if ([download canResume]) {
            [cell setImage:[[self class] resumeImage]];
            [cell setAction:@selector(resumeDownload:)];
            [cell setTarget:self];
        } else {
            [cell setImage:nil];
            [cell setAction:NULL];
            [cell setTarget:nil];
        }
    }
}

- (NSString *)tableView:(NSTableView *)aTableView toolTipForCell:(NSCell *)cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row mouseLocation:(NSPoint)mouseLocation {
    NSString *toolTip = nil;
    if ([[tableColumn identifier] isEqualToString:CANCEL_COLUMNID]) {
        if ([[self objectInDownloadsAtIndex:row] canCancel])
            toolTip = NSLocalizedString(@"Cancel download", @"Tool tip message");
        else if ([[self objectInDownloadsAtIndex:row] canRemove])
            toolTip = NSLocalizedString(@"Remove download", @"Tool tip message");
    } else if ([[tableColumn identifier] isEqualToString:RESUME_COLUMNID]) {
        if ([[self objectInDownloadsAtIndex:row] canResume])
            toolTip = NSLocalizedString(@"Resume download", @"Tool tip message");
    }
    return toolTip;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    if ([QLPreviewPanel sharedPreviewPanelExists] && [[QLPreviewPanel sharedPreviewPanel] isVisible] && [[QLPreviewPanel sharedPreviewPanel] dataSource] == self)
        [[QLPreviewPanel sharedPreviewPanel] reloadData];
}

- (void)tableView:(NSTableView *)aTableView deleteRowsWithIndexes:(NSIndexSet *)rowIndexes {
    NSUInteger row = [rowIndexes firstIndex];
    SKDownload *download = [self objectInDownloadsAtIndex:row];
    
    if ([download canCancel])
        [download cancel];
    else if ([download canRemove])
        [self removeObjectFromDownloadsAtIndex:row];
}

- (BOOL)tableView:(NSTableView *)aTableView canDeleteRowsWithIndexes:(NSIndexSet *)rowIndexes {
    return YES;
}

- (void)tableView:(NSTableView *)tv pasteFromPasteboard:(NSPasteboard *)pboard {
    if (NO == [self pasteFromPasteboard:pboard])
        NSBeep();
}

- (BOOL)tableView:(NSTableView *)tv canPasteFromPasteboard:(NSPasteboard *)pboard {
    return [NSURL canReadURLFromPasteboard:pboard];
}

- (NSArray *)tableView:(NSTableView *)aTableView typeSelectHelperSelectionStrings:(SKTypeSelectHelper *)typeSelectHelper {
    return [downloads valueForKey:SKDownloadFileNameKey];
}

#pragma mark Contextual menu

- (void)menuNeedsUpdate:(NSMenu *)menu {
    NSMenuItem *menuItem;
    NSInteger row = [tableView clickedRow];
    [menu removeAllItems];
    if (row != -1) {
        SKDownload *download = [self objectInDownloadsAtIndex:row];
        
        if ([download canCancel]) {
            menuItem = [menu addItemWithTitle:NSLocalizedString(@"Cancel", @"Menu item title") action:@selector(cancelDownload:) target:self];
            [menuItem setRepresentedObject:download];
        } else if ([download canRemove]) {
            menuItem = [menu addItemWithTitle:NSLocalizedString(@"Remove", @"Menu item title") action:@selector(removeDownload:) target:self];
            [menuItem setRepresentedObject:download];
        }
        if ([download canResume]) {
            menuItem = [menu addItemWithTitle:NSLocalizedString(@"Resume", @"Menu item title") action:@selector(resumeDownload:) target:self];
            [menuItem setRepresentedObject:download];
        }
        if ([download status] == SKDownloadStatusFinished && [[download fileURL] checkResourceIsReachableAndReturnError:NULL]) {
            menuItem = [menu addItemWithTitle:[NSLocalizedString(@"Open", @"Menu item title") stringByAppendingEllipsis] action:@selector(openDownloadedFile:) target:self];
            [menuItem setRepresentedObject:download];
            
            menuItem = [menu addItemWithTitle:[NSLocalizedString(@"Quick Look", @"Menu item title") stringByAppendingEllipsis] action:@selector(previewDownloadedFile:) target:self];
            [menuItem setRepresentedObject:download];
            
            menuItem = [menu addItemWithTitle:[NSLocalizedString(@"Reveal", @"Menu item title") stringByAppendingEllipsis] action:@selector(revealDownloadedFile:) target:self];
            [menuItem setRepresentedObject:download];
            
            menuItem = [menu addItemWithTitle:NSLocalizedString(@"Move to Trash", @"Menu item title") action:@selector(trashDownloadedFile:) target:self];
            [menuItem setRepresentedObject:download];
        }
    }
}

#pragma mark KVO

- (void)startObservingDownloads:(NSArray *)newDownloads {
    NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [newDownloads count])];
    [newDownloads addObserver:self toObjectsAtIndexes:indexes forKeyPath:SKDownloadFileNameKey options:0 context:&SKDownloadPropertiesObservationContext];
    [newDownloads addObserver:self toObjectsAtIndexes:indexes forKeyPath:SKDownloadStatusKey options:0 context:&SKDownloadPropertiesObservationContext];
}

- (void)endObservingDownloads:(NSArray *)oldDownloads {
    NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [oldDownloads count])];
    [oldDownloads removeObserver:self fromObjectsAtIndexes:indexes forKeyPath:SKDownloadFileNameKey];
    [oldDownloads removeObserver:self fromObjectsAtIndexes:indexes forKeyPath:SKDownloadStatusKey];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == &SKDownloadPropertiesObservationContext) {
        if ([keyPath isEqualToString:SKDownloadFileNameKey]) {
            [[tableView typeSelectHelper] rebuildTypeSelectSearchCache];
        } else if ([keyPath isEqualToString:SKDownloadStatusKey]) {
            NSUInteger row = [downloads indexOfObject:object];
            if (row != NSNotFound)
                [tableView setNeedsDisplayInRect:NSUnionRect([tableView frameOfCellAtColumn:RESUME_COLUMN row:row], [tableView frameOfCellAtColumn:CANCEL_COLUMN row:row])];
            if ([object status] == SKDownloadStatusFinished) {
                [self openDownload:object];
                if ([QLPreviewPanel sharedPreviewPanelExists] && [[QLPreviewPanel sharedPreviewPanel] isVisible] && [[QLPreviewPanel sharedPreviewPanel] dataSource] == self)
                    [[QLPreviewPanel sharedPreviewPanel] reloadData];
            }
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark Quick Look Panel Support

- (BOOL)acceptsPreviewPanelControl:(QLPreviewPanel *)panel {
    return YES;
}

- (void)beginPreviewPanelControl:(QLPreviewPanel *)panel {
    [panel setDelegate:self];
    [panel setDataSource:self];
}

- (void)endPreviewPanelControl:(QLPreviewPanel *)panel {
}

- (NSInteger)numberOfPreviewItemsInPreviewPanel:(QLPreviewPanel *)panel {
    NSUInteger row = [[tableView selectedRowIndexes] lastIndex];
    SKDownload *download = nil;
    if (row != NSNotFound) {
        download = [self objectInDownloadsAtIndex:row];
        if ([download status] == SKDownloadStatusFinished && [[download fileURL] checkResourceIsReachableAndReturnError:NULL])
            return 1;
    }
    return 0;
}

- (id <QLPreviewItem>)previewPanel:(QLPreviewPanel *)panel previewItemAtIndex:(NSInteger)anIndex {
    NSUInteger row = [[tableView selectedRowIndexes] lastIndex];
    SKDownload *download = nil;
    if (row != NSNotFound)
        download = [self objectInDownloadsAtIndex:row];
    return download;
}

- (NSRect)previewPanel:(QLPreviewPanel *)panel sourceFrameOnScreenForPreviewItem:(id <QLPreviewItem>)item {
    NSUInteger row = [downloads indexOfObject:item];
    NSRect iconRect = NSZeroRect;
    if (row != NSNotFound) {
        iconRect = [tableView frameOfCellAtColumn:0 row:row];
        if (NSIntersectsRect([tableView visibleRect], iconRect)) {
            iconRect = [tableView convertRectToBase:iconRect];
            iconRect.origin = [[self window] convertBaseToScreen:iconRect.origin];
        } else {
            iconRect = NSZeroRect;
        }
    }
    return iconRect;
}

- (BOOL)previewPanel:(QLPreviewPanel *)panel handleEvent:(NSEvent *)event {
    if ([event type] == NSKeyDown) {
        [tableView keyDown:event];
        return YES;
    }
    return NO;
}

@end
