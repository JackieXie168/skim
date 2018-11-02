//
//  SKRightSideViewController.m
//  Skim
//
//  Created by Christiaan Hofman on 3/28/10.
/*
 This software is Copyright (c) 2010-2018
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

#import "SKRightSideViewController.h"
#import "SKMainWindowController.h"
#import "SKMainWindowController_Actions.h"
#import "SKMainWindowController_UI.h"
#import "NSMenu_SKExtensions.h"
#import "NSSegmentedControl_SKExtensions.h"
#import "SKTypeSelectHelper.h"
#import "SKNoteOutlineView.h"
#import "NSColor_SKExtensions.h"
#import <SkimNotes/SkimNotes.h>
#import "PDFAnnotation_SKExtensions.h"
#import "SKSnapshotWindowController.h"
#import "NSURL_SKExtensions.h"
#import "PDFPage_SKExtensions.h"

#define IMAGE_COLUMNID @"image"
#define COLOR_COLUMNID @"color"

@implementation SKRightSideViewController

@synthesize noteArrayController, noteOutlineView, snapshotArrayController, snapshotTableView;

- (void)dealloc {
    [snapshotTableView setDelegate:nil];
    [snapshotTableView setDataSource:nil];
    [noteOutlineView setDelegate:nil];
    [noteOutlineView setDataSource:nil];
    SKDESTROY(noteArrayController);
    SKDESTROY(snapshotArrayController);
    SKDESTROY(noteOutlineView);
    SKDESTROY(snapshotTableView);
    [super dealloc];
}

- (NSString *)nibName {
    return @"RightSideView";
}

- (void)loadView {
    [super loadView];
    
    [button setHelp:NSLocalizedString(@"View Notes", @"Tool tip message") forSegment:SKSidePaneStateNote];
    [button setHelp:NSLocalizedString(@"View Snapshots", @"Tool tip message") forSegment:SKSidePaneStateSnapshot];
    
    NSMenu *menu = [NSMenu menu];
    [menu addItemWithTitle:NSLocalizedString(@"Ignore Case", @"Menu item title") action:@selector(toggleCaseInsensitiveNoteSearch:) target:mainController];
    [[searchField cell] setSearchMenuTemplate:menu];
    [[searchField cell] setPlaceholderString:NSLocalizedString(@"Search", @"placeholder")];
    
    [searchField setAction:@selector(searchNotes:)];
    [searchField setTarget:mainController];
    
    [noteOutlineView setAutoresizesOutlineColumn: NO];
    
    if ([noteOutlineView respondsToSelector:@selector(setStronglyReferencesItems:)])
        [noteOutlineView setStronglyReferencesItems:YES];
    
    [noteOutlineView setDelegate:mainController];
    [noteOutlineView setDataSource:mainController];
    [snapshotTableView setDelegate:self];
    [snapshotTableView setDataSource:self];
    [[noteOutlineView menu] setDelegate:mainController];
    [[snapshotTableView menu] setDelegate:mainController];
    
    [noteOutlineView setDoubleAction:@selector(selectSelectedNote:)];
    [noteOutlineView setTarget:mainController];
    [snapshotTableView setDoubleAction:@selector(toggleSelectedSnapshots:)];
    [snapshotTableView setTarget:mainController];
    
    [noteOutlineView setTypeSelectHelper:[SKTypeSelectHelper typeSelectHelperWithMatchOption:SKSubstringMatch]];
    
    [snapshotTableView setBackgroundColor:[NSColor mainSourceListBackgroundColor]];
    
    NSSortDescriptor *pageIndexSortDescriptor = [[[NSSortDescriptor alloc] initWithKey:SKNPDFAnnotationPageIndexKey ascending:YES] autorelease];
    NSSortDescriptor *boundsSortDescriptor = [[[NSSortDescriptor alloc] initWithKey:SKPDFAnnotationBoundsOrderKey ascending:YES selector:@selector(compare:)] autorelease];
    [noteArrayController setSortDescriptors:[NSArray arrayWithObjects:pageIndexSortDescriptor, boundsSortDescriptor, nil]];
    [snapshotArrayController setSortDescriptors:[NSArray arrayWithObjects:pageIndexSortDescriptor, nil]];
    
    [noteOutlineView setIndentationPerLevel:1.0];
    
    [noteOutlineView registerForDraggedTypes:[NSColor readableTypesForPasteboard:[NSPasteboard pasteboardWithName:NSDragPboard]]];
    
    [snapshotTableView setDraggingSourceOperationMask:NSDragOperationEvery forLocal:NO];
}

#pragma mark NSTableView datasource protocol

// AppKit bug: need a dummy NSTableDataSource implementation, otherwise some NSTableView delegate methods are ignored
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tv { return 0; }

- (id)tableView:(NSTableView *)tv objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row { return nil; }

- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard {
    if ([tv isEqual:snapshotTableView]) {
        NSUInteger idx = [rowIndexes firstIndex];
        if (idx != NSNotFound) {
            SKSnapshotWindowController *snapshot = [[snapshotArrayController arrangedObjects] objectAtIndex:idx];
            NSPasteboardItem *item = [[[NSPasteboardItem alloc] init] autorelease];
            [item setData:[[snapshot thumbnailWithSize:0.0] TIFFRepresentation] forType:NSPasteboardTypeTIFF];
            [item setString:(NSString *)kUTTypeTIFF forType:(NSString *)kPasteboardTypeFilePromiseContent];
            [item setDataProvider:snapshot forTypes:[NSArray arrayWithObjects:(NSString *)kPasteboardTypeFileURLPromise, nil]];
            [pboard clearContents];
            [pboard writeObjects:[NSArray arrayWithObjects:item, nil]];
            return YES;
        }
    }
    return NO;
}

- (NSArray *)tableView:(NSTableView *)tv namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination forDraggedRowsWithIndexes:(NSIndexSet *)rowIndexes {
    if ([tv isEqual:snapshotTableView]) {
        NSUInteger idx = [rowIndexes firstIndex];
        if (idx != NSNotFound) {
            SKSnapshotWindowController *snapshot = [[snapshotArrayController arrangedObjects] objectAtIndex:idx];
            PDFPage *page = [[[mainController pdfView] document] pageAtIndex:[snapshot pageIndex]];
            NSString *filename = [NSString stringWithFormat:@"%@ %c %@", ([[[mainController document] displayName] stringByDeletingPathExtension] ?: @"PDF"), '-', [NSString stringWithFormat:NSLocalizedString(@"Page %@", @""), [page displayLabel]]];
            NSURL *fileURL = [[dropDestination URLByAppendingPathComponent:filename] URLByAppendingPathExtension:@"tiff"];
            fileURL = [fileURL uniqueFileURL];
            if ([[[snapshot thumbnailWithSize:0.0] TIFFRepresentation] writeToURL:fileURL atomically:YES])
                return [NSArray arrayWithObjects:[fileURL lastPathComponent], nil];
        }
    }
    return [NSArray array];
}

#pragma mark NSTableView delegate protocol

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
    if ([[aNotification object] isEqual:snapshotTableView]) {
        NSInteger row = [snapshotTableView selectedRow];
        if (row != -1) {
            SKSnapshotWindowController *controller = [[snapshotArrayController arrangedObjects] objectAtIndex:row];
            if ([[controller window] isVisible])
                [[controller window] orderFront:self];
        }
    }
}

- (void)tableViewColumnDidResize:(NSNotification *)aNotification {
    if ([[[[aNotification userInfo] objectForKey:@"NSTableColumn"] identifier] isEqualToString:IMAGE_COLUMNID]) {
        if ([[aNotification object] isEqual:snapshotTableView]) {
            [snapshotTableView noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [snapshotTableView numberOfRows])]];
        }
    }
}

- (CGFloat)tableView:(NSTableView *)tv heightOfRow:(NSInteger)row {
    if ([tv isEqual:snapshotTableView]) {
        NSSize thumbSize = [[[[snapshotArrayController arrangedObjects] objectAtIndex:row] thumbnail] size];
        return [mainController heightOfRowForThumbnailSize:thumbSize inTableView:tv];
    }
    return [tv rowHeight];
}

- (void)tableView:(NSTableView *)tv deleteRowsWithIndexes:(NSIndexSet *)rowIndexes {
    if ([tv isEqual:snapshotTableView]) {
        NSArray *controllers = [[snapshotArrayController arrangedObjects] objectsAtIndexes:rowIndexes];
        [controllers makeObjectsPerformSelector:@selector(close)];
    }
}

- (BOOL)tableView:(NSTableView *)tv canDeleteRowsWithIndexes:(NSIndexSet *)rowIndexes {
    if ([tv isEqual:snapshotTableView]) {
        return [rowIndexes count] > 0;
    }
    return NO;
}

@end
